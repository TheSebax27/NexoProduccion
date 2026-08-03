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

    // ================= Gestion de usuarios (solo Administrador) =================

    [HttpGet("usuarios")]
    [Authorize(Roles = "Administrador")]
    public async Task<ActionResult<IEnumerable<UsuarioItem>>> ListarUsuarios()
        => Ok(await _authService.ListarUsuariosAsync());

    [HttpPost("usuarios")]
    [Authorize(Roles = "Administrador")]
    public async Task<ActionResult> CrearUsuario(CrearUsuarioRequest request)
    {
        try
        {
            var id = await _authService.CrearUsuarioAsync(request);
            return Ok(new { mensaje = "Usuario creado correctamente.", usuarioId = id });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { error = ex.Message });
        }
    }

    [HttpPut("usuarios/{id:int}")]
    [Authorize(Roles = "Administrador")]
    public async Task<ActionResult> ActualizarUsuario(int id, ActualizarUsuarioRequest request)
    {
        try
        {
            await _authService.ActualizarUsuarioAsync(id, request);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { error = ex.Message });
        }
    }

    [HttpPost("usuarios/{id:int}/resetear-password")]
    [Authorize(Roles = "Administrador")]
    public async Task<ActionResult> ResetearPassword(int id, ResetearPasswordRequest request)
    {
        try
        {
            await _authService.ResetearPasswordAsync(id, request);
            return Ok(new { mensaje = "Contrasena actualizada correctamente." });
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { error = ex.Message });
        }
    }

    [HttpGet("roles")]
    [Authorize(Roles = "Administrador")]
    public async Task<ActionResult<IEnumerable<RolItem>>> ListarRoles()
        => Ok(await _authService.ListarRolesAsync());
}