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
| `/api/auth` | `AuthController` | Login, registro, gestión de usuarios, `/perfil` y `/perfil/foto` (self-service: nombre y foto propios, cualquier rol) |
| `/api/catalogo` | `ArticulosController`, `BodegasController`, `CentroCostoController`, `ClientesYCentrosTrabajoController` | CRUD de catálogos maestros. `articulos/{id}/imagen` (GET anónimo, PUT/DELETE Admin+SupervisorPlanta) para la imagen opcional del artículo |
| `/api/configuracion` | `ConfiguracionController` | `GET empresa` (todos), `PUT empresa` / `PUT` / `DELETE empresa/logo` (solo Administrador) — nombre y logo globales del sidebar |
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
| `/settings` | `Settings.razor` — preferencias personales (tema oscuro, vista de listados, mostrar ayuda) | Todos autenticados |
| `/settings/ayuda` | `Ayuda.razor` — flujo de trabajo (placeholder, el usuario agrega el diagrama después) + contacto por correo/WhatsApp reales de la empresa | Todos autenticados |

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

**Config UI (agosto 2026)**: en `Catalogo > Centros de Costo` (`CentroCostoDialog.razor`, solo modo edición), el Administrador puede:
- Activar `TieneVisions` (switch "Este cliente tiene Visions") + `IdentificadorClienteVisions` (campo numérico, etiqueta "Código CENTROCOSTO en Visions") + `BodegaVentaVisionsID` (`MudSelect`, bodegas de ese mismo Centro de Costo). Estos 3 campos solo se guardan/envían si `TieneVisions=true` (si se desactiva, se limpian a `null` en el request).
- **`IdentificadorClienteVisions` (columna nvarchar por flexibilidad, pero SIEMPRE debe ser numérico) NO es un identificador de cliente — es el código `CENTROCOSTO` (smallint) que identifica esa sucursal DENTRO de la base de datos de Visions de ese cliente** (columna `CENTROCOSTO` en `dbo.TARJETA`/`dbo.MOVDETALLES`/`dbo.CENTROSDECOSTO` de Visions). Es un error de nombre heredado del diseño inicial — no renombrar la columna sin actualizar todos los usos (`IntegracionService`, `TareaSincronizarConfiguracion`, `TareaExportarVentas`, el dialog). Si un cliente tiene una sola sucursal, casi siempre es `1`.
- Botón "API Key" (solo visible si `TieneVisions=true`) que llama `POST api/integracion/agentes/api-key` y muestra la clave generada UNA sola vez en un `MudMessageBox` (no se persiste en claro en NEXO, solo su hash en `Integracion.AgentesSync`).

**Topología: varias sucursales (varios Centros de Costo) en Visions (agosto 2026)**: la relación es **un Agente (un `.exe`/servicio de Windows, una API Key) = un Centro de Costo = un código `CENTROCOSTO`**, nunca 1 agente para varias sucursales. Dos escenarios reales, ambos soportados:
- **Cada sucursal tiene su propia base de Visions separada**: 1 Centro de Costo en NEXO por sucursal, 1 instalación del agente por sucursal, cada una con su propio `ConnectionStrings:VisionsDb` (apuntando a su propia base) y su propia API Key. No hay riesgo de cruce, cada agente ve solo su base.
- **Varias sucursales comparten UNA sola base de Visions** (típico: instalación central con varios `CENTROCOSTO`): se crea 1 Centro de Costo en NEXO por sucursal, cada uno con su propio código `CENTROCOSTO` real y su propia API Key — pero se instalan **varios agentes** (varios servicios de Windows, uno por sucursal) todos con el **mismo** `ConnectionStrings:VisionsDb` (la base compartida) y cada uno con su **propia** `NexoApi:ApiKey`. `TareaExportarVentas` filtra explícitamente por `m.CENTROCOSTO = @CentroCostoVisions` (el código que le devolvió `TareaSincronizarConfiguracion` para esa API Key) — así, aunque los 3 agentes lean la misma base `MOVDETALLES`, cada uno solo procesa y reporta las ventas de SU propia sucursal. Antes de agosto 2026 esta query no tenía ese filtro y hubiera podido cruzar/atribuir mal las ventas entre sucursales que comparten base — corregido.

**Descuento real de stock por venta en Visions (agosto 2026)**: `Integracion.sp_ProcesarEventoEntrante` ya NO solo acumula en `Integracion.InventarioReportadoVisions` — también descuenta stock real (FEFO) de `Inventario.InventarioStock` y genera `Kardex.KardexMovimientos` (tipo `SALIDA_VENTA_VISIONS`) en la bodega fija `Organizacion.CentrosCosto.BodegaVentaVisionsID` del Centro de Costo. A propósito NO bloquea por stock insuficiente (la venta en Visions ya ocurrió, es un hecho consumado) — si no alcanza, el stock queda en negativo como señal de revisión manual. Los movimientos de Kardex generados por el sync se atribuyen al usuario de sistema `sistema.sync` (`Seguridad.Usuarios`, `Estado=0`, no puede iniciar sesión, existe solo como FK de auditoría).

**Decisión consciente**: se evaluó reemplazar el agente .NET por sincronización pura SQL (Linked Server) y se descartó — las instalaciones de Visions de cada cliente suelen estar en máquinas/redes separadas de `NEXO_ERP`, lo que un Linked Server no maneja de forma robusta. Se mantiene el Worker Service + API Key.

