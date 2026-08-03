using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NexoApi.Features.Dashboard.Dtos;

namespace NexoApi.Features.Dashboard;

[ApiController]
[Route("api/dashboard")]
[Authorize(Roles = "Administrador,SupervisorPlanta,Bodeguero")]
public class DashboardController : ControllerBase
{
    private readonly IDashboardService _service;

    public DashboardController(IDashboardService service)
    {
        _service = service;
    }

    [HttpGet("plan-vs-real")]
    public async Task<ActionResult<IEnumerable<PlanVsRealPunto>>> PlanVsReal(
        [FromQuery] DateTime? desde, [FromQuery] DateTime? hasta)
    {
        var hastaFinal = hasta ?? DateTime.Today;
        var desdeFinal = desde ?? hastaFinal.AddDays(-14);
        return Ok(await _service.ObtenerPlanVsRealAsync(desdeFinal, hastaFinal));
    }

    [HttpGet("distribucion-centro-costo")]
    public async Task<ActionResult<IEnumerable<DistribucionCentroCostoItem>>> DistribucionCentroCosto()
        => Ok(await _service.ObtenerDistribucionCentroCostoAsync());

    [HttpGet("perdidas-por-motivo")]
    public async Task<ActionResult<IEnumerable<PerdidaPorMotivoItem>>> PerdidasPorMotivo(
        [FromQuery] DateTime? desde, [FromQuery] DateTime? hasta)
    {
        var hastaFinal = hasta ?? DateTime.Today;
        var desdeFinal = desde ?? hastaFinal.AddDays(-30);
        return Ok(await _service.ObtenerPerdidasPorMotivoAsync(desdeFinal, hastaFinal));
    }

    [HttpGet("tendencia-costo")]
    public async Task<ActionResult<IEnumerable<TendenciaCostoPunto>>> TendenciaCosto([FromQuery] int articuloId)
        => Ok(await _service.ObtenerTendenciaCostoAsync(articuloId));

    [HttpGet("cumplimiento-planificacion")]
    public async Task<ActionResult<IEnumerable<CumplimientoCentroCostoItem>>> CumplimientoPlanificacion()
        => Ok(await _service.ObtenerCumplimientoAsync());
}