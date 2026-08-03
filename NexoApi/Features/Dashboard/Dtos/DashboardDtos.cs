namespace NexoApi.Features.Dashboard.Dtos;

public record PlanVsRealPunto(DateTime Fecha, decimal TotalPlanificado, decimal TotalReal);

public record DistribucionCentroCostoItem(
    int CentroCostoID, string CentroCosto, int TotalOrdenes, decimal TotalUnidadesProducidas, decimal InversionTotal
);

public record PerdidaPorMotivoItem(string Motivo, decimal CantidadTotalPerdida, decimal ValorTotalPerdido);

public record TendenciaCostoPunto(DateTime Fecha, decimal CostoUnitarioReal);

public record CumplimientoCentroCostoItem(
    int CentroCostoID,
    string CentroCosto,
    int TotalOrdenesFinalizadas,
    int OrdenesATiempo,
    decimal PorcentajeCumplimiento
);