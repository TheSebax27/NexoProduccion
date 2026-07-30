using Dapper;
using NexoSyncAgent.NexoApiClient;
using NexoSyncAgent.NexoApiClient.Dtos;
using NexoSyncAgent.VisionsData;

namespace NexoSyncAgent.Tareas;

public class TareaExportarVentas
{
    private record VentaPendiente(short CENTROCOSTO, string TIPDOC, string NRODOC, decimal ORDEN, string REFERENCIA, decimal CANTIDAD, DateTime FECDOC);

    private readonly INexoApiClient _apiClient;
    private readonly IVisionsConnectionFactory _visionsDb;
    private readonly ILogger<TareaExportarVentas> _logger;

    public TareaExportarVentas(
        INexoApiClient apiClient, IVisionsConnectionFactory visionsDb, ILogger<TareaExportarVentas> logger)
    {
        _apiClient = apiClient;
        _visionsDb = visionsDb;
        _logger = logger;
    }

    public async Task EjecutarAsync(CancellationToken ct)
    {
        using var connection = _visionsDb.CreateConnection();

        const string sqlVentasNuevas = @"
            SELECT m.CENTROCOSTO, m.TIPDOC, m.NRODOC, m.ORDEN, m.REFERENCIA, m.CANTIDAD, m.FECDOC
            FROM dbo.MOVDETALLES m
            JOIN dbo.NEXO_ConfiguracionSync cfg ON cfg.CENTROCOSTO = m.CENTROCOSTO
            WHERE cfg.Activo = 1
              AND ',' + cfg.TiposDocumentoVenta + ',' LIKE '%,' + m.TIPDOC + ',%'
              AND NOT EXISTS (
                  SELECT 1 FROM dbo.NEXO_VentasExportadas v
                  WHERE v.CENTROCOSTO = m.CENTROCOSTO AND v.TIPDOC = m.TIPDOC
                    AND v.NRODOC = m.NRODOC AND v.ORDEN = m.ORDEN AND v.REFERENCIA = m.REFERENCIA
              )";

        var ventas = (await connection.QueryAsync<VentaPendiente>(sqlVentasNuevas)).ToList();

        if (ventas.Count == 0)
            return;

        _logger.LogInformation("Encontradas {Cantidad} ventas nuevas para exportar", ventas.Count);

        foreach (var venta in ventas)
        {
            try
            {
                var idEventoExterno = $"{venta.CENTROCOSTO}-{venta.TIPDOC}-{venta.NRODOC}-{venta.ORDEN}-{venta.REFERENCIA}";

                await _apiClient.RegistrarEventoEntranteAsync(new RegistrarEventoEntranteRequest(
                    idEventoExterno, "VENTA", venta.REFERENCIA, venta.CANTIDAD, venta.FECDOC), ct);

                await connection.ExecuteAsync(
                    @"INSERT INTO dbo.NEXO_VentasExportadas (CENTROCOSTO, TIPDOC, NRODOC, ORDEN, REFERENCIA, CANTIDAD)
                      VALUES (@CENTROCOSTO, @TIPDOC, @NRODOC, @ORDEN, @REFERENCIA, @CANTIDAD)",
                    venta);

                _logger.LogInformation("Venta {IdEventoExterno} exportada", idEventoExterno);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "No se pudo exportar la venta {NRODOC}-{REFERENCIA}", venta.NRODOC, venta.REFERENCIA);
            }
        }
    }
}