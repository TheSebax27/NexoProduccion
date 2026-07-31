namespace NexoApi.Features.Recetas.Dtos;

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

public record RecetaResumen(
    int RecetaID,
    string ProductoTerminado,
    string NombreReceta,
    int Version,
    decimal CantidadRendimientoBase,
    string UnidadRendimiento,
    bool Estado
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