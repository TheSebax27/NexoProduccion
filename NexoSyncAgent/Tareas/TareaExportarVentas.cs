using Dapper;
using NexoSyncAgent.NexoApiClient;
using NexoSyncAgent.NexoApiClient.Dtos;
using NexoSyncAgent.VisionsData;

namespace NexoSyncAgent.Tareas;

public class TareaExportarVentas
{
    // DetalleTarjeta/CostoTarjeta/PPublicoTarjeta: lo que ya tiene Visions para
    // esa REFERENCIA en dbo.TARJETA -- viajan como sugerencia por si NEXO no
    // tiene mapeo para este articulo todavia.
    // NIT/Cliente: datos del comprador para que NEXO cree el cliente si no existe.
    private record VentaPendiente(
        short CENTROCOSTO, string TIPDOC, string NRODOC, decimal ORDEN, string REFERENCIA, decimal CANTIDAD, DateTime FECDOC,
        string? DetalleTarjeta, decimal? CostoTarjeta, decimal? PPublicoTarjeta,
        string? NIT, string? CLIENTE);

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

    // centroCostoVisions: el codigo CENTROCOSTO que le corresponde a ESTE agente
    // (ver TareaSincronizarConfiguracion). Se filtra explicito por el, aunque la
    // base de Visions sea compartida entre varias sucursales -- asi cada agente
    // (cada API Key) solo procesa y reporta las ventas de SU propia sucursal, sin
    // cruzarse con las de otras que compartan la misma base de datos de Visions.
    public async Task EjecutarAsync(int centroCostoVisions, CancellationToken ct)
    {
        using var connection = _visionsDb.CreateConnection();

        const string sqlVentasNuevas = @"
            SELECT m.CENTROCOSTO, m.TIPDOC, m.NRODOC, m.ORDEN, m.REFERENCIA, m.CANTIDAD, m.FECDOC,
                   t.DETALLE AS DetalleTarjeta, t.COSTO AS CostoTarjeta, t.PPUBLICO AS PPublicoTarjeta,
                   m.NIT,
                   CASE
                     WHEN NULLIF(LTRIM(RTRIM(ISNULL(u.NOMBRE1,'') + ' ' + ISNULL(u.APELLIDO1,''))), '') IS NOT NULL
                     THEN LTRIM(RTRIM(
                            ISNULL(u.NOMBRE1,'') + ' ' +
                            ISNULL(u.NOMBRE2+' ','') +
                            ISNULL(u.APELLIDO1,'') + ' ' +
                            ISNULL(u.APELLIDO2,'')
                          ))
                     ELSE ISNULL(NULLIF(m.CLIENTE,''), m.NIT)
                   END AS CLIENTE
            FROM dbo.MOVDETALLES m
            JOIN dbo.NEXO_ConfiguracionSync cfg ON cfg.CENTROCOSTO = m.CENTROCOSTO
            LEFT JOIN dbo.TARJETA t ON t.CENTROCOSTO = m.CENTROCOSTO AND t.REFERENCIA = m.REFERENCIA
            LEFT JOIN dbo.USUARIOS u ON u.NIT = m.NIT
            WHERE cfg.Activo = 1
              AND m.CENTROCOSTO = @CentroCostoVisions
              AND NOT EXISTS (
                  SELECT 1 FROM dbo.NEXO_VentasExportadas v
                  WHERE v.CENTROCOSTO = m.CENTROCOSTO AND v.TIPDOC = m.TIPDOC
                    AND v.NRODOC = m.NRODOC AND v.ORDEN = m.ORDEN AND v.REFERENCIA = m.REFERENCIA
              )";

        var ventas = (await connection.QueryAsync<VentaPendiente>(sqlVentasNuevas, new { CentroCostoVisions = centroCostoVisions })).ToList();

        if (ventas.Count == 0)
            return;

        _logger.LogInformation("Encontradas {Cantidad} ventas nuevas para exportar", ventas.Count);

        foreach (var venta in ventas)
        {
            try
            {
                var idEventoExterno = $"{venta.CENTROCOSTO}-{venta.TIPDOC}-{venta.NRODOC}-{venta.ORDEN}-{venta.REFERENCIA}";

                await _apiClient.RegistrarEventoEntranteAsync(new RegistrarEventoEntranteRequest(
                    idEventoExterno, "VENTA", venta.REFERENCIA, venta.CANTIDAD, venta.FECDOC,
                    venta.DetalleTarjeta, venta.CostoTarjeta, venta.PPublicoTarjeta,
                    venta.NIT, venta.CLIENTE,
                    TipDoc: venta.TIPDOC, NroDoc: venta.NRODOC), ct);

                await connection.ExecuteAsync(
                    @"IF NOT EXISTS (SELECT 1 FROM dbo.NEXO_VentasExportadas
                                    WHERE CENTROCOSTO=@CENTROCOSTO AND TIPDOC=@TIPDOC AND NRODOC=@NRODOC AND ORDEN=@ORDEN AND REFERENCIA=@REFERENCIA)
                      INSERT INTO dbo.NEXO_VentasExportadas (CENTROCOSTO, TIPDOC, NRODOC, ORDEN, REFERENCIA, CANTIDAD)
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