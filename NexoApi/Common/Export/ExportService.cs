using ClosedXML.Excel;
using NexoApi.Features.Catalogo.Dtos;
using NexoApi.Features.Crm.Dtos;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

namespace NexoApi.Common.Export;

public static class ExportService
{
    public static byte[] GenerarExcelArticulos(IEnumerable<ArticuloItem> articulos)
    {
        using var wb = new XLWorkbook();
        var ws = wb.Worksheets.Add("Artículos");

        string[] headers =
        {
            "SKU", "Nombre", "Tipo", "Marca", "Grupo Mayor", "Grupo Menor",
            "Presentación", "Costo", "P.Público", "P.Bodega", "P.Crédito",
            "Existencias", "Stock Mín.", "Punto Reorden", "Estado"
        };
        EstilizarEncabezados(ws, headers);

        int row = 2;
        foreach (var a in articulos)
        {
            ws.Cell(row, 1).Value = a.Referencia;
            ws.Cell(row, 2).Value = a.Nombre;
            ws.Cell(row, 3).Value = a.TipoArticulo;
            ws.Cell(row, 4).Value = a.MarcaNombre ?? a.MarcaCodigo ?? "";
            ws.Cell(row, 5).Value = a.GrupoMayorNombre ?? a.GrupoMayorCodigo ?? "";
            ws.Cell(row, 6).Value = a.GrupoMenorNombre ?? a.GrupoMenorCodigo ?? "";
            ws.Cell(row, 7).Value = a.PresentacionNombre ?? a.PresentacionCodigo ?? "";
            ws.Cell(row, 8).Value = (double)(a.Costo ?? 0);
            ws.Cell(row, 9).Value = (double)(a.PPublico ?? 0);
            ws.Cell(row, 10).Value = (double)(a.PBodega ?? 0);
            ws.Cell(row, 11).Value = (double)(a.PCredito ?? 0);
            ws.Cell(row, 12).Value = (double)a.Existencias;
            ws.Cell(row, 13).Value = (double)a.StockMinimo;
            ws.Cell(row, 14).Value = (double)a.PuntoReorden;
            ws.Cell(row, 15).Value = a.Estado ? "Activo" : "Inactivo";

            if (row % 2 == 0)
                ws.Row(row).Style.Fill.BackgroundColor = XLColor.FromHtml("#F5F7FA");

            row++;
        }

        for (int col = 8; col <= 14; col++)
            ws.Column(col).Style.NumberFormat.Format = "#,##0.00";

        ws.Columns().AdjustToContents();
        ws.SheetView.FreezeRows(1);

        using var ms = new MemoryStream();
        wb.SaveAs(ms);
        return ms.ToArray();
    }

