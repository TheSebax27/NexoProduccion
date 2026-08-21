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

        AplicarEntradaInventario(evento);
    }

    // Crea o actualiza el articulo en dbo.TARJETA sincronizando nombre, costo,
    // precio publico, existencias minimas y el stock actual de NEXO (Cantidad
    // en el evento = SUM de Inventario.InventarioStock en el momento del evento).
    private void SincronizarArticulo(NexoApiClient.Dtos.EventoPendienteItem evento)
    {
        using var connection = _visionsDb.CreateConnection();

        connection.Execute(
            @"MERGE dbo.TARJETA AS destino
              USING (SELECT @CentroCosto AS CENTROCOSTO, @Referencia AS REFERENCIA) AS origen
              ON destino.CENTROCOSTO = origen.CENTROCOSTO AND destino.REFERENCIA = origen.REFERENCIA
              WHEN MATCHED THEN UPDATE SET
                  DETALLE = ISNULL(@Detalle, ''),
                  COSTO = ISNULL(@Costo, 0),
                  PPUBLICO = ISNULL(@PPublico, 0),
                  EXISTENCIASMINIMAS = ISNULL(@ExistenciasMinimas, 0),
                  EXISTENCIAS = ISNULL(@Existencias, 0),
                  FRACCIONES    = COALESCE(@Fracciones,    FRACCIONES,    0),
                  PRESENTACION  = COALESCE(@Presentacion,  PRESENTACION,  ''),
                  MARCA         = COALESCE(@Marca,         MARCA,         ''),
                  VF4           = COALESCE(@Iva2,          VF4,           0),
                  UBICA4        = COALESCE(@IvaDescripcion2, UBICA4,      ''),
                  GRUPOMENOR    = COALESCE(@GrupoMenor,    GRUPOMENOR,    ''),
                  IVASINO       = COALESCE(@IvaSiNo,       IVASINO,       'SI'),
                  IVAVALOR      = COALESCE(@IvaValor,      IVAVALOR,      19),
                  IVADESCRIPCION = COALESCE(@IvaDescripcion, IVADESCRIPCION, 'IVA 19%'),
                  PBODEGA  = CASE WHEN @PBodega  IS NOT NULL THEN @PBodega  ELSE ISNULL(PBODEGA,  0) END,
                  PCREDITO = CASE WHEN @PCredito IS NOT NULL THEN @PCredito ELSE ISNULL(PCREDITO, 0) END,
                  UPUBLICO = CASE WHEN @UPublico IS NOT NULL THEN @UPublico ELSE ISNULL(UPUBLICO, 0) END,
                  UBODEGA  = CASE WHEN @UBodega  IS NOT NULL THEN @UBodega  ELSE ISNULL(UBODEGA,  0) END,
                  UCREDITO = CASE WHEN @UCredito IS NOT NULL THEN @UCredito ELSE ISNULL(UCREDITO, 0) END
              WHEN NOT MATCHED THEN
                  INSERT (CENTROCOSTO, REFERENCIA, DETALLE, COSTO, PPUBLICO, PBODEGA, PCREDITO, UPUBLICO, UBODEGA, UCREDITO, EXISTENCIASMINIMAS, FRACCIONES, CANTIDAD, PRESENTACION, EXISTENCIAS, MARCA, VF4, UBICA4, GRUPOMENOR, IVASINO, IVAVALOR, IVADESCRIPCION)
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
                      ISNULL(@Iva2, 0),
                      ISNULL(@IvaDescripcion2, ''),
                      ISNULL(@GrupoMenor, ''),
                      ISNULL(@IvaSiNo, 'SI'),
                      ISNULL(@IvaValor, 19),
                      ISNULL(@IvaDescripcion, 'IVA 19%'));",
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
                IvaDescripcion = evento.IvaDescripcion
            });
    }

    private void AplicarEntradaInventario(NexoApiClient.Dtos.EventoPendienteItem evento)
    {
        using var connection = _visionsDb.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();

        try
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

            transaction.Commit();
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }
}