namespace NexoWeb.Common.Dtos;

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
    bool TieneImagen,
    decimal StockMinimo,
    decimal CostoPromedio,
    decimal PrecioVenta
);

public record MotivoPerdidaItem(int MotivoID, string Nombre);

public record KardexMovimientoItem(
    long KardexID, DateTime Fecha,
    string SKU, string Articulo, string? Unidad, decimal? UnidadesPorEmbalaje,
    string Bodega, string TipoMovimiento,
    decimal Cantidad, decimal CostoUnitario, decimal CantidadSaldo, decimal ValorMovimiento,
    string? ObservacionDetallada
)
{
    // EsCaja: usa UnidadesPorEmbalaje en lugar de Unidad == "cja" porque Unidad
    // ahora viene de PresentacionCodigo y el código puede variar por cliente.
    public bool EsCaja => UnidadesPorEmbalaje is > 0;
    // La BD almacena cantidades siempre positivas; la dirección sale del nombre del tipo.
    public bool EsEntrada => !(
        TipoMovimiento.Contains("Salida")  ||
        TipoMovimiento.Contains("Baja")    ||
        TipoMovimiento.Contains("Pérdida") ||
        TipoMovimiento.Contains("Perdida") ||
        TipoMovimiento.Contains("Consumo")
    );
};

public record RegistrarBajaRequest(
    int ArticuloID,
    int BodegaID,
    int? LoteID,
    decimal CantidadPerdida,
    int MotivoID,
    string ObservacionDetallada
);

public record RegistrarBajaResponse(string CodigoBaja, int BajaID);

public record AjustarInventarioRequest(
    int ArticuloID,
    int BodegaID,
    decimal Cantidad,
    decimal CostoUnitario,
    string Motivo
);

public record AjustarInventarioResponse(string CodigoAjuste, int AjusteID, decimal NuevoSaldo);
