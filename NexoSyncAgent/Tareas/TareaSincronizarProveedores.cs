using Dapper;
using NexoSyncAgent.NexoApiClient;
using NexoSyncAgent.NexoApiClient.Dtos;
using NexoSyncAgent.VisionsData;

namespace NexoSyncAgent.Tareas;

// NEXO → Visions: sincroniza proveedores activos de catalogo.Proveedores hacia dbo.USUARIOS (PROVEEDOR=1).
// Visions → NEXO: lee dbo.USUARIOS (PROVEEDOR=1) y los upsertea en catalogo.Proveedores via API.
// Un NIT puede ser simultáneamente CLIENTE=1 y PROVEEDOR=1 en Visions; el MERGE no toca la columna CLIENTE.
public class TareaSincronizarProveedores
{
    private readonly INexoApiClient _apiClient;
    private readonly IVisionsConnectionFactory _visionsDb;
    private readonly ILogger<TareaSincronizarProveedores> _logger;

    public TareaSincronizarProveedores(
        INexoApiClient apiClient, IVisionsConnectionFactory visionsDb, ILogger<TareaSincronizarProveedores> logger)
    {
        _apiClient = apiClient;
        _visionsDb = visionsDb;
        _logger = logger;
    }

    public async Task EjecutarAsync(CancellationToken ct, bool incluirVisionsANexo = true)
    {
        await SincronizarNexoAVisionsAsync(ct);
        if (incluirVisionsANexo)
            await SincronizarVisionsANexoAsync(ct);
    }

