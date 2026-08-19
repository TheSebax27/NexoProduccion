namespace NexoApi.Features.Integracion.Dtos;

// Nombre/PrecioVentaArticulo/StockMinimoArticulo solo aplican al TipoEvento
// 'SINCRONIZAR_ARTICULO' (crear/actualizar el articulo en Visions) -- en los
// demas tipos de evento (entradas de inventario) van en null, se ignoran.
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

// NombreArticuloVisions/CostoArticuloVisions/PrecioArticuloVisions: datos del
// articulo tal como los tiene Visions en dbo.TARJETA al momento de la venta.
// Se mandan siempre (el agente ya tiene esa fila a la mano en TareaExportarVentas)
// para que, si resulta que el articulo no esta mapeado en NEXO todavia, sirvan
// de sugerencia en la pantalla de "Articulos pendientes de mapeo" -- evita que
// el Administracion tenga que ir a Visions a averiguar nombre/costo/precio.
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

// Configuracion que el Agente de Sincronizacion lee de NEXO y aplica en la
// base de Visions del cliente (NEXO_ConfiguracionSync), para que esos valores
// solo se puedan editar desde la web de NEXO (Catalogo > Centros de Costo)
// y no directo por SQL contra la base de Visions.
// CentroCostoVisions es el codigo CENTROCOSTO (smallint) DENTRO de la base de
// Visions de este cliente -- NO el CentroCostoID interno de NEXO (son cosas
// distintas: un mismo Visions puede compartir varias sucursales/CENTROCOSTO
// en una sola base, cada una mapeada a su propio Centro de Costo en NEXO).
public record ConfiguracionAgenteResponse(int? CentroCostoVisions, bool Activo, string? PrefijosDocumentoVenta, int IntervalMinutes);

// ---------- Configuracion completa del agente (solo Administracion, desde la web) ----------

public record ConfiguracionAgenteCompletaResponse(
    int AgenteSyncID,
    string? Descripcion,
    int CentroCostoID,
    string NombreCentroCosto,
    bool Activo,
    string? VisionsDbConexion,
    string? NexoApiBaseUrl,
    int IntervalMinutes,
    int IntervalSeconds,
    string? AgentePath,
    string? PrefijosDocumentoVenta
);

public record ActualizarConfiguracionAgenteRequest(
    string? VisionsDbConexion,
    string? NexoApiBaseUrl,
    int IntervalMinutes,
    int IntervalSeconds,
    string? AgentePath,
    string? PrefijosDocumentoVenta
);

public record GenerarApiKeyRequest(int CentroCostoID, string Descripcion);

// El ApiKey en texto plano SOLO viaja aqui, esta unica vez. Despues de esto,
// ni siquiera nosotros podemos volver a verlo (solo tenemos el hash guardado).
public record GenerarApiKeyResponse(int AgenteSyncID, string ApiKey);

// ---------- Mapeo de Articulos (NEXO <-> Visions) ----------

public record MapeoArticuloItem(
    int MapeoID, int ArticuloID, string SkuArticulo, string NombreArticulo,
    int CentroCostoID, string CodigoArticuloVisions, bool Estado, DateTime FechaCreacion
);

public record CrearMapeoArticuloRequest(int ArticuloID, int CentroCostoID, string CodigoArticuloVisions);

// ---------- Articulos pendientes de mapeo (vendidos en Visions, sin mapear) ----------

public record ArticuloPendienteMapeoItem(
    int PendienteID, int CentroCostoID, string CodigoArticuloVisions,
    string? NombreVisions, decimal? CostoVisions, decimal? PrecioVisions,
    decimal CantidadDetectada, DateTime FechaDetectado
);

// Si ArticuloIDExistente viene informado, solo se crea el mapeo hacia ese
// articulo. Si viene null, se crea un articulo NUEVO de tipo Producto
// Terminado con los datos dados (normalmente precargados con lo que sugirio
// Visions, pero el Administracion los puede editar antes de confirmar) y
// LUEGO se mapea. Nombre/PrecioVenta/StockMinimo solo se usan si se crea nuevo.
public record ResolverArticuloPendienteRequest(
    int? ArticuloIDExistente,
    string? SkuNuevo, string? NombreNuevo, decimal? PrecioVentaNuevo, decimal? StockMinimoNuevo
);

