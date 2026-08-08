using Dapper;
using NexoApi.Common.Data;
using NexoApi.Features.Facturacion.Dtos;

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
}

public class FacturacionService : IFacturacionService
{
    private readonly IDbConnectionFactory _db;

    public FacturacionService(IDbConnectionFactory db)
    {
        _db = db;
    }

    private record FacturaCruda(int FacturaID, int ClienteID, string Cliente, DateTime Fecha, string? Notas, decimal Total, decimal TotalPagado, bool StockDescontado);

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
                   f.StockDescontado
            FROM Facturacion.Facturas f
            JOIN Crm.Clientes c ON c.ClienteID = f.ClienteID
            WHERE (@ClienteId IS NULL OR f.ClienteID = @ClienteId)
            ORDER BY f.Fecha DESC, f.FacturaID DESC";

        var crudas = await connection.QueryAsync<FacturaCruda>(sql, new { ClienteId = clienteId });

        var items = crudas.Select(f =>
        {
            var saldo = f.Total - f.TotalPagado;
            var estadoCalculado = f.TotalPagado <= 0 ? "PENDIENTE" : saldo > 0 ? "PARCIAL" : "PAGADA";
            return new FacturaItem(f.FacturaID, f.ClienteID, f.Cliente, f.Fecha, f.Notas, f.Total, f.TotalPagado, saldo, estadoCalculado, f.StockDescontado);
        });

        if (estado is not null)
            items = items.Where(i => i.Estado == estado);

        return items.ToList();
    }

    public async Task<int> CrearFacturaAsync(CrearFacturaRequest r, int usuarioId)
    {
        if (r.Lineas.Count == 0)
            throw new InvalidOperationException("La factura debe tener al menos un artículo.");

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
                INSERT INTO Facturacion.FacturaLineas (FacturaID, ArticuloID, Cantidad, PrecioUnitario)
                VALUES (@FacturaId, @ArticuloID, @Cantidad, @PrecioUnitario)";

            foreach (var linea in r.Lineas)
            {
                await connection.ExecuteAsync(sqlLinea,
                    new { FacturaId = facturaId, linea.ArticuloID, linea.Cantidad, linea.PrecioUnitario }, transaction);
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
            SELECT l.LineaID, l.FacturaID, l.ArticuloID, a.SKU AS SkuArticulo, a.Nombre AS NombreArticulo,
                   l.Cantidad, l.PrecioUnitario, ROUND(l.Cantidad * l.PrecioUnitario, 0) AS Subtotal,
                   um.Abreviatura AS Unidad, a.UnidadesPorEmbalaje
            FROM Facturacion.FacturaLineas l
            JOIN Catalogo.Articulos a ON a.ArticuloID = l.ArticuloID
            LEFT JOIN Catalogo.UnidadesMedida um ON um.UnidadID = a.UnidadID
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
            SELECT fl.ArticuloID, a.SKU AS SkuArticulo, a.Nombre AS NombreArticulo,
                   fl.Cantidad AS CantidadFacturada,
                   ISNULL((SELECT SUM(s.CantidadActual) FROM Inventario.InventarioStock s WHERE s.ArticuloID = fl.ArticuloID), 0) AS StockDisponible
            FROM Facturacion.FacturaLineas fl
            JOIN Catalogo.Articulos a ON a.ArticuloID = fl.ArticuloID
            WHERE fl.FacturaID = @FacturaId
            ORDER BY fl.LineaID";

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
}
