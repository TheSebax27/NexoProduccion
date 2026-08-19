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

    public async Task EjecutarAsync(DateTime? ultimaSync, CancellationToken ct)
    {
        await SincronizarNexoAVisionsAsync(ultimaSync, ct);
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

            var esJuridica = c.TipoPersona == "Juridica";
            var tipotercero = esJuridica ? "JURIDICA" : "NATURAL";
            var tipoid = esJuridica ? "NIT" : "CEDULA DE CIUDADANIA";
            var empresa = esJuridica ? c.Nombre : null;
            var telefono = c.Telefono;
            var direccion = c.Direccion;

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
                        NOMBRE1 = @Nombre1, NOMBRE2 = @Nombre2, APELLIDO1 = @Apellido1, APELLIDO2 = @Apellido2,
                        EMPRESA = @Empresa, TIPOTERCERO = @Tipotercero, TIPOID = @Tipoid,
                        EMAIL = @Email, CIUDAD = @Ciudad, DEPARTAMENTO = @Departamento,
                        TELEFONOVIVE = @TelNatural, TELEFONOEMPRESA = @TelEmpresa,
                        DIRECCIONVIVE = @DirNatural, DIRECCIONEMPRESA = @DirEmpresa,
                        CLIENTE = 1
                    WHEN NOT MATCHED THEN INSERT
                        (NIT, NOMBRE1, NOMBRE2, APELLIDO1, APELLIDO2, EMPRESA, TIPOTERCERO, TIPOID,
                         EMAIL, TELEFONOVIVE, TELEFONOEMPRESA, DIRECCIONVIVE, DIRECCIONEMPRESA,
                         CIUDAD, DEPARTAMENTO, CLIENTE)
                    VALUES
                        (@NIT, @Nombre1, @Nombre2, @Apellido1, @Apellido2, @Empresa, @Tipotercero, @Tipoid,
                         @Email, @TelNatural, @TelEmpresa, @DirNatural, @DirEmpresa,
                         @Ciudad, @Departamento, 1);",
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
                        Ciudad     = c.Ciudad,
                        Departamento = c.Departamento
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
            @"SELECT NIT, TIPOTERCERO, NOMBRE1, NOMBRE2, APELLIDO1, APELLIDO2,
                     EMPRESA, TELEFONOVIVE, TELEFONOEMPRESA, EMAIL,
                     DIRECCIONVIVE, DIRECCIONEMPRESA, CIUDAD, DEPARTAMENTO
              FROM dbo.USUARIOS
              WHERE CLIENTE = 1 AND NIT IS NOT NULL AND NIT <> ''")).ToList();

        if (usuarios.Count == 0) return;

        _logger.LogInformation("Sincronizando {N} usuarios Visions → NEXO", usuarios.Count);

        foreach (var u in usuarios)
        {
            try
            {
                var esJuridica = (u.TIPOTERCERO ?? "").Contains("JURIDICA", StringComparison.OrdinalIgnoreCase)
                    || !string.IsNullOrWhiteSpace(u.EMPRESA);

                await _apiClient.SyncClienteDesdeVisionsAsync(new SyncClienteDesdeVisionsRequest(
                    NIT: u.NIT,
                    TipoPersona: esJuridica ? "Juridica" : "Natural",
                    PrimerNombre: u.NOMBRE1,
                    SegundoNombre: u.NOMBRE2,
                    PrimerApellido: u.APELLIDO1,
                    SegundoApellido: u.APELLIDO2,
                    NombreEmpresa: u.EMPRESA,
                    Telefono: u.TELEFONOVIVE ?? u.TELEFONOEMPRESA,
                    Email: u.EMAIL,
                    Direccion: u.DIRECCIONVIVE ?? u.DIRECCIONEMPRESA,
                    Departamento: u.DEPARTAMENTO,
                    Ciudad: u.CIUDAD
                ), ct);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al sincronizar usuario NIT {NIT} desde Visions a NEXO", u.NIT);
            }
        }

        _logger.LogInformation("Usuarios Visions → NEXO completado");
    }

    private record UsuarioVisions(
        string NIT, string? TIPOTERCERO,
        string? NOMBRE1, string? NOMBRE2, string? APELLIDO1, string? APELLIDO2, string? EMPRESA,
        string? TELEFONOVIVE, string? TELEFONOEMPRESA, string? EMAIL,
        string? DIRECCIONVIVE, string? DIRECCIONEMPRESA, string? CIUDAD, string? DEPARTAMENTO
    );
}
