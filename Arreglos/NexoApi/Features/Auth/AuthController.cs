using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NexoApi.Features.Auth.Dtos;

namespace NexoApi.Features.Auth;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    [HttpPost("login")]
    [AllowAnonymous]
    public async Task<ActionResult<LoginResponse>> Login(LoginRequest request)
    {
        var resultado = await _authService.LoginAsync(request);

        if (resultado is null)
            return Unauthorized(new { error = "Usuario o contrasena incorrectos, o usuario inactivo." });

        return Ok(resultado);
    }
    [HttpPost("registrar")]
    [AllowAnonymous]
    public async Task<ActionResult> RegistrarPrimerAdmin(RegistrarUsuarioRequest request)
    {
        try
        {
            var id = await _authService.RegistrarPrimerAdminAsync(request);
            return Ok(new { mensaje = "Usuario creado. Ya puedes hacer login.", usuarioId = id });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { error = ex.Message }); // 409: ya no se permite usar este endpoint
        }
    }
}