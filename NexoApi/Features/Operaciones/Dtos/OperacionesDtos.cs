namespace NexoApi.Features.Operaciones.Dtos;

public record MovimientoItem(
    int ID,
    string Tipo,        // OC | DESPACHO | FACTURA
    string Referencia,
    DateTime Fecha,
    string Contraparte,
    decimal Monto,
    string Estado
);

public record MovimientosFiltro(
    DateTime? Desde,
    DateTime? Hasta,
    string? Tipo        // null = todos
);