// ---------- Latido / monitoreo del agente ----------

// Respuesta al POST /latido -- confirma que la API recibio el heartbeat.
// HoraServidor permite al agente detectar desfase de reloj entre maquinas.
public record LatidoRequest(string? Version);
public record LatidoResponse(DateTime HoraServidor, int EventosPendientes, string VersionDisponible);

// Respuesta del GET /estado -- usada por NexoWeb para el panel de monitoreo.
public record EstadoIntegracionResponse(
    int AgenteSyncID,
    string Descripcion,
    int CentroCostoID,
    string NombreCentroCosto,
    bool Activo,
    DateTime? UltimoLatido,
    string? VersionAgente,
    string? VersionDisponible,
    int EventosPendientes,
    int EventosProcesadosHoy,
    int VentasImportadasHoy,
    int EventosConError
);

// Enviado por el Agente cuando no puede aplicar un evento en Visions.
// Tras 3 intentos fallidos el evento pasa a ERROR y deja de reintentarse.
public record RegistrarFalloRequest(string MensajeError);

// ──────────── Actividad detallada del agente (panel de administración) ────────────

public record EventoActividadItem(
    long EventoID,
    string TipoEvento,
    string Estado,
    string? ReferenciaVisions,
    string? NombreArticulo,
    decimal Cantidad,
    string? MensajeError,
    DateTime FechaCreacion,
    DateTime? FechaEnvio
);

public record ActividadAgenteResponse(
    int ArticulosEnlazados,
    int FacturasHoy,
    int ComprasHoy,
    int AjustesHoy,
    List<EventoActividadItem> UltimosEventos,
    // Catálogo — totales globales en NEXO
    int TotalArticulos,
    int TotalMarcas,
    int TotalGruposMayor,
    int TotalGruposMenor,
    int TotalClientes,
    // Sync hoy por dirección
    int FacturasNexoVisionsHoy,   // NEXO → Visions (FACTURA_NEXO confirmadas)
    int VentasVisionsNexoHoy      // Visions → NEXO (EventosEntrantes procesados)
);

// ──────────── Sincronizacion de catalogos (agente ↔ Visions) ────────────

public record MarcaSyncItem(string Codigo, string? Nombre);
public record GrupoMayorSyncItem(string Codigo, string? Nombre);
public record GrupoMenorSyncItem(string Codigo, string? Nombre, string GrupoMayor);
public record IvaSyncItem(int IvaID, int IvaValor, string? Descripcion);
public record PresentacionSyncItem(string Codigo, string Presentacion, decimal? Fracciones);

// ──────────── Facturas NEXO → Visions ────────────

public record FacturaParaVisionsItem(
    int FacturaID,
    string TipDoc, string? NroDoc,
    DateTime Fecha,
    string? ClienteNit, string ClienteNombre,
    List<LineaFacturaParaVisionsItem> Lineas
);

public record LineaFacturaParaVisionsItem(
    int Orden,
    string? ReferenciaVisions,
    string NombreArticulo,
    string? MarcaCodigo,
    string? GrupoMenorCodigo,
    decimal Cantidad,
    decimal PrecioUnitario,
    decimal Costo
);

// ──────────── Sync bidireccional articulos (Visions → NEXO) ────────────

// Enviado por el agente cuando detecta un cambio en TARJETA de Visions.
// La API compara FechaCambio con Catalogo.Tarjetas.FechaModificacion y
// solo aplica si Visions es mas reciente (+ 5s de margen) para no
// sobreescribir cambios que el Admin acaba de hacer en NEXO.
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

// ──────────── Actualización número de factura desde Visions ────────────
// El agente llama este endpoint cuando Visions asigna el número real a
// una factura que fue exportada con un placeholder NEXO-{FacturaID}.
public record ActualizarNumeroVisionsRequest(string TipDoc, string NroDoc);

// ──────────── Clientes desde Visions → NEXO ────────────
// Enviado por el agente cuando lee dbo.USUARIOS de Visions.
public record SyncClienteDesdeVisionsRequest(
    string NIT,
    string? TipoPersona,
    string? PrimerNombre, string? SegundoNombre, string? PrimerApellido, string? SegundoApellido,
    string? NombreEmpresa,
    string? Telefono, string? Email, string? Direccion,
    string? Departamento, string? Ciudad
);