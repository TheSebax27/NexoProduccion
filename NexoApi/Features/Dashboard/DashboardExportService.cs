using ClosedXML.Excel;
using Dapper;
using NexoApi.Common.Data;
using NexoApi.Features.Catalogo;
using NexoApi.Features.Catalogo.Dtos;
using NexoApi.Features.Dashboard.Dtos;
using NexoApi.Features.Inventario;
using NexoApi.Features.Inventario.Dtos;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

namespace NexoApi.Features.Dashboard;

public interface IDashboardExportService
{
    Task<byte[]> GenerarExcelAsync(DateTime desde, DateTime hasta);
    Task<byte[]> GenerarPdfAsync(DateTime desde, DateTime hasta);
}

// Junta los mismos datos que ya muestra el Dashboard (Plan vs Real, distribucion,
// cumplimiento, perdidas) mas el catalogo/stock actual, y los arma en un Excel
// (ClosedXML) o un PDF (QuestPDF) con la misma paleta morada de la app. A
// proposito no incluye imagenes de articulos -- son reportes de datos, no
// catalogos visuales, y las imagenes solo agregarian peso sin aportar nada aqui.
public class DashboardExportService : IDashboardExportService
{
    // Paleta "Morado + Gris moderno" de NEXO (ver CLAUDE.md #10), reutilizada
    // aqui para que los reportes se sientan parte de la misma aplicacion.
    private static readonly string ColorPrimario = "#7C5CFF";
    private static readonly string ColorPrimarioOscuro = "#5A3BFF";
    private static readonly string ColorTextoOscuro = "#1A1C2E";
    private static readonly string ColorTextoSecundario = "#6B6B8A";
    private static readonly string ColorBordes = "#E8E9EF";
    private static readonly string ColorFondoClaro = "#F4F5F9";
    private static readonly string ColorExito = "#10B981";
    private static readonly string ColorError = "#EF4444";
    private static readonly string ColorInfo = "#0EA5E9";

    private readonly IDbConnectionFactory _db;
    private readonly IDashboardService _dashboardService;
    private readonly ICatalogoService _catalogoService;
    private readonly IInventarioService _inventarioService;

    public DashboardExportService(
        IDbConnectionFactory db, IDashboardService dashboardService,
        ICatalogoService catalogoService, IInventarioService inventarioService)
    {
        _db = db;
        _dashboardService = dashboardService;
        _catalogoService = catalogoService;
        _inventarioService = inventarioService;
    }

    private record DatosReporte(
        string NombreEmpresa,
        List<PlanVsRealPunto> PlanVsReal,
        List<DistribucionCentroCostoItem> Distribucion,
        List<CumplimientoCentroCostoItem> Cumplimiento,
        List<PerdidaPorMotivoItem> Perdidas,
        List<StockConsolidadoItem> Stock,
        List<ArticuloItem> Articulos
    );

    private async Task<DatosReporte> RecolectarDatosAsync(DateTime desde, DateTime hasta)
    {
        using var connection = _db.CreateConnection();
        var nombreEmpresa = await connection.ExecuteScalarAsync<string?>(
            "SELECT TOP 1 NombreEmpresa FROM Organizacion.ConfiguracionEmpresa") ?? "NEXO ERP";

        var planVsReal = (await _dashboardService.ObtenerPlanVsRealAsync(desde, hasta)).ToList();
        var distribucion = (await _dashboardService.ObtenerDistribucionCentroCostoAsync()).ToList();
        var cumplimiento = (await _dashboardService.ObtenerCumplimientoAsync()).ToList();
        var perdidas = (await _dashboardService.ObtenerPerdidasPorMotivoAsync(desde, hasta)).ToList();
        var stock = (await _inventarioService.ConsultarStockAsync(null, null, null)).ToList();
        var articulos = (await _catalogoService.ListarArticulosAsync(null, null)).ToList();

        return new DatosReporte(nombreEmpresa, planVsReal, distribucion, cumplimiento, perdidas, stock, articulos);
    }

    // ==================================================================
    // EXCEL (ClosedXML)
    // ==================================================================

