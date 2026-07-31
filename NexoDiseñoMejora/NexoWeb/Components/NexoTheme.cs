using MudBlazor;

namespace NexoWeb.Components;

/// <summary>
/// Tema visual unico de NEXO ERP (paleta "Grafito + Beige"), compartido entre
/// AuthLayout (Login) y MainLayout (resto del sistema), para que toda la
/// aplicacion use exactamente los mismos colores de marca.
/// </summary>
public static class NexoTheme
{
    public static readonly MudTheme Theme = new()
    {
        PaletteLight = new PaletteLight
        {
            Primary = "#2563EB",
            PrimaryContrastText = "#FFFFFF",
            PrimaryDarken = "#1D4ED8",
            PrimaryLighten = "#DBE8FE",

            Background = "#F7F3EC",
            BackgroundGray = "#F1EBE0",
            Surface = "#FFFCF8",

            AppbarBackground = "#2B2D31",
            AppbarText = "#F7F3EC",

            DrawerBackground = "#2B2D31",
            DrawerText = "#E8E2D9",
            DrawerIcon = "#E8E2D9",

            TextPrimary = "#2E2E2E",
            TextSecondary = "#6B7280",
            TextDisabled = "rgba(46, 46, 46, 0.38)",

            LinesDefault = "#E8E2D9",
            LinesInputs = "#E8E2D9",
            TableLines = "#E8E2D9",
            Divider = "#E8E2D9",
            DividerLight = "#F0EBE2",

            Success = "#16A34A",
            SuccessContrastText = "#FFFFFF",
            Warning = "#F59E0B",
            WarningContrastText = "#2E2E2E",
            Error = "#DC2626",
            ErrorContrastText = "#FFFFFF",
            Info = "#2563EB",
            InfoContrastText = "#FFFFFF",

            TableHover = "rgba(37, 99, 235, 0.045)",
            TableStriped = "rgba(43, 45, 49, 0.025)",
            ActionDefault = "#6B7280",
            ActionDisabled = "rgba(46, 46, 46, 0.28)",
            ActionDisabledBackground = "rgba(46, 46, 46, 0.08)",

            GrayLight = "#F1EBE0",
            GrayLighter = "#F7F3EC",
            GrayDefault = "#9CA3AF",
            GrayDark = "#6B7280",

            OverlayDark = "rgba(20, 20, 22, 0.55)",

            White = "#FFFFFF",
            Black = "#1A1A1C",
        },

        Typography = new Typography
        {
            Default = new Default
            {
                FontFamily = new[] { "Inter", "Segoe UI", "Helvetica Neue", "Arial", "sans-serif" },
                FontSize = "0.875rem",
                LetterSpacing = ".01em",
            },
            H1 = new H1 { FontFamily = new[] { "Inter", "sans-serif" }, FontWeight = 700 },
            H2 = new H2 { FontFamily = new[] { "Inter", "sans-serif" }, FontWeight = 700 },
            H3 = new H3 { FontFamily = new[] { "Inter", "sans-serif" }, FontWeight = 600 },
            H4 = new H4 { FontFamily = new[] { "Inter", "sans-serif" }, FontWeight = 600 },
            H5 = new H5 { FontFamily = new[] { "Inter", "sans-serif" }, FontWeight = 600 },
            H6 = new H6 { FontFamily = new[] { "Inter", "sans-serif" }, FontWeight = 600, LetterSpacing = ".01em" },
            Button = new Button { FontFamily = new[] { "Inter", "sans-serif" }, FontWeight = 600, TextTransform = "none" },
        },

        LayoutProperties = new LayoutProperties
        {
            DefaultBorderRadius = "10px",
            DrawerWidthLeft = "270px",
            DrawerMiniWidthLeft = "76px",
            AppbarHeight = "64px",
        },
    };
}