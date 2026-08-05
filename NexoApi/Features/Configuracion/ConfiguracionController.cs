using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NexoApi.Features.Configuracion.Dtos;

namespace NexoApi.Features.Configuracion;

[ApiController]
[Route("api/configuracion")]
[Authorize]
public class ConfiguracionController : ControllerBase
{
    private readonly IConfiguracionService _service;

    public ConfiguracionController(IConfiguracionService service)
    {
        _service = service;
    }

    /// <summary>Nombre y logo de la empresa -- lo necesita cualquier usuario autenticado (se muestra en el sidebar).</summary>
    [HttpGet("empresa")]
    public async Task<ActionResult<ConfiguracionEmpresaResponse>> ObtenerEmpresa()
        => Ok(await _service.ObtenerEmpresaAsync());

    [HttpPut("empresa")]
    [Authorize(Roles = "Administrador")]
    public async Task<ActionResult> ActualizarNombre(ActualizarNombreEmpresaRequest request)
    {
        await _service.ActualizarNombreEmpresaAsync(request.NombreEmpresa);
        return NoContent();
    }

    [HttpPut("empresa/logo")]
    [Authorize(Roles = "Administrador")]
    public async Task<ActionResult> ActualizarLogo(ActualizarLogoEmpresaRequest request)
    {
        if (Convert.FromBase64String(request.Base64).Length > 1_000_000)
            return BadRequest(new { error = "La imagen es muy grande (máximo 1 MB)." });

        await _service.ActualizarLogoEmpresaAsync(request.Base64, request.ContentType);
        return NoContent();
    }

    [HttpDelete("empresa/logo")]
    [Authorize(Roles = "Administrador")]
    public async Task<ActionResult> EliminarLogo()
    {
        await _service.EliminarLogoEmpresaAsync();
        return NoContent();
    }
}