    public async Task<byte[]> GenerarExcelAsync(DateTime desde, DateTime hasta)
    {
        var datos = await RecolectarDatosAsync(desde, hasta);

        using var libro = new XLWorkbook();

        CrearHojaResumen(libro, datos, desde, hasta);
        CrearHojaPlanVsReal(libro, datos);
        CrearHojaDistribucion(libro, datos);
        CrearHojaCumplimiento(libro, datos);
        CrearHojaPerdidas(libro, datos);
        CrearHojaStock(libro, datos);
        CrearHojaArticulos(libro, datos);

        using var stream = new MemoryStream();
        libro.SaveAs(stream);
        return stream.ToArray();
    }

    private void EstilarEncabezado(IXLWorksheet hoja, int fila, int columnas, string colorHex)
    {
        var rango = hoja.Range(fila, 1, fila, columnas);
        rango.Style.Fill.BackgroundColor = XLColor.FromHtml(colorHex);
        rango.Style.Font.FontColor = XLColor.White;
        rango.Style.Font.Bold = true;
        rango.Style.Alignment.Vertical = XLAlignmentVerticalValues.Center;
        hoja.Row(fila).Height = 22;
    }

    private void EstilarTitulo(IXLWorksheet hoja, string titulo, string nombreEmpresa)
    {
        hoja.Cell(1, 1).Value = nombreEmpresa;
        hoja.Cell(1, 1).Style.Font.Bold = true;
        hoja.Cell(1, 1).Style.Font.FontSize = 16;
        hoja.Cell(1, 1).Style.Font.FontColor = XLColor.FromHtml(ColorPrimarioOscuro);

        hoja.Cell(2, 1).Value = titulo;
        hoja.Cell(2, 1).Style.Font.FontSize = 12;
        hoja.Cell(2, 1).Style.Font.FontColor = XLColor.FromHtml(ColorTextoSecundario);

        hoja.Cell(3, 1).Value = $"Generado: {DateTime.Now:dd/MM/yyyy HH:mm}";
        hoja.Cell(3, 1).Style.Font.FontSize = 9;
        hoja.Cell(3, 1).Style.Font.FontColor = XLColor.FromHtml(ColorTextoSecundario);
        hoja.Cell(3, 1).Style.Font.Italic = true;
    }

    private void CrearHojaResumen(XLWorkbook libro, DatosReporte d, DateTime desde, DateTime hasta)
    {
        var hoja = libro.Worksheets.Add("Resumen");
        EstilarTitulo(hoja, $"Reporte de Producción e Inventario ({desde:dd/MM/yyyy} - {hasta:dd/MM/yyyy})", d.NombreEmpresa);

        var totalPlanificado = d.PlanVsReal.Sum(p => p.TotalPlanificado);
        var totalReal = d.PlanVsReal.Sum(p => p.TotalReal);
        var cumplimientoGlobal = totalPlanificado > 0 ? totalReal / totalPlanificado * 100 : 0;
        var totalPerdidas = d.Perdidas.Sum(p => p.ValorTotalPerdido);
        var valorStock = d.Stock.Sum(s => s.ValorTotal);

        var kpis = new (string Titulo, string Valor, string Color)[]
        {
            ("Total Planificado", totalPlanificado.ToString("N0"), ColorInfo),
            ("Total Real Producido", totalReal.ToString("N0"), ColorPrimario),
            ("Cumplimiento Global", $"{cumplimientoGlobal:N1}%", cumplimientoGlobal >= 100 ? ColorExito : ColorError),
            ("Pérdidas (período)", totalPerdidas.ToString("C0"), ColorError),
            ("Valor de Stock Actual", valorStock.ToString("C0"), ColorExito),
            ("Artículos en Catálogo", d.Articulos.Count.ToString(), ColorTextoSecundario),
        };

        var filaBase = 5;
        for (var i = 0; i < kpis.Length; i++)
        {
            var fila = filaBase + i;
            hoja.Cell(fila, 1).Value = kpis[i].Titulo;
            hoja.Cell(fila, 1).Style.Font.FontColor = XLColor.FromHtml(ColorTextoSecundario);
            hoja.Cell(fila, 2).Value = kpis[i].Valor;
            hoja.Cell(fila, 2).Style.Font.Bold = true;
            hoja.Cell(fila, 2).Style.Font.FontSize = 13;
            hoja.Cell(fila, 2).Style.Font.FontColor = XLColor.FromHtml(kpis[i].Color);
        }

        hoja.Column(1).Width = 26;
        hoja.Column(2).Width = 20;
    }

