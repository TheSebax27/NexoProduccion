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
    string? MarcaCodigo
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
    string? ClienteNombre
);

// Configuracion que el Administrador dejo en NEXO Web (Catalogo > Centros de
// Costo) y que este agente aplica en la base de Visions local -- asi esos
// valores nunca se editan directo por SQL contra Visions.
// CentroCostoVisions es el codigo CENTROCOSTO real dentro de la base de
// Visions (puede ser null si el Administrador aun no lo configuro en NEXO).
// IntervalMinutes viene de la BD de NEXO -- el admin lo cambia desde la web
// sin necesidad de tocar appsettings.json en el servidor de Visions.
public record ConfiguracionAgenteResponse(int? CentroCostoVisions, bool Activo, string? PrefijosDocumentoVenta, int IntervalMinutes);

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
    DateTime FechaCambio
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
    string? Departamento, string? Ciudad
);

public record SyncClienteDesdeVisionsRequest(
    string NIT,
    string? TipoPersona,
    string? PrimerNombre, string? SegundoNombre, string? PrimerApellido, string? SegundoApellido,
    string? NombreEmpresa,
    string? Telefono, string? Email, string? Direccion,
    string? Departamento, string? Ciudad
);

// Enviado al endpoint PUT facturas/{id}/numero-visions cuando Visions asigna el número real.
public record ActualizarNumeroVisionsRequest(string TipDoc, string NroDoc);

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