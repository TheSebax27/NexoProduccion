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
    .AddInteractiveServerComponents();

// MudBlazor
builder.Services.AddMudServices();

// El cliente HTTP hacia NexoApi, con su URL base ya configurada
builder.Services.AddHttpClient<INexoApiClient, NexoApiClient>((sp, client) =>
{
    var config = sp.GetRequiredService<IConfiguration>();
    client.BaseAddress = new Uri(config["NexoApi:BaseUrl"]!);
});

builder.Services.AddAuthorizationCore(); // el "motor" de autorizacion de Blazor (distinto al AddAuthorization de la API)
builder.Services.AddScoped<AuthStateService>();
builder.Services.AddScoped<AuthenticationStateProvider, CustomAuthStateProvider>();
builder.Services.AddScoped<PreferenciasState>();
builder.Services.AddScoped<ConfiguracionEmpresaState>();

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

app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode()
    .AllowAnonymous(); // evita que ASP.NET Core exija un IAuthenticationService real a nivel de endpoint;
                       // la autorizacion queda 100% a cargo de AuthorizeRouteView + CustomAuthStateProvider

app.Run();