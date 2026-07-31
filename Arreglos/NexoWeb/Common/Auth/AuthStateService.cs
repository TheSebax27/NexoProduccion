using Microsoft.AspNetCore.Components.Server.ProtectedBrowserStorage;
using NexoWeb.Common.Dtos;

namespace NexoWeb.Common.Auth;

public class AuthStateService
{
    private const string ClaveStorage = "nexo_sesion";

    private readonly ProtectedSessionStorage _storage;

    public string? Token { get; private set; }
    public string? NombreCompleto { get; private set; }
    public string? Rol { get; private set; }
    public int? CentroCostoId { get; private set; }
    public bool EstaLogueado => !string.IsNullOrEmpty(Token);

    // Cualquier componente puede suscribirse a esto para "enterarse" cuando
    // alguien hace login o logout (por ejemplo, el menu lateral, para
    // mostrarse u ocultarse solo).
    public event Action? OnChange;

    public AuthStateService(ProtectedSessionStorage storage)
    {
        _storage = storage;
    }

    // Se llama al arrancar cada circuito nuevo, para recuperar la sesion
    // si el usuario solo recargo la pagina (F5) y no cerro realmente sesion.
    public async Task InicializarAsync()
    {
        try
        {
            var resultado = await _storage.GetAsync<DatosSesion>(ClaveStorage);
            if (resultado.Success && resultado.Value is not null)
            {
                var datos = resultado.Value;
                Token = datos.Token;
                NombreCompleto = datos.NombreCompleto;
                Rol = datos.Rol;
                CentroCostoId = datos.CentroCostoId;
            }
        }
        catch (InvalidOperationException)
        {
            // Pasa durante el "prerendering" inicial de la pagina (antes de
            // que el circuito termine de conectarse); es normal, se ignora.
        }
    }

    public async Task IniciarSesionAsync(LoginResponse respuesta)
    {
        Token = respuesta.AccessToken;
        NombreCompleto = respuesta.NombreCompleto;
        Rol = respuesta.Rol;
        CentroCostoId = respuesta.CentroCostoId;

        await _storage.SetAsync(ClaveStorage, new DatosSesion(Token, NombreCompleto, Rol, CentroCostoId));

        OnChange?.Invoke();
    }

    public async Task CerrarSesionAsync()
    {
        Token = null;
        NombreCompleto = null;
        Rol = null;
        CentroCostoId = null;

        await _storage.DeleteAsync(ClaveStorage);

        OnChange?.Invoke();
    }

    public Task<string?> ObtenerTokenAsync() => Task.FromResult(Token);

    private record DatosSesion(string Token, string NombreCompleto, string Rol, int? CentroCostoId);
}