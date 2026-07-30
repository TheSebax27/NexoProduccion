using NexoSyncAgent.NexoApiClient.Dtos;

namespace NexoSyncAgent.NexoApiClient;

public interface INexoApiClient
{
    Task<List<EventoPendienteItem>> ObtenerEventosPendientesAsync(CancellationToken ct);
    Task ConfirmarEventoSalienteAsync(long eventoId, CancellationToken ct);
    Task RegistrarEventoEntranteAsync(RegistrarEventoEntranteRequest request, CancellationToken ct);
}