using System.Net.Http.Json;
using NexoSyncAgent.NexoApiClient.Dtos;

namespace NexoSyncAgent.NexoApiClient;

public class NexoApiClient : INexoApiClient
{
    private readonly HttpClient _http;
    private readonly ILogger<NexoApiClient> _logger;

    public NexoApiClient(HttpClient http, ILogger<NexoApiClient> logger)
    {
        _http = http;
        _logger = logger;
    }

    public async Task<List<EventoPendienteItem>> ObtenerEventosPendientesAsync(CancellationToken ct)
    {
        var respuesta = await _http.GetAsync("api/integracion/eventos-pendientes", ct);
        respuesta.EnsureSuccessStatusCode();

        var eventos = await respuesta.Content.ReadFromJsonAsync<List<EventoPendienteItem>>(cancellationToken: ct);
        return eventos ?? new List<EventoPendienteItem>();
    }

    public async Task ConfirmarEventoSalienteAsync(long eventoId, CancellationToken ct)
    {
        var respuesta = await _http.PostAsync($"api/integracion/eventos-salientes/{eventoId}/confirmar", null, ct);
        respuesta.EnsureSuccessStatusCode();
    }

    public async Task RegistrarEventoEntranteAsync(RegistrarEventoEntranteRequest request, CancellationToken ct)
    {
        var respuesta = await _http.PostAsJsonAsync("api/integracion/eventos-entrantes", request, ct);

        // Si el evento ya existia (idempotencia del lado de la API), la API
        // responde 200 igual -- no es un error, asi que no hace falta
        // tratarlo distinto aqui.
        respuesta.EnsureSuccessStatusCode();
    }
}