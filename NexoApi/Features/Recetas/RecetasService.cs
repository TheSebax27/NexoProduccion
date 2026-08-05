using Dapper;
using NexoApi.Common.Data;
using NexoApi.Features.Recetas.Dtos;

namespace NexoApi.Features.Recetas;

public interface IRecetasService
{
    Task<int> CrearAsync(CrearRecetaRequest request);
    Task<int> CrearNuevaVersionAsync(int recetaBaseId, CrearNuevaVersionRequest request);
    Task<IEnumerable<RecetaResumen>> ListarAsync(int? productoTerminadoId, bool soloActivas);
    Task<IEnumerable<RecetaDetalleItem>> ObtenerDetalleAsync(int recetaId);
    Task DesactivarAsync(int recetaId);
}

public class RecetasService : IRecetasService
{
    private readonly IDbConnectionFactory _db;

    public RecetasService(IDbConnectionFactory db)
    {
        _db = db;
    }

    public async Task<int> CrearAsync(CrearRecetaRequest r)
    {
        using var connection = _db.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();

        try
        {
            const string sqlHeader = @"
                INSERT INTO Produccion.RecetaBOM
                    (ProductoTerminadoID, NombreReceta, Version, CantidadRendimientoBase, UnidadRendimientoID)
                OUTPUT INSERTED.RecetaID
                VALUES (@ProductoTerminadoID, @NombreReceta, 1, @CantidadRendimientoBase, @UnidadRendimientoID)";

            var recetaId = await connection.ExecuteScalarAsync<int>(sqlHeader, new
            {
                r.ProductoTerminadoID,
                r.NombreReceta,
                r.CantidadRendimientoBase,
                r.UnidadRendimientoID
            }, transaction);

            await InsertarDetalleAsync(connection, transaction, recetaId, r.Detalle);

            transaction.Commit();
            return recetaId;
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    private record RecetaBaseInfo(int ProductoTerminadoID, int VersionActual);

    public async Task<int> CrearNuevaVersionAsync(int recetaBaseId, CrearNuevaVersionRequest r)
    {
        using var connection = _db.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();

        try
        {
            // Dapper no soporta mapear una fila directo a ValueTuple -- con
            // (int,int) esto fallaba con 500 en TODA llamada a este endpoint.
            var baseInfo = await connection.QuerySingleOrDefaultAsync<RecetaBaseInfo>(
                "SELECT ProductoTerminadoID, Version AS VersionActual FROM Produccion.RecetaBOM WHERE RecetaID = @RecetaBaseId",
                new { RecetaBaseId = recetaBaseId }, transaction);

            if (baseInfo is null)
                throw new KeyNotFoundException($"No existe la receta {recetaBaseId} para versionar.");

            const string sqlHeader = @"
                INSERT INTO Produccion.RecetaBOM
                    (ProductoTerminadoID, NombreReceta, Version, CantidadRendimientoBase, UnidadRendimientoID)
                OUTPUT INSERTED.RecetaID
                VALUES (@ProductoTerminadoID, @NombreReceta, @NuevaVersion, @CantidadRendimientoBase, @UnidadRendimientoID)";

            var nuevaRecetaId = await connection.ExecuteScalarAsync<int>(sqlHeader, new
            {
                baseInfo.ProductoTerminadoID,
                r.NombreReceta,
                NuevaVersion = baseInfo.VersionActual + 1,
                r.CantidadRendimientoBase,
                r.UnidadRendimientoID
            }, transaction);

            await InsertarDetalleAsync(connection, transaction, nuevaRecetaId, r.Detalle);

            await connection.ExecuteAsync(
                "UPDATE Produccion.RecetaBOM SET Estado = 0 WHERE RecetaID = @RecetaBaseId",
                new { RecetaBaseId = recetaBaseId }, transaction);

            transaction.Commit();
            return nuevaRecetaId;
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    private static async Task InsertarDetalleAsync(
        System.Data.IDbConnection connection, System.Data.IDbTransaction transaction,
        int recetaId, List<DetalleRecetaRequest> detalle)
    {
        const string sqlDetalle = @"
            INSERT INTO Produccion.RecetaBOM_Detalle
                (RecetaID, InsumoID, CantidadRequerida, UnidadID, PorcentajeMermaEstandar, CentroTrabajoID, Orden)
            VALUES
                (@RecetaID, @InsumoID, @CantidadRequerida, @UnidadID, @PorcentajeMermaEstandar, @CentroTrabajoID, @Orden)";

        foreach (var linea in detalle)
        {
            await connection.ExecuteAsync(sqlDetalle, new
            {
                RecetaID = recetaId,
                linea.InsumoID,
                linea.CantidadRequerida,
                linea.UnidadID,
                linea.PorcentajeMermaEstandar,
                linea.CentroTrabajoID,
                linea.Orden
            }, transaction);
        }
    }

    public async Task<IEnumerable<RecetaResumen>> ListarAsync(int? productoTerminadoId, bool soloActivas)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT r.RecetaID, a.Nombre AS ProductoTerminado, r.NombreReceta, r.Version,
                   r.CantidadRendimientoBase, u.Abreviatura AS UnidadRendimiento, r.Estado
            FROM Produccion.RecetaBOM r
            JOIN Catalogo.Articulos a ON a.ArticuloID = r.ProductoTerminadoID
            JOIN Catalogo.UnidadesMedida u ON u.UnidadID = r.UnidadRendimientoID
            WHERE (@ProductoTerminadoId IS NULL OR r.ProductoTerminadoID = @ProductoTerminadoId)
              AND (@SoloActivas = 0 OR r.Estado = 1)
            ORDER BY a.Nombre, r.Version DESC";

        return await connection.QueryAsync<RecetaResumen>(sql, new
        {
            ProductoTerminadoId = productoTerminadoId,
            SoloActivas = soloActivas
        });
    }

    public async Task<IEnumerable<RecetaDetalleItem>> ObtenerDetalleAsync(int recetaId)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT d.RecetaDetalleID, d.InsumoID, a.Nombre AS Insumo, d.CantidadRequerida,
                   u.Abreviatura AS Unidad, d.PorcentajeMermaEstandar, d.CentroTrabajoID, d.Orden
            FROM Produccion.RecetaBOM_Detalle d
            JOIN Catalogo.Articulos a ON a.ArticuloID = d.InsumoID
            JOIN Catalogo.UnidadesMedida u ON u.UnidadID = d.UnidadID
            WHERE d.RecetaID = @RecetaId
            ORDER BY d.Orden";

        return await connection.QueryAsync<RecetaDetalleItem>(sql, new { RecetaId = recetaId });
    }

    // No se borra fisicamente: las ordenes de produccion ya ejecutadas quedan
    // enlazadas a esta receta por RecetaID, asi que se desactiva (igual que
    // Bodegas, Articulos, Clientes, Proveedores en este mismo sistema) para no
    // romper ese historial.
    public async Task DesactivarAsync(int recetaId)
    {
        using var connection = _db.CreateConnection();

        var filas = await connection.ExecuteAsync(
            "UPDATE Produccion.RecetaBOM SET Estado = 0 WHERE RecetaID = @RecetaId",
            new { RecetaId = recetaId });

        if (filas == 0)
            throw new KeyNotFoundException($"No existe la receta {recetaId}.");
    }
}