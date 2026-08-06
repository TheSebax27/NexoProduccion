namespace NexoApi.Features.Catalogo.Dtos;

// ---------- Centros de Costo ----------
public record CrearCentroCostoRequest(string Codigo, string Nombre, string TipoCentro, string? Direccion, string? Telefono);
// TieneVisions/IdentificadorClienteVisions/BodegaVentaVisionsID solo se
// editan en modo edicion (ver ArticuloDialog): al crear el centro de costo
// todavia no existen sus bodegas, asi que no hay nada que seleccionar como
// "bodega de venta" hasta despues.
// PrefijosDocumentoVentaVisions: lista de codigos TIPDOC (Visions) separados
// por coma, ej. "POS,FV" -- solo esos tipos de documento se exportan como
// venta hacia NEXO. Solo tiene sentido si TieneVisions=true.
public record ActualizarCentroCostoRequest(
    string Nombre, string? Direccion, string? Telefono, bool Estado,
    bool TieneVisions, string? IdentificadorClienteVisions, int? BodegaVentaVisionsID,
    string? PrefijosDocumentoVentaVisions
);
public record CentroCostoItem(
    int CentroCostoID, string Codigo, string Nombre, string TipoCentro, string? Direccion, bool Estado,
    bool TieneVisions, string? IdentificadorClienteVisions, int? BodegaVentaVisionsID,
    string? PrefijosDocumentoVentaVisions
);

// ---------- Bodegas ----------
public record CrearBodegaRequest(string Nombre, int CentroCostoID, string TipoBodega, bool EsVirtual);
// CentroCostoID no se puede cambiar una vez creada (una bodega con stock ya
// esta ligada al costeo de ese centro, igual criterio que el resto del catalogo).
public record ActualizarBodegaRequest(string Nombre, string TipoBodega, bool EsVirtual, bool Estado);
public record BodegaItem(int BodegaID, string Nombre, int CentroCostoID, string CentroCosto, string TipoBodega, bool EsVirtual, bool Estado);

// ---------- Articulos ----------
// UnidadID es opcional: un Servicio no es tangible, no tiene sentido forzarlo
// a una unidad fisica (kg, L, und, etc.).
// UnidadesPorEmbalaje: cuantas unidades base trae 1 caja/embalaje (ej. una
// Caja de Fuente trae 10 unidades). Es solo informativo/de conversion para
// ayudar a calcular bien la cantidad -- el stock, kardex y recetas SIEMPRE
// se registran en la UnidadID base del articulo, esto no cambia esa logica.
public record CrearArticuloRequest(
    string SKU, string Nombre, string? Descripcion, int TipoArticuloID, int? UnidadID,
    decimal PrecioVenta, decimal StockMinimo, decimal PuntoReorden, int? DiasVidaUtil,
    decimal? UnidadesPorEmbalaje
);
public record ActualizarArticuloRequest(
    string Nombre, string? Descripcion, decimal PrecioVenta,
    decimal StockMinimo, decimal PuntoReorden, int? DiasVidaUtil, bool Estado,
    decimal? UnidadesPorEmbalaje
);

public record ArticuloItem(
    int ArticuloID, string SKU, string Nombre, string? Descripcion, string TipoArticulo, string? Unidad,
    decimal CostoPromedio, decimal PrecioVenta, decimal StockMinimo, decimal PuntoReorden, bool Estado,
    int? DiasVidaUtil, decimal? UnidadesPorEmbalaje, bool TieneImagen
);

// ---------- Imagen de articulo (opcional, una sola por articulo) ----------
public record ActualizarImagenRequest(string Base64, string ContentType);

// Agregado para el punto #2 (pantalla de Articulos): no existia forma de listar
// estos dos catalogos, por lo que el formulario de creacion no podia poblar
// sus selectores de Tipo de Articulo ni de Unidad de Medida.
public record TipoArticuloItem(int TipoArticuloID, string Codigo, string Nombre);
public record UnidadMedidaItem(int UnidadID, string Nombre, string Abreviatura, string Tipo);

// Clientes se movio a Features/Crm (agosto 2026) -- ver Features/Crm/Dtos/CrmDtos.cs.

public record CentroTrabajoItem(
    int CentroTrabajoID, string Nombre, int CentroCostoID, string CentroCosto,
    decimal CostoHoraManoObra, decimal CostoHoraCIF, bool Estado
);

public record CrearCentroTrabajoRequest(
    string Nombre, int CentroCostoID, decimal CostoHoraManoObra, decimal CostoHoraCIF
);

public record ActualizarCentroTrabajoRequest(
    string Nombre, decimal CostoHoraManoObra, decimal CostoHoraCIF, bool Estado
);

public record ProveedorItem(
    int ProveedorID, string RazonSocial, string NIT, string? Contacto,
    string? Telefono, string? Email, string? Direccion, bool Estado
);
public record CrearProveedorRequest(string RazonSocial, string NIT, string? Contacto, string? Telefono, string? Email, string? Direccion);
public record ActualizarProveedorRequest(string RazonSocial, string NIT, string? Contacto, string? Telefono, string? Email, string? Direccion, bool Estado);