    private void CrearHojaPlanVsReal(XLWorkbook libro, DatosReporte d)
    {
        var hoja = libro.Worksheets.Add("Plan vs Real");
        EstilarTitulo(hoja, "Producción: Planificado vs Real por día", d.NombreEmpresa);

        var filaEncabezado = 5;
        hoja.Cell(filaEncabezado, 1).Value = "Fecha";
        hoja.Cell(filaEncabezado, 2).Value = "Planificado";
        hoja.Cell(filaEncabezado, 3).Value = "Real";
        hoja.Cell(filaEncabezado, 4).Value = "Variación %";
        EstilarEncabezado(hoja, filaEncabezado, 4, ColorPrimarioOscuro);

        var fila = filaEncabezado + 1;
        foreach (var p in d.PlanVsReal)
        {
            var variacion = p.TotalPlanificado > 0 ? (p.TotalReal - p.TotalPlanificado) / p.TotalPlanificado * 100 : 0;

            hoja.Cell(fila, 1).Value = p.Fecha;
            hoja.Cell(fila, 1).Style.DateFormat.Format = "dd/MM/yyyy";
            hoja.Cell(fila, 2).Value = (double)p.TotalPlanificado;
            hoja.Cell(fila, 3).Value = (double)p.TotalReal;
            hoja.Cell(fila, 4).Value = (double)variacion / 100;
            hoja.Cell(fila, 4).Style.NumberFormat.Format = "+0.0%;-0.0%";
            hoja.Cell(fila, 4).Style.Font.FontColor = XLColor.FromHtml(variacion >= 0 ? ColorExito : ColorError);
            hoja.Cell(fila, 4).Style.Font.Bold = true;
            fila++;
        }

        AplicarBordesYZebra(hoja, filaEncabezado, fila - 1, 4);
        hoja.Columns(1, 4).AdjustToContents();
    }

    private void CrearHojaDistribucion(XLWorkbook libro, DatosReporte d)
    {
        var hoja = libro.Worksheets.Add("Distribución CC");
        EstilarTitulo(hoja, "Distribución de Producción por Centro de Costo", d.NombreEmpresa);

        var filaEncabezado = 5;
        hoja.Cell(filaEncabezado, 1).Value = "Centro de Costo";
        hoja.Cell(filaEncabezado, 2).Value = "Órdenes";
        hoja.Cell(filaEncabezado, 3).Value = "Unidades Producidas";
        hoja.Cell(filaEncabezado, 4).Value = "Inversión";
        EstilarEncabezado(hoja, filaEncabezado, 4, ColorPrimarioOscuro);

        var fila = filaEncabezado + 1;
        foreach (var item in d.Distribucion)
        {
            hoja.Cell(fila, 1).Value = item.CentroCosto;
            hoja.Cell(fila, 2).Value = item.TotalOrdenes;
            hoja.Cell(fila, 3).Value = (double)item.TotalUnidadesProducidas;
            hoja.Cell(fila, 4).Value = (double)item.InversionTotal;
            hoja.Cell(fila, 4).Style.NumberFormat.Format = "$#,##0";
            fila++;
        }

        AplicarBordesYZebra(hoja, filaEncabezado, fila - 1, 4);
        hoja.Columns(1, 4).AdjustToContents();
    }

