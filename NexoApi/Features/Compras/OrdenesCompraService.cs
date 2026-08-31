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

    // Pedidos → Visions staging
    Task<List<PedidoParaVisionsDto>> ListarPedidosParaVisionsAsync(int centroCostoId);
    Task MarcarPedidoExportadoVisionsAsync(int pedidoId);
    Task ActualizarNumeroPedidoVisionsAsync(int pedidoId, ActualizarNumeroPedidoVisionsRequest request);
    Task AutoRecibirDesdeVisionsAsync(int pedidoId, string nroDoc);

    Task<IEnumerable<ComparacionPrecioRow>> ComparacionPreciosAsync(int? articuloId, int? proveedorId);
    Task EliminarOrdenCompraAsync(int ordenId);
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
                INSERT INTO Compras.OrdenesCompra (Codigo, ProveedorID, BodegaDestinoID, UsuarioID, CentroCostoID)
                OUTPUT INSERTED.OrdenCompraID
                VALUES (@Codigo, @ProveedorID, @BodegaDestinoID, @UsuarioID, @CentroCostoID)";

            var ordenCompraId = await connection.ExecuteScalarAsync<int>(sqlHeader, new
            {
                r.Codigo,
                r.ProveedorID,
                r.BodegaDestinoID,
                UsuarioID = usuarioId,
                r.CentroCostoID
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
                   oc.FechaEmision, SUM(d.CantidadSolicitada * d.CostoUnitario) AS Total, oc.FechaRecepcion,
                   oc.ExportadoVisions, oc.NroDocVisions, oc.TipDocVisions
            FROM Compras.OrdenesCompra oc
            JOIN Catalogo.Proveedores p ON p.ProveedorID = oc.ProveedorID
            JOIN Compras.OrdenesCompraDetalle d ON d.OrdenCompraID = oc.OrdenCompraID
            WHERE (@Estado IS NULL OR oc.EstadoOC = @Estado)
            GROUP BY oc.OrdenCompraID, oc.Codigo, p.RazonSocial, oc.EstadoOC, oc.FechaEmision, oc.FechaRecepcion,
                     oc.ExportadoVisions, oc.NroDocVisions, oc.TipDocVisions
            ORDER BY oc.FechaEmision DESC";

        return await connection.QueryAsync<OrdenCompraResumen>(sql, new { Estado = estado });
    }

    public async Task<IEnumerable<OrdenCompraDetalleItem>> ObtenerDetalleAsync(int ordenCompraId)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT d.OrdenCompraDetalleID, d.ArticuloID, a.Nombre AS Articulo,
                   d.CantidadSolicitada, d.CantidadRecibida, d.CostoUnitario,
                   a.PresentacionCodigo AS Unidad, p.Fracciones AS UnidadesPorEmbalaje, d.FechaUltimaRecepcion
            FROM Compras.OrdenesCompraDetalle d
            JOIN Catalogo.Tarjetas a ON a.ArticuloID = d.ArticuloID
            LEFT JOIN Catalogo.Presentacion p ON p.Codigo = a.PresentacionCodigo
            WHERE d.OrdenCompraID = @OrdenCompraId";

        return await connection.QueryAsync<OrdenCompraDetalleItem>(sql, new { OrdenCompraId = ordenCompraId });
    }

    public async Task<(int, decimal)> RecibirLineaAsync(int ordenCompraDetalleId, RecibirLineaOrdenCompraRequest r, int usuarioId)
    {
        using var connection = _db.CreateConnection();

        // Leer ArticuloID y costo para poder encolar el evento hacia Visions.
        var detalle = await connection.QuerySingleOrDefaultAsync<(int ArticuloID, decimal CostoUnitario)>(
            "SELECT ArticuloID, CostoUnitario FROM Compras.OrdenesCompraDetalle WHERE OrdenCompraDetalleID = @Id",
            new { Id = ordenCompraDetalleId });

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

        // Replicar entrada de compra en Visions para todos los CC mapeados.
        if (detalle.ArticuloID > 0)
        {
            await connection.ExecuteAsync(@"
                INSERT INTO Integracion.EventosSalientes (TipoEvento, CentroCostoID, ArticuloID, Cantidad, CostoUnitario)
                SELECT 'RECEPCION_COMPRA', ma.CentroCostoID, ma.ArticuloID, @Cantidad, @CostoUnitario
                FROM Integracion.MapeoArticulos ma
                JOIN Organizacion.CentrosCosto cc ON cc.CentroCostoID = ma.CentroCostoID
                WHERE ma.ArticuloID = @ArticuloId AND ma.Estado = 1 AND cc.TieneVisions = 1",
                new { ArticuloId = detalle.ArticuloID, Cantidad = r.CantidadRecibida, CostoUnitario = detalle.CostoUnitario });
        }

        return (resultado.LoteID, resultado.NuevoCostoPromedio);
    }

    public async Task<List<PedidoParaVisionsDto>> ListarPedidosParaVisionsAsync(int centroCostoId)
    {
        using var connection = _db.CreateConnection();

        const string sqlCabecera = @"
            SELECT oc.OrdenCompraID AS PedidoID, oc.Codigo, oc.TipoMovimiento,
                   oc.FechaEmision AS Fecha,
                   pr.NIT AS ProveedorNit, pr.RazonSocial AS ProveedorNombre
            FROM Compras.OrdenesCompra oc
            JOIN Catalogo.Proveedores pr ON pr.ProveedorID = oc.ProveedorID
            WHERE oc.ExportadoVisions = 0";

        var cabeceras = (await connection.QueryAsync<(int PedidoID, string Codigo, string TipoMovimiento,
            DateTime Fecha, string? ProveedorNit, string ProveedorNombre)>(sqlCabecera)).ToList();

        var resultado = new List<PedidoParaVisionsDto>();
        foreach (var c in cabeceras)
        {
            // Solo incluir líneas con mapeo a la referencia de Visions del CC del agente.
            const string sqlLineas = @"
                SELECT CAST(ROW_NUMBER() OVER (ORDER BY d.OrdenCompraDetalleID) AS INT) AS Orden,
                       a.Referencia AS ReferenciaVisions,
                       a.Nombre AS NombreArticulo,
                       d.CantidadSolicitada AS Cantidad,
                       d.CostoUnitario
                FROM Compras.OrdenesCompraDetalle d
                JOIN Catalogo.Tarjetas a ON a.ArticuloID = d.ArticuloID
                LEFT JOIN Integracion.MapeoArticulos ma
                    ON ma.ArticuloID = d.ArticuloID AND ma.CentroCostoID = @CentroCostoId AND ma.Estado = 1
                WHERE d.OrdenCompraID = @PedidoID
                ORDER BY d.OrdenCompraDetalleID";

            var lineas = (await connection.QueryAsync<LineaPedidoParaVisionsDto>(
                sqlLineas, new { PedidoID = c.PedidoID, CentroCostoId = centroCostoId })).ToList();

            resultado.Add(new PedidoParaVisionsDto(
                c.PedidoID, c.Codigo, c.TipoMovimiento, c.Fecha,
                c.ProveedorNit, c.ProveedorNombre, lineas));
        }
        return resultado;
    }

    public async Task MarcarPedidoExportadoVisionsAsync(int pedidoId)
    {
        using var connection = _db.CreateConnection();
        await connection.ExecuteAsync(
            "UPDATE Compras.OrdenesCompra SET ExportadoVisions = 1 WHERE OrdenCompraID = @PedidoId",
            new { PedidoId = pedidoId });
    }

    public async Task ActualizarNumeroPedidoVisionsAsync(int pedidoId, ActualizarNumeroPedidoVisionsRequest r)
    {
        using var connection = _db.CreateConnection();
        await connection.ExecuteAsync(
            @"UPDATE Compras.OrdenesCompra
              SET NroDocVisions = @NroDoc, TipDocVisions = @TipDoc
              WHERE OrdenCompraID = @PedidoId",
            new { PedidoId = pedidoId, r.NroDoc, r.TipDoc });
    }

    public async Task AutoRecibirDesdeVisionsAsync(int pedidoId, string nroDoc)
    {
        using var connection = _db.CreateConnection();

        var lineas = (await connection.QueryAsync<(int Id, decimal Solicitada, decimal Recibida)>(
            @"SELECT d.OrdenCompraDetalleID, d.CantidadSolicitada, d.CantidadRecibida
              FROM Compras.OrdenesCompraDetalle d
              WHERE d.OrdenCompraID = @PedidoId AND d.CantidadRecibida < d.CantidadSolicitada",
            new { PedidoId = pedidoId })).ToList();

        // Usar el primer usuario administrador como responsable del auto-recibo.
        var usuarioSistema = await connection.QuerySingleOrDefaultAsync<int>(
            "SELECT TOP 1 UsuarioID FROM Seguridad.Usuarios ORDER BY UsuarioID");

        foreach (var linea in lineas)
        {
            var parametros = new DynamicParameters();
            parametros.Add("OrdenCompraDetalleID", linea.Id);
            parametros.Add("CantidadRecibida", linea.Solicitada - linea.Recibida);
            parametros.Add("NumeroLote", nroDoc);
            parametros.Add("FechaVencimiento", null);
            parametros.Add("UsuarioID", usuarioSistema);
            // Se usa el SP existente pero sin disparar el evento RECEPCION_COMPRA a Visions
            // (Visions ya registró la entrada; dispararlo de vuelta duplicaría el stock allá)
            await connection.QuerySingleAsync<RecibirResultado>(
                "Compras.sp_RecibirOrdenCompra", parametros, commandType: CommandType.StoredProcedure);
        }
    }

    public async Task<IEnumerable<ComparacionPrecioRow>> ComparacionPreciosAsync(int? articuloId, int? proveedorId)
    {
        using var connection = _db.CreateConnection();
        return await connection.QueryAsync<ComparacionPrecioRow>(@"
            WITH UltimoPrecio AS (
                SELECT d.ArticuloID, oc.ProveedorID, d.CostoUnitario,
                       ROW_NUMBER() OVER (PARTITION BY d.ArticuloID, oc.ProveedorID
                                          ORDER BY oc.FechaEmision DESC, oc.OrdenCompraID DESC) AS rn
                FROM Compras.OrdenesCompraDetalle d
                JOIN Compras.OrdenesCompra oc ON oc.OrdenCompraID = d.OrdenCompraID
            )
            SELECT
                a.ArticuloID, a.Referencia AS SKU, a.Nombre AS Articulo,
                p.ProveedorID, p.RazonSocial AS Proveedor,
                COUNT(DISTINCT oc.OrdenCompraID) AS TotalPedidos,
                MIN(d.CostoUnitario)                      AS PrecioMin,
                MAX(d.CostoUnitario)                      AS PrecioMax,
                CAST(AVG(d.CostoUnitario) AS DECIMAL(18,4)) AS PrecioPromedio,
                up.CostoUnitario                          AS UltimoPrecio,
                MAX(oc.FechaEmision)                      AS UltimaCompra
            FROM Compras.OrdenesCompraDetalle d
            JOIN Compras.OrdenesCompra oc ON oc.OrdenCompraID = d.OrdenCompraID
            JOIN Catalogo.Tarjetas a    ON a.ArticuloID = d.ArticuloID
            JOIN Catalogo.Proveedores p ON p.ProveedorID = oc.ProveedorID
            JOIN UltimoPrecio up ON up.ArticuloID = d.ArticuloID
                                 AND up.ProveedorID = oc.ProveedorID
                                 AND up.rn = 1
            WHERE (@articuloId IS NULL OR d.ArticuloID  = @articuloId)
              AND (@proveedorId IS NULL OR oc.ProveedorID = @proveedorId)
            GROUP BY a.ArticuloID, a.Referencia, a.Nombre, p.ProveedorID, p.RazonSocial, up.CostoUnitario
            ORDER BY a.Nombre, p.RazonSocial",
            new { articuloId, proveedorId });
    }

    private record EstadoOrdenCompra(string EstadoOC, bool ExportadoVisions);

    public async Task EliminarOrdenCompraAsync(int ordenId)
    {
        using var connection = _db.CreateConnection();

        var orden = await connection.QuerySingleOrDefaultAsync<EstadoOrdenCompra>(
            "SELECT EstadoOC, ExportadoVisions FROM Compras.OrdenesCompra WHERE OrdenCompraID = @Id",
            new { Id = ordenId });

        if (orden is null)
            throw new KeyNotFoundException("Orden de compra no encontrada.");
        if (orden!.EstadoOC == "RECIBIDA")
            throw new InvalidOperationException("No se puede eliminar: la orden ya fue recibida completamente.");

        var tieneRecibidos = await connection.ExecuteScalarAsync<int>(
            "SELECT ISNULL(SUM(CantidadRecibida), 0) FROM Compras.OrdenesCompraDetalle WHERE OrdenCompraID = @Id",
            new { Id = ordenId });
        if (tieneRecibidos > 0)
            throw new InvalidOperationException("No se puede eliminar: la orden tiene mercancía parcialmente recibida.");

        connection.Open();
        using var tx = connection.BeginTransaction();
        try
        {
            await connection.ExecuteAsync(
                "DELETE FROM Compras.OrdenesCompraDetalle WHERE OrdenCompraID = @Id",
                new { Id = ordenId }, tx);
            await connection.ExecuteAsync(
                "DELETE FROM Compras.OrdenesCompra WHERE OrdenCompraID = @Id",
                new { Id = ordenId }, tx);
            if (orden.ExportadoVisions)
                await connection.ExecuteAsync(
                    "INSERT INTO Integracion.PendientesLimpiezaVisions (Tipo, EntidadID) VALUES ('PEDIDO', @Id)",
                    new { Id = ordenId }, tx);
            tx.Commit();
        }
        catch { tx.Rollback(); throw; }
    }
}