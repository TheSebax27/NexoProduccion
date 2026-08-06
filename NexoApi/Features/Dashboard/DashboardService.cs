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

    // Resumenes transversales para BI (agosto 2026) -- cada uno lee de su
    // propio modulo, no hay tabla de agregacion propia del Dashboard.
    Task<ResumenCrmItem> ObtenerResumenCrmAsync(DateTime desde, DateTime hasta);
    Task<IEnumerable<EmpleadosPorCentroCostoItem>> ObtenerEmpleadosPorCentroCostoAsync();
    Task<ResumenPlanificacionItem> ObtenerResumenPlanificacionAsync();
    Task<ResumenInventarioItem> ObtenerResumenInventarioAsync();
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

    public async Task<ResumenCrmItem> ObtenerResumenCrmAsync(DateTime desde, DateTime hasta)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT
                (SELECT COUNT(*) FROM Crm.Clientes WHERE FechaCreacion >= @Desde AND FechaCreacion <= @Hasta) AS ClientesNuevos,
                (SELECT COUNT(*) FROM Crm.Interacciones WHERE Fecha >= @Desde AND Fecha <= @Hasta) AS Interacciones";

        return await connection.QuerySingleAsync<ResumenCrmItem>(sql, new { Desde = desde.Date, Hasta = hasta.Date });
    }

    public async Task<IEnumerable<EmpleadosPorCentroCostoItem>> ObtenerEmpleadosPorCentroCostoAsync()
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT ISNULL(cc.Nombre, 'Sin asignar') AS CentroCosto, COUNT(*) AS TotalEmpleados
            FROM Rrhh.Empleados e
            LEFT JOIN Organizacion.CentrosCosto cc ON cc.CentroCostoID = e.CentroCostoID
            WHERE e.Estado = 1
            GROUP BY cc.Nombre
            ORDER BY TotalEmpleados DESC";

        return await connection.QueryAsync<EmpleadosPorCentroCostoItem>(sql);
    }

    // Promedio de cumplimiento del mes actual (no historico completo) -- es
    // la foto "de ahora" que tiene sentido en un landing de BI.
    public async Task<ResumenPlanificacionItem> ObtenerResumenPlanificacionAsync()
    {
        using var connection = _db.CreateConnection();

        // NOTA: AVG() no puede envolver directamente una expresion que
        // contiene una subconsulta correlacionada con su propio agregado
        // (SQL Server error 130 "Cannot perform an aggregate function on an
        // expression containing an aggregate or a subquery") -- se resuelve
        // materializando el porcentaje por fila en una tabla derivada y
        // promediando DESPUES, en la consulta externa.
        const string sql = @"
            DECLARE @PeriodoActual DATE = DATEFROMPARTS(YEAR(GETUTCDATE()), MONTH(GETUTCDATE()), 1);

            SELECT
                ISNULL((SELECT AVG(Cumplimiento) FROM (
                    SELECT CASE WHEN d.CantidadProyectada > 0
                         THEN (ISNULL((
                             SELECT SUM(km.Cantidad) FROM Kardex.KardexMovimientos km
                             JOIN Kardex.TiposMovimientoKardex t ON t.TipoMovID = km.TipoMovID
                             WHERE t.Codigo = 'ENTRADA_PT' AND km.ArticuloID = d.ArticuloID
                               AND km.CentroCostoID = d.CentroCostoID AND km.Fecha >= d.Periodo AND km.Fecha < DATEADD(MONTH, 1, d.Periodo)
                         ), 0) / d.CantidadProyectada * 100) ELSE 0 END AS Cumplimiento
                    FROM Planificacion.DemandaProyectada d WHERE d.Periodo = @PeriodoActual
                ) x), 0) AS CumplimientoDemandaPromedio,
                ISNULL((SELECT AVG(Cumplimiento) FROM (
                    SELECT CASE WHEN m.MetaValor > 0
                         THEN (ISNULL((
                             SELECT SUM(km.Cantidad * a.PrecioVenta) FROM Kardex.KardexMovimientos km
                             JOIN Kardex.TiposMovimientoKardex t ON t.TipoMovID = km.TipoMovID
                             JOIN Catalogo.Articulos a ON a.ArticuloID = km.ArticuloID
                             WHERE t.Codigo = 'SALIDA_VENTA_VISIONS' AND km.CentroCostoID = m.CentroCostoID
                               AND km.Fecha >= m.Periodo AND km.Fecha < DATEADD(MONTH, 1, m.Periodo)
                         ), 0) / m.MetaValor * 100) ELSE 0 END AS Cumplimiento
                    FROM Planificacion.MetasVenta m WHERE m.Periodo = @PeriodoActual
                ) y), 0) AS CumplimientoVentaPromedio";

        return await connection.QuerySingleAsync<ResumenPlanificacionItem>(sql);
    }

    public async Task<ResumenInventarioItem> ObtenerResumenInventarioAsync()
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT ISNULL(SUM(ValorTotal), 0) AS ValorTotalStock,
                   ISNULL(SUM(CASE WHEN RequierePedido = 1 THEN 1 ELSE 0 END), 0) AS ArticulosConAlerta
            FROM Inventario.vw_StockConsolidado";

        return await connection.QuerySingleAsync<ResumenInventarioItem>(sql);
    }
}