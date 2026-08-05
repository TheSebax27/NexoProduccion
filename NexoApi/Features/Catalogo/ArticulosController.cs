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
        // El body devuelve el ID (no solo el header Location) para que el
        // frontend pueda encadenar la subida de imagen opcional justo despues.
        return CreatedAtAction(nameof(Listar), new { ArticuloID = id }, new { articuloId = id });
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

    [HttpGet("tipos")]
    public async Task<ActionResult<IEnumerable<TipoArticuloItem>>> ListarTipos()
    {
        return Ok(await _service.ListarTiposArticuloAsync());
    }

    [HttpGet("unidades")]
    public async Task<ActionResult<IEnumerable<UnidadMedidaItem>>> ListarUnidades()
    {
        return Ok(await _service.ListarUnidadesMedidaAsync());
    }

    // ================= Imagen (opcional, una sola por articulo) =================

    // Sin [Authorize]: un <img src="..."> plano no puede mandar el header
    // Authorization, asi que este endpoint especifico queda anonimo a
    // proposito (solo sirve bytes de una foto de producto por ID, no es
    // informacion sensible). El resto de la API sigue exigiendo login.
    [HttpGet("{id:int}/imagen")]
    [AllowAnonymous]
    public async Task<IActionResult> ObtenerImagen(int id)
    {
        var imagen = await _service.ObtenerImagenArticuloAsync(id);
        if (imagen is null)
            return NotFound();

        return File(imagen.Value.Datos, imagen.Value.ContentType);
    }

    [HttpPut("{id:int}/imagen")]
    [Authorize(Roles = "Administrador,SupervisorPlanta")]
    public async Task<ActionResult> ActualizarImagen(int id, ActualizarImagenRequest request)
    {
        if (Convert.FromBase64String(request.Base64).Length > 1_000_000)
            return BadRequest(new { error = "La imagen es muy grande (máximo 1 MB)." });

        try
        {
            await _service.ActualizarImagenArticuloAsync(id, request);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { error = ex.Message });
        }
    }

    [HttpDelete("{id:int}/imagen")]
    [Authorize(Roles = "Administrador,SupervisorPlanta")]
    public async Task<ActionResult> EliminarImagen(int id)
    {
        try
        {
            await _service.EliminarImagenArticuloAsync(id);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { error = ex.Message });
        }
    }
}