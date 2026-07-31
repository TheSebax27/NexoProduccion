namespace NexoApi.Features.Produccion.Dtos;

public record CrearOrdenProduccionRequest(
    string CodigoOP, int TipoProduccionID, int ProductoTerminadoID, int RecetaID,
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