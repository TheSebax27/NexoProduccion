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

    [HttpGet("centros-trabajo")]
    public async Task<ActionResult<IEnumerable<CentroTrabajoItem>>> ListarCentrosTrabajo()
        => Ok(await _service.ListarCentrosTrabajoAsync());


    // Agregar a ClientesYCentrosTrabajoController (ya existe, lo reutilizamos)
    [HttpGet("proveedores")]
    public async Task<ActionResult<IEnumerable<ProveedorItem>>> ListarProveedores()
        => Ok(await _service.ListarProveedoresAsync());
}
