using NexoApi.Features.Crm;

namespace NexoApi.Infrastructure;

// Evalúa las reglas periódicas de automatización CRM cada hora.
public class AutomationBackgroundService : BackgroundService
{
    private readonly IServiceProvider _services;
    private readonly ILogger<AutomationBackgroundService> _logger;

    public AutomationBackgroundService(IServiceProvider services, ILogger<AutomationBackgroundService> logger)
    {
        _services = services;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        // Primera ejecución 5 minutos tras el arranque, luego cada hora.
        await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = _services.CreateScope();
                var automation = scope.ServiceProvider.GetRequiredService<IAutomacionService>();
                await automation.EvaluarReglasPeriodicasAsync();
                _logger.LogInformation("Automatización CRM: evaluación periódica completada ({Hora})", DateTime.Now);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en AutomationBackgroundService");
            }

            await Task.Delay(TimeSpan.FromHours(1), stoppingToken);
        }
    }
}
