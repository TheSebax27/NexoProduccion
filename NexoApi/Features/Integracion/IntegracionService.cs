using System.Data;
using System.IO.Compression;
using System.Security.Cryptography;
using System.Text;
using Dapper;
using Microsoft.Extensions.Caching.Memory;
using NexoApi.Common.Data;
using NexoApi.Features.Catalogo;
using NexoApi.Features.Catalogo.Dtos;
using NexoApi.Features.Integracion.Dtos;
using Microsoft.Extensions.Configuration;

namespace NexoApi.Features.Integracion;

public interface IIntegracionService
{
    Task<IEnumerable<EventoPendienteItem>> ObtenerEventosPendientesAsync(int centroCostoId);
    Task ConfirmarEventoSalienteAsync(long eventoId, int centroCostoId);
    Task RegistrarEventoEntranteAsync(RegistrarEventoEntranteRequest request, int centroCostoId);
    Task<GenerarApiKeyResponse> GenerarApiKeyAsync(GenerarApiKeyRequest request);
    Task<ConfiguracionAgenteResponse> ObtenerConfiguracionAgenteAsync(int centroCostoId);
    Task<IEnumerable<MapeoArticuloItem>> ListarMapeosAsync(int centroCostoId);
    Task CrearMapeoAsync(CrearMapeoArticuloRequest request);
    Task<IEnumerable<ArticuloPendienteMapeoItem>> ListarArticulosPendientesMapeoAsync(int centroCostoId);
    Task ResolverArticuloPendienteAsync(int pendienteId, ResolverArticuloPendienteRequest request);
    Task<LatidoResponse> RegistrarLatidoAsync(int centroCostoId);
    Task<IEnumerable<EstadoIntegracionResponse>> ObtenerEstadoIntegracionAsync();
    Task RegistrarFalloEventoAsync(long eventoId, int centroCostoId, string mensajeError);
    Task<ConfiguracionAgenteCompletaResponse> ObtenerConfiguracionCompletaAsync(int agenteSyncId);
    Task ActualizarConfiguracionCompletaAsync(int agenteSyncId, ActualizarConfiguracionAgenteRequest request);
    string GenerarAppsettingsJson(ConfiguracionAgenteCompletaResponse config, string apiKey);
    Task<string> PrepararAppsettingsConKeyFrescaAsync(int agenteSyncId);
    Task<string> PrepararDescargaInstaladorAsync(int agenteSyncId);
    byte[]? ObtenerPaqueteInstalador(string token);
    Task DesactivarAgenteAsync(int agenteSyncId);
}

public class IntegracionService : IIntegracionService
{
    private readonly IDbConnectionFactory _db;
    private readonly ICatalogoService _catalogoService;
    private readonly IMemoryCache _cache;
    private readonly IConfiguration _config;

    public IntegracionService(IDbConnectionFactory db, ICatalogoService catalogoService, IMemoryCache cache, IConfiguration config)
    {
        _db = db;
        _catalogoService = catalogoService;
        _cache = cache;
        _config = config;
    }

    public async Task<IEnumerable<EventoPendienteItem>> ObtenerEventosPendientesAsync(int centroCostoId)
    {
        using var connection = _db.CreateConnection();

        // Nombre/PrecioVenta/StockMinimo del articulo se traen siempre (aunque
        // solo los use el TipoEvento 'SINCRONIZAR_ARTICULO') porque es mas
        // simple que hacer un JOIN condicional -- el agente los ignora en los
        // demas tipos de evento.
        const string sql = @"
            SELECT e.EventoID, e.TipoEvento, e.Cantidad, e.CostoUnitario, e.FechaCreacion,
                   cc.IdentificadorClienteVisions AS CentroCostoVisions,
                   m.CodigoArticuloVisions AS ReferenciaVisions,
                   a.Nombre AS NombreArticulo, a.PPublico AS PrecioVentaArticulo, a.StockMinimo AS StockMinimoArticulo
            FROM Integracion.EventosSalientes e
            JOIN Organizacion.CentrosCosto cc ON cc.CentroCostoID = e.CentroCostoID
            JOIN Integracion.MapeoArticulos m ON m.ArticuloID = e.ArticuloID AND m.CentroCostoID = e.CentroCostoID
            JOIN Catalogo.Tarjetas a ON a.ArticuloID = e.ArticuloID
            WHERE e.Estado = 'PENDIENTE' AND e.CentroCostoID = @CentroCostoId";

        return await connection.QueryAsync<EventoPendienteItem>(sql, new { CentroCostoId = centroCostoId });
    }

