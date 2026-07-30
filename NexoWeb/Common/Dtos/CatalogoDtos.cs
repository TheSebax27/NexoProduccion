namespace NexoWeb.Common.Dtos;

public record ClienteItem(
    int ClienteID,
    string Nombre
);

public record CentroTrabajoItem(
    int CentroTrabajoID,
    string Nombre,
    int CentroCostoID
);

public record CentroCostoItem(
    int CentroCostoID,
    string Codigo,
    string Nombre,
    string TipoCentro,
    string? Direccion,
    bool Estado,
    bool TieneVisions
);

// Agregado: faltaba este DTO y se usaba en Dashboard, Compras, Inventario,
// Traspasos y Produccion (ArticuloID, SKU, Nombre).
public record ArticuloItem(
    int ArticuloID,
    string SKU,
    string Nombre
);

// Agregado: faltaba este DTO y se usaba en Compras, Inventario, Traspasos
// y Produccion (BodegaID, Nombre, CentroCosto, TipoBodega).
public record BodegaItem(
    int BodegaID,
    string Nombre,
    string CentroCosto,
    string TipoBodega
);