    private void CrearHojaCumplimiento(XLWorkbook libro, DatosReporte d)
    {
        var hoja = libro.Worksheets.Add("Cumplimiento CC");
        EstilarTitulo(hoja, "Cumplimiento de Planificación por Centro de Costo", d.NombreEmpresa);

        var filaEncabezado = 5;
        hoja.Cell(filaEncabezado, 1).Value = "Centro de Costo";
        hoja.Cell(filaEncabezado, 2).Value = "Órdenes Finalizadas";
        hoja.Cell(filaEncabezado, 3).Value = "Órdenes a Tiempo";
        hoja.Cell(filaEncabezado, 4).Value = "% Cumplimiento";
        EstilarEncabezado(hoja, filaEncabezado, 4, ColorPrimarioOscuro);

        var fila = filaEncabezado + 1;
        foreach (var item in d.Cumplimiento)
        {
            hoja.Cell(fila, 1).Value = item.CentroCosto;
            hoja.Cell(fila, 2).Value = item.TotalOrdenesFinalizadas;
            hoja.Cell(fila, 3).Value = item.OrdenesATiempo;
            hoja.Cell(fila, 4).Value = (double)item.PorcentajeCumplimiento / 100;
            hoja.Cell(fila, 4).Style.NumberFormat.Format = "0.0%";
            hoja.Cell(fila, 4).Style.Font.FontColor = XLColor.FromHtml(item.PorcentajeCumplimiento >= 90 ? ColorExito : item.PorcentajeCumplimiento >= 70 ? "#F59E0B" : ColorError);
            hoja.Cell(fila, 4).Style.Font.Bold = true;
            fila++;
        }

        AplicarBordesYZebra(hoja, filaEncabezado, fila - 1, 4);
        hoja.Columns(1, 4).AdjustToContents();
    }

    private void CrearHojaPerdidas(XLWorkbook libro, DatosReporte d)
    {
        var hoja = libro.Worksheets.Add("Pérdidas");
        EstilarTitulo(hoja, "Pérdidas de Inventario por Motivo", d.NombreEmpresa);

        var filaEncabezado = 5;
        hoja.Cell(filaEncabezado, 1).Value = "Motivo";
        hoja.Cell(filaEncabezado, 2).Value = "Cantidad Perdida";
        hoja.Cell(filaEncabezado, 3).Value = "Valor Perdido";
        EstilarEncabezado(hoja, filaEncabezado, 3, ColorError);

        var fila = filaEncabezado + 1;
        foreach (var item in d.Perdidas)
        {
            hoja.Cell(fila, 1).Value = item.Motivo;
            hoja.Cell(fila, 2).Value = (double)item.CantidadTotalPerdida;
            hoja.Cell(fila, 3).Value = (double)item.ValorTotalPerdido;
            hoja.Cell(fila, 3).Style.NumberFormat.Format = "$#,##0";
            fila++;
        }

        AplicarBordesYZebra(hoja, filaEncabezado, fila - 1, 3);
        hoja.Columns(1, 3).AdjustToContents();
    }

    private void CrearHojaStock(XLWorkbook libro, DatosReporte d)
    {
        var hoja = libro.Worksheets.Add("Stock Actual");
        EstilarTitulo(hoja, "Stock Consolidado Actual", d.NombreEmpresa);

        var filaEncabezado = 5;
        string[] columnas = { "SKU", "Artículo", "Bodega", "Centro de Costo", "Cantidad", "Unidad", "Costo Unitario", "Valor Total", "Requiere Pedido" };
        for (var c = 0; c < columnas.Length; c++)
            hoja.Cell(filaEncabezado, c + 1).Value = columnas[c];
        EstilarEncabezado(hoja, filaEncabezado, columnas.Length, ColorPrimarioOscuro);

        var fila = filaEncabezado + 1;
        foreach (var s in d.Stock)
        {
            hoja.Cell(fila, 1).Value = s.SKU;
            hoja.Cell(fila, 2).Value = s.Articulo;
            hoja.Cell(fila, 3).Value = s.Bodega;
            hoja.Cell(fila, 4).Value = s.CentroCosto;
            hoja.Cell(fila, 5).Value = (double)s.CantidadActual;
            hoja.Cell(fila, 6).Value = s.Unidad;
            hoja.Cell(fila, 7).Value = (double)s.CostoUnitarioLote;
            hoja.Cell(fila, 7).Style.NumberFormat.Format = "$#,##0.00";
            hoja.Cell(fila, 8).Value = (double)s.ValorTotal;
            hoja.Cell(fila, 8).Style.NumberFormat.Format = "$#,##0";
            hoja.Cell(fila, 9).Value = s.RequierePedido ? "Sí" : "No";
            if (s.RequierePedido)
                hoja.Cell(fila, 9).Style.Font.FontColor = XLColor.FromHtml("#F59E0B");
            fila++;
        }

        AplicarBordesYZebra(hoja, filaEncabezado, fila - 1, columnas.Length);
        hoja.Columns(1, columnas.Length).AdjustToContents();
        hoja.SheetView.FreezeRows(filaEncabezado);
    }