    public static byte[] GenerarPdfCotizacion(CotizacionPdfData d)
    {
        var total = d.Lineas.Sum(l => l.Subtotal);
        const string azul = "#1E3A5F";

        return Document.Create(container => container.Page(page =>
        {
            page.Size(PageSizes.A4);
            page.MarginHorizontal(1.5f, Unit.Centimetre);
            page.MarginVertical(1.5f, Unit.Centimetre);
            page.DefaultTextStyle(x => x.FontSize(9f));

            page.Content().Column(col =>
            {
                // ── Encabezado ─────────────────────────────
                col.Item().Row(row =>
                {
                    row.RelativeItem().Column(c =>
                    {
                        c.Item().Text(d.Empresa).Bold().FontSize(18).FontColor(azul);
                        c.Item().Text("Cotización de Venta").FontSize(11).FontColor(Colors.Grey.Darken1);
                    });
                    row.RelativeItem().Column(c =>
                    {
                        c.Item().AlignRight().Text($"COTIZACIÓN #{d.CotizacionID}").Bold().FontSize(14).FontColor(azul);
                        c.Item().AlignRight().Text($"Fecha: {d.Fecha:dd/MM/yyyy}").FontColor(Colors.Grey.Darken2);
                        if (d.ValidoHasta.HasValue)
                        {
                            var color = d.ValidoHasta.Value < DateTime.Today ? Colors.Red.Darken1 : Colors.Grey.Darken2;
                            c.Item().AlignRight().Text($"Válida hasta: {d.ValidoHasta.Value:dd/MM/yyyy}").FontColor(color);
                        }
                        else
                        {
                            c.Item().AlignRight().Text("Sin fecha límite").FontColor(Colors.Grey.Medium);
                        }
                    });
                });

                col.Item().PaddingVertical(8).LineHorizontal(2).LineColor(azul);

                col.Item().PaddingBottom(12).Column(c =>
                {
                    c.Item().Text("Para:").FontSize(8).Bold().FontColor(Colors.Grey.Medium);
                    c.Item().Text(d.Cliente).Bold().FontSize(12);
                });

                // ── Tabla de líneas ────────────────────────
                col.Item().Table(table =>
                {
                    table.ColumnsDefinition(cols =>
                    {
                        cols.ConstantColumn(55);
                        cols.RelativeColumn(3);
                        cols.ConstantColumn(55);
                        cols.ConstantColumn(82);
                        cols.ConstantColumn(82);
                    });

                    table.Header(h =>
                    {
                        h.Cell().Background(azul).Padding(5).Text("SKU").FontColor(Colors.White).Bold().FontSize(8.5f);
                        h.Cell().Background(azul).Padding(5).Text("Descripción").FontColor(Colors.White).Bold().FontSize(8.5f);
                        h.Cell().Background(azul).Padding(5).AlignRight().Text("Cant.").FontColor(Colors.White).Bold().FontSize(8.5f);
                        h.Cell().Background(azul).Padding(5).AlignRight().Text("P. Unitario").FontColor(Colors.White).Bold().FontSize(8.5f);
                        h.Cell().Background(azul).Padding(5).AlignRight().Text("Subtotal").FontColor(Colors.White).Bold().FontSize(8.5f);
                    });

                    int idx = 0;
                    foreach (var l in d.Lineas)
                    {
                        string bg = idx++ % 2 == 0 ? Colors.White : "#F9FAFB";
                        table.Cell().Background(bg).BorderBottom(0.5f).BorderColor("#E5E7EB").Padding(5).Text(l.SkuArticulo).FontSize(8.5f);
                        table.Cell().Background(bg).BorderBottom(0.5f).BorderColor("#E5E7EB").Padding(5).Text(l.NombreArticulo).FontSize(8.5f);
                        table.Cell().Background(bg).BorderBottom(0.5f).BorderColor("#E5E7EB").Padding(5).AlignRight().Text($"{l.Cantidad:N2}").FontSize(8.5f);
                        table.Cell().Background(bg).BorderBottom(0.5f).BorderColor("#E5E7EB").Padding(5).AlignRight().Text($"{l.PrecioUnitario:N0}").FontSize(8.5f);
                        table.Cell().Background(bg).BorderBottom(0.5f).BorderColor("#E5E7EB").Padding(5).AlignRight().Text($"{l.Subtotal:N0}").Bold().FontSize(8.5f);
                    }
                });

                // ── Total ──────────────────────────────────
                col.Item().AlignRight().PaddingTop(10).Row(row =>
                {
                    row.AutoItem().Padding(6).Text("TOTAL").Bold().FontSize(11);
                    row.ConstantItem(82).Padding(6).AlignRight().Text($"${total:N0}").Bold().FontSize(14).FontColor(azul);
                });

                // ── Notas ──────────────────────────────────
                if (!string.IsNullOrWhiteSpace(d.Notas))
                {
                    col.Item().PaddingTop(20).Column(c =>
                    {
                        c.Item().Text("Notas:").Bold().FontSize(9).FontColor(Colors.Grey.Medium);
                        c.Item().Text(d.Notas).FontSize(9).FontColor("#374141");
                    });
                }
            });

            page.Footer().AlignCenter().Text(t =>
            {
                t.DefaultTextStyle(s => s.FontSize(8).FontColor(Colors.Grey.Medium));
                t.Span($"Generado por NEXO ERP — {DateTime.Now:dd/MM/yyyy HH:mm}");
            });
        })).GeneratePdf();
    }

