using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NexoApi.Common.Security;
using NexoApi.Features.Integracion.Dtos;

namespace NexoApi.Features.Integracion;

[ApiController]
[Route("api/integracion")]
public class IntegracionController : ControllerBase
{
    private readonly IIntegracionService _service;

    public IntegracionController(IIntegracionService service)
    {
        _service = service;
    }

    private int CentroCostoDelAgente =>
        int.Parse(User.FindFirstValue("CentroCostoId")!);

    /// <summary>Llamado por el Agente de Sincronizacion. Requiere header X-Api-Key.</summary>
    [HttpGet("eventos-pendientes")]
    [Authorize(AuthenticationSchemes = ApiKeyAuthenticationHandler.SchemeName)]
    public async Task<ActionResult<IEnumerable<EventoPendienteItem>>> ObtenerEventosPendientes()
    {
        return Ok(await _service.ObtenerEventosPendientesAsync(CentroCostoDelAgente));
    }

    /// <summary>Llamado por el Agente tras aplicar exitosamente un evento en Visions.</summary>
    [HttpPost("eventos-salientes/{id:long}/confirmar")]
    [Authorize(AuthenticationSchemes = ApiKeyAuthenticationHandler.SchemeName)]
    public async Task<ActionResult> ConfirmarEventoSaliente(long id)
    {
        await _service.ConfirmarEventoSalienteAsync(id, CentroCostoDelAgente);
        return Ok(new { mensaje = "Evento confirmado." });
    }

    /// <summary>Llamado por el Agente cuando detecta una venta nueva en Visions.</summary>
    [HttpPost("eventos-entrantes")]
    [Authorize(AuthenticationSchemes = ApiKeyAuthenticationHandler.SchemeName)]
    public async Task<ActionResult> RegistrarEventoEntrante(RegistrarEventoEntranteRequest request)
    {
        await _service.RegistrarEventoEntranteAsync(request, CentroCostoDelAgente);
        return Ok(new { mensaje = "Evento entrante procesado." });
    }

    /// <summary>Genera la API Key de un cliente nuevo. Usa JWT normal, solo Administrador -- nada que ver con el agente.</summary>
    [HttpPost("agentes/api-key")]
    [Authorize(Roles = "Administrador")]
    public async Task<ActionResult<GenerarApiKeyResponse>> GenerarApiKey(GenerarApiKeyRequest request)
    {
        return Ok(await _service.GenerarApiKeyAsync(request));
    }
}