    public async Task ConfirmarEventoSalienteAsync(long eventoId, int centroCostoId)
    {
        using var connection = _db.CreateConnection();

        // El filtro AND CentroCostoID = @CentroCostoId no es decorativo: es lo
        // que impide que el agente de un cliente pueda confirmar (o espiar)
        // eventos que pertenecen a otro cliente, aunque adivinara un EventoID.
        const string sql = @"
            UPDATE Integracion.EventosSalientes
            SET Estado = 'CONFIRMADO', FechaEnvio = SYSUTCDATETIME()
            WHERE EventoID = @EventoId AND CentroCostoID = @CentroCostoId AND Estado = 'PENDIENTE'";

        var filas = await connection.ExecuteAsync(sql, new { EventoId = eventoId, CentroCostoId = centroCostoId });

        if (filas == 0)
            throw new KeyNotFoundException("El evento no existe, no pertenece a este agente, o ya fue confirmado.");
    }

    private record EventoEntranteExistente(long EventoEntranteID, bool Procesado);

    public async Task RegistrarEventoEntranteAsync(RegistrarEventoEntranteRequest r, int centroCostoId)
    {
        using var connection = _db.CreateConnection();

        var existente = await connection.QuerySingleOrDefaultAsync<EventoEntranteExistente>(
            "SELECT EventoEntranteID, Procesado FROM Integracion.EventosEntrantes WHERE IdEventoExterno = @IdEventoExterno",
            new { r.IdEventoExterno });

        // Ya se proceso exitosamente antes (idempotencia real: el agente
        // reenvio por un corte de internet, por ejemplo) -- no hay nada que hacer.
        if (existente is not null && existente.Procesado)
            return;

        long eventoEntranteId;

        if (existente is not null)
        {
            // Ya existia pero se habia quedado sin procesar (ej. la primera vez
            // fallo por falta de mapeo de articulo) -- NO se vuelve a insertar,
            // se reintenta el mismo EventoEntranteID. Antes de agosto 2026 este
            // caso se trataba igual que "ya procesado" y el evento quedaba
            // atascado para siempre, incluso despues de arreglar el mapeo.
            eventoEntranteId = existente.EventoEntranteID;
        }
        else
        {
            const string sqlInsert = @"
                INSERT INTO Integracion.EventosEntrantes
                    (IdEventoExterno, TipoEvento, CentroCostoID, CodigoArticuloVisions, Cantidad, FechaEventoOrigen,
                     NombreArticuloVisions, CostoArticuloVisions, PrecioArticuloVisions)
                OUTPUT INSERTED.EventoEntranteID
                VALUES (@IdEventoExterno, @TipoEvento, @CentroCostoId, @CodigoArticuloVisions, @Cantidad, @FechaEventoOrigen,
                        @NombreArticuloVisions, @CostoArticuloVisions, @PrecioArticuloVisions)";

            eventoEntranteId = await connection.ExecuteScalarAsync<long>(sqlInsert, new
            {
                r.IdEventoExterno,
                r.TipoEvento,
                CentroCostoId = centroCostoId,
                r.CodigoArticuloVisions,
                r.Cantidad,
                r.FechaEventoOrigen,
                r.NombreArticuloVisions,
                r.CostoArticuloVisions,
                r.PrecioArticuloVisions
            });
        }

        var parametros = new DynamicParameters();
        parametros.Add("EventoEntranteID", eventoEntranteId);

        await connection.ExecuteAsync(
            "Integracion.sp_ProcesarEventoEntrante",
            parametros,
            commandType: CommandType.StoredProcedure);
    }

