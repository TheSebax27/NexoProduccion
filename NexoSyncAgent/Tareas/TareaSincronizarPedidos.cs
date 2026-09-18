using Dapper;
using NexoSyncAgent.NexoApiClient;
using NexoSyncAgent.NexoApiClient.Dtos;
using NexoSyncAgent.VisionsData;

namespace NexoSyncAgent.Tareas;

// NEXO → Visions: escribe pedidos (órdenes de compra) creados en NEXO en la tabla
// de staging NEXO_Pedidos + NEXO_PedidosLineas en VISIONSDBL1.
// Un botón en Visions (Entradas) lee los pedidos via NEXO_SP_PedidosPendientes,
// los registra como Entrada de Mercancía y llama NEXO_SP_ConfirmarPedido con el NRODOC asignado.
// En la segunda fase, este task lee los confirmados y actualiza NEXO via API.
// TipoMovimiento: 'COMPRA' = Entrada de inventario | 'DEVOLUCION' = Salida (devolución al proveedor).
public class TareaSincronizarPedidos
{
    private readonly INexoApiClient _apiClient;
    private readonly IVisionsConnectionFactory _visionsDb;
    private readonly ILogger<TareaSincronizarPedidos> _logger;

    public TareaSincronizarPedidos(
        INexoApiClient apiClient, IVisionsConnectionFactory visionsDb, ILogger<TareaSincronizarPedidos> logger)
    {
        _apiClient = apiClient;
        _visionsDb = visionsDb;
        _logger = logger;
    }

    public async Task EjecutarAsync(CancellationToken ct)
    {
        await ExportarPedidosNuevosAsync(ct);
        await SincronizarNumerosDesdeVisionsAsync(ct);
    }

    // Fase 1: escribir pedidos nuevos al staging de Visions
    private async Task ExportarPedidosNuevosAsync(CancellationToken ct)
    {
        var pedidos = await _apiClient.ListarPedidosParaVisionsAsync(ct);
        if (pedidos.Count == 0) return;

        _logger.LogInformation("Encontrados {Cantidad} pedidos NEXO para exportar a Visions", pedidos.Count);

        using var connection = _visionsDb.CreateConnection();

        foreach (var pedido in pedidos)
        {
            if (ct.IsCancellationRequested) break;
            try
            {
                await EscribirStagingAsync(pedido, connection);
                await _apiClient.MarcarPedidoExportadoVisionsAsync(pedido.PedidoID, ct);
                _logger.LogInformation("Pedido NEXO {ID} ({Tipo}) registrado en staging Visions",
                    pedido.PedidoID, pedido.TipoMovimiento);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al exportar pedido NEXO {ID} a staging Visions", pedido.PedidoID);
            }
        }
    }

    private async Task EscribirStagingAsync(PedidoParaVisionsDto pedido, System.Data.IDbConnection connection)
    {
        var existente = await connection.ExecuteScalarAsync<int>(
            "SELECT COUNT(1) FROM dbo.NEXO_Pedidos WHERE PedidoID = @PedidoID",
            new { pedido.PedidoID });

        if (existente > 0)
            return; // ya fue enviado en ciclo anterior

        var total = pedido.Lineas.Sum(l => l.Cantidad * l.CostoUnitario);

        await connection.ExecuteAsync(
            @"INSERT INTO dbo.NEXO_Pedidos
                (PedidoID, Codigo, NombreProveedor, NITProveedor, Fecha, TotalNexo, TipoMovimiento, Estado, FechaEnvio)
              VALUES
                (@PedidoID, @Codigo, @NombreProveedor, @NITProveedor, @Fecha, @TotalNexo, @TipoMovimiento, 'PENDIENTE', GETDATE())",
            new
            {
                pedido.PedidoID,
                Codigo          = pedido.Codigo ?? "",
                NombreProveedor = pedido.ProveedorNombre ?? "",
                NITProveedor    = pedido.ProveedorNit ?? "",
                pedido.Fecha,
                TotalNexo       = total,
                TipoMovimiento  = pedido.TipoMovimiento ?? "COMPRA"
            });

        var orden = 0;
        foreach (var linea in pedido.Lineas)
        {
            if (linea.ReferenciaVisions is null) continue;
            orden++;
            var subtotal = linea.Cantidad * linea.CostoUnitario;

            await connection.ExecuteAsync(
                @"INSERT INTO dbo.NEXO_PedidosLineas
                    (PedidoID, Orden, Referencia, Detalle, Cantidad, PrecioUnitario, Total)
                  VALUES
                    (@PedidoID, @Orden, @Referencia, @Detalle, @Cantidad, @PrecioUnitario, @Total)",
                new
                {
                    pedido.PedidoID,
                    Orden         = orden,
                    Referencia    = linea.ReferenciaVisions,
                    Detalle       = linea.NombreArticulo ?? "",
                    linea.Cantidad,
                    PrecioUnitario = linea.CostoUnitario,
                    Total         = subtotal
                });
        }
    }

