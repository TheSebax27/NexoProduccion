using Dapper;
using Microsoft.AspNetCore.Connections;
using NexoApi.Common;
using NexoApi.Features.Inventario.Dtos;
using System.Data;
using System.Data.Entity.Infrastructure;

namespace NexoApi.Features.Inventario;

public interface IInventarioService
{
    Task<IEnumerable<StockConsolidadoItem>> ConsultarStockAsync(int? centroCostoId, int? bodegaId, string? sku);
    Task<RegistrarBajaResponse> RegistrarBajaAsync(RegistrarBajaRequest request, int usuarioId);
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
            SELECT ArticuloID, SKU, Articulo, TipoArticulo, BodegaID, Bodega,
                   CentroCostoID, CentroCosto, LoteID, NumeroLote, FechaVencimiento,
                   CantidadActual, CostoUnitarioLote, ValorTotal, RequierePedido
            FROM Inventario.vw_StockConsolidado
            WHERE (@CentroCostoId IS NULL OR CentroCostoID = @CentroCostoId)
              AND (@BodegaId IS NULL OR BodegaID = @BodegaId)
              AND (@Sku IS NULL OR SKU = @Sku)
            ORDER BY Articulo, Bodega";

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
}