namespace NexoApi.Features.Logistica.Dtos;

// NumeroGuia se genera en el SELECT (GUIA-000123 a partir del DespachoID),
// no se guarda como columna aparte.
public record DespachoItem(
    int DespachoID, string NumeroGuia, int ClienteID, string Cliente,
    int CentroCostoID, string CentroCosto, string BodegaOrigen,
    DateTime FechaDespacho, string Estado, DateTime? FechaEntrega,
    string? Direccion, string? Observaciones, decimal ValorTotal,
    string? MotivoAnulacion, DateTime? FechaAnulacion
);

public record DespachoDetalleItem(int ArticuloID, string SkuArticulo, string NombreArticulo, decimal Cantidad);

public record LineaDespachoRequest(int ArticuloID, decimal Cantidad);

public record CrearDespachoRequest(
    int ClienteID, int CentroCostoID, int BodegaOrigenID,
    string? Direccion, string? Observaciones, List<LineaDespachoRequest> Lineas
);

public record CrearDespachoResponse(int DespachoId);

public record AnularDespachoRequest(string? Motivo);
