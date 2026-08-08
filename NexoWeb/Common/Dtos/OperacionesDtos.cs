namespace NexoWeb.Common.Dtos;

public record MovimientoItem(
    int ID,
    string Tipo,
    string Referencia,
    DateTime Fecha,
    string Contraparte,
    decimal Monto,
    string Estado
);
