using System.Data;
using Dapper;
using NexoApi.Common.Data;
using NexoApi.Features.Produccion.Dtos;

namespace NexoApi.Features.Produccion;

public interface IOrdenesProduccionService
{
    Task<int> CrearAsync(CrearOrdenProduccionRequest request, int usuarioCreaId);
    Task<IEnumerable<OrdenProduccionResumen>> ListarAsync(int? centroCostoId, string? estado);
    Task<OrdenProduccionResumen?> ObtenerAsync(int ordenProduccionId);
    Task<OrdenProduccionDetalleEdicion?> ObtenerParaEdicionAsync(int ordenProduccionId);
    Task ActualizarAsync(int ordenProduccionId, ActualizarOrdenProduccionRequest request);
    Task CancelarAsync(int ordenProduccionId);
    Task LiberarAsync(int ordenProduccionId, int usuarioId);
    Task IniciarAsync(int ordenProduccionId, int usuarioId);
    Task<(decimal CostoUnitarioReal, int LoteProductoTerminadoID)> CerrarAsync(int ordenProduccionId, CerrarOrdenProduccionRequest request, int usuarioId);
    Task AjustarConsumoAsync(long consumoId, AjustarConsumoRealRequest request, int usuarioId);
    Task<IEnumerable<TipoProduccionItem>> ListarTiposProduccionAsync();
    Task<IEnumerable<ConsumoOpItem>> ListarConsumosAsync(int ordenProduccionId);
    Task<IEnumerable<MotivoExcesoItem>> ListarMotivosExcesoAsync();
}

public class OrdenesProduccionService : IOrdenesProduccionService
{
    private record CerrarResultado(string Resultado, decimal CostoUnitarioReal, int LoteProductoTerminadoID);

    private readonly IDbConnectionFactory _db;

    public OrdenesProduccionService(IDbConnectionFactory db)
    {
        _db = db;
    }

    public async Task<int> CrearAsync(CrearOrdenProduccionRequest r, int usuarioCreaId)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            INSERT INTO Produccion.OrdenesProduccion
                (CodigoOP, TipoProduccionID, EstadoOPID, ProductoTerminadoID, RecetaID, CantidadProgramada,
                 ClienteID, CentroCostoDestinoID, BodegaOrigenMPID, BodegaDestinoPTID, CentroTrabajoID,
                 FechaPlanificada, UsuarioCreaID, Observaciones)
            OUTPUT INSERTED.OrdenProduccionID
            VALUES
                (@CodigoOP, @TipoProduccionID,
                 (SELECT EstadoOPID FROM Produccion.EstadosOP WHERE Nombre = 'Planificada'),
                 @ProductoTerminadoID, @RecetaID, @CantidadProgramada,
                 @ClienteID, @CentroCostoDestinoID, @BodegaOrigenMPID, @BodegaDestinoPTID, @CentroTrabajoID,
                 @FechaPlanificada, @UsuarioCreaID, @Observaciones)";

