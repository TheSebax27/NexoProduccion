# NEXO ERP — Guía de Contexto para Claude

Este archivo es la fuente principal de contexto del proyecto. Léelo antes de cualquier tarea.

---

## 1. Descripción General

**NEXO ERP** es un sistema ERP industrial orientado a la gestión de producción multi-planta. Controla el ciclo completo: planificación → producción → inventario → compras, con integración al sistema externo de punto de venta **Visions**.

### Objetivo del sistema

Digitalizar y auditar el flujo de producción en múltiples centros de costo (plantas/bodegas), manteniendo trazabilidad completa de materiales, costos, lotes y movimientos de inventario.

---

## 2. Arquitectura General

```
SQL Server (NEXO_ERP)
        ↕ Dapper / SQL raw
    NexoApi (.NET 10 Web API)
        ↕ HTTP + JWT Bearer
    NexoWeb (Blazor Server .NET 10)
        ↕ SignalR (Blazor Server circuit)
       Navegador del usuario

    NexoSyncAgent (.NET 10 Worker Service)
        ↕ X-Api-Key / HTTP
       NexoApi  ←→  Visions ERP (externo)
```

Tres proyectos en `C:\Produccion\`:

| Proyecto | Puerto dev | Descripción |
|---|---|---|
| `NexoApi` | https://localhost:7144 | REST API, toda la lógica de negocio y acceso a datos |
| `NexoWeb` | https://localhost:7089 | Blazor Server, UI interactiva |
| `NexoSyncAgent` | Worker (sin HTTP expuesto) | Agente de sincronización con Visions |

---

## 3. Stack Tecnológico

### NexoApi
- **.NET 10** (ASP.NET Core Web API)
- **Dapper 2.1.79** — acceso a datos, SQL raw, sin ORM
- **Microsoft.Data.SqlClient 7.0.2** — driver SQL Server
- **JWT Bearer** — autenticación de usuarios (`Microsoft.AspNetCore.Authentication.JwtBearer`)
- **ApiKey custom scheme** — autenticación del agente sync (`ApiKeyAuthenticationHandler`)
- **Swashbuckle / OpenAPI** — Swagger en desarrollo
- No hay Entity Framework. No hay LINQ-to-SQL.

### NexoWeb
- **.NET 10** (Blazor Server — render interactivo en servidor)
- **MudBlazor 7.15.0** — componentes visuales (tablas, formularios, diálogos)
- **ProtectedSessionStorage** — sesión cifrada en el navegador (no cookies planas)
- No hay JavaScript propio significativo; solo interop mínimo de MudBlazor

### Base de datos
- **SQL Server** — instancia `DESKTOP-V83PQ7M\JONATHAN`, base `NEXO_ERP`
- **Autenticación Windows** (`Trusted_Connection=true`)
- Esquemas separados por dominio (ver sección 7)

---

## 4. Estructura de Carpetas

```
C:\Produccion\
├── NexoApi\
│   ├── Common\
│   │   ├── Data\           ← IDbConnectionFactory, SqlConnectionFactory
│   │   ├── Middleware\     ← ExceptionHandlingMiddleware (manejo central de errores)
│   │   └── Security\      ← IJwtService, JwtService, PasswordHasher, ApiKeyAuthenticationHandler
│   ├── Features\           ← Un directorio por módulo de negocio
│   │   ├── Auth\           ← Login, registro primer admin, gestión de usuarios
│   │   ├── Catalogo\       ← Artículos, Bodegas, CC, Clientes, Proveedores, Centros de Trabajo
│   │   ├── Compras\        ← Órdenes de compra
│   │   ├── Dashboard\      ← KPIs y gráficas
│   │   ├── Integracion\    ← Eventos entrantes/salientes con Visions
│   │   ├── Inventario\     ← Stock, bajas, kardex
│   │   ├── Notificaciones\ ← Resumen agregado para la campana del topbar
│   │   ├── Produccion\     ← Órdenes de producción, consumos, recetas BOM
│   │   ├── Recetas\        ← CRUD de recetas BOM
│   │   └── Traspasos\      ← Traspasos entre bodegas
│   ├── appsettings.json    ← Connection string + JWT config
│   └── Program.cs
│
├── NexoWeb\
│   ├── Common\
│   │   ├── ApiClient\      ← INexoApiClient, NexoApiClient (cliente HTTP tipado)
│   │   ├── Auth\           ← AuthStateService, CustomAuthStateProvider
│   │   └── Dtos\           ← DTOs espejo de NexoApi, por módulo
│   ├── Components\
│   │   ├── Layout\         ← MainLayout, AuthLayout, NavMenu, InicializadorSesion
│   │   ├── Shared\         ← MudMoneyField, MudHorasField (componentes de formulario reutilizables)
│   │   ├── Pages\
│   │   │   ├── Admin\      ← Usuarios (CRUD)
│   │   │   ├── Auth\       ← Login
│   │   │   ├── Catalogo\   ← Artículos, Bodegas, CC, Centros de Trabajo, Clientes, Proveedores
│   │   │   ├── Compras\    ← Órdenes de compra
│   │   │   ├── Dashboard\  ← Dashboard con gráficas (filtros por rango de fecha, no por "dias")
│   │   │   ├── Inventario\ ← Stock, Bajas, Kardex, Ajuste de Inventario
│   │   │   ├── Produccion\ ← Órdenes (crear/editar/cancelar), Recetas, Ajuste de consumo
│   │   │   └── Traspasos\  ← Lista y recepción de traspasos
│   │   ├── NexoTheme.cs    ← Paleta visual centralizada (MudTheme)
│   │   └── _Imports.razor
│   ├── appsettings.json    ← BaseUrl de NexoApi
│   └── Program.cs
│
├── NexoSyncAgent\          ← Worker Service de sincronización con Visions
├── ScriptsSQL\             ← Scripts SQL completos y por proceso
│   └── ScriptsCompletos\
│       └── sqlportablenexo.sql   ← Script maestro portable (re-ejecutable)
└── docs\                   ← Documentación técnica
    ├── architecture.md
    ├── database.md
    └── session-summary.md
```

---

## 5. Convenciones de Nombres

### C# / API
- Clases de servicio: `{Entidad}Service` implementando `I{Entidad}Service`
- Controladores: `{Modulo}Controller` con `[Route("api/{modulo}")]`
- DTOs: `record` positional — `{Accion}{Entidad}Request`, `{Entidad}Item`, `{Entidad}Resumen`
- Métodos de servicio: verbos en español — `ListarAsync`, `CrearAsync`, `ObtenerAsync`, `ActualizarAsync`, `EliminarAsync`

### Blazor
- Páginas: `{Nombre}.razor` con `@page "/ruta"` y `@attribute [Authorize(Roles="...")]`
- Diálogos: `{Nombre}Dialog.razor` — siempre usan `[CascadingParameter] MudDialogInstance`
- Variables de estado: prefijo `_` en minúscula (`_cargando`, `_errorCarga`, `_lista`)

### SQL
- Objetos: PascalCase, sin espacios
- Esquemas: PascalCase (excepto `catalogo` — minúscula, por compatibilidad legacy)
- SPs: `sp_{Verbo}{Entidad}` en PascalCase
- Vistas: `vw_{Descripcion}` en PascalCase
- Funciones: `fn_{Descripcion}` en camelCase

---

## 6. Patrones de Diseño

### API — Patrón de servicio

```csharp
// 1. Interface en el mismo archivo que la implementación
public interface IInventarioService
{
    Task<IEnumerable<StockConsolidadoItem>> ConsultarStockAsync(...);
}

