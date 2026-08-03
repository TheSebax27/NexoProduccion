namespace NexoApi.Features.Produccion.Dtos;

public record CrearOrdenProduccionRequest(
    string CodigoOP, int TipoProduccionID, int ProductoTerminadoID, int RecetaID,
    decimal CantidadProgramada, int? ClienteID, int CentroCostoDestinoID,
    int BodegaOrigenMPID, int BodegaDestinoPTID, int? CentroTrabajoID,
    DateTime? FechaPlanificada, string? Observaciones
);

// El codigo de la OP no se puede editar (es el identificador de negocio, igual
// que el SKU de un articulo o el codigo de un centro de costo). Solo aplica
// cuando la orden esta en estado Planificada (aun no se ha descontado stock).
public record ActualizarOrdenProduccionRequest(
    int TipoProduccionID, int ProductoTerminadoID, int RecetaID,
    decimal CantidadProgramada, int? ClienteID, int CentroCostoDestinoID,
    int BodegaOrigenMPID, int BodegaDestinoPTID, int? CentroTrabajoID,
    DateTime? FechaPlanificada, string? Observaciones
);

// Version con los IDs "crudos" (no nombres) para poder precargar el formulario
// de edicion. OrdenProduccionResumen no sirve para esto porque solo trae los
// nombres ya resueltos (Producto, CentroCosto), no los IDs de los selects.
public record OrdenProduccionDetalleEdicion(
    int OrdenProduccionID, string CodigoOP, string Estado,
    int TipoProduccionID, int ProductoTerminadoID, int RecetaID,
    decimal CantidadProgramada, int? ClienteID, int CentroCostoDestinoID,
    int BodegaOrigenMPID, int BodegaDestinoPTID, int? CentroTrabajoID,
    DateTime? FechaPlanificada, string? Observaciones
);

public record CerrarOrdenProduccionRequest(
    decimal CantidadProducidaReal, decimal HorasManoObra, decimal HorasCIF,
    string NumeroLotePT, DateTime? FechaVencimientoPT
);

public record AjustarConsumoRealRequest(
    decimal CantidadReal, int? MotivoExcesoID, string? Observacion
);

public record OrdenProduccionResumen(
    int OrdenProduccionID, string CodigoOP, string Estado, string Producto,
    string CentroCosto, decimal CantidadProgramada, decimal? CantidadProducidaReal,
    DateTime? FechaPlanificada, DateTime? FechaInicio, DateTime? FechaFin, decimal? CostoUnitarioReal
);

public record TipoProduccionItem(int TipoProduccionID, string Codigo, string Nombre);

public record ConsumoOpItem(
    long ConsumoID,
    int ArticuloID,
    string Articulo,
    decimal CantidadTeorica,
    decimal CantidadReal,
    string? MotivoExceso,
    string? Observacion
);

public record MotivoExcesoItem(int MotivoExcesoID, string Nombre);