**Instalación en un cliente nuevo**: `docs/sql/InstalarSincronizacionVisions.sql` — script idempotente (`IF NOT EXISTS`) que crea únicamente las 3 tablas de sincronización (`dbo.NEXO_ConfiguracionSync`, `dbo.NEXO_EntradasInventario`, `dbo.NEXO_VentasExportadas`) sobre la base de datos de Visions YA EXISTENTE del cliente, sin tocar sus tablas nativas. Se ejecuta una sola vez por cliente antes de instalar el NexoSyncAgent.

**Prefijos de documento de venta (agosto 2026)**: antes `NEXO_ConfiguracionSync.TiposDocumentoVenta` (en la base de Visions) solo se podía editar por SQL directo contra Visions — sin control de acceso. Ahora es 100% administrado desde NEXO:
- Nueva columna `Organizacion.CentrosCosto.PrefijosDocumentoVentaVisions` (nvarchar(200), lista de códigos separados por coma, ej. `"POS,FV"`), editable solo por Administrador en `CentroCostoDialog.razor` mediante un checklist fijo (`POS`, `FV`, `FE`, `NC`, `ND` — codificado en el propio componente; si aparece un tipo nuevo hay que agregarlo ahí).
- Nuevo endpoint `GET api/integracion/configuracion` (auth por API Key, igual que el resto del agente) que devuelve `ConfiguracionAgenteResponse(CentroCostoVisions, Activo, PrefijosDocumentoVenta)` — `CentroCostoVisions` es `TRY_CAST(IdentificadorClienteVisions AS INT)` (puede ser `null` si el Admin no lo ha configurado todavía, en cuyo caso el agente se salta la ronda con un warning en vez de reventar).
- Nueva tarea `NexoSyncAgent.Tareas.TareaSincronizarConfiguracion` — corre primera en cada ronda del Worker (antes de aplicar entradas o exportar ventas), llama ese endpoint, hace `MERGE` sobre `dbo.NEXO_ConfiguracionSync` en Visions (`CENTROCOSTO`, `Activo`, `TiposDocumentoVenta`) y devuelve el código `CentroCostoVisions` para que `Worker.cs` se lo pase a `TareaExportarVentas` (ver topología multi-sucursal arriba). Así ese valor en Visions queda como un espejo de solo lectura de lo que el Administrador configuró en NEXO Web — nadie más lo debería tocar directo por SQL.

**Mapeo de Articulos bidireccional NEXO <-> Visions (agosto 2026)**: antes solo existía la tabla `Integracion.MapeoArticulos` sin ninguna UI (se cargaba por SQL directo) y no había forma de crear/actualizar el maestro de artículos en Visions desde NEXO. Ahora:
- **Alcance**: solo `Catalogo.Articulos` con `TipoArticulo = 'Producto Terminado'` se sincronizan — Visions es un sistema de punto de venta, Materia Prima/Insumos/Servicios nunca se venden ahí y nunca se mapean (`IntegracionService.CrearMapeoAsync` lo valida y rechaza cualquier otro tipo).
- **NEXO → Visions**: pantalla `catalogo/mapeo-articulos-visions` (Admin-only) — al crear un mapeo (`POST api/integracion/mapeos`), se encola un `Integracion.EventosSalientes` con `TipoEvento='SINCRONIZAR_ARTICULO'`. El agente (`TareaAplicarEntradasInventario.SincronizarArticulo`) hace `MERGE` sobre `dbo.TARJETA` en Visions (crea la fila si no existe, o actualiza `DETALLE`/`COSTO`/`PPUBLICO`/`EXISTENCIASMINIMAS` si ya existe) — **nunca toca `EXISTENCIAS`**, eso sigue siendo responsabilidad exclusiva del evento de entrada de inventario (`ENTRADA_PRODUCTO_TERMINADO`/`TRASPASO_RECIBIDO`), para no pisar el stock real de Visions con un valor inicial cada vez que se resincroniza nombre/precio.
- **Visions → NEXO (artículo desconocido)**: si Visions reporta la venta de una `REFERENCIA` sin mapeo, `sp_ProcesarEventoEntrante` YA NO hace `THROW` — deja el evento `Procesado=0` (se reintenta solo cada ronda) y registra/actualiza una fila en la nueva tabla `Integracion.ArticulosPendientesMapeo` con el nombre/costo/precio que Visions tenía en `dbo.TARJETA` al momento de la venta (viajan en `RegistrarEventoEntranteRequest.NombreArticuloVisions/CostoArticuloVisions/PrecioArticuloVisions`, que `TareaExportarVentas` obtiene con un `LEFT JOIN` a `dbo.TARJETA`). El Administrador los revisa en la misma pantalla y con un clic decide **vincular a un Producto Terminado ya existente** o **crear uno nuevo** (precargado con los datos que sugirió Visions, editable antes de confirmar) — decisión consciente de NO crear automáticamente sin revisión humana, para no meter al catálogo datos de Visions sin que nadie los vea.
- **Bug corregido de paso**: `IntegracionService.RegistrarEventoEntranteAsync` antes decidía si reprocesar un evento mirando solo si ya existía una fila con ese `IdEventoExterno` — no si había quedado `Procesado=1`. Si el primer intento fallaba (ej. sin mapeo), el evento quedaba atascado para siempre, incluso después de arreglar el mapeo, porque NEXO respondía "ya existe" sin reintentar la SP. Ahora distingue: si existe y `Procesado=1` → no hace nada (idempotencia real); si existe pero `Procesado=0` → reintenta la misma SP en vez de insertar de nuevo.

