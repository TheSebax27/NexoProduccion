using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NexoApi.Features.Operaciones.Dtos;

namespace NexoApi.Features.Operaciones;

[ApiController]
[Route("api/operaciones")]
[Authorize(Roles = "Administracion,Empleados")]
public class OperacionesController : ControllerBase
{
    private readonly IOperacionesService _svc;

    public OperacionesController(IOperacionesService svc) => _svc = svc;

    [HttpGet("movimientos")]
    public async Task<IActionResult> ListarMovimientos(
        [FromQuery] DateTime? desde,
        [FromQuery] DateTime? hasta,
        [FromQuery] string? tipo)
    {
        var filtro = new MovimientosFiltro(desde, hasta, tipo?.ToUpperInvariant());
        var items = await _svc.ListarMovimientosAsync(filtro);
        return Ok(items);
    }
}
