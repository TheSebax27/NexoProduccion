using System.Globalization;
using Microsoft.AspNetCore.Components.Authorization;
using NexoWeb.Common.Auth;
using MudBlazor.Services;
using NexoWeb.Common.ApiClient;
using NexoWeb.Components;

var builder = WebApplication.CreateBuilder(args);

// Cultura colombiana global: hace que TODOS los ToString("C2")/("N2") de la app
// (tablas, chips, totales) muestren "$1.234.567,89" -- punto como separador de
// miles, coma como decimal -- sin tener que tocar cada pantalla una por una.
var culturaCO = new CultureInfo("es-CO");
CultureInfo.DefaultThreadCurrentCulture = culturaCO;
CultureInfo.DefaultThreadCurrentUICulture = culturaCO;

// Blazor Server: los componentes .razor + la conexion en tiempo real (SignalR)
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents()
    .AddHubOptions(o =>
    {
        // Permite subir imágenes base64 (~5 MB) a través del canal SignalR
        o.MaximumReceiveMessageSize = 10 * 1024 * 1024;
    });

// MudBlazor
builder.Services.AddMudServices();

// El cliente HTTP hacia NexoApi, con su URL base ya configurada
builder.Services.AddHttpClient<INexoApiClient, NexoApiClient>((sp, client) =>
{
    var config = sp.GetRequiredService<IConfiguration>();
    client.BaseAddress = new Uri(config["NexoApi:BaseUrl"]!);
});

// Cliente sin-auth para proxy de imágenes (los endpoints de imagen son AllowAnonymous en la API)
builder.Services.AddHttpClient("img-proxy").ConfigurePrimaryHttpMessageHandler(() =>
    new HttpClientHandler { ServerCertificateCustomValidationCallback = (_, _, _, _) => true });

builder.Services.AddAuthorizationCore(); // el "motor" de autorizacion de Blazor (distinto al AddAuthorization de la API)
builder.Services.AddScoped<AuthStateService>();
builder.Services.AddScoped<AuthenticationStateProvider, CustomAuthStateProvider>();
builder.Services.AddScoped<PreferenciasState>();
builder.Services.AddScoped<ConfiguracionEmpresaState>();
builder.Services.AddScoped<ModulosVisiblesState>();
builder.Services.AddSingleton<CalendarioBroadcast>();

var app = builder.Build();

// Fuerza es-CO en cada request (Blazor Server corre cada circuito en su propio
// contexto, asi que DefaultThreadCurrentCulture solo no basta para todos los casos).
var opcionesLocalizacion = new Microsoft.AspNetCore.Builder.RequestLocalizationOptions()
    .SetDefaultCulture("es-CO")
    .AddSupportedCultures("es-CO")
    .AddSupportedUICultures("es-CO");
app.UseRequestLocalization(opcionesLocalizacion);

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseAntiforgery();

// ── Proxy de imágenes hacia NexoApi ──────────────────────────────────────────
// Los <img src="api/..."> del browser no pueden mandar el JWT.
// NexoWeb recibe la petición y la reenvía al API (cuyos endpoints de imagen ya son AllowAnonymous).
{
    var apiBase = app.Configuration["NexoApi:BaseUrl"]!.TrimEnd('/');

    static async Task<IResult> ProxyImagen(string apiUrl, IHttpClientFactory hf)
    {
        var client = hf.CreateClient("img-proxy");
        HttpResponseMessage resp;
        try { resp = await client.GetAsync(apiUrl); }
        catch { return Results.NotFound(); }
        if (!resp.IsSuccessStatusCode) return Results.NotFound();
        var bytes = await resp.Content.ReadAsByteArrayAsync();
        var mime  = resp.Content.Headers.ContentType?.MediaType ?? "image/jpeg";
        return Results.File(bytes, mime);
    }

    app.MapGet("api/catalogo/articulos/{id:int}/imagen",
        (int id, IHttpClientFactory hf) => ProxyImagen($"{apiBase}/api/catalogo/articulos/{id}/imagen", hf));

    app.MapGet("api/rrhh/empleados/{id:int}/foto",
        (int id, IHttpClientFactory hf) => ProxyImagen($"{apiBase}/api/rrhh/empleados/{id}/foto", hf));

    app.MapGet("api/marketing/combos/{id:int}/imagen",
        (int id, IHttpClientFactory hf) => ProxyImagen($"{apiBase}/api/marketing/combos/{id}/imagen", hf));
}

app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode()
    .AllowAnonymous(); // evita que ASP.NET Core exija un IAuthenticationService real a nivel de endpoint;
                       // la autorizacion queda 100% a cargo de AuthorizeRouteView + CustomAuthStateProvider

app.Run();