using Dapper;
using NexoApi.Common.Data;
using NexoApi.Features.Facturacion.Dtos;
using NexoApi.Features.Produccion;
using NexoApi.Features.Produccion.Dtos;

namespace NexoApi.Features.Facturacion;

public interface IFacturacionService
{
    Task<IEnumerable<FacturaItem>> ListarFacturasAsync(int? clienteId, string? estado);
    Task<int> CrearFacturaAsync(CrearFacturaRequest request, int usuarioId);

    Task<IEnumerable<FacturaLineaItem>> ListarLineasAsync(int facturaId);
    Task<IEnumerable<FacturaLineaStockItem>> ObtenerStockLineasAsync(int facturaId);
    Task DescontarStockAsync(int facturaId, int usuarioId);

    Task<IEnumerable<PagoItem>> ListarPagosAsync(int facturaId);
    Task<int> CrearPagoAsync(CrearPagoRequest request, int usuarioId);

    Task<List<VerificarProduccionItem>> VerificarProduccionFacturaAsync(int facturaId);
    Task<List<AutoProducirResultItem>> AutoProducirFacturaAsync(int facturaId, int usuarioId);
}

public class FacturacionService : IFacturacionService
{
    private readonly IDbConnectionFactory _db;
    private readonly IOrdenesProduccionService _produccion;

    public FacturacionService(IDbConnectionFactory db, IOrdenesProduccionService produccion)
    {
        _db = db;
        _produccion = produccion;
    }

    private record FacturaCruda(int FacturaID, int ClienteID, string Cliente, DateTime Fecha, string? Notas, decimal Total, decimal TotalPagado, bool StockDescontado, bool ProduccionAutoEjecutada);

    // Estado (PAGADA/PARCIAL/PENDIENTE) y SaldoPendiente se calculan aca, en
    // C#, a partir de Total y TotalPagado -- nunca se guardan como columna
    // fija en Facturas (evitaria que quedaran desactualizados si se borra un pago).
    public async Task<IEnumerable<FacturaItem>> ListarFacturasAsync(int? clienteId, string? estado)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT f.FacturaID, f.ClienteID, c.Nombre AS Cliente, f.Fecha, f.Notas,
                   ISNULL(ROUND((SELECT SUM(l.Cantidad * l.PrecioUnitario) FROM Facturacion.FacturaLineas l WHERE l.FacturaID = f.FacturaID), 0), 0) AS Total,
                   ISNULL((SELECT SUM(p.Monto) FROM Facturacion.Pagos p WHERE p.FacturaID = f.FacturaID), 0) AS TotalPagado,
                   f.StockDescontado, f.ProduccionAutoEjecutada
            FROM Facturacion.Facturas f
            JOIN Crm.Clientes c ON c.ClienteID = f.ClienteID
            WHERE (@ClienteId IS NULL OR f.ClienteID = @ClienteId)
            ORDER BY f.Fecha DESC, f.FacturaID DESC";

        var crudas = await connection.QueryAsync<FacturaCruda>(sql, new { ClienteId = clienteId });

        var items = crudas.Select(f =>
        {
            var saldo = f.Total - f.TotalPagado;
            var estadoCalculado = f.TotalPagado <= 0 ? "PENDIENTE" : saldo > 0 ? "PARCIAL" : "PAGADA";
            return new FacturaItem(f.FacturaID, f.ClienteID, f.Cliente, f.Fecha, f.Notas, f.Total, f.TotalPagado, saldo, estadoCalculado, f.StockDescontado, f.ProduccionAutoEjecutada);
        });

        if (estado is not null)
            items = items.Where(i => i.Estado == estado);

