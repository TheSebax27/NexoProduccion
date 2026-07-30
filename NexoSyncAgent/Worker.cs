using NexoSyncAgent.Tareas;

namespace NexoSyncAgent;

public class Worker : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<Worker> _logger;
    private readonly TimeSpan _intervalo;

    public Worker(IServiceProvider serviceProvider, ILogger<Worker> logger, IConfiguration configuration)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
        _intervalo = TimeSpan.FromMinutes(configuration.GetValue<double>("Sync:IntervalMinutes", 5));
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Agente de Sincronizacion NEXO iniciado. Intervalo: {Intervalo}", _intervalo);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                // Cada tarea necesita su propio "scope" -- explicado abajo.
                using var scope = _serviceProvider.CreateScope();

                var tareaEntradas = scope.ServiceProvider.GetRequiredService<TareaAplicarEntradasInventario>();
                await tareaEntradas.EjecutarAsync(stoppingToken);

                var tareaVentas = scope.ServiceProvider.GetRequiredService<TareaExportarVentas>();
                await tareaVentas.EjecutarAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Fallo inesperado en la ronda de sincronizacion");
            }

            await Task.Delay(_intervalo, stoppingToken);
        }
    }
}