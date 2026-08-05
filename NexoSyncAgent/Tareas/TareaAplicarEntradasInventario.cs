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
                // No propagamos el error: un evento que falla no debe tumbar
                // el procesamiento de los demas. Se queda PENDIENTE y se
                // reintenta solo en la proxima ronda.
                _logger.LogError(ex, "No se pudo aplicar el evento {EventoID}", evento.EventoID);
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

    // Crea o actualiza el articulo en dbo.TARJETA (nombre, costo, precio
    // publico, existencias minimas). A proposito NUNCA toca EXISTENCIAS aqui
    // -- el stock se mueve solo por los eventos de entrada de inventario
    // (AplicarEntradaInventario), para no pisar cantidades reales de Visions
    // con un 0 cada vez que se resincroniza el nombre o el precio.
    private void SincronizarArticulo(NexoApiClient.Dtos.EventoPendienteItem evento)
    {
        using var connection = _visionsDb.CreateConnection();

        connection.Execute(
            @"MERGE dbo.TARJETA AS destino
              USING (SELECT @CentroCosto AS CENTROCOSTO, @Referencia AS REFERENCIA) AS origen
              ON destino.CENTROCOSTO = origen.CENTROCOSTO AND destino.REFERENCIA = origen.REFERENCIA
              WHEN MATCHED THEN UPDATE SET
                  DETALLE = @Detalle, COSTO = @Costo, PPUBLICO = @PPublico, EXISTENCIASMINIMAS = @ExistenciasMinimas
              WHEN NOT MATCHED THEN
                  INSERT (CENTROCOSTO, REFERENCIA, DETALLE, COSTO, PPUBLICO, EXISTENCIASMINIMAS, EXISTENCIAS)
                  VALUES (@CentroCosto, @Referencia, @Detalle, @Costo, @PPublico, @ExistenciasMinimas, 0);",
            new
            {
                CentroCosto = evento.CentroCostoVisions,
                Referencia = evento.ReferenciaVisions,
                Detalle = evento.NombreArticulo,
                Costo = evento.CostoUnitario,
                PPublico = evento.PrecioVentaArticulo,
                ExistenciasMinimas = evento.StockMinimoArticulo
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