namespace NexoApi.Features.Catalogo.Dtos;

// ---------- Centros de Costo ----------
public record CrearCentroCostoRequest(string Codigo, string Nombre, string TipoCentro, string? Direccion, string? Telefono);
public record ActualizarCentroCostoRequest(string Nombre, string? Direccion, string? Telefono, bool Estado);
public record CentroCostoItem(int CentroCostoID, string Codigo, string Nombre, string TipoCentro, string? Direccion, bool Estado, bool TieneVisions);

// ---------- Bodegas ----------
public record CrearBodegaRequest(string Nombre, int CentroCostoID, string TipoBodega, bool EsVirtual);
public record BodegaItem(int BodegaID, string Nombre, int CentroCostoID, string CentroCosto, string TipoBodega, bool EsVirtual, bool Estado);

// ---------- Articulos ----------
public record CrearArticuloRequest(
    string SKU, string Nombre, string? Descripcion, int TipoArticuloID, int UnidadID,
    decimal PrecioVenta, decimal StockMinimo, decimal PuntoReorden, int? DiasVidaUtil
);
public record ActualizarArticuloRequest(
    string Nombre, string? Descripcion, decimal PrecioVenta,
    decimal StockMinimo, decimal PuntoReorden, int? DiasVidaUtil, bool Estado
);
//public record ArticuloItem(
//    int ArticuloID, string SKU, string Nombre, string? Descripcion, string TipoArticulo, string Unidad,
//    decimal CostoPromedio, decimal PrecioVenta, decimal StockMinimo, decimal PuntoReorden, bool Estado
//);

public record ArticuloItem(
    int ArticuloID, string SKU, string Nombre, string? Descripcion, string TipoArticulo, string Unidad,
    decimal CostoPromedio, decimal PrecioVenta, decimal StockMinimo, decimal PuntoReorden, bool Estado,
    int? DiasVidaUtil
);

// Agregado para el punto #2 (pantalla de Articulos): no existia forma de listar
// estos dos catalogos, por lo que el formulario de creacion no podia poblar
// sus selectores de Tipo de Articulo ni de Unidad de Medida.
public record TipoArticuloItem(int TipoArticuloID, string Codigo, string Nombre);
public record UnidadMedidaItem(int UnidadID, string Nombre, string Abreviatura, string Tipo);

public record ClienteItem(int ClienteID, string Nombre);
public record CentroTrabajoItem(int CentroTrabajoID, string Nombre, int CentroCostoID);

// Agregar a Features/Catalogo/Dtos/CatalogoDtos.cs
public record ProveedorItem(int ProveedorID, string RazonSocial);

public record TipoArticuloItemm(int TipoArticuloID, string Codigo, string Nombre);
