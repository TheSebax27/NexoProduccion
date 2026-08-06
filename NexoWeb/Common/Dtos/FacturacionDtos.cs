namespace NexoWeb.Common.Dtos;

public record FacturaItem(
    int FacturaID, int ClienteID, string Cliente, DateTime Fecha, string? Notas,
    decimal Total, decimal TotalPagado, decimal SaldoPendiente, string Estado
);

public record LineaFacturaInput(int ArticuloID, decimal Cantidad, decimal PrecioUnitario);
public record CrearFacturaRequest(int ClienteID, DateTime Fecha, string? Notas, List<LineaFacturaInput> Lineas);

public record FacturaLineaItem(
    int LineaID, int FacturaID, int ArticuloID, string SkuArticulo, string NombreArticulo,
    decimal Cantidad, decimal PrecioUnitario, decimal Subtotal
);

public record PagoItem(int PagoID, int FacturaID, decimal Monto, DateTime FechaPago, string? Notas, string? Usuario);
public record CrearPagoRequest(int FacturaID, decimal Monto, DateTime FechaPago, string? Notas);