        return items.ToList();
    }

    public async Task<int> CrearFacturaAsync(CrearFacturaRequest r, int usuarioId)
    {
        if (r.Lineas.Count == 0)
            throw new InvalidOperationException("La factura debe tener al menos una línea.");

        if (r.Lineas.Any(l => l.ArticuloID is null && l.ComboID is null))
            throw new InvalidOperationException("Cada línea debe tener un artículo o un combo.");

        if (r.Lineas.Any(l => l.Cantidad <= 0))
            throw new InvalidOperationException("Todas las cantidades deben ser mayores a cero.");

        using var connection = _db.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();

        try
        {
            const string sqlFactura = @"
                INSERT INTO Facturacion.Facturas (ClienteID, Fecha, Notas, UsuarioID)
                OUTPUT INSERTED.FacturaID
                VALUES (@ClienteID, @Fecha, @Notas, @UsuarioID)";

            var facturaId = await connection.ExecuteScalarAsync<int>(sqlFactura,
                new { r.ClienteID, r.Fecha, r.Notas, UsuarioID = usuarioId }, transaction);

            const string sqlLinea = @"
                INSERT INTO Facturacion.FacturaLineas (FacturaID, ArticuloID, ComboID, DescripcionLinea, Cantidad, PrecioUnitario)
                VALUES (@FacturaId, @ArticuloID, @ComboID, @DescripcionLinea, @Cantidad, @PrecioUnitario)";

            foreach (var linea in r.Lineas)
            {
                await connection.ExecuteAsync(sqlLinea,
                    new { FacturaId = facturaId, linea.ArticuloID, linea.ComboID, linea.DescripcionLinea, linea.Cantidad, linea.PrecioUnitario }, transaction);
            }

            transaction.Commit();
            return facturaId;
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public async Task<IEnumerable<FacturaLineaItem>> ListarLineasAsync(int facturaId)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT l.LineaID, l.FacturaID, l.ArticuloID,
                   a.Referencia AS SkuArticulo,
                   COALESCE(a.Nombre, l.DescripcionLinea, c.Nombre) AS NombreArticulo,
                   l.ComboID, l.DescripcionLinea,
                   l.Cantidad, l.PrecioUnitario, ROUND(l.Cantidad * l.PrecioUnitario, 0) AS Subtotal,
                   a.PresentacionCodigo AS Unidad, p.Fracciones AS UnidadesPorEmbalaje
            FROM Facturacion.FacturaLineas l
            LEFT JOIN Catalogo.Tarjetas a ON a.ArticuloID = l.ArticuloID
            LEFT JOIN Marketing.Combos c ON c.ComboID = l.ComboID
            LEFT JOIN Catalogo.Presentacion p ON p.Codigo = a.PresentacionCodigo
            WHERE l.FacturaID = @FacturaId
            ORDER BY l.LineaID";

        return await connection.QueryAsync<FacturaLineaItem>(sql, new { FacturaId = facturaId });
    }

    public async Task<IEnumerable<PagoItem>> ListarPagosAsync(int facturaId)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT p.PagoID, p.FacturaID, p.Monto, p.FechaPago, p.MetodoPago, p.Notas,
                   u.Nombres + ' ' + u.Apellidos AS Usuario
            FROM Facturacion.Pagos p
            LEFT JOIN Seguridad.Usuarios u ON u.UsuarioID = p.UsuarioID
            WHERE p.FacturaID = @FacturaId
            ORDER BY p.FechaPago DESC, p.PagoID DESC";

        return await connection.QueryAsync<PagoItem>(sql, new { FacturaId = facturaId });
    }

    public async Task<int> CrearPagoAsync(CrearPagoRequest r, int usuarioId)
    {
        if (r.Monto <= 0)
            throw new InvalidOperationException("El monto del pago debe ser mayor a cero.");

        using var connection = _db.CreateConnection();

        const string sql = @"
            INSERT INTO Facturacion.Pagos (FacturaID, Monto, FechaPago, MetodoPago, Notas, UsuarioID)
            OUTPUT INSERTED.PagoID
            VALUES (@FacturaID, @Monto, @FechaPago, @MetodoPago, @Notas, @UsuarioID)";

        return await connection.ExecuteScalarAsync<int>(sql, new { r.FacturaID, r.Monto, r.FechaPago, r.MetodoPago, r.Notas, UsuarioID = usuarioId });
    }

    public async Task<IEnumerable<FacturaLineaStockItem>> ObtenerStockLineasAsync(int facturaId)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            -- Artículos directos
            SELECT fl.ArticuloID, a.Referencia AS SkuArticulo, a.Nombre AS NombreArticulo,
                   fl.Cantidad AS CantidadFacturada,
                   ISNULL((SELECT SUM(s.CantidadActual) FROM Inventario.InventarioStock s WHERE s.ArticuloID = fl.ArticuloID), 0) AS StockDisponible
            FROM Facturacion.FacturaLineas fl
            JOIN Catalogo.Tarjetas a ON a.ArticuloID = fl.ArticuloID
            WHERE fl.FacturaID = @FacturaId AND fl.ArticuloID IS NOT NULL
            UNION ALL
            -- Artículos dentro de combos (cantidad facturada = cantidad combo × cantidad en combo)
            SELECT ci.ArticuloID, a.Referencia AS SkuArticulo, a.Nombre AS NombreArticulo,
                   fl.Cantidad * ci.Cantidad AS CantidadFacturada,
                   ISNULL((SELECT SUM(s.CantidadActual) FROM Inventario.InventarioStock s WHERE s.ArticuloID = ci.ArticuloID), 0) AS StockDisponible
            FROM Facturacion.FacturaLineas fl
            JOIN Marketing.ComboItems ci ON ci.ComboID = fl.ComboID
            JOIN Catalogo.Tarjetas a ON a.ArticuloID = ci.ArticuloID
            WHERE fl.FacturaID = @FacturaId AND fl.ComboID IS NOT NULL
            ORDER BY SkuArticulo";

        return await connection.QueryAsync<FacturaLineaStockItem>(sql, new { FacturaId = facturaId });
    }

    public async Task DescontarStockAsync(int facturaId, int usuarioId)
    {
        using var connection = _db.CreateConnection();

        try
        {
            await connection.ExecuteAsync(
                "EXEC Facturacion.sp_DescontarStockFactura @FacturaID, @UsuarioID",
                new { FacturaID = facturaId, UsuarioID = usuarioId });
        }
        catch (Exception ex) when (ex.Message.Contains("ya fue descontado"))
        {
            throw new InvalidOperationException("El stock de esta factura ya fue descontado anteriormente.");
        }
        catch (Exception ex) when (ex.Message.Contains("Stock insuficiente"))
        {
            throw new InvalidOperationException(ex.Message);
        }
        catch (Exception ex) when (ex.Message.Contains("no encontrada") || ex.Message.Contains("no tiene lineas"))
        {
            throw new KeyNotFoundException(ex.Message);
        }
    }

    private record LineaPTCruda(int ArticuloID, string SKU, string Nombre, decimal Cantidad, int? RecetaID);
    private record InsumoCrudo(int RecetaID, int ArticuloID, string InsumoNombre, string Unidad, decimal CantidadRequerida);
    private record StockCrudo(int ArticuloID, decimal StockTotal);

    public async Task<List<VerificarProduccionItem>> VerificarProduccionFacturaAsync(int facturaId)
    {
        using var conn = _db.CreateConnection();

        var lineasPT = await conn.QueryAsync<LineaPTCruda>("""
            -- Productos terminados directos en la factura
            SELECT fl.ArticuloID, a.Referencia AS SKU, a.Nombre, fl.Cantidad,
                   (SELECT TOP 1 r.RecetaID FROM Produccion.RecetaBOM r
                    WHERE r.ProductoTerminadoID = fl.ArticuloID AND r.Estado = 1) AS RecetaID
            FROM Facturacion.FacturaLineas fl
            JOIN Catalogo.Tarjetas a ON a.ArticuloID = fl.ArticuloID
            WHERE fl.FacturaID = @facturaId
              AND a.TipoArticuloID = 2
            UNION ALL
            -- Productos terminados dentro de combos
            SELECT ci.ArticuloID, a.Referencia AS SKU, a.Nombre, fl.Cantidad * ci.Cantidad AS Cantidad,
                   (SELECT TOP 1 r.RecetaID FROM Produccion.RecetaBOM r
                    WHERE r.ProductoTerminadoID = ci.ArticuloID AND r.Estado = 1) AS RecetaID
            FROM Facturacion.FacturaLineas fl
            JOIN Marketing.ComboItems ci ON ci.ComboID = fl.ComboID
            JOIN Catalogo.Tarjetas a ON a.ArticuloID = ci.ArticuloID
            WHERE fl.FacturaID = @facturaId
              AND fl.ComboID IS NOT NULL
              AND a.TipoArticuloID = 2
            """, new { facturaId });

        var resultado = new List<VerificarProduccionItem>();

        foreach (var linea in lineasPT)
        {
            if (linea.RecetaID is null)
            {
                resultado.Add(new VerificarProduccionItem(
                    linea.ArticuloID, linea.SKU, linea.Nombre,
                    linea.Cantidad, false, null, []));
                continue;
            }

            var insumos = await conn.QueryAsync<InsumoCrudo>("""
                SELECT rd.RecetaID, rd.InsumoID AS ArticuloID, a.Nombre AS InsumoNombre,
                       ISNULL(u.Abreviatura, '') AS Unidad,
                       rd.CantidadRequerida * @cantidad AS CantidadRequerida
                FROM Produccion.RecetaBOM_Detalle rd
                JOIN Catalogo.Tarjetas a ON a.ArticuloID = rd.InsumoID
                LEFT JOIN catalogo.UnidadesMedida u ON u.UnidadID = rd.UnidadID
                WHERE rd.RecetaID = @recetaId
                """, new { recetaId = linea.RecetaID, cantidad = linea.Cantidad });

            var insumoIds = insumos.Select(i => i.ArticuloID).Distinct().ToList();
            var stocks = insumoIds.Count == 0 ? []
                : (await conn.QueryAsync<StockCrudo>("""
                    SELECT ArticuloID, ISNULL(SUM(CantidadActual), 0) AS StockTotal
                    FROM Inventario.InventarioStock
                    WHERE ArticuloID IN @ids
                    GROUP BY ArticuloID
                    """, new { ids = insumoIds })).ToList();

            var stockDict = stocks.ToDictionary(s => s.ArticuloID, s => s.StockTotal);

            var listaInsumos = insumos.Select(i => new InsumoVerificacionItem(
                i.ArticuloID, i.InsumoNombre, i.Unidad,
                i.CantidadRequerida,
                stockDict.GetValueOrDefault(i.ArticuloID, 0)
            )).ToList();

            resultado.Add(new VerificarProduccionItem(
                linea.ArticuloID, linea.SKU, linea.Nombre,
                linea.Cantidad, true, linea.RecetaID, listaInsumos));
        }

        return resultado;
    }

    public async Task<List<AutoProducirResultItem>> AutoProducirFacturaAsync(int facturaId, int usuarioId)
    {
        using var conn = _db.CreateConnection();

        var items = await VerificarProduccionFacturaAsync(facturaId);
        var resultado = new List<AutoProducirResultItem>();

        var defaultTipoProduccion = await conn.ExecuteScalarAsync<int>(
            "SELECT TOP 1 TipoProduccionID FROM Produccion.TiposProduccion ORDER BY TipoProduccionID");
        var defaultCentroCosto = await conn.ExecuteScalarAsync<int>(
            "SELECT TOP 1 CentroCostoID FROM Organizacion.CentrosCosto WHERE Estado = 1");
        var defaultBodega = await conn.ExecuteScalarAsync<int>(
            "SELECT TOP 1 BodegaID FROM Inventario.Bodegas WHERE Estado = 1");

        foreach (var item in items.Where(i => i.TieneReceta))
        {
            try
            {
                var codigoOP = $"AP-{facturaId}-{item.ArticuloID}-{DateTimeOffset.UtcNow.ToUnixTimeSeconds()}";
                var opId = await _produccion.CrearAsync(new CrearOrdenProduccionRequest(
                    CodigoOP: codigoOP,
                    TipoProduccionID: defaultTipoProduccion,
                    ProductoTerminadoID: item.ArticuloID,
                    RecetaID: item.RecetaID!.Value,
                    CantidadProgramada: item.CantidadFacturada,
                    ClienteID: null,
                    CentroCostoDestinoID: defaultCentroCosto,
                    BodegaOrigenMPID: defaultBodega,
                    BodegaDestinoPTID: defaultBodega,
                    CentroTrabajoID: null,
                    FechaPlanificada: DateTime.Today,
                    Observaciones: $"Auto-generada desde factura #{facturaId}"
                ), usuarioId);

                await _produccion.LiberarAsync(opId, usuarioId);
                await _produccion.IniciarAsync(opId, usuarioId);
                await _produccion.CerrarAsync(opId, new CerrarOrdenProduccionRequest(
                    CantidadProducidaReal: item.CantidadFacturada,
                    HorasManoObra: 0,
                    HorasCIF: 0,
                    NumeroLotePT: $"AUTO-{codigoOP}",
                    FechaVencimientoPT: null
                ), usuarioId);

                resultado.Add(new AutoProducirResultItem(
                    item.ArticuloID, item.Nombre, true, opId, null));
            }
            catch (Exception ex)
            {
                resultado.Add(new AutoProducirResultItem(
                    item.ArticuloID, item.Nombre, false, null, ex.Message));
            }
        }

        if (resultado.Any(r => r.Exitoso))
        {
            try { await DescontarStockAsync(facturaId, usuarioId); }
            catch { /* el stock se descuenta best-effort; puede fallar si ya fue descontado */ }

            using var conn2 = _db.CreateConnection();
            await conn2.ExecuteAsync(
                "UPDATE Facturacion.Facturas SET ProduccionAutoEjecutada=1 WHERE FacturaID=@facturaId",
                new { facturaId });
        }

        return resultado;
    }
}
