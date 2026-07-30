using System.Net.Http.Headers;
using System.Net.Http.Json;
using NexoWeb.Common.Auth;
using NexoWeb.Common.Dtos;

namespace NexoWeb.Common.ApiClient;

public class NexoApiClient : INexoApiClient
{
    private readonly HttpClient _http;
    private readonly AuthStateService _authState;

    public NexoApiClient(HttpClient http, AuthStateService authState)
    {
        _http = http;
        _authState = authState;
    }

    public async Task<LoginResponse?> LoginAsync(LoginRequest request)
    {
        // El login es el UNICO llamado que se hace SIN token (obviamente,
        // porque todavia no existe uno).
        var respuesta = await _http.PostAsJsonAsync("api/auth/login", request);

        if (!respuesta.IsSuccessStatusCode)
            return null;

        return await respuesta.Content.ReadFromJsonAsync<LoginResponse>();
    }

    public async Task<T?> GetAsync<T>(string ruta)
    {
        await AgregarTokenAsync();
        var respuesta = await _http.GetAsync(ruta);
        respuesta.EnsureSuccessStatusCode();
        return await respuesta.Content.ReadFromJsonAsync<T>();
    }

    public async Task<TResponse?> PostAsync<TRequest, TResponse>(string ruta, TRequest body)
    {
        await AgregarTokenAsync();
        var respuesta = await _http.PostAsJsonAsync(ruta, body);
        respuesta.EnsureSuccessStatusCode();
        return await respuesta.Content.ReadFromJsonAsync<TResponse>();
    }

    public async Task PostAsync<TRequest>(string ruta, TRequest body)
    {
        await AgregarTokenAsync();
        var respuesta = await _http.PostAsJsonAsync(ruta, body);
        respuesta.EnsureSuccessStatusCode();
    }

    public async Task<TResponse?> PutAsync<TRequest, TResponse>(string ruta, TRequest body)
    {
        await AgregarTokenAsync();
        var respuesta = await _http.PutAsJsonAsync(ruta, body);
        respuesta.EnsureSuccessStatusCode();
        return await respuesta.Content.ReadFromJsonAsync<TResponse>();
    }

    private async Task AgregarTokenAsync()
    {
        var token = await _authState.ObtenerTokenAsync();
        _http.DefaultRequestHeaders.Authorization =
            string.IsNullOrEmpty(token) ? null : new AuthenticationHeaderValue("Bearer", token);
    }

    // Agregar a NexoApiClient.cs
    public async Task PostAsync(string ruta)
    {
        await AgregarTokenAsync();
        var respuesta = await _http.PostAsync(ruta, null);
        respuesta.EnsureSuccessStatusCode();
    }
}