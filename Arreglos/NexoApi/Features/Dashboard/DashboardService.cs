using Dapper;
using NexoApi.Common.Data;
using NexoApi.Features.Dashboard.Dtos;

namespace NexoApi.Features.Dashboard;

public interface IDashboardService
{
    Task<IEnumerable<PlanVsRealPunto>> ObtenerPlanVsRealAsync(int dias);
    Task<IEnumerable<DistribucionCentroCostoItem>> ObtenerDistribucionCentroCostoAsync();
    Task<IEnumerable<PerdidaPorMotivoItem>> ObtenerPerdidasPorMotivoAsync(int dias);
    Task<IEnumerable<TendenciaCostoPunto>> ObtenerTendenciaCostoAsync(int articuloId);
}

public class DashboardService : IDashboardService
{
    private readonly IDbConnectionFactory _db;

    public DashboardService(IDbConnectionFactory db)
    {
        _db = db;
    }

    public async Task<IEnumerable<PlanVsRealPunto>> ObtenerPlanVsRealAsync(int dias)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT Fecha, SUM(TotalPlanificado) AS TotalPlanificado, SUM(TotalReal) AS TotalReal
            FROM Produccion.vw_ProduccionPlanVsReal
            WHERE Fecha >= DATEADD(DAY, -@Dias, CAST(GETDATE() AS DATE))
            GROUP BY Fecha
            ORDER BY Fecha";

        return await connection.QueryAsync<PlanVsRealPunto>(sql, new { Dias = dias });
    }

    public async Task<IEnumerable<DistribucionCentroCostoItem>> ObtenerDistribucionCentroCostoAsync()
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT CentroCostoID, CentroCosto, TotalOrdenes, TotalUnidadesProducidas, InversionTotal
            FROM Produccion.vw_DistribucionPorCentroCosto
            ORDER BY TotalUnidadesProducidas DESC";

        return await connection.QueryAsync<DistribucionCentroCostoItem>(sql);
    }

    public async Task<IEnumerable<PerdidaPorMotivoItem>> ObtenerPerdidasPorMotivoAsync(int dias)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT Motivo, SUM(CantidadTotalPerdida) AS CantidadTotalPerdida, SUM(ValorTotalPerdido) AS ValorTotalPerdido
            FROM Kardex.vw_PerdidasPorMotivo
            WHERE Fecha >= DATEADD(DAY, -@Dias, CAST(GETDATE() AS DATE))
            GROUP BY Motivo
            ORDER BY ValorTotalPerdido DESC";

        return await connection.QueryAsync<PerdidaPorMotivoItem>(sql, new { Dias = dias });
    }

    public async Task<IEnumerable<TendenciaCostoPunto>> ObtenerTendenciaCostoAsync(int articuloId)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT Fecha, CostoUnitarioReal
            FROM Produccion.vw_TendenciaCostoUnitario
            WHERE ArticuloID = @ArticuloId
            ORDER BY Fecha";

        return await connection.QueryAsync<TendenciaCostoPunto>(sql, new { ArticuloId = articuloId });
    }
}