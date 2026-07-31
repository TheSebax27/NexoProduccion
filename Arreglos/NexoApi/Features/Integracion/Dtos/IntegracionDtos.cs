namespace NexoApi.Features.Integracion.Dtos;

public record EventoPendienteItem(
    long EventoID,
    string TipoEvento,
    decimal Cantidad,
    decimal CostoUnitario,
    DateTime FechaCreacion,
    string CentroCostoVisions,
    string ReferenciaVisions
);

public record RegistrarEventoEntranteRequest(
    string IdEventoExterno,
    string TipoEvento,
    string CodigoArticuloVisions,
    decimal Cantidad,
    DateTime FechaEventoOrigen
);

public record GenerarApiKeyRequest(int CentroCostoID, string Descripcion);

// El ApiKey en texto plano SOLO viaja aqui, esta unica vez. Despues de esto,
// ni siquiera nosotros podemos volver a verlo (solo tenemos el hash guardado).
public record GenerarApiKeyResponse(int AgenteSyncID, string ApiKey);