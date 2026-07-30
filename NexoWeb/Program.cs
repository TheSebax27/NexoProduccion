using Microsoft.AspNetCore.Components.Authorization;
using NexoWeb.Common.Auth;
using MudBlazor.Services;
using NexoWeb.Common.ApiClient;
using NexoWeb.Components;

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