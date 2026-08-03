using MudBlazor;

namespace NexoWeb.Components;

/// <summary>
/// Tema visual de NEXO ERP — paleta "Morado profundo + Gris moderno".
/// Inspirada en el diseño de referencia SaaS: sidebar oscuro, acento morado,
/// fondo gris muy claro, tarjetas blancas.
/// </summary>
public static class NexoTheme
{
    public static readonly MudTheme Theme = new()
    {
        PaletteLight = new PaletteLight
        {
            // ── Acción principal ──────────────────────────────────────
            Primary             = "#7C5CFF",
            PrimaryContrastText = "#FFFFFF",
            PrimaryDarken       = "#5A3BFF",
            PrimaryLighten      = "#9B7FFF",

            // ── Semánticos ────────────────────────────────────────────
            Secondary           = "#6B6B8A",
            SecondaryContrastText = "#FFFFFF",
            Info                = "#0EA5E9",
            Success             = "#10B981",
            Warning             = "#F59E0B",
            Error               = "#EF4444",

            // ── Fondos ────────────────────────────────────────────────
            Background          = "#F4F5F9",   // Gris claro elegante
            Surface             = "#FFFFFF",   // Tarjetas y paneles blancos

            // ── Barra superior (blanca) ───────────────────────────────
            AppbarBackground    = "#FFFFFF",
            AppbarText          = "#1A1C2E",

            // ── Sidebar oscuro ────────────────────────────────────────
            DrawerBackground    = "#13131F",
            DrawerText          = "#9B9BB4",
            DrawerIcon          = "#6B6B8A",

            // ── Texto ─────────────────────────────────────────────────
            TextPrimary         = "#1A1C2E",
            TextSecondary       = "#6B6B8A",
            TextDisabled        = "#B0B0C8",

            // ── Líneas y bordes ───────────────────────────────────────
            LinesDefault        = "#E8E9EF",
            LinesInputs         = "#D1D5E8",
            TableLines          = "#EEEEF5",
            Divider             = "#E8E9EF",

            // ── Superposiciones ───────────────────────────────────────
            OverlayDark         = "rgba(26, 28, 46, 0.5)",
            OverlayLight        = "rgba(26, 28, 46, 0.04)",
        }
    };
}
