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
    Task LiberarAsync(int ordenProduccionId, int usuarioId);
    Task IniciarAsync(int ordenProduccionId, int usuarioId);
    Task<(decimal CostoUnitarioReal, int LoteProductoTerminadoID)> CerrarAsync(int ordenProduccionId, CerrarOrdenProduccionRequest request, int usuarioId);
    Task AjustarConsumoAsync(long consumoId, AjustarConsumoRealRequest request);
    Task<IEnumerable<TipoProduccionItem>> ListarTiposProduccionAsync();
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

    public async Task AjustarConsumoAsync(long consumoId, AjustarConsumoRealRequest r)
    {
        using var connection = _db.CreateConnection();
        var parametros = new DynamicParameters();
        parametros.Add("ConsumoID", consumoId);
        parametros.Add("CantidadReal", r.CantidadReal);
        parametros.Add("MotivoExcesoID", r.MotivoExcesoID);
        parametros.Add("Observacion", r.Observacion);

        await connection.ExecuteAsync(
            "Produccion.sp_AjustarConsumoReal", parametros, commandType: CommandType.StoredProcedure);
    }

    

    public async Task<IEnumerable<TipoProduccionItem>> ListarTiposProduccionAsync()
    {
        using var connection = _db.CreateConnection();
        return await connection.QueryAsync<TipoProduccionItem>(
            "SELECT TipoProduccionID, Codigo, Nombre FROM Produccion.TiposProduccion ORDER BY TipoProduccionID");
    }
}