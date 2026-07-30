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
    public async Task<ActionResult<IEnumerable<PlanVsRealPunto>>> PlanVsReal([FromQuery] int dias = 14)
        => Ok(await _service.ObtenerPlanVsRealAsync(dias));

    [HttpGet("distribucion-centro-costo")]
    public async Task<ActionResult<IEnumerable<DistribucionCentroCostoItem>>> DistribucionCentroCosto()
        => Ok(await _service.ObtenerDistribucionCentroCostoAsync());

    [HttpGet("perdidas-por-motivo")]
    public async Task<ActionResult<IEnumerable<PerdidaPorMotivoItem>>> PerdidasPorMotivo([FromQuery] int dias = 30)
        => Ok(await _service.ObtenerPerdidasPorMotivoAsync(dias));

    [HttpGet("tendencia-costo")]
    public async Task<ActionResult<IEnumerable<TendenciaCostoPunto>>> TendenciaCosto([FromQuery] int articuloId)
        => Ok(await _service.ObtenerTendenciaCostoAsync(articuloId));
}