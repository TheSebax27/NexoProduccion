using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NexoApi.Features.Rrhh.Dtos;

namespace NexoApi.Features.Rrhh;

[ApiController]
[Route("api/rrhh/empleados")]
[Authorize(Roles = "Administrador")]
public class EmpleadosController : ControllerBase
{
    private readonly IRrhhService _service;

    public EmpleadosController(IRrhhService service)
    {
        _service = service;
    }

    private int UsuarioActualId =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    // Solo esta lectura se abre tambien a SupervisorPlanta -- Proyectos
    // necesita elegir responsables de tarea, y ese modulo si incluye ese rol.
    // Crear/editar empleados se queda Admin-only.
    [HttpGet]
    [Authorize(Roles = "Administrador,SupervisorPlanta")]
    public async Task<ActionResult<IEnumerable<EmpleadoItem>>> Listar([FromQuery] bool soloActivos = false)
        => Ok(await _service.ListarEmpleadosAsync(soloActivos));

    [HttpPost]
    public async Task<ActionResult> Crear(CrearEmpleadoRequest request)
    {
        var id = await _service.CrearEmpleadoAsync(request);
        return CreatedAtAction(nameof(Listar), new { EmpleadoID = id }, new { empleadoId = id });
    }

    [HttpPut("{id:int}")]
    public async Task<ActionResult> Actualizar(int id, ActualizarEmpleadoRequest request)
    {
        try
        {
            await _service.ActualizarEmpleadoAsync(id, request, UsuarioActualId);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { error = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { error = ex.Message });
        }
    }

    // ================= Foto (opcional, una sola por empleado) =================

    // Sin [Authorize]: un <img src="..."> plano no puede mandar el header
    // Authorization -- mismo trade-off documentado que la imagen de articulo
    // (ArticulosController). Solo sirve bytes de una foto por ID numerico.
    [HttpGet("{id:int}/foto")]
    [AllowAnonymous]
    public async Task<IActionResult> ObtenerFoto(int id)
    {
        var foto = await _service.ObtenerFotoEmpleadoAsync(id);
        if (foto is null)
            return NotFound();

        return File(foto.Value.Datos, foto.Value.ContentType);
    }

    [HttpPut("{id:int}/foto")]
    public async Task<ActionResult> ActualizarFoto(int id, ActualizarFotoEmpleadoRequest request)
    {
        if (Convert.FromBase64String(request.Base64).Length > 1_000_000)
            return BadRequest(new { error = "La foto es muy grande (máximo 1 MB)." });

        try
        {
            await _service.ActualizarFotoEmpleadoAsync(id, request);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { error = ex.Message });
        }
    }

    [HttpDelete("{id:int}/foto")]
    public async Task<ActionResult> EliminarFoto(int id)
    {
        try
        {
            await _service.EliminarFotoEmpleadoAsync(id);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { error = ex.Message });
        }
    }

    // ================= Historial laboral (agosto 2026, RRHH v2) =================
    // Se genera automatico -- no hay POST, solo lectura.

    [HttpGet("{id:int}/historial")]
    public async Task<ActionResult<IEnumerable<HistorialLaboralItem>>> ListarHistorial(int id)
        => Ok(await _service.ListarHistorialLaboralAsync(id));

    // ================= Documentos (agosto 2026, RRHH v2) =================

    [HttpGet("{id:int}/documentos")]
    public async Task<ActionResult<IEnumerable<EmpleadoDocumentoItem>>> ListarDocumentos(int id)
        => Ok(await _service.ListarDocumentosAsync(id));

    [HttpPost("{id:int}/documentos")]
    public async Task<ActionResult> SubirDocumento(int id, SubirDocumentoEmpleadoRequest request)
    {
        if (Convert.FromBase64String(request.Base64).Length > 5_000_000)
            return BadRequest(new { error = "El documento es muy grande (máximo 5 MB)." });

        var documentoId = await _service.SubirDocumentoAsync(id, request, UsuarioActualId);
        return Ok(new { documentoId });
    }

    [HttpGet("documentos/{id:int}")]
    public async Task<IActionResult> DescargarDocumento(int id)
    {
        var documento = await _service.ObtenerDocumentoAsync(id);
        if (documento is null)
            return NotFound();

        return File(documento.Value.Datos, documento.Value.ContentType, documento.Value.NombreArchivo);
    }

    [HttpDelete("documentos/{id:int}")]
    public async Task<ActionResult> EliminarDocumento(int id)
    {
        try
        {
            await _service.EliminarDocumentoAsync(id);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { error = ex.Message });
        }
    }

    // ================= Evaluaciones de desempeño (agosto 2026, RRHH v2) =================

    [HttpGet("{id:int}/evaluaciones")]
    public async Task<ActionResult<IEnumerable<EvaluacionItem>>> ListarEvaluaciones(int id)
        => Ok(await _service.ListarEvaluacionesAsync(id));

    [HttpPost("evaluaciones")]
    public async Task<ActionResult> CrearEvaluacion(CrearEvaluacionRequest request)
    {
        try
        {
            var id = await _service.CrearEvaluacionAsync(request, UsuarioActualId);
            return Ok(new { evaluacionId = id });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    // ================= Capacitaciones (agosto 2026, RRHH v2) =================

    [HttpGet("{id:int}/capacitaciones")]
    public async Task<ActionResult<IEnumerable<CapacitacionItem>>> ListarCapacitaciones(int id)
        => Ok(await _service.ListarCapacitacionesAsync(id));

    [HttpPost("capacitaciones")]
    public async Task<ActionResult> CrearCapacitacion(CrearCapacitacionRequest request)
    {
        var id = await _service.CrearCapacitacionAsync(request, UsuarioActualId);
        return Ok(new { capacitacionId = id });
    }

    // ================= Organigrama (agosto 2026, RRHH v2) =================

    [HttpGet("organigrama")]
    public async Task<ActionResult<IEnumerable<OrganigramaNodo>>> ObtenerOrganigrama()
        => Ok(await _service.ObtenerOrganigramaAsync());
}
