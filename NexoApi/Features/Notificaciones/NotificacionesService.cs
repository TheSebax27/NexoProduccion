using System.Security.Claims;
using Dapper;
using NexoApi.Common.Data;
using NexoApi.Features.Crm;
using NexoApi.Features.Notificaciones.Dtos;
using NexoApi.Features.Planificacion;
using NexoApi.Features.Proyectos;

namespace NexoApi.Features.Notificaciones;

public interface INotificacionesService
{
    Task<ResumenNotificaciones> ObtenerResumenAsync(ClaimsPrincipal usuario);
}

// Notificaciones "agregadas por categoria" a proposito -- no una fila por
// cada articulo con bajo stock (seria una lista larga y molesta), sino un
// resumen con conteo por categoria (Sin Stock, Bajo Stock, Produccion en
// Proceso, y desde agosto 2026 las alertas ya construidas en BI) y un link
// a la pantalla correspondiente para ver el detalle.
public class NotificacionesService : INotificacionesService
{
    private readonly IDbConnectionFactory _db;
    private readonly ICrmService _crm;
    private readonly IPlanificacionService _planificacion;
    private readonly IProyectosService _proyectos;

    public NotificacionesService(IDbConnectionFactory db, ICrmService crm, IPlanificacionService planificacion, IProyectosService proyectos)
    {
        _db = db;
        _crm = crm;
        _planificacion = planificacion;
        _proyectos = proyectos;
    }

    public async Task<ResumenNotificaciones> ObtenerResumenAsync(ClaimsPrincipal usuario)
    {
        using var connection = _db.CreateConnection();
        var items = new List<NotificacionItem>();

        // Sin stock: total agrupado por artículo = 0
        const string sqlSinStock = @"
            SELECT g.Articulo
            FROM (
                SELECT ArticuloID, MAX(Articulo) AS Articulo, SUM(CantidadActual) AS TotalStock
                FROM Inventario.vw_StockConsolidado
                GROUP BY ArticuloID
            ) g
            WHERE g.TotalStock = 0
            ORDER BY g.Articulo";
        var sinStock = (await connection.QueryAsync<string>(sqlSinStock)).ToList();
        if (sinStock.Count > 0)
        {
            items.Add(new NotificacionItem(
                "SinStock", "error",
                $"{sinStock.Count} artículo{(sinStock.Count == 1 ? "" : "s")} sin stock",
                ResumirNombres(sinStock),
                "/inventario/stock"));
        }

        // Bajo reorden: total agrupado > 0 pero <= StockMinimo del catálogo
        const string sqlBajoStock = @"
            SELECT g.Articulo
            FROM (
                SELECT s.ArticuloID, MAX(s.Articulo) AS Articulo, SUM(s.CantidadActual) AS TotalStock
                FROM Inventario.vw_StockConsolidado s
                GROUP BY s.ArticuloID
            ) g
            JOIN Catalogo.Articulos a ON a.ArticuloID = g.ArticuloID
            WHERE a.StockMinimo > 0
              AND g.TotalStock > 0
              AND g.TotalStock <= a.StockMinimo
            ORDER BY g.Articulo";
        var bajoStock = (await connection.QueryAsync<string>(sqlBajoStock)).ToList();
        if (bajoStock.Count > 0)
        {
            items.Add(new NotificacionItem(
                "BajoStock", "warning",
                $"{bajoStock.Count} artículo{(bajoStock.Count == 1 ? "" : "s")} bajo el stock mínimo",
                ResumirNombres(bajoStock),
                "/inventario/stock"));
        }

        const string sqlEnProceso = @"
            SELECT op.CodigoOP
            FROM Produccion.OrdenesProduccion op
            JOIN Produccion.EstadosOP e ON e.EstadoOPID = op.EstadoOPID
            WHERE e.Nombre = 'En Proceso'
            ORDER BY op.FechaInicio DESC";
        var enProceso = (await connection.QueryAsync<string>(sqlEnProceso)).ToList();
        if (enProceso.Count > 0)
        {
            items.Add(new NotificacionItem(
                "EnProceso", "info",
                $"{enProceso.Count} orden{(enProceso.Count == 1 ? "" : "es")} de producción en proceso",
                ResumirNombres(enProceso),
                "/produccion/ordenes"));
        }

        // ---------- Alertas agregadas agosto 2026 -- reusan la MISMA logica
        // que ya existe en BI (Clientes Frios, Desviaciones, Alertas de
        // Proyectos) en vez de duplicar el SQL. Se gatean por rol igual que
        // el endpoint original de cada una (antes de esto, la campana nunca
        // las mostraba, solo se veian entrando manualmente a BI). ----------

        if (usuario.IsInRole("Administracion"))
        {
            var clientesFrios = (await _crm.ListarClientesFriosAsync(30)).ToList();
            if (clientesFrios.Count > 0)
            {
                items.Add(new NotificacionItem(
                    "ClientesFrios", "warning",
                    $"{clientesFrios.Count} cliente{(clientesFrios.Count == 1 ? "" : "s")} sin contacto reciente",
                    ResumirNombres(clientesFrios.Select(c => c.Nombre).ToList()),
                    "/crm/clientes"));
            }
        }

        if (usuario.IsInRole("Administracion") || usuario.IsInRole("Jefes"))
        {
            var desviaciones = (await _planificacion.ListarDesviacionesAsync(70)).ToList();
            if (desviaciones.Count > 0)
            {
                items.Add(new NotificacionItem(
                    "DesviacionesPlanificacion", "warning",
                    $"{desviaciones.Count} centro{(desviaciones.Count == 1 ? "" : "s")} de costo por debajo de su meta",
                    ResumirNombres(desviaciones.Select(d => d.CentroCosto).ToList()),
                    "/planificacion/demanda"));
            }

            var alertasProyectos = (await _proyectos.ListarAlertasAsync()).ToList();
            if (alertasProyectos.Count > 0)
            {
                items.Add(new NotificacionItem(
                    "AlertasProyectos", "error",
                    $"{alertasProyectos.Count} proyecto{(alertasProyectos.Count == 1 ? "" : "s")} atrasado{(alertasProyectos.Count == 1 ? "" : "s")} o con sobrecosto",
                    ResumirNombres(alertasProyectos.Select(p => p.Nombre).ToList()),
                    "/proyectos"));
            }
        }

        return new ResumenNotificaciones(items.Count, items);
    }

    private static string ResumirNombres(List<string> nombres)
    {
        const int max = 3;
        return nombres.Count <= max
            ? string.Join(", ", nombres)
            : $"{string.Join(", ", nombres.Take(max))} y {nombres.Count - max} más";
    }
}