    public static byte[] GenerarFichaTecnicaPdf(ArticuloItem a, byte[]? imagenBytes, string? imagenContentType, string empresa)
    {
        const string azul = "#1E3A5F";

        return Document.Create(container => container.Page(page =>
        {
            page.Size(PageSizes.A4);
            page.MarginHorizontal(1.5f, Unit.Centimetre);
            page.MarginVertical(1.5f, Unit.Centimetre);
            page.DefaultTextStyle(x => x.FontSize(9f));

            page.Content().Column(col =>
            {
                // Encabezado
                col.Item().Row(row =>
                {
                    row.RelativeItem().Column(c =>
                    {
                        c.Item().Text(empresa).Bold().FontSize(16).FontColor(azul);
                        c.Item().Text("Ficha Técnica de Artículo").FontSize(10).FontColor(Colors.Grey.Darken1);
                    });
                    row.AutoItem().AlignRight().Column(c =>
                    {
                        c.Item().AlignRight().Text(a.Referencia).Bold().FontSize(14).FontColor(azul);
                        c.Item().AlignRight().Text(a.Estado ? "ACTIVO" : "INACTIVO")
                            .FontColor(a.Estado ? Colors.Green.Darken2 : Colors.Red.Darken1).FontSize(9);
                    });
                });

                col.Item().PaddingVertical(6).LineHorizontal(2).LineColor(azul);

                // Imagen + datos básicos
                col.Item().Row(row =>
                {
                    if (imagenBytes != null && imagenBytes.Length > 0)
                    {
                        row.ConstantItem(110).PaddingRight(12)
                            .Image(imagenBytes).FitArea();
                    }

                    row.RelativeItem().Column(c =>
                    {
                        c.Item().Text(a.Nombre).Bold().FontSize(13);
                        if (!string.IsNullOrWhiteSpace(a.Descripcion))
                            c.Item().PaddingTop(4).Text(a.Descripcion).FontSize(9).FontColor(Colors.Grey.Darken2);
                        c.Item().PaddingTop(8).Table(t =>
                        {
                            t.ColumnsDefinition(cols => { cols.RelativeColumn(); cols.RelativeColumn(); });
                            void Fila(string label, string? val)
                            {
                                if (string.IsNullOrWhiteSpace(val)) return;
                                t.Cell().Padding(3).Text(label).FontColor(Colors.Grey.Medium).FontSize(8);
                                t.Cell().Padding(3).Text(val).FontSize(8.5f);
                            }
                            Fila("Tipo", a.TipoArticulo);
                            Fila("Marca", a.MarcaNombre ?? a.MarcaCodigo);
                            Fila("Grupo mayor", a.GrupoMayorNombre ?? a.GrupoMayorCodigo);
                            Fila("Grupo menor", a.GrupoMenorNombre ?? a.GrupoMenorCodigo);
                            Fila("Presentación", a.PresentacionNombre ?? a.PresentacionCodigo);
                            Fila("IVA", a.IvaDescripcion is not null ? $"{a.IvaValor}% – {a.IvaDescripcion}" : null);
                            Fila("Peso", a.Peso.HasValue ? $"{a.Peso:N2} kg" : null);
                        });
                    });
                });

                col.Item().PaddingVertical(10).LineHorizontal(1).LineColor("#E5E7EB");

                // Tabla de precios
                col.Item().PaddingBottom(6).Text("Precios").Bold().FontSize(10).FontColor(azul);
                col.Item().Table(t =>
                {
                    t.ColumnsDefinition(cols =>
                    {
                        cols.RelativeColumn();
                        cols.ConstantColumn(90);
                        cols.ConstantColumn(90);
                    });

                    t.Header(h =>
                    {
                        h.Cell().Background(azul).Padding(5).Text("Lista de precio").FontColor(Colors.White).Bold().FontSize(8.5f);
                        h.Cell().Background(azul).Padding(5).AlignRight().Text("Precio").FontColor(Colors.White).Bold().FontSize(8.5f);
                        h.Cell().Background(azul).Padding(5).AlignRight().Text("Costo").FontColor(Colors.White).Bold().FontSize(8.5f);
                    });

                    void FilaPrecio(string label, decimal? precio, decimal? costo, string bg)
                    {
                        t.Cell().Background(bg).BorderBottom(0.5f).BorderColor("#E5E7EB").Padding(5).Text(label).FontSize(8.5f);
                        t.Cell().Background(bg).BorderBottom(0.5f).BorderColor("#E5E7EB").Padding(5).AlignRight()
                            .Text(precio.HasValue ? $"${precio:N0}" : "–").FontSize(8.5f);
                        t.Cell().Background(bg).BorderBottom(0.5f).BorderColor("#E5E7EB").Padding(5).AlignRight()
                            .Text(costo.HasValue ? $"${costo:N2}" : "–").FontSize(8.5f);
                    }
                    FilaPrecio("P. Público",  a.PPublico,  a.Costo, Colors.White);
                    FilaPrecio("P. Bodega",   a.PBodega,   a.Costo, "#F9FAFB");
                    FilaPrecio("P. Crédito",  a.PCredito,  a.Costo, Colors.White);
                });

                col.Item().PaddingTop(10).Table(t =>
                {
                    t.ColumnsDefinition(cols => { cols.RelativeColumn(); cols.RelativeColumn(); cols.RelativeColumn(); });
                    t.Cell().Background("#F0F9FF").Padding(8).Column(c2 =>
                    {
                        c2.Item().Text("Stock actual").FontSize(8).FontColor(Colors.Grey.Medium);
                        c2.Item().Text($"{a.Existencias:N0}").Bold().FontSize(14).FontColor(azul);
                    });
                    t.Cell().Background("#F0FDF4").Padding(8).Column(c2 =>
                    {
                        c2.Item().Text("Stock mínimo").FontSize(8).FontColor(Colors.Grey.Medium);
                        c2.Item().Text($"{a.StockMinimo:N0}").Bold().FontSize(12);
                    });
                    t.Cell().Background("#FFF7ED").Padding(8).Column(c2 =>
                    {
                        c2.Item().Text("Punto de reorden").FontSize(8).FontColor(Colors.Grey.Medium);
                        c2.Item().Text($"{a.PuntoReorden:N0}").Bold().FontSize(12);
                    });
                });
            });

            page.Footer().AlignCenter().Text(t =>
            {
                t.DefaultTextStyle(s => s.FontSize(8).FontColor(Colors.Grey.Medium));
                t.Span($"Generado por NEXO ERP — {DateTime.Now:dd/MM/yyyy HH:mm}");
            });
        })).GeneratePdf();
    }

