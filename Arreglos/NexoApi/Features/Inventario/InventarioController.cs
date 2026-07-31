// Features/Inventario/InventarioController.cs
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NexoApi.Features.Inventario.Dtos;

namespace NexoApi.Features.Inventario;

[ApiController]
[Route("api/inventario")]
[Authorize]
public class InventarioController : ControllerBase
{
    private readonly IInventarioService _service;

    public InventarioController(IInventarioService service)
    {
        _service = service;
    }

    private int UsuarioActualId =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    /// <summary>Consulta el stock consolidado, con filtros opcionales.</summary>
    [HttpGet("stock")]
    public async Task<ActionResult<IEnumerable<StockConsolidadoItem>>> ConsultarStock(
        [FromQuery] int? centroCostoId, [FromQuery] int? bodegaId, [FromQuery] string? sku)
    {
        var stock = await _service.ConsultarStockAsync(centroCostoId, bodegaId, sku);
        return Ok(stock);
    }

    /// <summary>Registra una baja por dano o merma accidental. Descuenta stock y genera KARDEX.</summary>
    [HttpPost("bajas")]
    [Authorize(Roles = "Administrador,Bodeguero")]
    public async Task<ActionResult<RegistrarBajaResponse>> RegistrarBaja(RegistrarBajaRequest request)
    {
        var resultado = await _service.RegistrarBajaAsync(request, UsuarioActualId);
        return Ok(resultado);
    }

    // Agregar a InventarioController
    [HttpGet("motivos-perdida")]
    public async Task<ActionResult<IEnumerable<MotivoPerdidaItem>>> ListarMotivosPerdida()
    {
        return Ok(await _service.ListarMotivosPerdidaAsync());
    }
}