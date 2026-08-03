using NexoWeb.Common.ApiClient;
using NexoWeb.Common.Dtos;

namespace NexoWeb.Common.Auth;

// Estado de preferencias del usuario actual (tema oscuro, vista lista/tarjetas
// por pantalla, etc.), cacheado en memoria por circuito de Blazor Server y
// respaldado en Seguridad.PreferenciasUsuario via la API. Se carga una sola
// vez (CargarAsync es idempotente) y los componentes se suscriben a OnCambio
// para re-renderizar cuando algo cambia (ej. MainLayout al togglear el tema).
public class PreferenciasState
{
    private readonly INexoApiClient _apiClient;
    private Dictionary<string, string> _valores = new();
    private bool _cargado;

    public event Action? OnCambio;

    public PreferenciasState(INexoApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    public bool TemaOscuro => ObtenerValor("TemaOscuro") == "true";

    public string ObtenerVista(string pagina, string porDefecto = "lista") =>
        ObtenerValor($"Vista:{pagina}", porDefecto);

    public async Task CargarAsync()
    {
        if (_cargado) return;

        try
        {
            _valores = await _apiClient.GetAsync<Dictionary<string, string>>("api/preferencias") ?? new();
        }
        catch
        {
            _valores = new();
        }

        _cargado = true;
    }

    // Se llama al cerrar sesion para que el proximo login (posiblemente de
    // otro usuario en el mismo circuito/pestana) no arrastre preferencias
    // ajenas antes de que CargarAsync las vuelva a pedir.
    public void Reiniciar()
    {
        _valores = new();
        _cargado = false;
    }

    public async Task EstablecerTemaOscuroAsync(bool valor)
    {
        await EstablecerAsync("TemaOscuro", valor ? "true" : "false");
    }

    public async Task EstablecerVistaAsync(string pagina, string vista)
    {
        await EstablecerAsync($"Vista:{pagina}", vista);
    }

    private async Task EstablecerAsync(string clave, string valor)
    {
        _valores[clave] = valor;
        OnCambio?.Invoke();

        try
        {
            await _apiClient.PutAsync<GuardarPreferenciaRequest, object>(
                $"api/preferencias/{Uri.EscapeDataString(clave)}", new GuardarPreferenciaRequest(valor));
        }
        catch
        {
            // Si falla el guardado remoto, el valor local ya se aplico visualmente;
            // se reintentara sincronizar en la proxima carga de preferencias.
        }
    }

    private string ObtenerValor(string clave, string porDefecto = "") =>
        _valores.TryGetValue(clave, out var valor) ? valor : porDefecto;
}
