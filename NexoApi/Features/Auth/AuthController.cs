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
}