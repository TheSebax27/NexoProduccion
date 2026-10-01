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
    // Timestamps para el sync completo Visions → NEXO (full scan, se limita a 1 vez por hora).
    private DateTime _ultimaSyncVisionsANexoClientes   = DateTime.MinValue;
    private DateTime _ultimaSyncVisionsANexoProveedores = DateTime.MinValue;
    private static readonly TimeSpan IntervaloSyncVisionsANexo = TimeSpan.FromHours(1);

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
            await tareaInit.EjecutarAsync(stoppingToken);
        }

        while (!stoppingToken.IsCancellationRequested)
        {
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
                catch (ApiKeyInvalidaException exKey)
                {
                    // No es un error de red: reintentar con backoff no ayuda.
                    // El administrador debe corregir la ApiKey en appsettings.json.
                    _logger.LogError(
                        "⛔ API KEY INVALIDA — {Mensaje}", exKey.Message);
                    // Esperar el intervalo normal (sin backoff) para que el log sea visible
                    // pero no inunde el Event Viewer. El error persiste hasta que se corrija la clave.
                    await Task.Delay(_intervalo, stoppingToken);
                    continue;
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
                catch (Exception exLatido)
                {
                    // Cualquier otro fallo en el latido (ej. JsonException, respuesta inesperada del servidor).
                    // Se salta el ciclo completo para evitar ejecutar tareas de sync sin confirmacion de conectividad.
                    _backoffActual = CalcularBackoff(_backoffActual, _intervalo);
                    _logger.LogError(
                        exLatido,
                        "Error inesperado en latido. Saltando ciclo. Reintentando en {Backoff:mm\\:ss} min.",
                        _backoffActual);
                    await Task.Delay(_backoffActual, stoppingToken);
                    continue;
                }

                // 2. Sincronizar configuracion (prefijos de venta, activo/inactivo).
                //    Si el admin cambio el intervalo desde la web, se aplica aqui.
                var tareaConfiguracion = scope.ServiceProvider.GetRequiredService<TareaSincronizarConfiguracion>();
                var (centroCostoVisions, intervalApi, fechaInicioSyncVentas) = await tareaConfiguracion.EjecutarAsync(stoppingToken);
                if (_overrideSegundos is null && intervalApi > 0)
                    _intervalo = TimeSpan.FromMinutes(intervalApi);

                // 3. Solo si el Admin ya configuro el codigo CENTROCOSTO de Visions.
                if (centroCostoVisions is not null)
                {
                    // 3. Catalogos bidireccional (Marcas → GrupoMayor → GrupoMenor → IVA → Presentaciones).
                    //    SIEMPRE PRIMERO: los codigos de catalogo deben existir en ambos sistemas
                    //    antes de que cualquier articulo los referencie. Evita FK violations y
                    //    codigos huerfanos en MARCA/GRUPOMENOR/PRESENTACION.
                    var tareaCatalogos = scope.ServiceProvider.GetRequiredService<TareaSincronizarCatalogos>();
                    await tareaCatalogos.EjecutarAsync(stoppingToken);

                    // 4. Articulos Visions → NEXO: crear los que aun no existen en NEXO con
                    //    todos sus datos (nombre, precios, IVA, marca, grupo, presentacion,
                    //    existencias, existencias minimas). Lotes de 500 por ciclo.
                    //    Va ANTES de cambios y ventas: el articulo debe existir en NEXO antes
                    //    de procesar modificaciones o transacciones que lo referencien.
                    var tareaArticulosFaltantes = scope.ServiceProvider.GetRequiredService<TareaDetectarArticulosFaltantes>();
                    await tareaArticulosFaltantes.EjecutarAsync(centroCostoVisions!.Value, stoppingToken);

                    // 5. Cambios de TARJETA Visions → NEXO (trigger TR_TARJETA_NexoCambios):
                    //    precio, nombre, marca, grupo, IVA modificados en el POS.
                    //    Va despues de crear faltantes: solo actualiza articulos que ya existen.
                    var tareaImportarTarjeta = scope.ServiceProvider.GetRequiredService<TareaImportarCambiosTarjeta>();
                    await tareaImportarTarjeta.EjecutarAsync(centroCostoVisions!.Value, stoppingToken);

                    // 5b. Imagenes NEXO → Visions (opcional, no critico).
                    try
                    {
                        var tareaImagenes = scope.ServiceProvider.GetRequiredService<TareaExportarImagenesAVisions>();
                        await tareaImagenes.EjecutarAsync(centroCostoVisions!.Value, stoppingToken);
                    }
                    catch (Exception exImg)
                    {
                        _logger.LogWarning(exImg, "Sync de imagenes NEXO→Visions fallo (no critico)");
                    }

                    // 5c. Adicionales (toppings) NEXO → Visions.
                    //     Va despues de cambios de TARJETA: los articulos referenciados
                    //     ya existen en Visions. Unidireccional, NEXO es la fuente de verdad.
                    //     Aislado en su propio try/catch: si las tablas aun no existen en NEXO
                    //     (migracion SQL pendiente), el fallo no interrumpe ventas ni facturas.
                    try
                    {
                        var tareaAdicionales = scope.ServiceProvider.GetRequiredService<TareaSincronizarAdicionales>();
                        await tareaAdicionales.EjecutarAsync(stoppingToken);
                    }
                    catch (Exception exAd)
                    {
                        if (exAd.Message.Contains("Invalid object name", StringComparison.OrdinalIgnoreCase)
                         || exAd.Message.Contains("no existe", StringComparison.OrdinalIgnoreCase))
                            _logger.LogWarning(exAd, "Sync adicionales omitido (tablas aun no creadas?)");
                        else
                            _logger.LogError(exAd, "Error en sync adicionales");
                    }

                    // 6. Clientes Visions → NEXO y NEXO → Visions.
                    //    Va ANTES de ventas: cuando se exporta una venta, el cliente ya existe
                    //    en NEXO con todos sus datos (nombre, telefono, municipio, departamento).
                    //    El full-scan Visions→NEXO se limita a 1 vez/hora (no tiene timestamps en Visions).
                    var ahora = DateTime.UtcNow;
                    var syncVisionsClientes   = ahora - _ultimaSyncVisionsANexoClientes   >= IntervaloSyncVisionsANexo;
                    var syncVisionsProveedores = ahora - _ultimaSyncVisionsANexoProveedores >= IntervaloSyncVisionsANexo;

                    var tareaClientes = scope.ServiceProvider.GetRequiredService<TareaSincronizarClientes>();
                    await tareaClientes.EjecutarAsync(_ultimaSyncClientes, stoppingToken, incluirVisionsANexo: syncVisionsClientes);
                    _ultimaSyncClientes = DateTime.Now; // GETDATE() en SQL es hora local; UtcNow causaba comparacion incorrecta
                    if (syncVisionsClientes) _ultimaSyncVisionsANexoClientes = DateTime.UtcNow;

                    // 6b. Proveedores Visions → NEXO y NEXO → Visions.
                    //     Un NIT puede ser CLIENTE=1 y PROVEEDOR=1 simultáneamente sin duplicados.
                    //     Va junto a clientes, antes de ventas y facturas.
                    var tareaProveedores = scope.ServiceProvider.GetRequiredService<TareaSincronizarProveedores>();
                    await tareaProveedores.EjecutarAsync(stoppingToken, incluirVisionsANexo: syncVisionsProveedores);
                    if (syncVisionsProveedores) _ultimaSyncVisionsANexoProveedores = DateTime.UtcNow;

                    // 7. Ventas Visions → NEXO: lo que se vendio en el POS (MOVDETALLES).
                    //    Va despues de articulos Y clientes: tanto el mapeo del articulo como
                    //    el registro del cliente ya existen, evitando auto-creaciones con datos
                    //    incompletos en cualquiera de los dos.
                    var tareaVentas = scope.ServiceProvider.GetRequiredService<TareaExportarVentas>();
                    await tareaVentas.EjecutarAsync(centroCostoVisions!.Value, stoppingToken, fechaInicioSyncVentas);

                    // 7b. Entradas de inventario Visions → NEXO (MOVDETALLEE, TIPOMOV ECO).
                    //     Va inmediatamente despues de ventas: mismo flujo pero en sentido entrada.
                    //     Excluye documentos que vinieron de OC de NEXO (ya tienen Kardex).
                    //     Aislado en try/catch: si la migracion SQL aun no se ejecuto en NEXO,
                    //     el fallo no interrumpe el resto del ciclo.
                    try
                    {
                        var tareaEntradasVisions = scope.ServiceProvider.GetRequiredService<TareaExportarEntradasVisions>();
                        await tareaEntradasVisions.EjecutarAsync(centroCostoVisions!.Value, stoppingToken, fechaInicioSyncVentas);
                    }
                    catch (Exception exEnt)
                    {
                        if (exEnt.Message.Contains("Invalid object name", StringComparison.OrdinalIgnoreCase)
                         || exEnt.Message.Contains("no existe", StringComparison.OrdinalIgnoreCase))
                            _logger.LogWarning(exEnt, "Sync entradas Visions→NEXO omitido (migracion SQL pendiente?)");
                        else
                            _logger.LogError(exEnt, "Error en sync entradas Visions→NEXO");
                    }

                    // 8. Eventos NEXO → Visions: SINCRONIZAR_ARTICULO, AJUSTE_INVENTARIO,
                    //    BAJA_INVENTARIO, ENTRADA_PRODUCCION, CONSUMO_INSUMO.
                    //    Va despues de ventas: NEXO ya recibio todo lo de Visions y sus eventos
                    //    reflejan datos completos y stock actualizado.
                    var tareaEntradas = scope.ServiceProvider.GetRequiredService<TareaAplicarEntradasInventario>();
                    await tareaEntradas.EjecutarAsync(stoppingToken);

                    // 9. Facturas NEXO → Visions: solo cuando articulos Y clientes ya existen
                    //    en ambos sistemas. Va al final para garantizar que no haya FKs rotas
                    //    ni referencias a NITs o referencias desconocidas en Visions.
                    try
                    {
                        var tareaFacturasVisions = scope.ServiceProvider.GetRequiredService<TareaSincronizarFacturasNexoVisions>();
                        await tareaFacturasVisions.EjecutarAsync(centroCostoVisions!.Value, stoppingToken);
                    }
                    catch (Exception exFact)
                    {
                        _logger.LogError(exFact, "Fallo en sync facturas NEXO→Visions; pedidos continuan");
                    }

                    // 10. Pedidos NEXO → Visions Entradas: órdenes de compra pendientes de procesar
                    //     en Visions como Entrada de Mercancía. Va después de facturas para
                    //     respetar el mismo orden de procesamiento (primero salidas, luego entradas).
                    //     TipoMovimiento distingue COMPRA (entrada) de DEVOLUCION (salida inversa).
                    try
                    {
                        var tareaPedidosVisions = scope.ServiceProvider.GetRequiredService<TareaSincronizarPedidos>();
                        await tareaPedidosVisions.EjecutarAsync(stoppingToken);
                    }
                    catch (Exception exPed)
                    {
                        _logger.LogError(exPed, "Fallo en sync pedidos NEXO→Visions");
                    }
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

            await Task.Delay(_backoffActual > TimeSpan.Zero ? _backoffActual : _intervalo, stoppingToken);
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
