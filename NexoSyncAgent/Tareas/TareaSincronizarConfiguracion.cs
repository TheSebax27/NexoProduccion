using Dapper;
using NexoSyncAgent.NexoApiClient;
using NexoSyncAgent.VisionsData;

namespace NexoSyncAgent.Tareas;

// Corre primero en cada ronda (ver Worker.cs): trae de NEXO la configuracion
// que dejo el Administrador (activo, prefijos de tipos de documento de venta)
// y la aplica en dbo.NEXO_ConfiguracionSync de Visions. Con esto, esos valores
// solo se pueden cambiar desde NEXO Web -- nadie mas los toca directo por SQL
// contra la base de Visions.
public class TareaSincronizarConfiguracion
{
    private readonly INexoApiClient _apiClient;
    private readonly IVisionsConnectionFactory _visionsDb;
    private readonly ILogger<TareaSincronizarConfiguracion> _logger;

    public TareaSincronizarConfiguracion(
        INexoApiClient apiClient, IVisionsConnectionFactory visionsDb, ILogger<TareaSincronizarConfiguracion> logger)
    {
        _apiClient = apiClient;
        _visionsDb = visionsDb;
        _logger = logger;
    }

    // Devuelve el codigo CENTROCOSTO de Visions que le corresponde a este agente
    // (segun su propia API Key), para que Worker.cs se lo pase a las demas tareas
    // y cada una filtre SOLO por esa sucursal -- asi, si un mismo Visions
    // comparte varias sucursales (varios CENTROCOSTO en una sola base) y cada
    // una corre su propio agente/API Key, no se cruzan ventas entre sucursales.
    // Devuelve null si el Administrador todavia no configuro el codigo en NEXO
    // Web (Catalogo > Centros de Costo) -- en ese caso no hay nada seguro que
    // sincronizar todavia.
    public async Task<int?> EjecutarAsync(CancellationToken ct)
    {
        var configuracion = await _apiClient.ObtenerConfiguracionAsync(ct);

        if (configuracion.CentroCostoVisions is null)
        {
            _logger.LogWarning(
                "El Centro de Costo de este agente todavia no tiene configurado el codigo CENTROCOSTO de Visions en NEXO Web (Catalogo > Centros de Costo). No se sincroniza nada en esta ronda.");
            return null;
        }

        using var connection = _visionsDb.CreateConnection();

        const string sql = @"
            MERGE dbo.NEXO_ConfiguracionSync AS destino
            USING (SELECT @CENTROCOSTO AS CENTROCOSTO) AS origen
            ON destino.CENTROCOSTO = origen.CENTROCOSTO
            WHEN MATCHED THEN UPDATE SET
                Activo = @Activo, TiposDocumentoVenta = @TiposDocumentoVenta
            WHEN NOT MATCHED THEN
                INSERT (CENTROCOSTO, Activo, TiposDocumentoVenta)
                VALUES (@CENTROCOSTO, @Activo, @TiposDocumentoVenta);";

        await connection.ExecuteAsync(sql, new
        {
            CENTROCOSTO = configuracion.CentroCostoVisions.Value,
            configuracion.Activo,
            TiposDocumentoVenta = configuracion.PrefijosDocumentoVenta
        });

        _logger.LogInformation(
            "Configuracion sincronizada para CENTROCOSTO {CentroCosto}: Activo={Activo}, Prefijos={Prefijos}",
            configuracion.CentroCostoVisions, configuracion.Activo, configuracion.PrefijosDocumentoVenta ?? "(ninguno)");

        return configuracion.CentroCostoVisions;
    }
}
