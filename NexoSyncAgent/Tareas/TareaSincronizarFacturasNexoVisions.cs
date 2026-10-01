using Dapper;
using NexoSyncAgent.NexoApiClient;
using NexoSyncAgent.NexoApiClient.Dtos;
using NexoSyncAgent.VisionsData;

namespace NexoSyncAgent.Tareas;

// NEXO → Visions: escribe facturas creadas en NEXO en la tabla de staging
// NEXO_FacturasPendientes + NEXO_FacturasPendientesLineas en VISIONSDBL1.
// Un boton/script en Visions lee esas facturas via NEXO_SP_FacturasPendientes,
// las procesa y llama NEXO_SP_ConfirmarFactura para registrar el NRODOC asignado.
// En la segunda fase, este task lee los confirmados y actualiza NEXO via API.
public class TareaSincronizarFacturasNexoVisions
{
    private readonly INexoApiClient _apiClient;
    private readonly IVisionsConnectionFactory _visionsDb;
    private readonly ILogger<TareaSincronizarFacturasNexoVisions> _logger;

    public TareaSincronizarFacturasNexoVisions(
        INexoApiClient apiClient, IVisionsConnectionFactory visionsDb, ILogger<TareaSincronizarFacturasNexoVisions> logger)
    {
        _apiClient = apiClient;
        _visionsDb = visionsDb;
        _logger = logger;
    }

    public async Task EjecutarAsync(int centroCostoVisions, CancellationToken ct)
    {
        await LimpiarEliminadasEnVisionsAsync(ct);
        await ExportarFacturasNuevasAsync(ct);
        await SincronizarNumerosDesdeVisionsAsync(ct);
    }

    // Fase 0: limpiar del staging de Visions las facturas que fueron eliminadas en NEXO
    private async Task LimpiarEliminadasEnVisionsAsync(CancellationToken ct)
    {
        var pendientes = await _apiClient.ListarPendientesLimpiezaVisionsAsync(ct);
        if (pendientes.Count == 0) return;

        _logger.LogInformation("Limpiando {N} facturas eliminadas del staging de Visions", pendientes.Count);
        using var connection = _visionsDb.CreateConnection();

        foreach (var p in pendientes)
        {
            if (ct.IsCancellationRequested) break;
            try
            {
                if (p.Tipo == "FACTURA")
                {
                    await connection.ExecuteAsync(
                        "DELETE FROM dbo.NEXO_FacturasPendientesLineas WHERE FacturaID = @Id",
                        new { Id = p.EntidadID });
                    await connection.ExecuteAsync(
                        "DELETE FROM dbo.NEXO_FacturasPendientes WHERE FacturaID = @Id",
                        new { Id = p.EntidadID });
                }
                else if (p.Tipo == "PEDIDO")
                {
                    await connection.ExecuteAsync(
                        "DELETE FROM dbo.NEXO_PedidosLineas WHERE PedidoID = @Id",
                        new { Id = p.EntidadID });
                    await connection.ExecuteAsync(
                        "DELETE FROM dbo.NEXO_Pedidos WHERE PedidoID = @Id",
                        new { Id = p.EntidadID });
                }
                await _apiClient.MarcarLimpiezaVisionsCompletadaAsync(p.LimpiezaID, ct);
                _logger.LogInformation("{Tipo} NEXO {ID} eliminado del staging de Visions", p.Tipo, p.EntidadID);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al limpiar factura NEXO {ID} del staging de Visions", p.EntidadID);
            }
        }
    }

    // Fase 1: escribir facturas nuevas al staging de Visions
    private async Task ExportarFacturasNuevasAsync(CancellationToken ct)
    {
        var facturas = await _apiClient.ListarFacturasParaVisionsAsync(ct);
        if (facturas.Count == 0) return;

        _logger.LogInformation("Encontradas {Cantidad} facturas NEXO para exportar a Visions", facturas.Count);

        using var connection = _visionsDb.CreateConnection();

        foreach (var factura in facturas)
        {
            if (ct.IsCancellationRequested) break;
            try
            {
                await EscribirStagingAsync(factura, connection);
                await _apiClient.MarcarFacturaExportadaVisionsAsync(factura.FacturaID, ct);
                _logger.LogInformation("Factura NEXO {ID} registrada en staging Visions", factura.FacturaID);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al exportar factura NEXO {ID} a staging Visions", factura.FacturaID);
            }
        }
    }

