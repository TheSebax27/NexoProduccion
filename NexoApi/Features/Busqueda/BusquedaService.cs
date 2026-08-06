using System.Security.Claims;
using Dapper;
using NexoApi.Common.Data;
using NexoApi.Features.Busqueda.Dtos;

namespace NexoApi.Features.Busqueda;

public interface IBusquedaService
{
    Task<List<ResultadoBusqueda>> BuscarAsync(string texto, ClaimsPrincipal usuario);
}

// Busqueda global de la barra superior. Cada categoria solo se consulta si el
// usuario tiene acceso a la pantalla de destino (mismos roles que el
// @attribute [Authorize] de la pagina Blazor correspondiente) -- si no, no
// tiene sentido sugerirle un resultado que al hacer click le va a negar el
// acceso.
public class BusquedaService : IBusquedaService
{
    private const int MaxPorCategoria = 5;
    private readonly IDbConnectionFactory _db;

    public BusquedaService(IDbConnectionFactory db)
    {
        _db = db;
    }

    public async Task<List<ResultadoBusqueda>> BuscarAsync(string texto, ClaimsPrincipal usuario)
    {
        var resultados = new List<ResultadoBusqueda>();
        if (string.IsNullOrWhiteSpace(texto) || texto.Trim().Length < 2)
            return resultados;

        var patron = $"%{texto.Trim()}%";
        using var connection = _db.CreateConnection();

        // Stock: sin restriccion de rol porque /inventario/stock es [Authorize]
        // sin roles especificos (todos los autenticados pueden verla) -- a
        // diferencia del catalogo de Articulos, que si esta restringido.
        {
            const string sqlStock = @"
                SELECT DISTINCT TOP (@Max) s.SKU, s.Articulo, s.Bodega
                FROM Inventario.vw_StockConsolidado s
                WHERE s.Articulo LIKE @Patron OR s.SKU LIKE @Patron
                ORDER BY s.Articulo";
            var stock = await connection.QueryAsync<(string SKU, string Articulo, string Bodega)>(
                sqlStock, new { Patron = patron, Max = MaxPorCategoria });
            resultados.AddRange(stock.Select(s => new ResultadoBusqueda(
                "Stock", s.Articulo, $"SKU {s.SKU} · {s.Bodega}",
                "/inventario/stock")));
        }

        if (usuario.IsInRole("Administrador") || usuario.IsInRole("Bodeguero"))
        {
            const string sqlTraspasos = @"
                SELECT TOP (@Max) t.Codigo, bo.Nombre AS Origen, bd.Nombre AS Destino, t.EstadoTraspaso
                FROM Inventario.TraspasosBodega t
                JOIN Inventario.Bodegas bo ON bo.BodegaID = t.BodegaOrigenID
                JOIN Inventario.Bodegas bd ON bd.BodegaID = t.BodegaDestinoID
                WHERE t.Codigo LIKE @Patron
                ORDER BY t.TraspasoID DESC";
            var traspasos = await connection.QueryAsync<(string Codigo, string Origen, string Destino, string EstadoTraspaso)>(
                sqlTraspasos, new { Patron = patron, Max = MaxPorCategoria });
            resultados.AddRange(traspasos.Select(t => new ResultadoBusqueda(
                "Traspaso", t.Codigo, $"{t.Origen} → {t.Destino} · {t.EstadoTraspaso}",
                "/inventario/traspasos")));
        }

        if (usuario.IsInRole("Administrador") || usuario.IsInRole("SupervisorPlanta"))
        {
            const string sqlArticulos = @"
                SELECT TOP (@Max) SKU, Nombre
                FROM Catalogo.Articulos
                WHERE Nombre LIKE @Patron OR SKU LIKE @Patron
                ORDER BY Nombre";
            var articulos = await connection.QueryAsync<(string SKU, string Nombre)>(
                sqlArticulos, new { Patron = patron, Max = MaxPorCategoria });
            resultados.AddRange(articulos.Select(a => new ResultadoBusqueda(
                "Artículo", a.Nombre, $"SKU {a.SKU} · Catálogo",
                $"/catalogo/articulos?texto={Uri.EscapeDataString(a.SKU)}")));
        }

        if (usuario.IsInRole("Administrador"))
        {
            const string sqlClientes = @"
                SELECT TOP (@Max) Nombre, NIT
                FROM Crm.Clientes
                WHERE Nombre LIKE @Patron OR NIT LIKE @Patron
                ORDER BY Nombre";
            var clientes = await connection.QueryAsync<(string Nombre, string? NIT)>(
                sqlClientes, new { Patron = patron, Max = MaxPorCategoria });
            resultados.AddRange(clientes.Select(c => new ResultadoBusqueda(
                "Cliente", c.Nombre, c.NIT is null ? "CRM" : $"NIT {c.NIT} · CRM",
                "/crm/clientes")));

            const string sqlProveedores = @"
                SELECT TOP (@Max) RazonSocial, NIT
                FROM Catalogo.Proveedores
                WHERE RazonSocial LIKE @Patron OR NIT LIKE @Patron
                ORDER BY RazonSocial";
            var proveedores = await connection.QueryAsync<(string RazonSocial, string? NIT)>(
                sqlProveedores, new { Patron = patron, Max = MaxPorCategoria });
            resultados.AddRange(proveedores.Select(p => new ResultadoBusqueda(
                "Proveedor", p.RazonSocial, p.NIT is null ? "Catálogo" : $"NIT {p.NIT} · Catálogo",
                "/catalogo/proveedores")));

            const string sqlCentrosCosto = @"
                SELECT TOP (@Max) Codigo, Nombre
                FROM Organizacion.CentrosCosto
                WHERE Nombre LIKE @Patron OR Codigo LIKE @Patron
                ORDER BY Nombre";
            var centrosCosto = await connection.QueryAsync<(string Codigo, string Nombre)>(
                sqlCentrosCosto, new { Patron = patron, Max = MaxPorCategoria });
            resultados.AddRange(centrosCosto.Select(c => new ResultadoBusqueda(
                "Centro de Costo", c.Nombre, $"{c.Codigo} · Catálogo",
                "/catalogo/centros-costo")));

            const string sqlBodegas = @"
                SELECT TOP (@Max) b.Nombre, cc.Nombre AS CentroCosto
                FROM Inventario.Bodegas b
                JOIN Organizacion.CentrosCosto cc ON cc.CentroCostoID = b.CentroCostoID
                WHERE b.Nombre LIKE @Patron
                ORDER BY b.Nombre";
            var bodegas = await connection.QueryAsync<(string Nombre, string CentroCosto)>(
                sqlBodegas, new { Patron = patron, Max = MaxPorCategoria });
            resultados.AddRange(bodegas.Select(b => new ResultadoBusqueda(
                "Bodega", b.Nombre, $"{b.CentroCosto} · Catálogo",
                "/catalogo/bodegas")));
        }

        if (usuario.IsInRole("Administrador") || usuario.IsInRole("SupervisorPlanta") || usuario.IsInRole("Operario"))
        {
            const string sqlOrdenesProduccion = @"
                SELECT TOP (@Max) op.CodigoOP, a.Nombre AS Producto, e.Nombre AS Estado
                FROM Produccion.OrdenesProduccion op
                JOIN Catalogo.Articulos a ON a.ArticuloID = op.ProductoTerminadoID
                JOIN Produccion.EstadosOP e ON e.EstadoOPID = op.EstadoOPID
                WHERE op.CodigoOP LIKE @Patron OR a.Nombre LIKE @Patron
                ORDER BY op.OrdenProduccionID DESC";
            var ordenesProduccion = await connection.QueryAsync<(string CodigoOP, string Producto, string Estado)>(
                sqlOrdenesProduccion, new { Patron = patron, Max = MaxPorCategoria });
            resultados.AddRange(ordenesProduccion.Select(o => new ResultadoBusqueda(
                "Orden de Producción", o.CodigoOP, $"{o.Producto} · {o.Estado}",
                "/produccion/ordenes")));
        }

        if (usuario.IsInRole("Administrador") || usuario.IsInRole("Bodeguero"))
        {
            const string sqlOrdenesCompra = @"
                SELECT TOP (@Max) oc.Codigo, p.RazonSocial AS Proveedor, oc.EstadoOC AS Estado
                FROM Compras.OrdenesCompra oc
                JOIN Catalogo.Proveedores p ON p.ProveedorID = oc.ProveedorID
                WHERE oc.Codigo LIKE @Patron OR p.RazonSocial LIKE @Patron
                ORDER BY oc.OrdenCompraID DESC";
            var ordenesCompra = await connection.QueryAsync<(string Codigo, string Proveedor, string Estado)>(
                sqlOrdenesCompra, new { Patron = patron, Max = MaxPorCategoria });
            resultados.AddRange(ordenesCompra.Select(o => new ResultadoBusqueda(
                "Orden de Compra", o.Codigo, $"{o.Proveedor} · {o.Estado}",
                "/compras/ordenes")));
        }

        return resultados;
    }
}