**Pendiente / fuera de alcance de esta fase**: no hay UI para `Integracion.MapeoArticulos` (mapeo Artículo NEXO ↔ REFERENCIA Visions por Centro de Costo) ni para administrar `Integracion.AgentesSync` más allá de generar la API key — hoy se asume que el mapeo se carga directo por SQL, y **solo los artículos mapeados ahí sincronizan** (no es automático para "cualquier artículo" todavía).

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

- **Backend**: `Features/Busqueda/BusquedaService.cs` (`api/busqueda?q=texto`) consulta con `LIKE '%texto%'` (parametrizado vía Dapper, TOP 5 por categoría) sobre `Inventario.vw_StockConsolidado` (categoría "Stock", sin restricción de rol porque `/inventario/stock` es `[Authorize]` sin roles), `Inventario.TraspasosBodega` (Admin/Bodeguero), `Catalogo.Articulos`, `Catalogo.Clientes`, `Catalogo.Proveedores`, `Organizacion.CentrosCosto` (**ojo**: no es `Catalogo.CentrosCosto`, es un esquema `Organizacion` aparte), `Inventario.Bodegas`, `Produccion.OrdenesProduccion` y `Compras.OrdenesCompra` (`oc.EstadoOC` es una columna string directa, no una FK a una tabla de estados — a diferencia de `Produccion.OrdenesProduccion.EstadoOPID` que sí es FK a `Produccion.EstadosOP`). Las categorías Stock y Traspasos se agregaron después porque el usuario probó con el rol Bodeguero y notó que casi no había nada que buscar — Bodeguero solo tenía acceso a la categoría "Orden de Compra" (Artículos/Clientes/Proveedores/Bodegas están restringidos a Admin/SupervisorPlanta), aunque sí puede ver Stock y Traspasos en el menú.
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
- **Tema oscuro — solo páginas, nunca Top Bar/Sidebar**: requisito explícito del usuario. `MainLayout.razor` envuelve `MudPopoverProvider` + `MudDialogProvider` + `MudSnackbarProvider` + `MudLayout` completo (Top Bar, Sidebar Y MainContent) en `<div id="nexo-app-root" class="@(Preferencias.TemaOscuro ? "nexo-tema-oscuro" : "")">` — pero el CSS en `app.css` (bloque "MODO OSCURO") **solo** define reglas para `.mud-main-content`, `.mud-dialog`, `.mud-picker`, `.mud-table*`, `.nexo-kpi`, etc. dentro de ese wrapper — nunca para `.nexo-topbar`/`.nexo-sidebar`, así que aunque están "adentro" del wrapper no cambian (ya son oscuros de por sí). Se envolvió TODO el wrapper (no solo `MudMainContent`) porque `MudDialogProvider`/`MudPopoverProvider` son *siblings* de `MudLayout`, no descendientes — si el wrapper solo cubriera `.mud-main-content`, los diálogos y los `MudDatePicker` (que se portan a esos providers) nunca habrían recibido el tema oscuro.
- **Bug real encontrado y corregido — `!important` NO alcanza, hace falta un ID**: la primera versión usaba `.nexo-tema-oscuro .algo` (solo clases) y el fondo general de la página se quedaba blanco pese al `!important`. Causa: `!important` solo gana contra declaraciones *sin* `!important` — cuando DOS reglas con `!important` compiten (la mía en `app.css` vs. el hex fijo `background:#F4F5F9 !important` de `.mud-main-content.nexo-main-content` en `MainLayout.razor.css`), gana la de **mayor especificidad**, y si empatan, la que **carga después** en el HTML. El CSS scoped de cada página compila agregando un atributo `[b-xxxx]` al selector (`.mud-main-content.nexo-main-content[b-xxxx]` = 3 "clases"), que empata en especificidad con `.nexo-tema-oscuro .mud-main-content.nexo-main-content` (también 3 clases) — y como `NexoWeb.styles.css` (todo el CSS scoped empaquetado) carga DESPUÉS de `app.css` en `App.razor`, el scoped ganaba el empate. **Fix**: todos los selectores del bloque de modo oscuro ahora empiezan con `#nexo-app-root.nexo-tema-oscuro` (ID + clase) en vez de solo `.nexo-tema-oscuro` — un selector con ID tiene más especificidad que cualquier combinación de clases/atributos, así que gana siempre sin importar el orden de carga. **Regla general para el futuro**: cualquier override global en `app.css` que deba ganarle a CSS scoped de una página debe usar un ID como ancla, no solo clases — la coincidencia de especificidad con `!important` en ambos lados es un empate silencioso muy fácil de pasar por alto.
- **Contraste fondo/tarjeta**: `--n-bg` (fondo general, `#0D0D14`) y `--n-card` (tarjetas/tablas/diálogos, `#1C1C2C`) son dos tonos deliberadamente distintos — si fueran el mismo color las tarjetas se verían "planas" sin profundidad. Pedido explícito del usuario tras ver la primera versión (que además del bug de arriba, usaba tonos casi idénticos entre sí).
- **MudChart en oscuro**: los ejes de `MudChart` usan `fill: var(--mud-palette-text-primary)` (confirmado en el CSS fuente de MudBlazor) — como es una variable CSS heredable, redefinirla dentro de `.nexo-tema-oscuro` basta para que los charts (incluido el SVG de variación hecho a mano) se vean bien, sin tocar cada gráfico individualmente.
- **Vista Lista/Tarjetas — control único y global**: existió una primera versión con un toggle por pantalla (`Components/Shared/VistaToggle.razor`, clave `"Vista:{pagina}"`) que el usuario pidió simplificar: ahora es **un solo control en Settings** (`/settings`) que aplica a todas las pantallas. `VistaToggle.razor` se eliminó. `PreferenciasState.VistaListado` (antes `ObtenerVista(pagina)`) expone el valor único (clave `"VistaListado"`, `"lista"`/`"tarjetas"`), y `EstablecerVistaListadoAsync(vista)` (antes `EstablecerVistaAsync(pagina, vista)`) lo guarda. Clases `.nexo-card-grid`/`.nexo-item-card` en `app.css` sin cambios. En `Settings.razor` el botón activo usa `Color.Primary` + ícono de check (antes solo `Variant.Filled` vs `Outlined`, el usuario no distinguía cuál estaba activo) y se dispara un `Snackbar.Add("Nuevo formato de listado aplicado.")` al cambiar.
- **Aplicado en TODAS las pantallas de listado** (13 en total): Artículos, Clientes, Proveedores, Centros de Costo, Bodegas, Centros de Trabajo, Usuarios, Consulta de Stock, Kardex, Órdenes de Producción, Órdenes de Compra, Traspasos, Recetas. Cada una inyecta `PreferenciasState Preferencias` y usa `@if (Preferencias.VistaListado == "tarjetas") { ...grid... } else { ...MudTable... }` (sin ningún botón propio — el control vive solo en Settings). Si se agrega una pantalla de listado nueva en el futuro, replicar este mismo patrón `@if`/`.nexo-card-grid`/`.nexo-item-card` directamente (no hace falta preguntar el patrón, ya está establecido en las 13 existentes).

