namespace NexoWeb.Common.Dtos;

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

public record InteraccionItem(long InteraccionID, int ClienteID, string Tipo, string Notas, DateTime Fecha, string? Usuario);
public record CrearInteraccionRequest(int ClienteID, string Tipo, string Notas, DateTime? ProximoContacto);

public record ContactoItem(int ContactoID, int ClienteID, string Nombres, string? Cargo, string? Telefono, string? Email, bool EsPrincipal, bool Estado);
public record CrearContactoRequest(int ClienteID, string Nombres, string? Cargo, string? Telefono, string? Email, bool EsPrincipal);
public record ActualizarContactoRequest(string Nombres, string? Cargo, string? Telefono, string? Email, bool EsPrincipal, bool Estado);

public record EventoHistorialItem(string TipoEvento, DateTime Fecha, string Titulo, string? Detalle);

public record ClienteDocumentoItem(int DocumentoID, int ClienteID, string TipoDocumento, string NombreArchivo, string ContentType, DateTime FechaSubida);
public record SubirDocumentoRequest(string TipoDocumento, string NombreArchivo, string ContentType, string Base64);

public record LeadItem(
    int LeadID, string Nombre, string? Empresa, string? Telefono, string? Email,
    string? FuenteContacto, string Etapa, string? Notas,
    int? ResponsableID, string? Responsable, int? ClienteIDConvertido,
    DateTime FechaCreacion, DateTime? FechaConversion
);
public record CrearLeadRequest(string Nombre, string? Empresa, string? Telefono, string? Email, string? FuenteContacto, string? Notas, int? ResponsableID);
public record ActualizarLeadRequest(string Nombre, string? Empresa, string? Telefono, string? Email, string? FuenteContacto, string Etapa, string? Notas, int? ResponsableID);
public record ConvertirLeadResponse(int ClienteId);

public record ClienteFrioItem(int ClienteID, string Nombre, string? Responsable, DateTime? UltimaInteraccion, DateTime? ProximoContacto);

// ---------- Oportunidades (embudo de ventas, agosto 2026) ----------
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