// 2. Implementación usa IDbConnectionFactory (Singleton)
public class InventarioService : IInventarioService
{
    private readonly IDbConnectionFactory _db;
    public InventarioService(IDbConnectionFactory db) { _db = db; }

    public async Task<IEnumerable<StockConsolidadoItem>> ConsultarStockAsync(...)
    {
        using var connection = _db.CreateConnection();
        const string sql = @"SELECT ... FROM ...";
        return await connection.QueryAsync<StockConsolidadoItem>(sql, new { ... });
    }
}
```

### API — Stored procedures

```csharp
var parametros = new DynamicParameters();
parametros.Add("OrdenProduccionID", id);
parametros.Add("UsuarioID", usuarioId);
await connection.ExecuteAsync("Produccion.sp_LiberarOrdenProduccion",
    parametros, commandType: CommandType.StoredProcedure);
```

### API — Extracción del UsuarioID del JWT

```csharp
// En el controlador:
var usuarioId = int.Parse(User.FindFirst("sub")?.Value ?? "0");
```

### Web — Patrón de página

```razor
@page "/modulo/pantalla"
@attribute [Authorize(Roles = "Administrador,SupervisorPlanta")]
@inject INexoApiClient ApiClient
@inject ISnackbar Snackbar

@code {
    private bool _cargando = true;
    private string? _errorCarga;
    private List<MiDto> _lista = new();

    protected override async Task OnInitializedAsync()
    {
        try
        {
            _lista = await ApiClient.GetAsync<List<MiDto>>("api/modulo/ruta") ?? new();
        }
        catch (Exception ex)
        {
            _errorCarga = ex.Message;
        }
        finally
        {
            _cargando = false;
        }
    }
}
```

### Web — Patrón de diálogo

```razor
@code {
    [CascadingParameter] private MudDialogInstance MudDialog { get; set; } = default!;
    [Parameter] public MiDto? Entidad { get; set; }  // null = crear, !null = editar

    private void Confirmar() => MudDialog.Close(DialogResult.Ok(resultado));
    private void Cancelar() => MudDialog.Cancel();
}
```

### Web — Invocar un diálogo

```csharp
var options = new DialogOptions { MaxWidth = MaxWidth.Small, FullWidth = true };
var dialog = await DialogService.ShowAsync<MiDialog>("Título", parametros, options);
var result = await dialog.Result;
if (result is { Canceled: false })
{
    var dato = (MiDto)result.Data!;
    // usar dato
}
```

### Web — Confirmación antes de acción destructiva

```csharp
var confirmar = await DialogService.ShowMessageBox(
    "Confirmar Acción",
    "¿Está seguro de que desea proceder? Esta acción es irreversible.",
    yesText: "Sí, proceder", cancelText: "Cancelar");

if (confirmar != true) return;
```

### Web — ApiClient

El `NexoApiClient` es el único punto de acceso a la API. No hacer `HttpClient` directamente en componentes.

```csharp
// GET
var lista = await ApiClient.GetAsync<List<MiDto>>("api/modulo/ruta");

// POST con respuesta
var creado = await ApiClient.PostAsync<CrearRequest, MiDto>("api/modulo", request);

// POST sin respuesta
await ApiClient.PostAsync("api/modulo/accion");

// PUT
await ApiClient.PutAsync<ActualizarRequest, MiDto>("api/modulo/{id}", request);

// PATCH
await ApiClient.PatchAsync<PatchRequest, object?>("api/modulo/{id}", request);

// DELETE
await ApiClient.DeleteAsync("api/modulo/{id}");
```

---

## 7. Flujo de Autenticación

### Login

```
Usuario → POST /api/auth/login
        ← { accessToken (JWT 60 min), refreshToken (7 días), rol, centroCostoId }
        → AuthStateService.IniciarSesionAsync()   [guarda en ProtectedSessionStorage]
        → CustomAuthStateProvider notifica cambio
        → NavMenu / AuthorizeView se actualiza
