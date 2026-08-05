using NexoWeb.Common.ApiClient;
using NexoWeb.Common.Dtos;

namespace NexoWeb.Common.Auth;

// Nombre y logo de la empresa (Settings > Mi Negocio, solo Administrador
// puede editarlo) -- a diferencia de PreferenciasState, esto NO es por
// usuario: todos ven lo mismo. Se carga una vez por circuito (CargarAsync es
// idempotente) y dispara OnCambio para que el sidebar se actualice sin
// recargar la pagina cuando un Administrador lo cambia.
public class ConfiguracionEmpresaState
{
    private readonly INexoApiClient _apiClient;
    private bool _cargado;

    public string NombreEmpresa { get; private set; } = "NEXO ERP";
    public string? LogoBase64 { get; private set; }
    public string? LogoContentType { get; private set; }

    // Null si no hay logo propio -- el sidebar usa la imagen por defecto (LogoV.png) en ese caso.
    public string? LogoDataUri => LogoBase64 is null ? null : $"data:{LogoContentType};base64,{LogoBase64}";

    public event Action? OnCambio;

    public ConfiguracionEmpresaState(INexoApiClient apiClient)
    {
        _apiClient = apiClient;
    }

    public async Task CargarAsync()
    {
        if (_cargado) return;

        try
        {
            var respuesta = await _apiClient.GetAsync<ConfiguracionEmpresaResponse>("api/configuracion/empresa");
            if (respuesta is not null)
            {
                NombreEmpresa = respuesta.NombreEmpresa;
                LogoBase64 = respuesta.LogoBase64;
                LogoContentType = respuesta.LogoContentType;
            }
        }
        catch
        {
            // Se queda con los valores por defecto si aun no hay sesion/API disponible.
        }

        _cargado = true;
    }

    public async Task ActualizarNombreAsync(string nombreEmpresa)
    {
        await _apiClient.PutAsync<ActualizarNombreEmpresaRequest, object>(
            "api/configuracion/empresa", new ActualizarNombreEmpresaRequest(nombreEmpresa));
        NombreEmpresa = nombreEmpresa;
        OnCambio?.Invoke();
    }

    public async Task ActualizarLogoAsync(string base64, string contentType)
    {
        await _apiClient.PutAsync<ActualizarLogoEmpresaRequest, object>(
            "api/configuracion/empresa/logo", new ActualizarLogoEmpresaRequest(base64, contentType));
        LogoBase64 = base64;
        LogoContentType = contentType;
        OnCambio?.Invoke();
    }

    public async Task EliminarLogoAsync()
    {
        await _apiClient.DeleteAsync("api/configuracion/empresa/logo");
        LogoBase64 = null;
        LogoContentType = null;
        OnCambio?.Invoke();
    }
}