### 20.21 — Fecha de recepción por línea de Orden de Compra (`Compras.OrdenesCompraDetalle.FechaUltimaRecepcion`)

Una OC puede recibirse en partes en días distintos (línea A un día, línea B otro día, o incluso la misma línea en varias entregas parciales). `Compras.OrdenesCompra.FechaRecepcion` (cabecera) **ya** se seteaba correctamente solo cuando *todas* las líneas quedaban completas (`sp_RecibirOrdenCompra`, rama `IF NOT EXISTS (... CantidadRecibida < CantidadSolicitada)`) — eso no se tocó, ya cumplía "fecha de recibido final = hasta que se recibió todo en total". Lo que faltaba era la fecha por línea individual: se agregó `Compras.OrdenesCompraDetalle.FechaUltimaRecepcion` (ver `docs/database.md` 9.12), seteada en cada llamada a `sp_RecibirOrdenCompra` (si una línea recibe en dos entregas parciales, queda la fecha de la **última**, no un historial completo — suficiente para lo que se pidió: saber cuándo se recibió cada línea). Se agregaron columnas "Recibido" (cabecera, `ListaOrdenesCompra.razor`) y "Fecha Recibido" (detalle por línea) a la UI.

**Backfill de datos históricos**: las líneas recibidas ANTES de agregar la columna quedaron con `FechaUltimaRecepcion = NULL` (mostraban "-" en la UI, no era un bug de código). Se corrió un `UPDATE` one-off (no un script versionado, ya se ejecutó) que las completa con `COALESCE(oc.FechaRecepcion, oc.FechaEmision)` de su cabecera — es una fecha aproximada para el histórico, no la fecha real de cada recepción pasada (esa información nunca se guardó). Si se necesita volver a hacer un backfill así en otra columna nueva, buscar una fecha "razonable" relacionada en vez de dejar NULL, para que la UI no quede con "-" en todo lo histórico.

### 20.22 — `Produccion.vw_ProduccionPlanVsReal` sumaba órdenes Canceladas en "Planificado"

El usuario reportó que el Dashboard (tabla Plan vs Real y el gráfico de variación 20.16) mostraba números que no coincidían con sus órdenes reales. Causa: la vista agrupaba `SUM(CantidadProgramada)` por `FechaPlanificada` sin filtrar por `EstadoOP` — una orden **Cancelada** seguía sumando su cantidad programada en "Planificado" para siempre (0 en "Real", porque nunca se produjo), arrastrando el cumplimiento de ese día hacia abajo artificialmente y sin forma de corregirse. Fix: agregar `JOIN Produccion.EstadosOP e ... WHERE e.Nombre <> 'Cancelada'` (ver `docs/database.md` 9.13). Esto también corrigió el gráfico de variación (20.16), que consume la misma vista — no hubo que tocar ese código, el bug era 100% de datos, no de presentación.

**Lección para el futuro**: cualquier vista/consulta que agregue `Produccion.OrdenesProduccion` por cantidad programada/planificada debe decidir explícitamente si incluye o excluye órdenes Canceladas (y probablemente también verificar el resto de vistas de `Produccion.vw_*` que tocan `OrdenesProduccion` por si tienen el mismo gap — no se auditaron todas en esta pasada, solo `vw_ProduccionPlanVsReal`).

