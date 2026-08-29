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
    List<DetalleOrdenCompraRequest> Detalle,
    int? CentroCostoID = null
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
    decimal Total,
    DateTime? FechaRecepcion
);

public record PedidoParaVisionsDto(
    int PedidoID,
    string Codigo,
    string TipoMovimiento,
    DateTime Fecha,
    string? ProveedorNit,
    string ProveedorNombre,
    List<LineaPedidoParaVisionsDto> Lineas
);

public record LineaPedidoParaVisionsDto(
    int Orden,
    string? ReferenciaVisions,
    string NombreArticulo,
    decimal Cantidad,
    decimal CostoUnitario
);

public record ActualizarNumeroPedidoVisionsRequest(string TipDoc, string NroDoc);

public record ComparacionPrecioRow(
    int ArticuloID, string SKU, string Articulo,
    int ProveedorID, string Proveedor,
    int TotalPedidos,
    decimal PrecioMin, decimal PrecioMax, decimal PrecioPromedio, decimal UltimoPrecio,
    DateTime UltimaCompra
);

public record OrdenCompraDetalleItem(
    int OrdenCompraDetalleID,
    int ArticuloID,
    string Articulo,
    decimal CantidadSolicitada,
    decimal CantidadRecibida,
    decimal CostoUnitario,
    string? Unidad,
    decimal? UnidadesPorEmbalaje,
    DateTime? FechaUltimaRecepcion
);