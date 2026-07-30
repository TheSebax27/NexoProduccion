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