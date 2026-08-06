# Arquitectura del Sistema NEXO ERP

> **Actualizado agosto 2026** para reflejar los 19 módulos existentes (antes solo documentaba los 6 originales). Para un análisis crítico (qué falta, qué mejorar, prioridades) ver `docs/AUDITORIA_2026.md` — este archivo es solo el mapa de "qué existe y cómo se conecta", no una evaluación.

## 1. Visión General

NEXO ERP está construido en tres capas bien diferenciadas que se comunican de forma unidireccional:

```
┌─────────────────────────────────────────────────────────────┐
│                    Capa de Datos                             │
│   SQL Server (DESKTOP-V83PQ7M\JONATHAN / NEXO_ERP)          │
│   Tablas · Vistas · Stored Procedures · Funciones           │
└────────────────────────┬────────────────────────────────────┘
                         │ Dapper + SQL raw (sin ORM)
                         │ Microsoft.Data.SqlClient
┌────────────────────────▼────────────────────────────────────┐
│                    Capa de Negocio / API                     │
│   NexoApi — .NET 10 ASP.NET Core Web API                    │
│   JWT Bearer · ApiKey · ExceptionHandlingMiddleware          │
│   Features: Auth, Catalogo, Produccion, Inventario, Compras, │
│   Crm, Rrhh, Planificacion, Logistica, Proyectos,             │
│   Facturacion, Dashboard, Notificaciones, Busqueda ...        │
└───────────────┬─────────────────────────────────────────────┘
                │ HTTP + JSON (Bearer token)
                │ HttpClient tipado (NexoApiClient)
┌───────────────▼─────────────────────────────────────────────┐
│                    Capa de Presentación                       │
│   NexoWeb — .NET 10 Blazor Server                           │
│   MudBlazor 7.15 · ProtectedSessionStorage · SignalR        │
│   Páginas, Diálogos, NavMenu, Tema Grafito+Beige            │
└─────────────────────────────────────────────────────────────┘

Componente paralelo:
┌─────────────────────────────────────────────────────────────┐
│   NexoSyncAgent — .NET 10 Worker Service                    │
│   Sincroniza NEXO ↔ Visions ERP (sistema externo)           │
│   Auth: X-Api-Key sobre HTTPS hacia NexoApi                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. Diagrama de Flujo Principal

```mermaid
sequenceDiagram
    actor Usuario
    participant Web as NexoWeb<br/>(Blazor Server)
    participant API as NexoApi<br/>(.NET 10)
    participant DB as SQL Server<br/>(NEXO_ERP)

    Usuario->>Web: Inicia sesión (usuario/password)
    Web->>API: POST /api/auth/login
    API->>DB: SELECT Seguridad.Usuarios
    DB-->>API: UsuarioID, Hash, Rol, CentroCostoID
    API->>API: Verificar password (PBKDF2)
    API->>DB: INSERT Seguridad.SesionesUsuario
    API-->>Web: { accessToken, refreshToken, rol }
    Web->>Web: AuthStateService.IniciarSesionAsync()<br/>ProtectedSessionStorage
    Web-->>Usuario: Redirige al Dashboard

    Usuario->>Web: Navega a Órdenes de Producción
    Web->>API: GET /api/produccion/ordenes (Bearer JWT)
    API->>API: Valida JWT → extrae rol y centroCostoId
    API->>DB: SELECT OrdenesProduccion JOIN EstadosOP JOIN Articulos
    DB-->>API: Lista de OPs
    API-->>Web: JSON [ OrdenProduccionResumen ]
    Web-->>Usuario: Tabla con órdenes