        return await connection.ExecuteScalarAsync<int>(sql, new
        {
            r.CodigoOP,
            r.TipoProduccionID,
            r.ProductoTerminadoID,
            r.RecetaID,
            r.CantidadProgramada,
            r.ClienteID,
            r.CentroCostoDestinoID,
            r.BodegaOrigenMPID,
            r.BodegaDestinoPTID,
            r.CentroTrabajoID,
            r.FechaPlanificada,
            UsuarioCreaID = usuarioCreaId,
            r.Observaciones
        });
    }

    public async Task<IEnumerable<OrdenProduccionResumen>> ListarAsync(int? centroCostoId, string? estado)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT op.OrdenProduccionID, op.CodigoOP, e.Nombre AS Estado, a.Nombre AS Producto,
                   cc.Nombre AS CentroCosto, op.CantidadProgramada, op.CantidadProducidaReal,
                   op.FechaPlanificada, op.FechaInicio, op.FechaFin, op.CostoUnitarioReal
            FROM Produccion.OrdenesProduccion op
            JOIN Produccion.EstadosOP e ON e.EstadoOPID = op.EstadoOPID
            JOIN Catalogo.Articulos a ON a.ArticuloID = op.ProductoTerminadoID
            JOIN Organizacion.CentrosCosto cc ON cc.CentroCostoID = op.CentroCostoDestinoID
            WHERE (@CentroCostoId IS NULL OR op.CentroCostoDestinoID = @CentroCostoId)
              AND (@Estado IS NULL OR e.Nombre = @Estado)
            ORDER BY op.FechaCreacion DESC";

        return await connection.QueryAsync<OrdenProduccionResumen>(sql, new { CentroCostoId = centroCostoId, Estado = estado });
    }

    public async Task<OrdenProduccionResumen?> ObtenerAsync(int ordenProduccionId)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT op.OrdenProduccionID, op.CodigoOP, e.Nombre AS Estado, a.Nombre AS Producto,
                   cc.Nombre AS CentroCosto, op.CantidadProgramada, op.CantidadProducidaReal,
                   op.FechaPlanificada, op.FechaInicio, op.FechaFin, op.CostoUnitarioReal
            FROM Produccion.OrdenesProduccion op
            JOIN Produccion.EstadosOP e ON e.EstadoOPID = op.EstadoOPID
            JOIN Catalogo.Articulos a ON a.ArticuloID = op.ProductoTerminadoID
            JOIN Organizacion.CentrosCosto cc ON cc.CentroCostoID = op.CentroCostoDestinoID
            WHERE op.OrdenProduccionID = @OrdenProduccionId";

        return await connection.QuerySingleOrDefaultAsync<OrdenProduccionResumen>(sql, new { OrdenProduccionId = ordenProduccionId });
    }

    public async Task<OrdenProduccionDetalleEdicion?> ObtenerParaEdicionAsync(int ordenProduccionId)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT op.OrdenProduccionID, op.CodigoOP, e.Nombre AS Estado,
                   op.TipoProduccionID, op.ProductoTerminadoID, op.RecetaID,
                   op.CantidadProgramada, op.ClienteID, op.CentroCostoDestinoID,
                   op.BodegaOrigenMPID, op.BodegaDestinoPTID, op.CentroTrabajoID,
                   op.FechaPlanificada, op.Observaciones
            FROM Produccion.OrdenesProduccion op
            JOIN Produccion.EstadosOP e ON e.EstadoOPID = op.EstadoOPID
            WHERE op.OrdenProduccionID = @OrdenProduccionId";

        return await connection.QuerySingleOrDefaultAsync<OrdenProduccionDetalleEdicion>(
            sql, new { OrdenProduccionId = ordenProduccionId });
    }

    public async Task ActualizarAsync(int ordenProduccionId, ActualizarOrdenProduccionRequest r)
    {
        using var connection = _db.CreateConnection();
        var parametros = new DynamicParameters();
        parametros.Add("OrdenProduccionID", ordenProduccionId);
        parametros.Add("TipoProduccionID", r.TipoProduccionID);
        parametros.Add("ProductoTerminadoID", r.ProductoTerminadoID);
        parametros.Add("RecetaID", r.RecetaID);
        parametros.Add("CantidadProgramada", r.CantidadProgramada);
        parametros.Add("ClienteID", r.ClienteID);
        parametros.Add("CentroCostoDestinoID", r.CentroCostoDestinoID);
        parametros.Add("BodegaOrigenMPID", r.BodegaOrigenMPID);
        parametros.Add("BodegaDestinoPTID", r.BodegaDestinoPTID);
        parametros.Add("CentroTrabajoID", r.CentroTrabajoID);
        parametros.Add("FechaPlanificada", r.FechaPlanificada);
        parametros.Add("Observaciones", r.Observaciones);

        await connection.ExecuteAsync(
            "Produccion.sp_ActualizarOrdenProduccion", parametros, commandType: CommandType.StoredProcedure);
    }

    public async Task CancelarAsync(int ordenProduccionId)
    {
        using var connection = _db.CreateConnection();
        var parametros = new DynamicParameters();
        parametros.Add("OrdenProduccionID", ordenProduccionId);

        await connection.ExecuteAsync(
            "Produccion.sp_CancelarOrdenProduccion", parametros, commandType: CommandType.StoredProcedure);
    }

    public async Task LiberarAsync(int ordenProduccionId, int usuarioId)
    {
        using var connection = _db.CreateConnection();
        var parametros = new DynamicParameters();
        parametros.Add("OrdenProduccionID", ordenProduccionId);
        parametros.Add("UsuarioID", usuarioId);

        await connection.ExecuteAsync(
            "Produccion.sp_LiberarOrdenProduccion", parametros, commandType: CommandType.StoredProcedure);
    }

    public async Task IniciarAsync(int ordenProduccionId, int usuarioId)
    {
        using var connection = _db.CreateConnection();
        var parametros = new DynamicParameters();
        parametros.Add("OrdenProduccionID", ordenProduccionId);
        parametros.Add("UsuarioID", usuarioId);

        await connection.ExecuteAsync(
            "Produccion.sp_IniciarOrdenProduccion", parametros, commandType: CommandType.StoredProcedure);
    }

    public async Task<(decimal, int)> CerrarAsync(int ordenProduccionId, CerrarOrdenProduccionRequest r, int usuarioId)
    {
        using var connection = _db.CreateConnection();
        var parametros = new DynamicParameters();
        parametros.Add("OrdenProduccionID", ordenProduccionId);
        parametros.Add("CantidadProducidaReal", r.CantidadProducidaReal);
        parametros.Add("HorasManoObra", r.HorasManoObra);
        parametros.Add("HorasCIF", r.HorasCIF);
        parametros.Add("NumeroLotePT", r.NumeroLotePT);
        parametros.Add("FechaVencimientoPT", r.FechaVencimientoPT);
        parametros.Add("UsuarioID", usuarioId);

        var resultado = await connection.QuerySingleAsync<CerrarResultado>(
            "Produccion.sp_CerrarOrdenProduccion", parametros, commandType: CommandType.StoredProcedure);

        return (resultado.CostoUnitarioReal, resultado.LoteProductoTerminadoID);
    }

    public async Task AjustarConsumoAsync(long consumoId, AjustarConsumoRealRequest r, int usuarioId)
    {
        using var connection = _db.CreateConnection();
        var parametros = new DynamicParameters();
        parametros.Add("ConsumoID", consumoId);
        parametros.Add("CantidadReal", r.CantidadReal);
        parametros.Add("MotivoExcesoID", r.MotivoExcesoID);
        parametros.Add("Observacion", r.Observacion);
        parametros.Add("UsuarioID", usuarioId);

        await connection.ExecuteAsync(
            "Produccion.sp_AjustarConsumoReal", parametros, commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<ConsumoOpItem>> ListarConsumosAsync(int ordenProduccionId)
    {
        using var connection = _db.CreateConnection();
        const string sql = @"
            SELECT c.ConsumoID, c.ArticuloID, a.Nombre AS Articulo,
                   c.CantidadTeorica, c.CantidadReal,
                   me.Nombre AS MotivoExceso, c.Observacion
            FROM Produccion.OrdenesProduccionConsumo c
            JOIN Catalogo.Articulos a ON a.ArticuloID = c.ArticuloID
            LEFT JOIN Produccion.MotivosExcesoConsumo me ON me.MotivoExcesoID = c.MotivoExcesoID
            WHERE c.OrdenProduccionID = @OrdenProduccionId
            ORDER BY c.ConsumoID";
        return await connection.QueryAsync<ConsumoOpItem>(sql, new { OrdenProduccionId = ordenProduccionId });
    }

    public async Task<IEnumerable<MotivoExcesoItem>> ListarMotivosExcesoAsync()
    {
        using var connection = _db.CreateConnection();
        return await connection.QueryAsync<MotivoExcesoItem>(
            "SELECT MotivoExcesoID, Nombre FROM Produccion.MotivosExcesoConsumo ORDER BY Nombre");
    }

    public async Task<IEnumerable<TipoProduccionItem>> ListarTiposProduccionAsync()
    {
        using var connection = _db.CreateConnection();
        return await connection.QueryAsync<TipoProduccionItem>(
            "SELECT TipoProduccionID, Codigo, Nombre FROM Produccion.TiposProduccion ORDER BY TipoProduccionID");
    }
}