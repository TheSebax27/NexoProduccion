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

    private readonly string _version;
    // Timestamp de la ultima sync de clientes exitosa (persiste durante la vida del servicio).
    private DateTime? _ultimaSyncClientes;

    public Worker(IServiceProvider serviceProvider, ILogger<Worker> logger, IConfiguration configuration)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
        _version = configuration.GetValue<string>("Sync:AgentVersion") ?? "1.0.0";

        var segundos = configuration.GetValue<int>("Sync:IntervalSeconds", 0);
        if (segundos > 0)
            _overrideSegundos = TimeSpan.FromSeconds(segundos);

        var minutosDefault = configuration.GetValue<double>("Sync:IntervalMinutes", 5);
        _intervalo = _overrideSegundos ?? TimeSpan.FromMinutes(minutosDefault);
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Agente NEXO v{Version} iniciado. Intervalo: {Intervalo}", _version, _intervalo);

        // Crear tablas NEXO_* en Visions si no existen (primera vez o reinstalacion).
        using (var scope = _serviceProvider.CreateScope())
        {
            var tareaInit = scope.ServiceProvider.GetRequiredService<TareaInicializarVisions>();
            await tareaInit.EjecutarAsync();
        }

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
                    latido = await apiClient.EnviarLatidoAsync(_version, stoppingToken);
                    _backoffActual = TimeSpan.Zero;
                    _logger.LogInformation(
                        "Latido OK. Hora servidor: {HoraServidor:HH:mm:ss}. Eventos pendientes en NEXO: {Pendientes}",
                        latido.HoraServidor, latido.EventosPendientes);

                    if (latido.VersionDisponible is not null && latido.VersionDisponible != _version)
                        _logger.LogWarning(
                            "Hay una actualizacion del agente disponible: v{Disponible} (instalada: v{Actual}). Descarga el instalador desde NEXO Web > Integracion Visions.",
                            latido.VersionDisponible, _version);
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

                // 3. Solo si el Admin ya configuro el codigo CENTROCOSTO de Visions.
                if (centroCostoVisions is not null)
                {
                    // 3. Sincronizar catalogos bidireccional (Marcas → GrupoMayor → GrupoMenor → IVA → Presentaciones).
                    //    Va PRIMERO: antes de cualquier sync de articulos en cualquier direccion, para que
                    //    los codigos de Marca/GrupoMayor/GrupoMenor/Presentacion ya existan en NEXO y en
                    //    Visions cuando se sincronicen articulos (evita FK violations y codigos huerfanos).
                    var tareaCatalogos = scope.ServiceProvider.GetRequiredService<TareaSincronizarCatalogos>();
                    await tareaCatalogos.EjecutarAsync(stoppingToken);

                    // 4. Aplicar entradas de inventario y sync de articulos (NEXO → Visions).
                    //    Va despues de catalogos para que GRUPOMENOR/MARCA/PRESENTACION ya existan en Visions.
                    var tareaEntradas = scope.ServiceProvider.GetRequiredService<TareaAplicarEntradasInventario>();
                    await tareaEntradas.EjecutarAsync(stoppingToken);

                    // 5. Exportar ventas (Visions → NEXO: lo que se vendio en el POS).
                    var tareaVentas = scope.ServiceProvider.GetRequiredService<TareaExportarVentas>();
                    await tareaVentas.EjecutarAsync(centroCostoVisions!.Value, stoppingToken);

                    // 6. Importar cambios de TARJETA desde Visions → NEXO (precio/nombre/marca modificados en el POS).
                    var tareaImportarTarjeta = scope.ServiceProvider.GetRequiredService<TareaImportarCambiosTarjeta>();
                    await tareaImportarTarjeta.EjecutarAsync(centroCostoVisions!.Value, stoppingToken);

                    // 7. Detectar articulos de Visions que aun no existen en NEXO y crearlos (en lotes, con datos completos).
                    var tareaArticulosFaltantes = scope.ServiceProvider.GetRequiredService<TareaDetectarArticulosFaltantes>();
                    await tareaArticulosFaltantes.EjecutarAsync(centroCostoVisions!.Value, stoppingToken);

                    // 8. Sincronizar clientes NEXO → Visions (upsert en NEXO_Clientes).
                    //    Va antes de facturas: las facturas referencian NIT de cliente en Visions.
                    var tareaClientes = scope.ServiceProvider.GetRequiredService<TareaSincronizarClientes>();
                    await tareaClientes.EjecutarAsync(_ultimaSyncClientes, stoppingToken);
                    _ultimaSyncClientes = DateTime.UtcNow;

                    // 9. Exportar facturas NEXO → Visions (las que tienen stock descontado y aun no estan en MOVDETALLES).
                    var tareaFacturasVisions = scope.ServiceProvider.GetRequiredService<TareaSincronizarFacturasNexoVisions>();
                    await tareaFacturasVisions.EjecutarAsync(centroCostoVisions!.Value, stoppingToken);
                }
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
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