    private void CrearHojaArticulos(XLWorkbook libro, DatosReporte d)
    {
        var hoja = libro.Worksheets.Add("Artículos");
        EstilarTitulo(hoja, "Catálogo de Artículos", d.NombreEmpresa);

        var filaEncabezado = 5;
        string[] columnas = { "SKU", "Nombre", "Tipo", "Unidad", "Costo Promedio", "Precio Venta", "Stock Mínimo", "Punto Reorden", "Estado" };
        for (var c = 0; c < columnas.Length; c++)
            hoja.Cell(filaEncabezado, c + 1).Value = columnas[c];
        EstilarEncabezado(hoja, filaEncabezado, columnas.Length, ColorPrimarioOscuro);

        var fila = filaEncabezado + 1;
        foreach (var a in d.Articulos)
        {
            hoja.Cell(fila, 1).Value = a.SKU;
            hoja.Cell(fila, 2).Value = a.Nombre;
            hoja.Cell(fila, 3).Value = a.TipoArticulo;
            hoja.Cell(fila, 4).Value = a.Unidad;
            hoja.Cell(fila, 5).Value = (double)a.CostoPromedio;
            hoja.Cell(fila, 5).Style.NumberFormat.Format = "$#,##0.00";
            hoja.Cell(fila, 6).Value = (double)a.PrecioVenta;
            hoja.Cell(fila, 6).Style.NumberFormat.Format = "$#,##0.00";
            hoja.Cell(fila, 7).Value = (double)a.StockMinimo;
            hoja.Cell(fila, 8).Value = (double)a.PuntoReorden;
            hoja.Cell(fila, 9).Value = a.Estado ? "Activo" : "Inactivo";
            hoja.Cell(fila, 9).Style.Font.FontColor = XLColor.FromHtml(a.Estado ? ColorExito : ColorError);
            fila++;
        }

        AplicarBordesYZebra(hoja, filaEncabezado, fila - 1, columnas.Length);
        hoja.Columns(1, columnas.Length).AdjustToContents();
        hoja.SheetView.FreezeRows(filaEncabezado);
    }

    private void AplicarBordesYZebra(IXLWorksheet hoja, int filaEncabezado, int ultimaFila, int columnas)
    {
        if (ultimaFila < filaEncabezado + 1)
            return;

        var rango = hoja.Range(filaEncabezado, 1, ultimaFila, columnas);
        rango.Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
        rango.Style.Border.InsideBorder = XLBorderStyleValues.Hair;
        rango.Style.Border.OutsideBorderColor = XLColor.FromHtml(ColorBordes);
        rango.Style.Border.InsideBorderColor = XLColor.FromHtml(ColorBordes);

        for (var fila = filaEncabezado + 1; fila <= ultimaFila; fila++)
        {
            if ((fila - filaEncabezado) % 2 == 0)
                hoja.Range(fila, 1, fila, columnas).Style.Fill.BackgroundColor = XLColor.FromHtml(ColorFondoClaro);
        }
    }

    // ==================================================================
    // PDF (QuestPDF)
    // ==================================================================