```

### JWT Claims
- `sub` → UsuarioID
- `unique_name` → Username
- `role` → Nombre del rol
- `CentroCostoId` → ID del centro de costo asignado (puede ser null)

### Roles del sistema

| Rol | Acceso |
|---|---|
| `Administrador` | Acceso total. Gestión de usuarios, catálogos, clientes, proveedores. |
| `SupervisorPlanta` | Producción, recetas, inventario (sin bajas), kardex. |
| `Bodeguero` | Inventario, bajas, traspasos, compras, kardex. |
| `Operario` | Solo órdenes de producción (vista limitada). |

### Primer usuario

```
POST /api/auth/registrar
Body: { nombres, apellidos, email, username, password, rolID, centroCostoID }
```

Solo funciona si no existe ningún usuario en la BD. Luego queda deshabilitado.

Credenciales actuales del entorno de desarrollo: `admin` / `Admin123!`

---

## 8. Organización de la API

### Endpoints por módulo

| Prefijo | Controlador | Descripción |
|---|---|---|
| `/api/auth` | `AuthController` | Login, registro, gestión de usuarios |
| `/api/catalogo` | `ArticulosController`, `BodegasController`, `CentroCostoController`, `ClientesYCentrosTrabajoController` | CRUD de catálogos maestros |
| `/api/produccion/ordenes` | `OrdenesProduccionController` | CRUD + ciclo de vida de OPs |
| `/api/produccion/recetas` | `RecetasController` | CRUD de recetas BOM |
| `/api/inventario` | `InventarioController` | Stock, bajas, kardex |
| `/api/inventario/traspasos` | `TraspasosController` | Traspasos entre bodegas |
| `/api/compras` | `OrdenesCompraController` | Órdenes de compra |
| `/api/dashboard` | `DashboardController` | KPIs y series de datos |
| `/api/notificaciones` | `NotificacionesController` | Resumen agregado (sin stock, bajo stock, producción en proceso) para la campana del topbar |
| `/api/busqueda` | `BusquedaController` | Búsqueda global de la barra superior (artículos, clientes, proveedores, centros de costo, bodegas, OP, OC), filtrada por rol |
| `/api/preferencias` | `PreferenciasController` | Preferencias personales por usuario (tema oscuro, vista lista/tarjetas por pantalla) — `GET` trae todas, `PUT /{clave}` crea o actualiza una |
| `/api/integracion` | `IntegracionController` | Eventos con Visions (para NexoSyncAgent) |

### Manejo de errores — ExceptionHandlingMiddleware

Los errores SQL de regla de negocio (rango 50000–59999) se mapean automáticamente:

| Número SQL | HTTP Status | Casos |
|---|---|---|
| 51020 | 404 Not Found | Registro no encontrado |
| 51001, 51002, 51010, 51011, 51030, 52001, 53000, 53010 | 409 Conflict | Estado inválido, transición no permitida |
| Resto 50000–59999 | 400 Bad Request | Validación de negocio |
| 2627, 2601 | 409 Conflict | Violación UNIQUE |
| 547 | 400 Bad Request | Violación FK |
| `KeyNotFoundException` | 404 Not Found | Registro no encontrado (en servicios) |

La respuesta siempre es `{ "error": "mensaje legible" }`.

---

## 9. Organización del Frontend

### Layouts

- `AuthLayout` → solo para `/login`. Fondo oscuro con imagen hero.
- `MainLayout` → todas las demás rutas. AppBar + Drawer + contenido.
- `InicializadorSesion` → componente que recupera la sesión de `ProtectedSessionStorage` al inicio del circuito.

### Rutas registradas

| Ruta | Componente | Roles |
|---|---|---|
| `/` | `Dashboard.razor` | Admin, SupervisorPlanta, Bodeguero |
| `/produccion/ordenes` | `ListaOrdenes.razor` | Admin, SupervisorPlanta, Operario |
| `/produccion/ordenes/crear` | `CrearOrden.razor` (modo crear) | Admin, SupervisorPlanta |
| `/produccion/ordenes/{id}/editar` | `CrearOrden.razor` (modo editar — misma pagina, `@page` doble) | Admin, SupervisorPlanta |
| `/produccion/recetas` | `Recetas.razor` | Admin, SupervisorPlanta |
| `/produccion/recetas/crear` | `CrearReceta.razor` (modo crear) | Admin, SupervisorPlanta |
| `/produccion/recetas/{id}/nueva-version` | `CrearReceta.razor` (modo nueva version — misma pagina) | Admin, SupervisorPlanta |
| `/inventario/stock` | `ConsultaStock.razor` | Todos autenticados |
| `/inventario/kardex` | `ConsultaKardex.razor` | Admin, SupervisorPlanta, Bodeguero |
| `/inventario/bajas` | `RegistrarBaja.razor` | Admin, Bodeguero |
| `/inventario/ajustes` | `AjustarInventario.razor` — carga de stock inicial / correccion por conteo fisico | Admin, Bodeguero |
| `/inventario/traspasos` | `ListaTraspasos.razor` | Admin, Bodeguero |
| `/compras/ordenes` | `ListaOrdenesCompra.razor` — acepta `?articuloId=N` ([SupplyParameterFromQuery]) para abrir "Nueva Orden de Compra" con ese artículo precargado (usado por el chip "Requiere pedido" de Consulta de Stock) | Admin, Bodeguero |
| `/catalogo/articulos` | `Articulos.razor` — acepta `?texto=` ([SupplyParameterFromQuery]) precargado desde la búsqueda global | Admin, SupervisorPlanta |
| `/catalogo/centros-costo` | `CentrosCosto.razor` | Admin |
| `/catalogo/centros-trabajo` | `CentrosTrabajo.razor` — linea/maquina dentro de un Centro de Costo, con costo hora MOD/CIF | Admin |
| `/catalogo/bodegas` | `Bodegas.razor` | Admin |
| `/catalogo/clientes` | `Clientes.razor` | Admin |
| `/catalogo/proveedores` | `Proveedores.razor` | Admin |
| `/admin/usuarios` | `Usuarios.razor` | Admin |
| `/settings` | `Settings.razor` — preferencias personales (tema oscuro por ahora) | Todos autenticados |

**Patrón "una página sirve para crear y editar"**: `CrearOrden.razor` y `CrearReceta.razor` registran **dos** `@page` (uno literal `/crear`, otro con parámetro `{id:int}/editar` o `/nueva-version`). El componente expone `[Parameter] public int? XxxId` y una propiedad `EsEdicion => XxxId.HasValue` que controla precarga de datos, textos y si hace POST o PUT/nueva versión. Seguir este patrón para no duplicar formularios grandes.

---

## 10. Paleta de Colores — Tema "Morado + Gris moderno" (rediseño agosto 2026)

Definida en `NexoWeb/Components/NexoTheme.cs` y aplicada en ambos layouts con `<MudThemeProvider Theme="NexoTheme.Theme" />`. Reemplazó al tema anterior "Grafito + Beige" (obsoleto, no usar como referencia).

| Elemento | Color | Hex |
|---|---|---|
| Fondo general | Gris muy claro | `#F4F5F9` |
| Superficie / tarjetas | Blanco | `#FFFFFF` |
| AppBar (barra superior) | Casi negro (igual que el sidebar, desde agosto 2026) | `#13131F`, altura `76px` |
| Drawer/Sidebar | Casi negro | `#13131F` |
| Color primario (degradado, botones, activo en menú) | Morado | `#7C5CFF` → `#5A3BFF` (gradiente 135deg) |
| Texto principal | Casi negro | `#1A1C2E` |
| Texto secundario | Gris azulado | `#6B6B8A` |
| Bordes / líneas | Gris muy claro | `#E8E9EF` |
| Success / Warning / Error / Info | `#10B981` / `#F59E0B` / `#EF4444` / `#0EA5E9` | |

**Regla**: nunca sobreescribir el tema con CSS hardcodeado en los componentes. Usar siempre las variables de MudBlazor, las clases utilitarias en `wwwroot/app.css` (`.nexo-*`), o agregar propiedades en `NexoTheme.cs`.

**Excepción documentada**: `Components/Pages/Auth/Login.razor` y `Login.razor.css` mantienen su estructura visual original (el usuario la diseñó y pidió no tocarla) — solo se le actualizaron las variables de color (`--nexo-primary`, `--nexo-bg`, etc.) para que coincidan con la paleta morada.

### Componentes compartidos de formulario (`Components/Shared/`)

- **`MudMoneyField.razor`** — campo de dinero: se ve como texto con separador de miles (punto) en vivo mientras escribes, prefijo `$`. Internamente expone un `decimal` limpio vía `@bind-Value`, nunca guarda el símbolo. Usar en cualquier campo de Precio/Costo en vez de `MudNumericField`.
- **`MudHorasField.razor`** — campo de horas: se ve como dos inputs "Horas" y "Minutos" en vez de forzar a escribir un decimal ("1.75"). Expone un `decimal` de horas totales vía `@bind-Value`.

### Convención de formato numérico (actualizada, agosto 2026)

