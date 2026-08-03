namespace NexoWeb.Common.Dtos;

public record OrdenProduccionResumen(
    int OrdenProduccionID,
    string CodigoOP,
    string Estado,
    string Producto,
    string CentroCosto,
    decimal CantidadProgramada,
    decimal? CantidadProducidaReal,
    DateTime? FechaPlanificada,
    DateTime? FechaInicio,
    DateTime? FechaFin,
    decimal? CostoUnitarioReal
);

public record CerrarOrdenProduccionRequest(
    decimal CantidadProducidaReal,
    decimal HorasManoObra,
    decimal HorasCIF,
    string NumeroLotePT,
    DateTime? FechaVencimientoPT
);

// Agregar a Common/Dtos/ProduccionDtos.cs
public record TipoProduccionItem(int TipoProduccionID, string Codigo, string Nombre);

public record RecetaResumen(
    int RecetaID, string ProductoTerminado, string NombreReceta, int Version,
    decimal CantidadRendimientoBase, string UnidadRendimiento, bool Estado
);

public record CrearOrdenProduccionRequest(
    string CodigoOP, int TipoProduccionID, int ProductoTerminadoID, int RecetaID,
    decimal CantidadProgramada, int? ClienteID, int CentroCostoDestinoID,
    int BodegaOrigenMPID, int BodegaDestinoPTID, int? CentroTrabajoID,
    DateTime? FechaPlanificada, string? Observaciones
);

// Solo aplica cuando la orden esta en estado Planificada; el codigo de la OP
// no se puede editar (es el identificador de negocio).
public record ActualizarOrdenProduccionRequest(
    int TipoProduccionID, int ProductoTerminadoID, int RecetaID,
    decimal CantidadProgramada, int? ClienteID, int CentroCostoDestinoID,
    int BodegaOrigenMPID, int BodegaDestinoPTID, int? CentroTrabajoID,
    DateTime? FechaPlanificada, string? Observaciones
);

// IDs crudos (no nombres) para precargar el formulario de edicion.
public record OrdenProduccionDetalleEdicion(
    int OrdenProduccionID, string CodigoOP, string Estado,
    int TipoProduccionID, int ProductoTerminadoID, int RecetaID,
    decimal CantidadProgramada, int? ClienteID, int CentroCostoDestinoID,
    int BodegaOrigenMPID, int BodegaDestinoPTID, int? CentroTrabajoID,
    DateTime? FechaPlanificada, string? Observaciones
);

public record RecetaDetalleItem(
    int RecetaDetalleID,
    int InsumoID,
    string Insumo,
    decimal CantidadRequerida,
    string Unidad,
    decimal PorcentajeMermaEstandar,
    int? CentroTrabajoID,
    int Orden
);

public record DetalleRecetaRequest(
    int InsumoID,
    decimal CantidadRequerida,
    int UnidadID,
    decimal PorcentajeMermaEstandar,
    int? CentroTrabajoID,
    int Orden
);

public record CrearRecetaRequest(
    int ProductoTerminadoID,
    string NombreReceta,
    decimal CantidadRendimientoBase,
    int UnidadRendimientoID,
    List<DetalleRecetaRequest> Detalle
);

public record CrearNuevaVersionRequest(
    string NombreReceta,
    decimal CantidadRendimientoBase,
    int UnidadRendimientoID,
    List<DetalleRecetaRequest> Detalle
);

public record ConsumoOpItem(
    long ConsumoID, int ArticuloID, string Articulo,
    decimal CantidadTeorica, decimal CantidadReal,
    string? MotivoExceso, string? Observacion
);

public record MotivoExcesoItem(int MotivoExcesoID, string Nombre);

public record AjustarConsumoRealRequest(decimal CantidadReal, int? MotivoExcesoID, string? Observacion);