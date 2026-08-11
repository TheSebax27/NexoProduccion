namespace NexoWeb.Common.Dtos;

public record ComboItem(
    int ComboID, string Nombre, string? Descripcion,
    string Estado, string ModoPrecio,
    DateOnly? FechaInicio, DateOnly? FechaFin,
    decimal? PrecioManual, decimal PorcentajeDescuento,
    decimal? PrecioCalculado,
    string? ImagenBase64, string? ImagenContentType,
    DateTime FechaCreacion
)
{
    public bool TieneImagen => !string.IsNullOrEmpty(ImagenBase64);
    public string? ImagenDataUri => TieneImagen ? $"data:{ImagenContentType};base64,{ImagenBase64}" : null;
    public decimal PrecioEfectivo => ModoPrecio == "CALCULADO" ? (PrecioCalculado ?? 0) : (PrecioManual ?? 0);
    public bool Vigente
    {
        get
        {
            var hoy = DateOnly.FromDateTime(DateTime.Today);
            return (FechaInicio is null || FechaInicio <= hoy) && (FechaFin is null || FechaFin >= hoy);
        }
    }
}

public record ComboDetalle(
    int ComboID, string Nombre, string? Descripcion,
    string? ImagenBase64, string? ImagenContentType,
    string Estado, string ModoPrecio,
    DateOnly? FechaInicio, DateOnly? FechaFin,
    decimal? PrecioManual, decimal PorcentajeDescuento,
    decimal? PrecioCalculado,
    List<ComboItemLine> Items, DateTime FechaCreacion
);

public record ComboItemLine(
    int ComboItemID, int ArticuloID, string SKU, string NombreArticulo,
    decimal Cantidad, string? Unidad, decimal? PrecioUnitarioSnapshot
);

public record CrearComboRequest(
    string Nombre,
    string? Descripcion,
    string? ImagenBase64,
    string? ImagenContentType,
    string Estado,
    string ModoPrecio,
    DateOnly? FechaInicio,
    DateOnly? FechaFin,
    decimal? PrecioManual,
    decimal PorcentajeDescuento,
    List<ComboItemInput> Items
);

public record ActualizarComboRequest(
    string Nombre,
    string? Descripcion,
    string? ImagenBase64,
    string? ImagenContentType,
    string Estado,
    string ModoPrecio,
    DateOnly? FechaInicio,
    DateOnly? FechaFin,
    decimal? PrecioManual,
    decimal PorcentajeDescuento,
    List<ComboItemInput> Items
);

public record ComboItemInput(int ArticuloID, decimal Cantidad);
