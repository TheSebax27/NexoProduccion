using Dapper;
using NexoApi.Common.Data;
using NexoApi.Features.Operaciones.Dtos;

namespace NexoApi.Features.Operaciones;

public interface IOperacionesService
{
    Task<IEnumerable<MovimientoItem>> ListarMovimientosAsync(MovimientosFiltro filtro);
}

public class OperacionesService : IOperacionesService
{
    private readonly IDbConnectionFactory _db;

    public OperacionesService(IDbConnectionFactory db) => _db = db;

    public async Task<IEnumerable<MovimientoItem>> ListarMovimientosAsync(MovimientosFiltro filtro)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            -- Ordenes de Compra
            SELECT oc.OrdenCompraID       AS ID,
                   'OC'                   AS Tipo,
                   oc.Codigo              AS Referencia,
                   oc.FechaEmision        AS Fecha,
                   p.RazonSocial          AS Contraparte,
                   ISNULL(SUM(d.CantidadSolicitada * d.CostoUnitario), 0) AS Monto,
                   oc.EstadoOC            AS Estado
            FROM Compras.OrdenesCompra oc
            JOIN Catalogo.Proveedores p ON p.ProveedorID = oc.ProveedorID
            LEFT JOIN Compras.OrdenesCompraDetalle d ON d.OrdenCompraID = oc.OrdenCompraID
            WHERE (@Tipo IS NULL OR @Tipo = 'OC')
              AND (@Desde IS NULL OR oc.FechaEmision >= @Desde)
              AND (@Hasta IS NULL OR oc.FechaEmision <  DATEADD(DAY, 1, @Hasta))
            GROUP BY oc.OrdenCompraID, oc.Codigo, oc.FechaEmision, p.RazonSocial, oc.EstadoOC

            UNION ALL

            -- Despachos
            SELECT d.DespachoID           AS ID,
                   'DESPACHO'             AS Tipo,
                   'GUIA-' + RIGHT('000000' + CAST(d.DespachoID AS VARCHAR(6)), 6) AS Referencia,
                   d.FechaDespacho        AS Fecha,
                   c.Nombre               AS Contraparte,
                   ISNULL((
                       SELECT SUM(dd.Cantidad * a.PrecioVenta)
                       FROM Logistica.DespachoDetalle dd
                       JOIN Catalogo.Tarjetas a ON a.ArticuloID = dd.ArticuloID
                       WHERE dd.DespachoID = d.DespachoID
                   ), 0)                  AS Monto,
                   d.Estado               AS Estado
            FROM Logistica.Despachos d
            JOIN Crm.Clientes c ON c.ClienteID = d.ClienteID
            WHERE (@Tipo IS NULL OR @Tipo = 'DESPACHO')
              AND (@Desde IS NULL OR d.FechaDespacho >= @Desde)
              AND (@Hasta IS NULL OR d.FechaDespacho < DATEADD(DAY, 1, @Hasta))

            UNION ALL

            -- Facturas
            SELECT f.FacturaID            AS ID,
                   'FACTURA'             AS Tipo,
                   'FACT-' + RIGHT('000000' + CAST(f.FacturaID AS VARCHAR(6)), 6) AS Referencia,
                   f.Fecha,
                   c.Nombre               AS Contraparte,
                   ISNULL((SELECT SUM(l.Cantidad * l.PrecioUnitario)
                            FROM Facturacion.FacturaLineas l WHERE l.FacturaID = f.FacturaID), 0) AS Monto,
                   CASE
                       WHEN ISNULL((SELECT SUM(pg.Monto) FROM Facturacion.Pagos pg WHERE pg.FacturaID = f.FacturaID), 0) = 0
                           THEN 'Pendiente'
                       WHEN ISNULL((SELECT SUM(pg.Monto) FROM Facturacion.Pagos pg WHERE pg.FacturaID = f.FacturaID), 0) >=
                            ISNULL((SELECT SUM(l.Cantidad * l.PrecioUnitario) FROM Facturacion.FacturaLineas l WHERE l.FacturaID = f.FacturaID), 0)
                           THEN 'Pagada'
                       ELSE 'Parcial'
                   END                    AS Estado
            FROM Facturacion.Facturas f
            JOIN Crm.Clientes c ON c.ClienteID = f.ClienteID
            WHERE (@Tipo IS NULL OR @Tipo = 'FACTURA')
              AND (@Desde IS NULL OR f.Fecha >= @Desde)
              AND (@Hasta IS NULL OR f.Fecha < DATEADD(DAY, 1, @Hasta))

            ORDER BY Fecha DESC, ID DESC";

        return await connection.QueryAsync<MovimientoItem>(sql, new
        {
            filtro.Tipo,
            filtro.Desde,
            filtro.Hasta
        });
    }
}
