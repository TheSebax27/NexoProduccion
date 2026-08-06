# NEXO ERP — Guía de Contexto para Claude

Este archivo es la fuente principal de contexto del proyecto. Léelo antes de cualquier tarea.

**Otros documentos**: `docs/architecture.md` (mapa técnico de los 19 módulos y sus endpoints), `docs/database.md` (esquema completo de BD tabla por tabla), `docs/AUDITORIA_2026.md` (evaluación crítica: qué falta, qué mejorar, prioridades — leer antes de proponer un módulo nuevo o un cambio grande, para no repetir un hallazgo ya identificado). `docs/session-summary.md` es histórico/superado, no consultar como fuente de verdad.

## Índice — dónde buscar cada cosa (para no releer el archivo completo)

**Fundamentos** (rara vez cambian, leer una sola vez): [1](#1-descripción-general) Descripción · [2](#2-arquitectura-general) Arquitectura · [3](#3-stack-tecnológico) Stack · [4](#4-estructura-de-carpetas) Carpetas · [5](#5-convenciones-de-nombres) Nombres · [6](#6-patrones-de-diseño) Patrones de diseño · [7](#7-flujo-de-autenticación) Auth · [8](#8-organización-de-la-api) API · [9](#9-organización-del-frontend) Frontend · [10](#10-paleta-de-colores--tema-morado--gris-moderno-rediseño-agosto-2026) Colores/Tema · [11](#11-convenciones-sql) SQL · [12](#12-convenciones-blazor) Blazor · [13](#13-reglas-que-nunca-deben-romperse) **Reglas que nunca deben romperse** · [17](#17-cómo-agregar-un-nuevo-módulo) Cómo agregar un módulo nuevo

**Operación** (cómo correr/compilar/publicar): [14](#14-cómo-ejecutar-el-proyecto) Ejecutar · [15](#15-cómo-compilar) Compilar · [16](#16-cómo-publicar) Publicar · [18](#18-nexosyncagent--integración-con-visions) NexoSyncAgent/Visions · [22](#22-limpieza-completa-tras-tocar-nexoapinexoweb--cache-de-imágenes--hot-reload-vs-reinicio-real-agosto-2026) Limpieza/rebuild/procesos huérfanos

**Antes de tocar código — bugs ya resueltos, no los repitas**: [20](#20-lecciones-aprendidas--bugs-recurrentes-leer-antes-de-tocar-código-similar) Lecciones aprendidas (⚠️ **20.30 Dapper+ValueTuple** es el más repetido — verificar siempre antes de un `Query*Async<T>` nuevo) · [29](#29-bugs-reales-reportados-por-el-usuario-y-corregidos-agosto-2026) Bugs reales de UX (ShowAsync no espera cierre de diálogo, topbar tapando contenido, decimales)

**Módulos por fase de construcción** (qué existe, qué se decidió y por qué): [23](#23-expansión-a-erpcrm-completo--fases-1-y-2-agosto-2026) RRHH+CRM v1, Planificación · [24](#24-bi--logística-tms--gestión-de-proyectos-agosto-2026) BI, Logística, Proyectos v1 · [25](#25-crm-v2-nivel-profesional-agosto-2026) CRM v2 · [26](#26-rrhh-v2--planificación-v2-nivel-profesional-agosto-2026) RRHH v2 + Planificación v2 · [27](#27-sidebar-con-submenús-flotantes-flyout--favoritos-agosto-2026) Sidebar/Favoritos (⚠️ ver 27.2, el flyout se REVIRTIÓ a acordeón) · [28](#28-proyectos-v2-nivel-profesional-el-último-módulo-pendiente-agosto-2026) Proyectos v2 · [30](#30-facturación-agosto-2026--módulo-nuevo-tipo-guardado) Facturación

**Pendientes / próximos pasos**: [19](#19-pendientes-conocidos-phase-3) Pendientes conocidos · `docs/AUDITORIA_2026.md` sección "Roadmap sugerido" (más completo y priorizado que la sección 19 de este archivo)

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
| Fondo general | Gris muy claro | `#EDEFF5` (agosto 2026, antes `#F4F5F9` — se oscureció un poco junto con Superficie, ver abajo) |
| Superficie / tarjetas | Blanco roto (NO puro) | `#FAFBFD` (agosto 2026, antes `#FFFFFF` — el usuario lo vio "demasiado luminoso"; se ajustaron `NexoTheme.cs` Background/Surface/AppbarBackground Y `app.css` `--n-bg`/`--n-card` a la vez, deben moverse juntos) |
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

**Segundo ajuste (mismo día)**: el gráfico compartía el rango de fechas del selector de "Producción Planificada vs Real" (arriba, default últimos 14 días) — un día con variación grande "desaparecía" del gráfico apenas quedaba fuera de esa ventana, aunque el dato seguía intacto en la BD. A pedido explícito del usuario, "Variación" ahora es **independiente**: `OnInitializedAsync` hace un fetch aparte a `api/dashboard/plan-vs-real?desde=2000-01-01&hasta=hoy` (todo el histórico, sin límite) solo para este gráfico; el selector de fecha de arriba sigue afectando únicamente a "Producción Planificada vs Real". El SVG ahora tiene ancho dinámico (`AnchoSvgVariacion = Math.Max(1000, dias * 32)`) dentro de un contenedor `overflow-x: auto`, para que las barras no se aplasten a medida que crece el histórico.

## 21. Exportación del Dashboard — Excel y PDF (agosto 2026)

Dos botones en el header del Dashboard ("Excel" / "PDF") descargan un reporte con los mismos datos que ya muestra la pantalla (Plan vs Real, Variación, Distribución por Centro de Costo, Cumplimiento, Pérdidas por Motivo) más el catálogo de Artículos y el Stock Consolidado actual — **sin imágenes de artículo a propósito** (son reportes de datos, no catálogos visuales; meter imágenes solo pesaría el archivo sin aportar nada).

- **Backend**: `NexoApi/Features/Dashboard/DashboardExportService.cs` (`IDashboardExportService`), inyecta `IDashboardService` + `ICatalogoService` + `IInventarioService` para reutilizar exactamente las mismas consultas que ya usa el Dashboard (no hay SQL duplicado). Nuevos endpoints `GET api/dashboard/exportar/excel` y `GET api/dashboard/exportar/pdf` (mismos roles que el resto del Dashboard, JWT normal — no son anónimos).
- **Excel**: librería `ClosedXML` (gratuita). Genera 7 hojas (Resumen/KPIs, Plan vs Real, Distribución CC, Cumplimiento CC, Pérdidas, Stock Actual, Artículos), con estilo (encabezados morados `#5A3BFF`, zebra striping, congelar encabezado en hojas largas, formato de moneda/porcentaje, color condicional verde/rojo según cumple o no el plan).
- **PDF**: librería `QuestPDF` — requiere `QuestPDF.Settings.License = LicenseType.Community` seteado una vez en `Program.cs` antes de generar cualquier documento (si no, revienta al llamar `GeneratePdf()`). **Licencia Community es gratis solo para empresas con ingresos anuales < 1M USD** (ver questpdf.com/license) — si el negocio del cliente crece más de eso, hay que comprar la licencia comercial de QuestPDF; quedó anotado aquí para no olvidarlo. El PDF recrea el gráfico de barras de Variación (verde/rojo) con primitivas de QuestPDF (rectángulos con alto proporcional), no con una librería de gráficos — evita depender de renderizar el SVG del navegador en el servidor.
- **Frontend**: como los endpoints exigen JWT, un `<a href>` plano no puede descargar el archivo (no manda el header `Authorization`). Se resolvió con el patrón estándar de Blazor Server: `ApiClient.GetBytesAsync(ruta)` (nuevo método en `INexoApiClient`, trae los bytes ya autenticados) → `DotNetStreamReference` → `IJSRuntime.InvokeVoidAsync("nexoDescargarArchivo", ...)` → `wwwroot/js/descargas.js` arma un `Blob` y dispara la descarga con un `<a>` temporal. El script se referencia en `Components/App.razor`.
- **Verificación**: no se puede verificar visualmente el PDF por terminal (no hay `pdftoppm` disponible), así que se armó un arnés de consola desechable (`ProjectReference` a `NexoApi.csproj`, conexión directa a `NEXO_ERP`) para generar ambos archivos contra datos reales y confirmar que no truenan en runtime — QuestPDF en particular es propenso a excepciones de layout (`Available space is too small...`) que un `dotnet build` exitoso NO detecta. Si se toca `DashboardExportService.cs` de nuevo, repetir esa verificación antes de dar por buena la compilación sola.

## 22. Limpieza completa tras tocar NexoApi/NexoWeb + cache de imágenes + Hot Reload vs reinicio real (agosto 2026)

**Pedido explícito del usuario**: después de modificar código de `NexoApi` y/o `NexoWeb`, correr esta limpieza completa (no solo `dotnet build`) antes de dar la tarea por terminada:
```powershell
cd C:\Produccion\NexoApi  # o NexoWeb
dotnet clean; Get-ChildItem -Path . -Include bin,obj -Recurse -Directory | Remove-Item -Recurse -Force; dotnet restore; dotnet build
```
Si el `Remove-Item` falla por archivos bloqueados, es porque Visual Studio SÍ tiene el proceso corriendo en ese momento — avisar al usuario, no forzar.

**"El sistema no toma los cambios" — causa real confirmada: procesos huérfanos de `NexoApi.exe`/`NexoWeb.exe`** que sobreviven al cerrar Visual Studio y se quedan ocupando el puerto (`7144`/`5272` en el caso real que se dio), sirviendo código viejo sin importar cuántas veces se reinicie VS, se recompile, o se pruebe en incógnito. Se descartó primero Hot Reload (sospecha inicial razonable pero incorrecta en este caso) y caché de navegador antes de encontrar el proceso zombie con `Get-Process`/`Get-NetTCPConnection`. Diagnóstico y arreglo:
```powershell
Get-Process -Name "NexoApi","NexoWeb" -ErrorAction SilentlyContinue | Select-Object Id, ProcessName, Path, StartTime
Get-NetTCPConnection -State Listen | Where-Object { $_.LocalPort -in 5000,5001,5272,7000,7097,7144 } | ForEach-Object {
    $p = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
    [PSCustomObject]@{ Puerto = $_.LocalPort; PID = $_.OwningProcess; Proceso = $p.ProcessName; Ruta = $p.Path }
}
Stop-Process -Id <PID> -Force  # si aparece algo de Nexo* corriendo cuando el usuario cree que todo esta cerrado
```
**Si el usuario reporta "esto no aparece" después de un cambio de UI y ya descartó Hot Reload/caché (Detener+F5 real, navegador en incógnito), este chequeo de procesos huérfanos es el siguiente paso — no seguir buscando en el código sin antes descartar esto.** Verificar el fix directo contra la lógica/BD (ver patrón de arnés de consola en sección 21) para confirmar que el código en sí está bien antes de enfocarse en el entorno.

**Cache de imágenes de artículo en el navegador**: `<img src="api/catalogo/articulos/{id}/imagen">` no tenía ningún parámetro que cambiara — si el navegador llegaba a cachear una respuesta rota (ej. mientras existía el bug de Dapper+ValueTuple de la sección 20.30) o el usuario subía una imagen nueva, el `<img>` podía seguir mostrando lo viejo indefinidamente porque la URL nunca cambiaba. Se agregó un query param `?v={_cacheBust}` (un `long` de `DateTime.UtcNow.Ticks`) en las 5 URLs de imagen de artículo (`Articulos.razor` x2, `ConsultaStock.razor` x2, `ArticuloDialog.razor` x1) — en `Articulos.razor` (que sí sube imágenes) se recalcula justo después de un upload exitoso para forzar el refetch inmediato; en las pantallas de solo lectura (`ConsultaStock.razor`, `ArticuloDialog.razor`) es un valor fijo calculado una vez al cargar el componente, solo para invalidar cache de sesiones anteriores.

**Paleta modo claro (agosto 2026)**: `Surface`/`Background`/`AppbarBackground` en `NexoTheme.cs` y `--n-bg`/`--n-card` en `wwwroot/app.css` se oscurecieron un poco (`#FFFFFF` → `#FAFBFD` para tarjetas, `#F4F5F9` → `#EDEFF5` para el fondo) — pedido explícito del usuario ("el blanco es muy luminoso"). **Estos dos archivos deben moverse juntos**: `NexoTheme.cs` controla los componentes de MudBlazor (`MudPaper`, `MudCard`, etc.), `app.css` controla las clases custom `.nexo-*` (KPIs, tarjetas de item, etc.) — si se ajusta uno sin el otro quedan descoordinados.

## 23. Expansión a ERP+CRM completo — Fases 1 y 2 (agosto 2026)

El usuario pidió expandir NEXO más allá de Producción: **CRM** (contactos + bitácora de interacciones, sin pipeline de ventas por ahora), **RRHH** (directorio básico de personal, sin nómina/contabilidad — eso lo maneja en otro sistema aparte), y **Planificación** (demanda/capacidad de producción a futuro + metas comerciales, ambas). Se acordó ir módulo por módulo. **Fase 1 (RRHH) y Fase 2 (CRM) ya están construidas**; Planificación queda pendiente como próxima fase.

**Decisión de navegación confirmada con el usuario**: la app ya organiza el menú por módulos con `MudNavGroup` (Producción, Inventario, Compras, Catálogo, Administración) — cada módulo nuevo (Recursos Humanos, CRM, y después Planificación) sigue exactamente ese mismo patrón, no es un cambio de arquitectura. Ver `NavMenu.razor`.

**RRHH (Fase 1) — lo que se construyó**:
- Schema nuevo `Rrhh` con tabla `Rrhh.Empleados` (EmpleadoID, Nombres, Apellidos, Cargo, CentroCostoID NULL FK, FechaIngreso, Telefono, Email, Estado, FechaCreacion, **Foto**/**FotoContentType** VARBINARY(MAX)/nvarchar NULL) — **deliberadamente separada de `Seguridad.Usuarios`**: un empleado no necesariamente tiene login al sistema (ej. operarios de planta sin acceso a NEXO), y un usuario de sistema no necesariamente es empleado formal (ej. un consultor externo con acceso temporal). No confundir ni fusionar estas dos tablas.
- Backend: `NexoApi/Features/Rrhh/` (`RrhhService.cs`, `EmpleadosController.cs`, `Dtos/RrhhDtos.cs`) — mismo patrón CRUD que `CatalogoService`/`CentrosCostoController`. Rutas bajo `api/rrhh/empleados`, `[Authorize(Roles = "Administrador")]` únicamente (datos de personal son sensibles, no se abrió a otros roles).
- Frontend: `NexoWeb/Components/Pages/Rrhh/Empleados.razor` + `EmpleadoDialog.razor`, ruta `/rrhh/empleados`, mismo patrón que `CentrosCosto.razor`/`CentroCostoDialog.razor`. Nuevo grupo "Recursos Humanos" en `NavMenu.razor` (icono `Badge`), Admin-only.
- **Sin nómina, sin cálculo de horas/salario, sin documentos adjuntos, sin control de asistencia** — alcance explícitamente acotado a "saber quién trabaja dónde" por decisión del usuario. Si se pide expandir esto después (documentos, asistencia), son features nuevas, no bugs de esta fase.
- **Foto opcional por empleado (agregada justo después de la Fase 1)** — mismo patrón exacto que la imagen de artículo (`ArticuloDialog`/`Articulos.razor`, ver lección 20.29): `GET api/rrhh/empleados/{id}/foto` `[AllowAnonymous]` (un `<img src>` no manda `Authorization`), flujo de dos pasos crear-articulo-luego-subir-foto (`EmpleadoDialogResultado(Datos, FotoBase64, FotoContentType)`), y `RrhhService.ObtenerFotoEmpleadoAsync` usa el patrón de `record` privado para Dapper (NO `ValueTuple`, ver lección 20.30) desde el primer intento — no repitió el bug.

**CRM (Fase 2) — lo que se construyó**:
- **`Catalogo.Clientes` se movió a `Crm.Clientes`** vía `ALTER SCHEMA Crm TRANSFER Catalogo.Clientes` — esto preserva automáticamente el FK existente desde `Produccion.OrdenesProduccion.ClienteID` sin tocar esa tabla ni su código (confirmado con `sys.foreign_keys` antes y después: mismo FK, mismo nombre). **Si hay que mover una tabla de esquema de nuevo, usar `ALTER SCHEMA ... TRANSFER`, nunca crear tabla nueva + copiar datos a mano** — mucho más seguro cuando hay FKs de otras tablas apuntando ahí.
- `Crm.Clientes` ganó 2 columnas nuevas: `FuenteContacto` (Referido/Redes Sociales/Llamada en Frío/Página Web/Otro) y `TipoCliente` (Empresa/Persona Natural).
- Nueva tabla `Crm.Interacciones` (InteraccionID, ClienteID FK, Tipo, Notas, Fecha, UsuarioID NULL FK) — bitácora de llamadas/correos/reuniones por cliente.
- Backend: `NexoApi/Features/Crm/` (`CrmService.cs`, `CrmController.cs`, `Dtos/CrmDtos.cs`), rutas `api/crm/clientes` y `api/crm/interacciones`, Admin-only. Los métodos de Cliente se sacaron de `ICatalogoService`/`CatalogoService`/`CatalogoDtos.cs` — si algo referencia `ClienteItem` o `Catalogo.Clientes`, está desactualizado.
- `Features/Catalogo/ClientesYCentrosTrabajoController.cs` se quedó solo con Centros de Trabajo y Proveedores (el nombre de la clase no se cambió para no romper referencias, pero ya no incluye Clientes — el comentario en el archivo lo deja claro).
- Frontend: `NexoWeb/Components/Pages/Crm/` (`Clientes.razor`, `ClienteDialog.razor`, `InteraccionesDialog.razor`), ruta `/crm/clientes` (antes `/catalogo/clientes` — los archivos viejos en `Components/Pages/Catalogo/Clientes.razor`/`ClienteDialog.razor` se **eliminaron**, no se dejaron como código muerto). Nuevo grupo "CRM" en `NavMenu.razor` (icono `Handshake`), Admin-only. Botón "Bitácora" por cliente abre `InteraccionesDialog` (lista + registrar interacción nueva).
- `CrearOrden.razor` (Producción, selector de cliente MTO) y `BusquedaService.cs` (buscador global) actualizados a `api/crm/clientes`/`Crm.Clientes` — eran los únicos dos consumidores externos del módulo de Clientes.
- **Sin pipeline de oportunidades ni cotizaciones** — alcance acotado a contactos + bitácora, por decisión del usuario.

**Planificación (Fase 3) — ya construida**:
- Schema nuevo `Planificacion` con `DemandaProyectada` (forecast de producción por Articulo+CentroCosto+mes) y `MetasVenta` (meta comercial por CentroCosto+mes). `Periodo` siempre se guarda como el **primer día del mes** (ej. `2026-08-01`) — el frontend normaliza cualquier fecha elegida a eso antes de mandarla, para que agrupar/comparar por mes calendario sea directo.
- **Comparación contra lo real se calcula al vuelo en el SELECT (subquery correlacionada), no hay tabla de snapshot**: `CantidadReal` suma `Kardex.KardexMovimientos` con `TipoMovID` del código `ENTRADA_PT` (producción terminada real) para el mismo Articulo+CentroCosto+mes; `VentaReal` suma `Cantidad * PrecioVenta` (precio **actual** del artículo, no histórico — aproximación consciente) sobre movimientos `SALIDA_VENTA_VISIONS` del mismo CentroCosto+mes. Si se agregan más tipos de movimiento de entrada/salida de PT en el futuro, revisar si deben sumarse aquí también.
- Backend: `NexoApi/Features/Planificacion/` (`PlanificacionService.cs`, `PlanificacionController.cs`, `Dtos/PlanificacionDtos.cs`), rutas `api/planificacion/demanda` y `api/planificacion/metas-venta`, `[Authorize(Roles = "Administrador,SupervisorPlanta")]` (a diferencia de RRHH/CRM que son Admin-only, aquí SupervisorPlanta también necesita ver/cargar proyecciones de producción).
- Frontend: `NexoWeb/Components/Pages/Planificacion/` (`Demanda.razor`+`DemandaDialog.razor`, `MetasVenta.razor`+`MetaVentaDialog.razor`), rutas `/planificacion/demanda` y `/planificacion/metas-venta`. Cada fila muestra un chip de % de cumplimiento (verde ≥100%, amarillo ≥70%, rojo <70%). Nuevo grupo "Planificacion" en `NavMenu.razor` (ícono `Timeline`).
- Demanda Proyectada solo permite elegir artículos `TipoArticulo == "Producto Terminado"` (mismo criterio que Mapeo Articulos Visions) — Materia Prima/Insumos no se "proyectan" para vender/producir con este mecanismo.

**Las 3 fases de la expansión ERP+CRM quedaron completas** (RRHH, CRM, Planificación). Ver sección 24 para lo que siguió después (BI, Logística, Proyectos) el mismo día.

## 24. BI + Logística (TMS) + Gestión de Proyectos (agosto 2026)

Continuación de la expansión de la sección 23. El usuario pidió: renombrar el Dashboard a "Business Intelligence" con datos transversales de todos los módulos; un módulo de Logística tipo TMS ("Despachos, guías y control de rutas/entregas"); y Gestión de Proyectos. Se acotó alcance con el usuario antes de construir (igual que en CRM/RRHH/Planificación):
- **BI**: se agregaron KPIs de CRM, RRHH, Planificación e Inventario (todas las opciones que ofrecí, el usuario las quería todas).
- **Logística (TMS)**: solo despachos + guías, **sin vehículos ni planeación de rutas** (fase inicial).
- **Proyectos**: proyectos + tareas + presupuesto/costos (el alcance más grande de las 3 opciones que ofrecí, no el mínimo).

**Decisión sobre Traspasos**: el usuario preguntó si Traspasos debía moverse a Logística. Se decidió que **no** — Traspasos (`Inventario`) son movimientos internos entre bodegas propias, sin cliente/ruta/guía; Logística es para despachos a clientes externos. Se mantienen como módulos separados, sin fusionar.

### Business Intelligence (rename + expansión transversal)

- **Solo se renombró la parte visible al usuario** (`NavMenu.razor`: "Dashboard" → "Business Intelligence"; `Dashboard.razor`: `<PageTitle>`, `<h1>`, módulo del hero). **La ruta (`/`), el namespace C# (`Features/Dashboard`), y las rutas de API (`api/dashboard/*`) NO se renombraron** — es una decisión de ingeniería consciente para no romper nada que ya funcionaba (botones de exportación Excel/PDF, gráficos, etc.) solo por un cambio de nombre visual. Si se busca "BI" en el código y no aparece, es porque vive bajo `Dashboard` a propósito.
- Nueva sección "Resumen General" en `Dashboard.razor`, con 4 tarjetas KPI nuevas: Clientes Nuevos (CRM, últimos 30 días + interacciones), Empleados Activos (RRHH, por Centro de Costo), Cumplimiento Demanda/Venta (Planificación, mes actual), Valor de Stock + Alertas (Inventario).
- Backend: 4 métodos nuevos en `DashboardService.cs`/`DashboardController.cs` (`ObtenerResumenCrmAsync`, `ObtenerEmpleadosPorCentroCostoAsync`, `ObtenerResumenPlanificacionAsync`, `ObtenerResumenInventarioAsync`), endpoints `api/dashboard/resumen-crm`, `api/dashboard/empleados-por-centro-costo`, `api/dashboard/resumen-planificacion`, `api/dashboard/resumen-inventario`.
- **`resumen-crm` y `empleados-por-centro-costo` son `[Authorize(Roles = "Administrador")]`** (más restrictivo que el resto del Dashboard, que es `Administrador,SupervisorPlanta,Bodeguero`) porque CRM y RRHH son Admin-only en sus propias pantallas — mismo criterio debe mantenerse ahí. `resumen-planificacion`/`resumen-inventario` sí son visibles para todos los roles del Dashboard.
- **El frontend carga estos 4 resúmenes en una llamada SEPARADA (`CargarResumenGeneralAsync`) del `Task.WhenAll` principal**, con su propio try/catch por HttpRequestException — así, cuando SupervisorPlanta/Bodeguero reciben 403 en CRM/RRHH, esas 2 tarjetas quedan en 0 en vez de tumbar el Dashboard completo con un error. Si se agregan más resúmenes restringidos por rol, seguir este mismo patrón (nunca meterlos en el `Task.WhenAll` que ya tiene su propio catch-all).
- `Crm.Clientes` ganó columna `FechaCreacion` (no existía desde la migración de Catalogo) — necesaria para contar "clientes nuevos" por período.

### Logística (TMS) — Despachos y Guías

- Schema nuevo `Logistica` con `Despachos` (ClienteID FK, CentroCostoID FK, BodegaOrigenID FK, Direccion, Observaciones, Estado, FechaDespacho, FechaEntrega, UsuarioID) y `DespachoDetalle` (líneas: ArticuloID + Cantidad). `NumeroGuia` **no es una columna** — se genera en el `SELECT` como `'GUIA-' + RIGHT('000000' + CAST(DespachoID AS VARCHAR), 6)`.
- **Un despacho SÍ descuenta stock real** (a diferencia de un simple registro documental) — se decidió así porque es un movimiento físico real de mercancía, igual de real que una venta de Visions o un traspaso. Nuevo tipo de movimiento Kardex `SALIDA_DESPACHO` (Signo -1).
- **`Logistica.sp_CrearDespacho`** — SP nuevo (patrón multi-línea, no hay TVP registrado): recibe las líneas como **JSON** (`@LineasJson NVARCHAR(MAX)`, parseado con `OPENJSON` en el SP), valida stock suficiente de TODAS las líneas ANTES de tocar nada (a diferencia de `sp_ProcesarEventoEntrante`, aquí SÍ se rechaza si no alcanza — es un despacho creado por un usuario interno, no una venta externa ya consumada), y hace FEFO por cada línea igual que `sp_ProcesarEventoEntrante`/`sp_CrearYEnviarTraspaso` (cursor anidado: uno por línea, uno por lote dentro de cada línea). **Verificado con una prueba real dentro de una transacción con ROLLBACK** (Cliente/Artículo/Bodega reales) antes de dar el trabajo por terminado — confirmó stock descontado correctamente y Kardex generado, sin dejar datos de prueba.
- Backend: `NexoApi/Features/Logistica/` (`LogisticaService.cs` usa `System.Text.Json.JsonSerializer.Serialize` para las líneas antes de llamar el SP vía Dapper `CommandType.StoredProcedure`), rutas `api/logistica/despachos`, `[Authorize(Roles = "Administrador,Bodeguero")]`.
- Frontend: `NexoWeb/Components/Pages/Logistica/` (`Despachos.razor`, `CrearDespachoDialog.razor` con líneas dinámicas agregar/quitar, `DetalleDespachoDialog.razor`). Botón "Confirmar Entrega" cambia Estado `DESPACHADO` → `ENTREGADO` y setea `FechaEntrega`.
- Solo Producto Terminado es despachable (mismo criterio que Planificación/Mapeo Visions).
- **Ajuste de permisos necesario**: como esta página permite Bodeguero (y Proyectos permite SupervisorPlanta) pero `api/crm/clientes` y `api/rrhh/empleados` (GET) eran Admin-only, se abrieron esos DOS endpoints de lectura (NO creación/edición) a esos roles adicionales — ver `CrmController.cs`/`EmpleadosController.cs`, comentado en el código. Si se agrega un módulo nuevo que necesite leer Clientes o Empleados con un rol distinto, seguir el mismo patrón (override de `[Authorize]` a nivel de acción, no aflojar el controller completo).

#### Logística v2 — "nivel profesional" (mismo día, a pedido explícito del usuario)

El usuario pidió llevar cada fase "a un nivel profesional" — se acordó con él enfocarse en **profundidad funcional + validaciones robustas**, un módulo a la vez, empezando por Logística (por ser el único de los 6 módulos nuevos que ya toca inventario y dinero real).

- **`Logistica.sp_AnularDespacho`** (SP nuevo) — revierte un despacho `DESPACHADO` (no `ENTREGADO` ni ya `ANULADO`): por cada movimiento `SALIDA_DESPACHO` que generó el despacho original (identificados por `ObservacionDetallada = 'Despacho #N'`, no hay FK directa Kardex→Despacho), devuelve la cantidad exacta al mismo lote/bodega y genera un movimiento `ENTRADA_ANULACION_DESPACHO` (Signo +1, nuevo tipo Kardex) compensatorio. Marca `Estado='ANULADO'`, `MotivoAnulacion`, `FechaAnulacion`, `UsuarioAnulaID` (3 columnas nuevas en `Logistica.Despachos`). **Verificado con una prueba real de ciclo completo** (crear → anular, dentro de una transacción con `ROLLBACK`): confirmó que el stock final coincide exactamente con el stock antes de crear el despacho.
- **`sp_CrearDespacho` ganó 5 validaciones nuevas**, todas con mensaje específico (antes solo existía la de stock, con mensaje genérico "una o más líneas"):
  1. Cliente debe existir y estar activo (`THROW 56004`)
  2. La bodega de origen debe pertenecer al Centro de Costo elegido (`THROW 56005`)
  3. No se puede repetir el mismo `ArticuloID` en dos líneas del mismo despacho (`THROW 56006`)
  4. Las cantidades deben ser > 0 (`THROW 56007`)
  5. El mensaje de stock insuficiente ahora **nombra el SKU y nombre exacto** del/los artículo(s) que faltan (antes solo decía "una o más líneas") — usa `STRING_AGG` con JOIN a `Catalogo.Articulos`
  - Las 5 se probaron una por una contra la base real (todas fallan ANTES de `BEGIN TRANSACTION`, así que no hace falta wrappearlas en un `ROLLBACK` — no llegan a tocar nada).
- Backend: `LogisticaService.AnularDespachoAsync` + endpoint `POST api/logistica/despachos/{id}/anular`, mismo rol `Administrador,Bodeguero` que el resto del módulo.
- Frontend: botón "Anular" (solo visible si `Estado == DESPACHADO`) abre `AnularDespachoDialog.razor` (exige motivo, advierte que es irreversible) antes de llamar al endpoint. Filtro por Estado (`DESPACHADO`/`ENTREGADO`/`ANULADO`) en `Despachos.razor`. Chip de estado ahora tiene 3 colores (antes 2): verde=Entregado, rojo=Anulado, azul=Despachado.
- **Protección contra doble clic**: el botón "Nuevo Despacho" se deshabilita (`_creando`) mientras la petición de creación está en vuelo, para que un doble clic accidental no cree dos despachos idénticos.
- **Validación de artículo repetido también en el frontend** (`CrearDespachoDialog.razor`), antes de llamar al servidor — el SP la valida igual (es la fuente de verdad), pero avisar en el cliente da feedback inmediato sin esperar el viaje de red.

### Gestión de Proyectos

- Schema nuevo `Proyectos` con `Proyectos` (Nombre, ClienteID NULL FK, CentroCostoID NULL FK, Descripcion, FechaInicio, FechaFin, Estado, Presupuesto), `Tareas` (ProyectoID FK, Titulo, ResponsableID NULL FK → `Rrhh.Empleados`, Estado, FechaLimite), `Costos` (ProyectoID FK, Tipo `MANO_OBRA`/`MATERIAL`/`OTRO`, Descripcion, Valor, EmpleadoID NULL FK, ArticuloID NULL FK, UsuarioID).
- **Los costos son un valor `$` ingresado manualmente por el usuario, NO se calculan automático** desde horas trabajadas (RRHH) ni desde consumo real de inventario — es una decisión consciente de alcance para la primera versión. `EmpleadoID`/`ArticuloID` en `Costos` son solo de **trazabilidad** (para saber a quién/qué se refiere ese costo), no disparan ningún movimiento de Kardex ni afectan nómina.
- Backend: `NexoApi/Features/Proyectos/` (`ProyectosService.cs`, `ProyectosController.cs`), rutas `api/proyectos`, `api/proyectos/tareas`, `api/proyectos/costos`, `[Authorize(Roles = "Administrador,SupervisorPlanta")]`. `CostoTotal`/`TotalTareas`/`TareasCompletadas` en `ProyectoItem` son subqueries correlacionadas en el `SELECT` de `ListarProyectosAsync` (mismo patrón que Planificación — sin tabla de snapshot).
- Frontend: `NexoWeb/Components/Pages/Proyectos/` — `Proyectos.razor` (tarjetas con % de costo vs presupuesto), `ProyectoDialog.razor` (crear/editar datos básicos), `GestionProyectoDialog.razor` (diálogo con tabs "Tareas"/"Costos", formularios inline para agregar de cada uno, cambio de estado de tarea directo desde la tabla). Ruta `/proyectos`.

## 25. CRM v2 — "nivel profesional" (agosto 2026)

Siguiendo el mismo plan de "llevar cada fase a un nivel profesional" (sección 24), el usuario pidió para CRM no solo validaciones sino **funcionalidad nueva de fondo**: "clientes es de crm entonces un apartado de contacto bien elaborado". Se formuló el alcance con el usuario en dos rondas de `AskUserQuestion` (4 opciones máx. cada una). El usuario seleccionó **todo lo ofrecido** (A-F) más pidió correo/WhatsApp/Leads/marketing automation — se acotó con él a: **"orden 1" (CRM núcleo A-F + Leads, sin dependencias externas) y "orden 3" (marketing automation) ahora; "orden 2" (correo/WhatsApp reales) queda explícitamente en pausa**. "Marketing automation" se acotó a **alertas internas de clientes fríos** (sin ningún envío real de correo/WhatsApp — no hay integración de mensajería en este alcance) para poder cumplir "orden 3" sin depender de "orden 2".

**Piezas construidas (A-F + Leads)**:
- **A) Múltiples contactos por cliente**: tabla nueva `Crm.Contactos` (ContactoID, ClienteID FK, Nombres, Cargo, Telefono, Email, EsPrincipal bit, Estado bit, FechaCreacion). Se migró el dato del campo suelto `Contacto` (texto) de los clientes existentes a un registro en `Crm.Contactos` con `EsPrincipal=1`, y **la columna `Contacto` dejó de usarse** (no se eliminó de la tabla, pero ya no se lee/escribe desde código — el campo real es `Crm.Contactos`). Al crear/editar un contacto con `EsPrincipal=true`, `CrmService.CrearContactoAsync`/`ActualizarContactoAsync` usan una **transacción** para desmarcar cualquier otro contacto principal del mismo cliente antes de marcar el nuevo — garantiza máximo un principal por cliente a nivel de aplicación (no hay constraint en BD para esto).
- **B) Responsable comercial**: `Crm.Clientes.ResponsableID` (FK → `Rrhh.Empleados`, NULL). Mismo patrón ya usado en `Proyectos.Tareas.ResponsableID`. Filtro por Responsable en `Clientes.razor`.
- **C) Historial unificado**: `CrmService.ObtenerHistorialAsync` hace `UNION ALL` de `Crm.Interacciones` + `Produccion.OrdenesProduccion` (filtradas por `ClienteID`) + `Logistica.Despachos` (filtradas por `ClienteID`), ordenado por fecha DESC — un solo timeline por cliente (pedidos + despachos + bitácora), sin tabla nueva.
- **D) Seguimiento y alertas de clientes fríos** (incluye el alcance acotado de "marketing automation"): `Crm.Clientes.ProximoContacto` (DATE NULL) se puede agendar desde la pestaña "Bitácora" al registrar una interacción. Endpoint `GET api/crm/clientes-frios?diasSinContacto=30` (`ListarClientesFriosAsync`) devuelve clientes sin interacción reciente. **Se muestra en Business Intelligence** (`Dashboard.razor`, tarjeta "Clientes Fríos (CRM)"): `MudPaper` con tabla (Cliente/Responsable/Última Interacción/Próximo Contacto) y botón "Ver en CRM" que navega a `/crm/clientes` (no abre el diálogo de un cliente específico — el Dashboard no carga la lista completa de clientes, solo la de fríos). Se oculta por completo si no hay clientes fríos (`@if (_clientesFrios.Count > 0)`). Se carga en `CargarResumenGeneralAsync()`, mismo try/catch que `_resumenCrm` (Admin-only, 403 esperado para SupervisorPlanta/Bodeguero, queda en lista vacía sin romper el resto del Dashboard).
- **E) Documentos adjuntos**: tabla nueva `Crm.ClienteDocumentos` (DocumentoID, ClienteID FK, TipoDocumento [RUT/CAMARA_COMERCIO/CONTRATO/OTRO], NombreArchivo, ContentType, Archivo VARBINARY(MAX), FechaSubida, UsuarioID FK), límite 5MB validado en el controller. **Descarga NO es `[AllowAnonymous]`** (a diferencia de imágenes de artículo/empleado que sí lo son, porque van en `<img src>`): usa `ApiClient.GetBytesAsync()` autenticado + `DotNetStreamReference` + JS `nexoDescargarArchivo` (mismo patrón que las exportaciones del Dashboard) — un RUT o contrato nunca queda expuesto sin autenticación. Bug de Dapper evitado usando `private record DocumentoArchivo(byte[] Archivo, string ContentType, string NombreArchivo)` en vez de `ValueTuple` (ver lección 20.30).
- **F) Validación de NIT duplicado + búsqueda avanzada**: índice único filtrado `UQ_Clientes_NIT` sobre `Crm.Clientes(NIT) WHERE NIT IS NOT NULL AND NIT <> ''` (permite muchos NULL, rechaza NIT no vacío repetido). **Requirió `SET QUOTED_IDENTIFIER ON` explícito** antes del `CREATE UNIQUE INDEX` — el default de `sqlcmd` lo tiene OFF, lo cual falla con error 1934 en índices filtrados. Búsqueda avanzada = filtros combinables por Responsable/TipoCliente/FuenteContacto en `Clientes.razor` (client-side sobre la lista ya cargada, sin nuevo endpoint).
- **Leads (pipeline de prospectos)**: tabla nueva `Crm.Leads` (LeadID, Nombre, Empresa, Telefono, Email, FuenteContacto, Etapa nvarchar(20) default `NUEVO` [NUEVO/CONTACTADO/CALIFICADO/CONVERTIDO/DESCARTADO], Notas, ResponsableID FK, ClienteIDConvertido NULL FK → `Crm.Clientes`, FechaCreacion, FechaConversion NULL). Un Lead `CONVERTIDO` **no se puede editar** (`CrmService.ActualizarLeadAsync` lanza `InvalidOperationException` si `Etapa == "CONVERTIDO"`). `ConvertirLeadAsync` es una **transacción**: crea un `Cliente` nuevo con los datos del Lead, marca el Lead como `CONVERTIDO` con `FechaConversion` y `ClienteIDConvertido`. Frontend nuevo `NexoWeb/Components/Pages/Crm/Leads.razor` + `LeadDialog.razor`, ruta `/crm/leads`, botón "Convertir a Cliente" solo visible en Etapa `CALIFICADO`. Link agregado al `MudNavGroup Title="CRM"` en `NavMenu.razor`.

**Frontend — reestructuración de la gestión de cliente**: `InteraccionesDialog.razor` (fase 1) se **eliminó** y su contenido se absorbió como la pestaña "Bitácora" dentro de un diálogo unificado nuevo, `GestionClienteDialog.razor`, con 4 tabs (`MudTabs`): Contactos, Bitácora, Historial, Documentos. El botón "Bitácora" en `Clientes.razor` se renombró a "Gestionar" y ahora abre este diálogo unificado.

**Explícitamente diferido/en pausa** (no construir sin que el usuario lo retome primero): envío real de correos electrónicos, automatización de WhatsApp (API oficial de Meta requiere cuenta de negocio verificada + proveedor intermediario como Twilio/360dialog + costo por mensaje — sin eso, solo sería posible un botón `wa.me` manual, mismo patrón ya usado en Ayuda/Configuración), y marketing automation con envíos reales (dependía de que exista infraestructura de correo primero).

**Actualización (mismo día)**: la tarjeta de clientes fríos SÍ se construyó — ver sección 25.1.

### 25.1 — Tarjeta "Clientes Fríos" en Business Intelligence

`Dashboard.razor` gano una tarjeta `MudPaper` ("Clientes Fríos (CRM)") que consume `GET api/crm/clientes-frios`, con tabla (Cliente/Responsable/Última Interacción/Próximo Contacto) y botón "Ver en CRM" que navega a `/crm/clientes` (no abre el diálogo de un cliente específico — el Dashboard no carga la lista completa de clientes). Se oculta si no hay clientes fríos. Se carga en `CargarResumenGeneralAsync()`, mismo try/catch que `_resumenCrm` (Admin-only, 403 esperado para SupervisorPlanta/Bodeguero).

## 26. RRHH v2 + Planificación v2 — "nivel profesional" (agosto 2026)

Continuación del plan de "llevar cada fase a un nivel profesional" (secciones 24-25). El usuario pidió construir TODO lo ofrecido en ambos módulos (formulado con `AskUserQuestion`, 2 preguntas por módulo, 4 opciones máx. cada una) y "planifiquemos todo lo que debe llevar" antes de construir.

**Bug real encontrado y corregido de paso**: `DashboardService.ObtenerResumenPlanificacionAsync` (sección 24) tenía un patrón SQL roto — `AVG(CASE WHEN ... THEN (subconsulta con SUM correlacionada) END)` — que SQL Server rechaza con error 130 ("Cannot perform an aggregate function on an expression containing an aggregate or a subquery") **siempre que se ejecuta**, sin importar si hay datos. Confirmado standalone contra la BD real. Este bug ya existía en producción (tarjeta "Cumplimiento Demanda" del Dashboard fallando silenciosamente, atrapada por el try/catch de `CargarResumenGeneralAsync`). **Patrón correcto**: materializar el valor por fila en una tabla derivada (`SELECT CASE ... AS Cumplimiento FROM ... ) x`) y recién ahí aplicar `AVG()` en la consulta externa — nunca envolver un `AVG()`/`SUM()` externo directamente alrededor de una expresión que contiene una subconsulta correlacionada con su propio agregado. Corregido y verificado standalone contra la BD real. **Si se escribe una consulta nueva con este patrón (agregado sobre CASE con subconsulta agregada), usar SIEMPRE la tabla derivada** — ya se aplicó también en `PlanificacionService.ListarDesviacionesAsync` y `ObtenerHistoricoCumplimientoAsync` (ver abajo), que tenían el mismo problema antes de corregirlo.

### RRHH v2

- **Cargos y Departamentos formales**: tablas nuevas `Rrhh.Departamentos` y `Rrhh.Cargos` (Cargo pertenece opcionalmente a un Departamento). `Rrhh.Empleados.Cargo` (texto libre) se reemplazó por `CargoID` FK — el único valor existente ("Desarrollador") se migró a un Cargo real. La columna `Cargo` vieja se dejó en la tabla sin eliminar pero ya no se usa desde el código (mismo criterio que `Crm.Clientes.Contacto`). Página nueva `NexoWeb/Components/Pages/Rrhh/CargosDepartamentos.razor` (`/rrhh/cargos`, 2 tabs).
- **Historial laboral**: tabla nueva `Rrhh.HistorialLaboral`, **se genera automático** (no hay POST manual) dentro de `RrhhService.ActualizarEmpleadoAsync` — compara `CargoID`/`CentroCostoID` ANTES vs DESPUÉS del `UPDATE`, en una transacción, e inserta una fila por cada campo que cambió con los nombres (no los IDs) de antes/después.
- **Organigrama**: `Rrhh.Empleados.JefeDirectoID` (auto-FK, NULL). `ActualizarEmpleadoAsync` valida dos cosas antes de guardar: (1) un empleado no puede ser su propio jefe, (2) el nuevo jefe no puede ser subordinado directo o indirecto del empleado editado (deteccion de ciclos vía CTE recursivo `WITH Subordinados AS (...)`) — si lo es, lanza `InvalidOperationException` (409 Conflict). **Verificado con una prueba real de ciclo dentro de una transacción con ROLLBACK**: confirmó `EsCiclo = 1` para el caso que debía bloquearse. Frontend: `NexoWeb/Components/Pages/Rrhh/Organigrama.razor` (`/rrhh/organigrama`) + `OrganigramaRama.razor` (componente recursivo: un nodo se renderiza a sí mismo y a sus hijos vía `Todos.Where(n => n.JefeDirectoID == Nodo.EmpleadoID)`).
- **Documentos de empleado**: tabla nueva `Rrhh.EmpleadoDocumentos`, mismo patrón exacto que `Crm.ClienteDocumentos` (descarga autenticada, no `[AllowAnonymous]`, límite 5MB, `private record DocumentoArchivo` para evitar el bug de Dapper+ValueTuple).
- **Ausencias y Vacaciones**: tabla nueva `Rrhh.Ausencias` (Tipo VACACIONES/INCAPACIDAD/PERMISO/OTRO, Estado PENDIENTE/APROBADA/RECHAZADA). **Sin ningún cálculo de nómina** — solo control de disponibilidad, por instrucción explícita del usuario (nómina/contabilidad siempre fuera de alcance). Se registran desde la pestaña "Ausencias" en `GestionEmpleadoDialog`; se aprueban/rechazan desde la página global nueva `NexoWeb/Components/Pages/Rrhh/Ausencias.razor` (`/rrhh/ausencias`, filtro por Estado).
- **Evaluaciones de desempeño**: tabla nueva `Rrhh.Evaluaciones` (Calificacion `DECIMAL(3,1)` de 1.0 a 5.0, validado en el backend, ResponsableID opcional FK → `Rrhh.Empleados`). Sin vínculo a compensación.
- **Capacitaciones**: tabla nueva `Rrhh.Capacitaciones` (con `FechaVencimiento` opcional — la UI resalta en rojo si ya venció).
- **Frontend — diálogo unificado**: `GestionEmpleadoDialog.razor` (nuevo), mismo patrón que `GestionClienteDialog.razor` de CRM v2 — 5 tabs (`MudTabs`): Historial Laboral, Documentos, Ausencias, Evaluaciones, Capacitaciones. Se abre con el botón "Gestionar" en `Empleados.razor` (antes solo tenía "Editar").
- **`EmpleadoDialog.razor`**: el campo `Cargo` (texto libre) se reemplazó por un `MudSelect` de `Cargos` (mostrando también su Departamento); se agregó `MudSelect` de "Jefe Directo" (excluye al propio empleado en edición).
- Controllers nuevos/ampliados: `EmpleadosController.cs` ganó `/historial`, `/documentos`, `/evaluaciones`, `/capacitaciones`, `/organigrama`; controller nuevo `RrhhCatalogosController.cs` (`api/rrhh/departamentos`, `api/rrhh/cargos`, `api/rrhh/ausencias`) para los recursos que no giran alrededor de un solo `EmpleadoID`.

### Planificación v2

- **Alertas de desviación**: `PlanificacionService.ListarDesviacionesAsync(umbral)` — por Centro de Costo (no promediado global), cumplimiento de Demanda y Venta del mes actual, filtrado a los que están por debajo del umbral (default 70%). Mismo patrón de "alerta interna" que Clientes Fríos — **solo detecta, no envía nada**. Se muestra en BI (`Dashboard.razor`, tarjeta "Desviaciones de Planificación"), cargada junto con `_resumenPlanificacion`/`_resumenInventario` (mismo try/catch, visible para Administrador/SupervisorPlanta).
- **Comparativo histórico multi-mes**: `PlanificacionService.ObtenerHistoricoCumplimientoAsync(meses)` trae la serie completa (default 12 meses) de cumplimiento promedio de Demanda y Venta por mes — antes solo existía el mes actual. Se muestra como tabla en la parte superior de `Demanda.razor` (`/planificacion/demanda`).
- **Proyección sugerida**: `GET api/planificacion/demanda/sugerencia?articuloId=&centroCostoId=&periodo=` calcula el promedio de lo realmente producido (`ENTRADA_PT`) en los 3 meses calendario anteriores al período elegido. Botón "Usar sugerencia" en `DemandaDialog.razor` (solo visible al crear, cuando Artículo+Centro de Costo+Mes ya están elegidos) rellena el campo `CantidadProyectada` — el usuario puede editarlo después, **nunca se guarda automático**.
- **Versionado de metas**: tabla nueva `Planificacion.MetasVentaHistorial`. `PlanificacionService.ActualizarMetaVentaAsync` ahora es una **transacción**: antes del `UPDATE`, inserta el valor ANTERIOR (`MetaValor`/`Notas`) en el historial con el `UsuarioID` de quien hizo el cambio. Botón "Historial" nuevo en `MetasVenta.razor` abre `HistorialMetaVentaDialog.razor` (lista de versiones anteriores). **Verificado con una prueba real dentro de una transacción con ROLLBACK**: crear meta → insertar historial → actualizar meta, confirmando que ambas tablas quedan consistentes.
- `PlanificacionController` ganó `UsuarioActualId` (mismo patrón `ClaimTypes.NameIdentifier` que `CrmController`/`EmpleadosController`) para poder pasar quién hizo cada cambio de meta al historial.

## 27. Sidebar con submenús flotantes (flyout) + Favoritos (agosto 2026)

El usuario pidió cambiar el menú lateral de acordeón (subitems empujando el resto hacia abajo, `MudNavGroup`) a submenús flotantes que aparecen a un lado al pasar el cursor o hacer click (como HubSpot), manteniendo los mismos colores, y agregar un apartado "Favoritos" con un botón de marcador en cada subpágina para guardarla ahí.

- **`NavFlyoutGroup.razor`** (nuevo, `Components/Layout/`) — reemplaza a `MudNavGroup`. Envuelve un `MudMenu` (mismo componente que ya usan Notificaciones/PerfilMenu en la barra superior — se porta vía `MudPopoverProvider`, así el panel nunca queda recortado por el `overflow` del sidebar). `ActivatorContent` es la fila del grupo (ícono + texto + chevron); el click nativo de `MudMenu` ya abre/cierra el menú (cubre "presionar la pestaña"). Para el hover se llama a mano `MudMenu.OpenMenuAsync(new EventArgs(), temporary: true)` en `@onmouseenter` del trigger (`temporary:true` = sin overlay de fondo, pensado exactamente para menús que solo viven mientras el cursor está encima) y `CloseMenuAsync()` en `@onmouseleave` con un delay de 250ms cancelable (`CancellationTokenSource`) para poder cruzar el espacio hasta el panel sin que se cierre solo; el panel también tiene su propio `@onmouseenter`/`@onmouseleave` que cancela/reprograma el mismo cierre.
- **`NavFlyoutLink.razor`** (nuevo) — una fila del panel: `NavLink` (el de Microsoft, no `MudNavLink` — necesitábamos `Match="NavLinkMatch.Prefix"` con clase `active` automática) + `MudIconButton` de marcador (`Bookmark`/`BookmarkBorder`) que alterna favorito sin navegar (es un botón hermano del link, no anidado, así no hay conflicto de click).
- **Favoritos**: se guardan como **JSON en la tabla genérica `Seguridad.PreferenciasUsuario`** (clave `"Favoritos"`, valor `[{"Href":"...","Etiqueta":"..."}]`) — mismo mecanismo ya usado para `TemaOscuro`/`VistaListado`/`MostrarAyuda`, sin tabla nueva. **Requirió ampliar `Seguridad.PreferenciasUsuario.Valor` de `NVARCHAR(50)` a `NVARCHAR(MAX)`** (ya ejecutado) — el tamaño viejo alcanzaba para los valores simples anteriores pero no para una lista. `PreferenciasState.cs` ganó `Favoritos` (deserializa el JSON), `EsFavorito(href)`, `ToggleFavoritoAsync(href, etiqueta)` (reusa el `EstablecerAsync` privado que ya existía — actualiza el diccionario en memoria, dispara `OnCambio`, persiste a la API).
- `NavMenu.razor` reescrito completo: el grupo "Favoritos" va primero, listando `Preferencias.Favoritos` (vacío → mensaje de ayuda); todos los `MudNavGroup`/`MudNavLink` viejos pasaron a `NavFlyoutGroup`/`NavFlyoutLink`; los 2 links planos de nivel superior (Business Intelligence, Proyectos) ahora son un `NavLink` de Microsoft con la misma clase visual del trigger (sin flyout, sin botón de favorito — no son "subpáginas" de nada). La lógica de `AuthorizeView`/roles se mantuvo idéntica a como estaba, solo se reemplazaron los componentes visuales.
- `NavMenu.razor.css` reescrito completo con las clases nuevas (`.nexo-navflyout__*`), mismo esquema de color que ya existía (fondo `#13131F`/`#1A1A2C`, texto `#9B9BB4`/`#E0E0F0`, activo con degradado morado `#7C5CFF → #5A3BFF`) — el panel flotante usa `PopoverClass`/`ListClass` de `MudMenu` para poder apuntarle con `::deep`.
- **No verificado visualmente en navegador** — por regla del usuario, los cambios de UI se validan solo con `dotnet build` salvo que pida verlo corriendo. El comportamiento de hover/click y el posicionamiento exacto del flyout debe confirmarse en la app real.

### 27.1 — Corrección: varios flyouts abiertos a la vez + rediseño visual (mismo día)

Primera versión tenía 2 problemas reales (reportados por el usuario con captura): (1) pasar el cursor rápido por varios grupos dejaba **varios paneles abiertos y apilados al mismo tiempo** (cada `NavFlyoutGroup` cerraba con su propio timer independiente, sin coordinación entre grupos); (2) el diseño se veía "cortado" — sin separación entre título y links, botón de favorito apretado contra el texto sin espacio reservado, sin tarjeta claramente diferenciada del fondo.

- **`NavFlyoutCoordinator.cs`** (nuevo, clase C# plana, no componente) — una sola instancia se crea en `NavMenu.razor` y se pasa a todos los `NavFlyoutGroup` via `<CascadingValue Value="_coordinador">`. Cada grupo se registra en `MudMenu.OpenChanged` (dispara sin importar si se abrió por hover o por click): al abrirse, `Coordinador.Registrar(this)` cierra inmediatamente (`CerrarAhoraAsync()`, sin el delay de 250ms pensado para cruzar el mouse) cualquier otro grupo que estuviera abierto. Así solo hay un panel visible a la vez, sin importar qué tan rápido se mueva el cursor entre triggers.
- **Rediseño del panel** (`NavMenu.razor.css`): el `PopoverClass`/`ListClass` de `MudMenu` ahora quedan transparentes (sin fondo/sombra propios) y la tarjeta visual real es un `<div class="nexo-navflyout__panel">` interno con ancho fijo (240px), fondo `#1C1C30` (un tono más claro que el sidebar `#13131F`, para que se note como capa flotante), borde sutil, sombra marcada y esquinas redondeadas — separado con más "aire" del trigger. Título del grupo con `border-bottom` (línea divisoria clara antes de los links) y color morado de acento en vez de gris plano.
- Cada fila (`.nexo-navflyout__item`) ahora resalta como bloque completo al hover (texto + botón de marcador juntos, no cada uno por separado), y el icono de marcador queda con `opacity:0.55` por defecto (descubrible pero no compite visualmente) subiendo a opacidad completa al pasar el cursor sobre la fila.
- **Favoritos vacío**: ya no es un `NavFlyoutGroup` interactivo — es una fila estática (`div` con clase `nexo-navflyout__trigger--disabled`, `opacity:0.45`, sin hover ni cursor de acción) que ni siquiera monta el `MudMenu` por debajo. En cuanto hay ≥1 favorito, `NavMenu.razor` renderiza el `NavFlyoutGroup` real. Se agregó también un separador visual (`.nexo-navflyout__divider`) entre Favoritos y el resto del menú.

### 27.2 — Vuelta atrás: el usuario no quiso el flyout, favoritos pasan a botón por página (mismo día)

Tras ver el resultado, el usuario pidió **revertir el sidebar al diseño de acordeón original** (`MudNavGroup`, subitems empujando hacia abajo) — no le gustó el flyout. Los favoritos se mantienen, pero el botón de marcador **ya no vive en el menú lateral**: ahora es un botón dentro de cada subpágina, junto a su título.

- **`NavFlyoutGroup.razor`, `NavFlyoutLink.razor`, `NavFlyoutCoordinator.cs` se ELIMINARON** (código muerto, ya no se usan). `NavMenu.razor` y `NavMenu.razor.css` volvieron exactamente al diseño de acordeón de antes de la sección 27 (mismas clases `.mud-nav-link`/`.mud-nav-group`).
- **`NavMenu.razor`** ganó un `MudNavGroup Title="Favoritos"` al inicio, pero **solo se renderiza si `Preferencias.Favoritos.Count > 0`** (si no hay ninguno, no aparece nada en el menú — cumple "que se active solo si tiene al menos un favorito"). Sin botón de marcador ahí — solo lista los links guardados.
- **`Components/Shared/BotonFavorito.razor`** (nuevo) — `MudIconButton` (Bookmark/BookmarkBorder) que recibe `Href`/`Etiqueta` como parámetros y llama a `PreferenciasState.ToggleFavoritoAsync` (el mismo mecanismo de la sección 27, sin cambios ahí). Se agregó junto al `<MudText Typo="Typo.h5">` de **24 subpáginas** (todas las que cuelgan de un grupo en el menú), envuelto en un `<div class="d-flex align-center mb-4">` para alinearlo con el título. **No se agregó** en Business Intelligence (`/`) ni Proyectos (`/proyectos`) — son links planos de nivel superior, no "subpáginas" de ningún grupo, mismo criterio que ya se había usado en la versión flyout.
- Si se agrega una subpágina nueva a futuro, replicar el mismo patrón: `<div class="d-flex align-center mb-4" style="gap: 0.25rem;"><MudText Typo="Typo.h5">Titulo</MudText><BotonFavorito Href="/ruta" Etiqueta="Titulo" /></div>` (ya no lleva `Class="mb-4"` en el `MudText`, se movió al div contenedor).

## 28. Proyectos v2 — "nivel profesional", el último módulo pendiente (agosto 2026)

Con BI, Logística, CRM, RRHH y Planificación ya nivelados (secciones 24-27), Proyectos era el único que quedaba "sin alimentar" — solo tenía Proyectos + Tareas + Costos básicos (crear/editar plano, sin nada más). Se formuló el alcance con `AskUserQuestion` (2 preguntas, 4 opciones cada una) — el usuario seleccionó **todo lo ofrecido en ambas partes**: Hitos/Fases, Documentos, Comentarios/Bitácora, Dependencias entre tareas, Alertas de atraso/sobrecosto, Prioridad, y Vista Kanban de tareas.

- **Prioridad del proyecto**: `Proyectos.Proyectos` ganó `Prioridad NVARCHAR(10) DEFAULT 'MEDIA'` (ALTA/MEDIA/BAJA). Se muestra como chip de color en la tarjeta de `Proyectos.razor` junto al chip de Estado.
- **Hitos / Fases**: tabla nueva `Proyectos.Hitos` (Nombre, FechaObjetivo, FechaCompletado NULL, Estado PENDIENTE/EN_PROGRESO/COMPLETADO, Orden). Al marcar un hito como COMPLETADO, `ActualizarHitoAsync` rellena `FechaCompletado` con la fecha actual **solo si estaba en NULL** (`ISNULL(FechaCompletado, CAST(GETDATE() AS DATE))` — no la pisa si el usuario ya la había fijado antes). Nueva pestaña "Hitos" en `GestionProyectoDialog.razor`. `ProyectoItem` ganó `TotalHitos`/`HitosCompletados` (subqueries correlacionadas, mismo patrón que `TotalTareas`/`TareasCompletadas`), mostrado en la tarjeta de `Proyectos.razor` solo si `TotalHitos > 0`.
- **Documentos adjuntos**: tabla nueva `Proyectos.ProyectoDocumentos`, mismo patrón exacto que `Crm.ClienteDocumentos`/`Rrhh.EmpleadoDocumentos` (descarga autenticada, límite 5MB, `private record DocumentoArchivo` anti-bug-Dapper). Tipos: CONTRATO/PLANO/COTIZACION/OTRO.
- **Comentarios / Bitácora**: tabla nueva `Proyectos.Comentarios` (Texto, Fecha, UsuarioID) — timeline simple de notas, pestaña "Bitacora" nueva.
- **Dependencias entre tareas**: tabla nueva `Proyectos.TareaDependencias` (TareaID, DependeDeTareaID, PK compuesta, `CHECK TareaID <> DependeDeTareaID` contra auto-dependencia). **Una tarea no puede salir de `PENDIENTE` si alguna tarea de la que depende no está `COMPLETADA`** — validado en `ProyectosService.ActualizarTareaAsync` (lanza `InvalidOperationException` listando por nombre las tareas que bloquean → 409 Conflict). `TareaItem` ganó `DependeDeTareaIds` (lista), poblada con una query aparte agrupada por `TareaID` (mismo patrón de "dos queries + merge en C#" que el historial de Planificación). **Verificado con una prueba real dentro de una transacción con ROLLBACK**: Tarea B con dependencia de Tarea A bloqueada mientras A está pendiente, desbloqueada al completar A.
- **Alertas de atraso/sobrecosto**: `ProyectosService.ListarAlertasAsync()` — mismo patrón de "alerta interna" que Clientes Fríos/Desviaciones (solo detecta, no envía nada). Atrasado = `FechaFin < hoy AND Estado NOT IN ('FINALIZADO','CANCELADO')`; Sobrecosto = `CostoTotal > Presupuesto` (con `Presupuesto > 0`). Tarjeta nueva "Alertas de Proyectos" en BI (`Dashboard.razor`), cargada junto con `_resumenPlanificacion`/`_desviaciones` (mismo try/catch, visible para Administrador/SupervisorPlanta).
- **Vista Kanban de tareas**: reemplaza la tabla plana de la pestaña "Tareas" en `GestionProyectoDialog.razor` por 3 columnas (Pendiente/En Curso/Completada), CSS nuevo (`GestionProyectoDialog.razor.css`, scoped normal — sin `::deep`, porque son divs propios del componente, no de MudBlazor). **Sin drag & drop** — cada tarjeta tiene botones `‹`/`›` para mover a la columna anterior/siguiente (evita depender de eventos HTML5 dragstart/dragover que no se pudieron probar visualmente). Si el backend rechaza el movimiento por dependencias sin completar, el mensaje de error del 409 se muestra tal cual en un Snackbar de advertencia.
- Al crear una tarea, un `MudSelect MultiSelection="true"` permite elegir de qué tareas existentes depende (oculto si el proyecto todavía no tiene tareas).
- Controller: `ProyectosController` ganó `/hitos`, `/{proyectoId}/documentos` + `/documentos/{id}` (descarga/eliminar), `/comentarios`, `/alertas`. Mismo rol `Administrador,SupervisorPlanta` del resto del módulo.
- **Verificado con SQL real dentro de transacciones con ROLLBACK**: bloqueo/desbloqueo de dependencias, y relleno de `FechaCompletado` al completar un hito — ambos casos confirmados correctos, sin dejar datos de prueba.

## 29. Bugs reales reportados por el usuario y corregidos (agosto 2026)

Tras las secciones 24-28, el usuario reportó 3 problemas reales usando la app (con capturas): errores al cargar Demanda Proyectada, contenido de página tapado detrás de la barra superior, y que "Gestionar Cliente" no reflejaba una edición reciente.

### 29.1 — Bug real: `ValueTuple` con Dapper (violó la lección 20.30 propia del proyecto)

Al construir Planificación v2 (sección 26) y Proyectos v2 (sección 28) se repitió el mismo error ya documentado en la lección 20.30: usar `ValueTuple` como tipo genérico de `QueryAsync<T>`/`QuerySingleOrDefaultAsync<T>` de Dapper.
- `PlanificacionService.ObtenerHistoricoCumplimientoAsync` — la consulta de venta usaba `QueryAsync<(DateTime Periodo, decimal CumplimientoVentaPromedio)>`. Causaba el error genérico "Ocurrio un error interno inesperado" (500) al abrir `/planificacion/demanda`, con el `Task.WhenAll` fallando completo (por eso también se veía "No hay proyecciones registradas" — nunca llegaba a cargar nada). **Fix**: `private record VentaPorPeriodo(DateTime Periodo, decimal CumplimientoVentaPromedio)`.
- `ProyectosService.ListarTareasAsync` — usaba `QueryAsync<(int TareaID, ...)>` (7 campos). Rompía el tablero Kanban de `GestionProyectoDialog` (`CargarAsync` no tiene try/catch individual por sección, así que un fallo ahí tumbaba también Hitos/Costos/Documentos/Comentarios sin cargar nada — coincide con el reporte "no veo lo nuevo de proyectos y sus subpáginas bien trabajadas"). **Fix**: `private record TareaPlana(int TareaID, int ProyectoID, string Titulo, int? ResponsableID, string? Responsable, string Estado, DateTime? FechaLimite)`.
- **No se pudo reproducir en vivo para confirmar 100%** (verificar con `[Authorize]` deshabilitado temporalmente fue bloqueado correctamente por el clasificador de seguridad del entorno — decisión correcta, no se intentó rodear). El fix se aplicó igual porque es el patrón exacto que la lección 20.30 ya identificó como roto, independientemente de si con 0 filas alcanza a explotar o no.
- **Regla reforzada**: cualquier `Query*Async<T>` de Dapper con más de una columna debe usar un `record` (público o `private record` junto al método), **nunca** una tupla `(...)` de C#, sin excepción — ni siquiera para queries "internas" de una sola fila.

### 29.2 — Bug real: contenido tapado detrás de la barra superior (`MainLayout.razor.css`)

`MudAppBar` es `Fixed` por defecto (sale del flujo normal, `position:fixed`) — MudBlazor compensa esto agregando `padding-top: var(--mud-appbar-height)` a `.mud-main-content`. La regla de este proyecto pisaba el padding COMPLETO con un valor fijo `1.75rem` (28px) sin relación con la altura REAL de `.nexo-topbar` (76px, agrandada explícitamente en una sesión anterior) — dejaba los primeros ~48px de **cada página** tapados detrás de la barra fija. **Fix**: `padding: calc(76px + 1.75rem) 2rem 1.75rem !important;` (y su variante responsive en el media query de 960px). **Acoplamiento a vigilar**: si se vuelve a cambiar la altura de `.nexo-topbar`, hay que actualizar este `calc()` también — quedó comentado en el CSS para no repetir el bug.

### 29.3 — Bug real: "Gestionar Cliente" no mostraba los campos editables de CRM v2

`GestionClienteDialog.razor` solo mostraba `@Cliente.Nombre` en el encabezado — `Responsable`, `NIT`, `Estado` y `ProximoContacto` (agregados en CRM v2, sección 25) nunca se mostraban en ningún lado del diálogo de gestión, solo en el diálogo de "Editar". Si el usuario editaba esos campos y luego abría "Gestionar" esperando verlo reflejado, no había ningún indicio visual del cambio. **Fix**: encabezado nuevo con chips (Estado, NIT, Responsable, Próximo Contacto) justo debajo del nombre del cliente. El flujo de datos (`Clientes.razor.AbrirGestionAsync` pasa el `ClienteItem` actual de `_clientes`, ya refrescado tras cada edición vía `CargarAsync()`) ya era correcto — el problema era puramente de visualización, no de datos desactualizados.

## 30. Facturación (agosto 2026) — módulo nuevo, "tipo guardado"

El usuario pidió un registro de ventas simple: qué artículo se vendió, a quién, cuándo, y el estado de pago (Pagado / Pago por partes / Pendiente). Se acotó el alcance con 4 preguntas de `AskUserQuestion` antes de construir:
- **Es un registro APARTE de Despachos/Inventario** — no descuenta stock, no genera movimiento de Kardex. Si en algún momento se necesita que Facturación sí afecte inventario, es un cambio de alcance explícito a discutir primero, no algo implícito.
- **Una factura puede tener varios artículos** (encabezado + líneas, como una factura real).
- **El estado de pago se calcula, no se guarda**: se registran abonos/pagos con monto y fecha; el estado (`PENDIENTE`/`PARCIAL`/`PAGADA`) se deriva comparando `SUM(Pagos.Monto)` contra `SUM(Lineas.Cantidad*PrecioUnitario)` — así nunca queda desincronizado si se borra o corrige un pago (aunque por ahora no hay endpoint para editar/borrar pagos, solo crear).
- **Roles**: `Administrador,Bodeguero` (igual que Logística — el Bodeguero suele ser quien despacha/factura directo al cliente).

- Schema nuevo `Facturacion` con `Facturas` (ClienteID FK → `Crm.Clientes`, Fecha, Notas, UsuarioID), `FacturaLineas` (FacturaID FK, ArticuloID FK → `Catalogo.Articulos`, Cantidad, PrecioUnitario), `Pagos` (FacturaID FK, Monto, FechaPago, Notas, UsuarioID).
- Backend: `NexoApi/Features/Facturacion/` (`FacturacionService.cs`, `FacturacionController.cs`, `Dtos/FacturacionDtos.cs`), rutas `api/facturacion/facturas`, `api/facturacion/facturas/{id}/lineas`, `api/facturacion/facturas/{id}/pagos`, `api/facturacion/pagos`. `ListarFacturasAsync` trae `Total`/`TotalPagado` con subqueries correlacionadas vía un `private record FacturaCruda` (Dapper — nunca `ValueTuple`, ver lección 20.30/sección 29.1) y calcula `SaldoPendiente`/`Estado` en C#, filtrando por `estado` (si se pidió) después de calcularlo, no en SQL.
- Frontend: `NexoWeb/Components/Pages/Facturacion/` — `Facturas.razor` (lista con filtro por Cliente/Estado, ruta `/facturacion`), `FacturaDialog.razor` (crear factura con líneas dinámicas, mismo patrón que `CrearDespachoDialog.razor` de Logística — el precio unitario se prellena con `ArticuloItem.PrecioVenta` pero es editable), `GestionFacturaDialog.razor` (tabs Artículos/Pagos; registrar un pago sugiere por defecto el saldo pendiente completo, pero es editable). Link plano de nivel superior en `NavMenu.razor` (icono `Receipt`, no es un grupo con subitems) — igual que Proyectos, pero SÍ lleva `BotonFavorito` (a diferencia de Dashboard/Proyectos) porque no está anclado/siempre visible como esos dos.
- **Verificado con SQL real dentro de una transacción con ROLLBACK**: crear factura de 2 líneas (Total=200) → 0% pagado (PENDIENTE) → abono de 50 (PARCIAL, saldo 150) → abono de 150 (PAGADA, saldo 0). Los 3 estados calculados correctamente, sin dejar datos de prueba.

### 30.1 — Correcciones de UX reportadas por el usuario (mismo día)

- **Decimales feos en los campos numéricos**: `Catalogo.Articulos.PrecioVenta` es `DECIMAL(18,4)` — al prellenar `PrecioUnitario` de una línea de factura con ese valor, el `MudNumericField` (sin `Format` explícito) mostraba los 4 decimales crudos (ej. `10000,0000`). **Fix**: `Format="N0"` en los campos de precio/monto (`FacturaDialog.razor`, `GestionFacturaDialog.razor`), `Format="N2"` en Cantidad. La tabla de líneas en `GestionFacturaDialog` también cambió `Cantidad.ToString("N2")` (siempre 2 decimales, ej. "2,00") por `ToString("0.##")` (hasta 2 decimales, sin ceros de sobra).
- **Bug real y sistémico: `DialogService.ShowAsync(...)` resuelve cuando el diálogo se ABRE, no cuando se CIERRA.** Todas las pantallas con botón "Gestionar" (`Clientes.razor`, `Empleados.razor`, `Proyectos.razor`, y la nueva `Facturas.razor`) hacían `await DialogService.ShowAsync<...>(...); await CargarXAsync();` — el refresh de la lista corría apenas se abría el diálogo, **antes** de que el usuario alcanzara a hacer ningún cambio adentro. Por eso los cambios (ej. un pago registrado) parecían tardar mucho o no reflejarse — en realidad el refresh ya había pasado y no se repetía hasta la siguiente acción del usuario en la pantalla exterior. **Fix en las 4 pantallas**: capturar la referencia (`var dialogo = await DialogService.ShowAsync<...>(...)`) y hacer `await dialogo.Result;` antes de refrescar. **Si se agrega un nuevo flujo "Gestionar" en el futuro, seguir siempre este patrón** — nunca refrescar justo después de `ShowAsync` sin esperar `.Result`.
- **`GestionFacturaDialog.razor` además ganó actualización optimista en el propio diálogo**: en vez de cerrarse al registrar un pago (que forzaba reabrir para ver el resultado), ahora mantiene una copia local mutable (`_facturaActual`, un `record` con `with`-expression) que se recalcula al instante tras el POST, y de todos modos llama a `CargarAsync()` justo después para confirmar contra el servidor — el usuario ve el cambio de una vez, sin esperar ni reabrir.

### 29.4 — Nota: no se encontraron procesos huérfanos al momento de revisar

Se verificó `Get-Process -Name "NexoApi","NexoWeb","dotnet"` y los puertos 5272/7144 — nada corriendo. Si el usuario seguía viendo comportamiento viejo, probablemente su instancia local no se reinició después de los últimos cambios (ver rutina de diagnóstico ya documentada: sección de reglas de sesión al inicio de este archivo) — recomendado cerrar Visual Studio/cualquier proceso previo y volver a compilar antes de probar de nuevo.
