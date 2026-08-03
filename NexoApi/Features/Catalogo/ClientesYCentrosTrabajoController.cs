using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NexoApi.Features.Catalogo.Dtos;

namespace NexoApi.Features.Catalogo;

[ApiController]
[Route("api/catalogo")]
[Authorize]
public class ClientesYCentrosTrabajoController : ControllerBase
{
    private readonly ICatalogoService _service;

    public ClientesYCentrosTrabajoController(ICatalogoService service)
    {
        _service = service;
    }

    [HttpGet("clientes")]
    public async Task<ActionResult<IEnumerable<ClienteItem>>> ListarClientes()
        => Ok(await _service.ListarClientesAsync());

    [HttpPost("clientes")]
    [Authorize(Roles = "Administrador")]
    public async Task<ActionResult> CrearCliente(CrearClienteRequest request)
    {
        var id = await _service.CrearClienteAsync(request);
        return CreatedAtAction(nameof(ListarClientes), new { }, new { ClienteID = id });
    }

    [HttpPut("clientes/{id:int}")]
    [Authorize(Roles = "Administrador")]
    public async Task<ActionResult> ActualizarCliente(int id, ActualizarClienteRequest request)
    {
        await _service.ActualizarClienteAsync(id, request);
        return Ok();
    }

    [HttpGet("centros-trabajo")]
    public async Task<ActionResult<IEnumerable<CentroTrabajoItem>>> ListarCentrosTrabajo([FromQuery] bool soloActivos = true)
        => Ok(await _service.ListarCentrosTrabajoAsync(soloActivos));

    [HttpPost("centros-trabajo")]
    [Authorize(Roles = "Administrador")]
    public async Task<ActionResult> CrearCentroTrabajo(CrearCentroTrabajoRequest request)
    {
        var id = await _service.CrearCentroTrabajoAsync(request);
        return CreatedAtAction(nameof(ListarCentrosTrabajo), new { }, new { CentroTrabajoID = id });
    }

    [HttpPut("centros-trabajo/{id:int}")]
    [Authorize(Roles = "Administrador")]
    public async Task<ActionResult> ActualizarCentroTrabajo(int id, ActualizarCentroTrabajoRequest request)
    {
        await _service.ActualizarCentroTrabajoAsync(id, request);
        return Ok();
    }

    [HttpGet("proveedores")]
    public async Task<ActionResult<IEnumerable<ProveedorItem>>> ListarProveedores()
        => Ok(await _service.ListarProveedoresAsync());

    [HttpPost("proveedores")]
    [Authorize(Roles = "Administrador")]
    public async Task<ActionResult> CrearProveedor(CrearProveedorRequest request)
    {
        var id = await _service.CrearProveedorAsync(request);
        return CreatedAtAction(nameof(ListarProveedores), new { }, new { ProveedorID = id });
    }

    [HttpPut("proveedores/{id:int}")]
    [Authorize(Roles = "Administrador")]
    public async Task<ActionResult> ActualizarProveedor(int id, ActualizarProveedorRequest request)
    {
        await _service.ActualizarProveedorAsync(id, request);
        return Ok();
    }
}
