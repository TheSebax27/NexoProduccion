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
    decimal? StockMinimoArticulo
);

// NombreArticuloVisions/CostoArticuloVisions/PrecioArticuloVisions: datos del
// articulo tal como los tiene Visions en dbo.TARJETA al momento de la venta.
// Se mandan siempre (el agente ya tiene esa fila a la mano en TareaExportarVentas)
// para que, si resulta que el articulo no esta mapeado en NEXO todavia, sirvan
// de sugerencia en la pantalla de "Articulos pendientes de mapeo" -- evita que
// el Administrador tenga que ir a Visions a averiguar nombre/costo/precio.
public record RegistrarEventoEntranteRequest(
    string IdEventoExterno,
    string TipoEvento,
    string CodigoArticuloVisions,
    decimal Cantidad,
    DateTime FechaEventoOrigen,
    string? NombreArticuloVisions,
    decimal? CostoArticuloVisions,
    decimal? PrecioArticuloVisions
);

// Configuracion que el Agente de Sincronizacion lee de NEXO y aplica en la
// base de Visions del cliente (NEXO_ConfiguracionSync), para que esos valores
// solo se puedan editar desde la web de NEXO (Catalogo > Centros de Costo)
// y no directo por SQL contra la base de Visions.
// CentroCostoVisions es el codigo CENTROCOSTO (smallint) DENTRO de la base de
// Visions de este cliente -- NO el CentroCostoID interno de NEXO (son cosas
// distintas: un mismo Visions puede compartir varias sucursales/CENTROCOSTO
// en una sola base, cada una mapeada a su propio Centro de Costo en NEXO).
public record ConfiguracionAgenteResponse(int? CentroCostoVisions, bool Activo, string? PrefijosDocumentoVenta);

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
// Visions, pero el Administrador los puede editar antes de confirmar) y
// LUEGO se mapea. Nombre/PrecioVenta/StockMinimo solo se usan si se crea nuevo.
public record ResolverArticuloPendienteRequest(
    int? ArticuloIDExistente,
    string? SkuNuevo, string? NombreNuevo, decimal? PrecioVentaNuevo, decimal? StockMinimoNuevo
);