### 20.23 — Baja de Inventario: Bodega filtrada por stock real del Artículo

`RegistrarBaja.razor` antes listaba TODAS las bodegas sin importar si el artículo elegido tenía stock ahí — fácil de seleccionar por error una bodega vacía. Ahora carga `api/inventario/stock` completo una sola vez al iniciar (sin filtro, dataset chico) y calcula `_bodegasConStock` client-side (`_stock.Any(s => s.ArticuloID == articuloId && s.BodegaID == bodegaId && s.CantidadActual > 0)`) — sin llamada nueva a la API por cada cambio de artículo. El `MudSelect` de Bodega se deshabilita hasta elegir un artículo, y si la bodega ya elegida deja de tener stock del nuevo artículo seleccionado, se resetea a 0.

### 20.24 — `.mud-picker { overflow: hidden; min-width: 340px }` sospechoso de recortar el calendario (fecha futura "inseleccionable")

El usuario reportó no poder seleccionar fechas de hoy en adelante en el `MudDateRangePicker` del Dashboard. Investigación: no hay `MaxDate`/`MinDate` en ningún `.razor` del proyecto, el backend no limita fechas futuras, y el código fuente de MudBlazor 7.15 confirma que `MaxDate` es `null` por defecto y no restringe navegación de mes por sí solo. Hipótesis más probable: `.mud-picker-content` (clase propia de MudBlazor) ya trae `overflow: hidden; max-width: 100%` de fábrica — el `overflow: hidden !important` + `min-width: 340px !important` que se le había agregado a `.mud-picker` en `app.css` (sección 20.17/20.19) pudo estar forzando contenido más ancho que el dialog disponible, y como MudBlazor recorta sin mostrar scrollbar, el resultado visual es que la navegación al mes siguiente (o las columnas de días más "tarde") desaparece sin ningún indicio de que algo se está cortando. Se quitó `overflow: hidden` y `min-width: 340px` de `.mud-picker`, y se redujo el padding lateral de `.mud-picker-calendar-container` (1rem → 0.5rem) por la misma razón. **Sin confirmar en vivo** (el usuario prefiere verificar solo con `dotnet build`, ver [[feedback_verificacion_ui_solo_compilar]]) — si sigue sin poder seleccionar fechas futuras después de este cambio, es un síntoma distinto y hay que replantear el diagnóstico (probablemente sí requiera abrir el navegador para inspeccionar el DOM en vivo).

### 20.25 — `NavMenu.razor`: grupos y links sin `AuthorizeView` (menú vs. permisos de página desincronizados)

Bug real reportado por el usuario con Bodeguero: el grupo "Producción" se mostraba en el sidebar SIN ningún item debajo (Bodeguero no tiene acceso a ninguna subpágina de Producción), y "Artículos" bajo "Catálogo" se mostraba pero al entrar la página quedaba en blanco (Bodeguero no tiene acceso, pero el link en el menú no estaba protegido). Causa: varios `MudNavGroup` (Producción, Compras, Catálogo) y el link `/catalogo/articulos` no estaban envueltos en `<AuthorizeView Roles="...">` — solo los `MudNavLink` internos lo estaban, así que el grupo/link "padre" se renderizaba siempre, vacío o roto, sin importar el rol.

**Regla fija ahora**: todo `MudNavGroup` debe envolverse en `<AuthorizeView Roles="{unión de roles de TODOS sus hijos}">` (para que el grupo entero desaparezca si el rol no tiene acceso a ningún hijo), y cada `MudNavLink` individual debe tener su propio `<AuthorizeView Roles="...">` con **exactamente** los mismos roles que el `@attribute [Authorize(Roles=...)]` de la página a la que apunta (nunca dejar un link sin `AuthorizeView` a menos que la página de destino sea `[Authorize]` sin roles, es decir "todos los autenticados" — ese es el único caso donde el link no necesita restricción, ej. `/inventario/stock`). Roles reales en `Seguridad.Roles`: `Administrador`, `SupervisorPlanta`, `Operario`, `Bodeguero`. Cuando `AuthorizeView` está anidado dentro de otro `AuthorizeView` con bloques `<Authorized>`, hay que nombrar el `Context` del externo (ej. `Context="grupoProduccion"`) porque Blazor no permite que dos `<Authorized>` anidados compartan el nombre de parámetro implícito `context` (error `RZ9999`).

### 20.26 — Sistema de ayuda: banner descriptivo por página + toggle global en Settings

A pedido del usuario, cada página/subpágina de listado (14 en total: las mismas de la sección 20.20 + Dashboard) tiene ahora un banner de ayuda (`Components/Shared/InfoAyuda.razor`) debajo del título, con 2-3 frases explicando qué es esa pantalla y cómo se usa. Se oculta por completo si el usuario apaga "Mostrar información en cada página" en Settings (`PreferenciasState.MostrarAyuda`, clave `"MostrarAyuda"`, **default `"true"`** — a diferencia de `TemaOscuro`/`VistaListado` que son opt-in, esto viene activado de fábrica porque el objetivo es ayudar a usuarios nuevos desde el primer login).

