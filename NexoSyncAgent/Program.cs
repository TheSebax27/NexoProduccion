using NexoSyncAgent;
using NexoSyncAgent.NexoApiClient;
using NexoSyncAgent.Tareas;
using NexoSyncAgent.VisionsData;

var builder = Host.CreateApplicationBuilder(args);

// Permite que, al instalarlo como Servicio de Windows, los logs
// se integren con el Visor de Sucesos de Windows.
builder.Services.AddWindowsService();

builder.Services.AddSingleton<IVisionsConnectionFactory, VisionsConnectionFactory>();

builder.Services.AddScoped<TareaAplicarEntradasInventario>();
builder.Services.AddScoped<TareaExportarVentas>();

// HttpClient tipado: cada vez que alguien pida INexoApiClient, le dan un
// NexoApiClient ya configurado con la URL base y el header de autenticacion.
builder.Services.AddHttpClient<INexoApiClient, NexoApiClient>((sp, client) =>
{
    var config = sp.GetRequiredService<IConfiguration>();
    client.BaseAddress = new Uri(config["NexoApi:BaseUrl"]!);
    client.DefaultRequestHeaders.Add("X-Api-Key", config["NexoApi:ApiKey"]);
});

builder.Services.AddHostedService<Worker>();

var host = builder.Build();
host.Run();