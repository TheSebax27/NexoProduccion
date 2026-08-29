using Dapper;
using NexoSyncAgent.NexoApiClient;
using NexoSyncAgent.NexoApiClient.Dtos;
using NexoSyncAgent.VisionsData;

namespace NexoSyncAgent.Tareas;

// NEXO → Visions: sincroniza clientes activos de NEXO hacia dbo.USUARIOS en Visions.
// Visions → NEXO: lee dbo.USUARIOS (CLIENTE=1) y los upsertea en NEXO via API.
public class TareaSincronizarClientes
{
    private readonly INexoApiClient _apiClient;
    private readonly IVisionsConnectionFactory _visionsDb;
    private readonly ILogger<TareaSincronizarClientes> _logger;

    public TareaSincronizarClientes(
        INexoApiClient apiClient, IVisionsConnectionFactory visionsDb, ILogger<TareaSincronizarClientes> logger)
    {
        _apiClient = apiClient;
        _visionsDb = visionsDb;
        _logger = logger;
    }

    public async Task EjecutarAsync(DateTime? ultimaSync, CancellationToken ct, bool incluirVisionsANexo = true)
    {
        await SincronizarNexoAVisionsAsync(ultimaSync, ct);
        if (incluirVisionsANexo)
            await SincronizarVisionsANexoAsync(ct);
    }

