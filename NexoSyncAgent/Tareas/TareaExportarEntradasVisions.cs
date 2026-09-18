using Dapper;
using NexoSyncAgent.NexoApiClient;
using NexoSyncAgent.NexoApiClient.Dtos;
using NexoSyncAgent.VisionsData;

namespace NexoSyncAgent.Tareas;

public class TareaExportarEntradasVisions
{
    private record EntradaPendiente(
        short CENTROCOSTO, string TIPDOC, string NRODOC, int ORDEN, string REFERENCIA,
        decimal CANTIDAD, decimal COSTOCOMPRA, DateTime FECDOC,
        string? ProveedorNIT,
        string? DetalleTarjeta, decimal? CostoTarjeta, decimal? PPublicoTarjeta,
        string? MarcaCodigo, string? IvaSiNo, decimal? IvaValor, string? IvaDescripcion,
        string? GrupoMenorCodigo, string? PresentacionCodigo,
        decimal? ExistenciasActuales, decimal? ExistenciasMinimas);

    private readonly INexoApiClient _apiClient;
    private readonly IVisionsConnectionFactory _visionsDb;
    private readonly ILogger<TareaExportarEntradasVisions> _logger;

    public TareaExportarEntradasVisions(
        INexoApiClient apiClient, IVisionsConnectionFactory visionsDb,
        ILogger<TareaExportarEntradasVisions> logger)
    {
        _apiClient = apiClient;
        _visionsDb = visionsDb;
        _logger = logger;
    }

    public async Task EjecutarAsync(int centroCostoVisions, CancellationToken ct)
    {
        using var connection = _visionsDb.CreateConnection();

        const string sql = @"
            SELECT m.CENTROCOSTO, m.TIPDOC, m.NRODOC, CAST(m.ORDEN AS INT) AS ORDEN, m.REFERENCIA,
                   m.CANTIDAD, m.COSTOCOMPRA, m.FECDOC,
                   m.NIT                                                   AS ProveedorNIT,
                   t.DETALLE                                               AS DetalleTarjeta,
                   t.COSTO                                                 AS CostoTarjeta,
                   t.PPUBLICO                                              AS PPublicoTarjeta,
                   t.MARCA                                                 AS MarcaCodigo,
                   ISNULL(t.IVASINO, 'SI')                                AS IvaSiNo,
                   CAST(ISNULL(t.IVAVALOR, 19) AS DECIMAL(18,4))         AS IvaValor,
                   ISNULL(t.IVADESCRIPCION, 'IVA 19%')                   AS IvaDescripcion,
                   t.GRUPOMENOR                                            AS GrupoMenorCodigo,
                   t.PRESENTACION                                          AS PresentacionCodigo,
                   t.EXISTENCIAS                                           AS ExistenciasActuales,
                   t.EXISTENCIASMINIMAS                                    AS ExistenciasMinimas
            FROM dbo.MOVDETALLEE m
            JOIN dbo.NEXO_ConfiguracionSync cfg ON cfg.CENTROCOSTO = m.CENTROCOSTO
            LEFT JOIN dbo.TARJETA t ON t.CENTROCOSTO = m.CENTROCOSTO AND t.REFERENCIA = m.REFERENCIA
            WHERE cfg.Activo = 1
              AND m.CENTROCOSTO = @CentroCostoVisions
              AND m.TIPDOC IN ('FACTURA', 'REMISION', 'DOCUMENTO SOPORTE')
              AND NOT EXISTS (
                  SELECT 1 FROM dbo.NEXO_EntradasExportadas e
                  WHERE e.CENTROCOSTO = m.CENTROCOSTO AND e.TIPDOC = m.TIPDOC
                    AND e.NRODOC = m.NRODOC AND e.ORDEN = m.ORDEN AND e.REFERENCIA = m.REFERENCIA
              )
              -- Excluir entradas que vinieron de OC de NEXO: NEXO ya creo el Kardex
              -- al confirmar la OC via NEXO_SP_ConfirmarPedido. Exportarlas de nuevo
              -- duplicaria el stock.
              AND NOT EXISTS (
                  SELECT 1 FROM dbo.NEXO_Pedidos p
                  WHERE p.NroDocVisions = m.NRODOC AND p.TipDocVisions = m.TIPDOC
              )";

        var entradas = (await connection.QueryAsync<EntradaPendiente>(
            sql, new { CentroCostoVisions = centroCostoVisions })).ToList();

        if (entradas.Count == 0)
            return;

        _logger.LogInformation("Encontradas {Cantidad} entradas de inventario nuevas para exportar", entradas.Count);

        foreach (var entrada in entradas)
        {
            try
            {
                // Prefijo ENT- distingue de ventas que usan el mismo patron sin prefijo.
                var idEventoExterno = $"{entrada.CENTROCOSTO}-ENT-{entrada.TIPDOC}-{entrada.NRODOC}-{entrada.ORDEN}-{entrada.REFERENCIA}";

                await _apiClient.RegistrarEventoEntranteAsync(new RegistrarEventoEntranteRequest(
                    idEventoExterno,
                    "ENTRADA_COMPRA",
                    entrada.REFERENCIA,
                    entrada.CANTIDAD,
                    entrada.FECDOC,
                    NombreArticuloVisions: entrada.DetalleTarjeta ?? "",
                    CostoArticuloVisions:  entrada.COSTOCOMPRA,
                    PrecioArticuloVisions: entrada.PPublicoTarjeta ?? 0m,
                    ClienteNit:            entrada.ProveedorNIT,
                    ClienteNombre:         null,
                    TipDoc:                entrada.TIPDOC,
                    NroDoc:                entrada.NRODOC,
                    MarcaCodigo:           entrada.MarcaCodigo ?? "",
                    IvaValor:              entrada.IvaValor,
                    IvaDescripcion:        entrada.IvaDescripcion,
                    IvaSiNo:               entrada.IvaSiNo,
                    GrupoMenorCodigo:      entrada.GrupoMenorCodigo ?? "",
                    PresentacionCodigo:    entrada.PresentacionCodigo ?? "",
                    ExistenciasActuales:   entrada.ExistenciasActuales ?? 0m,
                    ExistenciasMinimas:    entrada.ExistenciasMinimas ?? 0m), ct);

                await connection.ExecuteAsync(
                    @"IF NOT EXISTS (SELECT 1 FROM dbo.NEXO_EntradasExportadas
                                    WHERE CENTROCOSTO=@CENTROCOSTO AND TIPDOC=@TIPDOC AND NRODOC=@NRODOC
                                      AND ORDEN=@ORDEN AND REFERENCIA=@REFERENCIA)
                      INSERT INTO dbo.NEXO_EntradasExportadas (CENTROCOSTO, TIPDOC, NRODOC, ORDEN, REFERENCIA, CANTIDAD)
                      VALUES (@CENTROCOSTO, @TIPDOC, @NRODOC, @ORDEN, @REFERENCIA, @CANTIDAD)",
                    entrada);

                _logger.LogInformation("Entrada {IdEventoExterno} exportada", idEventoExterno);
            }
            catch (OperationCanceledException) when (ct.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "No se pudo exportar la entrada {NRODOC}-{REFERENCIA}", entrada.NRODOC, entrada.REFERENCIA);
            }
        }
    }
}
