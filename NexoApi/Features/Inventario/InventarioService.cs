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
                   CAST(CASE WHEN a.Imagen IS NULL THEN 0 ELSE 1 END AS BIT) AS TieneImagen
            FROM Inventario.vw_StockConsolidado s
            JOIN Catalogo.Articulos a ON a.ArticuloID = s.ArticuloID
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
            SELECT TOP 500 k.KardexID, k.Fecha, a.Nombre AS Articulo, b.Nombre AS Bodega,
                   tm.Nombre AS TipoMovimiento, k.Cantidad, k.CostoUnitario,
                   k.CantidadSaldo, k.ObservacionDetallada
            FROM Kardex.KardexMovimientos k
            JOIN Catalogo.Articulos a ON a.ArticuloID = k.ArticuloID
            JOIN Inventario.Bodegas b ON b.BodegaID = k.BodegaID
            JOIN Kardex.TiposMovimientoKardex tm ON tm.TipoMovID = k.TipoMovID
            WHERE (@ArticuloId IS NULL OR k.ArticuloID = @ArticuloId)
              AND (@BodegaId IS NULL OR k.BodegaID = @BodegaId)
              AND (@Desde IS NULL OR k.Fecha >= @Desde)
              AND (@Hasta IS NULL OR k.Fecha < DATEADD(DAY,1,@Hasta))
            ORDER BY k.Fecha DESC, k.KardexID DESC";
        return await connection.QueryAsync<KardexMovimientoItem>(sql,
            new { ArticuloId = articuloId, BodegaId = bodegaId, Desde = desde, Hasta = hasta });
    }
}