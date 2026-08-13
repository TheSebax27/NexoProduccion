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

    /// <summary>Genera la API Key de un cliente nuevo. Usa JWT normal, solo Administracion -- nada que ver con el agente.</summary>
    [HttpPost("agentes/api-key")]
    [Authorize(Roles = "Administracion")]
    public async Task<ActionResult<GenerarApiKeyResponse>> GenerarApiKey(GenerarApiKeyRequest request)
    {
        return Ok(await _service.GenerarApiKeyAsync(request));
    }

    /// <summary>Llamado por el Agente en cada ronda: trae la configuracion que el Administracion
    /// dejo en NEXO (activo, prefijos de documento de venta) para aplicarla en Visions. Asi
    /// esos valores solo se editan desde la web, nunca directo por SQL contra la base de Visions.</summary>
    [HttpGet("configuracion")]
    [Authorize(AuthenticationSchemes = ApiKeyAuthenticationHandler.SchemeName)]
    public async Task<ActionResult<ConfiguracionAgenteResponse>> ObtenerConfiguracion()
    {
        return Ok(await _service.ObtenerConfiguracionAgenteAsync(CentroCostoDelAgente));
    }

    // ---------- Mapeo de Articulos (uso del Administracion desde NEXO Web, JWT normal) ----------

    [HttpGet("mapeos")]
    [Authorize]
    public async Task<ActionResult<IEnumerable<MapeoArticuloItem>>> ListarMapeos([FromQuery] int centroCostoId)
    {
        return Ok(await _service.ListarMapeosAsync(centroCostoId));
    }

    [HttpPost("mapeos")]
    [Authorize(Roles = "Administracion")]
    public async Task<ActionResult> CrearMapeo(CrearMapeoArticuloRequest request)
    {
        await _service.CrearMapeoAsync(request);
        return Ok(new { mensaje = "Articulo mapeado y encolado para crear/actualizar en Visions." });
    }

    [HttpGet("articulos-pendientes")]
    [Authorize]
    public async Task<ActionResult<IEnumerable<ArticuloPendienteMapeoItem>>> ListarArticulosPendientes([FromQuery] int centroCostoId)
    {
        return Ok(await _service.ListarArticulosPendientesMapeoAsync(centroCostoId));
    }

    [HttpPost("articulos-pendientes/{id:int}/resolver")]
    [Authorize(Roles = "Administracion")]
    public async Task<ActionResult> ResolverArticuloPendiente(int id, ResolverArticuloPendienteRequest request)
    {
        try
        {
            await _service.ResolverArticuloPendienteAsync(id, request);
            return Ok(new { mensaje = "Articulo vinculado correctamente." });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { error = ex.Message });
        }
    }

    // ---------- Latido y monitoreo ----------

    /// <summary>Llamado por el Agente en cada ronda para registrar que sigue activo
    /// y actualizar UltimaConexion. Devuelve hora del servidor y eventos pendientes.</summary>
    [HttpPost("latido")]
    [Authorize(AuthenticationSchemes = ApiKeyAuthenticationHandler.SchemeName)]
    public async Task<ActionResult<LatidoResponse>> RegistrarLatido()
    {
        try
        {
            var respuesta = await _service.RegistrarLatidoAsync(CentroCostoDelAgente);
            return Ok(respuesta);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { error = ex.Message });
        }
    }

    /// <summary>Devuelve el estado de todos los agentes registrados.
    /// Usado por la pantalla de monitoreo de NexoWeb (solo Administracion).</summary>
    [HttpGet("estado")]
    [Authorize(Roles = "Administracion")]
    public async Task<ActionResult<IEnumerable<EstadoIntegracionResponse>>> ObtenerEstado()
    {
        return Ok(await _service.ObtenerEstadoIntegracionAsync());
    }

    /// <summary>Llamado por el Agente cuando no pudo aplicar un evento en Visions.
    /// Tras 3 intentos fallidos el evento pasa a ERROR y deja de reintentarse.</summary>
    [HttpPost("eventos-salientes/{id:long}/fallar")]
    [Authorize(AuthenticationSchemes = ApiKeyAuthenticationHandler.SchemeName)]
    public async Task<ActionResult> RegistrarFallo(long id, RegistrarFalloRequest request)
    {
        await _service.RegistrarFalloEventoAsync(id, CentroCostoDelAgente, request.MensajeError);
        return Ok(new { mensaje = "Fallo registrado." });
    }

    // ---------- Gestión de configuración del agente (Administracion) ----------

    [HttpGet("agentes/{id:int}/config")]
    [Authorize(Roles = "Administracion")]
    public async Task<ActionResult<ConfiguracionAgenteCompletaResponse>> ObtenerConfigCompleta(int id)
    {
        try { return Ok(await _service.ObtenerConfiguracionCompletaAsync(id)); }
        catch (KeyNotFoundException ex) { return NotFound(new { error = ex.Message }); }
    }

    [HttpPut("agentes/{id:int}/config")]
    [Authorize(Roles = "Administracion")]
    public async Task<ActionResult> ActualizarConfigCompleta(int id, ActualizarConfiguracionAgenteRequest request)
    {
        try
        {
            await _service.ActualizarConfiguracionCompletaAsync(id, request);
            return Ok(new { mensaje = "Configuracion actualizada." });
        }
        catch (KeyNotFoundException ex) { return NotFound(new { error = ex.Message }); }
    }

    /// <summary>Genera el ZIP del instalador (exe + appsettings con key fresca) y devuelve un token de descarga.</summary>
    [HttpPost("agentes/{id:int}/preparar-descarga")]
    [Authorize(Roles = "Administracion")]
    public async Task<ActionResult> PrepararDescarga(int id)
    {
        try
        {
            var token = await _service.PrepararDescargaInstaladorAsync(id);
            return Ok(new { token });
        }
        catch (InvalidOperationException ex) { return BadRequest(new { error = ex.Message }); }
        catch (KeyNotFoundException ex)      { return NotFound(new { error = ex.Message }); }
    }

    /// <summary>Descarga el instalador .exe usando el token de un solo uso generado por PrepararDescarga.</summary>
    [HttpGet("descargar-agente/{token}")]
    [AllowAnonymous]
    public ActionResult DescargarAgente(string token)
    {
        var bytes = _service.ObtenerPaqueteInstalador(token);
        if (bytes is null)
            return NotFound(new { error = "El enlace de descarga expiró o ya fue usado. Genera uno nuevo." });

        return File(bytes, "application/octet-stream", "NexoAgente-Setup.exe");
    }

    /// <summary>Desactiva (soft-delete) un agente. El servicio Windows puede seguir corriendo hasta que se detenga manualmente.</summary>
    [HttpDelete("agentes/{id:int}")]
    [Authorize(Roles = "Administracion")]
    public async Task<ActionResult> DesactivarAgente(int id)
    {
        try
        {
            await _service.DesactivarAgenteAsync(id);
            return Ok(new { mensaje = "Agente desactivado." });
        }
        catch (KeyNotFoundException ex) { return NotFound(new { error = ex.Message }); }
    }

    /// <summary>Genera solo el appsettings.json (para actualizar config en agentes ya instalados).</summary>
    [HttpGet("agentes/{id:int}/appsettings-json")]
    [Authorize(Roles = "Administracion")]
    public async Task<ActionResult<string>> GenerarAppsettingsJson(int id)
    {
        try
        {
            var contenido = await _service.PrepararAppsettingsConKeyFrescaAsync(id);
            return Ok(contenido);
        }
        catch (KeyNotFoundException ex) { return NotFound(new { error = ex.Message }); }
    }
}