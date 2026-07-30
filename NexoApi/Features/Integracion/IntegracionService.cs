using System.Data;
using System.Security.Cryptography;
using System.Text;
using Dapper;
using NexoApi.Common.Data;
using NexoApi.Features.Integracion.Dtos;

namespace NexoApi.Features.Integracion;

public interface IIntegracionService
{
    Task<IEnumerable<EventoPendienteItem>> ObtenerEventosPendientesAsync(int centroCostoId);
    Task ConfirmarEventoSalienteAsync(long eventoId, int centroCostoId);
    Task RegistrarEventoEntranteAsync(RegistrarEventoEntranteRequest request, int centroCostoId);
    Task<GenerarApiKeyResponse> GenerarApiKeyAsync(GenerarApiKeyRequest request);
}

public class IntegracionService : IIntegracionService
{
    private readonly IDbConnectionFactory _db;

    public IntegracionService(IDbConnectionFactory db)
    {
        _db = db;
    }

    public async Task<IEnumerable<EventoPendienteItem>> ObtenerEventosPendientesAsync(int centroCostoId)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT e.EventoID, e.TipoEvento, e.Cantidad, e.CostoUnitario, e.FechaCreacion,
                   cc.IdentificadorClienteVisions AS CentroCostoVisions,
                   m.CodigoArticuloVisions AS ReferenciaVisions
            FROM Integracion.EventosSalientes e
            JOIN Organizacion.CentrosCosto cc ON cc.CentroCostoID = e.CentroCostoID
            JOIN Integracion.MapeoArticulos m ON m.ArticuloID = e.ArticuloID AND m.CentroCostoID = e.CentroCostoID
            WHERE e.Estado = 'PENDIENTE' AND e.CentroCostoID = @CentroCostoId";

        return await connection.QueryAsync<EventoPendienteItem>(sql, new { CentroCostoId = centroCostoId });
    }

    public async Task ConfirmarEventoSalienteAsync(long eventoId, int centroCostoId)
    {
        using var connection = _db.CreateConnection();

        // El filtro AND CentroCostoID = @CentroCostoId no es decorativo: es lo
        // que impide que el agente de un cliente pueda confirmar (o espiar)
        // eventos que pertenecen a otro cliente, aunque adivinara un EventoID.
        const string sql = @"
            UPDATE Integracion.EventosSalientes
            SET Estado = 'CONFIRMADO', FechaEnvio = SYSUTCDATETIME()
            WHERE EventoID = @EventoId AND CentroCostoID = @CentroCostoId AND Estado = 'PENDIENTE'";

        var filas = await connection.ExecuteAsync(sql, new { EventoId = eventoId, CentroCostoId = centroCostoId });

        if (filas == 0)
            throw new KeyNotFoundException("El evento no existe, no pertenece a este agente, o ya fue confirmado.");
    }

    public async Task RegistrarEventoEntranteAsync(RegistrarEventoEntranteRequest r, int centroCostoId)
    {
        using var connection = _db.CreateConnection();

        var yaExiste = await connection.ExecuteScalarAsync<int>(
            "SELECT COUNT(1) FROM Integracion.EventosEntrantes WHERE IdEventoExterno = @IdEventoExterno",
            new { r.IdEventoExterno });

        if (yaExiste > 0)
            return; // idempotente: el agente ya mando esto antes (reintento por corte de internet); no se procesa de nuevo

        const string sqlInsert = @"
            INSERT INTO Integracion.EventosEntrantes
                (IdEventoExterno, TipoEvento, CentroCostoID, CodigoArticuloVisions, Cantidad, FechaEventoOrigen)
            OUTPUT INSERTED.EventoEntranteID
            VALUES (@IdEventoExterno, @TipoEvento, @CentroCostoId, @CodigoArticuloVisions, @Cantidad, @FechaEventoOrigen)";

        var eventoEntranteId = await connection.ExecuteScalarAsync<long>(sqlInsert, new
        {
            r.IdEventoExterno,
            r.TipoEvento,
            CentroCostoId = centroCostoId,
            r.CodigoArticuloVisions,
            r.Cantidad,
            r.FechaEventoOrigen
        });

        var parametros = new DynamicParameters();
        parametros.Add("EventoEntranteID", eventoEntranteId);

        await connection.ExecuteAsync(
            "Integracion.sp_ProcesarEventoEntrante",
            parametros,
            commandType: CommandType.StoredProcedure);
    }

    public async Task<GenerarApiKeyResponse> GenerarApiKeyAsync(GenerarApiKeyRequest r)
    {
        using var connection = _db.CreateConnection();

        var apiKey = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32));
        var apiKeyHash = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(apiKey)));

        const string sql = @"
            INSERT INTO Integracion.AgentesSync (CentroCostoID, ApiKeyHash, Descripcion)
            OUTPUT INSERTED.AgenteSyncID
            VALUES (@CentroCostoID, @ApiKeyHash, @Descripcion)";

        var id = await connection.ExecuteScalarAsync<int>(sql, new { r.CentroCostoID, ApiKeyHash = apiKeyHash, r.Descripcion });

        return new GenerarApiKeyResponse(id, apiKey);
    }
}