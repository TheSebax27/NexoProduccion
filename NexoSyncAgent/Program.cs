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
builder.Services.AddScoped<TareaExportarEntradasVisions>();
builder.Services.AddScoped<TareaSincronizarCatalogos>();
builder.Services.AddScoped<TareaSincronizarFacturasNexoVisions>();
builder.Services.AddScoped<TareaImportarCambiosTarjeta>();
builder.Services.AddScoped<TareaDetectarArticulosFaltantes>();
builder.Services.AddScoped<TareaSincronizarClientes>();
builder.Services.AddScoped<TareaSincronizarProveedores>();
builder.Services.AddScoped<TareaSincronizarPedidos>();
builder.Services.AddScoped<TareaSincronizarAdicionales>();

// HttpClient tipado: cada vez que alguien pida INexoApiClient, le dan un
// NexoApiClient ya configurado con la URL base y el header de autenticacion.
builder.Services.AddHttpClient<INexoApiClient, NexoApiClient>((sp, client) =>
{
    var config = sp.GetRequiredService<IConfiguration>();

    // Si hay Subdomain configurado, construir la URL automaticamente.
    // En desarrollo (Subdomain vacio) se usa BaseUrl directo (localhost).
    var subdomain = config["NexoApi:Subdomain"];
    var baseUrl = !string.IsNullOrWhiteSpace(subdomain)
        ? $"https://{subdomain}.{config["NexoApi:Domain"]}/"
        : config["NexoApi:BaseUrl"]!;

    client.BaseAddress = new Uri(baseUrl);
    client.DefaultRequestHeaders.Add("X-Api-Key", config["NexoApi:ApiKey"]);

    // TenantHost lo genera la API al crear el instalador e identifica al cliente.
    // Se envía como X-Nexo-Host para que TenantMiddleware resuelva el tenant correcto
    // aunque la URL de la API sea un dominio compartido (apinexo.colombiasis.com).
    var tenantHost = config["NexoApi:TenantHost"];
    if (!string.IsNullOrWhiteSpace(tenantHost))
        client.DefaultRequestHeaders.Add("X-Nexo-Host", tenantHost);

    client.Timeout = TimeSpan.FromMinutes(15);
})
.ConfigurePrimaryHttpMessageHandler((sp) =>
{
    var cfg = sp.GetRequiredService<IConfiguration>();
    var subdomain = cfg["NexoApi:Subdomain"];
    var baseUrl = !string.IsNullOrWhiteSpace(subdomain)
        ? $"https://{subdomain}.{cfg["NexoApi:Domain"]}/"
        : cfg["NexoApi:BaseUrl"] ?? "";
    // PooledConnectionLifetime evita que el agente reutilice conexiones TCP que el
    // servidor (Kestrel en VS) ya cerró al reiniciar, lo que causaba SocketError 995.
    var handler = new SocketsHttpHandler
    {
        PooledConnectionLifetime = TimeSpan.FromMinutes(2)
    };
    if (baseUrl.Contains("localhost", StringComparison.OrdinalIgnoreCase))
        handler.SslOptions = new System.Net.Security.SslClientAuthenticationOptions
        {
            RemoteCertificateValidationCallback = (_, _, _, _) => true
        };
    return handler;
});

builder.Services.AddHostedService<Worker>();

var host = builder.Build();
host.Run();