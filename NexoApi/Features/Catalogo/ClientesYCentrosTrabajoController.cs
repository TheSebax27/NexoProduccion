using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NexoApi.Features.Catalogo.Dtos;

namespace NexoApi.Features.Catalogo;

// Clientes se movio a Features/Crm/CrmController.cs (agosto 2026) -- este
// controller se quedo solo con Centros de Trabajo y Proveedores, el nombre
// de la clase no se cambio para no romper referencias, pero ya no incluye Clientes.
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
