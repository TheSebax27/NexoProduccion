namespace NexoApi.Features.Crm.Dtos;

// Clientes -- movido desde Features/Catalogo (agosto 2026), ahora con campos
// de seguimiento comercial (FuenteContacto, TipoCliente) y, agosto 2026 (v2),
// Responsable comercial + Proximo Contacto. El campo "Contacto" (texto suelto)
// se mantiene por compatibilidad pero la UI nueva usa Crm.Contactos (multiples
// contactos por cliente) en su lugar.
public record ClienteItem(
    int ClienteID, string Nombre, string? NIT, string? Contacto,
    string? Telefono, string? Email, string? Direccion, bool Estado,
    string? FuenteContacto, string? TipoCliente,
    int? ResponsableID, string? Responsable, DateTime? ProximoContacto,
    int TotalContactos, DateTime? UltimaInteraccion
);

public record CrearClienteRequest(
    string Nombre, string? NIT, string? Telefono, string? Email, string? Direccion,
    string? FuenteContacto, string? TipoCliente, int? ResponsableID
);

public record ActualizarClienteRequest(
    string Nombre, string? NIT, string? Telefono, string? Email, string? Direccion, bool Estado,
    string? FuenteContacto, string? TipoCliente, int? ResponsableID, DateTime? ProximoContacto
);

// Bitacora de interacciones -- llamadas, correos, reuniones con un cliente.
public record InteraccionItem(
    long InteraccionID, int ClienteID, string Tipo, string Notas, DateTime Fecha, string? Usuario
);

public record CrearInteraccionRequest(int ClienteID, string Tipo, string Notas, DateTime? ProximoContacto);

// ---------- A) Multiples contactos por cliente ----------
public record ContactoItem(int ContactoID, int ClienteID, string Nombres, string? Cargo, string? Telefono, string? Email, bool EsPrincipal, bool Estado);
public record CrearContactoRequest(int ClienteID, string Nombres, string? Cargo, string? Telefono, string? Email, bool EsPrincipal);
public record ActualizarContactoRequest(string Nombres, string? Cargo, string? Telefono, string? Email, bool EsPrincipal, bool Estado);

// ---------- C) Historial unificado ----------
// TipoEvento: INTERACCION / PEDIDO / DESPACHO -- un timeline con todo lo que
// ha pasado con el cliente, cruzando Crm + Produccion + Logistica.
public record EventoHistorialItem(string TipoEvento, DateTime Fecha, string Titulo, string? Detalle);

// ---------- E) Documentos adjuntos ----------
public record ClienteDocumentoItem(int DocumentoID, int ClienteID, string TipoDocumento, string NombreArchivo, string ContentType, DateTime FechaSubida);
public record SubirDocumentoRequest(string TipoDocumento, string NombreArchivo, string ContentType, string Base64);

// ---------- Leads (prospectos, distinto de Clientes) ----------
public record LeadItem(
    int LeadID, string Nombre, string? Empresa, string? Telefono, string? Email,
    string? FuenteContacto, string Etapa, string? Notas,
    int? ResponsableID, string? Responsable, int? ClienteIDConvertido,
    DateTime FechaCreacion, DateTime? FechaConversion
);
public record CrearLeadRequest(string Nombre, string? Empresa, string? Telefono, string? Email, string? FuenteContacto, string? Notas, int? ResponsableID);
public record ActualizarLeadRequest(string Nombre, string? Empresa, string? Telefono, string? Email, string? FuenteContacto, string Etapa, string? Notas, int? ResponsableID);
public record ConvertirLeadResponse(int ClienteId);

// ---------- D) Clientes fríos (BI / alertas internas) ----------
public record ClienteFrioItem(int ClienteID, string Nombre, string? Responsable, DateTime? UltimaInteraccion, DateTime? ProximoContacto);

// ---------- Oportunidades (embudo de ventas, agosto 2026) ----------
// Origen: un Lead sin convertir aun, o un Cliente ya existente -- al menos
// uno de los dos debe venir informado (CK_Oportunidades_OrigenRequerido en BD).
public record OportunidadItem(
    int OportunidadID, int? LeadID, string? Lead, int? ClienteID, string? Cliente,
    string Nombre, decimal ValorEstimado, int Probabilidad, string Etapa,
    DateTime? FechaCierreEsperada, int? ResponsableID, string? Responsable, string? Notas,
    DateTime FechaCreacion, DateTime? FechaCierre
);
public record CrearOportunidadRequest(
    int? LeadID, int? ClienteID, string Nombre, decimal ValorEstimado, int Probabilidad,
    DateTime? FechaCierreEsperada, int? ResponsableID, string? Notas
);
public record ActualizarOportunidadRequest(
    string Nombre, decimal ValorEstimado, int Probabilidad, string Etapa,
    DateTime? FechaCierreEsperada, int? ResponsableID, string? Notas
);

// ---------- Cotizaciones (agosto 2026) ----------
public record LineaCotizacionInput(int ArticuloID, decimal Cantidad, decimal PrecioUnitario);
public record CotizacionItem(
    int CotizacionID, int ClienteID, string Cliente, int? OportunidadID, DateTime Fecha,
    DateTime? ValidoHasta, string Estado, string? Notas, int? FacturaID, decimal Total
);
public record CrearCotizacionRequest(int ClienteID, int? OportunidadID, DateTime Fecha, DateTime? ValidoHasta, string? Notas, List<LineaCotizacionInput> Lineas);
public record ActualizarEstadoCotizacionRequest(string Estado);
public record CotizacionLineaItem(int LineaID, int CotizacionID, int ArticuloID, string SkuArticulo, string NombreArticulo, decimal Cantidad, decimal PrecioUnitario, decimal Subtotal);
public record ConvertirCotizacionResponse(int FacturaId);
