using Dapper;
using NexoSyncAgent.NexoApiClient;
using NexoSyncAgent.VisionsData;

namespace NexoSyncAgent.Tareas;

public class TareaAplicarEntradasInventario
{
    private readonly INexoApiClient _apiClient;
    private readonly IVisionsConnectionFactory _visionsDb;
    private readonly ILogger<TareaAplicarEntradasInventario> _logger;

    public TareaAplicarEntradasInventario(
        INexoApiClient apiClient, IVisionsConnectionFactory visionsDb, ILogger<TareaAplicarEntradasInventario> logger)
    {
        _apiClient = apiClient;
        _visionsDb = visionsDb;
        _logger = logger;
    }

    public async Task EjecutarAsync(CancellationToken ct)
    {
        var eventos = await _apiClient.ObtenerEventosPendientesAsync(ct);

        if (eventos.Count == 0)
            return;

        _logger.LogInformation("Encontrados {Cantidad} eventos pendientes de Produccion", eventos.Count);

        foreach (var evento in eventos)
        {
            try
            {
                AplicarEnVisions(evento);
                await _apiClient.ConfirmarEventoSalienteAsync(evento.EventoID, ct);
                _logger.LogInformation("Evento {EventoID} aplicado y confirmado", evento.EventoID);
            }
            catch (Exception ex)
            {
                // No propagamos el error: un evento que falla no debe tumbar
                // el procesamiento de los demas. Se queda PENDIENTE y se
                // reintenta solo en la proxima ronda.
                _logger.LogError(ex, "No se pudo aplicar el evento {EventoID}", evento.EventoID);
            }
        }
    }

    private void AplicarEnVisions(NexoApiClient.Dtos.EventoPendienteItem evento)
    {
        using var connection = _visionsDb.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();

        try
        {
            var filas = connection.Execute(
                @"UPDATE dbo.TARJETA SET EXISTENCIAS = ISNULL(EXISTENCIAS,0) + @Cantidad
                  WHERE CENTROCOSTO = @CentroCosto AND REFERENCIA = @Referencia",
                new
                {
                    evento.Cantidad,
                    CentroCosto = evento.CentroCostoVisions,
                    Referencia = evento.ReferenciaVisions
                },
                transaction);

            if (filas == 0)
                throw new InvalidOperationException(
                    $"La referencia {evento.ReferenciaVisions} no existe en TARJETA para el centro de costo {evento.CentroCostoVisions}.");

            connection.Execute(
                @"INSERT INTO dbo.NEXO_EntradasInventario
                    (IdEventoOrigen, CENTROCOSTO, REFERENCIA, CANTIDAD, COSTO, Aplicado, FechaAplicado)
                  VALUES (@IdEventoOrigen, @CentroCosto, @Referencia, @Cantidad, @Costo, 1, GETDATE())",
                new
                {
                    IdEventoOrigen = evento.EventoID,
                    CentroCosto = evento.CentroCostoVisions,
                    Referencia = evento.ReferenciaVisions,
                    evento.Cantidad,
                    Costo = evento.CostoUnitario
                },
                transaction);

            transaction.Commit();
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }
}