    public async Task<byte[]> GenerarPdfAsync(DateTime desde, DateTime hasta)
    {
        var datos = await RecolectarDatosAsync(desde, hasta);

        var documento = Document.Create(contenedor =>
        {
            contenedor.Page(pagina =>
            {
                pagina.Size(PageSizes.A4);
                pagina.Margin(30);
                pagina.DefaultTextStyle(x => x.FontSize(9).FontColor(ColorTextoOscuro));

                pagina.Header().Element(c => ComponerEncabezado(c, datos.NombreEmpresa, desde, hasta));
                pagina.Content().Element(c => ComponerContenido(c, datos));
                pagina.Footer().AlignCenter().Text(t =>
                {
                    t.CurrentPageNumber().FontSize(8).FontColor(ColorTextoSecundario);
                    t.Span(" / ").FontSize(8).FontColor(ColorTextoSecundario);
                    t.TotalPages().FontSize(8).FontColor(ColorTextoSecundario);
                });
            });
        });

        return documento.GeneratePdf();
    }

    private void ComponerEncabezado(QuestPDF.Infrastructure.IContainer contenedor, string nombreEmpresa, DateTime desde, DateTime hasta)
    {
        contenedor.Background(ColorPrimarioOscuro).Padding(20).Row(fila =>
        {
            fila.RelativeItem().Column(col =>
            {
                col.Item().Text(nombreEmpresa).FontSize(18).Bold().FontColor(Colors.White);
                col.Item().Text("Reporte de Producción e Inventario").FontSize(11).FontColor(Colors.White);
                col.Item().PaddingTop(3).Text($"Período: {desde:dd/MM/yyyy} — {hasta:dd/MM/yyyy}").FontSize(8).FontColor("#D8D0FF");
            });
            fila.ConstantItem(140).AlignRight().AlignMiddle()
                .Text($"Generado\n{DateTime.Now:dd/MM/yyyy HH:mm}").FontSize(8).FontColor("#D8D0FF").AlignRight();
        });
    }

    private void ComponerContenido(QuestPDF.Infrastructure.IContainer contenedor, DatosReporte d)
    {
        contenedor.PaddingVertical(15).Column(col =>
        {
            col.Spacing(16);

            col.Item().Element(c => ComponerKpis(c, d));
            col.Item().Element(c => ComponerBarrasPlanVsReal(c, d));
            col.Item().Element(c => ComponerTablaDistribucion(c, d));
            col.Item().Element(c => ComponerTablaCumplimiento(c, d));
            col.Item().Element(c => ComponerTablaPerdidas(c, d));
            col.Item().PageBreak();
            col.Item().Element(c => ComponerTablaStock(c, d));
        });
    }

    private void ComponerTitulo(QuestPDF.Infrastructure.IContainer contenedor, string texto) =>
        contenedor.Text(texto).FontSize(13).Bold().FontColor(ColorPrimarioOscuro);

    private void ComponerKpis(QuestPDF.Infrastructure.IContainer contenedor, DatosReporte d)
    {
        var totalPlanificado = d.PlanVsReal.Sum(p => p.TotalPlanificado);
        var totalReal = d.PlanVsReal.Sum(p => p.TotalReal);
        var cumplimientoGlobal = totalPlanificado > 0 ? totalReal / totalPlanificado * 100 : 0;
        var totalPerdidas = d.Perdidas.Sum(p => p.ValorTotalPerdido);
        var valorStock = d.Stock.Sum(s => s.ValorTotal);

        var kpis = new (string Titulo, string Valor, string Color)[]
        {
            ("Planificado", totalPlanificado.ToString("N0"), ColorInfo),
            ("Real Producido", totalReal.ToString("N0"), ColorPrimario),
            ("Cumplimiento", $"{cumplimientoGlobal:N1}%", cumplimientoGlobal >= 100 ? ColorExito : ColorError),
            ("Pérdidas", totalPerdidas.ToString("C0"), ColorError),
            ("Valor Stock", valorStock.ToString("C0"), ColorExito),
        };

        contenedor.Row(fila =>
        {
            foreach (var kpi in kpis)
            {
                fila.RelativeItem().Border(1).BorderColor(ColorBordes).Background(Colors.White)
                    .Padding(10).Column(col =>
                    {
                        col.Item().Text(kpi.Titulo).FontSize(7.5f).FontColor(ColorTextoSecundario);
                        col.Item().PaddingTop(2).Text(kpi.Valor).FontSize(14).Bold().FontColor(kpi.Color);
                    });
            }
        });
    }

