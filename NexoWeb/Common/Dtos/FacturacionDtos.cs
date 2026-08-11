namespace NexoWeb.Common.Dtos;

public record FacturaItem(
    int FacturaID, int ClienteID, string Cliente, DateTime Fecha, string? Notas,
    decimal Total, decimal TotalPagado, decimal SaldoPendiente, string Estado,
    bool StockDescontado, bool ProduccionAutoEjecutada
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

public record InsumoVerificacionItem(
    int ArticuloID, string Nombre, string Unidad,
    decimal CantidadRequerida, decimal StockDisponible
)
{
    public bool EsInsuficiente => StockDisponible < CantidadRequerida;
}

public record VerificarProduccionItem(
    int ArticuloID, string SKU, string Nombre,
    decimal CantidadFacturada, bool TieneReceta, int? RecetaID,
    List<InsumoVerificacionItem> Insumos
)
{
    public bool TieneStockCompleto => TieneReceta && Insumos.All(i => !i.EsInsuficiente);
    public bool TieneInsuficientes => Insumos.Any(i => i.EsInsuficiente);
}

public record AutoProducirResultItem(
    int ArticuloID, string Nombre, bool Exitoso,
    int? OrdenProduccionID, string? Error
);