**Iteración importante**: la primera versión de `InfoAyuda.razor` era un pequeño ícono ⓘ con `MudTooltip` (hover), pero el usuario lo rechazó — quería el estilo que ya existía como banner estático en `AjustarInventario.razor`/`CentrosTrabajo.razor` (`MudAlert Severity="Info"`, fondo celeste, texto descriptivo siempre visible, no un tooltip al pasar el mouse) y que ESE banner respondiera al toggle. Se rediseñó `InfoAyuda.razor` para renderizar un `MudAlert` de ancho completo en vez del ícono+tooltip, y se **consolidaron** los dos banners estáticos preexistentes (`AjustarInventario.razor`, `CentrosTrabajo.razor`) para que usen este mismo componente en vez de un `MudAlert` hardcodeado — así también quedan controlados por el toggle. Uso correcto: `<InfoAyuda Texto="..." />` como bloque de ancho completo debajo del título (`MudText Typo="Typo.h5"`), **no** en línea dentro del `<h1>`/título.

**Nueva página `/settings/ayuda`** (ícono ⓘ en Settings): tiene dos bloques —
1. "Flujo de trabajo": **placeholder vacío a propósito** (`nexo-empty-state` con el texto "Próximamente"). El usuario va a insertar su propio diagrama/imagen del proceso más adelante — no se construyó un diagrama BPMN ni se agregó ninguna librería de diagramado (decisión explícita del usuario, para no sumar dependencias).
2. "¿Necesitas ayuda?": botón de correo (`mailto:visionscomercial@gmail.com`) y botón de WhatsApp (`https://api.whatsapp.com/send/?phone=573015324933&...`) — **datos reales de la empresa**, ya no son de relleno.

### 20.27 — Calendario y búsqueda: confirmados funcionando en vivo (no eran bugs de código)

Tras dos rondas de fixes a ciegas (20.24) que el usuario reportó como insuficientes, el usuario autorizó por única vez abrir el navegador para depurar en vivo. Resultado: **ambos sistemas funcionan correctamente** contra el código actual — el `MudDateRangePicker` permite avanzar/retroceder de mes libremente (probado hasta septiembre 2026 y de vuelta), seleccionar rango completo, y el buscador global devuelve sugerencias y navega correctamente al hacer click. La sospecha es que el usuario venía probando sobre una build vieja (ver [[reference_nexo_erp_project]] sobre el problema recurrente de reiniciar en Visual Studio) al momento de reportar el bug. Se aprovechó la sesión en vivo para detectar el gap real de búsqueda (ver 20.18: Bodeguero casi no tenía nada que buscar) y agregar Stock/Traspasos.

**Gotcha del entorno de preview (`.claude/launch.json`)**: al lanzar `NexoApi` vía `preview_start`, el log mostró `Now listening on: http://localhost:5000` (por el `--urls` forzado en `launch.json`), pero `NexoWeb/appsettings.json` tiene `INexoApi:BaseUrl = https://localhost:7144/` — un mismatch que causó `HttpRequestException: conexión rechazada` en NexoWeb cuando el NexoApi de preview se reinició a mitad de la sesión. Si se vuelve a necesitar `preview_start` para NexoApi+NexoWeb juntos (con permiso explícito del usuario), verificar que ambos puertos coincidan o que `NexoWeb:appsettings.Development.json` sobreescriba `BaseUrl` a `http://localhost:5000`.

**Regla de proceso violada y corregida**: en esa misma sesión, el permiso de "abrir el navegador para inspeccionar" se malinterpretó como permiso para además lanzar `dotnet run` de NexoApi y NexoWeb (`preview_start` con `name`). El usuario corrigió: eso NUNCA estaba autorizado — ver [[feedback_verificacion_ui_solo_compilar]] (actualizada con esta distinción explícita). Los servidores se detuvieron apenas se señaló el error.

### 20.28 — Mi perfil: cambiar nombre y foto desde el menú del avatar (Top Bar)

