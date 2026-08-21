using NexoSyncAgent;
using NexoSyncAgent.NexoApiClient;
using NexoSyncAgent.Tareas;
using NexoSyncAgent.VisionsData;

var builder = Host.CreateApplicationBuilder(args);

// Permite que, al instalarlo como Servicio de Windows, los logs
// se integren con el Visor de Sucesos de Windows.
builder.Services.AddWindowsService();

builder.Services.AddSingleton<IVisionsConnectionFactory, VisionsConnectionFactory>();

builder.Services.AddScoped<TareaInicializarVisions>();
builder.Services.AddScoped<TareaSincronizarConfiguracion>();
builder.Services.AddScoped<TareaAplicarEntradasInventario>();
builder.Services.AddScoped<TareaExportarVentas>();
builder.Services.AddScoped<TareaSincronizarCatalogos>();
builder.Services.AddScoped<TareaSincronizarFacturasNexoVisions>();
builder.Services.AddScoped<TareaImportarCambiosTarjeta>();
builder.Services.AddScoped<TareaDetectarArticulosFaltantes>();
builder.Services.AddScoped<TareaSincronizarClientes>();
builder.Services.AddScoped<TareaSincronizarProveedores>();

// HttpClient tipado: cada vez que alguien pida INexoApiClient, le dan un
// NexoApiClient ya configurado con la URL base y el header de autenticacion.
builder.Services.AddHttpClient<INexoApiClient, NexoApiClient>((sp, client) =>
{
    var config = sp.GetRequiredService<IConfiguration>();
    client.BaseAddress = new Uri(config["NexoApi:BaseUrl"]!);
    client.DefaultRequestHeaders.Add("X-Api-Key", config["NexoApi:ApiKey"]);
    client.Timeout = TimeSpan.FromMinutes(15);
})
.ConfigurePrimaryHttpMessageHandler((sp) =>
{
    var baseUrl = sp.GetRequiredService<IConfiguration>()["NexoApi:BaseUrl"] ?? "";
    var handler = new HttpClientHandler();
    // Solo omite validacion SSL cuando se apunta a localhost (desarrollo).
    if (baseUrl.Contains("localhost", StringComparison.OrdinalIgnoreCase))
        handler.ServerCertificateCustomValidationCallback =
            HttpClientHandler.DangerousAcceptAnyServerCertificateValidator;
    return handler;
});

builder.Services.AddHostedService<Worker>();

var host = builder.Build();
host.Run();