    // Fase 2: leer confirmaciones de Visions y actualizar NEXO con el número de documento asignado
    private async Task SincronizarNumerosDesdeVisionsAsync(CancellationToken ct)
    {
        using var connection = _visionsDb.CreateConnection();

        // Solo pedidos que Visions ya procesó (PROCESADA) y aún no hemos sincronizado de vuelta (no SINCRONIZADO).
        var confirmados = (await connection.QueryAsync<PedidoConfirmado>(
            @"SELECT PedidoID, TipDocVisions, NroDocVisions
              FROM dbo.NEXO_Pedidos
              WHERE Estado = 'PROCESADA' AND NroDocVisions IS NOT NULL AND TipDocVisions IS NOT NULL")).ToList();

        if (confirmados.Count == 0) return;

        _logger.LogInformation("Actualizando {N} pedidos confirmados por Visions en NEXO", confirmados.Count);

        foreach (var p in confirmados)
        {
            if (ct.IsCancellationRequested) break;
            try
            {
                await _apiClient.ActualizarNumeroPedidoVisionsAsync(
                    p.PedidoID,
                    new ActualizarNumeroPedidoVisionsRequest(p.TipDocVisions!, p.NroDocVisions!),
                    ct);

                // Marcar SINCRONIZADO antes de AutoRecibir: NroDoc ya fue escrito en NEXO.
                // AutoRecibir es best-effort; si falla, el pedido no vuelve a reprocesar ActualizarNumeroPedido.
                await connection.ExecuteAsync(
                    "UPDATE dbo.NEXO_Pedidos SET Estado = 'SINCRONIZADO' WHERE PedidoID = @PedidoID",
                    new { p.PedidoID });

                // Reintentar auto-recibir ante errores transitorios de red (ej.: API reiniciando en VS).
                for (int intento = 0; intento < 3; intento++)
                {
                    try
                    {
                        await _apiClient.AutoRecibirDesdeVisionsAsync(p.PedidoID, p.NroDocVisions!, ct);
                        break;
                    }
                    catch (Exception ex) when (!ct.IsCancellationRequested && intento < 2)
                    {
                        _logger.LogWarning("Auto-recibir pedido {ID} intento {N} fallido, reintentando en 5s...",
                            p.PedidoID, intento + 1);
                        await Task.Delay(TimeSpan.FromSeconds(5), ct);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Auto-recibir pedido {ID} fallido definitivamente; NroDoc ya guardado en NEXO", p.PedidoID);
                        break;
                    }
                }

                _logger.LogInformation("Pedido NEXO {ID} sincronizado con número Visions {NroDoc}",
                    p.PedidoID, p.NroDocVisions);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al actualizar número Visions para pedido NEXO {ID}", p.PedidoID);
            }
        }
    }

    private record PedidoConfirmado(int PedidoID, string? TipDocVisions, string? NroDocVisions);
}
