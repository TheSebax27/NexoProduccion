using System.Data;
using System.Security.Cryptography;
using System.Text;
using Dapper;
using NexoApi.Common.Data;
using NexoApi.Features.Catalogo;
using NexoApi.Features.Catalogo.Dtos;
using NexoApi.Features.Integracion.Dtos;

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
}

public class IntegracionService : IIntegracionService
{
    private readonly IDbConnectionFactory _db;
    private readonly ICatalogoService _catalogoService;

    public IntegracionService(IDbConnectionFactory db, ICatalogoService catalogoService)
    {
        _db = db;
        _catalogoService = catalogoService;
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
                   a.Nombre AS NombreArticulo, a.PrecioVenta AS PrecioVentaArticulo, a.StockMinimo AS StockMinimoArticulo
            FROM Integracion.EventosSalientes e
            JOIN Organizacion.CentrosCosto cc ON cc.CentroCostoID = e.CentroCostoID
            JOIN Integracion.MapeoArticulos m ON m.ArticuloID = e.ArticuloID AND m.CentroCostoID = e.CentroCostoID
            JOIN Catalogo.Articulos a ON a.ArticuloID = e.ArticuloID
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

        var apiKey = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32));
        var apiKeyHash = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(apiKey)));

        const string sql = @"
            INSERT INTO Integracion.AgentesSync (CentroCostoID, ApiKeyHash, Descripcion)
            OUTPUT INSERTED.AgenteSyncID
            VALUES (@CentroCostoID, @ApiKeyHash, @Descripcion)";

        var id = await connection.ExecuteScalarAsync<int>(sql, new { r.CentroCostoID, ApiKeyHash = apiKeyHash, r.Descripcion });

        return new GenerarApiKeyResponse(id, apiKey);
    }

    public async Task<ConfiguracionAgenteResponse> ObtenerConfiguracionAgenteAsync(int centroCostoId)
    {
        using var connection = _db.CreateConnection();

        // TRY_CAST porque IdentificadorClienteVisions es nvarchar en NEXO (permite
        // texto libre), pero en Visions CENTROCOSTO siempre es numerico (smallint).
        const string sql = @"
            SELECT TRY_CAST(IdentificadorClienteVisions AS INT) AS CentroCostoVisions,
                   Estado AS Activo, PrefijosDocumentoVentaVisions AS PrefijosDocumentoVenta
            FROM Organizacion.CentrosCosto
            WHERE CentroCostoID = @CentroCostoId";

        var resultado = await connection.QuerySingleOrDefaultAsync<ConfiguracionAgenteResponse>(sql, new { CentroCostoId = centroCostoId });

        return resultado ?? throw new KeyNotFoundException($"No existe el centro de costo {centroCostoId}.");
    }

    public async Task<IEnumerable<MapeoArticuloItem>> ListarMapeosAsync(int centroCostoId)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT m.MapeoID, m.ArticuloID, a.SKU AS SkuArticulo, a.Nombre AS NombreArticulo,
                   m.CentroCostoID, m.CodigoArticuloVisions, m.Estado, m.FechaCreacion
            FROM Integracion.MapeoArticulos m
            JOIN Catalogo.Articulos a ON a.ArticuloID = m.ArticuloID
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
            @"SELECT ta.Nombre FROM Catalogo.Articulos a
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
            FROM Catalogo.Articulos a WHERE a.ArticuloID = @ArticuloID";

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
                    INSERT INTO Catalogo.Articulos (SKU, Nombre, TipoArticuloID, PrecioVenta, StockMinimo, PuntoReorden)
                    OUTPUT INSERTED.ArticuloID
                    VALUES (@SKU, @Nombre, @TipoArticuloID, @PrecioVenta, @StockMinimo, @StockMinimo)";

                articuloId = await connection.ExecuteScalarAsync<int>(sqlCrearArticulo, new
                {
                    SKU = r.SkuNuevo,
                    Nombre = r.NombreNuevo,
                    TipoArticuloID = tipoProductoTerminadoId,
                    PrecioVenta = r.PrecioVentaNuevo ?? 0,
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
}