```

---

## 3. Responsabilidades por Proyecto

### NexoApi

**Es**: el único punto de contacto con la base de datos. Toda la lógica de negocio vive aquí.

**No hace**: renderizado de UI, manipulación de estado del navegador.

Responsabilidades:
- Autenticación y emisión de JWT
- Validación de roles en cada endpoint
- Traducción de errores SQL a HTTP status codes
- Abstracción del modelo de datos (mapeo SQL → C# records)
- Ejecución de stored procedures para operaciones transaccionales
- Exposición de endpoints REST para cada módulo de negocio

### NexoWeb

**Es**: una interfaz de usuario reactiva. Nunca accede a la BD directamente.

**No hace**: validaciones de negocio, acceso a datos, lógica transaccional.

Responsabilidades:
- Renderizar la UI con MudBlazor
- Gestionar la sesión del usuario en memoria y en `ProtectedSessionStorage`
- Invocar `NexoApiClient` para todas las operaciones
- Controlar la visibilidad de elementos según el rol del usuario
- Mostrar notificaciones y confirmar operaciones destructivas

### NexoSyncAgent

**Es**: un worker autónomo que sincroniza inventario entre NEXO y Visions.

Responsabilidades:
- Leer `Integracion.EventosSalientes` pendientes via API y enviarlos a Visions
- Recibir eventos de ventas de Visions y registrarlos en `Integracion.EventosEntrantes`
- Procesar eventos entrantes invocando `Integracion.sp_ProcesarEventoEntrante`

---

## 4. Organización Interna de NexoApi — Feature Slices

Cada módulo de negocio es un "slice" independiente:

```
Features/
└── Produccion/
    ├── Dtos/
    │   └── OrdenProduccionDtos.cs    ← todos los records del módulo
    ├── OrdenesProduccionService.cs   ← interface + implementación (mismo archivo)
    └── OrdenesProduccionController.cs ← [ApiController] [Route] [Authorize]
```

**Regla**: un módulo no importa clases de otro módulo (excepto DTOs de Catálogo que son compartidos entre varios módulos).

### Registro en Program.cs

```csharp
// Infraestructura (Singleton — una conexión factory para toda la app)
builder.Services.AddSingleton<IDbConnectionFactory, SqlConnectionFactory>();

// Servicios de negocio (Scoped — uno por request HTTP)
builder.Services.AddScoped<IOrdenesProduccionService, OrdenesProduccionService>();
builder.Services.AddScoped<IInventarioService, InventarioService>();
// ... resto de módulos
```

---

## 5. Organización Interna de NexoWeb

### Flujo de autenticación en el cliente

```
Program.cs registra:
  - AuthStateService (Scoped) — estado de sesión en memoria
  - CustomAuthStateProvider (Scoped) — provee el ClaimsPrincipal a Blazor
  - NexoApiClient (Scoped via HttpClient) — cliente HTTP tipado

Al montar el circuito (InicializadorSesion.razor):
  → AuthStateService.InicializarAsync()
  → Lee ProtectedSessionStorage["nexo_sesion"]
  → Si existe, restaura Token, Nombre, Rol, CentroCostoId
  → NotifyAuthenticationStateChanged()
  → AuthorizeView / NavMenu se actualizan

En cada request HTTP (NexoApiClient):
  → AgregarTokenAsync() → agrega "Authorization: Bearer {token}"
  → Si respuesta 401 → CerrarSesionAsync() + redirect a /login
  → Si error → leer { "error": "..." } y lanzar HttpRequestException
