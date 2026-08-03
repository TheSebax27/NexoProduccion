using Dapper;
using NexoApi.Common.Data;
using NexoApi.Features.Dashboard.Dtos;

namespace NexoApi.Features.Dashboard;

public interface IDashboardService
{
    Task<IEnumerable<PlanVsRealPunto>> ObtenerPlanVsRealAsync(DateTime desde, DateTime hasta);
    Task<IEnumerable<DistribucionCentroCostoItem>> ObtenerDistribucionCentroCostoAsync();
    Task<IEnumerable<PerdidaPorMotivoItem>> ObtenerPerdidasPorMotivoAsync(DateTime desde, DateTime hasta);
    Task<IEnumerable<TendenciaCostoPunto>> ObtenerTendenciaCostoAsync(int articuloId);
    Task<IEnumerable<CumplimientoCentroCostoItem>> ObtenerCumplimientoAsync();
}

public class DashboardService : IDashboardService
{
    private readonly IDbConnectionFactory _db;

    public DashboardService(IDbConnectionFactory db)
    {
        _db = db;
    }

    public async Task<IEnumerable<PlanVsRealPunto>> ObtenerPlanVsRealAsync(DateTime desde, DateTime hasta)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT Fecha, SUM(TotalPlanificado) AS TotalPlanificado, SUM(TotalReal) AS TotalReal
            FROM Produccion.vw_ProduccionPlanVsReal
            WHERE Fecha >= @Desde AND Fecha <= @Hasta
            GROUP BY Fecha
            ORDER BY Fecha";

        return await connection.QueryAsync<PlanVsRealPunto>(sql, new { Desde = desde.Date, Hasta = hasta.Date });
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

    public async Task<IEnumerable<PerdidaPorMotivoItem>> ObtenerPerdidasPorMotivoAsync(DateTime desde, DateTime hasta)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT Motivo, SUM(CantidadTotalPerdida) AS CantidadTotalPerdida, SUM(ValorTotalPerdido) AS ValorTotalPerdido
            FROM Kardex.vw_PerdidasPorMotivo
            WHERE Fecha >= @Desde AND Fecha <= @Hasta
            GROUP BY Motivo
            ORDER BY ValorTotalPerdido DESC";

        return await connection.QueryAsync<PerdidaPorMotivoItem>(sql, new { Desde = desde.Date, Hasta = hasta.Date });
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

    public async Task<IEnumerable<CumplimientoCentroCostoItem>> ObtenerCumplimientoAsync()
    {
        using var connection = _db.CreateConnection();
        const string sql = @"
            SELECT CentroCostoID, CentroCosto, TotalOrdenesFinalizadas, OrdenesATiempo,
                   ISNULL(PorcentajeCumplimiento, 0) AS PorcentajeCumplimiento
            FROM Produccion.vw_CumplimientoPlanificacion
            ORDER BY PorcentajeCumplimiento DESC";
        return await connection.QueryAsync<CumplimientoCentroCostoItem>(sql);
    }
}