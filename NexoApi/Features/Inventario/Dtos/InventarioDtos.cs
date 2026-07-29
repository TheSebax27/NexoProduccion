namespace NexoApi.Features.Inventario.Dtos;

public record StockConsolidadoItem(
    int ArticuloID,
    string SKU,
    string Articulo,
    string TipoArticulo,
    int BodegaID,
    string Bodega,
    int CentroCostoID,
    string CentroCosto,
    int? LoteID,
    string? NumeroLote,
    DateTime? FechaVencimiento,
    decimal CantidadActual,
    decimal CostoUnitarioLote,
    decimal ValorTotal,
    bool RequierePedido
);

public record RegistrarBajaRequest(
    int ArticuloID,
    int BodegaID,
    int? LoteID,
    decimal CantidadPerdida,
    int MotivoID,
    string ObservacionDetallada
);

public record RegistrarBajaResponse(string CodigoBaja, int BajaID);