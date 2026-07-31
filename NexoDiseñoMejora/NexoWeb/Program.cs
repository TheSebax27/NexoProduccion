using Microsoft.AspNetCore.Components.Authorization;
using NexoWeb.Common.Auth;
using MudBlazor;
using MudBlazor.Services;
using NexoWeb.Common.ApiClient;
using NexoWeb.Components;

// Valores por defecto globales de MudBlazor: al definirlos aqui, TODOS los
// MudTextField/MudSelect/MudNumericField/etc. de la aplicacion (Catalogo,
// Compras, Produccion, Inventario, Traspasos...) adoptan automaticamente el
// mismo estilo "Outlined" premium, sin tener que tocar cada formulario uno
// por uno. Esto es clave para el Design System: consistencia total sin
// riesgo de romper la logica de cada pagina (solo cambia la presentacion).
MudGlobal.InputDefaults.Variant = Variant.Outlined;
MudGlobal.InputDefaults.ShrinkLabel = true;

var builder = WebApplication.CreateBuilder(args);

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

var app = builder.Build();

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