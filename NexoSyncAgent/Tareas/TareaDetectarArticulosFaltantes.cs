using Dapper;
using NexoSyncAgent.NexoApiClient;
using NexoSyncAgent.NexoApiClient.Dtos;
using NexoSyncAgent.VisionsData;

namespace NexoSyncAgent.Tareas;

// Recorre dbo.TARJETA de Visions e inserta en NEXO_TarjetasCambios los articulos
// que aun no han sido procesados, para que TareaImportarCambiosTarjeta los cree
// en NEXO via SyncArticuloDesdeVisionsAsync (que ahora auto-crea cuando no existe mapeo).
// Se ejecuta en lotes de 500 por ciclo para no saturar la API.
public class TareaDetectarArticulosFaltantes
{
    private readonly INexoApiClient _apiClient;
    private readonly IVisionsConnectionFactory _visionsDb;
    private readonly ILogger<TareaDetectarArticulosFaltantes> _logger;
    private const int LotePorCiclo = 500;

    public TareaDetectarArticulosFaltantes(
        INexoApiClient apiClient, IVisionsConnectionFactory visionsDb,
        ILogger<TareaDetectarArticulosFaltantes> logger)
    {
        _apiClient = apiClient;
        _visionsDb = visionsDb;
        _logger = logger;
    }

    public async Task EjecutarAsync(int centroCostoVisions, CancellationToken ct)
    {
        using var connection = _visionsDb.CreateConnection();

        // Tomar articulos de TARJETA que no tienen ninguna entrada en NEXO_TarjetasCambios
        // (pendiente o procesada) — solo los que nunca han sido enviados a NEXO.
        var articulos = (await connection.QueryAsync<ArticuloVisions>(@"
            SELECT TOP (@Lote) t.REFERENCIA, t.DETALLE, t.COSTO, t.PPUBLICO
            FROM dbo.TARJETA t
            WHERE t.CENTROCOSTO = @CC
              AND t.REFERENCIA IS NOT NULL AND t.REFERENCIA <> ''
              AND NOT EXISTS (
                  SELECT 1 FROM dbo.NEXO_TarjetasCambios c
                  WHERE c.CENTROCOSTO = t.CENTROCOSTO AND c.REFERENCIA = t.REFERENCIA
              )",
            new { CC = centroCostoVisions, Lote = LotePorCiclo })).ToList();

        if (articulos.Count == 0)
            return;

        _logger.LogInformation(
            "TareaDetectarArticulosFaltantes: {N} articulos de TARJETA sin entrada en NEXO — sincronizando...",
            articulos.Count);

        foreach (var a in articulos)
        {
            if (ct.IsCancellationRequested) break;
            try
            {
                await _apiClient.SyncArticuloDesdeVisionsAsync(new SyncArticuloDesdeVisionsRequest(
                    ReferenciaVisions: a.REFERENCIA,
                    CentroCostoVisions: centroCostoVisions.ToString(),
                    Nombre: a.DETALLE,
                    Costo: a.COSTO,
                    PPublico: a.PPUBLICO,
                    FechaCambio: DateTime.Now), ct);

                // Marcar en NEXO_TarjetasCambios como procesado para no repetir.
                await connection.ExecuteAsync(@"
                    IF NOT EXISTS (SELECT 1 FROM dbo.NEXO_TarjetasCambios
                                   WHERE CENTROCOSTO = @CC AND REFERENCIA = @Ref)
                    INSERT INTO dbo.NEXO_TarjetasCambios
                        (CENTROCOSTO, REFERENCIA, DETALLE, COSTO, PPUBLICO, FechaCambio, Procesado)
                    VALUES (@CC, @Ref, @Detalle, @Costo, @PPub, GETDATE(), 1)",
                    new { CC = centroCostoVisions, Ref = a.REFERENCIA, Detalle = a.DETALLE, Costo = a.COSTO, PPub = a.PPUBLICO });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al sincronizar articulo faltante {Ref}", a.REFERENCIA);
            }
        }

        _logger.LogInformation("TareaDetectarArticulosFaltantes: lote completado ({N} articulos)", articulos.Count);
    }

    private record ArticuloVisions(string REFERENCIA, string? DETALLE, decimal? COSTO, decimal? PPUBLICO);
}
