using NexoSyncAgent.NexoApiClient.Dtos;

namespace NexoSyncAgent.NexoApiClient;

public interface INexoApiClient
{
    Task<List<EventoPendienteItem>> ObtenerEventosPendientesAsync(CancellationToken ct);
    Task ConfirmarEventoSalienteAsync(long eventoId, CancellationToken ct);
    Task RegistrarEventoEntranteAsync(RegistrarEventoEntranteRequest request, CancellationToken ct);
    Task<ConfiguracionAgenteResponse> ObtenerConfiguracionAsync(CancellationToken ct);
    Task<LatidoResponse> EnviarLatidoAsync(string version, CancellationToken ct);
    Task RegistrarFalloEventoAsync(long eventoId, string mensajeError, CancellationToken ct);

    // Catalogos bidireccionales
    Task<List<MarcaSyncDto>> ListarMarcasSyncAsync(CancellationToken ct);
    Task UpsertMarcaEnNexoAsync(MarcaSyncDto item, CancellationToken ct);
    Task<List<GrupoMayorSyncDto>> ListarGruposMayorSyncAsync(CancellationToken ct);
    Task UpsertGrupoMayorEnNexoAsync(GrupoMayorSyncDto item, CancellationToken ct);
    Task<List<GrupoMenorSyncDto>> ListarGruposMenorSyncAsync(CancellationToken ct);
    Task UpsertGrupoMenorEnNexoAsync(GrupoMenorSyncDto item, CancellationToken ct);
    Task<List<IvaSyncDto>> ListarIvaSyncAsync(CancellationToken ct);
    Task UpsertIvaEnNexoAsync(IvaSyncDto item, CancellationToken ct);
    Task<List<PresentacionSyncDto>> ListarPresentacionesSyncAsync(CancellationToken ct);
    Task UpsertPresentacionEnNexoAsync(PresentacionSyncDto item, CancellationToken ct);

    // Facturas NEXO → Visions
    Task<List<FacturaParaVisionsDto>> ListarFacturasParaVisionsAsync(CancellationToken ct);
    Task MarcarFacturaExportadaVisionsAsync(int facturaId, CancellationToken ct);

    // Sync bidireccional articulos (Visions → NEXO)
    Task SyncArticuloDesdeVisionsAsync(SyncArticuloDesdeVisionsRequest request, CancellationToken ct);
    Task InactivarArticuloDesdeVisionsAsync(string referencia, CancellationToken ct);

    // Clientes para sync NEXO → Visions
    Task<List<ClienteParaSyncDto>> ListarClientesParaSyncAsync(DateTime? desde, CancellationToken ct);
    // Clientes Visions → NEXO
    Task SyncClienteDesdeVisionsAsync(SyncClienteDesdeVisionsRequest request, CancellationToken ct);

    // Proveedores para sync NEXO → Visions
    Task<List<ProveedorParaSyncDto>> ListarProveedoresParaSyncAsync(CancellationToken ct);
    // Proveedores Visions → NEXO
    Task SyncProveedorDesdeVisionsAsync(SyncProveedorDesdeVisionsRequest request, CancellationToken ct);

    // Número de factura asignado por Visions → actualizar NEXO
    Task ActualizarNumeroVisionsAsync(int facturaId, ActualizarNumeroVisionsRequest request, CancellationToken ct);

    // Pedidos NEXO → Visions (Entradas)
    Task<List<PedidoParaVisionsDto>> ListarPedidosParaVisionsAsync(CancellationToken ct);
    Task MarcarPedidoExportadoVisionsAsync(int pedidoId, CancellationToken ct);
    Task ActualizarNumeroPedidoVisionsAsync(int pedidoId, ActualizarNumeroPedidoVisionsRequest request, CancellationToken ct);
}