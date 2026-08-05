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
    decimal? StockMinimoArticulo
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
    decimal? PrecioArticuloVisions
);

// Configuracion que el Administrador dejo en NEXO Web (Catalogo > Centros de
// Costo) y que este agente aplica en la base de Visions local -- asi esos
// valores nunca se editan directo por SQL contra Visions.
// CentroCostoVisions es el codigo CENTROCOSTO real dentro de la base de
// Visions (puede ser null si el Administrador aun no lo configuro en NEXO).
public record ConfiguracionAgenteResponse(int? CentroCostoVisions, bool Activo, string? PrefijosDocumentoVenta);