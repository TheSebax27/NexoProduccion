namespace NexoSyncAgent.NexoApiClient.Dtos;

// NombreArticulo/PrecioVentaArticulo/StockMinimoArticulo solo vienen cuando
// TipoEvento='SINCRONIZAR_ARTICULO' -- en los demas tipos van null y se ignoran.
public record EventoPendienteItem(
    long EventoID,
    string TipoEvento,
    decimal Cantidad,
    decimal CostoUnitario,
    DateTime FechaCreacion,
    string CentroCostoVisions,
    string ReferenciaVisions,
    string? NombreArticulo,
    decimal? PrecioVentaArticulo,
    decimal? StockMinimoArticulo,
    decimal? Fracciones,
    string? PresentacionCodigo,
    string? MarcaCodigo,
    decimal? Iva2 = null,
    string? IvaDescripcion2 = null,
    string? GrupoMenorCodigo = null,
    string? IvaSiNo = null,
    decimal? IvaValor = null,
    string? IvaDescripcion = null,
    decimal? PBodega = null,
    decimal? PCredito = null,
    decimal? UPublico = null,
    decimal? UBodega = null,
    decimal? UCredito = null,
    string? TipoProductoCodigo = null
);

// NombreArticuloVisions/CostoArticuloVisions/PrecioArticuloVisions: lo que ya
// tiene Visions en dbo.TARJETA para esa REFERENCIA al momento de la venta.
// Se manda siempre -- si NEXO no tiene mapeo para este articulo, sirve de
// sugerencia en la pantalla de "Articulos pendientes de mapeo".
public record RegistrarEventoEntranteRequest(
    string IdEventoExterno,
    string TipoEvento,
    string CodigoArticuloVisions,
    decimal Cantidad,
    DateTime FechaEventoOrigen,
    string? NombreArticuloVisions,
    decimal? CostoArticuloVisions,
    decimal? PrecioArticuloVisions,
    string? ClienteNit,
    string? ClienteNombre,
    string? TipDoc = null,
    string? NroDoc = null,
    string? ClienteTipoPersona = null,
    string? ClientePrimerNombre = null,
    string? ClienteSegundoNombre = null,
    string? ClientePrimerApellido = null,
    string? ClienteSegundoApellido = null,
    string? ClienteEmpresa = null,
    string? ClienteTelefono = null,
    string? ClienteDireccion = null,
    string? ClienteCiudad = null,
    string? ClienteDepartamento = null,
    string? ClienteCodigoMuni = null,
    string? ClienteCodigoDept = null,
    // Datos del catálogo de Visions (dbo.TARJETA) al momento de la venta.
    // Si el artículo no existe en NEXO todavía, se usan para crearlo completo.
    string? MarcaCodigo = null,
    decimal? IvaValor = null,
    string? IvaDescripcion = null,
    string? IvaSiNo = null,
    decimal? Iva2 = null,
    string? IvaDescripcion2 = null,
    string? GrupoMenorCodigo = null,
    string? PresentacionCodigo = null,
    string? TipoProductoCodigo = null,
    decimal? PBodega = null,
    decimal? PCredito = null,
    decimal? UPublico = null,
    decimal? UBodega = null,
    decimal? UCredito = null,
    decimal? ExistenciasActuales = null,
    decimal? ExistenciasMinimas = null
);

// Configuracion que el Administrador dejo en NEXO Web (Catalogo > Centros de
// Costo) y que este agente aplica en la base de Visions local -- asi esos
// valores nunca se editan directo por SQL contra Visions.
// CentroCostoVisions es el codigo CENTROCOSTO real dentro de la base de
// Visions (puede ser null si el Administrador aun no lo configuro en NEXO).
// IntervalMinutes viene de la BD de NEXO -- el admin lo cambia desde la web
// sin necesidad de tocar appsettings.json en el servidor de Visions.
public record ConfiguracionAgenteResponse(int? CentroCostoVisions, bool Activo, string? PrefijosDocumentoVenta, int IntervalMinutes, DateTime? FechaInicioSyncVentas = null);

// Respuesta del endpoint /latido -- confirma que la API recibio el latido
// y devuelve la hora del servidor para que el agente pueda detectar desfase de reloj.
public record LatidoResponse(DateTime HoraServidor, int EventosPendientes, string? VersionDisponible);

// ──────────── Sincronizacion de catalogos ────────────

public record MarcaSyncDto(string Codigo, string? Nombre);
public record GrupoMayorSyncDto(string Codigo, string? Nombre);
public record GrupoMenorSyncDto(string Codigo, string? Nombre, string GrupoMayor);
public record IvaSyncDto(int IvaID, int IvaValor, string? Descripcion);
public record PresentacionSyncDto(string Codigo, string Presentacion, decimal? Fracciones);

// ──────────── Facturas NEXO → Visions ────────────