    public static byte[] GenerarExcelClientes(IEnumerable<ClienteItem> clientes)
    {
        using var wb = new XLWorkbook();
        var ws = wb.Worksheets.Add("Clientes");

        string[] headers = { "Nombre", "NIT", "Tipo Cliente", "Tipo Persona", "Teléfono", "Email",
            "Dirección", "Ciudad", "Departamento", "Responsable", "Fuente Contacto",
            "Total Contactos", "Última Interacción", "Estado" };
        EstilizarEncabezados(ws, headers);

        int row = 2;
        foreach (var c in clientes)
        {
            ws.Cell(row, 1).Value  = c.Nombre;
            ws.Cell(row, 2).Value  = c.NIT ?? "";
            ws.Cell(row, 3).Value  = c.TipoCliente ?? "";
            ws.Cell(row, 4).Value  = c.TipoPersona ?? "";
            ws.Cell(row, 5).Value  = c.Telefono ?? "";
            ws.Cell(row, 6).Value  = c.Email ?? "";
            ws.Cell(row, 7).Value  = c.Direccion ?? "";
            ws.Cell(row, 8).Value  = c.Ciudad ?? "";
            ws.Cell(row, 9).Value  = c.Departamento ?? "";
            ws.Cell(row, 10).Value = c.Responsable ?? "";
            ws.Cell(row, 11).Value = c.FuenteContacto ?? "";
            ws.Cell(row, 12).Value = c.TotalContactos;
            ws.Cell(row, 13).Value = c.UltimaInteraccion.HasValue ? c.UltimaInteraccion.Value.ToString("dd/MM/yyyy") : "";
            ws.Cell(row, 14).Value = c.Estado ? "Activo" : "Inactivo";
            if (row % 2 == 0)
                ws.Row(row).Style.Fill.BackgroundColor = XLColor.FromHtml("#F5F7FA");
            row++;
        }

        ws.Columns().AdjustToContents();
        ws.SheetView.FreezeRows(1);
        using var ms = new MemoryStream();
        wb.SaveAs(ms);
        return ms.ToArray();
    }