    // Barras estilo Dashboard: verde cuando cumple/supera el plan, rojo cuando
    // queda por debajo, dibujadas con primitivas de QuestPDF (sin depender de
    // renderizar el SVG del navegador).
    private void ComponerBarrasPlanVsReal(QuestPDF.Infrastructure.IContainer contenedor, DatosReporte d)
    {
        contenedor.Column(col =>
        {
            col.Item().Element(c => ComponerTitulo(c, "Variación de Producción vs Plan"));
            col.Item().PaddingBottom(4).Text("Real sobre planificado por día").FontSize(8).FontColor(ColorTextoSecundario);

            if (d.PlanVsReal.Count == 0)
            {
                col.Item().Text("Sin datos en el período seleccionado.").FontColor(ColorTextoSecundario).Italic();
                return;
            }

            var puntos = d.PlanVsReal.Select(p => new
            {
                p.Fecha,
                Variacion = p.TotalPlanificado > 0 ? (p.TotalReal - p.TotalPlanificado) / p.TotalPlanificado * 100 : 0
            }).ToList();

            var maxAbs = Math.Max(puntos.Max(p => Math.Abs(p.Variacion)), 5);

            col.Item().Height(90).Row(fila =>
            {
                foreach (var p in puntos)
                {
                    var alturaPorcentaje = (float)(Math.Abs(p.Variacion) / maxAbs);
                    var color = p.Variacion >= 0 ? ColorExito : ColorError;

                    fila.RelativeItem().AlignBottom().Column(barraCol =>
                    {
                        if (p.Variacion >= 0)
                        {
                            barraCol.Item().Text($"{(p.Variacion >= 0 ? "+" : "")}{p.Variacion:N1}%")
                                .FontSize(6).FontColor(color).AlignCenter();
                            barraCol.Item().AlignCenter().Height(60 * alturaPorcentaje).Width(14).Background(color);
                        }
                        else
                        {
                            barraCol.Item().AlignCenter().Height(60 * alturaPorcentaje).Width(14).Background(color);
                            barraCol.Item().Text($"{p.Variacion:N1}%")
                                .FontSize(6).FontColor(color).AlignCenter();
                        }
                        barraCol.Item().PaddingTop(2).Text(p.Fecha.ToString("dd/MM")).FontSize(6).FontColor(ColorTextoSecundario).AlignCenter();
                    });
                }
            });
        });
    }

    private void ComponerTablaDistribucion(QuestPDF.Infrastructure.IContainer contenedor, DatosReporte d)
    {
        contenedor.Column(col =>
        {
            col.Item().Element(c => ComponerTitulo(c, "Distribución de Producción por Centro de Costo"));
            col.Item().PaddingTop(6).Table(tabla =>
            {
                tabla.ColumnsDefinition(c =>
                {
                    c.RelativeColumn(3);
                    c.RelativeColumn(1);
                    c.RelativeColumn(1.5f);
                    c.RelativeColumn(1.5f);
                });

                EncabezadoTabla(tabla, null, "Centro de Costo", "Órdenes", "Unidades", "Inversión");

                foreach (var item in d.Distribucion)
                {
                    CeldaTabla(tabla, item.CentroCosto);
                    CeldaTabla(tabla, item.TotalOrdenes.ToString(), alinearDerecha: true);
                    CeldaTabla(tabla, item.TotalUnidadesProducidas.ToString("N0"), alinearDerecha: true);
                    CeldaTabla(tabla, item.InversionTotal.ToString("C0"), alinearDerecha: true);
                }
            });
        });
    }

