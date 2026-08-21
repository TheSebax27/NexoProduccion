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

    public async Task<ConfiguracionAgenteResponse> ObtenerConfiguracionAsync(CancellationToken ct)
    {
        var respuesta = await _http.GetAsync("api/integracion/configuracion", ct);
        respuesta.EnsureSuccessStatusCode();

        var configuracion = await respuesta.Content.ReadFromJsonAsync<ConfiguracionAgenteResponse>(cancellationToken: ct);
        return configuracion ?? throw new InvalidOperationException("La API no devolvio configuracion para este agente.");
    }

    public async Task<LatidoResponse> EnviarLatidoAsync(string version, CancellationToken ct)
    {
        var respuesta = await _http.PostAsJsonAsync("api/integracion/latido", new { Version = version }, ct);
        respuesta.EnsureSuccessStatusCode();

        var latido = await respuesta.Content.ReadFromJsonAsync<LatidoResponse>(cancellationToken: ct);
        return latido ?? throw new InvalidOperationException("La API no devolvio respuesta de latido.");
    }

    public async Task RegistrarFalloEventoAsync(long eventoId, string mensajeError, CancellationToken ct)
    {
        var respuesta = await _http.PostAsJsonAsync(
            $"api/integracion/eventos-salientes/{eventoId}/fallar",
            new { MensajeError = mensajeError },
            ct);
        respuesta.EnsureSuccessStatusCode();
    }

    // ──────────── Catalogos ────────────

    public async Task<List<MarcaSyncDto>> ListarMarcasSyncAsync(CancellationToken ct)
    {
        var r = await _http.GetAsync("api/integracion/catalogo/marcas", ct);
        r.EnsureSuccessStatusCode();
        return await r.Content.ReadFromJsonAsync<List<MarcaSyncDto>>(cancellationToken: ct) ?? [];
    }

    public async Task UpsertMarcaEnNexoAsync(MarcaSyncDto item, CancellationToken ct)
    {
        var r = await _http.PostAsJsonAsync("api/integracion/catalogo/marcas/upsert", item, ct);
        r.EnsureSuccessStatusCode();
    }

    public async Task<List<GrupoMayorSyncDto>> ListarGruposMayorSyncAsync(CancellationToken ct)
    {
        var r = await _http.GetAsync("api/integracion/catalogo/grupos-mayor", ct);
        r.EnsureSuccessStatusCode();
        return await r.Content.ReadFromJsonAsync<List<GrupoMayorSyncDto>>(cancellationToken: ct) ?? [];
    }

    public async Task UpsertGrupoMayorEnNexoAsync(GrupoMayorSyncDto item, CancellationToken ct)
    {
        var r = await _http.PostAsJsonAsync("api/integracion/catalogo/grupos-mayor/upsert", item, ct);
        r.EnsureSuccessStatusCode();
    }

    public async Task<List<GrupoMenorSyncDto>> ListarGruposMenorSyncAsync(CancellationToken ct)
    {
        var r = await _http.GetAsync("api/integracion/catalogo/grupos-menor", ct);
        r.EnsureSuccessStatusCode();
        return await r.Content.ReadFromJsonAsync<List<GrupoMenorSyncDto>>(cancellationToken: ct) ?? [];
    }

    public async Task UpsertGrupoMenorEnNexoAsync(GrupoMenorSyncDto item, CancellationToken ct)
    {
        var r = await _http.PostAsJsonAsync("api/integracion/catalogo/grupos-menor/upsert", item, ct);
        r.EnsureSuccessStatusCode();
    }

    public async Task<List<IvaSyncDto>> ListarIvaSyncAsync(CancellationToken ct)
    {
        var r = await _http.GetAsync("api/integracion/catalogo/iva", ct);
        r.EnsureSuccessStatusCode();
        return await r.Content.ReadFromJsonAsync<List<IvaSyncDto>>(cancellationToken: ct) ?? [];
    }

    public async Task UpsertIvaEnNexoAsync(IvaSyncDto item, CancellationToken ct)
    {
        var r = await _http.PostAsJsonAsync("api/integracion/catalogo/iva/upsert", item, ct);
        r.EnsureSuccessStatusCode();
    }

    public async Task<List<PresentacionSyncDto>> ListarPresentacionesSyncAsync(CancellationToken ct)
    {
        var r = await _http.GetAsync("api/integracion/catalogo/presentaciones", ct);
        r.EnsureSuccessStatusCode();
        return await r.Content.ReadFromJsonAsync<List<PresentacionSyncDto>>(cancellationToken: ct) ?? [];
    }

    public async Task UpsertPresentacionEnNexoAsync(PresentacionSyncDto item, CancellationToken ct)
    {
        var r = await _http.PostAsJsonAsync("api/integracion/catalogo/presentaciones/upsert", item, ct);
        r.EnsureSuccessStatusCode();
    }

    // ──────────── Facturas NEXO → Visions ────────────

    public async Task<List<FacturaParaVisionsDto>> ListarFacturasParaVisionsAsync(CancellationToken ct)
    {
        var r = await _http.GetAsync("api/integracion/facturas-para-visions", ct);
        r.EnsureSuccessStatusCode();
        return await r.Content.ReadFromJsonAsync<List<FacturaParaVisionsDto>>(cancellationToken: ct) ?? [];
    }

    public async Task MarcarFacturaExportadaVisionsAsync(int facturaId, CancellationToken ct)
    {
        var r = await _http.PostAsync($"api/integracion/facturas/{facturaId}/marcar-exportada-visions", null, ct);
        r.EnsureSuccessStatusCode();
    }

    public async Task SyncArticuloDesdeVisionsAsync(SyncArticuloDesdeVisionsRequest request, CancellationToken ct)
    {
        var r = await _http.PostAsJsonAsync("api/integracion/sync/articulo-desde-visions", request, ct);
        r.EnsureSuccessStatusCode();
    }

    public async Task InactivarArticuloDesdeVisionsAsync(string referencia, CancellationToken ct)
    {
        var r = await _http.PostAsync($"api/integracion/sync/articulo-inactivar?referencia={Uri.EscapeDataString(referencia)}", null, ct);
        r.EnsureSuccessStatusCode();
    }

    public async Task<List<ClienteParaSyncDto>> ListarClientesParaSyncAsync(DateTime? desde, CancellationToken ct)
    {
        var url = desde.HasValue
            ? $"api/integracion/sync/clientes?desde={desde.Value:O}"
            : "api/integracion/sync/clientes";
        var r = await _http.GetAsync(url, ct);
        r.EnsureSuccessStatusCode();
        return await r.Content.ReadFromJsonAsync<List<ClienteParaSyncDto>>(cancellationToken: ct) ?? [];
    }

    public async Task SyncClienteDesdeVisionsAsync(SyncClienteDesdeVisionsRequest request, CancellationToken ct)
    {
        var r = await _http.PostAsJsonAsync("api/integracion/sync/cliente-desde-visions", request, ct);
        r.EnsureSuccessStatusCode();
    }

    public async Task<List<ProveedorParaSyncDto>> ListarProveedoresParaSyncAsync(CancellationToken ct)
    {
        var r = await _http.GetAsync("api/integracion/sync/proveedores", ct);
        r.EnsureSuccessStatusCode();
        return await r.Content.ReadFromJsonAsync<List<ProveedorParaSyncDto>>(cancellationToken: ct) ?? [];
    }

    public async Task SyncProveedorDesdeVisionsAsync(SyncProveedorDesdeVisionsRequest request, CancellationToken ct)
    {
        var r = await _http.PostAsJsonAsync("api/integracion/sync/proveedor-desde-visions", request, ct);
        r.EnsureSuccessStatusCode();
    }

    public async Task ActualizarNumeroVisionsAsync(int facturaId, ActualizarNumeroVisionsRequest request, CancellationToken ct)
    {
        var r = await _http.PutAsJsonAsync($"api/integracion/facturas/{facturaId}/numero-visions", request, ct);
        r.EnsureSuccessStatusCode();
    }
}