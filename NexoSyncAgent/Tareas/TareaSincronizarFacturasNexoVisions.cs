using Dapper;
using NexoSyncAgent.NexoApiClient;
using NexoSyncAgent.NexoApiClient.Dtos;
using NexoSyncAgent.VisionsData;

namespace NexoSyncAgent.Tareas;

// NEXO → Visions: escribe en MOVDETALLES las facturas creadas en NEXO
// que ya tienen stock descontado pero aun no fueron exportadas a Visions.
// Usa 'NEXO-{FacturaID}' como placeholder de NRODOC para que Visions sepa
// que el número real lo asignará su propio sistema. Un trigger en Visions
// detecta cuando se actualiza el NRODOC y lo copia a NEXO_FacturasSalientes.
// En la segunda fase, este task lee esa tabla y actualiza NEXO vía API.
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
        // Fase 1: exportar facturas nuevas de NEXO → Visions MOVDETALLES
        await ExportarFacturasNuevasAsync(centroCostoVisions, ct);

        // Fase 2: leer números asignados por Visions y actualizar NEXO
        await SincronizarNumerosDesdeVisionsAsync(ct);
    }

    private async Task ExportarFacturasNuevasAsync(int centroCostoVisions, CancellationToken ct)
    {
        var facturas = await _apiClient.ListarFacturasParaVisionsAsync(ct);
        if (facturas.Count == 0)
            return;

        _logger.LogInformation("Encontradas {Cantidad} facturas NEXO para exportar a Visions", facturas.Count);

        foreach (var factura in facturas)
        {
            try
            {
                await ExportarFacturaAsync(factura, centroCostoVisions, ct);
                await _apiClient.MarcarFacturaExportadaVisionsAsync(factura.FacturaID, ct);
                _logger.LogInformation("Factura NEXO {ID} exportada a Visions (placeholder NEXO-{ID})",
                    factura.FacturaID, factura.FacturaID);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al exportar factura NEXO {ID} a Visions", factura.FacturaID);
            }
        }
    }

    private async Task ExportarFacturaAsync(FacturaParaVisionsDto factura, int cc, CancellationToken ct)
    {
        // Si la factura ya tiene NroDoc propio (CC sin Visions), lo usamos directamente.
        // Si no, usamos el placeholder NEXO-{FacturaID} para que Visions lo identifique.
        var nroDocUsado = factura.NroDoc ?? $"NEXO-{factura.FacturaID}";

        using var connection = _visionsDb.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();

        try
        {
            foreach (var linea in factura.Lineas)
            {
                if (linea.ReferenciaVisions is null)
                    continue;

                var tarjeta = await connection.QueryFirstOrDefaultAsync<TarjetaIvaInfo>(
                    "SELECT TOP 1 ISNULL(IVASINO,'S') AS IvaSino, ISNULL(IVADESCRIPCION,'IVA 19%') AS IvaDescripcion, ISNULL(IVAVALOR,19) AS IvaValor FROM dbo.TARJETA WHERE CENTROCOSTO=@CC AND REFERENCIA=@Ref",
                    new { CC = cc, Ref = linea.ReferenciaVisions }, transaction);

                var ivaSino = tarjeta?.IvaSino ?? "S";
                var ivaDesc = tarjeta?.IvaDescripcion ?? "IVA 19%";
                var ivaValor = tarjeta?.IvaValor ?? 19;

                var subtotal = linea.Cantidad * linea.PrecioUnitario;
                var ivaImporte = ivaSino == "S" ? Math.Round(subtotal * ivaValor / 100m, 2) : 0m;
                var total = subtotal + ivaImporte;

                await connection.ExecuteAsync(
                    @"INSERT INTO dbo.MOVDETALLES
                        (CENTROCOSTO, NIT, TIPDOC, NRODOC, FECDOC, ORDEN, REFERENCIA, DETALLE,
                         CANTIDAD, PRECIO, COSTO, IVASINO, IVADESCRIPCION, IVAVALOR,
                         SUBTOTAL, TOTAL, MARCA, GRUPOMENOR, VENDEDOR, CLIENTE)
                      VALUES
                        (@CC, @Nit, @TipDoc, @NroDoc, @Fecha, @Orden, @Referencia, @Detalle,
                         @Cantidad, @Precio, @Costo, @IvaSino, @IvaDesc, @IvaValor,
                         @Subtotal, @Total, @Marca, @GrupoMenor, NULL, @Cliente)",
                    new
                    {
                        CC = cc,
                        Nit = factura.ClienteNit,
                        factura.TipDoc,
                        NroDoc = nroDocUsado,
                        Fecha = factura.Fecha,
                        linea.Orden,
                        Referencia = linea.ReferenciaVisions,
                        Detalle = linea.NombreArticulo,
                        linea.Cantidad,
                        Precio = linea.PrecioUnitario,
                        linea.Costo,
                        IvaSino = ivaSino,
                        IvaDesc = ivaDesc,
                        IvaValor = ivaValor,
                        Subtotal = subtotal,
                        Total = total,
                        Marca = linea.MarcaCodigo,
                        GrupoMenor = linea.GrupoMenorCodigo,
                        Cliente = factura.ClienteNombre
                    }, transaction);

                await connection.ExecuteAsync(
                    @"UPDATE dbo.TARJETA
                      SET EXISTENCIAS = ISNULL(EXISTENCIAS, 0) - @Cantidad
                      WHERE CENTROCOSTO = @CC AND REFERENCIA = @Referencia",
                    new { CC = cc, Referencia = linea.ReferenciaVisions, linea.Cantidad }, transaction);

                // Pre-marcar en NEXO_VentasExportadas usando el mismo nroDoc para que
                // TareaExportarVentas no reimporte estas líneas en la próxima ronda.
                await connection.ExecuteAsync(
                    @"IF NOT EXISTS (SELECT 1 FROM dbo.NEXO_VentasExportadas
                                    WHERE CENTROCOSTO=@CC AND TIPDOC=@TipDoc AND NRODOC=@NroDoc AND ORDEN=@Orden AND REFERENCIA=@Ref)
                      INSERT INTO dbo.NEXO_VentasExportadas (CENTROCOSTO, TIPDOC, NRODOC, ORDEN, REFERENCIA, CANTIDAD)
                      VALUES (@CC, @TipDoc, @NroDoc, @Orden, @Ref, @Cantidad)",
                    new
                    {
                        CC = cc,
                        factura.TipDoc,
                        NroDoc = nroDocUsado,
                        linea.Orden,
                        Ref = linea.ReferenciaVisions,
                        linea.Cantidad
                    }, transaction);
            }

            // Registrar en NEXO_FacturasSalientes para que el trigger (y el agente)
            // puedan hacer el seguimiento del número asignado por Visions.
            if (factura.NroDoc is null)
            {
                await connection.ExecuteAsync(
                    @"IF NOT EXISTS (SELECT 1 FROM dbo.NEXO_FacturasSalientes WHERE FacturaID=@FacturaId)
                      INSERT INTO dbo.NEXO_FacturasSalientes (FacturaID, NexoNroDoc, FechaEnvio)
                      VALUES (@FacturaId, @NexoNroDoc, GETDATE())",
                    new { FacturaId = factura.FacturaID, NexoNroDoc = nroDocUsado }, transaction);
            }

            transaction.Commit();
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    private async Task SincronizarNumerosDesdeVisionsAsync(CancellationToken ct)
    {
        using var connection = _visionsDb.CreateConnection();

        var pendientes = (await connection.QueryAsync<FacturaSalienteNumerada>(
            @"SELECT FacturaID, TipDocVisions, NroDocVisions
              FROM dbo.NEXO_FacturasSalientes
              WHERE NroDocVisions IS NOT NULL AND FechaSyncBack IS NULL")).ToList();

        if (pendientes.Count == 0)
            return;

        _logger.LogInformation("Actualizando {N} facturas con número asignado por Visions", pendientes.Count);

        foreach (var f in pendientes)
        {
            try
            {
                await _apiClient.ActualizarNumeroVisionsAsync(
                    f.FacturaID,
                    new ActualizarNumeroVisionsRequest(f.TipDocVisions!, f.NroDocVisions!),
                    ct);

                await connection.ExecuteAsync(
                    "UPDATE dbo.NEXO_FacturasSalientes SET FechaSyncBack=GETDATE() WHERE FacturaID=@FacturaId",
                    new { FacturaId = f.FacturaID });

                _logger.LogInformation("Factura NEXO {ID} actualizada con número Visions {NroDoc}",
                    f.FacturaID, f.NroDocVisions);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al actualizar número Visions para factura NEXO {ID}", f.FacturaID);
            }
        }
    }

    private record TarjetaIvaInfo(string IvaSino, string IvaDescripcion, short IvaValor);
    private record FacturaSalienteNumerada(int FacturaID, string? TipDocVisions, string? NroDocVisions);
}
