using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NexoApi.Features.Recetas.Dtos;

namespace NexoApi.Features.Recetas;

[ApiController]
[Route("api/produccion/recetas")]
[Authorize]
public class RecetasController : ControllerBase
{
    private readonly IRecetasService _service;

    public RecetasController(IRecetasService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<RecetaResumen>>> Listar(
        [FromQuery] int? productoTerminadoId, [FromQuery] bool soloActivas = true)
    {
        return Ok(await _service.ListarAsync(productoTerminadoId, soloActivas));
    }

    [HttpGet("{id:int}/detalle")]
    public async Task<ActionResult<IEnumerable<RecetaDetalleItem>>> ObtenerDetalle(int id)
    {
        return Ok(await _service.ObtenerDetalleAsync(id));
    }

    [HttpPost]
    [Authorize(Roles = "Administrador,SupervisorPlanta")]
    public async Task<ActionResult> Crear(CrearRecetaRequest request)
    {
        var id = await _service.CrearAsync(request);
        return CreatedAtAction(nameof(ObtenerDetalle), new { id }, new { RecetaID = id });
    }

    /// <summary>Crea una nueva version de la receta y desactiva la anterior. La anterior nunca se borra.</summary>
    [HttpPost("{id:int}/nueva-version")]
    [Authorize(Roles = "Administrador,SupervisorPlanta")]
    public async Task<ActionResult> CrearNuevaVersion(int id, CrearNuevaVersionRequest request)
    {
        var nuevaId = await _service.CrearNuevaVersionAsync(id, request);
        return CreatedAtAction(nameof(ObtenerDetalle), new { id = nuevaId }, new { RecetaID = nuevaId });
    }
}