    private void ComponerTablaCumplimiento(QuestPDF.Infrastructure.IContainer contenedor, DatosReporte d)
    {
        contenedor.Column(col =>
        {
            col.Item().Element(c => ComponerTitulo(c, "Cumplimiento de Planificación"));
            col.Item().PaddingTop(6).Table(tabla =>
            {
                tabla.ColumnsDefinition(c =>
                {
                    c.RelativeColumn(3);
                    c.RelativeColumn(1.5f);
                    c.RelativeColumn(1.5f);
                    c.RelativeColumn(1.5f);
                });

                EncabezadoTabla(tabla, null, "Centro de Costo", "Finalizadas", "A Tiempo", "% Cumplimiento");

                foreach (var item in d.Cumplimiento)
                {
                    var color = item.PorcentajeCumplimiento >= 90 ? ColorExito : item.PorcentajeCumplimiento >= 70 ? "#F59E0B" : ColorError;
                    CeldaTabla(tabla, item.CentroCosto);
                    CeldaTabla(tabla, item.TotalOrdenesFinalizadas.ToString(), alinearDerecha: true);
                    CeldaTabla(tabla, item.OrdenesATiempo.ToString(), alinearDerecha: true);
                    tabla.Cell().Element(CeldaBase).AlignRight().Text($"{item.PorcentajeCumplimiento:N1}%").Bold().FontColor(color);
                }
            });
        });
    }

    private void ComponerTablaPerdidas(QuestPDF.Infrastructure.IContainer contenedor, DatosReporte d)
    {
        contenedor.Column(col =>
        {
            col.Item().Element(c => ComponerTitulo(c, "Pérdidas de Inventario por Motivo"));

            if (d.Perdidas.Count == 0)
            {
                col.Item().PaddingTop(4).Text("Sin pérdidas registradas en el período.").FontColor(ColorTextoSecundario).Italic();
                return;
            }

            col.Item().PaddingTop(6).Table(tabla =>
            {
                tabla.ColumnsDefinition(c =>
                {
                    c.RelativeColumn(3);
                    c.RelativeColumn(2);
                    c.RelativeColumn(2);
                });

                EncabezadoTabla(tabla, ColorError, "Motivo", "Cantidad Perdida", "Valor Perdido");

                foreach (var item in d.Perdidas)
                {
                    CeldaTabla(tabla, item.Motivo);
                    CeldaTabla(tabla, item.CantidadTotalPerdida.ToString("N2"), alinearDerecha: true);
                    CeldaTabla(tabla, item.ValorTotalPerdido.ToString("C0"), alinearDerecha: true);
                }
            });
        });
    }

    private void ComponerTablaStock(QuestPDF.Infrastructure.IContainer contenedor, DatosReporte d)
    {
        contenedor.Column(col =>
        {
            col.Item().Element(c => ComponerTitulo(c, "Stock Consolidado Actual"));
            col.Item().PaddingTop(6).Table(tabla =>
            {
                tabla.ColumnsDefinition(c =>
                {
                    c.RelativeColumn(1.3f);
                    c.RelativeColumn(2.5f);
                    c.RelativeColumn(1.5f);
                    c.RelativeColumn(1.3f);
                    c.RelativeColumn(1.5f);
                });

                EncabezadoTabla(tabla, null, "SKU", "Artículo", "Bodega", "Cantidad", "Valor Total");

                foreach (var s in d.Stock)
                {
                    CeldaTabla(tabla, s.SKU);
                    CeldaTabla(tabla, s.Articulo);
                    CeldaTabla(tabla, s.Bodega);
                    CeldaTabla(tabla, $"{s.CantidadActual:N2} {s.Unidad}", alinearDerecha: true);
                    CeldaTabla(tabla, s.ValorTotal.ToString("C0"), alinearDerecha: true);
                }
            });
        });
    }

    private void EncabezadoTabla(TableDescriptor tabla, string? colorFondo = null, params string[] titulos)
    {
        var color = colorFondo ?? ColorPrimarioOscuro;

        foreach (var titulo in titulos)
        {
            tabla.Cell().Background(color).Padding(5).Text(titulo).FontColor(Colors.White).Bold().FontSize(8);
        }
    }

    private static QuestPDF.Infrastructure.IContainer CeldaBase(QuestPDF.Infrastructure.IContainer contenedor) =>
        contenedor.BorderBottom(1).BorderColor("#E8E9EF").PaddingVertical(4).PaddingHorizontal(5);

    private void CeldaTabla(TableDescriptor tabla, string texto, bool alinearDerecha = false)
    {
        var celda = tabla.Cell().Element(CeldaBase);
        if (alinearDerecha)
            celda.AlignRight().Text(texto).FontSize(8);
        else
            celda.Text(texto).FontSize(8);
    }
}
