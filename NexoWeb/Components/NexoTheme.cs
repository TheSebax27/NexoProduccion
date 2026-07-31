using MudBlazor;

namespace NexoWeb.Components;

/// <summary>
/// Tema visual unico de NEXO ERP (paleta "Grafito + Beige"), compartido entre
/// AuthLayout (Login) y MainLayout (resto del sistema), para que toda la
/// aplicacion use exactamente los mismos colores de marca.
///
/// Antes de este archivo, &lt;MudThemeProvider /&gt; no recibia ningun Theme
/// personalizado, asi que MudBlazor aplicaba su paleta azul-violeta POR DEFECTO
/// al AppBar, al Drawer y a los enlaces activos del menu. De ahi salia el morado
/// que se veia en el sistema - no de MainLayout.razor.css ni de NavMenu.razor.css
/// (esos archivos no le pegan a ninguna clase que MudBlazor realmente genera).
/// </summary>
public static class NexoTheme
{
    public static readonly MudTheme Theme = new()
    {
        PaletteLight = new PaletteLight
        {
            // Botones, enlaces activos, foco de inputs
            Primary = "#2563EB",
            PrimaryContrastText = "#FFFFFF",

            // Fondo general de la app y superficie de tarjetas/paneles
            Background = "#F7F3EC",
            Surface = "#FFFCF8",

            // Barra superior (AppBar)
            AppbarBackground = "#2B2D31",
            AppbarText = "#F7F3EC",

            // Menu lateral (Drawer / Sidebar)
            DrawerBackground = "#2B2D31",
            DrawerText = "#E8E2D9",
            DrawerIcon = "#E8E2D9",

            // Texto general
            TextPrimary = "#2E2E2E",
            TextSecondary = "#6B6B6B",

            // Bordes y separadores (tablas, inputs, divisores)
            LinesDefault = "#E8E2D9",
            LinesInputs = "#E8E2D9",
            TableLines = "#E8E2D9",
            Divider = "#E8E2D9",
        }
    };
}