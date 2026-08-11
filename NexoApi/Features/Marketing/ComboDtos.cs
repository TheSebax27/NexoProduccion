namespace NexoApi.Features.Marketing.Dtos;

public record ComboItem(
    int ComboID, string Nombre, string? Descripcion,
    string Estado, string ModoPrecio,
    DateOnly? FechaInicio, DateOnly? FechaFin,
    decimal? PrecioManual, decimal PorcentajeDescuento,
    decimal? PrecioCalculado,
    string? ImagenBase64, string? ImagenContentType,
    DateTime FechaCreacion
);

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
