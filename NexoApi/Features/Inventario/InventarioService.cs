using System.Data;
using Dapper;
using NexoApi.Common.Data;
using NexoApi.Features.Inventario.Dtos;

namespace NexoApi.Features.Inventario;

public interface IInventarioService
{
    Task<IEnumerable<StockConsolidadoItem>> ConsultarStockAsync(int? centroCostoId, int? bodegaId, string? sku);
    Task<RegistrarBajaResponse> RegistrarBajaAsync(RegistrarBajaRequest request, int usuarioId);
    Task<AjustarInventarioResponse> AjustarInventarioAsync(AjustarInventarioRequest request, int usuarioId);
    Task<IEnumerable<MotivoPerdidaItem>> ListarMotivosPerdidaAsync();
    Task<IEnumerable<KardexMovimientoItem>> ConsultarKardexAsync(int? articuloId, int? bodegaId, DateTime? desde, DateTime? hasta);
    Task<IEnumerable<LoteProximoVencerItem>> ListarLotesPorVencerAsync(int diasAlerta);
}

public class InventarioService : IInventarioService
{
    private readonly IDbConnectionFactory _db;

    public InventarioService(IDbConnectionFactory db)
    {
        _db = db;
    }

    public async Task<IEnumerable<StockConsolidadoItem>> ConsultarStockAsync(int? centroCostoId, int? bodegaId, string? sku)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT s.ArticuloID, s.SKU, s.Articulo, s.TipoArticulo, s.Unidad, s.UnidadesPorEmbalaje, s.BodegaID, s.Bodega,
                   s.CentroCostoID, s.CentroCosto, s.LoteID, s.NumeroLote, s.FechaVencimiento,
                   s.CantidadActual, s.CostoUnitarioLote, s.ValorTotal, s.RequierePedido,
                   CAST(CASE WHEN a.Imagen IS NULL THEN 0 ELSE 1 END AS BIT) AS TieneImagen,
                   ISNULL(a.StockMinimo, 0) AS StockMinimo,
                   ISNULL(a.CostoPromedio, 0) AS CostoPromedio,
                   ISNULL(a.PPublico, 0) AS PrecioVenta
            FROM Inventario.vw_StockConsolidado s
            JOIN Catalogo.Tarjetas a ON a.ArticuloID = s.ArticuloID
            WHERE (@CentroCostoId IS NULL OR s.CentroCostoID = @CentroCostoId)
              AND (@BodegaId IS NULL OR s.BodegaID = @BodegaId)
              AND (@Sku IS NULL OR s.SKU = @Sku)
            ORDER BY s.Articulo, s.Bodega";

