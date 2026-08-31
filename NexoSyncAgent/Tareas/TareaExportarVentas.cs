using Dapper;
using NexoSyncAgent.NexoApiClient;
using NexoSyncAgent.NexoApiClient.Dtos;
using NexoSyncAgent.VisionsData;

namespace NexoSyncAgent.Tareas;

public class TareaExportarVentas
{
    // DetalleTarjeta/CostoTarjeta/PPublicoTarjeta: lo que ya tiene Visions para
    // esa REFERENCIA en dbo.TARJETA -- viajan como sugerencia por si NEXO no
    // tiene mapeo para este articulo todavia.
    // NIT/Cliente: datos del comprador para que NEXO cree el cliente si no existe.
    // El orden de parámetros debe coincidir exactamente con el orden de columnas del SELECT.
    // Dapper mapea records por posición, no por nombre.
    private record VentaPendiente(
        short CENTROCOSTO, string TIPDOC, string NRODOC, decimal ORDEN, string REFERENCIA, decimal CANTIDAD, DateTime FECDOC,
        string? DetalleTarjeta, decimal? CostoTarjeta, decimal? PPublicoTarjeta,
        string? MarcaCodigo, string? IvaSiNo, decimal? IvaValor, string? IvaDescripcion,
        decimal? Iva2, string? IvaDescripcion2,
        string? GrupoMenorCodigo, string? PresentacionCodigo, string? TipoProductoCodigo,
        decimal? PBodega, decimal? PCredito, decimal? UPublico, decimal? UBodega, decimal? UCredito,
        decimal? ExistenciasActuales, decimal? ExistenciasMinimas,
        string? NIT, string? CLIENTE,
        string? ClienteTipoTercero,
        string? ClienteNombre1, string? ClienteNombre2,
        string? ClienteApellido1, string? ClienteApellido2,
        string? ClienteEmpresa,
        string? ClienteTelefono, string? ClienteDireccion,
        string? ClienteCiudad, string? ClienteDepartamento,
        string? ClienteCodigoMuni, string? ClienteCodigoDept);

    private readonly INexoApiClient _apiClient;
    private readonly IVisionsConnectionFactory _visionsDb;
    private readonly ILogger<TareaExportarVentas> _logger;

    public TareaExportarVentas(
        INexoApiClient apiClient, IVisionsConnectionFactory visionsDb, ILogger<TareaExportarVentas> logger)
    {
        _apiClient = apiClient;
        _visionsDb = visionsDb;
        _logger = logger;
    }

