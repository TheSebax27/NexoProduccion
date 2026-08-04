using System.Security.Claims;
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

    private int UsuarioActualId =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

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

    // ================= Mi perfil (cualquier usuario autenticado, sobre si mismo) =================
    // Sin restriccion de rol a proposito: solo tocan Nombres/Apellidos/Foto del
    // propio UsuarioID (del JWT), nunca RolID/CentroCostoID/Estado -- eso sigue
    // siendo exclusivo de Administrador via /usuarios/{id}.

    [HttpPut("perfil")]
    [Authorize]
    public async Task<ActionResult<PerfilActualizadoResponse>> ActualizarPerfil(ActualizarPerfilRequest request)
    {
        try
        {
            var nombreCompleto = await _authService.ActualizarPerfilAsync(UsuarioActualId, request);
            return Ok(new PerfilActualizadoResponse(nombreCompleto));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { error = ex.Message });
        }
    }

    [HttpPut("perfil/foto")]
    [Authorize]
    public async Task<ActionResult> ActualizarFotoPerfil(ActualizarFotoPerfilRequest request)
    {
        // Limite generoso para un avatar pequeno (~1.3MB en base64 ~ 1MB real);
        // suficiente para una foto de perfil sin abrir la puerta a archivos grandes.
        if (Convert.FromBase64String(request.Base64).Length > 1_000_000)
            return BadRequest(new { error = "La imagen es muy grande (máximo 1 MB)." });

        try
        {
            await _authService.ActualizarFotoPerfilAsync(UsuarioActualId, request);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { error = ex.Message });
        }
    }

    [HttpDelete("perfil/foto")]
    [Authorize]
    public async Task<ActionResult> EliminarFotoPerfil()
    {
        try
        {
            await _authService.EliminarFotoPerfilAsync(UsuarioActualId);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { error = ex.Message });
        }
    }
}