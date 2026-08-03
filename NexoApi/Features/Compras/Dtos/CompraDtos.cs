namespace NexoApi.Features.Compras.Dtos;

public record DetalleOrdenCompraRequest(
    int ArticuloID,
    decimal CantidadSolicitada,
    decimal CostoUnitario
);

public record CrearOrdenCompraRequest(
    string Codigo,
    int ProveedorID,
    int BodegaDestinoID,
    List<DetalleOrdenCompraRequest> Detalle
);

public record RecibirLineaOrdenCompraRequest(
    decimal CantidadRecibida,
    string NumeroLote,
    DateTime? FechaVencimiento
);

public record OrdenCompraResumen(
    int OrdenCompraID,
    string Codigo,
    string Proveedor,
    string EstadoOC,
    DateTime FechaEmision,
    decimal Total
);

public record OrdenCompraDetalleItem(
    int OrdenCompraDetalleID,
    int ArticuloID,
    string Articulo,
    decimal CantidadSolicitada,
    decimal CantidadRecibida,
    decimal CostoUnitario,
    string? Unidad,
    decimal? UnidadesPorEmbalaje
);