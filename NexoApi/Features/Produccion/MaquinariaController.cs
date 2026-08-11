using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NexoApi.Features.Produccion.Dtos;

namespace NexoApi.Features.Produccion;

[ApiController]
[Authorize]
public class MaquinariaController(IMaquinariaService svc) : ControllerBase
{
    // ── Tipos ─────────────────────────────────────────────────────

    [HttpGet("api/produccion/tipos-maquinaria")]
    public async Task<IActionResult> ListarTipos()
        => Ok(await svc.ListarTiposAsync());

    [HttpPost("api/produccion/tipos-maquinaria")]
    [Authorize(Roles = "Administracion,Jefes")]
    public async Task<IActionResult> CrearTipo([FromBody] CrearTipoMaquinariaRequest r)
    {
        if (string.IsNullOrWhiteSpace(r.Nombre)) return BadRequest("El nombre es obligatorio.");
        var id = await svc.CrearTipoAsync(r);
        return Ok(id);
    }

    // ── Maquinaria ────────────────────────────────────────────────

    [HttpGet("api/produccion/maquinaria")]
    public async Task<IActionResult> Listar(
        [FromQuery] int? tipoId,
        [FromQuery] string? estado,
        [FromQuery] int? centroTrabajoId)
        => Ok(await svc.ListarAsync(tipoId, estado, centroTrabajoId));

    [HttpGet("api/produccion/maquinaria/en-mantenimiento")]
    public async Task<IActionResult> EnMantenimiento()
        => Ok(await svc.ListarEnMantenimientoAsync());

    [HttpGet("api/produccion/maquinaria/{id:int}")]
    public async Task<IActionResult> Obtener(int id)
    {
        var m = await svc.ObtenerAsync(id);
        return m is null ? NotFound() : Ok(m);
    }

    [HttpPost("api/produccion/maquinaria")]
    [Authorize(Roles = "Administracion,Jefes")]
    public async Task<IActionResult> Crear([FromBody] CrearMaquinariaRequest r)
    {
        try
        {
            var id = await svc.CrearAsync(r);
            return Ok(id);
        }
        catch (InvalidOperationException ex) { return BadRequest(ex.Message); }
    }

    [HttpPut("api/produccion/maquinaria/{id:int}")]
    [Authorize(Roles = "Administracion,Jefes")]
    public async Task<IActionResult> Actualizar(int id, [FromBody] ActualizarMaquinariaRequest r)
    {
        try
        {
            await svc.ActualizarAsync(id, r);
            return NoContent();
        }
        catch (InvalidOperationException ex) { return BadRequest(ex.Message); }
        catch (KeyNotFoundException) { return NotFound(); }
    }

    // ── Estadísticas ──────────────────────────────────────────────

    [HttpGet("api/produccion/maquinaria/{id:int}/estadisticas")]
    public async Task<IActionResult> Estadisticas(int id)
        => Ok(await svc.GetEstadisticasAsync(id));

    // ── Enlace Recetas ────────────────────────────────────────────

    [HttpGet("api/produccion/recetas/{recetaId:int}/maquinaria")]
    public async Task<IActionResult> MaquinasReceta(int recetaId)
        => Ok(await svc.ListarMaquinasRecetaAsync(recetaId));

    // ── Enlace Órdenes ────────────────────────────────────────────

    [HttpGet("api/produccion/ordenes/{ordenId:int}/maquinaria")]
    public async Task<IActionResult> MaquinasOrden(int ordenId)
        => Ok(await svc.ListarMaquinasOrdenAsync(ordenId));

    [HttpPut("api/produccion/ordenes/{ordenId:int}/maquinaria")]
    [Authorize(Roles = "Administracion,Jefes")]
    public async Task<IActionResult> GuardarMaquinasOrden(int ordenId, [FromBody] List<MaquinariaOrdenInput> maquinas)
    {
        await svc.GuardarMaquinasOrdenAsync(ordenId, maquinas);
        return NoContent();
    }

    // ── Mantenimientos ────────────────────────────────────────────

    [HttpGet("api/produccion/maquinaria/{id:int}/mantenimientos")]
    public async Task<IActionResult> ListarMantenimientos(int id)
        => Ok(await svc.ListarMantenimientosAsync(id));

    [HttpPost("api/produccion/maquinaria/{id:int}/mantenimientos")]
    [Authorize(Roles = "Administracion,Jefes")]
    public async Task<IActionResult> RegistrarMantenimiento(
        int id, [FromBody] CrearMantenimientoRequest r)
    {
        var usuarioIdStr = User.FindFirst("UsuarioID")?.Value;
        if (!int.TryParse(usuarioIdStr, out var usuarioId)) return Unauthorized();
        try
        {
            await svc.RegistrarMantenimientoAsync(id, r, usuarioId);
            return NoContent();
        }
        catch (InvalidOperationException ex) { return BadRequest(ex.Message); }
    }
}
