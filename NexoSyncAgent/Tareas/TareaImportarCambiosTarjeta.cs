using Dapper;
using NexoSyncAgent.NexoApiClient;
using NexoSyncAgent.NexoApiClient.Dtos;
using NexoSyncAgent.VisionsData;

namespace NexoSyncAgent.Tareas;

// Lee NEXO_TarjetasCambios (rellenada por el trigger TR_TARJETA_NexoCambios en Visions)
// y envia los cambios de precio/nombre/marca/grupo a NEXO para mantener Catalogo.Tarjetas
// sincronizado. La API aplica el cambio solo si el timestamp de Visions es mas reciente
// que FechaModificacion en NEXO (+ 5s de margen), evitando bucles de sincronizacion.
public class TareaImportarCambiosTarjeta
{
    private readonly INexoApiClient _apiClient;
    private readonly IVisionsConnectionFactory _visionsDb;
    private readonly ILogger<TareaImportarCambiosTarjeta> _logger;

    public TareaImportarCambiosTarjeta(
        INexoApiClient apiClient, IVisionsConnectionFactory visionsDb, ILogger<TareaImportarCambiosTarjeta> logger)
    {
        _apiClient = apiClient;
        _visionsDb = visionsDb;
        _logger = logger;
    }

    public async Task EjecutarAsync(int centroCostoVisions, CancellationToken ct)
    {
        using var connection = _visionsDb.CreateConnection();

        // Tomar el cambio mas reciente por CENTROCOSTO+REFERENCIA (si hay varios pendientes).
        // Se hace JOIN a dbo.TARJETA para obtener el estado actual de Marca, Grupo, IVA y
        // Presentacion, ya que NEXO_TarjetasCambios solo guarda nombre/costo/precio.
        var cambios = (await connection.QueryAsync<CambioPendiente>(
            @"SELECT t.Id, t.CENTROCOSTO, t.REFERENCIA, t.DETALLE, t.COSTO, t.PPUBLICO, t.FechaCambio,
                     NULLIF(tar.PBODEGA,  0)                              AS PBodega,
                     NULLIF(tar.PCREDITO, 0)                              AS PCredito,
                     NULLIF(tar.UPUBLICO, 0)                              AS UPublico,
                     NULLIF(tar.UBODEGA,  0)                              AS UBodega,
                     NULLIF(tar.UCREDITO, 0)                              AS UCredito,
                     tar.MARCA         AS MarcaCodigo,
                     tar.GRUPOMENOR    AS GrupoMenorCodigo,
                     tar.PRESENTACION  AS PresentacionCodigo,
                     ISNULL(tar.IVASINO,'SI')                             AS IvaSiNo,
                     CAST(ISNULL(tar.IVAVALOR,19) AS DECIMAL(18,4))      AS IvaValor,
                     ISNULL(tar.IVADESCRIPCION,'IVA 19%')                 AS IvaDescripcion,
                     CAST(tar.VF4 AS DECIMAL(18,4))                       AS Iva2,
                     tar.UBICA4                                            AS IvaDescripcion2,
                     tp.Codigo                                             AS TipoProductoCodigo,
                     tar.EXISTENCIAS                                       AS ExistenciasActuales,
                     tar.EXISTENCIASMINIMAS                                AS ExistenciasMinimas,
                     CAST(CASE WHEN tar.REFERENCIA IS NULL THEN 1 ELSE 0 END AS BIT) AS EliminadoEnVisions
              FROM dbo.NEXO_TarjetasCambios t
              INNER JOIN (
                  SELECT CENTROCOSTO, REFERENCIA, MAX(Id) AS UltimoId
                  FROM dbo.NEXO_TarjetasCambios
                  WHERE Procesado = 0 AND CENTROCOSTO = @CC
                  GROUP BY CENTROCOSTO, REFERENCIA
              ) ult ON ult.UltimoId = t.Id
              LEFT JOIN dbo.TARJETA tar ON tar.CENTROCOSTO = t.CENTROCOSTO AND tar.REFERENCIA = t.REFERENCIA
              LEFT JOIN dbo.TIPOPRODUCTO_TIPOS tp ON tp.TipoID = COALESCE(t.VV3, tar.VV3)",
            new { CC = centroCostoVisions })).ToList();

        if (cambios.Count == 0)
            return;

        _logger.LogInformation("Encontrados {Cantidad} cambios de TARJETA en Visions para importar a NEXO", cambios.Count);

        foreach (var cambio in cambios)
        {
            try
            {
                if (cambio.EliminadoEnVisions)
                {
                    await _apiClient.InactivarArticuloDesdeVisionsAsync(cambio.REFERENCIA, ct);
                    _logger.LogInformation("Articulo {Ref} ya no existe en Visions — inactivado en NEXO", cambio.REFERENCIA);
                }
                else
                {
                    await _apiClient.SyncArticuloDesdeVisionsAsync(new SyncArticuloDesdeVisionsRequest(
                        ReferenciaVisions:  cambio.REFERENCIA,
                        CentroCostoVisions: cambio.CENTROCOSTO.ToString(),
                        Nombre:             cambio.DETALLE,
                        Costo:              cambio.COSTO,
                        PPublico:           cambio.PPUBLICO,
                        FechaCambio:        cambio.FechaCambio,
                        MarcaCodigo:        cambio.MarcaCodigo,
                        GrupoMenorCodigo:   cambio.GrupoMenorCodigo,
                        PresentacionCodigo: cambio.PresentacionCodigo,
                        IvaSiNo:            cambio.IvaSiNo ?? "SI",
                        IvaValor:           cambio.IvaValor,
                        IvaDescripcion:     cambio.IvaDescripcion,
                        Iva2:               cambio.Iva2,
                        IvaDescripcion2:    cambio.IvaDescripcion2,
                        PBodega:            cambio.PBodega,
                        PCredito:           cambio.PCredito,
                        UPublico:           cambio.UPublico,
                        UBodega:            cambio.UBodega,
                        UCredito:           cambio.UCredito,
                        TipoProductoCodigo:  cambio.TipoProductoCodigo,
                        ExistenciasActuales: cambio.ExistenciasActuales,
                        ExistenciasMinimas:  cambio.ExistenciasMinimas), ct);
                    _logger.LogInformation("Cambio de TARJETA ({Ref}) sincronizado a NEXO", cambio.REFERENCIA);
                }

                // Marcar todos los registros de esta referencia como procesados.
                await connection.ExecuteAsync(
                    "UPDATE dbo.NEXO_TarjetasCambios SET Procesado = 1 WHERE CENTROCOSTO = @CC AND REFERENCIA = @Ref AND Procesado = 0",
                    new { CC = cambio.CENTROCOSTO, Ref = cambio.REFERENCIA });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "No se pudo sincronizar cambio de TARJETA ({Ref}) a NEXO", cambio.REFERENCIA);
            }
        }
    }

    private record CambioPendiente(
        long Id, int CENTROCOSTO, string REFERENCIA,
        string? DETALLE, decimal? COSTO, decimal? PPUBLICO, DateTime FechaCambio,
        decimal? PBodega, decimal? PCredito,
        decimal? UPublico, decimal? UBodega, decimal? UCredito,
        string? MarcaCodigo, string? GrupoMenorCodigo, string? PresentacionCodigo,
        string? IvaSiNo, decimal? IvaValor, string? IvaDescripcion,
        decimal? Iva2, string? IvaDescripcion2,
        string? TipoProductoCodigo = null,
        decimal? ExistenciasActuales = null,
        decimal? ExistenciasMinimas = null,
        bool EliminadoEnVisions = false);
}