- **Cantidades** (inventario, recetas, producción): `Format="N2"` en `MudNumericField`, `.ToString("N2")` en tablas. **No usar N3/N4** — se decidió reducir a 2 decimales en toda la app porque los decimales extra confundían a los usuarios; internamente la BD sigue en `decimal(18,4)`, es solo presentación.
- **Dinero** (Precio, Costo, Total, Valor): `MudMoneyField` en formularios editables, `.ToString("C2")` en tablas de solo lectura.
- **Cultura global**: `Program.cs` de `NexoWeb` fuerza `es-CO` (`CultureInfo.DefaultThreadCurrentCulture` + `UseRequestLocalization`), así que todo `ToString("C2")`/`("N2")` ya sale con formato colombiano (punto miles, coma decimal, `$`) sin tener que tocar cada pantalla.

---

## 11. Convenciones SQL

- Esquemas en PascalCase (excepto `catalogo` — legacy)
- PKs: `{Entidad}ID` de tipo `int IDENTITY(1,1)`
- FechaCreacion: siempre `datetime2(7) NOT NULL DEFAULT SYSUTCDATETIME()`
- Campos de auditoría de usuario: `{Rol}ID` referenciando `Seguridad.Usuarios`
- SPs de negocio lanzan errores con `THROW 5XXXX, 'mensaje', 1`
- Vistas: solo lectura, siempre con `WITH SCHEMABINDING` si son críticas
- No usar `SELECT *` en ningún SP ni consulta del API

---

## 12. Convenciones Blazor

- Siempre usar `@attribute [Authorize(Roles="...")]` en páginas protegidas
- El estado de autenticación viene de `AuthStateService` — no leer el JWT directamente en componentes
- Para obtener el UsuarioID en el servidor: extraer el claim desde el controlador API, no desde el frontend
- `@inject IDialogService DialogService` — necesario para abrir diálogos
- `@inject ISnackbar Snackbar` — para notificaciones de éxito/error
- No mezclar lógica de negocio en los componentes; toda la lógica va en el API
- El `StateHasChanged()` es necesario después de operaciones asíncronas que modifiquen UI si no estás en el flujo normal de Blazor

---

## 13. Reglas que Nunca Deben Romperse

1. **No Entity Framework**. Dapper + SQL raw siempre.
2. **No lógica de negocio en el frontend**. Los componentes Blazor solo llaman al API.
3. **No usar `IMudDialogInstance`** — el tipo correcto en MudBlazor 7.x es `MudDialogInstance`.
4. **Toda operación de escritura que pueda fallar por regla de negocio va en un SP**. Las consultas pueden ser SQL inline.
5. **Siempre llamar `AgregarTokenAsync()` antes de cualquier request HTTP** (ya encapsulado en `NexoApiClient`; no bypasear).
6. **No usar `GET /api/auth/registrar` si ya existe un usuario** — el endpoint lo bloqueará con excepción.
7. **El connection string usa Windows Authentication** — no agregar usuario/contraseña SQL.
8. **Los SPs deben lanzar `THROW 5XXXX`** — el middleware mapea estos números a HTTP status codes. No cambiar la numeración.
9. **Datos decimales**: precisión `(18,4)` en BD (no cambia). En UI usar `"N2"` para cantidades (ver sección 10 — se bajó de N4 a N2 en agosto 2026 porque confundía a los usuarios) y `"C2"` para valores monetarios (usar `MudMoneyField` en formularios editables).
10. **Confirmación obligatoria** antes de cualquier operación irreversible en UI (iniciar OP, recibir traspaso, registrar baja).

---

## 14. Cómo Ejecutar el Proyecto

### Prerrequisitos
- .NET 10 SDK
- SQL Server con instancia `DESKTOP-V83PQ7M\JONATHAN`
- Base de datos creada con `ScriptsSQL/ScriptsCompletos/sqlportablenexo.sql`
- Datos semilla insertados con `ScriptsSQL/ScriptsProcesos/DatosSemilla.sql`

> **IMPORTANTE**: `sqlportablenexo.sql` crea solo la estructura (tablas, vistas, SPs).
> Las tablas de catálogo quedan vacías. Sin ejecutar `DatosSemilla.sql` el primer
> registro de usuario falla con FK violation en `Seguridad.Roles`.

### Opción A — Visual Studio / Rider
Abrir `NexoApi.slnx` o `NexoWeb.slnx` y ejecutar el perfil `https`.

### Opción B — CLI

```bash
# Terminal 1 — API
cd C:\Produccion\NexoApi
dotnet run

# Terminal 2 — Web
cd C:\Produccion\NexoWeb
dotnet run
```

La API queda en `https://localhost:7144` y la web en su puerto de launchSettings.

### Verificar que la API apunta al URL correcto

`NexoWeb/appsettings.json`:
```json
{
  "NexoApi": {
    "BaseUrl": "https://localhost:7144/"
  }
}
```

---

## 15. Cómo Compilar

```bash
dotnet build C:\Produccion\NexoApi\NexoApi.csproj
dotnet build C:\Produccion\NexoWeb\NexoWeb.csproj
```

Sin errores esperados. Hay 8 advertencias `MUD0002` de MudBlazor (comportamiento heredado, no críticas).

---

## 16. Cómo Publicar

```bash
# API
dotnet publish C:\Produccion\NexoApi\NexoApi.csproj -c Release -o C:\Deploy\NexoApi

# Web
dotnet publish C:\Produccion\NexoWeb\NexoWeb.csproj -c Release -o C:\Deploy\NexoWeb
```

En producción actualizar `appsettings.json` de cada proyecto con las URLs y connection strings del servidor de producción.

---

## 17. Cómo Agregar un Nuevo Módulo

Seguir exactamente este orden y estructura:

### 1. BD — Crear tablas y SPs en `ScriptsProcesos/`

```sql
-- Nuevo archivo: ScriptsProcesos/MiModulo.sql
CREATE TABLE MiEsquema.MiTabla ( ... );
GO
CREATE PROCEDURE MiEsquema.sp_CrearMiEntidad @Param1 INT, ...
AS BEGIN ... THROW 51099, 'error especifico', 1; END
```

### 2. API — Crear la Feature

```
NexoApi/Features/MiModulo/
    Dtos/
        MiModuloDtos.cs     ← records positional
    MiModuloService.cs      ← interface + implementación Dapper
    MiModuloController.cs   ← [ApiController][Route("api/mi-modulo")]
```

Registrar en `Program.cs`:
```csharp
builder.Services.AddScoped<IMiModuloService, MiModuloService>();
```

### 3. Web — Crear los DTOs espejo

```
NexoWeb/Common/Dtos/MiModuloDtos.cs
```

### 4. Web — Crear las páginas y diálogos

```
NexoWeb/Components/Pages/MiModulo/
    ListaMiEntidad.razor
    MiEntidadDialog.razor
```

### 5. Web — Agregar al NavMenu

```razor
<MudNavGroup Title="Mi Módulo" Icon="@Icons.Material.Filled.Icono" Expanded="false">
    <AuthorizeView Roles="Administrador">
        <Authorized>
            <MudNavLink Href="/mi-modulo/lista">Mi Entidad</MudNavLink>
        </Authorized>
    </AuthorizeView>
</MudNavGroup>
```

---

## 18. NexoSyncAgent — Integración con Visions

