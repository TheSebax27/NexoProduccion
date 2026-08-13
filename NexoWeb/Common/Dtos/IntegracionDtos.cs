namespace NexoWeb.Common.Dtos;

public record MapeoArticuloItem(
    int MapeoID, int ArticuloID, string SkuArticulo, string NombreArticulo,
    int CentroCostoID, string CodigoArticuloVisions, bool Estado, DateTime FechaCreacion
);

public record CrearMapeoArticuloRequest(int ArticuloID, int CentroCostoID, string CodigoArticuloVisions);

public record ArticuloPendienteMapeoItem(
    int PendienteID, int CentroCostoID, string CodigoArticuloVisions,
    string? NombreVisions, decimal? CostoVisions, decimal? PrecioVisions,
    decimal CantidadDetectada, DateTime FechaDetectado
);

public record ResolverArticuloPendienteRequest(
    int? ArticuloIDExistente,
    string? SkuNuevo, string? NombreNuevo, decimal? PrecioVentaNuevo, decimal? StockMinimoNuevo
);

public record EstadoIntegracionResponse(
    int AgenteSyncID,
    string Descripcion,
    int CentroCostoID,
    string NombreCentroCosto,
    bool Activo,
    DateTime? UltimoLatido,
    string? VersionAgente,
    int EventosPendientes,
    int EventosProcesadosHoy,
    int VentasImportadasHoy,
    int EventosConError
);

public record ConfiguracionAgenteCompletaResponse(
    int AgenteSyncID,
    string? Descripcion,
    int CentroCostoID,
    string NombreCentroCosto,
    bool Activo,
    string? VisionsDbConexion,
    string? NexoApiBaseUrl,
    int IntervalMinutes,
    string? AgentePath
);

public record ActualizarConfiguracionAgenteRequest(
    string? VisionsDbConexion,
    string? NexoApiBaseUrl,
    int IntervalMinutes,
    string? AgentePath
);
