using System.Data;
using Dapper;
using NexoSyncAgent.NexoApiClient;
using NexoSyncAgent.VisionsData;

namespace NexoSyncAgent.Tareas;

public class TareaAplicarEntradasInventario
{
    private readonly INexoApiClient _apiClient;
    private readonly IVisionsConnectionFactory _visionsDb;
    private readonly ILogger<TareaAplicarEntradasInventario> _logger;

    public TareaAplicarEntradasInventario(
        INexoApiClient apiClient, IVisionsConnectionFactory visionsDb, ILogger<TareaAplicarEntradasInventario> logger)
    {
        _apiClient = apiClient;
        _visionsDb = visionsDb;
        _logger = logger;
    }

    public async Task EjecutarAsync(CancellationToken ct)
    {
        var eventos = await _apiClient.ObtenerEventosPendientesAsync(ct);

        if (eventos.Count == 0)
            return;

        _logger.LogInformation("Encontrados {Cantidad} eventos pendientes de Produccion", eventos.Count);

        foreach (var evento in eventos)
        {
            try
            {
                AplicarEnVisions(evento);
                await _apiClient.ConfirmarEventoSalienteAsync(evento.EventoID, ct);
                _logger.LogInformation("Evento {EventoID} aplicado y confirmado", evento.EventoID);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "No se pudo aplicar el evento {EventoID}", evento.EventoID);
                try
                {
                    await _apiClient.RegistrarFalloEventoAsync(evento.EventoID, ex.Message, ct);
                }
                catch (Exception exFallo)
                {
                    _logger.LogWarning(exFallo, "No se pudo registrar el fallo del evento {EventoID} en la API", evento.EventoID);
                }
            }
        }
    }

    private void AplicarEnVisions(NexoApiClient.Dtos.EventoPendienteItem evento)
    {
        if (evento.TipoEvento == "SINCRONIZAR_ARTICULO")
        {
            SincronizarArticulo(evento);
            return;
        }

        if (evento.TipoEvento is "AJUSTE_INVENTARIO" or "ENTRADA_INVENTARIO" or "ENTRADA_PRODUCCION" or "BAJA_INVENTARIO" or "CONSUMO_INSUMO")
        {
            AplicarEntradaInventario(evento);
            return;
        }

        throw new NotSupportedException($"TipoEvento '{evento.TipoEvento}' desconocido para evento {evento.EventoID}. Actualizar el agente.");
    }

    // Crea o actualiza el articulo en dbo.TARJETA.
    // TR_TARJETA_NexoCambios se suprime automaticamente: el trigger verifica
    // APP_NAME() = 'NexoSyncAgent' y retorna sin insertar en NEXO_TarjetasCambios.
    // VisionsConnectionFactory siempre fuerza ese ApplicationName. Compatible SQL 2008+.
    private void SincronizarArticulo(NexoApiClient.Dtos.EventoPendienteItem evento)
    {
        using var connection = _visionsDb.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();

        // Resolver TipoID numérico de Visions desde el Codigo ('PT','MP','IN','SER').
        // Si viene null o no se encuentra en TIPOPRODUCTO_TIPOS, se deja VV3 sin cambiar (COALESCE).
        int? tipoProductoID = null;
        if (!string.IsNullOrWhiteSpace(evento.TipoProductoCodigo))
            tipoProductoID = connection.ExecuteScalar<int?>(
                "SELECT TipoID FROM dbo.TIPOPRODUCTO_TIPOS WHERE Codigo = @Codigo",
                new { Codigo = evento.TipoProductoCodigo }, transaction);

        connection.Execute(
            @"MERGE dbo.TARJETA AS destino
              USING (SELECT @CentroCosto AS CENTROCOSTO, @Referencia AS REFERENCIA) AS origen
              ON destino.CENTROCOSTO = origen.CENTROCOSTO AND destino.REFERENCIA = origen.REFERENCIA
              WHEN MATCHED THEN UPDATE SET
                  DETALLE = COALESCE(NULLIF(@Detalle, ''), DETALLE, ''),
                  COSTO = CASE WHEN ISNULL(@Costo, 0) > 0 THEN @Costo ELSE ISNULL(COSTO, 0) END,
                  PPUBLICO = CASE WHEN ISNULL(@PPublico, 0) > 0 THEN @PPublico ELSE ISNULL(PPUBLICO, 0) END,
                  EXISTENCIASMINIMAS = CASE WHEN ISNULL(@ExistenciasMinimas, 0) > 0 THEN @ExistenciasMinimas ELSE ISNULL(EXISTENCIASMINIMAS, 0) END,
                  -- EXISTENCIAS no se toca en sync de catalogo; solo cambia por ENTRADA_INVENTARIO
                  -- o por ventas internas del POS. Sobreescribirla con el stock de NEXO (que puede
                  -- ser 0 si aun no se han procesado las ventas) destruiria el stock de Visions.
                  FRACCIONES    = COALESCE(@Fracciones,    FRACCIONES,    0),
                  PRESENTACION  = COALESCE(@Presentacion,  PRESENTACION,  ''),
                  MARCA         = COALESCE(@Marca,         MARCA,         ''),
                  VF4           = COALESCE(@Iva2,          VF4,           0),
                  UBICA4        = COALESCE(@IvaDescripcion2, UBICA4,      ''),
                  GRUPOMENOR    = COALESCE(@GrupoMenor,    GRUPOMENOR,    ''),
                  IVASINO       = COALESCE(@IvaSiNo,       IVASINO,       'SI'),
                  IVAVALOR      = COALESCE(@IvaValor,      IVAVALOR,      19),
                  IVADESCRIPCION = COALESCE(@IvaDescripcion, IVADESCRIPCION, 'IVA 19%'),
                  VV3      = COALESCE(@TipoProductoID, VV3),
                  PBODEGA  = CASE WHEN @PBodega  IS NOT NULL THEN @PBodega  ELSE ISNULL(PBODEGA,  0) END,
                  PCREDITO = CASE WHEN @PCredito IS NOT NULL THEN @PCredito ELSE ISNULL(PCREDITO, 0) END,
                  UPUBLICO = CASE WHEN @UPublico IS NOT NULL THEN @UPublico ELSE ISNULL(UPUBLICO, 0) END,
                  UBODEGA  = CASE WHEN @UBodega  IS NOT NULL THEN @UBodega  ELSE ISNULL(UBODEGA,  0) END,
                  UCREDITO = CASE WHEN @UCredito IS NOT NULL THEN @UCredito ELSE ISNULL(UCREDITO, 0) END,
                  FULTV = ISNULL(FULTV, CAST('2000-01-01' AS date)),
                  FULTC = ISNULL(FULTC, CAST('2000-01-01' AS date)),
                  NOTA  = ISNULL(NOTA,  N''),
                  DFI   = ISNULL(DFI,   CAST('2000-01-01' AS date)),
                  DFF   = ISNULL(DFF,   CAST('2000-01-01' AS date))
              WHEN NOT MATCHED THEN
                  INSERT (CENTROCOSTO, REFERENCIA, DETALLE, COSTO, PPUBLICO, PBODEGA, PCREDITO, UPUBLICO, UBODEGA, UCREDITO,
                          EXISTENCIASMINIMAS, FRACCIONES, CANTIDAD, PRESENTACION, EXISTENCIAS, MARCA,
                          VF1, VV1, VF2, VV2, VF3, VF4, VV3, VV4,
                          GRUPOMENOR, IVASINO, IVAVALOR, IVADESCRIPCION, UBICA4,
                          BARRAS, VALORIZADO, FRACCIONA, TIPOTARJETA,
                          ROTA1, ROTA2, SUGERIDO, FISICOE, FISICOF, COMBO,
                          FULTV, FULTC, REVISAR, NOTA, PESO, DFI, DFF, DPO, DVA, PESAR,
                          MARGEN1, MARGEN2, MARGEN3, PUC, BODEGA,
                          UBICA, UBICA1, UBICA2, UBICA3,
                          INTERNO, INVENTA, ADVIERTE)
                  VALUES (
                      @CentroCosto,
                      @Referencia,
                      ISNULL(@Detalle, ''),
                      ISNULL(@Costo, 0),
                      ISNULL(@PPublico, 0),
                      ISNULL(@PBodega, 0),
                      ISNULL(@PCredito, 0),
                      ISNULL(@UPublico, 0),
                      ISNULL(@UBodega, 0),
                      ISNULL(@UCredito, 0),
                      ISNULL(@ExistenciasMinimas, 0),
                      ISNULL(@Fracciones, 0),
                      1,
                      ISNULL(@Presentacion, ''),
                      ISNULL(@Existencias, 0),
                      ISNULL(@Marca, ''),
                      0, 0, 0, 0, 0,
                      ISNULL(@Iva2, 0),
                      ISNULL(@TipoProductoID, 1),
                      0,
                      ISNULL(@GrupoMenor, ''),
                      ISNULL(@IvaSiNo, 'SI'),
                      ISNULL(@IvaValor, 19),
                      ISNULL(@IvaDescripcion, 'IVA 19%'),
                      ISNULL(@IvaDescripcion2, ''),
                      '', 0, '', '',
                      0, 0, 0, 0, 0, 0,
                      CAST('2000-01-01' AS date), CAST('2000-01-01' AS date), 0, N'', 0, CAST('2000-01-01' AS date), CAST('2000-01-01' AS date), 0, 0, '',
                      0, 0, 0, '', '',
                      0, '', '', '',
                      0, 0, 0);",
            new
            {
                CentroCosto = evento.CentroCostoVisions,
                Referencia = evento.ReferenciaVisions,
                Detalle = evento.NombreArticulo,
                Costo = evento.CostoUnitario,
                PPublico = evento.PrecioVentaArticulo,
                PBodega = evento.PBodega > 0 ? evento.PBodega : (decimal?)null,
                PCredito = evento.PCredito > 0 ? evento.PCredito : (decimal?)null,
                UPublico = evento.UPublico > 0 ? evento.UPublico : (decimal?)null,
                UBodega  = evento.UBodega  > 0 ? evento.UBodega  : (decimal?)null,
                UCredito = evento.UCredito > 0 ? evento.UCredito : (decimal?)null,
                ExistenciasMinimas = evento.StockMinimoArticulo,
                Fracciones = evento.Fracciones,
                Presentacion = evento.PresentacionCodigo,
                Existencias = evento.Cantidad,
                Marca = evento.MarcaCodigo,
                Iva2 = evento.Iva2,
                IvaDescripcion2 = evento.IvaDescripcion2,
                GrupoMenor = evento.GrupoMenorCodigo,
                IvaSiNo = evento.IvaSiNo,
                IvaValor = evento.IvaValor,
                IvaDescripcion = evento.IvaDescripcion,
                TipoProductoID = tipoProductoID
            }, transaction);

        // Marcar en NEXO_TarjetasCambios para que TareaDetectarArticulosFaltantes
        // no reenvie este articulo a NEXO en el mismo ciclo (doble pasada).
        // El trigger no inserto nada (APP_NAME supresion), este INSERT es el unico rastro.
        // Dentro de la misma transaccion: si falla el INSERT de guardia, el MERGE de TARJETA
        // tambien se revierte y el evento se reintenta en el siguiente ciclo.
        connection.Execute(@"
            MERGE dbo.NEXO_TarjetasCambios WITH (HOLDLOCK) AS dest
            USING (SELECT @CC AS CENTROCOSTO, @Ref AS REFERENCIA) AS src
            ON dest.CENTROCOSTO = src.CENTROCOSTO AND dest.REFERENCIA = src.REFERENCIA
            WHEN NOT MATCHED THEN
                INSERT (CENTROCOSTO, REFERENCIA, DETALLE, COSTO, PPUBLICO, FechaCambio, Procesado)
                VALUES (@CC, @Ref, @Detalle, @Costo, @PPub, GETDATE(), 1);",
            new
            {
                CC     = evento.CentroCostoVisions,
                Ref    = evento.ReferenciaVisions,
                Detalle = evento.NombreArticulo,
                Costo  = evento.CostoUnitario,
                PPub   = evento.PrecioVentaArticulo
            }, transaction);

        transaction.Commit();
    }

    private void AplicarEntradaInventario(NexoApiClient.Dtos.EventoPendienteItem evento)
    {
        using var connection = _visionsDb.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();

        try
        {
            // Idempotencia: si NEXO_EntradasInventario ya tiene fila para este EventoID,
            // el stock fue sumado en un ciclo anterior (confirm falló tras apply exitoso).
            // No repetir el UPDATE — solo dejar que el caller confirme en NEXO.
            var yaAplicado = connection.ExecuteScalar<int>(
                "SELECT COUNT(1) FROM dbo.NEXO_EntradasInventario WHERE IdEventoOrigen = @Id",
                new { Id = evento.EventoID }, transaction) > 0;

            if (!yaAplicado)
            {
                var filas = connection.Execute(
                    @"UPDATE dbo.TARJETA SET EXISTENCIAS = ISNULL(EXISTENCIAS,0) + @Cantidad
                      WHERE CENTROCOSTO = @CentroCosto AND REFERENCIA = @Referencia",
                    new
                    {
                        evento.Cantidad,
                        CentroCosto = evento.CentroCostoVisions,
                        Referencia = evento.ReferenciaVisions
                    },
                    transaction);

                if (filas == 0)
                    throw new InvalidOperationException(
                        $"La referencia {evento.ReferenciaVisions} no existe en TARJETA para el centro de costo {evento.CentroCostoVisions}.");

                connection.Execute(
                    @"INSERT INTO dbo.NEXO_EntradasInventario
                        (IdEventoOrigen, CENTROCOSTO, REFERENCIA, CANTIDAD, COSTO, Aplicado, FechaAplicado)
                      VALUES (@IdEventoOrigen, @CentroCosto, @Referencia, @Cantidad, @Costo, 1, GETDATE())",
                    new
                    {
                        IdEventoOrigen = evento.EventoID,
                        CentroCosto = evento.CentroCostoVisions,
                        Referencia = evento.ReferenciaVisions,
                        evento.Cantidad,
                        Costo = evento.CostoUnitario
                    },
                    transaction);
            }

            transaction.Commit();
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }
}