    // NEXO → dbo.USUARIOS
    private async Task SincronizarNexoAVisionsAsync(DateTime? ultimaSync, CancellationToken ct)
    {
        var clientes = await _apiClient.ListarClientesParaSyncAsync(ultimaSync, ct);
        if (clientes.Count == 0) return;

        _logger.LogInformation("Sincronizando {N} clientes NEXO → Visions USUARIOS", clientes.Count);

        using var connection = _visionsDb.CreateConnection();

        foreach (var c in clientes)
        {
            if (string.IsNullOrWhiteSpace(c.NIT)) continue;

            // Si el cliente fue inactivado en NEXO, solo propagar el de-rol en Visions
            if (!c.Estado)
            {
                try
                {
                    await connection.ExecuteAsync(
                        "UPDATE dbo.USUARIOS SET CLIENTE = 0 WHERE NIT = @NIT",
                        new { NIT = c.NIT });
                    _logger.LogDebug("Cliente NIT {NIT} inactivado en NEXO → CLIENTE=0 en Visions", c.NIT);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error al propagar inactivacion del cliente NIT {NIT} a Visions", c.NIT);
                }
                continue;
            }

            var esJuridica = c.TipoPersona == "Juridica";
            var tipotercero = esJuridica ? "JURIDICA" : "NATURAL";
            // Usar el detalle de tipo de identificación desde NEXO; fallback al tipo de persona
            var tipoid = !string.IsNullOrWhiteSpace(c.TipoIdentificacionDetalle)
                ? c.TipoIdentificacionDetalle
                : (esJuridica ? "NIT" : "CEDULA DE CIUDADANIA");
            var empresa = esJuridica ? c.Nombre : null;
            // Si NEXO no tiene el dígito de verificación, calcularlo desde el NIT.
            var digitoVerificacion = c.DigitoVerificacion
                ?? ColombiaUtils.CalcularDigitoVerificacion(c.NIT);
            var telefono  = string.IsNullOrWhiteSpace(c.Telefono)  ? "3000000000"      : c.Telefono;
            var email     = string.IsNullOrWhiteSpace(c.Email)     ? "default@gmail.com" : c.Email;
            var direccion = string.IsNullOrWhiteSpace(c.Direccion) ? "default"           : c.Direccion;
            // Usar nombres resueltos de Municipios; fallback a los textos libres de Departamento/Ciudad
            var departamento = c.NombreDept ?? c.Departamento;
            var ciudad = c.NombreMuni ?? c.Ciudad;

            // Validar campos obligatorios antes de escribir en Visions
            // (SegundoNombre, SegundoApellido, Telefono, Email y Direccion son opcionales — se usan defaults)
            // Para naturales: si falta apellido, intentar partir el nombre (ej. "Juan Perez" → apellido "Perez").
            // Si tampoco hay espacios, usar "." como placeholder mínimo válido para Visions.
            string? primerApellido = c.PrimerApellido;
            if (!esJuridica && string.IsNullOrWhiteSpace(primerApellido))
            {
                var partes = (c.PrimerNombre ?? "").Trim().Split(' ', StringSplitOptions.RemoveEmptyEntries);
                primerApellido = partes.Length > 1 ? partes[^1] : ".";
            }

            // Jurídica sin nombre: omitir. Natural sin nombre: usar "." como placeholder mínimo aceptado por Visions.
            if (esJuridica && string.IsNullOrWhiteSpace(empresa))
            {
                _logger.LogWarning("Cliente NIT {NIT} omitido del sync a Visions: empresa/razón social vacía", c.NIT);
                continue;
            }
            var primerNombre = !esJuridica && string.IsNullOrWhiteSpace(c.PrimerNombre) ? "." : c.PrimerNombre;
            if (string.IsNullOrWhiteSpace(ciudad))       ciudad       = "SIN DATOS";
            if (string.IsNullOrWhiteSpace(departamento)) departamento = "SIN DATOS";

            try
            {
                // Asignar telefono y direccion segun tipo para evitar CASE WHEN con ambas ramas NULL
                var telNatural  = esJuridica ? null : telefono;
                var telEmpresa  = esJuridica ? telefono : null;
                var dirNatural  = esJuridica ? null : direccion;
                var dirEmpresa  = esJuridica ? direccion : null;

                await connection.ExecuteAsync(@"
                    MERGE dbo.USUARIOS AS dest
                    USING (SELECT @NIT AS NIT) AS src ON dest.NIT = src.NIT
                    WHEN MATCHED THEN UPDATE SET
                        -- Solo sobreescribir si NEXO tiene un valor real; si esta vacio conservar lo que Visions ya tenia
                        NOMBRE1    = CASE WHEN ISNULL(@Nombre1,'') <> ''    THEN @Nombre1    ELSE dest.NOMBRE1    END,
                        NOMBRE2    = CASE WHEN ISNULL(@Nombre2,'') <> ''    THEN @Nombre2    ELSE dest.NOMBRE2    END,
                        APELLIDO1  = CASE WHEN ISNULL(@Apellido1,'') <> ''  THEN @Apellido1  ELSE dest.APELLIDO1  END,
                        APELLIDO2  = CASE WHEN ISNULL(@Apellido2,'') <> ''  THEN @Apellido2  ELSE dest.APELLIDO2  END,
                        EMPRESA    = CASE WHEN ISNULL(@Empresa,'') <> ''    THEN @Empresa    ELSE dest.EMPRESA    END,
                        TIPOTERCERO= CASE WHEN ISNULL(@Tipotercero,'') <> '' THEN @Tipotercero ELSE dest.TIPOTERCERO END,
                        TIPOID     = CASE WHEN ISNULL(@Tipoid,'') <> ''     THEN @Tipoid     ELSE dest.TIPOID     END,
                        NITVERIFICA= CASE WHEN ISNULL(@DigitoVerificacion,'') <> '' THEN @DigitoVerificacion ELSE dest.NITVERIFICA END,
                        EMAIL      = CASE WHEN ISNULL(@Email,'') <> ''      THEN @Email      ELSE dest.EMAIL      END,
                        CIUDAD     = CASE WHEN ISNULL(@Ciudad,'') <> ''     THEN @Ciudad     ELSE dest.CIUDAD     END,
                        CIUDADCODIGO = CASE WHEN ISNULL(@CiudadCodigo,'') <> '' THEN @CiudadCodigo ELSE dest.CIUDADCODIGO END,
                        DEPARTAMENTO = CASE WHEN ISNULL(@Departamento,'') <> '' THEN @Departamento ELSE dest.DEPARTAMENTO END,
                        DEPARTAMENTOCODIGO = CASE WHEN ISNULL(@DeptCodigo,'') <> '' THEN @DeptCodigo ELSE dest.DEPARTAMENTOCODIGO END,
                        PAIS = 'COLOMBIA', PAISCODIGO = 170,
                        TELEFONOVIVE  = CASE WHEN ISNULL(@TelNatural,'') <> ''  THEN @TelNatural  ELSE dest.TELEFONOVIVE  END,
                        TELEFONOEMPRESA = CASE WHEN ISNULL(@TelEmpresa,'') <> '' THEN @TelEmpresa ELSE dest.TELEFONOEMPRESA END,
                        DIRECCIONVIVE   = CASE WHEN ISNULL(@DirNatural,'') <> '' THEN @DirNatural ELSE dest.DIRECCIONVIVE  END,
                        DIRECCIONEMPRESA= CASE WHEN ISNULL(@DirEmpresa,'') <> '' THEN @DirEmpresa ELSE dest.DIRECCIONEMPRESA END,
                        CLIENTE = 1
                    WHEN NOT MATCHED THEN INSERT
                        (NIT, NOMBRE1, NOMBRE2, APELLIDO1, APELLIDO2, EMPRESA, TIPOTERCERO, TIPOID,
                         NITVERIFICA, EMAIL, TELEFONOVIVE, TELEFONOEMPRESA, DIRECCIONVIVE, DIRECCIONEMPRESA,
                         CIUDAD, CIUDADCODIGO, DEPARTAMENTO, DEPARTAMENTOCODIGO, PAIS, PAISCODIGO, CLIENTE)
                    VALUES
                        (@NIT,
                         ISNULL(@Nombre1,''), ISNULL(@Nombre2,''),
                         ISNULL(@Apellido1,''), ISNULL(@Apellido2,''),
                         ISNULL(@Empresa,''), ISNULL(@Tipotercero,''), ISNULL(@Tipoid,''),
                         ISNULL(@DigitoVerificacion,''),
                         ISNULL(@Email,''), ISNULL(@TelNatural,''), ISNULL(@TelEmpresa,''),
                         ISNULL(@DirNatural,''), ISNULL(@DirEmpresa,''),
                         ISNULL(@Ciudad,''), ISNULL(@CiudadCodigo,''),
                         ISNULL(@Departamento,''), ISNULL(@DeptCodigo,''),
                         'COLOMBIA', 170, 1);",
                    new
                    {
                        NIT          = T(c.NIT, 25),
                        Nombre1      = T(esJuridica ? null : primerNombre, 255),
                        Nombre2      = T(esJuridica ? null : c.SegundoNombre, 50),
                        Apellido1    = T(esJuridica ? null : primerApellido, 50),
                        Apellido2    = T(esJuridica ? null : c.SegundoApellido, 50),
                        Empresa      = T(empresa, 50),
                        Tipotercero  = T(tipotercero, 10),
                        Tipoid       = T(tipoid, 20),
                        Email        = T(email, 50),
                        TelNatural   = T(telNatural, 50),
                        TelEmpresa   = T(telEmpresa, 50),
                        DirNatural   = T(dirNatural, 200),
                        DirEmpresa   = T(dirEmpresa, 50),
                        Ciudad       = T(ciudad, 50),
                        CiudadCodigo = T(c.CodigoMuni, 10),
                        Departamento = T(departamento, 50),
                        DeptCodigo   = T(c.CodigoDept, 10),
                        DigitoVerificacion = digitoVerificacion?.ToString()
                    });

                _logger.LogDebug("Cliente NIT {NIT} sincronizado a USUARIOS en Visions", c.NIT);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al sincronizar cliente NIT {NIT} a Visions USUARIOS", c.NIT);
            }
        }

        _logger.LogInformation("Clientes NEXO → Visions completado");
    }