    // NEXO catalogo.Proveedores → dbo.USUARIOS (PROVEEDOR=1)
    // Si el NIT ya existe en USUARIOS (posiblemente como CLIENTE=1), solo marca PROVEEDOR=1
    // sin tocar ningún otro campo (TareaSincronizarClientes ya gestiona los datos compartidos).
    // Solo hace INSERT completo si el NIT no existe todavía en USUARIOS.
    private async Task SincronizarNexoAVisionsAsync(CancellationToken ct)
    {
        var proveedores = await _apiClient.ListarProveedoresParaSyncAsync(ct);
        if (proveedores.Count == 0) return;

        _logger.LogInformation("Sincronizando {N} proveedores NEXO → Visions USUARIOS", proveedores.Count);

        using var connection = _visionsDb.CreateConnection();

        foreach (var p in proveedores)
        {
            if (string.IsNullOrWhiteSpace(p.NIT)) continue;
            if (ct.IsCancellationRequested) break;

            // Si el proveedor fue inactivado en NEXO, solo propagar el de-rol en Visions
            if (!p.Estado)
            {
                try
                {
                    await connection.ExecuteAsync(
                        "UPDATE dbo.USUARIOS SET PROVEEDOR = 0 WHERE NIT = @NIT",
                        new { NIT = p.NIT });
                    _logger.LogDebug("Proveedor NIT {NIT} inactivado en NEXO → PROVEEDOR=0 en Visions", p.NIT);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error al propagar inactivacion del proveedor NIT {NIT} a Visions", p.NIT);
                }
                continue;
            }

            try
            {
                var esJuridica = (p.TipoPersona ?? "Juridica") != "Natural";
                var tipotercero = esJuridica ? "JURIDICA" : "NATURAL";
                var tipoid = esJuridica ? "NIT" : "CEDULA DE CIUDADANIA";
                var empresa   = esJuridica ? p.RazonSocial : null;
                var nombre2   = esJuridica ? null : p.SegundoNombre;
                var apellido2 = esJuridica ? null : p.SegundoApellido;

                // Para naturales: aplicar "." como placeholder mínimo si faltan nombre/apellido.
                var nombre1   = esJuridica ? null : (string.IsNullOrWhiteSpace(p.PrimerNombre) ? "." : p.PrimerNombre);
                var apellido1 = esJuridica ? null : (string.IsNullOrWhiteSpace(p.PrimerApellido) ? "." : p.PrimerApellido);

                // Aplicar defaults para campos de contacto opcionales
                var telProv   = string.IsNullOrWhiteSpace(p.Telefono)  ? "3000000000"       : p.Telefono;
                var emailProv = string.IsNullOrWhiteSpace(p.Email)     ? "default@gmail.com" : p.Email;
                var dirProv   = string.IsNullOrWhiteSpace(p.Direccion) ? "default"           : p.Direccion;
                // Teléfono y dirección van a la columna correcta según tipo de persona
                var telNatural  = esJuridica ? null : telProv;
                var telEmpresa  = esJuridica ? telProv : null;
                var dirNatural  = esJuridica ? null : dirProv;
                var dirEmpresa  = esJuridica ? dirProv : null;

                // Si NEXO no tiene el dígito de verificación, calcularlo desde el NIT.
                var digitoVerificacion = p.DigitoVerificacion
                    ?? ColombiaUtils.CalcularDigitoVerificacion(p.NIT);
                if (digitoVerificacion.HasValue && !p.DigitoVerificacion.HasValue)
                    _logger.LogDebug("Proveedor NIT {NIT}: digito de verificacion calculado automaticamente = {Digito}", p.NIT, digitoVerificacion.Value);

                // Solo omitir si faltan campos que no tienen fallback razonable.
                var camposFaltantes = new List<string>();
                if (esJuridica && string.IsNullOrWhiteSpace(empresa)) camposFaltantes.Add("Empresa/RazonSocial");
                if (digitoVerificacion is null)                        camposFaltantes.Add("DigitoVerificacion");
                if (string.IsNullOrWhiteSpace(p.Ciudad))               camposFaltantes.Add("Ciudad");
                if (string.IsNullOrWhiteSpace(p.Departamento))         camposFaltantes.Add("Departamento");
                if (camposFaltantes.Count > 0)
                {
                    _logger.LogWarning("Proveedor NIT {NIT} omitido del sync a Visions: faltan campos requeridos: {Campos}",
                        p.NIT, string.Join(", ", camposFaltantes));
                    continue;
                }

                await connection.ExecuteAsync(@"
                    IF EXISTS (SELECT 1 FROM dbo.USUARIOS WHERE NIT = @NIT)
                        -- Ya existe: marcar PROVEEDOR=1 y actualizar todos los datos del proveedor
                        UPDATE dbo.USUARIOS SET
                            PROVEEDOR   = 1,
                            TIPOTERCERO = @Tipotercero,
                            TIPOID      = @Tipoid,
                            NITVERIFICA     = CASE WHEN ISNULL(@DigitoVerificacion,'') <> '' THEN @DigitoVerificacion ELSE NITVERIFICA END,
                            EMPRESA         = CASE WHEN ISNULL(@Empresa,'') <> ''    THEN @Empresa    ELSE EMPRESA    END,
                            NOMBRE1         = CASE WHEN ISNULL(@Nombre1,'') <> ''    THEN @Nombre1    ELSE NOMBRE1    END,
                            NOMBRE2         = CASE WHEN ISNULL(@Nombre2,'') <> ''    THEN @Nombre2    ELSE NOMBRE2    END,
                            APELLIDO1       = CASE WHEN ISNULL(@Apellido1,'') <> ''  THEN @Apellido1  ELSE APELLIDO1  END,
                            APELLIDO2       = CASE WHEN ISNULL(@Apellido2,'') <> ''  THEN @Apellido2  ELSE APELLIDO2  END,
                            TELEFONOVIVE    = CASE WHEN ISNULL(@TelNatural,'') <> ''  THEN @TelNatural  ELSE TELEFONOVIVE    END,
                            TELEFONOEMPRESA = CASE WHEN ISNULL(@TelEmpresa,'') <> '' THEN @TelEmpresa  ELSE TELEFONOEMPRESA END,
                            EMAIL           = CASE WHEN ISNULL(@Email,'') <> ''      THEN @Email       ELSE EMAIL           END,
                            DIRECCIONVIVE   = CASE WHEN ISNULL(@DirNatural,'') <> '' THEN @DirNatural  ELSE DIRECCIONVIVE   END,
                            DIRECCIONEMPRESA= CASE WHEN ISNULL(@DirEmpresa,'') <> '' THEN @DirEmpresa  ELSE DIRECCIONEMPRESA END,
                            CIUDAD          = CASE WHEN ISNULL(@Ciudad,'') <> ''     THEN @Ciudad     ELSE CIUDAD     END,
                            CIUDADCODIGO    = CASE WHEN ISNULL(@CiudadCodigo,'') <> '' THEN @CiudadCodigo ELSE CIUDADCODIGO END,
                            DEPARTAMENTO    = CASE WHEN ISNULL(@Departamento,'') <> '' THEN @Departamento ELSE DEPARTAMENTO END,
                            DEPARTAMENTOCODIGO = CASE WHEN ISNULL(@DeptCodigo,'') <> '' THEN @DeptCodigo ELSE DEPARTAMENTOCODIGO END
                        WHERE NIT = @NIT
                    ELSE
                        -- No existe: insertar con todos los datos del proveedor
                        INSERT INTO dbo.USUARIOS
                            (NIT, NOMBRE1, NOMBRE2, APELLIDO1, APELLIDO2, EMPRESA,
                             TIPOTERCERO, TIPOID, NITVERIFICA,
                             TELEFONOVIVE, TELEFONOEMPRESA, EMAIL,
                             DIRECCIONVIVE, DIRECCIONEMPRESA,
                             CIUDAD, CIUDADCODIGO, DEPARTAMENTO, DEPARTAMENTOCODIGO,
                             PAIS, PAISCODIGO, PROVEEDOR)
                        VALUES
                            (@NIT, ISNULL(@Nombre1,''), ISNULL(@Nombre2,''),
                             ISNULL(@Apellido1,''), ISNULL(@Apellido2,''),
                             ISNULL(@Empresa,''), @Tipotercero, @Tipoid,
                             ISNULL(@DigitoVerificacion,''),
                             ISNULL(@TelNatural,''), ISNULL(@TelEmpresa,''), ISNULL(@Email,''),
                             ISNULL(@DirNatural,''), ISNULL(@DirEmpresa,''),
                             ISNULL(@Ciudad,''), ISNULL(@CiudadCodigo,''),
                             ISNULL(@Departamento,''), ISNULL(@DeptCodigo,''),
                             'COLOMBIA', 170, 1)",
                    new
                    {
                        NIT                = T(p.NIT, 25),
                        Nombre1            = T(nombre1, 255),
                        Nombre2            = T(nombre2, 50),
                        Apellido1          = T(apellido1, 50),
                        Apellido2          = T(apellido2, 50),
                        Empresa            = T(empresa, 50),
                        Tipotercero        = T(tipotercero, 10),
                        Tipoid             = T(tipoid, 20),
                        DigitoVerificacion = digitoVerificacion?.ToString(),
                        TelNatural         = T(telNatural, 50),
                        TelEmpresa         = T(telEmpresa, 50),
                        Email              = T(emailProv, 50),
                        DirNatural         = T(dirNatural, 200),
                        DirEmpresa         = T(dirEmpresa, 50),
                        Ciudad             = T(p.Ciudad, 50),
                        CiudadCodigo       = T(p.CodigoMuni, 10),
                        Departamento       = T(p.Departamento, 50),
                        DeptCodigo         = T(p.CodigoDept, 10)
                    });

                _logger.LogDebug("Proveedor NIT {NIT} sincronizado a USUARIOS en Visions", p.NIT);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al sincronizar proveedor NIT {NIT} a Visions USUARIOS", p.NIT);
            }
        }

        _logger.LogInformation("Proveedores NEXO → Visions completado");
    }