        return await connection.QueryAsync<StockConsolidadoItem>(sql, new
        {
            CentroCostoId = centroCostoId,
            BodegaId = bodegaId,
            Sku = sku
        });
    }

    public async Task<RegistrarBajaResponse> RegistrarBajaAsync(RegistrarBajaRequest r, int usuarioId)
    {
        using var connection = _db.CreateConnection();

        var parametros = new DynamicParameters();
        parametros.Add("ArticuloID", r.ArticuloID);
        parametros.Add("BodegaID", r.BodegaID);
        parametros.Add("LoteID", r.LoteID);
        parametros.Add("CantidadPerdida", r.CantidadPerdida);
        parametros.Add("MotivoID", r.MotivoID);
        parametros.Add("ObservacionDetallada", r.ObservacionDetallada);
        parametros.Add("UsuarioRegistraID", usuarioId);

        var resultado = await connection.QuerySingleAsync<RegistrarBajaResponse>(
            "Kardex.sp_RegistrarBajaInventario",
            parametros,
            commandType: CommandType.StoredProcedure);

        // Replicar baja en Visions para todos los CC mapeados (Cantidad negativa = descuento).
        await connection.ExecuteAsync(@"
            INSERT INTO Integracion.EventosSalientes (TipoEvento, CentroCostoID, ArticuloID, Cantidad, CostoUnitario)
            SELECT 'BAJA_INVENTARIO', ma.CentroCostoID, ma.ArticuloID, -@Cantidad, ISNULL(a.CostoPromedio, 0)
            FROM Integracion.MapeoArticulos ma
            JOIN Catalogo.Tarjetas a          ON a.ArticuloID    = ma.ArticuloID
            JOIN Organizacion.CentrosCosto cc ON cc.CentroCostoID = ma.CentroCostoID
            WHERE ma.ArticuloID = @ArticuloId AND ma.Estado = 1 AND cc.TieneVisions = 1",
            new { ArticuloId = r.ArticuloID, Cantidad = r.CantidadPerdida });

        return resultado;
    }

    public async Task<AjustarInventarioResponse> AjustarInventarioAsync(AjustarInventarioRequest r, int usuarioId)
    {
        using var connection = _db.CreateConnection();

        var parametros = new DynamicParameters();
        parametros.Add("ArticuloID", r.ArticuloID);
        parametros.Add("BodegaID", r.BodegaID);
        parametros.Add("Cantidad", r.Cantidad);
        parametros.Add("CostoUnitario", r.CostoUnitario);
        parametros.Add("Motivo", r.Motivo);
        parametros.Add("UsuarioID", usuarioId);

        var resultado = await connection.QuerySingleAsync<AjustarInventarioResponse>(
            "Kardex.sp_AjustePositivoInventario",
            parametros,
            commandType: CommandType.StoredProcedure);

        // Replicar ajuste en Visions para todos los CC mapeados.
        await connection.ExecuteAsync(@"
            INSERT INTO Integracion.EventosSalientes (TipoEvento, CentroCostoID, ArticuloID, Cantidad, CostoUnitario)
            SELECT 'AJUSTE_INVENTARIO', ma.CentroCostoID, ma.ArticuloID, @Cantidad, @CostoUnitario
            FROM Integracion.MapeoArticulos ma
            JOIN Organizacion.CentrosCosto cc ON cc.CentroCostoID = ma.CentroCostoID
            WHERE ma.ArticuloID = @ArticuloId AND ma.Estado = 1 AND cc.TieneVisions = 1",
            new { ArticuloId = r.ArticuloID, r.Cantidad, CostoUnitario = r.CostoUnitario });

        return resultado;
    }

    public async Task<IEnumerable<MotivoPerdidaItem>> ListarMotivosPerdidaAsync()
    {
        using var connection = _db.CreateConnection();
        return await connection.QueryAsync<MotivoPerdidaItem>(
            "SELECT MotivoID, Nombre FROM Kardex.TiposMotivoLoss ORDER BY Nombre");
    }

    public async Task<IEnumerable<KardexMovimientoItem>> ConsultarKardexAsync(
        int? articuloId, int? bodegaId, DateTime? desde, DateTime? hasta)
    {
        using var connection = _db.CreateConnection();
        const string sql = @"
            SELECT TOP 500
                k.KardexID, k.Fecha,
                a.Referencia AS SKU, a.Nombre AS Articulo,
                a.PresentacionCodigo AS Unidad, p.Fracciones AS UnidadesPorEmbalaje,
                b.Nombre AS Bodega,
                tm.Nombre AS TipoMovimiento,
                k.Cantidad, k.CostoUnitario, k.CantidadSaldo,
                ABS(k.Cantidad) * k.CostoUnitario AS ValorMovimiento,
                k.ObservacionDetallada,
                l.NumeroLote, l.FechaVencimiento
            FROM Kardex.KardexMovimientos k
            JOIN Catalogo.Tarjetas a ON a.ArticuloID = k.ArticuloID
            LEFT JOIN Catalogo.Presentacion p ON p.Codigo = a.PresentacionCodigo
            JOIN Inventario.Bodegas b ON b.BodegaID = k.BodegaID
            JOIN Kardex.TiposMovimientoKardex tm ON tm.TipoMovID = k.TipoMovID
            LEFT JOIN Inventario.Lotes l ON l.LoteID = k.LoteID
            WHERE (@ArticuloId IS NULL OR k.ArticuloID = @ArticuloId)
              AND (@BodegaId IS NULL OR k.BodegaID = @BodegaId)
              AND (@Desde IS NULL OR k.Fecha >= @Desde)
              AND (@Hasta IS NULL OR k.Fecha < DATEADD(DAY,1,@Hasta))
            ORDER BY k.Fecha DESC, k.KardexID DESC";
        return await connection.QueryAsync<KardexMovimientoItem>(sql,
            new { ArticuloId = articuloId, BodegaId = bodegaId, Desde = desde, Hasta = hasta });
    }

    public async Task<IEnumerable<LoteProximoVencerItem>> ListarLotesPorVencerAsync(int diasAlerta)
    {
        using var connection = _db.CreateConnection();
        const string sql = @"
            SELECT a.Referencia AS SKU, a.Nombre AS Articulo, b.Nombre AS Bodega,
                   l.NumeroLote, l.FechaVencimiento,
                   s.CantidadActual,
                   DATEDIFF(DAY, GETDATE(), l.FechaVencimiento) AS DiasParaVencer
            FROM Inventario.vw_StockConsolidado s
            JOIN Catalogo.Tarjetas a ON a.ArticuloID = s.ArticuloID
            JOIN Inventario.Bodegas b ON b.BodegaID = s.BodegaID
            JOIN Inventario.Lotes l ON l.LoteID = s.LoteID
            WHERE s.CantidadActual > 0
              AND l.FechaVencimiento IS NOT NULL
              AND l.FechaVencimiento <= DATEADD(DAY, @DiasAlerta, GETDATE())
            ORDER BY l.FechaVencimiento ASC";
        return await connection.QueryAsync<LoteProximoVencerItem>(sql, new { DiasAlerta = diasAlerta });
    }
}