Worker service que corre como servicio de Windows. Lee eventos pendientes de `Integracion.EventosSalientes` y los envía a Visions, y también recibe eventos de Visions y los procesa en NEXO vía `Integracion.sp_ProcesarEventoEntrante`.

Se autentica en NexoApi usando el header `X-Api-Key` (SHA256 del API key almacenado en `Integracion.AgentesSync`).

---

## 19. Pendientes Conocidos (Phase 3)

Ver `docs/session-summary.md` para la lista completa priorizada.

Principales:
- DataAnnotations en DTOs de request (validación sin llegar a la BD)
- Checkbox "Recordarme" en Login (actualmente es código muerto)
- Endpoint `/api/auth/refresh-token` no implementado (el RefreshToken se genera pero no se puede usar)
- `Auditoria.LogAuditoria` creado en BD pero no se llena desde la API
- **No hay módulo de Ventas/Facturación.** El catálogo de Clientes solo se usa para etiquetar una Orden de Producción como MTO (Make To Order) — no descuenta stock de Producto Terminado, no genera ingreso, no lleva historial de compras. Si se necesita cerrar el ciclo compra→producción→venta, este es el módulo que falta construir (decisión consciente del usuario de posponerlo, agosto 2026).
- `UsuarioDialog`/`ArticuloDialog`/`CentroTrabajoDialog` ya usan `<MudSelect>` para sus FKs (ya no son campos numéricos libres) — si aparece un formulario nuevo con un ID de catálogo como `MudNumericField`, es una regresión, corregirlo a `MudSelect`.

---

## 20. Lecciones Aprendidas / Bugs Recurrentes (leer antes de tocar código similar)

Estos patrones causaron bugs reales en producción durante agosto 2026. Repetirlos en código nuevo reintroduce los mismos problemas.

### 20.1 — Nunca hardcodear IDs de catálogos sembrados

Los IDs de `Catalogo.TiposArticulo`, `Kardex.TiposMovimientoKardex`, `Produccion.EstadosOP`, etc. dependen del **orden de inserción** de `DatosSemilla.sql`, no de un valor fijo. Se encontraron **5+ lugares distintos** con `tipoArticuloId=3` esperando "Producto Terminado" cuando en realidad ID=3 era "Insumo" (el orden real es MP=1, PT=2, INS=3, SER=4).

**Regla**: siempre traer la lista completa vía API y filtrar client-side por el string `Nombre` (`a.TipoArticulo == "Producto Terminado"`), nunca por `tipoArticuloId=N` en la URL ni por el número crudo en C#.

### 20.2 — Los `Codigo` de `Kardex.TiposMovimientoKardex` deben coincidir EXACTO con los stored procedures

`DatosSemilla.sql` sembró `ENT_COMPRA`, `SAL_PRODUCCION`, etc., pero los SPs en `LogicaNegocio.sql` buscan `ENTRADA_COMPRA`, `SALIDA_WIP`, etc. — un desajuste total que causaba `INSERT` fallido en `Kardex.KardexMovimientos` (columna `TipoMovID` NOT NULL recibiendo NULL) la primera vez que alguien ejecutaba un flujo real (Iniciar OP, Recibir Compra). Si agregas un nuevo tipo de movimiento, verifica con un `SELECT Codigo FROM Kardex.TiposMovimientoKardex` que el string sembrado sea idéntico al que el SP va a buscar.

### 20.3 — Dapper + records sin constructor vacío exige columnas EXACTAS

`connection.QuerySingleAsync<TDto>(...)` con un `record` posicional falla (`InvalidOperationException`) si el `SELECT` final del SP devuelve una columna que no está en el record (típicamente `'OK' AS Resultado` de más). Pasó en 3 SPs distintos antes de detectarse el patrón.

**Trampa peligrosa**: el `COMMIT TRANSACTION` del SP ya ocurrió **antes** de que Dapper intente materializar el resultado — así que el INSERT/UPDATE ya se aplicó en la BD aunque la UI muestre una excepción. Si un usuario reporta un error pero dice "aun así parece que funcionó", verificar el estado real en la BD antes de asumir que no pasó nada.

**Regla**: el `SELECT` final del SP debe tener exactamente las mismas columnas (incluyendo `Resultado` si el DTO lo tiene) que el record de respuesta en C#.

### 20.4 — MudTable `SelectedItemChanged` puede recibir `null`

Al recargar `Items` y limpiar `SelectedItem`, MudBlazor dispara el callback con `null`. El handler debe declarar el parámetro `T?` y manejarlo explícitamente, no asumir que siempre viene un objeto.

### 20.5 — Redondeo de consumo por tipo de Unidad

`sp_LiberarOrdenProduccion` y `sp_IniciarOrdenProduccion` calculan la cantidad de insumo necesaria escalando la receta (`CantidadRequerida * FactorEscala * (1 + Merma%)`). Cuando la `Unidad` de esa línea de receta es de tipo `'UNIDAD'` (discreta — piezas, no kg/L), el resultado se redondea con `CEILING()` porque no se puede tomar una fracción de un artículo indivisible. Ambos SPs deben tener el mismo criterio de redondeo o una orden puede "liberarse" con una cantidad y fallar al "iniciar" con otra.

### 20.6 — `sp_AjustarConsumoReal` debe mover stock, no solo el registro

Ajustar la cantidad real consumida de un insumo (más o menos de lo que ya se descontó teóricamente al iniciar la OP) **debe generar el delta correspondiente en `InventarioStock` y `Kardex`** — si solo se actualiza el número en `OrdenesProduccionConsumo`, el inventario queda desincronizado silenciosamente (sobreestimado si ajustaste hacia arriba, subestimado si ajustaste hacia abajo).

### 20.7 — `Catalogo.Articulos` — campos ahora opcionales/nuevos

- `UnidadID` es **nullable** (antes NOT NULL) — un `Servicio` no siempre tiene unidad física aplicable.
- `UnidadesPorEmbalaje` (decimal, nullable) — cuántas unidades base trae 1 "Caja".
  ⚠️ **Corrección respecto a la primera versión de esta nota (agosto 2026):** inicialmente esto era solo informativo/de presentación. Ya no — desde el fix de la sección 20.9, **sí afecta el cálculo real** de `sp_LiberarOrdenProduccion`/`sp_IniciarOrdenProduccion` cuando la Unidad de una línea de receta no coincide con la Unidad base del artículo (conversión Caja↔Unidad). Sigue siendo puramente informativo en las tablas/formularios de Compras/Ajuste (esos flujos no convierten, solo muestran el equivalente como ayuda visual).
- `Servicio` **no es sinónimo de "intangible sin stock"** — puede comprarse por Orden de Compra, tener Stock Mínimo/Punto de Reorden, y usarse como insumo de una receta (ej. una licencia de Windows como parte de la receta de un Computador armado). Solo "Vida Útil (caducidad)" no aplica a Servicio.

### 20.8 — La Unidad de una línea de receta puede no coincidir con la Unidad del artículo

