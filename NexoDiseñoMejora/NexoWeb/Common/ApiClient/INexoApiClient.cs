using NexoWeb.Common.Dtos;

namespace NexoWeb.Common.ApiClient;

public interface INexoApiClient
{
    Task<LoginResponse?> LoginAsync(LoginRequest request);

    // Metodos genericos: cualquier pantalla los usa para hablar con
    // cualquier endpoint de NexoApi, sin que este cliente tenga que
    // conocer cada modulo de negocio uno por uno.
    Task<T?> GetAsync<T>(string ruta);
    Task<TResponse?> PostAsync<TRequest, TResponse>(string ruta, TRequest body);
    Task PostAsync<TRequest>(string ruta, TRequest body);
    Task<TResponse?> PutAsync<TRequest, TResponse>(string ruta, TRequest body);
    // Agregar a INexoApiClient.cs
    Task PostAsync(string ruta);

    // Agregado para el punto #2 (pantalla de Bodegas): la API expone
    // "desactivar" como HTTP DELETE y el cliente no tenia forma de llamarlo.
    Task DeleteAsync(string ruta);
}