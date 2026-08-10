using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace NexoApi.Features.Email;

[ApiController]
[Route("api/email")]
[Authorize]
public class EmailController(IEmailService emailService) : ControllerBase
{
    [HttpGet("config")]
    [Authorize(Roles = "Administracion")]
    public async Task<EmailConfigItem> ObtenerConfig() =>
        await emailService.ObtenerConfigAsync();

    [HttpPut("config")]
    [Authorize(Roles = "Administracion")]
    public async Task<IActionResult> GuardarConfig([FromBody] EmailConfigItem config)
    {
        await emailService.GuardarConfigAsync(config);
        return Ok();
    }
}