`Produccion.RecetaBOM_Detalle.UnidadID` es independiente del `Catalogo.Articulos.UnidadID` del insumo — nada impedía (ni impide) que alguien arme una receta pidiendo "2 und" de un artículo que se stockea por "Caja". `sp_LiberarOrdenProduccion`/`sp_IniciarOrdenProduccion` ahora detectan este caso y convierten usando `UnidadesPorEmbalaje` (ver 20.9) **solo para el par Caja↔Unidad**; cualquier otra combinación de unidades distintas (ej. kg vs Caja) se deja sin convertir — es responsabilidad de quien arma la receta usar la misma unidad que el artículo en ese caso, el sistema no adivina factores de conversión que no existen.

### 20.9 — Conversión Caja↔Unidad en `sp_LiberarOrdenProduccion` / `sp_IniciarOrdenProduccion`

Antes de agosto 2026 (segunda mitad), estos SPs comparaban directamente la cantidad requerida por la receta contra `InventarioStock.CantidadActual` sin verificar si ambas estaban expresadas en la misma Unidad — causaba faltantes falsos (o sobreconsumo, según el sentido del error) cada vez que un artículo se stockeaba por Caja pero la receta lo pedía en unidades sueltas. Se corrigió agregando conversión explícita usando `Catalogo.Articulos.UnidadesPorEmbalaje` cuando `RecetaBOM_Detalle.UnidadID <> Articulos.UnidadID` y el par es Caja/Unidad. **Los dos SPs deben mantenerse en sincronía** (mismo criterio de conversión y redondeo) — si se toca uno, tocar el otro.

### 20.10 — Traspasos: casi todo el stock real tiene Lote asignado

`Inventario.sp_CrearYEnviarTraspaso` buscaba stock con `LoteID IS NULL` cuando el detalle no especificaba un lote exacto — pero la UI de "Nuevo Traspaso" **nunca** deja elegir lote, y prácticamente todo el stock real tiene lote (Compras y Producción siempre crean uno vía `Inventario.Lotes`). Resultado: cualquier traspaso de un artículo con stock "normal" fallaba con "Stock insuficiente" aunque sobrara inventario. Se corrigió para que, cuando no se pide un lote específico, tome de **todos los lotes disponibles por FEFO** (mismo patrón que `sp_IniciarOrdenProduccion`), generando una línea de `TraspasosDetalle`/`Kardex` por cada lote consumido.

### 20.11 — Login acepta Username o Email

`Auth.AuthService.LoginAsync` ahora busca `WHERE Username = @Username OR Email = @Username` — antes solo aceptaba el Username exacto, y era común que el usuario intentara ingresar con su correo (confundiéndolo con el username) y recibiera "credenciales incorrectas" sin que hubiera ningún problema real con su cuenta. Si se agrega una nueva forma de autenticación, mantener esta tolerancia.

### 20.12 — El consumo de materia prima NO se ajusta solo al cerrar una OP

`sp_IniciarOrdenProduccion` descuenta el consumo **teórico** basado en `CantidadProgramada` (lo planeado) en el momento de "Iniciar" — no sabe todavía cuánto saldrá realmente. `sp_CerrarOrdenProduccion` usa `CantidadProducidaReal` (lo que de verdad salió) **solo para calcular el costo unitario**, no reajusta retroactivamente el consumo de insumos. Si programaste 10 y salieron 9, el sistema sigue creyendo que se gastaron insumos para 10 **a menos que** alguien use "Ajustar Consumo" en cada línea antes o después de cerrar la orden — eso sí devuelve al stock la diferencia no usada (ver 20.6). No es un bug: es una limitación de diseño conocida — el ajuste es manual, no automático. Explicarlo así si un usuario reporta "se descontó de más".

### 20.13 — `Inventario.vw_StockConsolidado` ya no filtra `CantidadActual > 0`

Antes los artículos que llegaban a 0 unidades desaparecían por completo de Consulta de Stock. Se quitó el filtro para que sigan apareciendo (con alerta roja "Sin stock" en el frontend, distinta de la naranja "Requiere pedido" para cantidad baja-pero-no-cero). **Nota de portabilidad**: `ScriptsSQL/ScriptsCompletos/sqlportablenexo.sql` (el script de instalación desde cero) quedó desincronizado varias veces durante agosto 2026 porque los fixes se aplicaban directo a la BD viva sin siempre re-exportar ese archivo completo — tiene una nota de instalación al inicio listando qué scripts adicionales de `ScriptsProcesos/` ejecutar para llegar al estado actual. Si se hace otro cambio de esquema, considerar si también hay que tocar ese script maestro, no solo `LogicaNegocio.sql`/`DatosSemilla.sql`.

### 20.14 — Campana de notificaciones: agregada por categoría, no por item

`Features/Notificaciones` (`/api/notificaciones/resumen`) resume el estado del sistema en 3 categorías (Sin Stock, Bajo Stock, Producción en Proceso) — **una notificación por categoría con conteo y hasta 3 nombres**, no una fila por cada artículo/orden individual. Esto fue deliberado: el usuario pidió explícitamente que no fuera "molesto" — una lista larga de alertas individuales se vuelve ruido. Si se agregan más categorías (ej. órdenes de compra pendientes, traspasos en tránsito), seguir el mismo patrón de agregación.

En el frontend (`MainLayout.razor`), la campana usa `MudMenu` con `ActivatorContent` custom (para superponer el punto rojo sobre el ícono) y se refresca con un `System.Timers.Timer` cada 2 minutos (no polling agresivo, no SignalR custom — suficiente para sentirse "al día" sin sobrecargar). El punto rojo (`.nexo-topbar__notif-dot`) solo se muestra cuando `_notificaciones.Total > 0`. **Importante**: el timer se crea en `OnInitialized` (no `OnInitializedAsync`) y se limpia explícitamente en `Dispose()` (`Stop()` + `Dispose()`) — si se olvida, el timer sigue corriendo contra un circuito de Blazor Server ya cerrado.

### 20.15 — `MudDatePicker`/`MudDateRangePicker` deben usar `PickerVariant="PickerVariant.Dialog"`

Con el `PickerVariant` por defecto (popover inline), el calendario se ancla y a veces se recorta al ancho del contenedor que lo rodea (ej. `.nexo-chart-header` con `Style="max-width: 240px"` en el input) — el resultado visual es texto superpuesto/ilegible en el header del calendario. **Todos** los `MudDatePicker`/`MudDateRangePicker` del proyecto (`Dashboard.razor` x2, `RecibirLineaDialog.razor`, `CerrarOrdenDialog.razor`, `ConsultaKardex.razor` x2, `CrearOrden.razor`) usan `PickerVariant="PickerVariant.Dialog"`, que abre el calendario como modal centrado — inmune al ancho del contenedor padre. El modal se retemó en morado en `wwwroot/app.css` (sección "MudDatePicker / MudDateRangePicker").