    public async Task<GenerarApiKeyResponse> GenerarApiKeyAsync(GenerarApiKeyRequest r)
    {
        using var connection = _db.CreateConnection();

        var apiKey    = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32));
        var apiKeyHash = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(apiKey)));

        // Upsert: si ya existe un agente activo para este CentroCosto se regenera
        // su clave en lugar de crear un registro nuevo -- garantiza 1 agente por CentroCosto.
        var existingId = await connection.ExecuteScalarAsync<int?>(
            @"SELECT TOP 1 AgenteSyncID FROM Integracion.AgentesSync
              WHERE CentroCostoID = @CentroCostoID AND Activo = 1
              ORDER BY AgenteSyncID DESC",
            new { r.CentroCostoID });

        if (existingId.HasValue)
        {
            await connection.ExecuteAsync(
                @"UPDATE Integracion.AgentesSync
                  SET ApiKeyHash = @ApiKeyHash, Descripcion = @Descripcion
                  WHERE AgenteSyncID = @AgenteSyncID",
                new { ApiKeyHash = apiKeyHash, r.Descripcion, AgenteSyncID = existingId.Value });
            return new GenerarApiKeyResponse(existingId.Value, apiKey);
        }

        var id = await connection.ExecuteScalarAsync<int>(
            @"INSERT INTO Integracion.AgentesSync (CentroCostoID, ApiKeyHash, Descripcion)
              OUTPUT INSERTED.AgenteSyncID
              VALUES (@CentroCostoID, @ApiKeyHash, @Descripcion)",
            new { r.CentroCostoID, ApiKeyHash = apiKeyHash, r.Descripcion });

        return new GenerarApiKeyResponse(id, apiKey);
    }

    public async Task<ConfiguracionAgenteResponse> ObtenerConfiguracionAgenteAsync(int centroCostoId)
    {
        using var connection = _db.CreateConnection();

        // TRY_CAST porque IdentificadorClienteVisions es nvarchar en NEXO (permite
        // texto libre), pero en Visions CENTROCOSTO siempre es numerico (smallint).
        // IntervalMinutes viene de AgentesSync -- el agente usa el valor guardado en DB
        // en vez de appsettings.json para que el admin pueda cambiarlo desde la web.
        const string sql = @"
            SELECT TRY_CAST(cc.IdentificadorClienteVisions AS INT) AS CentroCostoVisions,
                   cc.Estado AS Activo,
                   cc.PrefijosDocumentoVentaVisions AS PrefijosDocumentoVenta,
                   ISNULL(a.IntervalMinutes, 5) AS IntervalMinutes
            FROM Organizacion.CentrosCosto cc
            LEFT JOIN Integracion.AgentesSync a
                   ON a.CentroCostoID = cc.CentroCostoID AND a.Activo = 1
            WHERE cc.CentroCostoID = @CentroCostoId";

        var resultado = await connection.QuerySingleOrDefaultAsync<ConfiguracionAgenteResponse>(sql, new { CentroCostoId = centroCostoId });

        return resultado ?? throw new KeyNotFoundException($"No existe el centro de costo {centroCostoId}.");
    }

    public async Task<IEnumerable<MapeoArticuloItem>> ListarMapeosAsync(int centroCostoId)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT m.MapeoID, m.ArticuloID, a.Referencia AS SkuArticulo, a.Nombre AS NombreArticulo,
                   m.CentroCostoID, m.CodigoArticuloVisions, m.Estado, m.FechaCreacion
            FROM Integracion.MapeoArticulos m
            JOIN Catalogo.Tarjetas a ON a.ArticuloID = m.ArticuloID
            WHERE m.CentroCostoID = @CentroCostoId
            ORDER BY a.Nombre";

        return await connection.QueryAsync<MapeoArticuloItem>(sql, new { CentroCostoId = centroCostoId });
    }

    public async Task CrearMapeoAsync(CrearMapeoArticuloRequest r)
    {
        using var connection = _db.CreateConnection();

        // Visions es un sistema de punto de venta: solo tiene sentido mapear
        // Producto Terminado (lo unico que se vende ahi). Materia Prima,
        // Insumos y Servicios se quedan solo en NEXO.
        var tipoArticulo = await connection.ExecuteScalarAsync<string?>(
            @"SELECT ta.Nombre FROM Catalogo.Tarjetas a
              JOIN Catalogo.TiposArticulo ta ON ta.TipoArticuloID = a.TipoArticuloID
              WHERE a.ArticuloID = @ArticuloID", new { r.ArticuloID });

        if (tipoArticulo != "Producto Terminado")
            throw new InvalidOperationException("Solo se pueden mapear articulos de tipo Producto Terminado hacia Visions.");

        const string sqlInsert = @"
            INSERT INTO Integracion.MapeoArticulos (ArticuloID, CentroCostoID, CodigoArticuloVisions)
            VALUES (@ArticuloID, @CentroCostoID, @CodigoArticuloVisions)";

        await connection.ExecuteAsync(sqlInsert, r);

        await EncolarSincronizacionArticuloAsync(connection, r.ArticuloID, r.CentroCostoID);
    }

    // Encola el evento saliente que hace que el Agente cree/actualice el
    // articulo en dbo.TARJETA de Visions (nombre, costo, precio publico,
    // existencias minimas -- nunca la cantidad de stock, eso va por el evento
    // de entradas de inventario, no por este).
    private static async Task EncolarSincronizacionArticuloAsync(IDbConnection connection, int articuloId, int centroCostoId)
    {
        const string sql = @"
            INSERT INTO Integracion.EventosSalientes (TipoEvento, CentroCostoID, ArticuloID, Cantidad, CostoUnitario)
            SELECT 'SINCRONIZAR_ARTICULO', @CentroCostoID, @ArticuloID, 0, a.CostoPromedio
            FROM Catalogo.Tarjetas a WHERE a.ArticuloID = @ArticuloID";

        await connection.ExecuteAsync(sql, new { ArticuloID = articuloId, CentroCostoID = centroCostoId });
    }

    public async Task<IEnumerable<ArticuloPendienteMapeoItem>> ListarArticulosPendientesMapeoAsync(int centroCostoId)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT PendienteID, CentroCostoID, CodigoArticuloVisions, NombreVisions, CostoVisions, PrecioVisions,
                   CantidadDetectada, FechaDetectado
            FROM Integracion.ArticulosPendientesMapeo
            WHERE CentroCostoID = @CentroCostoId AND Resuelto = 0
            ORDER BY FechaDetectado DESC";

        return await connection.QueryAsync<ArticuloPendienteMapeoItem>(sql, new { CentroCostoId = centroCostoId });
    }

    private record PendienteMapeoBasico(int CentroCostoID, string CodigoArticuloVisions);

    public async Task ResolverArticuloPendienteAsync(int pendienteId, ResolverArticuloPendienteRequest r)
    {
        using var connection = _db.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();

        try
        {
            var pendiente = await connection.QuerySingleOrDefaultAsync<PendienteMapeoBasico>(
                "SELECT CentroCostoID, CodigoArticuloVisions FROM Integracion.ArticulosPendientesMapeo WHERE PendienteID = @PendienteID AND Resuelto = 0",
                new { PendienteID = pendienteId }, transaction);

            if (pendiente is null)
                throw new KeyNotFoundException($"No existe (o ya se resolvio) el articulo pendiente {pendienteId}.");

            int articuloId;

            if (r.ArticuloIDExistente is not null)
            {
                articuloId = r.ArticuloIDExistente.Value;
            }
            else
            {
                if (string.IsNullOrWhiteSpace(r.SkuNuevo) || string.IsNullOrWhiteSpace(r.NombreNuevo))
                    throw new InvalidOperationException("Falta SKU o Nombre para crear el articulo nuevo.");

                var tipoProductoTerminadoId = await connection.ExecuteScalarAsync<int>(
                    "SELECT TipoArticuloID FROM Catalogo.TiposArticulo WHERE Nombre = 'Producto Terminado'", transaction: transaction);

                var stockMinimo = r.StockMinimoNuevo ?? 0;

                const string sqlCrearArticulo = @"
                    INSERT INTO Catalogo.Tarjetas (Referencia, Nombre, TipoArticuloID, PPublico, StockMinimo, PuntoReorden)
                    OUTPUT INSERTED.ArticuloID
                    VALUES (@Referencia, @Nombre, @TipoArticuloID, @PPublico, @StockMinimo, @StockMinimo)";

                articuloId = await connection.ExecuteScalarAsync<int>(sqlCrearArticulo, new
                {
                    Referencia = r.SkuNuevo,
                    Nombre = r.NombreNuevo,
                    TipoArticuloID = tipoProductoTerminadoId,
                    PPublico = r.PrecioVentaNuevo ?? 0,
                    StockMinimo = stockMinimo
                }, transaction);
            }

            const string sqlMapeo = @"
                INSERT INTO Integracion.MapeoArticulos (ArticuloID, CentroCostoID, CodigoArticuloVisions)
                VALUES (@ArticuloID, @CentroCostoID, @CodigoArticuloVisions)";

            await connection.ExecuteAsync(sqlMapeo, new
            {
                ArticuloID = articuloId,
                pendiente.CentroCostoID,
                pendiente.CodigoArticuloVisions
            }, transaction);

            await connection.ExecuteAsync(
                "UPDATE Integracion.ArticulosPendientesMapeo SET Resuelto = 1, FechaResuelto = SYSUTCDATETIME() WHERE PendienteID = @PendienteID",
                new { PendienteID = pendienteId }, transaction);

            transaction.Commit();
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public async Task<LatidoResponse> RegistrarLatidoAsync(int centroCostoId)
    {
        using var connection = _db.CreateConnection();

        // Actualiza UltimaConexion y UltimoLatido en el AgentesSync de este centro.
        var parametros = new DynamicParameters();
        parametros.Add("AgenteSyncID", await ObtenerAgenteSyncIdAsync(connection, centroCostoId));
        await connection.ExecuteAsync("Integracion.sp_RegistrarLatido", parametros, commandType: CommandType.StoredProcedure);

        var pendientes = await connection.ExecuteScalarAsync<int>(
            "SELECT COUNT(*) FROM Integracion.EventosSalientes WHERE Estado = 'PENDIENTE' AND CentroCostoID = @CentroCostoId",
            new { CentroCostoId = centroCostoId });

        return new LatidoResponse(DateTime.UtcNow, pendientes);
    }

    private static async Task<int> ObtenerAgenteSyncIdAsync(System.Data.IDbConnection connection, int centroCostoId)
    {
        var id = await connection.ExecuteScalarAsync<int?>(
            "SELECT TOP 1 AgenteSyncID FROM Integracion.AgentesSync WHERE CentroCostoID = @CentroCostoId AND Activo = 1 ORDER BY AgenteSyncID DESC",
            new { CentroCostoId = centroCostoId });
        return id ?? throw new KeyNotFoundException($"No hay agente activo para el centro de costo {centroCostoId}.");
    }

    private record EstadoFila(
        int AgenteSyncID, string Descripcion, int CentroCostoID, string NombreCentroCosto,
        bool Activo, DateTime? UltimoLatido, string? VersionAgente);

    public async Task<IEnumerable<EstadoIntegracionResponse>> ObtenerEstadoIntegracionAsync()
    {
        using var connection = _db.CreateConnection();

        const string sqlAgentes = @"
            SELECT a.AgenteSyncID, a.Descripcion, a.CentroCostoID, cc.Nombre AS NombreCentroCosto,
                   a.Activo, a.UltimoLatido, a.VersionAgente
            FROM Integracion.AgentesSync a
            JOIN Organizacion.CentrosCosto cc ON cc.CentroCostoID = a.CentroCostoID
            ORDER BY a.UltimoLatido DESC";

        var agentes = (await connection.QueryAsync<EstadoFila>(sqlAgentes)).ToList();
        var resultado = new List<EstadoIntegracionResponse>();
        var hoy = DateTime.UtcNow.Date;

        foreach (var ag in agentes)
        {
            var pendientes = await connection.ExecuteScalarAsync<int>(
                "SELECT COUNT(*) FROM Integracion.EventosSalientes WHERE Estado = 'PENDIENTE' AND CentroCostoID = @Id",
                new { Id = ag.CentroCostoID });

            var procesadosHoy = await connection.ExecuteScalarAsync<int>(
                "SELECT COUNT(*) FROM Integracion.EventosSalientes WHERE Estado = 'CONFIRMADO' AND CentroCostoID = @Id AND CAST(FechaEnvio AS DATE) = @Hoy",
                new { Id = ag.CentroCostoID, Hoy = hoy });

            var ventasHoy = await connection.ExecuteScalarAsync<int>(
                "SELECT COUNT(*) FROM Integracion.EventosEntrantes WHERE TipoEvento = 'VENTA' AND CentroCostoID = @Id AND Procesado = 1 AND CAST(FechaRecepcion AS DATE) = @Hoy",
                new { Id = ag.CentroCostoID, Hoy = hoy });

            var conError = await connection.ExecuteScalarAsync<int>(
                "SELECT COUNT(*) FROM Integracion.EventosSalientes WHERE Estado = 'ERROR' AND CentroCostoID = @Id",
                new { Id = ag.CentroCostoID });

            resultado.Add(new EstadoIntegracionResponse(
                ag.AgenteSyncID, ag.Descripcion, ag.CentroCostoID, ag.NombreCentroCosto,
                ag.Activo, ag.UltimoLatido, ag.VersionAgente,
                pendientes, procesadosHoy, ventasHoy, conError));
        }

        return resultado;
    }

    public async Task RegistrarFalloEventoAsync(long eventoId, int centroCostoId, string mensajeError)
    {
        using var connection = _db.CreateConnection();

        var mensaje = mensajeError.Length > 500 ? mensajeError[..500] : mensajeError;

        const string sql = @"
            UPDATE Integracion.EventosSalientes
            SET IntentosEnvio  = IntentosEnvio + 1,
                UltimoError    = @Mensaje,
                Estado         = CASE WHEN IntentosEnvio + 1 >= 3 THEN 'ERROR' ELSE Estado END
            WHERE EventoID = @EventoId AND CentroCostoID = @CentroCostoId AND Estado = 'PENDIENTE'";

        await connection.ExecuteAsync(sql, new { EventoId = eventoId, CentroCostoId = centroCostoId, Mensaje = mensaje });
    }

    public async Task<ConfiguracionAgenteCompletaResponse> ObtenerConfiguracionCompletaAsync(int agenteSyncId)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT a.AgenteSyncID, a.Descripcion, a.CentroCostoID, cc.Nombre AS NombreCentroCosto,
                   a.Activo, a.VisionsDbConexion, a.NexoApiBaseUrl, a.IntervalMinutes, a.AgentePath
            FROM Integracion.AgentesSync a
            JOIN Organizacion.CentrosCosto cc ON cc.CentroCostoID = a.CentroCostoID
            WHERE a.AgenteSyncID = @AgenteSyncId";

        var resultado = await connection.QuerySingleOrDefaultAsync<ConfiguracionAgenteCompletaResponse>(
            sql, new { AgenteSyncId = agenteSyncId });

        return resultado ?? throw new KeyNotFoundException($"No existe el agente {agenteSyncId}.");
    }

    public async Task ActualizarConfiguracionCompletaAsync(int agenteSyncId, ActualizarConfiguracionAgenteRequest r)
    {
        using var connection = _db.CreateConnection();

        // NexoApiBaseUrl siempre se toma del servidor — el cliente no tiene que escribirla.
        var nexoApiUrl = _config["NexoApi:BaseUrl"]?.TrimEnd('/') + "/";

        const string sql = @"
            UPDATE Integracion.AgentesSync
            SET VisionsDbConexion = @VisionsDbConexion,
                NexoApiBaseUrl    = @NexoApiBaseUrl,
                IntervalMinutes   = @IntervalMinutes,
                AgentePath        = @AgentePath
            WHERE AgenteSyncID = @AgenteSyncId";

        var filas = await connection.ExecuteAsync(sql, new
        {
            AgenteSyncId         = agenteSyncId,
            r.VisionsDbConexion,
            NexoApiBaseUrl       = nexoApiUrl,
            r.IntervalMinutes,
            r.AgentePath
        });

        if (filas == 0)
            throw new KeyNotFoundException($"No existe el agente {agenteSyncId}.");
    }

    public async Task DesactivarAgenteAsync(int agenteSyncId)
    {
        using var connection = _db.CreateConnection();
        var filas = await connection.ExecuteAsync(
            "UPDATE Integracion.AgentesSync SET Activo = 0 WHERE AgenteSyncID = @Id",
            new { Id = agenteSyncId });
        if (filas == 0)
            throw new KeyNotFoundException($"No existe el agente {agenteSyncId}.");
    }

    // Formato del EXE combinado generado para el cliente:
    // [NexoInstaladorAgente.exe] + [appsettings UTF-8] + [int32: settings_len]
    // + [NexoSyncAgent.exe] + [int64: agent_len] + ["NEXO_SETUP_V1" 13 bytes]
    private const string InstallerMagic = "NEXO_SETUP_V1";

    public async Task<string> PrepararDescargaInstaladorAsync(int agenteSyncId)
    {
        var origenDir = Path.Combine(AppContext.BaseDirectory, "Agent");
        if (!Directory.Exists(origenDir))
        {
            // En desarrollo (Debug) no existe Agent/ en bin\Debug; usar NexoSyncAgent\publish\ junto a la solución.
            var devFallback = Path.GetFullPath(
                Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", "NexoSyncAgent", "publish"));
            if (Directory.Exists(devFallback))
                origenDir = devFallback;
            else
                throw new InvalidOperationException(
                    "El agente no está bundled. En desarrollo ejecuta 'dotnet publish NexoSyncAgent' primero.");
        }

        var installerPath = Path.Combine(origenDir, "NexoInstaladorAgente.exe");
        var agentPath     = Path.Combine(origenDir, "NexoSyncAgent.exe");

        if (!File.Exists(installerPath) || !File.Exists(agentPath))
            throw new InvalidOperationException(
                "Faltan archivos en la carpeta Agent/ del servidor. Republica NexoApi.");

        // Generar API Key fresca y actualizar hash en BD.
        using var connection = _db.CreateConnection();
        var apiKey     = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32));
        var apiKeyHash = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(apiKey)));
        await connection.ExecuteAsync(
            "UPDATE Integracion.AgentesSync SET ApiKeyHash = @ApiKeyHash WHERE AgenteSyncID = @AgenteSyncId",
            new { ApiKeyHash = apiKeyHash, AgenteSyncId = agenteSyncId });

        var config          = await ObtenerConfiguracionCompletaAsync(agenteSyncId);
        var settingsBytes   = Encoding.UTF8.GetBytes(GenerarAppsettingsJson(config, apiKey));
        var installerBytes  = await File.ReadAllBytesAsync(installerPath);
        var agentBytes      = await File.ReadAllBytesAsync(agentPath);
        var magicBytes      = Encoding.ASCII.GetBytes(InstallerMagic);

        // Ensamblar el EXE combinado en memoria.
        using var ms = new MemoryStream(
            installerBytes.Length + settingsBytes.Length + 4 + agentBytes.Length + 8 + magicBytes.Length);
        await ms.WriteAsync(installerBytes);
        await ms.WriteAsync(settingsBytes);
        await ms.WriteAsync(BitConverter.GetBytes(settingsBytes.Length));  // int32
        await ms.WriteAsync(agentBytes);
        await ms.WriteAsync(BitConverter.GetBytes((long)agentBytes.Length)); // int64
        await ms.WriteAsync(magicBytes);

        // Guardar en caché con token de un solo uso (10 min).
        var token = Guid.NewGuid().ToString("N");
        _cache.Set(token, ms.ToArray(), TimeSpan.FromMinutes(10));
        return token;
    }

    public byte[]? ObtenerPaqueteInstalador(string token)
    {
        if (!_cache.TryGetValue(token, out byte[]? bytes)) return null;
        _cache.Remove(token); // un solo uso
        return bytes;
    }

    public async Task<string> PrepararAppsettingsConKeyFrescaAsync(int agenteSyncId)
    {
        using var connection = _db.CreateConnection();
        var apiKey     = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32));
        var apiKeyHash = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(apiKey)));
        await connection.ExecuteAsync(
            "UPDATE Integracion.AgentesSync SET ApiKeyHash = @ApiKeyHash WHERE AgenteSyncID = @AgenteSyncId",
            new { ApiKeyHash = apiKeyHash, AgenteSyncId = agenteSyncId });

        var config = await ObtenerConfiguracionCompletaAsync(agenteSyncId);
        return GenerarAppsettingsJson(config, apiKey);
    }

    public string GenerarAppsettingsJson(ConfiguracionAgenteCompletaResponse config, string apiKey)
    {
        var intervalo   = config.IntervalMinutes > 0 ? config.IntervalMinutes : 5;
        var serverName  = config.VisionsDbConexion ?? "SERVIDOR\\INSTANCIA";
        var db          = $"Server={serverName};Database=VISIONSDBL1;Trusted_Connection=True;TrustServerCertificate=True;";
        var url         = (config.NexoApiBaseUrl ?? _config["NexoApi:BaseUrl"] ?? "https://nexo.mi-empresa.com/").TrimEnd('/') + "/";

        return $$"""
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.Hosting.Lifetime": "Information"
    }
  },
  "ConnectionStrings": {
    "VisionsDb": "{{db}}"
  },
  "NexoApi": {
    "BaseUrl": "{{url}}",
    "ApiKey": "{{apiKey}}"
  },
  "Sync": {
    "IntervalMinutes": {{intervalo}},
    "IntervalSeconds": 0
  }
}
""";
    }
}