    public static byte[] GenerarPdfClientes(IEnumerable<ClienteItem> clientes, string empresa)
    {
        const string azul = "#1E3A5F";
        var lista = clientes.ToList();

        return Document.Create(container => container.Page(page =>
        {
            page.Size(PageSizes.A4.Landscape());
            page.MarginHorizontal(1.5f, Unit.Centimetre);
            page.MarginVertical(1.2f, Unit.Centimetre);
            page.DefaultTextStyle(x => x.FontSize(8f));

            page.Header().Row(row =>
            {
                row.RelativeItem().Column(c =>
                {
                    c.Item().Text(empresa).Bold().FontSize(14).FontColor(azul);
                    c.Item().Text("Listado de Clientes").FontSize(10).FontColor(Colors.Grey.Darken1);
                });
                row.AutoItem().AlignRight().Column(c =>
                {
                    c.Item().AlignRight().Text($"Fecha: {DateTime.Now:dd/MM/yyyy}").FontColor(Colors.Grey.Darken2);
                    c.Item().AlignRight().Text($"Total: {lista.Count} clientes").FontColor(Colors.Grey.Darken2);
                });
            });

            page.Content().PaddingTop(10).Table(table =>
            {
                table.ColumnsDefinition(cols =>
                {
                    cols.RelativeColumn(3);
                    cols.RelativeColumn(2);
                    cols.RelativeColumn(2);
                    cols.RelativeColumn(2);
                    cols.RelativeColumn(2);
                    cols.RelativeColumn(2);
                    cols.RelativeColumn(2);
                });

                table.Header(h =>
                {
                    foreach (var t in new[] { "Nombre", "NIT", "Teléfono", "Email", "Ciudad", "Responsable", "Estado" })
                        h.Cell().Background(azul).Padding(4).Text(t).FontColor(Colors.White).Bold().FontSize(7.5f);
                });

                int idx = 0;
                foreach (var c in lista)
                {
                    string bg = idx++ % 2 == 0 ? Colors.White : "#F9FAFB";
                    table.Cell().Background(bg).BorderBottom(0.5f).BorderColor("#E5E7EB").Padding(4).Text(c.Nombre).FontSize(7.5f);
                    table.Cell().Background(bg).BorderBottom(0.5f).BorderColor("#E5E7EB").Padding(4).Text(c.NIT ?? "").FontSize(7.5f);
                    table.Cell().Background(bg).BorderBottom(0.5f).BorderColor("#E5E7EB").Padding(4).Text(c.Telefono ?? "").FontSize(7.5f);
                    table.Cell().Background(bg).BorderBottom(0.5f).BorderColor("#E5E7EB").Padding(4).Text(c.Email ?? "").FontSize(7.5f);
                    table.Cell().Background(bg).BorderBottom(0.5f).BorderColor("#E5E7EB").Padding(4).Text(c.Ciudad ?? "").FontSize(7.5f);
                    table.Cell().Background(bg).BorderBottom(0.5f).BorderColor("#E5E7EB").Padding(4).Text(c.Responsable ?? "").FontSize(7.5f);
                    table.Cell().Background(bg).BorderBottom(0.5f).BorderColor("#E5E7EB").Padding(4).Text(c.Estado ? "Activo" : "Inactivo").FontSize(7.5f);
                }
            });

            page.Footer().AlignCenter().Text(t =>
            {
                t.DefaultTextStyle(s => s.FontSize(7).FontColor(Colors.Grey.Medium));
                t.Span($"Generado por NEXO ERP — {DateTime.Now:dd/MM/yyyy HH:mm}");
            });
        })).GeneratePdf();
    }

    public static byte[] GenerarExcelProveedores(IEnumerable<ProveedorItem> proveedores)
    {
        using var wb = new XLWorkbook();
        var ws = wb.Worksheets.Add("Proveedores");

        string[] headers = { "Razón Social", "NIT", "Tipo Persona", "Contacto", "Teléfono", "Email",
            "Dirección", "Ciudad", "Departamento", "País", "Estado" };
        EstilizarEncabezados(ws, headers);

        int row = 2;
        foreach (var p in proveedores)
        {
            ws.Cell(row, 1).Value  = p.RazonSocial;
            ws.Cell(row, 2).Value  = p.NIT ?? "";
            ws.Cell(row, 3).Value  = p.TipoPersona ?? "";
            ws.Cell(row, 4).Value  = p.Contacto ?? "";
            ws.Cell(row, 5).Value  = p.Telefono ?? "";
            ws.Cell(row, 6).Value  = p.Email ?? "";
            ws.Cell(row, 7).Value  = p.Direccion ?? "";
            ws.Cell(row, 8).Value  = p.Ciudad ?? "";
            ws.Cell(row, 9).Value  = p.Departamento ?? "";
            ws.Cell(row, 10).Value = p.Pais ?? "";
            ws.Cell(row, 11).Value = p.Estado ? "Activo" : "Inactivo";
            if (row % 2 == 0)
                ws.Row(row).Style.Fill.BackgroundColor = XLColor.FromHtml("#F5F7FA");
            row++;
        }

        ws.Columns().AdjustToContents();
        ws.SheetView.FreezeRows(1);
        using var ms = new MemoryStream();
        wb.SaveAs(ms);
        return ms.ToArray();
    }