```

### Comunicación de estado entre componentes

No hay state management global (Flux/Redux). El estado local está en cada componente. Para comunicación entre página y diálogo se usa `DialogResult.Ok(dato)`.

---

## 6. Seguridad

### Autenticación de usuarios (JWT)

- Algoritmo: HMAC-SHA256
- Emisor: `NexoApi` | Audiencia: `NexoClients`
- Expiración: 60 minutos (access token), 7 días (refresh token)
- Claims: `sub` (UsuarioID), `unique_name` (username), `role`, `CentroCostoId`
- Clave en `appsettings.json["Jwt:Key"]`

### Autenticación de NexoSyncAgent (ApiKey)

- Header: `X-Api-Key: {clave-raw}`
- Se hace SHA256 de la clave y se compara con `Integracion.AgentesSync.ApiKeyHash`
- Claim resultante: `CentroCostoId` del agente
- Al autenticarse: actualiza `UltimaConexion` en la BD

### Hashing de contraseñas

- Clase `PasswordHasher` (custom, archivo `Common/Security/PasswordHasher.cs`)
- Usa `PBKDF2` con salt aleatorio
- Almacena `varbinary(256)` (hash) y `varbinary(128)` (salt) en `Seguridad.Usuarios`

---

## 7. Dependencias entre Proyectos

```
NexoApi
  ├── Dapper 2.1.79
  ├── Microsoft.Data.SqlClient 7.0.2
  ├── Microsoft.AspNetCore.Authentication.JwtBearer 10.0.10
  ├── System.IdentityModel.Tokens.Jwt 8.22.0
  ├── Microsoft.OpenApi 1.6.22
  └── Swashbuckle.AspNetCore 6.6.2

NexoWeb
  └── MudBlazor 7.15.0
      (MudBlazor incluye todo lo de MudBlazor internamente; no hay más packages)

NexoSyncAgent
  ├── Microsoft.Data.SqlClient (para Visions)
  └── HttpClient hacia NexoApi
