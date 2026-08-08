namespace NexoWeb.Common.Dtos;

public record FacturaItem(
    int FacturaID, int ClienteID, string Cliente, DateTime Fecha, string? Notas,
    decimal Total, decimal TotalPagado, decimal SaldoPendiente, string Estado,
    bool StockDescontado
);

public record FacturaLineaStockItem(
    int ArticuloID, string SkuArticulo, string NombreArticulo,
    decimal CantidadFacturada, decimal StockDisponible
)
{
    public bool EsInsuficiente => StockDisponible < CantidadFacturada;
};

public record LineaFacturaInput(int ArticuloID, decimal Cantidad, decimal PrecioUnitario);
public record CrearFacturaRequest(int ClienteID, DateTime Fecha, string? Notas, List<LineaFacturaInput> Lineas);

public record FacturaLineaItem(
    int LineaID, int FacturaID, int ArticuloID, string SkuArticulo, string NombreArticulo,
    decimal Cantidad, decimal PrecioUnitario, decimal Subtotal,
    string? Unidad, decimal? UnidadesPorEmbalaje
)
{
    public bool EsUnidadCaja => Unidad == "cja" && UnidadesPorEmbalaje is > 0;
};

public record PagoItem(int PagoID, int FacturaID, decimal Monto, DateTime FechaPago, string MetodoPago, string? Notas, string? Usuario);
public record CrearPagoRequest(int FacturaID, decimal Monto, DateTime FechaPago, string MetodoPago, string? Notas);