    public static byte[] GenerarPdfProveedores(IEnumerable<ProveedorItem> proveedores, string empresa)
    {
        const string azul = "#1E3A5F";
        var lista = proveedores.ToList();

        return Document.Create(container => container.Page(page =>
        {
            page.Size(PageSizes.A4.Landscape());
            page.MarginHorizontal(1.5f, Unit.Centimetre);
            page.MarginVertical(1.2f, Unit.Centimetre);
            page.DefaultTextStyle(x => x.FontSize(8f));

            page.Header().Row(row =>
            {
                row.RelativeItem().Column(c =>
                {
                    c.Item().Text(empresa).Bold().FontSize(14).FontColor(azul);
                    c.Item().Text("Listado de Proveedores").FontSize(10).FontColor(Colors.Grey.Darken1);
                });
                row.AutoItem().AlignRight().Column(c =>
                {
                    c.Item().AlignRight().Text($"Fecha: {DateTime.Now:dd/MM/yyyy}").FontColor(Colors.Grey.Darken2);
                    c.Item().AlignRight().Text($"Total: {lista.Count} proveedores").FontColor(Colors.Grey.Darken2);
                });
            });

            page.Content().PaddingTop(10).Table(table =>
            {
                table.ColumnsDefinition(cols =>
                {
                    cols.RelativeColumn(3);
                    cols.RelativeColumn(2);
                    cols.RelativeColumn(2);
                    cols.RelativeColumn(2);
                    cols.RelativeColumn(2);
                    cols.RelativeColumn(2);
                });

                table.Header(h =>
                {
                    foreach (var t in new[] { "Razón Social", "NIT", "Teléfono", "Email", "Ciudad", "Estado" })
                        h.Cell().Background(azul).Padding(4).Text(t).FontColor(Colors.White).Bold().FontSize(7.5f);
                });

                int idx = 0;
                foreach (var p in lista)
                {
                    string bg = idx++ % 2 == 0 ? Colors.White : "#F9FAFB";
                    table.Cell().Background(bg).BorderBottom(0.5f).BorderColor("#E5E7EB").Padding(4).Text(p.RazonSocial).FontSize(7.5f);
                    table.Cell().Background(bg).BorderBottom(0.5f).BorderColor("#E5E7EB").Padding(4).Text(p.NIT ?? "").FontSize(7.5f);
                    table.Cell().Background(bg).BorderBottom(0.5f).BorderColor("#E5E7EB").Padding(4).Text(p.Telefono ?? "").FontSize(7.5f);
                    table.Cell().Background(bg).BorderBottom(0.5f).BorderColor("#E5E7EB").Padding(4).Text(p.Email ?? "").FontSize(7.5f);
                    table.Cell().Background(bg).BorderBottom(0.5f).BorderColor("#E5E7EB").Padding(4).Text(p.Ciudad ?? "").FontSize(7.5f);
                    table.Cell().Background(bg).BorderBottom(0.5f).BorderColor("#E5E7EB").Padding(4).Text(p.Estado ? "Activo" : "Inactivo").FontSize(7.5f);
                }
            });

            page.Footer().AlignCenter().Text(t =>
            {
                t.DefaultTextStyle(s => s.FontSize(7).FontColor(Colors.Grey.Medium));
                t.Span($"Generado por NEXO ERP — {DateTime.Now:dd/MM/yyyy HH:mm}");
            });
        })).GeneratePdf();
    }

    private static void EstilizarEncabezados(IXLWorksheet ws, string[] headers)
    {
        for (int i = 0; i < headers.Length; i++)
        {
            var cell = ws.Cell(1, i + 1);
            cell.Value = headers[i];
            cell.Style.Font.Bold = true;
            cell.Style.Fill.BackgroundColor = XLColor.FromHtml("#1E3A5F");
            cell.Style.Font.FontColor = XLColor.White;
        }
    }
}
