using Dapper;
using NexoApi.Common.Data;
using NexoApi.Features.Notificaciones.Dtos;

namespace NexoApi.Features.Notificaciones;

public interface INotificacionesService
{
    Task<ResumenNotificaciones> ObtenerResumenAsync();
}

// Notificaciones "agregadas por categoria" a proposito -- no una fila por
// cada articulo con bajo stock (seria una lista larga y molesta), sino un
// resumen con conteo por categoria (Sin Stock, Bajo Stock, Produccion en
// Proceso) y un link a la pantalla correspondiente para ver el detalle.
public class NotificacionesService : INotificacionesService
{
    private readonly IDbConnectionFactory _db;

    public NotificacionesService(IDbConnectionFactory db)
    {
        _db = db;
    }

    public async Task<ResumenNotificaciones> ObtenerResumenAsync()
    {
        using var connection = _db.CreateConnection();
        var items = new List<NotificacionItem>();

        var sinStock = (await connection.QueryAsync<string>(
            "SELECT DISTINCT Articulo FROM Inventario.vw_StockConsolidado WHERE CantidadActual = 0 ORDER BY Articulo"))
            .ToList();
        if (sinStock.Count > 0)
        {
            items.Add(new NotificacionItem(
                "SinStock", "error",
                $"{sinStock.Count} artículo{(sinStock.Count == 1 ? "" : "s")} sin stock",
                ResumirNombres(sinStock),
                "/inventario/stock"));
        }

        var bajoStock = (await connection.QueryAsync<string>(
            "SELECT DISTINCT Articulo FROM Inventario.vw_StockConsolidado WHERE CantidadActual > 0 AND RequierePedido = 1 ORDER BY Articulo"))
            .ToList();
        if (bajoStock.Count > 0)
        {
            items.Add(new NotificacionItem(
                "BajoStock", "warning",
                $"{bajoStock.Count} artículo{(bajoStock.Count == 1 ? "" : "s")} bajo el punto de reorden",
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