    private async Task EscribirStagingAsync(FacturaParaVisionsDto factura, System.Data.IDbConnection connection)
    {
        var totalLineas = factura.Lineas.Sum(l => l.Cantidad * l.PrecioUnitario);

        // Upsert del encabezado: si ya existe no duplicar
        var existente = await connection.ExecuteScalarAsync<int>(
            "SELECT COUNT(1) FROM dbo.NEXO_FacturasPendientes WHERE FacturaID=@FacturaID",
            new { factura.FacturaID });

        if (existente > 0)
            return; // ya fue enviado en ciclo anterior

        var lineasMapeadas = factura.Lineas.Where(l => l.ReferenciaVisions is not null).ToList();
        if (lineasMapeadas.Count == 0)
        {
            _logger.LogWarning("Factura {FacturaID} omitida: ninguna línea tiene ReferenciaVisions (artículos sin mapeo Visions).", factura.FacturaID);
            return;
        }

        await connection.ExecuteAsync(
            @"INSERT INTO dbo.NEXO_FacturasPendientes
                (FacturaID, NIT, NombreCliente, Fecha, TipDoc, TotalNexo, Estado, FechaEnvio)
              VALUES
                (@FacturaID, @NIT, @NombreCliente, @Fecha, @TipDoc, @TotalNexo, 'PENDIENTE', GETDATE())",
            new
            {
                factura.FacturaID,
                NIT           = factura.ClienteNit ?? "",
                NombreCliente = factura.ClienteNombre ?? "",
                factura.Fecha,
                TipDoc        = factura.TipDoc ?? "FACTURA",
                TotalNexo     = totalLineas
            });

        var orden = 0;
        foreach (var linea in lineasMapeadas)
        {
            orden++;
            var subtotal = linea.Cantidad * linea.PrecioUnitario;

            await connection.ExecuteAsync(
                @"INSERT INTO dbo.NEXO_FacturasPendientesLineas
                    (FacturaID, Orden, Referencia, Detalle, Cantidad, PrecioUnitario, Total)
                  VALUES
                    (@FacturaID, @Orden, @Referencia, @Detalle, @Cantidad, @PrecioUnitario, @Total)",
                new
                {
                    factura.FacturaID,
                    Orden        = orden,
                    Referencia   = linea.ReferenciaVisions,
                    Detalle      = linea.NombreArticulo ?? "",
                    linea.Cantidad,
                    linea.PrecioUnitario,
                    Total        = subtotal
                });
        }
    }

    // Fase 2: leer confirmaciones de Visions y actualizar NEXO
    private async Task SincronizarNumerosDesdeVisionsAsync(CancellationToken ct)
    {
        using var connection = _visionsDb.CreateConnection();

        var confirmadas = (await connection.QueryAsync<FacturaConfirmada>(
            @"SELECT FacturaID, TipDocVisions, NroDocVisions
              FROM dbo.NEXO_FacturasPendientes
              WHERE Estado='PROCESADA' AND NroDocVisions IS NOT NULL AND TipDocVisions IS NOT NULL
                AND FacturaID NOT IN (
                    SELECT FacturaID FROM dbo.NEXO_FacturasSalientes WHERE FechaSyncBack IS NOT NULL
                )")).ToList();

        if (confirmadas.Count == 0) return;

        _logger.LogInformation("Actualizando {N} facturas confirmadas por Visions en NEXO", confirmadas.Count);

        foreach (var f in confirmadas)
        {
            if (ct.IsCancellationRequested) break;
            try
            {
                await _apiClient.ActualizarNumeroVisionsAsync(
                    f.FacturaID,
                    new ActualizarNumeroVisionsRequest(f.TipDocVisions!, f.NroDocVisions!),
                    ct);

                await connection.ExecuteAsync(
                    @"IF NOT EXISTS (SELECT 1 FROM dbo.NEXO_FacturasSalientes WHERE FacturaID=@FacturaID)
                        INSERT INTO dbo.NEXO_FacturasSalientes (FacturaID, NexoNroDoc, TipDocVisions, NroDocVisions, FechaEnvio, FechaSyncBack)
                        VALUES (@FacturaID, 'NEXO-'+CAST(@FacturaID AS nvarchar), @TipDoc, @NroDoc, GETDATE(), GETDATE())
                      ELSE
                        UPDATE dbo.NEXO_FacturasSalientes SET FechaSyncBack=GETDATE() WHERE FacturaID=@FacturaID",
                    new { f.FacturaID, TipDoc = f.TipDocVisions ?? "", NroDoc = f.NroDocVisions ?? "" });

                _logger.LogInformation("Factura NEXO {ID} actualizada con número Visions {NroDoc}",
                    f.FacturaID, f.NroDocVisions);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al actualizar número Visions para factura NEXO {ID}", f.FacturaID);
            }
        }
    }

    private record FacturaConfirmada(int FacturaID, string? TipDocVisions, string? NroDocVisions);
}