public record FacturaParaVisionsDto(
    int FacturaID,
    string TipDoc, string? NroDoc,
    DateTime Fecha,
    string? ClienteNit, string ClienteNombre,
    List<LineaFacturaParaVisionsDto> Lineas
);

// ──────────── Sync bidireccional articulos (Visions → NEXO) ────────────

public record SyncArticuloDesdeVisionsRequest(
    string ReferenciaVisions,
    string CentroCostoVisions,
    string? Nombre,
    decimal? Costo,
    decimal? PPublico,
    DateTime FechaCambio,
    string? MarcaCodigo = null,
    string? GrupoMenorCodigo = null,
    string? PresentacionCodigo = null,
    string? IvaSiNo = null,
    decimal? IvaValor = null,
    string? IvaDescripcion = null,
    decimal? Iva2 = null,
    string? IvaDescripcion2 = null,
    decimal? PBodega = null,
    decimal? PCredito = null,
    decimal? UPublico = null,
    decimal? UBodega = null,
    decimal? UCredito = null,
    string? TipoProductoCodigo = null,
    decimal? ExistenciasActuales = null,
    decimal? ExistenciasMinimas = null,
    decimal? Fracciones = null
);

// ──────────── Clientes para sync NEXO → Visions ────────────

public record ClienteParaSyncDto(
    int ClienteID,
    string? NIT,
    string Nombre,
    string? Telefono,
    string? Email,
    string? Direccion,
    DateTime FechaModificacion,
    string? TipoPersona,
    string? PrimerNombre, string? SegundoNombre, string? PrimerApellido, string? SegundoApellido,
    string? Departamento, string? Ciudad,
    string? TipoIdentificacionDetalle = null,
    string? NombreDept = null,
    string? NombreMuni = null,
    string? CodigoDept = null,
    string? CodigoMuni = null,
    int? DigitoVerificacion = null,
    bool Estado = true
);

public record SyncClienteDesdeVisionsRequest(
    string NIT,
    string? TipoPersona,
    string? PrimerNombre, string? SegundoNombre, string? PrimerApellido, string? SegundoApellido,
    string? NombreEmpresa,
    string? Telefono, string? Email, string? Direccion,
    string? Departamento, string? Ciudad,
    string? CodigoDept = null,
    string? CodigoMuni = null,
    int? DigitoVerificacion = null
);

// Enviado al endpoint PUT facturas/{id}/numero-visions cuando Visions asigna el número real.
public record ActualizarNumeroVisionsRequest(string TipDoc, string NroDoc);

// ──────────── Proveedores para sync NEXO → Visions ────────────
public record ProveedorParaSyncDto(
    int ProveedorID,
    string NIT,
    string RazonSocial,
    string? Contacto,
    string? Telefono,
    string? Email,
    string? Direccion,
    string? TipoPersona = null,
    string? PrimerNombre = null, string? SegundoNombre = null,
    string? PrimerApellido = null, string? SegundoApellido = null,
    string? TipoIdentificacion = null, int? DigitoVerificacion = null,
    string? Departamento = null, string? Ciudad = null,
    string? CodigoDept = null, string? CodigoMuni = null,
    string? Pais = null, string? CodigoPais = null,
    bool Estado = true
);

// ──────────── Proveedores desde Visions → NEXO ────────────
public record SyncProveedorDesdeVisionsRequest(
    string NIT,
    string RazonSocial,
    string? Telefono,
    string? Email,
    string? Direccion,
    string? TipoPersona = null,
    string? PrimerNombre = null, string? SegundoNombre = null,
    string? PrimerApellido = null, string? SegundoApellido = null,
    string? TipoIdentificacion = null, int? DigitoVerificacion = null,
    string? Departamento = null, string? Ciudad = null,
    string? CodigoDept = null, string? CodigoMuni = null
);

// ──────────── Pedidos NEXO → Visions (Entradas) ────────────

public record PedidoParaVisionsDto(
    int PedidoID,
    string Codigo,
    string TipoMovimiento,
    DateTime Fecha,
    string? ProveedorNit,
    string ProveedorNombre,
    List<LineaPedidoParaVisionsDto> Lineas
);

public record LineaPedidoParaVisionsDto(
    int Orden,
    string? ReferenciaVisions,
    string NombreArticulo,
    decimal Cantidad,
    decimal CostoUnitario
);

public record ActualizarNumeroPedidoVisionsRequest(string TipDoc, string NroDoc);

public record LineaFacturaParaVisionsDto(
    int Orden,
    string? ReferenciaVisions,
    string NombreArticulo,
    string? MarcaCodigo,
    string? GrupoMenorCodigo,
    decimal Cantidad,
    decimal PrecioUnitario,
    decimal Costo
);
public record PendienteLimpiezaVisionsDto(int LimpiezaID, string Tipo, int EntidadID);
