using Dapper;
using NexoApi.Common.Data;
using NexoApi.Features.Compras.Dtos;
using System.Data;

namespace NexoApi.Features.Compras;

public interface IOrdenesCompraService
{
    Task<int> CrearAsync(CrearOrdenCompraRequest request, int usuarioId);
    Task<IEnumerable<OrdenCompraResumen>> ListarAsync(string? estado);
    Task<IEnumerable<OrdenCompraDetalleItem>> ObtenerDetalleAsync(int ordenCompraId);
    Task<(int LoteID, decimal NuevoCostoPromedio)> RecibirLineaAsync(int ordenCompraDetalleId, RecibirLineaOrdenCompraRequest request, int usuarioId);
}

public class OrdenesCompraService : IOrdenesCompraService
{
    private record RecibirResultado(string Resultado, int LoteID, decimal NuevoCostoPromedio);

    private readonly IDbConnectionFactory _db;

    public OrdenesCompraService(IDbConnectionFactory db)
    {
        _db = db;
    }

    public async Task<int> CrearAsync(CrearOrdenCompraRequest r, int usuarioId)
    {
        using var connection = _db.CreateConnection();
        connection.Open(); // necesitamos abrirla nosotros mismos para poder iniciar una transaccion sobre ella
        using var transaction = connection.BeginTransaction();

        try
        {
            const string sqlHeader = @"
                INSERT INTO Compras.OrdenesCompra (Codigo, ProveedorID, BodegaDestinoID, UsuarioID)
                OUTPUT INSERTED.OrdenCompraID
                VALUES (@Codigo, @ProveedorID, @BodegaDestinoID, @UsuarioID)";

            var ordenCompraId = await connection.ExecuteScalarAsync<int>(sqlHeader, new
            {
                r.Codigo,
                r.ProveedorID,
                r.BodegaDestinoID,
                UsuarioID = usuarioId
            }, transaction);

            const string sqlDetalle = @"
                INSERT INTO Compras.OrdenesCompraDetalle (OrdenCompraID, ArticuloID, CantidadSolicitada, CostoUnitario)
                VALUES (@OrdenCompraID, @ArticuloID, @CantidadSolicitada, @CostoUnitario)";

            foreach (var linea in r.Detalle)
            {
                await connection.ExecuteAsync(sqlDetalle, new
                {
                    OrdenCompraID = ordenCompraId,
                    linea.ArticuloID,
                    linea.CantidadSolicitada,
                    linea.CostoUnitario
                }, transaction);
            }

            transaction.Commit();
            return ordenCompraId;
        }
        catch
        {
            transaction.Rollback();
            throw; // el middleware de excepciones se encarga de convertirlo en una respuesta HTTP clara
        }
    }

    public async Task<IEnumerable<OrdenCompraResumen>> ListarAsync(string? estado)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT oc.OrdenCompraID, oc.Codigo, p.RazonSocial AS Proveedor, oc.EstadoOC,
                   oc.FechaEmision, SUM(d.CantidadSolicitada * d.CostoUnitario) AS Total
            FROM Compras.OrdenesCompra oc
            JOIN Catalogo.Proveedores p ON p.ProveedorID = oc.ProveedorID
            JOIN Compras.OrdenesCompraDetalle d ON d.OrdenCompraID = oc.OrdenCompraID
            WHERE (@Estado IS NULL OR oc.EstadoOC = @Estado)
            GROUP BY oc.OrdenCompraID, oc.Codigo, p.RazonSocial, oc.EstadoOC, oc.FechaEmision
            ORDER BY oc.FechaEmision DESC";

        return await connection.QueryAsync<OrdenCompraResumen>(sql, new { Estado = estado });
    }

    public async Task<IEnumerable<OrdenCompraDetalleItem>> ObtenerDetalleAsync(int ordenCompraId)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT d.OrdenCompraDetalleID, d.ArticuloID, a.Nombre AS Articulo,
                   d.CantidadSolicitada, d.CantidadRecibida, d.CostoUnitario,
                   u.Abreviatura AS Unidad, a.UnidadesPorEmbalaje
            FROM Compras.OrdenesCompraDetalle d
            JOIN Catalogo.Articulos a ON a.ArticuloID = d.ArticuloID
            LEFT JOIN Catalogo.UnidadesMedida u ON u.UnidadID = a.UnidadID
            WHERE d.OrdenCompraID = @OrdenCompraId";

        return await connection.QueryAsync<OrdenCompraDetalleItem>(sql, new { OrdenCompraId = ordenCompraId });
    }

    public async Task<(int, decimal)> RecibirLineaAsync(int ordenCompraDetalleId, RecibirLineaOrdenCompraRequest r, int usuarioId)
    {
        using var connection = _db.CreateConnection();

        var parametros = new DynamicParameters();
        parametros.Add("OrdenCompraDetalleID", ordenCompraDetalleId);
        parametros.Add("CantidadRecibida", r.CantidadRecibida);
        parametros.Add("NumeroLote", r.NumeroLote);
        parametros.Add("FechaVencimiento", r.FechaVencimiento);
        parametros.Add("UsuarioID", usuarioId);

        var resultado = await connection.QuerySingleAsync<RecibirResultado>(
            "Compras.sp_RecibirOrdenCompra",
            parametros,
            commandType: CommandType.StoredProcedure);

        return (resultado.LoteID, resultado.NuevoCostoPromedio);
    }
}