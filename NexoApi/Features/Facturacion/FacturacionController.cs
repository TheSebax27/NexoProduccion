using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NexoApi.Features.Facturacion.Dtos;

namespace NexoApi.Features.Facturacion;

[ApiController]
[Route("api/facturacion")]
[Authorize(Roles = "Administracion,Empleados")]
public class FacturacionController : ControllerBase
{
    private readonly IFacturacionService _service;

    public FacturacionController(IFacturacionService service)
    {
        _service = service;
    }

    private int UsuarioActualId =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    [HttpGet("facturas")]
    public async Task<ActionResult<IEnumerable<FacturaItem>>> ListarFacturas([FromQuery] int? clienteId, [FromQuery] string? estado)
        => Ok(await _service.ListarFacturasAsync(clienteId, estado));

    [HttpPost("facturas")]
    public async Task<ActionResult> CrearFactura(CrearFacturaRequest request)
    {
        try
        {
            var id = await _service.CrearFacturaAsync(request, UsuarioActualId);
            return Ok(new { facturaId = id });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpGet("facturas/{id:int}/lineas")]
    public async Task<ActionResult<IEnumerable<FacturaLineaItem>>> ListarLineas(int id)
        => Ok(await _service.ListarLineasAsync(id));

    [HttpGet("facturas/{id:int}/stock-lineas")]
    public async Task<ActionResult<IEnumerable<FacturaLineaStockItem>>> ObtenerStockLineas(int id)
        => Ok(await _service.ObtenerStockLineasAsync(id));

    [HttpPost("facturas/{id:int}/descontar-stock")]
    public async Task<ActionResult> DescontarStock(int id)
    {
        try
        {
            await _service.DescontarStockAsync(id, UsuarioActualId);
            return NoContent();
        }
        catch (KeyNotFoundException ex) { return NotFound(new { error = ex.Message }); }
        catch (InvalidOperationException ex) { return Conflict(new { error = ex.Message }); }
    }

    [HttpGet("facturas/{id:int}/pagos")]
    public async Task<ActionResult<IEnumerable<PagoItem>>> ListarPagos(int id)
        => Ok(await _service.ListarPagosAsync(id));

    [HttpPost("pagos")]
    public async Task<ActionResult> CrearPago(CrearPagoRequest request)
    {
        try
        {
            var id = await _service.CrearPagoAsync(request, UsuarioActualId);
            return Ok(new { pagoId = id });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
}