```

---

## 8. Módulos y sus Endpoints

### Auth (`/api/auth`)

| Método | Ruta | Rol | Descripción |
|---|---|---|---|
| POST | `/registrar` | Público (solo si no hay usuarios) | Crea el primer admin |
| POST | `/login` | Público | Login, devuelve JWT |
| GET | `/usuarios` | Administrador | Lista usuarios |
| POST | `/usuarios` | Administrador | Crea usuario |
| PUT | `/usuarios/{id}` | Administrador | Actualiza usuario |
| POST | `/usuarios/{id}/resetear-password` | Administrador | Resetea contraseña |
| GET | `/roles` | Administrador | Lista roles activos |

### Catálogo (`/api/catalogo`)

| Método | Ruta | Rol | Descripción |
|---|---|---|---|
| GET | `/articulos` | Autenticado | Lista artículos (filtro: tipoArticuloId) |
| POST | `/articulos` | Administrador | Crea artículo |
| PUT | `/articulos/{id}` | Administrador | Actualiza artículo |
| GET | `/tipos-articulo` | Autenticado | Lista tipos de artículo |
| GET | `/unidades-medida` | Autenticado | Lista unidades |
| GET | `/bodegas` | Autenticado | Lista bodegas |
| POST | `/bodegas` | Administrador | Crea bodega |
| GET | `/centros-costo` | Autenticado | Lista centros de costo |
| POST | `/centros-costo` | Administrador | Crea centro de costo |
| PUT | `/centros-costo/{id}` | Administrador | Actualiza centro de costo |
| GET | `/clientes` | Autenticado | Lista clientes |
| POST | `/clientes` | Administrador | Crea cliente |
| PUT | `/clientes/{id}` | Administrador | Actualiza cliente |
| GET | `/proveedores` | Autenticado | Lista proveedores |
| POST | `/proveedores` | Administrador | Crea proveedor |
| PUT | `/proveedores/{id}` | Administrador | Actualiza proveedor |
| GET | `/centros-trabajo` | Autenticado | Lista centros de trabajo |

### Producción (`/api/produccion`)

| Método | Ruta | Rol | Descripción |
|---|---|---|---|
| GET | `/ordenes` | Autenticado | Lista OPs (filtro: centroCostoId, estado) |
| POST | `/ordenes` | Admin, Supervisor | Crea OP |
| GET | `/ordenes/{id}` | Autenticado | Detalle de OP |
| POST | `/ordenes/{id}/liberar` | Admin, Supervisor | Libera OP (Planificada→Liberada) |
| POST | `/ordenes/{id}/iniciar` | Admin, Supervisor, Operario | Inicia OP (→En Proceso) |
| POST | `/ordenes/{id}/cerrar` | Admin, Supervisor | Cierra OP (→Finalizada) |
| GET | `/ordenes/{id}/consumos` | Autenticado | Lista consumos de MP de la OP |
| PATCH | `/ordenes/consumo/{consumoId}` | Admin, Supervisor | Ajusta cantidad real consumida |
| GET | `/ordenes/motivos-exceso` | Autenticado | Lista motivos de exceso de consumo |
| GET | `/ordenes/tipos-produccion` | Autenticado | Lista tipos de producción |
| GET | `/recetas` | Admin, Supervisor | Lista recetas BOM |
| POST | `/recetas` | Admin, Supervisor | Crea receta |
| GET | `/recetas/{id}` | Admin, Supervisor | Detalle de receta con líneas |

### Inventario (`/api/inventario`)

| Método | Ruta | Rol | Descripción |
|---|---|---|---|
| GET | `/stock` | Autenticado | Stock consolidado (filtros varios) |
| GET | `/kardex` | Admin, Supervisor, Bodeguero | Kardex de movimientos (TOP 500) |
| GET | `/motivos-perdida` | Admin, Bodeguero | Lista motivos de baja |
| POST | `/bajas` | Admin, Bodeguero | Registra baja de inventario |
| GET | `/traspasos` | Admin, Bodeguero | Lista traspasos |
| POST | `/traspasos` | Admin, Bodeguero | Crea traspaso |
| POST | `/traspasos/{id}/recibir` | Admin, Bodeguero | Recibe traspaso |

### Compras (`/api/compras`)

| Método | Ruta | Rol | Descripción |
|---|---|---|---|
| GET | `/ordenes` | Admin, Bodeguero | Lista OCs |
| POST | `/ordenes` | Admin, Bodeguero | Crea OC |
| POST | `/ordenes/{id}/recibir-linea` | Admin, Bodeguero | Recibe una línea de OC |

### Dashboard / Business Intelligence (`/api/dashboard`)

| Método | Ruta | Rol | Descripción |
|---|---|---|---|
| GET | `/plan-vs-real?dias=14` | Admin, Supervisor, Bodeguero | Serie planificado vs real |
| GET | `/distribucion-centro-costo` | Admin, Supervisor, Bodeguero | Distribución de producción por CC |
| GET | `/perdidas-por-motivo?dias=30` | Admin, Supervisor, Bodeguero | Pérdidas agrupadas por motivo |
| GET | `/tendencia-costo?articuloId=X` | Admin, Supervisor, Bodeguero | Tendencia de costo unitario por producto |
| GET | `/cumplimiento-planificacion` | Admin, Supervisor, Bodeguero | % cumplimiento por centro de costo |
| GET | `/resumen-crm?desde=&hasta=` | Administrador | Clientes nuevos + interacciones (agosto 2026) |
| GET | `/empleados-por-centro-costo` | Administrador | Conteo de empleados activos por CC (agosto 2026) |
| GET | `/resumen-planificacion` | Admin, Supervisor, Bodeguero | % cumplimiento Demanda/Venta del mes actual (agosto 2026) |
| GET | `/resumen-inventario` | Admin, Supervisor, Bodeguero | Valor total de stock + artículos con alerta (agosto 2026) |
| POST | `/exportar/excel`, `/exportar/pdf` | Admin, Supervisor, Bodeguero | Exportación del Dashboard (`DashboardExportService`) |

### Traspasos (`/api/inventario/traspasos` — nota: comparte controller con Inventario)

Ver tabla de Inventario arriba — Traspasos vive como feature slice propio (`Features/Traspasos/`) pero expone rutas bajo `/api/inventario/traspasos` por historia del proyecto.

### CRM (`/api/crm`) — agosto 2026

| Método | Ruta | Rol | Descripción |
|---|---|---|---|
| GET | `/clientes` | Admin, Bodeguero, Supervisor | Lista clientes (filtros: responsable, tipo, fuente, activos) |
| POST/PUT | `/clientes[/{id}]` | Administrador | Crear/editar cliente |
| GET/POST | `/clientes/{id}/interacciones`, `/interacciones` | Administrador | Bitácora de interacciones |
| GET/POST/PUT | `/clientes/{id}/contactos`, `/contactos[/{id}]` | Administrador | Múltiples contactos por cliente |
| GET | `/clientes/{id}/historial` | Administrador | Timeline unificado (interacciones + pedidos + despachos) |
| GET/POST/DELETE | `/clientes/{id}/documentos`, `/documentos/{id}` | Administrador | Documentos adjuntos (descarga autenticada) |
| GET/POST/PUT | `/leads[/{id}]` | Administrador | Pipeline de prospectos |
| POST | `/leads/{id}/convertir` | Administrador | Convierte Lead → Cliente (transacción) |
| GET | `/clientes-frios?diasSinContacto=30` | Administrador | Alerta interna de clientes sin contacto reciente |

### RRHH (`/api/rrhh`) — agosto 2026

| Método | Ruta | Rol | Descripción |
|---|---|---|---|
| GET | `/empleados` | Admin, Supervisor | Lista empleados |
| POST/PUT | `/empleados[/{id}]` | Administrador | Crear/editar empleado (dispara Historial Laboral automático) |
| GET/PUT/DELETE | `/empleados/{id}/foto`, `/documentos`, `/historial`, `/evaluaciones`, `/capacitaciones`, `/organigrama` | Administrador | Sub-recursos del empleado |
| GET/POST/PUT | `/departamentos[/{id}]`, `/cargos[/{id}]` | Admin (lectura: +Supervisor) | Estructura organizacional |
| GET/POST/PUT | `/ausencias[/{id}/estado]` | Administrador | Vacaciones/incapacidades/permisos, sin cálculo de nómina |

### Planificación (`/api/planificacion`) — ampliado agosto 2026

| Método | Ruta | Rol | Descripción |
|---|---|---|---|
| GET/POST/PUT | `/demanda[/{id}]` | Admin, Supervisor | Demanda proyectada vs real (Kardex ENTRADA_PT) |
| GET | `/demanda/sugerencia` | Admin, Supervisor | Promedio de los últimos 3 meses reales |
| GET/POST/PUT | `/metas-venta[/{id}]` | Admin, Supervisor | Meta comercial vs venta real (Kardex SALIDA_VENTA_VISIONS) |
| GET | `/metas-venta/{id}/historial` | Admin, Supervisor | Versionado de metas (valor anterior antes de cada cambio) |
| GET | `/desviaciones?umbral=70` | Admin, Supervisor | Alerta interna de Centros de Costo por debajo del umbral |
| GET | `/historico-cumplimiento?meses=12` | Admin, Supervisor | Serie histórica de cumplimiento Demanda/Venta |

### Logística (`/api/logistica`) — agosto 2026

| Método | Ruta | Rol | Descripción |
|---|---|---|---|
| GET/POST | `/despachos` | Admin, Bodeguero | Despachos a cliente — **descuenta stock real** (FEFO), a diferencia de un registro documental |
| POST | `/despachos/{id}/confirmar-entrega` | Admin, Bodeguero | Marca DESPACHADO → ENTREGADO |
| POST | `/despachos/{id}/anular` | Admin, Bodeguero | Revierte stock del despacho (SP `sp_AnularDespacho`) |

### Proyectos (`/api/proyectos`) — ampliado agosto 2026

| Método | Ruta | Rol | Descripción |
|---|---|---|---|
| GET/POST/PUT | `/[{id}]` | Admin, Supervisor | Proyectos (con Prioridad, % Hitos/Tareas) |
| GET/POST/PUT | `/{proyectoId}/tareas`, `/tareas[/{id}]` | Admin, Supervisor | Tareas (Kanban), con dependencias entre tareas |
| GET/POST/PUT | `/{proyectoId}/hitos`, `/hitos[/{id}]` | Admin, Supervisor | Fases/hitos del proyecto |
| GET/POST | `/{proyectoId}/costos`, `/costos` | Admin, Supervisor | Costos manuales (mano de obra/material/otro) — sin cálculo automático |
| GET/POST/DELETE | `/{proyectoId}/documentos`, `/documentos/{id}` | Admin, Supervisor | Documentos adjuntos |
| GET/POST | `/{proyectoId}/comentarios`, `/comentarios` | Admin, Supervisor | Bitácora del proyecto |
| GET | `/alertas` | Admin, Supervisor | Proyectos atrasados o con sobrecosto |

### Facturación (`/api/facturacion`) — nuevo, agosto 2026

| Método | Ruta | Rol | Descripción |
|---|---|---|---|
| GET/POST | `/facturas` | Admin, Bodeguero | Registro de ventas — **no descuenta stock ni toca Kardex**, independiente de Logística |
| GET | `/facturas/{id}/lineas`, `/{id}/pagos` | Admin, Bodeguero | Detalle de una factura |
| POST | `/pagos` | Admin, Bodeguero | Registra abono — Estado (Pagada/Parcial/Pendiente) se calcula, nunca se guarda fijo |

### Notificaciones (`/api/notificaciones`)

| Método | Ruta | Rol | Descripción |
|---|---|---|---|
| GET | `/resumen` | Autenticado | Resumen agregado por categoría — **hoy solo cubre Sin Stock/Bajo Stock/Órdenes en Proceso**, ver auditoría (`docs/AUDITORIA_2026.md` sección 5.5) para el gap de módulos nuevos sin conectar |

### Búsqueda (`/api/busqueda`)

| Método | Ruta | Rol | Descripción |
|---|---|---|---|
| GET | `?q=texto` | Autenticado | Búsqueda global — **hoy solo cubre Stock, Traspasos, Artículos, Clientes, Proveedores, Centros de Costo, Bodegas, Órdenes de Producción/Compra**, ver auditoría sección 5.2 para el gap |

### Preferencias (`/api/preferencias`) y Configuración (`/api/configuracion`)

| Método | Ruta | Rol | Descripción |
|---|---|---|---|
| GET/PUT | `/preferencias[/{clave}]` | Autenticado | Preferencias por usuario, clave/valor genérico (tema, vista, favoritos) |
| GET/PUT | `/configuracion/empresa` | Administrador | Nombre/logo de empresa (fila única, global) |

---

## 9. Ciclo de Vida de una Orden de Producción

```
              ┌─────────────┐
              │  Planificada │  (estado inicial al crear)
              └──────┬──────┘
                     │ sp_LiberarOrdenProduccion
                     │ • Valida stock de MP
                     │ • Reserva cantidades teóricas
                     ▼
              ┌─────────────┐
              │   Liberada   │
              └──────┬──────┘
                     │ sp_IniciarOrdenProduccion
                     │ • Descuenta stock de MP del inventario
                     │ • Registra movimientos en Kardex (salida)
                     │ • Crea registros en OrdenesProduccionConsumo
                     ▼
              ┌─────────────┐
              │  En Proceso  │  ← Ajuste de consumo disponible (PATCH)
              └──────┬──────┘
                     │ sp_CerrarOrdenProduccion
                     │ • Calcula costo real (materiales + MOD + CIF)
                     │ • Ingresa PT al inventario (Kardex entrada)
                     │ • Crea lote de PT
                     │ • Genera evento saliente para Visions
                     ▼
              ┌─────────────┐
              │  Finalizada  │
              └─────────────┘
```
