namespace NexoWeb.Common.Dtos;

public record EmpleadoItem(
    int EmpleadoID, string Nombres, string Apellidos,
    int? CargoID, string? Cargo, int? DepartamentoID, string? Departamento,
    int? CentroCostoID, string? CentroCosto, DateTime? FechaIngreso,
    string? Telefono, string? Email, bool Estado, bool TieneFoto,
    int? JefeDirectoID, string? JefeDirecto
);

public record CrearEmpleadoRequest(
    string Nombres, string Apellidos, int? CargoID, int? CentroCostoID,
    DateTime? FechaIngreso, string? Telefono, string? Email, int? JefeDirectoID
);

public record ActualizarEmpleadoRequest(
    string Nombres, string Apellidos, int? CargoID, int? CentroCostoID,
    DateTime? FechaIngreso, string? Telefono, string? Email, bool Estado, int? JefeDirectoID
);

public record ActualizarFotoEmpleadoRequest(string Base64, string ContentType);
public record CrearEmpleadoResponse(int EmpleadoId);

// Lo que cierra EmpleadoDialog: la solicitud de crear/actualizar de siempre,
// mas la foto opcional (mismo patron que ArticuloDialogResultado).
public record EmpleadoDialogResultado(object Datos, string? FotoBase64, string? FotoContentType);

// ---------- Departamentos y Cargos (agosto 2026, RRHH v2) ----------

public record DepartamentoItem(int DepartamentoID, string Nombre, bool Estado, int TotalCargos);
public record CrearDepartamentoRequest(string Nombre);
public record ActualizarDepartamentoRequest(string Nombre, bool Estado);

public record CargoItem(int CargoID, string Nombre, int? DepartamentoID, string? Departamento, bool Estado);
public record CrearCargoRequest(string Nombre, int? DepartamentoID);
public record ActualizarCargoRequest(string Nombre, int? DepartamentoID, bool Estado);

// ---------- Historial laboral (agosto 2026, RRHH v2) ----------

public record HistorialLaboralItem(
    int HistorialID, int EmpleadoID, string TipoEvento,
    string? ValorAnterior, string? ValorNuevo, DateTime Fecha, string? Notas, string? Usuario
);

// ---------- Documentos de empleado (agosto 2026, RRHH v2) ----------

public record EmpleadoDocumentoItem(int DocumentoID, int EmpleadoID, string TipoDocumento, string NombreArchivo, string ContentType, DateTime FechaSubida);
public record SubirDocumentoEmpleadoRequest(string TipoDocumento, string NombreArchivo, string ContentType, string Base64);

// ---------- Ausencias y Vacaciones (agosto 2026, RRHH v2) ----------

public record AusenciaItem(
    int AusenciaID, int EmpleadoID, string Empleado, string Tipo,
    DateTime FechaInicio, DateTime FechaFin, string? Motivo, string Estado, DateTime FechaCreacion
);
public record CrearAusenciaRequest(int EmpleadoID, string Tipo, DateTime FechaInicio, DateTime FechaFin, string? Motivo);
public record ActualizarEstadoAusenciaRequest(string Estado);

// ---------- Evaluaciones de desempeño (agosto 2026, RRHH v2) ----------

public record EvaluacionItem(
    int EvaluacionID, int EmpleadoID, int? ResponsableID, string? Responsable,
    DateTime Fecha, decimal Calificacion, string? Comentarios
);
public record CrearEvaluacionRequest(int EmpleadoID, int? ResponsableID, DateTime Fecha, decimal Calificacion, string? Comentarios);

// ---------- Capacitaciones (agosto 2026, RRHH v2) ----------

public record CapacitacionItem(
    int CapacitacionID, int EmpleadoID, string Nombre, string? Institucion,
    DateTime FechaRealizacion, DateTime? FechaVencimiento
);
public record CrearCapacitacionRequest(int EmpleadoID, string Nombre, string? Institucion, DateTime FechaRealizacion, DateTime? FechaVencimiento);

// ---------- Organigrama (agosto 2026, RRHH v2) ----------

public record OrganigramaNodo(int EmpleadoID, string Nombres, string Apellidos, string? Cargo, int? JefeDirectoID);