**Importante — nombres de clases CSS de MudBlazor**: no asumir/inventar nombres de clase para estilizar internals de MudBlazor (ej. se probó `.mud-picker-day`, `.mud-picker-day-selected`, `.mud-picker-abbr`, `.mud-picker-calendar-header` — **ninguna existe**). Verificar siempre contra el CSS compilado real del paquete instalado: `C:\Users\ASROCK\.nuget\packages\mudblazor\7.15.0\staticwebassets\MudBlazor.min.css` (grep por el prefijo, ej. `mud-picker-`, `mud-day`). Las clases reales para el calendario del date picker son `.mud-day` (celda de día), `.mud-current` (hoy), `.mud-selected` (día elegido), `.mud-range-selection` / `.mud-range-start-selected` / `.mud-range-end-selected` (rango), `.mud-picker-calendar-header-switch` (botón mes/año), `.mud-picker-nav-button-prev/-next` (flechas), `.mud-picker-calendar-week-text` (letras de días de la semana), `.mud-picker-datepicker-toolbar` (franja superior con la fecha grande).

### 20.16 — Gráfico "Variación de Producción vs Plan" en el Dashboard (barras verdes/rojas estilo IPI)

A pedido del usuario (referencia visual: gráfico del INE "Índice de producción industrial"), se agregó un panel nuevo en `Dashboard.razor` con barras centradas en una línea de cero — verdes cuando `TotalReal >= TotalPlanificado` del día, rojas cuando queda por debajo — reutilizando los mismos datos ya cargados de `_planVsReal` (sin llamada nueva a la API). Solo se etiquetan el pico más alto y el más bajo (no cada barra, para no saturar), igual que la referencia.

**Por qué no se usó `MudChart`**: `MudChart` de tipo `Bar` colorea por *serie completa*, no por barra individual — no hay forma nativa de que una misma serie tenga barras verdes y rojas mezcladas según el signo del valor. Se construyó en su lugar un SVG a mano (`ObtenerBarrasVariacion()` calcula posiciones/alturas, `ConstruirSvgVariacion()` genera el markup).

**Gotcha de Razor**: el elemento SVG `<text>` no puede llevar atributos directamente en un `.razor` — Razor reserva ese nombre de tag y lanza `RZ1023`. La solución fue generar ese fragmento como `string` en C# (`ConstruirSvgVariacion()`) e inyectarlo con `@((MarkupString)...)`. Es seguro porque el contenido es 100% numérico/generado por el servidor, sin input de usuario.

**Gotcha de cultura**: la app fuerza `es-CO` globalmente (coma decimal). Los atributos numéricos de SVG (`x`, `y`, `width`, `height`) necesitan punto decimal — usar `CultureInfo.InvariantCulture` al formatear (helper `Inv()` en `Dashboard.razor`), nunca `.ToString()` directo sobre un `double` dentro de este componente.

### 20.17 — Toolbar del `MudDatePicker`/`MudDateRangePicker` (dialog): año y fecha se superponían

Con `PickerVariant.Dialog`, el toolbar superior morado renderiza dos `MudButton` (`mud-button-year` con el año y `mud-button-date` con `GetTitleDateString()`) — por defecto un `MudButton` es `inline-flex` con texto `nowrap`. Con un rango de fechas el texto es largo ("lun, 20 jul – lun, 03 ago") y visualmente se encimaba con el año. Fix en `app.css` (bloque "MudDatePicker / MudDateRangePicker"): se fuerza `.mud-picker-datepicker-toolbar` a `flex-direction: column`, y ambos botones a `position: static`, `width: 100%`, `white-space: normal` (permite wrap en 2 líneas sin superposición) y `text-align: left`. También se subió `.mud-picker { min-width }` de 320px a 340px.

**Complementario**: el input de texto del `MudDateRangePicker` (no el modal, el campo visible en la página) se veía truncado ("20/07/2", "03/08/2") porque el `Style="max-width: 240px"` puesto en `Dashboard.razor` era muy angosto para dos fechas `dd/MM/yyyy` + separador + ícono. Se subió a `max-width: 300px; min-width: 260px`.

**Nota sobre `.mud-picker` — cómo descubrir clases reales de MudBlazor**: para verificar la estructura interna real (no adivinar), se usó el código fuente del componente en GitHub (`https://raw.githubusercontent.com/MudBlazor/MudBlazor/v7.15.0/src/MudBlazor/Components/DatePicker/MudBaseDatePicker.razor` vía `WebFetch`) además de grep sobre el CSS compilado en `C:\Users\ASROCK\.nuget\packages\mudblazor\7.15.0\staticwebassets\MudBlazor.min.css`. El grep del CSS solo muestra clases que tienen reglas propias (no todas las que existen en el markup); si hace falta ver el HTML/Razor exacto de un componente MudBlazor, el fuente en GitHub (tag `vX.Y.Z` que coincida con la versión del `.csproj`) es más confiable.

### 20.18 — Búsqueda global de la barra superior (`api/busqueda`)

A pedido del usuario, la barra de búsqueda del Top Bar (antes un `<input>` decorativo sin funcionalidad) ahora es una búsqueda real con sugerencias en vivo. Arquitectura:

- **Backend**: `Features/Busqueda/BusquedaService.cs` (`api/busqueda?q=texto`) consulta con `LIKE '%texto%'` (parametrizado vía Dapper, TOP 5 por categoría) sobre `Catalogo.Articulos`, `Catalogo.Clientes`, `Catalogo.Proveedores`, `Organizacion.CentrosCosto` (**ojo**: no es `Catalogo.CentrosCosto`, es un esquema `Organizacion` aparte), `Inventario.Bodegas`, `Produccion.OrdenesProduccion` y `Compras.OrdenesCompra` (`oc.EstadoOC` es una columna string directa, no una FK a una tabla de estados — a diferencia de `Produccion.OrdenesProduccion.EstadoOPID` que sí es FK a `Produccion.EstadosOP`).
- **Filtrado por rol**: cada categoría solo se consulta si `usuario.IsInRole(...)` coincide con los mismos roles que el `@attribute [Authorize(Roles=...)]` de la página de destino (ej. Clientes/Proveedores/CentrosCosto/Bodegas solo para Administrador) — así no se sugiere un resultado que al hacer click le va a negar el acceso al usuario.
- **Frontend**: `MainLayout.razor` — el `<input>` de búsqueda tiene un debounce manual (350ms) implementado con un contador `_busquedaId` (se descarta la respuesta si el usuario ya siguió escribiendo — más simple que `CancellationToken` porque `INexoApiClient.GetAsync<T>` no acepta uno). El dropdown de resultados usa `@onmousedown` + `@onmousedown:preventDefault="true"` en cada item (en vez de `@onclick`) para que el click se procese ANTES de que el `@onblur` del input (con un delay de 150ms) oculte el dropdown — si se usara `@onclick` normal, el blur del input cerraría el dropdown antes de que el click llegara a disparar.
- **Deep-link a Artículos**: `Articulos.razor` ahora lee el filtro de texto desde la URL con `[SupplyParameterFromQuery(Name = "texto")]` sobre la propiedad `_filtroTexto` (no requiere `[Parameter]`, funciona standalone en ASP.NET Core 8+), así un resultado de búsqueda tipo Artículo llega a `/catalogo/articulos?texto=SKU-001` ya filtrado. Los demás catálogos (Clientes, Proveedores, Centros de Costo, Bodegas) no tenían filtro de texto en la página, así que sus resultados de búsqueda navegan a la lista completa sin pre-filtrar — si se les agrega un filtro de texto en el futuro, replicar el mismo patrón `[SupplyParameterFromQuery]`.

