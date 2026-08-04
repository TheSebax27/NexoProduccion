using Microsoft.AspNetCore.Components.Server.ProtectedBrowserStorage;
using NexoWeb.Common.Dtos;

namespace NexoWeb.Common.Auth;

// OJO: esta clase NO debe inyectar INexoApiClient -- NexoApiClient depende de
// AuthStateService (para el token del header Authorization), asi que
// inyectarlo aqui crearia un ciclo de DI. Los metodos que tocan el perfil
// (nombre/foto) solo actualizan el estado local; el llamado a la API lo hace
// el componente de UI, que si puede inyectar INexoApiClient sin problema.
public class AuthStateService
{
    private const string ClaveStorage = "nexo_sesion";

    private readonly ProtectedSessionStorage _storage;

    public string? Token { get; private set; }
    public int? UsuarioId { get; private set; }
    public string? Nombres { get; private set; }
    public string? Apellidos { get; private set; }
    public string? NombreCompleto { get; private set; }
    public string? Rol { get; private set; }
    public int? CentroCostoId { get; private set; }
    public string? FotoPerfilBase64 { get; private set; }
    public string? FotoPerfilContentType { get; private set; }
    public bool EstaLogueado => !string.IsNullOrEmpty(Token);

    // Data URI listo para <img src="..."> -- null si el usuario no tiene foto.
    public string? FotoPerfilDataUri =>
        FotoPerfilBase64 is null ? null : $"data:{FotoPerfilContentType};base64,{FotoPerfilBase64}";

    // Cualquier componente puede suscribirse a esto para "enterarse" cuando
    // alguien hace login o logout (por ejemplo, el menu lateral, para
    // mostrarse u ocultarse solo), o cuando cambia el nombre/foto del perfil.
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
                UsuarioId = datos.UsuarioId;
                Nombres = datos.Nombres;
                Apellidos = datos.Apellidos;
                NombreCompleto = datos.NombreCompleto;
                Rol = datos.Rol;
                CentroCostoId = datos.CentroCostoId;
                FotoPerfilBase64 = datos.FotoPerfilBase64;
                FotoPerfilContentType = datos.FotoPerfilContentType;
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
        UsuarioId = respuesta.UsuarioId;
        Nombres = respuesta.Nombres;
        Apellidos = respuesta.Apellidos;
        NombreCompleto = respuesta.NombreCompleto;
        Rol = respuesta.Rol;
        CentroCostoId = respuesta.CentroCostoId;
        FotoPerfilBase64 = respuesta.FotoPerfilBase64;
        FotoPerfilContentType = respuesta.FotoPerfilContentType;

        await GuardarSesionAsync();

        OnChange?.Invoke();
    }

    public async Task CerrarSesionAsync()
    {
        Token = null;
        UsuarioId = null;
        Nombres = null;
        Apellidos = null;
        NombreCompleto = null;
        Rol = null;
        CentroCostoId = null;
        FotoPerfilBase64 = null;
        FotoPerfilContentType = null;

        await _storage.DeleteAsync(ClaveStorage);

        OnChange?.Invoke();
    }

    // El componente de UI llama primero a la API (PUT /api/auth/perfil) y,
    // si sale bien, llama esto para reflejar el cambio localmente sin tener
    // que recargar la pagina ni volver a loguearse.
    public async Task ActualizarNombreAsync(string nombres, string apellidos)
    {
        Nombres = nombres;
        Apellidos = apellidos;
        NombreCompleto = $"{nombres} {apellidos}";
        await GuardarSesionAsync();
        OnChange?.Invoke();
    }

    public async Task ActualizarFotoAsync(string base64, string contentType)
    {
        FotoPerfilBase64 = base64;
        FotoPerfilContentType = contentType;
        await GuardarSesionAsync();
        OnChange?.Invoke();
    }

    public async Task EliminarFotoAsync()
    {
        FotoPerfilBase64 = null;
        FotoPerfilContentType = null;
        await GuardarSesionAsync();
        OnChange?.Invoke();
    }

    public Task<string?> ObtenerTokenAsync() => Task.FromResult(Token);

    private ValueTask GuardarSesionAsync() => _storage.SetAsync(ClaveStorage,
        new DatosSesion(Token!, UsuarioId, Nombres!, Apellidos!, NombreCompleto!, Rol!, CentroCostoId, FotoPerfilBase64, FotoPerfilContentType));

    private record DatosSesion(
        string Token, int? UsuarioId, string Nombres, string Apellidos, string NombreCompleto, string Rol, int? CentroCostoId,
        string? FotoPerfilBase64, string? FotoPerfilContentType);
}
