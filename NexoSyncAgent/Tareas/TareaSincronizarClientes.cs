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
            var telefono = c.Telefono;
            var direccion = c.Direccion;
            // Usar nombres resueltos de Municipios; fallback a los textos libres de Departamento/Ciudad
            var departamento = c.NombreDept ?? c.Departamento;
            var ciudad = c.NombreMuni ?? c.Ciudad;

            // Validar campos obligatorios antes de escribir en Visions
            // (SegundoNombre y SegundoApellido son opcionales)
            var camposFaltantes = new List<string>();
            if (esJuridica) { if (string.IsNullOrWhiteSpace(empresa))      camposFaltantes.Add("Empresa/RazonSocial"); }
            else             { if (string.IsNullOrWhiteSpace(c.PrimerNombre))   camposFaltantes.Add("PrimerNombre");
                               if (string.IsNullOrWhiteSpace(c.PrimerApellido)) camposFaltantes.Add("PrimerApellido"); }
            if (string.IsNullOrWhiteSpace(telefono))     camposFaltantes.Add("Telefono");
            if (string.IsNullOrWhiteSpace(direccion))    camposFaltantes.Add("Direccion");
            if (string.IsNullOrWhiteSpace(ciudad))       camposFaltantes.Add("Ciudad");
            if (string.IsNullOrWhiteSpace(departamento)) camposFaltantes.Add("Departamento");
            if (camposFaltantes.Count > 0)
            {
                _logger.LogWarning("Cliente NIT {NIT} omitido del sync a Visions: campos obligatorios vacios en NEXO: {Campos}",
                    c.NIT, string.Join(", ", camposFaltantes));
                continue;
            }

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
                        NIT = c.NIT,
                        Nombre1    = esJuridica ? null : c.PrimerNombre,
                        Nombre2    = esJuridica ? null : c.SegundoNombre,
                        Apellido1  = esJuridica ? null : c.PrimerApellido,
                        Apellido2  = esJuridica ? null : c.SegundoApellido,
                        Empresa    = empresa,
                        Tipotercero = tipotercero,
                        Tipoid     = tipoid,
                        Email      = c.Email,
                        TelNatural = telNatural,
                        TelEmpresa = telEmpresa,
                        DirNatural = dirNatural,
                        DirEmpresa = dirEmpresa,
                        Ciudad     = ciudad,
                        CiudadCodigo = c.CodigoMuni,
                        Departamento = departamento,
                        DeptCodigo   = c.CodigoDept,
                        DigitoVerificacion = c.DigitoVerificacion.HasValue
                            ? c.DigitoVerificacion.Value.ToString()
                            : null
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
                var tieneNombrePersona = !string.IsNullOrWhiteSpace(u.NOMBRE1) || !string.IsNullOrWhiteSpace(u.APELLIDO1);
                var tieneNombreEmpresa = !string.IsNullOrWhiteSpace(u.EMPRESA);
                var usaRepresentante   = !tieneNombrePersona && !tieneNombreEmpresa && !string.IsNullOrWhiteSpace(u.REPRESENTANTE);

                // Solo SegundoNombre (NOMBRE2) y SegundoApellido (APELLIDO2) pueden ir vacíos.
                // Si no hay ningún campo de nombre válido, omitir este registro.
                if (!tieneNombrePersona && !tieneNombreEmpresa && !usaRepresentante)
                {
                    _logger.LogDebug("Usuario NIT {NIT} sin nombre en Visions — omitido del sync a NEXO", u.NIT);
                    continue;
                }

                await _apiClient.SyncClienteDesdeVisionsAsync(new SyncClienteDesdeVisionsRequest(
                    NIT: u.NIT,
                    TipoPersona: esJuridica ? "Juridica" : "Natural",
                    PrimerNombre: usaRepresentante ? u.REPRESENTANTE : u.NOMBRE1,
                    SegundoNombre: usaRepresentante ? null : u.NOMBRE2,
                    PrimerApellido: usaRepresentante ? null : u.APELLIDO1,
                    SegundoApellido: usaRepresentante ? null : u.APELLIDO2,
                    NombreEmpresa: u.EMPRESA,
                    Telefono: esJuridica ? (u.TELEFONOEMPRESA ?? u.TELEFONOVIVE) : (u.TELEFONOVIVE ?? u.TELEFONOEMPRESA),
                    Email: u.EMAIL,
                    Direccion: esJuridica ? (u.DIRECCIONEMPRESA ?? u.DIRECCIONVIVE) : (u.DIRECCIONVIVE ?? u.DIRECCIONEMPRESA),
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

    private record UsuarioVisions(
        string NIT, string? TIPOTERCERO, string? TIPOID,
        string? NOMBRE1, string? NOMBRE2, string? APELLIDO1, string? APELLIDO2,
        string? EMPRESA, string? REPRESENTANTE,
        string? TELEFONOVIVE, string? TELEFONOEMPRESA, string? EMAIL,
        string? DIRECCIONVIVE, string? DIRECCIONEMPRESA, string? CIUDAD, string? DEPARTAMENTO,
        string? CIUDADCODIGO, string? DEPARTAMENTOCODIGO, string? NITVERIFICA, string? REGIMEN
    );
}
