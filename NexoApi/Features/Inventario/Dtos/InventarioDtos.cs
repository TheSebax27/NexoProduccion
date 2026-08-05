namespace NexoApi.Features.Inventario.Dtos;

public record StockConsolidadoItem(
    int ArticuloID,
    string SKU,
    string Articulo,
    string TipoArticulo,
    string? Unidad,
    decimal? UnidadesPorEmbalaje,
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
    bool RequierePedido,
    bool TieneImagen
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

public record MotivoPerdidaItem(int MotivoID, string Nombre);

public record AjustarInventarioRequest(
    int ArticuloID,
    int BodegaID,
    decimal Cantidad,
    decimal CostoUnitario,
    string Motivo
);

public record AjustarInventarioResponse(string CodigoAjuste, int AjusteID, decimal NuevoSaldo);

public record KardexMovimientoItem(
    long KardexID,
    DateTime Fecha,
    string Articulo,
    string Bodega,
    string TipoMovimiento,
    decimal Cantidad,
    decimal CostoUnitario,
    decimal CantidadSaldo,
    string? ObservacionDetallada
);