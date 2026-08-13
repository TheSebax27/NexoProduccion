using NexoSyncAgent.NexoApiClient;
using NexoSyncAgent.NexoApiClient.Dtos;
using NexoSyncAgent.Tareas;

namespace NexoSyncAgent;

public class Worker : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<Worker> _logger;
    // El intervalo base puede actualizarse desde la API en cada ciclo.
    // IntervalSeconds en appsettings.json solo sirve como override de pruebas (si > 0 gana).
    private TimeSpan _intervalo;
    private readonly TimeSpan? _overrideSegundos;
    private TimeSpan _backoffActual = TimeSpan.Zero;

    public Worker(IServiceProvider serviceProvider, ILogger<Worker> logger, IConfiguration configuration)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;

        var segundos = configuration.GetValue<int>("Sync:IntervalSeconds", 0);
        if (segundos > 0)
            _overrideSegundos = TimeSpan.FromSeconds(segundos);

        var minutosDefault = configuration.GetValue<double>("Sync:IntervalMinutes", 5);
        _intervalo = _overrideSegundos ?? TimeSpan.FromMinutes(minutosDefault);
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Agente NEXO iniciado. Intervalo: {Intervalo}", _intervalo);

        while (!stoppingToken.IsCancellationRequested)
        {
            var espera = _backoffActual > TimeSpan.Zero ? _backoffActual : _intervalo;

            try
            {
                using var scope = _serviceProvider.CreateScope();

                // 1. Latido — confirma conectividad con NEXO y actualiza UltimaConexion.
                //    Si falla, se registra el error y se salta la ronda completa con backoff.
                var apiClient = scope.ServiceProvider.GetRequiredService<INexoApiClient>();
                LatidoResponse latido;
                try
                {
                    latido = await apiClient.EnviarLatidoAsync(stoppingToken);
                    _backoffActual = TimeSpan.Zero;
                    _logger.LogInformation(
                        "Latido OK. Hora servidor: {HoraServidor:HH:mm:ss}. Eventos pendientes en NEXO: {Pendientes}",
                        latido.HoraServidor, latido.EventosPendientes);
                }
                catch (Exception exLatido) when (EsErrorDeConectividad(exLatido))
                {
                    _backoffActual = CalcularBackoff(_backoffActual, _intervalo);
                    _logger.LogWarning(
                        "NEXO no esta disponible ({Error}). Reintentando en {Backoff:mm\\:ss} min.",
                        exLatido.Message, _backoffActual);
                    await Task.Delay(_backoffActual, stoppingToken);
                    continue;
                }

                // 2. Sincronizar configuracion (prefijos de venta, activo/inactivo).
                //    Si el admin cambio el intervalo desde la web, se aplica aqui.
                var tareaConfiguracion = scope.ServiceProvider.GetRequiredService<TareaSincronizarConfiguracion>();
                var (centroCostoVisions, intervalApi) = await tareaConfiguracion.EjecutarAsync(stoppingToken);
                if (_overrideSegundos is null && intervalApi > 0)
                    _intervalo = TimeSpan.FromMinutes(intervalApi);

                // 3. Aplicar entradas de inventario (NEXO → Visions: stock por OPs/traspasos).
                var tareaEntradas = scope.ServiceProvider.GetRequiredService<TareaAplicarEntradasInventario>();
                await tareaEntradas.EjecutarAsync(stoppingToken);

                // 4. Exportar ventas (Visions → NEXO: lo que se vendio en el POS).
                //    Solo si el Admin ya configuro el codigo CENTROCOSTO de Visions.
                if (centroCostoVisions is not null)
                {
                    var tareaVentas = scope.ServiceProvider.GetRequiredService<TareaExportarVentas>();
                    await tareaVentas.EjecutarAsync(centroCostoVisions!.Value, stoppingToken);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Fallo inesperado en la ronda de sincronizacion");
            }

            await Task.Delay(espera, stoppingToken);
        }
    }

    private static bool EsErrorDeConectividad(Exception ex) =>
        ex is HttpRequestException or TaskCanceledException or OperationCanceledException
        || ex.Message.Contains("refused") || ex.Message.Contains("timeout", StringComparison.OrdinalIgnoreCase);

    private static TimeSpan CalcularBackoff(TimeSpan actual, TimeSpan maximo)
    {
        // 30s → 60s → 120s → ... hasta el intervalo normal configurado.
        var siguiente = actual == TimeSpan.Zero ? TimeSpan.FromSeconds(30) : actual * 2;
        return siguiente > maximo ? maximo : siguiente;
    }
}
