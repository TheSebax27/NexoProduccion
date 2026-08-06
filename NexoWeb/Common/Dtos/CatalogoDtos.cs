namespace NexoWeb.Common.Dtos;

// Clientes se movio a Common/Dtos/CrmDtos.cs (agosto 2026).

public record CentroTrabajoItem(
    int CentroTrabajoID,
    string Nombre,
    int CentroCostoID,
    string CentroCosto,
    decimal CostoHoraManoObra,
    decimal CostoHoraCIF,
    bool Estado
);

public record CrearCentroTrabajoRequest(
    string Nombre, int CentroCostoID, decimal CostoHoraManoObra, decimal CostoHoraCIF
);

public record ActualizarCentroTrabajoRequest(
    string Nombre, decimal CostoHoraManoObra, decimal CostoHoraCIF, bool Estado
);

public record CentroCostoItem(
    int CentroCostoID,
    string Codigo,
    string Nombre,
    string TipoCentro,
    string? Direccion,
    bool Estado,
    bool TieneVisions,
    string? IdentificadorClienteVisions,
    int? BodegaVentaVisionsID,
    string? PrefijosDocumentoVentaVisions
);

// Agregado para la pantalla de administracion de Centros de Costo (punto #2).
public record CrearCentroCostoRequest(
    string Codigo,
    string Nombre,
    string TipoCentro,
    string? Direccion,
    string? Telefono
);

public record ActualizarCentroCostoRequest(
    string Nombre,
    string? Direccion,
    string? Telefono,
    bool Estado,
    bool TieneVisions,
    string? IdentificadorClienteVisions,
    int? BodegaVentaVisionsID,
    string? PrefijosDocumentoVentaVisions
);

// ---------- Integracion Visions ----------
public record GenerarApiKeyRequest(int CentroCostoID, string Descripcion);
public record GenerarApiKeyResponse(int AgenteSyncID, string ApiKey);

// Agregado: faltaba este DTO y se usaba en Dashboard, Compras, Inventario,
// Traspasos y Produccion (ArticuloID, SKU, Nombre).


// Reemplaza la version reducida anterior: ahora coincide exactamente con el
// BodegaItem que devuelve la API (antes faltaban CentroCostoID, EsVirtual y
// Estado). Se agregan al final para no romper el binding por nombre que ya
// usan Compras, Inventario, Traspasos y Produccion.
public record BodegaItem(
    int BodegaID,
    string Nombre,
    string CentroCosto,
    string TipoBodega,
    int CentroCostoID,
    bool EsVirtual,
    bool Estado
);

// Agregado para la pantalla de administracion de Bodegas (punto #2).
public record CrearBodegaRequest(
    string Nombre,
    int CentroCostoID,
    string TipoBodega,
    bool EsVirtual
);

// CentroCostoID no se puede cambiar una vez creada la bodega.
public record ActualizarBodegaRequest(
    string Nombre,
    string TipoBodega,
    bool EsVirtual,
    bool Estado
);

// Reemplaza la version reducida anterior: ahora coincide exactamente con el
// ArticuloItem que devuelve la API (antes solo traia ArticuloID, SKU y
// Nombre). Se agregan al final para no romper el binding por nombre que ya
// usan Dashboard, Compras, Inventario, Traspasos y Produccion.
public record ArticuloItem(
    int ArticuloID,
    string SKU,
    string Nombre,
    string? Descripcion,
    string TipoArticulo,
    string? Unidad,
    decimal CostoPromedio,
    decimal PrecioVenta,
    decimal StockMinimo,
    decimal PuntoReorden,
    bool Estado,
    int? DiasVidaUtil,
    decimal? UnidadesPorEmbalaje,
    bool TieneImagen
);

// Imagen opcional, una sola por articulo. CrearArticuloResponse solo se usa
// para leer el ArticuloID nuevo y poder subir la imagen justo despues de crear.
public record ActualizarImagenRequest(string Base64, string ContentType);
public record CrearArticuloResponse(int ArticuloId);

// Lo que cierra ArticuloDialog: la solicitud de crear/actualizar de siempre,
// mas la imagen opcional seleccionada (si el usuario eligio una). Articulos.razor
// primero hace el Crear/Actualizar de siempre y, si hay imagen, la sube
// aparte con el ArticuloID resultante.
public record ArticuloDialogResultado(object Datos, string? ImagenBase64, string? ImagenContentType);

// Agregado para la pantalla de administracion de Articulos (punto #2).
// UnidadID es opcional: un Servicio no es tangible, no aplica una unidad fisica.
// UnidadesPorEmbalaje: cuantas unidades base trae 1 caja/embalaje (solo
// informativo/de conversion, el stock siempre se registra en UnidadID base).
public record CrearArticuloRequest(
    string SKU,
    string Nombre,
    string? Descripcion,
    int TipoArticuloID,
    int? UnidadID,
    decimal PrecioVenta,
    decimal StockMinimo,
    decimal PuntoReorden,
    int? DiasVidaUtil,
    decimal? UnidadesPorEmbalaje
);

public record ActualizarArticuloRequest(
    string Nombre,
    string? Descripcion,
    decimal PrecioVenta,
    decimal StockMinimo,
    decimal PuntoReorden,
    int? DiasVidaUtil,
    bool Estado,
    decimal? UnidadesPorEmbalaje
);

public record ProveedorItem(
    int ProveedorID, string RazonSocial, string NIT, string? Contacto,
    string? Telefono, string? Email, string? Direccion, bool Estado
);
public record CrearProveedorRequest(string RazonSocial, string NIT, string? Contacto, string? Telefono, string? Email, string? Direccion);
public record ActualizarProveedorRequest(string RazonSocial, string NIT, string? Contacto, string? Telefono, string? Email, string? Direccion, bool Estado);

public record TipoArticuloItem(int TipoArticuloID, string Codigo, string Nombre);
public record UnidadMedidaItem(int UnidadID, string Nombre, string Abreviatura, string Tipo);