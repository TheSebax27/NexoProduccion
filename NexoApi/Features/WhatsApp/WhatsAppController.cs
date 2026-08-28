using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NexoApi.Features.WhatsApp.Dtos;

namespace NexoApi.Features.WhatsApp;

[ApiController]
[Route("api/whatsapp")]
[Authorize]
public class WhatsAppController(IWhatsAppService svc) : ControllerBase
{
    [HttpGet("config")]
    [Authorize(Roles = "Administracion")]
    public async Task<WhatsAppConfigItem> ObtenerConfig() =>
        await svc.ObtenerConfigAsync();

    [HttpPut("config")]
    [Authorize(Roles = "Administracion")]
    public async Task<IActionResult> GuardarConfig([FromBody] WhatsAppConfigItem config)
    {
        await svc.GuardarConfigAsync(config);
        return Ok();
    }

    [HttpPost("test")]
    [Authorize(Roles = "Administracion")]
    public async Task<IActionResult> EnviarTest([FromQuery] string telefono)
    {
        if (string.IsNullOrWhiteSpace(telefono))
            return BadRequest(new { error = "Debes indicar un número de teléfono de destino." });

        var config = await svc.ObtenerConfigAsync();
        if (!config.Activo || string.IsNullOrWhiteSpace(config.AccountSid))
            return BadRequest(new { error = "WhatsApp no está activo o no tiene credenciales configuradas." });

        var result = await svc.EnviarAsync(telefono, "✅ Mensaje de prueba desde NEXO ERP — la integración con WhatsApp está funcionando correctamente.");
        return result.Enviado
            ? Ok(new { mensaje = $"Mensaje de prueba enviado al {telefono}." })
            : BadRequest(new { error = result.Error ?? "No se pudo enviar el mensaje." });
    }

    [HttpPost("enviar")]
    public async Task<IActionResult> Enviar([FromBody] EnviarWhatsAppRequest req)
    {
        var result = await svc.EnviarAsync(req.Telefono, req.Mensaje);
        return result.Enviado ? Ok(result) : BadRequest(result);
    }

    [HttpPost("enviar-masivo")]
    [Authorize(Roles = "Administracion")]
    public async Task<IActionResult> EnviarMasivo([FromBody] EnvioMasivoRequest req)
    {
        if (!req.Destinatarios.Any())
            return BadRequest(new { error = "Debes seleccionar al menos un destinatario." });
        if (string.IsNullOrWhiteSpace(req.Mensaje))
            return BadRequest(new { error = "El mensaje no puede estar vacío." });

        var config = await svc.ObtenerConfigAsync();
        if (!config.Activo || string.IsNullOrWhiteSpace(config.AccountSid))
            return BadRequest(new { error = "WhatsApp no está activo o no tiene credenciales configuradas." });

        var resultados = new List<ResultadoDestinatario>();
        foreach (var d in req.Destinatarios)
        {
            var r = await svc.EnviarAsync(d.Telefono, req.Mensaje);
            resultados.Add(new ResultadoDestinatario(d.ClienteID, d.Nombre, d.Telefono, r.Enviado, r.Error));
            // Pausa mínima para no saturar Twilio
            await Task.Delay(200);
        }

        return Ok(new
        {
            Total       = resultados.Count,
            Enviados    = resultados.Count(r => r.Enviado),
            Fallidos    = resultados.Count(r => !r.Enviado),
            Resultados  = resultados
        });
    }
}
