using Dapper;
using NexoSyncAgent.NexoApiClient;
using NexoSyncAgent.NexoApiClient.Dtos;
using NexoSyncAgent.VisionsData;

namespace NexoSyncAgent.Tareas;

// Recorre dbo.TARJETA de Visions e inserta en NEXO_TarjetasCambios los articulos
// que aun no han sido procesados, para que TareaImportarCambiosTarjeta los cree
// en NEXO via SyncArticuloDesdeVisionsAsync (que ahora auto-crea cuando no existe mapeo).
// Se ejecuta en lotes de 500 por ciclo para no saturar la API.
public class TareaDetectarArticulosFaltantes
{
    private readonly INexoApiClient _apiClient;
    private readonly IVisionsConnectionFactory _visionsDb;
    private readonly ILogger<TareaDetectarArticulosFaltantes> _logger;
    private const int LotePorCiclo = 500;

    public TareaDetectarArticulosFaltantes(
        INexoApiClient apiClient, IVisionsConnectionFactory visionsDb,
        ILogger<TareaDetectarArticulosFaltantes> logger)
    {
        _apiClient = apiClient;
        _visionsDb = visionsDb;
        _logger = logger;
    }

    public async Task EjecutarAsync(int centroCostoVisions, CancellationToken ct)
    {
        using var connection = _visionsDb.CreateConnection();

        // Tomar articulos de TARJETA que no tienen ninguna entrada en NEXO_TarjetasCambios
        // (pendiente o procesada) — solo los que nunca han sido enviados a NEXO.
        // Se incluyen Marca, Grupo, Presentacion e IVA para crear el articulo con datos completos.
        var articulos = (await connection.QueryAsync<ArticuloVisions>(@"
            SELECT TOP (@Lote)
                t.REFERENCIA, t.DETALLE, t.COSTO, t.PPUBLICO,
                NULLIF(t.PBODEGA,  0)                          AS PBodega,
                NULLIF(t.PCREDITO, 0)                          AS PCredito,
                NULLIF(t.UPUBLICO, 0)                          AS UPublico,
                NULLIF(t.UBODEGA,  0)                          AS UBodega,
                NULLIF(t.UCREDITO, 0)                          AS UCredito,
                t.MARCA         AS MarcaCodigo,
                t.GRUPOMENOR    AS GrupoMenorCodigo,
                t.PRESENTACION  AS PresentacionCodigo,
                ISNULL(t.IVASINO, 'SI')                        AS IvaSiNo,
                CAST(ISNULL(t.IVAVALOR, 19) AS DECIMAL(18,4)) AS IvaValor,
                ISNULL(t.IVADESCRIPCION, 'IVA 19%')            AS IvaDescripcion,
                CAST(t.VF4 AS DECIMAL(18,4))                   AS Iva2,
                t.UBICA4                                        AS IvaDescripcion2,
                tp.Codigo                                       AS TipoProductoCodigo,
                t.EXISTENCIAS                                   AS ExistenciasActuales,
                t.EXISTENCIASMINIMAS                            AS ExistenciasMinimas,
                NULLIF(t.FRACCIONES, 0)                         AS Fracciones
            FROM dbo.TARJETA t
            LEFT JOIN dbo.TIPOPRODUCTO_TIPOS tp ON tp.TipoID = t.VV3
            WHERE t.CENTROCOSTO = @CC
              AND t.REFERENCIA IS NOT NULL AND t.REFERENCIA <> ''
              AND NOT EXISTS (
                  SELECT 1 FROM dbo.NEXO_TarjetasCambios c
                  WHERE c.CENTROCOSTO = t.CENTROCOSTO AND c.REFERENCIA = t.REFERENCIA
              )",
            new { CC = centroCostoVisions, Lote = LotePorCiclo })).ToList();

        if (articulos.Count == 0)
            return;

        _logger.LogInformation(
            "TareaDetectarArticulosFaltantes: {N} articulos de TARJETA sin entrada en NEXO — sincronizando...",
            articulos.Count);

        foreach (var a in articulos)
        {
            if (ct.IsCancellationRequested) break;
            try
            {
                await _apiClient.SyncArticuloDesdeVisionsAsync(new SyncArticuloDesdeVisionsRequest(
                    ReferenciaVisions:    a.REFERENCIA,
                    CentroCostoVisions:   centroCostoVisions.ToString(),
                    Nombre:               a.DETALLE,
                    Costo:                a.COSTO,
                    PPublico:             a.PPUBLICO,
                    FechaCambio:          DateTime.Now,
                    MarcaCodigo:          a.MarcaCodigo,
                    GrupoMenorCodigo:     a.GrupoMenorCodigo,
                    PresentacionCodigo:   a.PresentacionCodigo,
                    IvaSiNo:              a.IvaSiNo ?? "SI",
                    IvaValor:             a.IvaValor,
                    IvaDescripcion:       a.IvaDescripcion,
                    Iva2:                 a.Iva2,
                    IvaDescripcion2:      a.IvaDescripcion2,
                    PBodega:              a.PBodega,
                    PCredito:             a.PCredito,
                    UPublico:             a.UPublico,
                    UBodega:              a.UBodega,
                    UCredito:             a.UCredito,
                    TipoProductoCodigo:   a.TipoProductoCodigo,
                    ExistenciasActuales:  a.ExistenciasActuales,
                    ExistenciasMinimas:   a.ExistenciasMinimas,
                    Fracciones:           a.Fracciones), ct);

                // Marcar en NEXO_TarjetasCambios como procesado para no repetir.
                await connection.ExecuteAsync(@"
                    IF NOT EXISTS (SELECT 1 FROM dbo.NEXO_TarjetasCambios
                                   WHERE CENTROCOSTO = @CC AND REFERENCIA = @Ref)
                    INSERT INTO dbo.NEXO_TarjetasCambios
                        (CENTROCOSTO, REFERENCIA, DETALLE, COSTO, PPUBLICO, FechaCambio, Procesado)
                    VALUES (@CC, @Ref, @Detalle, @Costo, @PPub, GETDATE(), 1)",
                    new { CC = centroCostoVisions, Ref = a.REFERENCIA, Detalle = a.DETALLE ?? "", Costo = a.COSTO ?? 0m, PPub = a.PPUBLICO ?? 0m });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al sincronizar articulo faltante {Ref}", a.REFERENCIA);
            }
        }

        _logger.LogInformation("TareaDetectarArticulosFaltantes: lote completado ({N} articulos)", articulos.Count);
    }

    private record ArticuloVisions(
        string REFERENCIA, string? DETALLE, decimal? COSTO, decimal? PPUBLICO,
        decimal? PBodega, decimal? PCredito,
        decimal? UPublico, decimal? UBodega, decimal? UCredito,
        string? MarcaCodigo, string? GrupoMenorCodigo, string? PresentacionCodigo,
        string? IvaSiNo, decimal? IvaValor, string? IvaDescripcion,
        decimal? Iva2, string? IvaDescripcion2,
        string? TipoProductoCodigo = null,
        decimal? ExistenciasActuales = null,
        decimal? ExistenciasMinimas = null,
        decimal? Fracciones = null);
}