El avatar+nombre+rol del Top Bar (antes un `<div>` decorativo, sin `onclick`) ahora es `Components/Shared/PerfilMenu.razor` — un `MudMenu` con mini-formulario: **Nombres**/**Apellidos** editables (el usuario puede cambiar su propio nombre) y una foto de perfil opcional. **El Rol se muestra pero está deshabilitado a propósito** — cambiar de rol sigue siendo exclusivo de Administrador vía `/admin/usuarios` (`ActualizarUsuarioAsync`), esto es un feature completamente separado y solo toca `Nombres`/`Apellidos`/`FotoPerfil` sobre el propio `UsuarioID`.

- **Backend**: `AuthController` gana 3 endpoints `[Authorize]` sin rol específico (cualquiera sobre sí mismo, `UsuarioActualId` del JWT): `PUT /api/auth/perfil` (nombre), `PUT /api/auth/perfil/foto` (sube, límite 1 MB validado server-side), `DELETE /api/auth/perfil/foto` (quita, vuelve a mostrar iniciales). La foto se guarda en `Seguridad.Usuarios.FotoPerfil` (`VARBINARY(MAX)`) — ver `docs/database.md` 9.14. **"Reemplazar la foto" es solo un `UPDATE`** — no hay archivo en disco que borrar, la columna simplemente se sobrescribe (esto era literalmente el requisito del usuario: "que la anterior se borre de BD y se reemplace por la nueva", y un `UPDATE` de una sola columna ya lo garantiza sin lógica extra).
- **Cómo llega la foto al navegador sin un endpoint de imagen aparte**: en vez de un endpoint `GET /foto/{id}` servido como binario (que no puede llevar el header `Authorization` si se referencia desde un `<img src="...">` plano), la foto viaja como **Base64 dentro del JSON** — ya en el `LoginResponse` (`FotoPerfilBase64`/`FotoPerfilContentType`) y se cachea en `AuthStateService` (persistido en `ProtectedSessionStorage`, sobrevive F5). `AuthStateService.FotoPerfilDataUri` arma el `data:image/...;base64,...` listo para `<img src="@...">`. Simple para el tamaño de estas imágenes (tope 1 MB), no vale la pena la complejidad de un endpoint de streaming binario autenticado para un avatar.
- **Gotcha de DI evitado**: `AuthStateService` **NO** inyecta `INexoApiClient` — `NexoApiClient` ya depende de `AuthStateService` (para el header `Authorization`), así que hacerlo al revés crearía un ciclo de DI. Los métodos `ActualizarNombreAsync`/`ActualizarFotoAsync`/`EliminarFotoAsync` de `AuthStateService` **solo actualizan estado local** (memoria + `ProtectedSessionStorage`) y disparan `OnChange`; el componente de UI (`PerfilMenu.razor`, que sí puede inyectar `INexoApiClient`) hace la llamada HTTP primero y **después** llama al setter local si salió bien. Replicar este orden (API → luego estado local) en cualquier feature similar.
- **Subir archivo sin JS interop**: `PerfilMenu.razor` usa `<InputFile>` (Blazor nativo) oculto con `display:none` + un `<label for="mismo-id">` estilizado como botón — el navegador abre el selector de archivos al hacer click en el label sin necesitar ningún JS. El archivo se lee con `OpenReadStream(maxAllowedSize: 1_000_000)`, se copia a un `MemoryStream` y se convierte a Base64 antes de mandarlo.

### 20.29 — Logo/nombre de la empresa (Admin) e imagen opcional por artículo — mismo patrón, imágenes servidas por URL en vez de Base64

Dos features nuevas que reutilizan la infraestructura de "foto de perfil" (20.28) pero con una diferencia clave: **estas imágenes se sirven por URL (`<img src="api/.../imagen">`), no embebidas en Base64 dentro del JSON**, porque a diferencia de una sola foto de perfil por sesión, aquí hay *muchos* artículos listados a la vez — meter el Base64 de cada uno en cada respuesta de lista (`ArticuloItem`, `StockConsolidadoItem`) sería carísimo en payload. En su lugar, los DTOs de lista solo llevan `bool TieneImagen`, y el `<img>` apunta a un endpoint dedicado por ID.

- **`GET /api/catalogo/articulos/{id}/imagen` es `[AllowAnonymous]` a propósito**: un `<img src="...">` plano del navegador no puede mandar el header `Authorization`, así que este endpoint puntual (sirve solo bytes de una foto de producto por ID numérico, nada sensible) queda sin `[Authorize]`. El resto de la API de Artículos sigue exigiendo login normalmente. Mismo trade-off documentado aquí para si se necesita replicar este patrón en otro lado.
- **Mi Negocio (Settings, solo Administrador)**: `Organizacion.ConfiguracionEmpresa` (fila única, ver `docs/database.md` 9.16) vía `ConfiguracionEmpresaState` (Scoped, patrón igual a `PreferenciasState`/`AuthStateService` — cargar una vez, exponer `OnCambio`). A diferencia de `AuthStateService`, esta clase **sí puede inyectar `INexoApiClient`** directamente sin riesgo de ciclo de DI (no es una dependencia de `NexoApiClient`). El logo del sidebar (`MainLayout.razor`) usa `LogoDataUri` (si hay logo propio) o `/images/LogoV.png` (default) — aquí sí se usa Base64/data-URI porque solo hay UN logo por circuito, no una lista.
- **"Mismas dimensiones" al cambiar el logo**: el `<img>` del sidebar mantiene `height: 34px` fijo (CSS existente, sin tocar) sin importar el tamaño real de la imagen subida — así cualquier logo que suba el Administrador se ajusta visualmente al mismo espacio, aunque el archivo original tenga otras proporciones.
- **Imagen de Artículo — flujo de creación con ID nuevo**: `ArticuloDialog.razor` no puede subir la imagen directamente (un artículo nuevo aún no tiene `ArticuloID`) — en vez de eso, cierra el diálogo con `ArticuloDialogResultado(Datos, ImagenBase64, ImagenContentType)` que empaqueta la solicitud de crear/editar de siempre MÁS la imagen opcional. `Articulos.razor` primero hace el `POST`/`PUT` normal (el `POST` ahora devuelve `{ articuloId }` en el body, antes no devolvía nada útil) y, si el usuario eligió una imagen, hace un segundo `PUT .../imagen` con el ID ya conocido. Se muestra en `Articulos.razor` y `ConsultaStock.razor`, tabla y tarjetas.

### 20.30 — Dapper NO mapea una fila directo a `ValueTuple` — usar un `record` privado siempre

`connection.QuerySingleOrDefaultAsync<(byte[] Datos, string ContentType)?>(...)` (o cualquier `(T1,T2)`/`(T1,T2)?`) **compila bien pero explota en tiempo de ejecución** apenas la fila SÍ existe — Dapper no tiene soporte nativo para materializar un `SELECT` de una fila directo a `System.ValueTuple`. Se encontraron **2 casos reales** con este patrón (agosto 2026):
- `CatalogoService.ObtenerImagenArticuloAsync` — el endpoint `GET .../imagen` fallaba con 500 en TODO artículo que SÍ tenía imagen guardada (el caso "sin imagen" nunca llegaba a mapear una fila, por eso pasaba desapercibido en pruebas rápidas). Efecto visible: "al crear un producto con imagen, la imagen no se muestra bien" en `Articulos.razor`/`ConsultaStock.razor`/`ArticuloDialog.razor`.
- `RecetasService.CrearNuevaVersionAsync` — `QuerySingleOrDefaultAsync<(int ProductoTerminadoID, int VersionActual)>` fallaba en TODA llamada al crear una nueva versión de receta.

**Regla**: nunca usar `ValueTuple` como tipo genérico de un `Query*Async<T>` de Dapper para una sola fila con varias columnas — declarar un `private record NombreDescriptivo(TipoA CampoA, TipoB CampoB)` (con los mismos nombres que el `SELECT`, o alias `AS` si no calzan) y usar eso como `T`. Si el resultado puede no existir, comparar contra `null` (el record), no contra un tuple `?`.

### 20.31 — Gráfico "Variación de Producción vs Plan" (Dashboard): el pico no se etiquetaba si el valor era exactamente 0%

`ObtenerBarrasVariacion()` en `Dashboard.razor` marca como "pico" (con etiqueta de %) solo el día con mayor variación positiva y el de mayor variación negativa — pero el filtro tenía `&& punto.Porcentaje != 0`, así que si el "mejor día" (`indiceMax`) resultaba tener exactamente `0%` de variación (cumplimiento exacto del plan, ni más ni menos), **no se le pintaba ninguna etiqueta y ningún otro día la reemplazaba** — visualmente parecía que las barras verdes nunca mostraban su porcentaje, mientras que la roja (variación negativa, casi nunca exactamente 0) sí. Corregido quitando ese filtro — un día en 0% es información válida y debe etiquetarse igual si es el pico.

## 21. Exportación del Dashboard — Excel y PDF (agosto 2026)

Dos botones en el header del Dashboard ("Excel" / "PDF") descargan un reporte con los mismos datos que ya muestra la pantalla (Plan vs Real, Variación, Distribución por Centro de Costo, Cumplimiento, Pérdidas por Motivo) más el catálogo de Artículos y el Stock Consolidado actual — **sin imágenes de artículo a propósito** (son reportes de datos, no catálogos visuales; meter imágenes solo pesaría el archivo sin aportar nada).

- **Backend**: `NexoApi/Features/Dashboard/DashboardExportService.cs` (`IDashboardExportService`), inyecta `IDashboardService` + `ICatalogoService` + `IInventarioService` para reutilizar exactamente las mismas consultas que ya usa el Dashboard (no hay SQL duplicado). Nuevos endpoints `GET api/dashboard/exportar/excel` y `GET api/dashboard/exportar/pdf` (mismos roles que el resto del Dashboard, JWT normal — no son anónimos).
- **Excel**: librería `ClosedXML` (gratuita). Genera 7 hojas (Resumen/KPIs, Plan vs Real, Distribución CC, Cumplimiento CC, Pérdidas, Stock Actual, Artículos), con estilo (encabezados morados `#5A3BFF`, zebra striping, congelar encabezado en hojas largas, formato de moneda/porcentaje, color condicional verde/rojo según cumple o no el plan).
- **PDF**: librería `QuestPDF` — requiere `QuestPDF.Settings.License = LicenseType.Community` seteado una vez en `Program.cs` antes de generar cualquier documento (si no, revienta al llamar `GeneratePdf()`). **Licencia Community es gratis solo para empresas con ingresos anuales < 1M USD** (ver questpdf.com/license) — si el negocio del cliente crece más de eso, hay que comprar la licencia comercial de QuestPDF; quedó anotado aquí para no olvidarlo. El PDF recrea el gráfico de barras de Variación (verde/rojo) con primitivas de QuestPDF (rectángulos con alto proporcional), no con una librería de gráficos — evita depender de renderizar el SVG del navegador en el servidor.
- **Frontend**: como los endpoints exigen JWT, un `<a href>` plano no puede descargar el archivo (no manda el header `Authorization`). Se resolvió con el patrón estándar de Blazor Server: `ApiClient.GetBytesAsync(ruta)` (nuevo método en `INexoApiClient`, trae los bytes ya autenticados) → `DotNetStreamReference` → `IJSRuntime.InvokeVoidAsync("nexoDescargarArchivo", ...)` → `wwwroot/js/descargas.js` arma un `Blob` y dispara la descarga con un `<a>` temporal. El script se referencia en `Components/App.razor`.
- **Verificación**: no se puede verificar visualmente el PDF por terminal (no hay `pdftoppm` disponible), así que se armó un arnés de consola desechable (`ProjectReference` a `NexoApi.csproj`, conexión directa a `NEXO_ERP`) para generar ambos archivos contra datos reales y confirmar que no truenan en runtime — QuestPDF en particular es propenso a excepciones de layout (`Available space is too small...`) que un `dotnet build` exitoso NO detecta. Si se toca `DashboardExportService.cs` de nuevo, repetir esa verificación antes de dar por buena la compilación sola.