    // dbo.USUARIOS (PROVEEDOR=1) → NEXO catalogo.Proveedores
    private async Task SincronizarVisionsANexoAsync(CancellationToken ct)
    {
        using var connection = _visionsDb.CreateConnection();

        var usuarios = (await connection.QueryAsync<ProveedorVisions>(
            @"SELECT NIT, TIPOTERCERO, NOMBRE1, NOMBRE2, APELLIDO1, APELLIDO2,
                     EMPRESA, REPRESENTANTE, TELEFONOVIVE, TELEFONOEMPRESA, EMAIL,
                     DIRECCIONVIVE, DIRECCIONEMPRESA, CIUDAD, DEPARTAMENTO,
                     CIUDADCODIGO, DEPARTAMENTOCODIGO
              FROM dbo.USUARIOS
              WHERE PROVEEDOR = 1 AND NIT IS NOT NULL AND NIT <> ''")).ToList();

        if (usuarios.Count == 0) return;

        _logger.LogInformation("Sincronizando {N} proveedores Visions → NEXO", usuarios.Count);

        foreach (var u in usuarios)
        {
            if (ct.IsCancellationRequested) break;

            try
            {
                // Construir RazonSocial: EMPRESA > REPRESENTANTE > NOMBRE1+APELLIDO1
                var razonSocial = !string.IsNullOrWhiteSpace(u.EMPRESA) ? u.EMPRESA
                    : !string.IsNullOrWhiteSpace(u.REPRESENTANTE) ? u.REPRESENTANTE
                    : string.Join(" ", new[] { u.NOMBRE1, u.APELLIDO1 }.Where(s => !string.IsNullOrWhiteSpace(s)));

                // "." es el placeholder que el sync NEXO→Visions pone cuando faltan campos. Usar NIT en ese caso.
                if (string.IsNullOrWhiteSpace(razonSocial) || razonSocial.Trim().All(c => c == '.' || c == ' '))
                    razonSocial = u.NIT;

                if (string.IsNullOrWhiteSpace(razonSocial))
                {
                    _logger.LogDebug("Proveedor NIT {NIT} sin nombre en Visions — omitido del sync a NEXO", u.NIT);
                    continue;
                }

                var esJuridica = (u.TIPOTERCERO ?? "").Contains("JURIDICA", StringComparison.OrdinalIgnoreCase)
                    || !string.IsNullOrWhiteSpace(u.EMPRESA);

                var telProvV = u.TELEFONOEMPRESA ?? u.TELEFONOVIVE;
                var dirProvV = u.DIRECCIONEMPRESA ?? u.DIRECCIONVIVE;

                await _apiClient.SyncProveedorDesdeVisionsAsync(new SyncProveedorDesdeVisionsRequest(
                    NIT:               u.NIT,
                    RazonSocial:       razonSocial,
                    Telefono:          string.IsNullOrWhiteSpace(telProvV) ? "3000000000"       : telProvV,
                    Email:             string.IsNullOrWhiteSpace(u.EMAIL)  ? "default@gmail.com" : u.EMAIL,
                    Direccion:         string.IsNullOrWhiteSpace(dirProvV) ? "default"           : dirProvV,
                    TipoPersona:       esJuridica ? "Juridica" : "Natural",
                    PrimerNombre:      esJuridica ? null : u.NOMBRE1,
                    SegundoNombre:     esJuridica ? null : u.NOMBRE2,
                    PrimerApellido:    esJuridica ? null : u.APELLIDO1,
                    SegundoApellido:   esJuridica ? null : u.APELLIDO2,
                    Departamento:      u.DEPARTAMENTO,
                    Ciudad:            u.CIUDAD,
                    CodigoDept:        u.DEPARTAMENTOCODIGO,
                    CodigoMuni:        u.CIUDADCODIGO
                ), ct);
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al sincronizar proveedor NIT {NIT} desde Visions a NEXO", u.NIT);
            }
        }

        _logger.LogInformation("Proveedores Visions → NEXO completado");
    }

    private static string? T(string? s, int max) => s?.Length > max ? s[..max] : s;

    private record ProveedorVisions(
        string NIT, string? TIPOTERCERO,
        string? NOMBRE1, string? NOMBRE2, string? APELLIDO1, string? APELLIDO2,
        string? EMPRESA, string? REPRESENTANTE,
        string? TELEFONOVIVE, string? TELEFONOEMPRESA, string? EMAIL,
        string? DIRECCIONVIVE, string? DIRECCIONEMPRESA,
        string? CIUDAD, string? DEPARTAMENTO,
        string? CIUDADCODIGO, string? DEPARTAMENTOCODIGO
    );
}