### 20.19 — Top Bar oscuro (`#13131F`, 76px) — antes blanco 64px

A pedido explícito del usuario ("que quede del mismo color de la barra lateral... hazla un poco más gruesa"), el Top Bar pasó de blanco/64px a `#13131F`/76px (mismo color que el sidebar). Esto invirtió el esquema de contraste de **todo** el contenido del AppBar — título, ícono de menú, barra de búsqueda, campana de notificaciones, avatar/nombre/rol — de "texto oscuro sobre blanco" a "texto claro sobre oscuro". Los estilos viven en `MainLayout.razor.css` (bloque "TOP BAR") con refuerzo en `wwwroot/app.css` (`.nexo-topbar__user-name` etc.) — **si se vuelve a tocar el color del Top Bar, hay que actualizar ambos archivos** (el `::deep` de `MainLayout.razor.css` gana por especificidad sobre el `!important` global de `app.css`, pero dejarlos desincronizados es confuso). El panel desplegable de notificaciones (`MudMenu`) sigue siendo blanco con texto oscuro — es un popover aparte, no hereda el fondo del AppBar.

**Gotcha operativo importante**: el usuario reportó "el top bar sigue en blanco y el search no sirve" en la sesión siguiente — la causa NO era el código (que sí había cambiado y compilaba bien), sino que el usuario corre la app bajo el debugger de Visual Studio, y como VS tiene los `.dll` bloqueados, mis `dotnet build` de verificación se hacen a una carpeta de scratch aparte y NUNCA tocan los binarios que VS está sirviendo. **Cada vez que se termina una tarea con cambios de código, hay que recordarle al usuario que debe detener y volver a correr (F5) en Visual Studio** para ver los cambios reflejados — si no, la sesión sigue viendo la build vieja indefinidamente. Ver [[reference_nexo_erp_project]] en la memoria de Claude.

### 20.20 — Preferencias por usuario: tema oscuro + vista lista/tarjetas (`Seguridad.PreferenciasUsuario`)

Sistema de preferencias personales (cualquier rol puede cambiarlas para sí mismo) guardadas en `Seguridad.PreferenciasUsuario` (UsuarioID, Clave, Valor — genérico, sin migrar esquema por cada preferencia nueva). Ver `docs/database.md` sección 9.11 para el DDL.

- **Backend**: `Features/Preferencias/PreferenciasService.cs` — `ObtenerTodasAsync` trae todas las claves del usuario de una vez (se cargan una sola vez por circuito), `GuardarAsync` hace `MERGE` (upsert). Controlador en `api/preferencias` (`GET` = todas, `PUT /{clave}` = una).
- **Frontend**: `Common/Auth/PreferenciasState.cs` — servicio *Scoped* (uno por circuito de Blazor Server) que cachea las preferencias en memoria, expone `TemaOscuro` y `ObtenerVista(pagina)`, y dispara `OnCambio` cuando algo cambia para que los componentes suscritos se re-rendericen. Se carga en `MainLayout.OnInitializedAsync` (`Preferencias.CargarAsync()`, idempotente) y se reinicia en `CerrarSesionAsync` (`Preferencias.Reiniciar()`) para que un login distinto en el mismo circuito no arrastre preferencias ajenas.
- **Tema oscuro — solo páginas, nunca Top Bar/Sidebar**: requisito explícito del usuario. `MainLayout.razor` envuelve `MudPopoverProvider` + `MudDialogProvider` + `MudSnackbarProvider` + `MudLayout` completo (Top Bar, Sidebar Y MainContent) en un `<div class="@(Preferencias.TemaOscuro ? "nexo-tema-oscuro" : "")">` — pero el CSS en `app.css` (bloque "MODO OSCURO") **solo** define reglas para `.nexo-tema-oscuro .mud-main-content`, `.mud-dialog`, `.mud-picker`, `.mud-table*`, `.nexo-kpi`, etc. — nunca para `.nexo-topbar`/`.nexo-sidebar`, así que aunque están "adentro" del wrapper no cambian (ya son oscuros de por sí). Se envolvió TODO el wrapper (no solo `MudMainContent`) porque `MudDialogProvider`/`MudPopoverProvider` son *siblings* de `MudLayout`, no descendientes — si el wrapper solo cubriera `.mud-main-content`, los diálogos y los `MudDatePicker` (que se portan a esos providers) nunca habrían recibido el tema oscuro.
- **Por qué `!important` en todo el bloque de modo oscuro**: el CSS scoped de cada página (`*.razor.css`, ej. `Dashboard.razor.css`) se compila con un atributo `[b-xxxx]` agregado al selector, lo que le da la MISMA especificidad que una regla de dos clases en `app.css` (`.nexo-tema-oscuro .nexo-kpi`) — y `NexoWeb.styles.css` (que empaqueta todo el CSS scoped) carga DESPUÉS de `app.css` en `App.razor`, así que a igual especificidad el scoped gana por orden de carga. Sin `!important`, el modo oscuro simplemente no se habría aplicado en las páginas con CSS scoped propio.
- **MudChart en oscuro**: los ejes de `MudChart` usan `fill: var(--mud-palette-text-primary)` (confirmado en el CSS fuente de MudBlazor) — como es una variable CSS heredable, redefinirla dentro de `.nexo-tema-oscuro` basta para que los charts (incluido el SVG de variación hecho a mano) se vean bien, sin tocar cada gráfico individualmente.
- **Vista Lista/Tarjetas**: componente reutilizable `Components/Shared/VistaToggle.razor` (parámetro `Pagina`, clave única por pantalla, ej. `"articulos"`, `"consulta-stock"`, `"ordenes-produccion"`) + clases `.nexo-card-grid`/`.nexo-item-card` en `app.css`. Cada página que lo usa debe: 1) implementar `IDisposable` y suscribirse a `Preferencias.OnCambio` en `OnInitialized` (para re-renderizar cuando el toggle cambia), 2) usar `@if (Preferencias.ObtenerVista("clave") == "tarjetas") { ...grid... } else { ...MudTable... }`. **Aplicado por ahora solo en 3 pantallas** (Artículos, Consulta de Stock, Órdenes de Producción) — el resto de pantallas de listado (Clientes, Proveedores, Centros de Costo, Bodegas, Centros de Trabajo, Usuarios, Órdenes de Compra, Traspasos, Recetas, Kardex) no tienen el toggle todavía; replicar el mismo patrón cuando se pida.
