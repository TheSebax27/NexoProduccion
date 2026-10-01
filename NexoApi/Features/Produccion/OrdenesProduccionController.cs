using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NexoApi.Features.Produccion.Dtos;

namespace NexoApi.Features.Produccion;

[ApiController]
[Route("api/produccion/ordenes")]
[Authorize]
public class OrdenesProduccionController : ControllerBase
{
    private readonly IOrdenesProduccionService _service;

    public OrdenesProduccionController(IOrdenesProduccionService service)
    {
        _service = service;
    }

    private int UsuarioActualId =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    [HttpGet]
    public async Task<ActionResult<IEnumerable<OrdenProduccionResumen>>> Listar(
        [FromQuery] int? centroCostoId, [FromQuery] string? estado)
    {
        var ordenes = await _service.ListarAsync(centroCostoId, estado);
        return Ok(ordenes);
    }

    [HttpGet("siguiente-codigo")]
    public async Task<ActionResult<string>> SiguienteCodigoOP([FromQuery] string prefijo = "OP")
        => Ok(await _service.GenerarSiguienteCodigoOPAsync(prefijo.Trim().ToUpper()));

    [HttpGet("siguiente-lote")]
    public async Task<ActionResult<string>> SiguienteNumeroLote([FromQuery] string prefijo = "LOTE")
        => Ok(await _service.GenerarSiguienteNumeroLoteAsync(prefijo.Trim().ToUpper()));

    [HttpGet("{id:int}")]
    public async Task<ActionResult<OrdenProduccionResumen>> Obtener(int id)
    {
        var orden = await _service.ObtenerAsync(id);
        return orden is null ? NotFound() : Ok(orden);
    }

    [HttpPost]
    [Authorize]
    public async Task<ActionResult> Crear(CrearOrdenProduccionRequest request)
    {
        var id = await _service.CrearAsync(request, UsuarioActualId);
        return CreatedAtAction(nameof(Obtener), new { id }, new { OrdenProduccionID = id });
    }

    /// <summary>Detalle con IDs crudos (no nombres), para precargar el formulario de edicion.</summary>
    [HttpGet("{id:int}/editar")]
    [Authorize]
    public async Task<ActionResult<OrdenProduccionDetalleEdicion>> ObtenerParaEdicion(int id)
    {
        var detalle = await _service.ObtenerParaEdicionAsync(id);
        return detalle is null ? NotFound() : Ok(detalle);
    }

    /// <summary>Solo permitido mientras la orden esta en estado Planificada (aun no se descuenta stock).</summary>
    [HttpPut("{id:int}")]
    [Authorize]
    public async Task<ActionResult> Actualizar(int id, ActualizarOrdenProduccionRequest request)
    {
        await _service.ActualizarAsync(id, request);
        return Ok(new { mensaje = "Orden de produccion actualizada correctamente." });
    }

    /// <summary>Solo permitido mientras la orden esta en estado Planificada. No se borra fisicamente, queda como Cancelada.</summary>
    [HttpPost("{id:int}/cancelar")]
    [Authorize]
    public async Task<ActionResult> Cancelar(int id)
    {
        await _service.CancelarAsync(id);
        return Ok(new { mensaje = "Orden de produccion cancelada." });
    }

    [HttpPost("{id:int}/liberar")]
    [Authorize]
    public async Task<ActionResult> Liberar(int id)
    {
        await _service.LiberarAsync(id, UsuarioActualId);
        return Ok(new { mensaje = "Orden liberada correctamente." });
    }

    [HttpPost("{id:int}/iniciar")]
    [Authorize]
    public async Task<ActionResult> Iniciar(int id)
    {
        await _service.IniciarAsync(id, UsuarioActualId);
        return Ok(new { mensaje = "Orden iniciada, materia prima descontada." });
    }

    [HttpPatch("consumo/{consumoId:long}")]
    [Authorize]
    public async Task<ActionResult> AjustarConsumo(long consumoId, AjustarConsumoRealRequest request)
    {
        await _service.AjustarConsumoAsync(consumoId, request, UsuarioActualId);
        return Ok(new { mensaje = "Consumo actualizado." });
    }

    [HttpPost("{id:int}/cerrar")]
    [Authorize]
    public async Task<ActionResult> Cerrar(int id, CerrarOrdenProduccionRequest request)
    {
        var (costoUnitarioReal, loteId) = await _service.CerrarAsync(id, request, UsuarioActualId);
        return Ok(new { mensaje = "Orden finalizada.", costoUnitarioReal, loteProductoTerminadoId = loteId });
    }

    [HttpGet("{id:int}/verificar-stock")]
    [Authorize]
    public async Task<ActionResult<IEnumerable<StockLineaItem>>> VerificarStock(int id)
        => Ok(await _service.VerificarStockOrdenAsync(id));

    [HttpGet("{id:int}/consumos")]
    public async Task<ActionResult<IEnumerable<ConsumoOpItem>>> ListarConsumos(int id)
        => Ok(await _service.ListarConsumosAsync(id));

    [HttpGet("motivos-exceso")]
    public async Task<ActionResult<IEnumerable<MotivoExcesoItem>>> ListarMotivosExceso()
        => Ok(await _service.ListarMotivosExcesoAsync());

    [HttpGet("tipos-produccion")]
    public async Task<ActionResult<IEnumerable<TipoProduccionItem>>> ListarTiposProduccion()
    {
        return Ok(await _service.ListarTiposProduccionAsync());
    }

    [HttpPost("marcar-retrasadas")]
    [Authorize(Roles = "Administracion,Jefes")]
    public async Task<ActionResult> MarcarRetrasadas()
    {
        var afectadas = await _service.MarcarRetrasadasAsync();
        return Ok(new { mensaje = $"{afectadas} orden(es) marcada(s) como Retrasada.", afectadas });
    }

    [HttpGet("control-consumos/faltantes")]
    [Authorize]
    public async Task<ActionResult<IEnumerable<FaltanteMaterialItem>>> ListarFaltantes()
        => Ok(await _service.ListarFaltantesMaterialesAsync());

    [HttpGet("control-consumos/desviaciones")]
    [Authorize]
    public async Task<ActionResult<IEnumerable<DesviacionConsumoItem>>> ListarDesviaciones(
        [FromQuery] DateTime? desde, [FromQuery] DateTime? hasta)
        => Ok(await _service.ListarDesviacionesConsumoAsync(desde, hasta));
}