using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NexoApi.Features.Compras.Dtos;

namespace NexoApi.Features.Compras;

[ApiController]
[Route("api/compras/ordenes")]
[Authorize]
public class OrdenesCompraController : ControllerBase
{
    private readonly IOrdenesCompraService _service;

    public OrdenesCompraController(IOrdenesCompraService service)
    {
        _service = service;
    }

    private int UsuarioActualId =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    [HttpGet]
    public async Task<ActionResult<IEnumerable<OrdenCompraResumen>>> Listar([FromQuery] string? estado)
    {
        var ordenes = await _service.ListarAsync(estado);
        return Ok(ordenes);
    }

    [HttpGet("{id:int}/detalle")]
    public async Task<ActionResult<IEnumerable<OrdenCompraDetalleItem>>> ObtenerDetalle(int id)
    {
        var detalle = await _service.ObtenerDetalleAsync(id);
        return Ok(detalle);
    }

    [HttpPost]
    [Authorize]
    public async Task<ActionResult> Crear(CrearOrdenCompraRequest request)
    {
        var id = await _service.CrearAsync(request, UsuarioActualId);
        return CreatedAtAction(nameof(ObtenerDetalle), new { id }, new { OrdenCompraID = id });
    }

    /// <summary>Recibe (total o parcialmente) una linea especifica de la orden de compra.</summary>
    [HttpPost("detalle/{ordenCompraDetalleId:int}/recibir")]
    [Authorize]
    public async Task<ActionResult> RecibirLinea(int ordenCompraDetalleId, RecibirLineaOrdenCompraRequest request)
    {
        var (loteId, nuevoCostoPromedio) = await _service.RecibirLineaAsync(ordenCompraDetalleId, request, UsuarioActualId);
        return Ok(new { mensaje = "Mercancia recibida.", loteId, nuevoCostoPromedio });
    }

    [HttpGet("comparacion-precios")]
    public async Task<ActionResult<IEnumerable<ComparacionPrecioRow>>> ComparacionPrecios(
        [FromQuery] int? articuloId,
        [FromQuery] int? proveedorId)
        => Ok(await _service.ComparacionPreciosAsync(articuloId, proveedorId));

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Eliminar(int id)
    {
        try
        {
            await _service.EliminarOrdenCompraAsync(id);
            return NoContent();
        }
        catch (KeyNotFoundException ex) { return NotFound(ex.Message); }
        catch (InvalidOperationException ex) { return BadRequest(ex.Message); }
    }
}