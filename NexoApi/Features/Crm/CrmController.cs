using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NexoApi.Features.Crm.Dtos;

namespace NexoApi.Features.Crm;

[ApiController]
[Route("api/crm")]
[Authorize(Roles = "Administrador")]
public class CrmController : ControllerBase
{
    private readonly ICrmService _service;

    public CrmController(ICrmService service)
    {
        _service = service;
    }

    private int UsuarioActualId =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    // Solo esta lectura se abre tambien a Bodeguero (Logistica/Despachos) y
    // SupervisorPlanta (Proyectos) -- ambos necesitan elegir un cliente.
    // Crear/editar clientes y ver interacciones se quedan Admin-only.
    [HttpGet("clientes")]
    [Authorize(Roles = "Administrador,Bodeguero,SupervisorPlanta")]
    public async Task<ActionResult<IEnumerable<ClienteItem>>> ListarClientes(
        [FromQuery] int? responsableId, [FromQuery] string? tipoCliente,
        [FromQuery] string? fuenteContacto, [FromQuery] bool? soloActivos)
        => Ok(await _service.ListarClientesAsync(responsableId, tipoCliente, fuenteContacto, soloActivos));

    [HttpPost("clientes")]
    public async Task<ActionResult> CrearCliente(CrearClienteRequest request)
    {
        var id = await _service.CrearClienteAsync(request);
        return CreatedAtAction(nameof(ListarClientes), new { }, new { clienteId = id });
    }

    [HttpPut("clientes/{id:int}")]
    public async Task<ActionResult> ActualizarCliente(int id, ActualizarClienteRequest request)
    {
        try
        {
            await _service.ActualizarClienteAsync(id, request);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { error = ex.Message });
        }
    }

    [HttpGet("clientes/{id:int}/interacciones")]
    public async Task<ActionResult<IEnumerable<InteraccionItem>>> ListarInteracciones(int id)
        => Ok(await _service.ListarInteraccionesAsync(id));

    [HttpPost("interacciones")]
    public async Task<ActionResult> CrearInteraccion(CrearInteraccionRequest request)
    {
        var id = await _service.CrearInteraccionAsync(request, UsuarioActualId);
        return Ok(new { interaccionId = id });
    }

    // ---------- A) Contactos ----------

    [HttpGet("clientes/{id:int}/contactos")]
    public async Task<ActionResult<IEnumerable<ContactoItem>>> ListarContactos(int id)
        => Ok(await _service.ListarContactosAsync(id));

    [HttpPost("contactos")]
    public async Task<ActionResult> CrearContacto(CrearContactoRequest request)
    {
        var id = await _service.CrearContactoAsync(request);
        return Ok(new { contactoId = id });
    }

    [HttpPut("contactos/{id:int}")]
    public async Task<ActionResult> ActualizarContacto(int id, ActualizarContactoRequest request)
    {
        try
        {
            await _service.ActualizarContactoAsync(id, request);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { error = ex.Message });
        }
    }

    // ---------- C) Historial unificado ----------

    [HttpGet("clientes/{id:int}/historial")]
    public async Task<ActionResult<IEnumerable<EventoHistorialItem>>> ObtenerHistorial(int id)
        => Ok(await _service.ObtenerHistorialAsync(id));

    // ---------- E) Documentos ----------

    [HttpGet("clientes/{id:int}/documentos")]
    public async Task<ActionResult<IEnumerable<ClienteDocumentoItem>>> ListarDocumentos(int id)
        => Ok(await _service.ListarDocumentosAsync(id));

    [HttpPost("clientes/{id:int}/documentos")]
    public async Task<ActionResult> SubirDocumento(int id, SubirDocumentoRequest request)
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

    // ---------- Leads ----------

    [HttpGet("leads")]
    public async Task<ActionResult<IEnumerable<LeadItem>>> ListarLeads([FromQuery] string? etapa)
        => Ok(await _service.ListarLeadsAsync(etapa));

    [HttpPost("leads")]
    public async Task<ActionResult> CrearLead(CrearLeadRequest request)
    {
        var id = await _service.CrearLeadAsync(request);
        return Ok(new { leadId = id });
    }

    [HttpPut("leads/{id:int}")]
    public async Task<ActionResult> ActualizarLead(int id, ActualizarLeadRequest request)
    {
        try
        {
            await _service.ActualizarLeadAsync(id, request);
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

    [HttpPost("leads/{id:int}/convertir")]
    public async Task<ActionResult<ConvertirLeadResponse>> ConvertirLead(int id)
    {
        try
        {
            var clienteId = await _service.ConvertirLeadAsync(id);
            return Ok(new ConvertirLeadResponse(clienteId));
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

    // ---------- D) Clientes fríos ----------

    [HttpGet("clientes-frios")]
    public async Task<ActionResult<IEnumerable<ClienteFrioItem>>> ListarClientesFrios([FromQuery] int diasSinContacto = 30)
        => Ok(await _service.ListarClientesFriosAsync(diasSinContacto));

    // ---------- Oportunidades (embudo de ventas, agosto 2026) ----------

    [HttpGet("oportunidades")]
    public async Task<ActionResult<IEnumerable<OportunidadItem>>> ListarOportunidades([FromQuery] string? etapa, [FromQuery] int? responsableId)
        => Ok(await _service.ListarOportunidadesAsync(etapa, responsableId));

    [HttpPost("oportunidades")]
    public async Task<ActionResult> CrearOportunidad(CrearOportunidadRequest request)
    {
        try
        {
            var id = await _service.CrearOportunidadAsync(request);
            return Ok(new { oportunidadId = id });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPut("oportunidades/{id:int}")]
    public async Task<ActionResult> ActualizarOportunidad(int id, ActualizarOportunidadRequest request)
    {
        try
        {
            await _service.ActualizarOportunidadAsync(id, request);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { error = ex.Message });
        }
    }

    // ---------- Cotizaciones (agosto 2026) ----------

    [HttpGet("cotizaciones")]
    public async Task<ActionResult<IEnumerable<CotizacionItem>>> ListarCotizaciones([FromQuery] int? clienteId, [FromQuery] string? estado)
        => Ok(await _service.ListarCotizacionesAsync(clienteId, estado));

    [HttpPost("cotizaciones")]
    public async Task<ActionResult> CrearCotizacion(CrearCotizacionRequest request)
    {
        try
        {
            var id = await _service.CrearCotizacionAsync(request, UsuarioActualId);
            return Ok(new { cotizacionId = id });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpGet("cotizaciones/{id:int}/lineas")]
    public async Task<ActionResult<IEnumerable<CotizacionLineaItem>>> ListarLineasCotizacion(int id)
        => Ok(await _service.ListarLineasCotizacionAsync(id));

    [HttpPut("cotizaciones/{id:int}/estado")]
    public async Task<ActionResult> ActualizarEstadoCotizacion(int id, ActualizarEstadoCotizacionRequest request)
    {
        try
        {
            await _service.ActualizarEstadoCotizacionAsync(id, request);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { error = ex.Message });
        }
    }

    [HttpPost("cotizaciones/{id:int}/convertir-a-factura")]
    public async Task<ActionResult<ConvertirCotizacionResponse>> ConvertirCotizacionAFactura(int id)
    {
        try
        {
            var facturaId = await _service.ConvertirCotizacionAFacturaAsync(id, UsuarioActualId);
            return Ok(new ConvertirCotizacionResponse(facturaId));
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
}