    // centroCostoVisions: el codigo CENTROCOSTO que le corresponde a ESTE agente
    // (ver TareaSincronizarConfiguracion). Se filtra explicito por el, aunque la
    // base de Visions sea compartida entre varias sucursales -- asi cada agente
    // (cada API Key) solo procesa y reporta las ventas de SU propia sucursal, sin
    // cruzarse con las de otras que compartan la misma base de datos de Visions.
    public async Task EjecutarAsync(int centroCostoVisions, CancellationToken ct, DateTime? fechaInicioSyncVentas = null)
    {
        using var connection = _visionsDb.CreateConnection();

        const string sqlVentasNuevas = @"
            SELECT m.CENTROCOSTO, m.TIPDOC, m.NRODOC, m.ORDEN, m.REFERENCIA,
                   -- Visions separa unidades sueltas (CANTIDAD) y cajas (CANTIDADCAJA).
                   -- Para ventas por caja, CANTIDAD=0 y CANTIDADCAJA=1; hay que sumarlas.
                   CAST(m.CANTIDAD + (m.CANTIDADCAJA * ISNULL(NULLIF(t.FRACCIONES, 0), 1)) AS DECIMAL(18,4)) AS CANTIDAD,
                   m.FECDOC,
                   t.DETALLE                                               AS DetalleTarjeta,
                   t.COSTO                                                 AS CostoTarjeta,
                   t.PPUBLICO                                              AS PPublicoTarjeta,
                   t.MARCA                                                 AS MarcaCodigo,
                   ISNULL(t.IVASINO, 'SI')                                AS IvaSiNo,
                   CAST(ISNULL(t.IVAVALOR, 19) AS DECIMAL(18,4))         AS IvaValor,
                   ISNULL(t.IVADESCRIPCION, 'IVA 19%')                   AS IvaDescripcion,
                   CAST(t.VF4 AS DECIMAL(18,4))                           AS Iva2,
                   t.UBICA4                                                AS IvaDescripcion2,
                   t.GRUPOMENOR                                            AS GrupoMenorCodigo,
                   t.PRESENTACION                                          AS PresentacionCodigo,
                   tp.Codigo                                               AS TipoProductoCodigo,
                   NULLIF(t.PBODEGA,  0)                                  AS PBodega,
                   NULLIF(t.PCREDITO, 0)                                  AS PCredito,
                   NULLIF(t.UPUBLICO, 0)                                  AS UPublico,
                   NULLIF(t.UBODEGA,  0)                                  AS UBodega,
                   NULLIF(t.UCREDITO, 0)                                  AS UCredito,
                   t.EXISTENCIAS                                           AS ExistenciasActuales,
                   t.EXISTENCIASMINIMAS                                    AS ExistenciasMinimas,
                   m.NIT,
                   CASE
                     WHEN NULLIF(LTRIM(RTRIM(ISNULL(u.NOMBRE1,'') + ' ' + ISNULL(u.APELLIDO1,''))), '') IS NOT NULL
                     THEN LTRIM(RTRIM(
                            ISNULL(u.NOMBRE1,'') + ' ' +
                            ISNULL(u.NOMBRE2+' ','') +
                            ISNULL(u.APELLIDO1,'') + ' ' +
                            ISNULL(u.APELLIDO2,'')
                          ))
                     ELSE ISNULL(NULLIF(m.CLIENTE,''), m.NIT)
                   END AS CLIENTE,
                   u.TIPOTERCERO                                           AS ClienteTipoTercero,
                   u.NOMBRE1                                               AS ClienteNombre1,
                   u.NOMBRE2                                               AS ClienteNombre2,
                   u.APELLIDO1                                             AS ClienteApellido1,
                   u.APELLIDO2                                             AS ClienteApellido2,
                   u.EMPRESA                                               AS ClienteEmpresa,
                   ISNULL(NULLIF(u.TELEFONOVIVE,''), u.TELEFONOEMPRESA)   AS ClienteTelefono,
                   ISNULL(NULLIF(u.DIRECCIONVIVE,''), u.DIRECCIONEMPRESA) AS ClienteDireccion,
                   u.CIUDAD                                                AS ClienteCiudad,
                   u.DEPARTAMENTO                                          AS ClienteDepartamento,
                   u.CIUDADCODIGO                                          AS ClienteCodigoMuni,
                   u.DEPARTAMENTOCODIGO                                    AS ClienteCodigoDept
            FROM dbo.MOVDETALLES m
            JOIN dbo.NEXO_ConfiguracionSync cfg ON cfg.CENTROCOSTO = m.CENTROCOSTO
            LEFT JOIN dbo.TARJETA t ON t.CENTROCOSTO = m.CENTROCOSTO AND t.REFERENCIA = m.REFERENCIA
            LEFT JOIN dbo.TIPOPRODUCTO_TIPOS tp ON tp.TipoID = t.VV3
            LEFT JOIN dbo.USUARIOS u ON u.NIT = m.NIT
            WHERE cfg.Activo = 1
              AND m.CENTROCOSTO = @CentroCostoVisions
              AND (@FechaInicio IS NULL OR m.FECDOC >= @FechaInicio)
              AND NOT EXISTS (
                  SELECT 1 FROM dbo.NEXO_VentasExportadas v
                  WHERE v.CENTROCOSTO = m.CENTROCOSTO AND v.TIPDOC = m.TIPDOC
                    AND v.NRODOC = m.NRODOC AND v.ORDEN = m.ORDEN AND v.REFERENCIA = m.REFERENCIA
              )";

        var ventas = (await connection.QueryAsync<VentaPendiente>(sqlVentasNuevas, new
        {
            CentroCostoVisions = centroCostoVisions,
            FechaInicio        = fechaInicioSyncVentas.HasValue ? (object)fechaInicioSyncVentas.Value.Date : DBNull.Value
        })).ToList();

        if (ventas.Count == 0)
            return;

        _logger.LogInformation("Encontradas {Cantidad} ventas nuevas para exportar", ventas.Count);

        foreach (var venta in ventas)
        {
            try
            {
                var idEventoExterno = $"{venta.CENTROCOSTO}-{venta.TIPDOC}-{venta.NRODOC}-{venta.ORDEN}-{venta.REFERENCIA}";

                var esJuridica = (venta.ClienteTipoTercero ?? "").Contains("JURIDICA", StringComparison.OrdinalIgnoreCase)
                    || !string.IsNullOrWhiteSpace(venta.ClienteEmpresa);

                await _apiClient.RegistrarEventoEntranteAsync(new RegistrarEventoEntranteRequest(
                    idEventoExterno, "VENTA", venta.REFERENCIA, venta.CANTIDAD, venta.FECDOC,
                    venta.DetalleTarjeta, venta.CostoTarjeta, venta.PPublicoTarjeta,
                    venta.NIT, venta.CLIENTE,
                    TipDoc:                  venta.TIPDOC,
                    NroDoc:                  venta.NRODOC,
                    ClienteTipoPersona:      esJuridica ? "Juridica" : (venta.NIT != null ? "Natural" : null),
                    ClientePrimerNombre:     esJuridica ? null : venta.ClienteNombre1,
                    ClienteSegundoNombre:    esJuridica ? null : venta.ClienteNombre2,
                    ClientePrimerApellido:   esJuridica ? null : venta.ClienteApellido1,
                    ClienteSegundoApellido:  esJuridica ? null : venta.ClienteApellido2,
                    ClienteEmpresa:          esJuridica ? venta.ClienteEmpresa : null,
                    ClienteTelefono:         venta.ClienteTelefono,
                    ClienteDireccion:        venta.ClienteDireccion,
                    ClienteCiudad:           venta.ClienteCiudad,
                    ClienteDepartamento:     venta.ClienteDepartamento,
                    ClienteCodigoMuni:       venta.ClienteCodigoMuni,
                    ClienteCodigoDept:       venta.ClienteCodigoDept,
                    MarcaCodigo:             venta.MarcaCodigo,
                    IvaValor:                venta.IvaValor,
                    IvaDescripcion:          venta.IvaDescripcion,
                    IvaSiNo:                 venta.IvaSiNo,
                    Iva2:                    venta.Iva2,
                    IvaDescripcion2:         venta.IvaDescripcion2,
                    GrupoMenorCodigo:        venta.GrupoMenorCodigo,
                    PresentacionCodigo:      venta.PresentacionCodigo,
                    TipoProductoCodigo:      venta.TipoProductoCodigo,
                    PBodega:                 venta.PBodega,
                    PCredito:                venta.PCredito,
                    UPublico:                venta.UPublico,
                    UBodega:                 venta.UBodega,
                    UCredito:                venta.UCredito,
                    ExistenciasActuales:     venta.ExistenciasActuales,
                    ExistenciasMinimas:      venta.ExistenciasMinimas), ct);

                await connection.ExecuteAsync(
                    @"IF NOT EXISTS (SELECT 1 FROM dbo.NEXO_VentasExportadas
                                    WHERE CENTROCOSTO=@CENTROCOSTO AND TIPDOC=@TIPDOC AND NRODOC=@NRODOC AND ORDEN=@ORDEN AND REFERENCIA=@REFERENCIA)
                      INSERT INTO dbo.NEXO_VentasExportadas (CENTROCOSTO, TIPDOC, NRODOC, ORDEN, REFERENCIA, CANTIDAD)
                      VALUES (@CENTROCOSTO, @TIPDOC, @NRODOC, @ORDEN, @REFERENCIA, @CANTIDAD)",
                    venta);

                _logger.LogInformation("Venta {IdEventoExterno} exportada", idEventoExterno);
            }
            catch (OperationCanceledException) when (ct.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "No se pudo exportar la venta {NRODOC}-{REFERENCIA}", venta.NRODOC, venta.REFERENCIA);
            }
        }
    }
}