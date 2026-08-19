using Dapper;
using NexoSyncAgent.NexoApiClient;
using NexoSyncAgent.NexoApiClient.Dtos;
using NexoSyncAgent.VisionsData;

namespace NexoSyncAgent.Tareas;

// Lee NEXO_TarjetasCambios (rellenada por el trigger TR_TARJETA_NexoCambios en Visions)
// y envia los cambios de precio/nombre a NEXO para mantener Catalogo.Tarjetas sincronizado.
// La API aplica el cambio solo si el timestamp de Visions es mas reciente que FechaModificacion
// en NEXO (+ 5s de margen), evitando bucles de sincronizacion.
public class TareaImportarCambiosTarjeta
{
    private readonly INexoApiClient _apiClient;
    private readonly IVisionsConnectionFactory _visionsDb;
    private readonly ILogger<TareaImportarCambiosTarjeta> _logger;

    public TareaImportarCambiosTarjeta(
        INexoApiClient apiClient, IVisionsConnectionFactory visionsDb, ILogger<TareaImportarCambiosTarjeta> logger)
    {
        _apiClient = apiClient;
        _visionsDb = visionsDb;
        _logger = logger;
    }

    public async Task EjecutarAsync(int centroCostoVisions, CancellationToken ct)
    {
        using var connection = _visionsDb.CreateConnection();

        // Tomar el cambio mas reciente por CENTROCOSTO+REFERENCIA (si hay varios pendientes).
        var cambios = (await connection.QueryAsync<CambioPendiente>(
            @"SELECT t.Id, t.CENTROCOSTO, t.REFERENCIA, t.DETALLE, t.COSTO, t.PPUBLICO, t.FechaCambio
              FROM dbo.NEXO_TarjetasCambios t
              INNER JOIN (
                  SELECT CENTROCOSTO, REFERENCIA, MAX(Id) AS UltimoId
                  FROM dbo.NEXO_TarjetasCambios
                  WHERE Procesado = 0 AND CENTROCOSTO = @CC
                  GROUP BY CENTROCOSTO, REFERENCIA
              ) ult ON ult.UltimoId = t.Id",
            new { CC = centroCostoVisions })).ToList();

        if (cambios.Count == 0)
            return;

        _logger.LogInformation("Encontrados {Cantidad} cambios de TARJETA en Visions para importar a NEXO", cambios.Count);

        foreach (var cambio in cambios)
        {
            try
            {
                await _apiClient.SyncArticuloDesdeVisionsAsync(new SyncArticuloDesdeVisionsRequest(
                    ReferenciaVisions: cambio.REFERENCIA,
                    CentroCostoVisions: cambio.CENTROCOSTO.ToString(),
                    Nombre: cambio.DETALLE,
                    Costo: cambio.COSTO,
                    PPublico: cambio.PPUBLICO,
                    FechaCambio: cambio.FechaCambio), ct);

                // Marcar todos los registros de esta referencia como procesados.
                await connection.ExecuteAsync(
                    "UPDATE dbo.NEXO_TarjetasCambios SET Procesado = 1 WHERE CENTROCOSTO = @CC AND REFERENCIA = @Ref AND Procesado = 0",
                    new { CC = cambio.CENTROCOSTO, Ref = cambio.REFERENCIA });

                _logger.LogInformation("Cambio de TARJETA ({Ref}) sincronizado a NEXO", cambio.REFERENCIA);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "No se pudo sincronizar cambio de TARJETA ({Ref}) a NEXO", cambio.REFERENCIA);
            }
        }
    }

    private record CambioPendiente(
        long Id, int CENTROCOSTO, string REFERENCIA,
        string? DETALLE, decimal? COSTO, decimal? PPUBLICO, DateTime FechaCambio);
}
