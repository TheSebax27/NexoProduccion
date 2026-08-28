using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NexoApi.Features.Reportes.Dtos;

namespace NexoApi.Features.Reportes;

[ApiController]
[Route("api/reportes")]
[Authorize]
public class ReportesController : ControllerBase
{
    private readonly IReportesService _svc;
    public ReportesController(IReportesService svc) => _svc = svc;

    [HttpGet]
    public IActionResult ListarTipos() => Ok(_svc.ListarReportes());

    [HttpPost("ejecutar")]
    public async Task<IActionResult> Ejecutar([FromBody] ReporteRequest req)
    {
        var filas = await _svc.EjecutarAsync(req);
        return Ok(filas);
    }

    [HttpPost("exportar")]
    public async Task<IActionResult> Exportar([FromBody] ReporteRequest req)
    {
        var bytes    = await _svc.ExportarExcelAsync(req);
        var filename = $"reporte_{req.Tipo}_{DateTime.Today:yyyy-MM-dd}.xlsx";
        return File(bytes,
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            filename);
    }
}