    // dbo.USUARIOS → NEXO
    private async Task SincronizarVisionsANexoAsync(CancellationToken ct)
    {
        using var connection = _visionsDb.CreateConnection();

        var usuarios = (await connection.QueryAsync<UsuarioVisions>(
            @"SELECT NIT, TIPOTERCERO, TIPOID, NOMBRE1, NOMBRE2, APELLIDO1, APELLIDO2,
                     EMPRESA, REPRESENTANTE, TELEFONOVIVE, TELEFONOEMPRESA, EMAIL,
                     DIRECCIONVIVE, DIRECCIONEMPRESA, CIUDAD, DEPARTAMENTO,
                     CIUDADCODIGO, DEPARTAMENTOCODIGO, NITVERIFICA, REGIMEN
              FROM dbo.USUARIOS
              WHERE CLIENTE = 1 AND NIT IS NOT NULL AND NIT <> ''")).ToList();

        if (usuarios.Count == 0) return;

        _logger.LogInformation("Sincronizando {N} usuarios Visions → NEXO", usuarios.Count);

        foreach (var u in usuarios)
        {
            if (ct.IsCancellationRequested) break;

            try
            {
                var esJuridica = (u.TIPOTERCERO ?? "").Contains("JURIDICA", StringComparison.OrdinalIgnoreCase)
                    || !string.IsNullOrWhiteSpace(u.EMPRESA);

                // Cuando NOMBRE1/APELLIDO1/EMPRESA estan vacios en USUARIOS (ej: CONSUMIDOR FINAL,
                // CUANTIAS MENORES), Visions guarda el nombre de pantalla en REPRESENTANTE.
                // Se inyecta como PrimerNombre para que el API lo use directamente como Nombre
                // sin tocar TipoPersona (que viene de TIPOTERCERO en Visions y determina el tipo
                // de identificación que se asigna en NEXO).
                // "." es el placeholder que el sync NEXO→Visions pone cuando faltan campos; tratarlo como vacío.
                var nombre1Real   = EsDotPlaceholder(u.NOMBRE1)   ? null : u.NOMBRE1;
                var apellido1Real = EsDotPlaceholder(u.APELLIDO1) ? null : u.APELLIDO1;
                var empresaReal   = EsDotPlaceholder(u.EMPRESA)   ? null : u.EMPRESA;

                var tieneNombrePersona = !string.IsNullOrWhiteSpace(nombre1Real) || !string.IsNullOrWhiteSpace(apellido1Real);
                var tieneNombreEmpresa = !string.IsNullOrWhiteSpace(empresaReal);
                var usaRepresentante   = !tieneNombrePersona && !tieneNombreEmpresa && !string.IsNullOrWhiteSpace(u.REPRESENTANTE);

                if (!tieneNombrePersona && !tieneNombreEmpresa && !usaRepresentante)
                {
                    // Todos los campos de nombre son "." o vacíos; usar NIT como nombre de display en NEXO.
                    nombre1Real = u.NIT;
                    tieneNombrePersona = true;
                }

                var telVisions  = esJuridica ? (u.TELEFONOEMPRESA ?? u.TELEFONOVIVE) : (u.TELEFONOVIVE ?? u.TELEFONOEMPRESA);
                var dirVisions  = esJuridica ? (u.DIRECCIONEMPRESA ?? u.DIRECCIONVIVE) : (u.DIRECCIONVIVE ?? u.DIRECCIONEMPRESA);

                await _apiClient.SyncClienteDesdeVisionsAsync(new SyncClienteDesdeVisionsRequest(
                    NIT: u.NIT,
                    TipoPersona: esJuridica ? "Juridica" : "Natural",
                    PrimerNombre: usaRepresentante ? u.REPRESENTANTE : nombre1Real,
                    SegundoNombre: usaRepresentante ? null : u.NOMBRE2,
                    PrimerApellido: usaRepresentante ? null : apellido1Real,
                    SegundoApellido: usaRepresentante ? null : u.APELLIDO2,
                    NombreEmpresa: empresaReal,
                    Telefono: string.IsNullOrWhiteSpace(telVisions)  ? "3000000000"      : telVisions,
                    Email:    string.IsNullOrWhiteSpace(u.EMAIL)     ? "default@gmail.com" : u.EMAIL,
                    Direccion: string.IsNullOrWhiteSpace(dirVisions) ? "default"          : dirVisions,
                    Departamento: u.DEPARTAMENTO,
                    Ciudad: u.CIUDAD,
                    CodigoDept: u.DEPARTAMENTOCODIGO,
                    CodigoMuni: u.CIUDADCODIGO,
                    DigitoVerificacion: int.TryParse(u.NITVERIFICA, out var dv) ? dv : null
                ), ct);
            }
            catch (OperationCanceledException)
            {
                // Puede ser el stoppingToken o el timeout del HttpClient; en ambos casos no tiene sentido continuar.
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al sincronizar usuario NIT {NIT} desde Visions a NEXO", u.NIT);
            }
        }

        _logger.LogInformation("Usuarios Visions → NEXO completado");
    }

    private static string? T(string? s, int max) => s?.Length > max ? s[..max] : s;
    private static bool EsDotPlaceholder(string? s) => !string.IsNullOrWhiteSpace(s) && s.Trim() == ".";

    private record UsuarioVisions(
        string NIT, string? TIPOTERCERO, string? TIPOID,
        string? NOMBRE1, string? NOMBRE2, string? APELLIDO1, string? APELLIDO2,
        string? EMPRESA, string? REPRESENTANTE,
        string? TELEFONOVIVE, string? TELEFONOEMPRESA, string? EMAIL,
        string? DIRECCIONVIVE, string? DIRECCIONEMPRESA, string? CIUDAD, string? DEPARTAMENTO,
        string? CIUDADCODIGO, string? DEPARTAMENTOCODIGO, string? NITVERIFICA, string? REGIMEN
    );
}
