using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NexoApi.Features.Catalogo.Dtos;

namespace NexoApi.Features.Catalogo;

[ApiController]
[Route("api/catalogo/articulos")]
[Authorize]
public class ArticulosController : ControllerBase
{
    private readonly ICatalogoService _service;

    public ArticulosController(ICatalogoService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ArticuloItem>>> Listar(
        [FromQuery] int? tipoArticuloId, [FromQuery] string? texto)
    {
        return Ok(await _service.ListarArticulosAsync(tipoArticuloId, texto));
    }

    [HttpPost]
    [Authorize(Roles = "Administrador,SupervisorPlanta")]
    public async Task<ActionResult> Crear(CrearArticuloRequest request)
    {
        var id = await _service.CrearArticuloAsync(request);
        return CreatedAtAction(nameof(Listar), new { ArticuloID = id });
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = "Administrador,SupervisorPlanta")]
    public async Task<ActionResult> Actualizar(int id, ActualizarArticuloRequest request)
    {
        try
        {
            await _service.ActualizarArticuloAsync(id, request);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { error = ex.Message });
        }
    }
}