# Resumen de Sesión de Desarrollo — NEXO ERP

**Fecha**: 2026-08-01
**Objetivo**: Revisión completa del proyecto (BD → API → Web) y corrección de inconsistencias (Fase 1) + implementación de funcionalidades faltantes (Fase 2).

---

## 1. Cambios Realizados

### Fase 1 — Correcciones de Integridad

#### Base de Datos
- Script `sqlportablenexo.sql` actualizado para ser portable (sin rutas de archivo fijas)
- Connection string actualizado a nueva instancia: `DESKTOP-V83PQ7M\JONATHAN`

#### NexoApi

| Archivo | Cambio |
|---|---|
| `appsettings.json` | Nueva instancia SQL: `DESKTOP-V83PQ7M\JONATHAN` |
| `ExceptionHandlingMiddleware.cs` | Error 51020 → 404 (antes caía en el handler genérico de 50000 → 400) |
| `CatalogoDtos.cs` | `ArticuloItem` expandido con campo `DiasVidaUtil`; eliminado `TipoArticuloItemm` (duplicado con doble m) |
| `CatalogoDtos.cs` | `ClienteItem` expandido de 2 a 8 campos; `ProveedorItem` expandido de 2 a 8 campos; DTOs de request CRUD para Clientes y Proveedores |
| `ComprasDtos.cs` | Eliminado `ProveedorItem` duplicado (existía en 2 archivos) |
| `CatalogoService.cs` | `ListarClientesAsync()`: query expandida a 8 campos; `ListarProveedoresAsync()`: query expandida a 8 campos |
| `CatalogoService.cs` | Agregados: `CrearClienteAsync`, `ActualizarClienteAsync`, `CrearProveedorAsync`, `ActualizarProveedorAsync` |
| `ClientesYCentrosTrabajoController.cs` | Agregados: `POST /api/catalogo/clientes`, `PUT /api/catalogo/clientes/{id}`, `POST /api/catalogo/proveedores`, `PUT /api/catalogo/proveedores/{id}` |

#### NexoWeb

| Archivo | Cambio |
|---|---|
| `CatalogoDtos.cs` | Espejo de los cambios del API: `ClienteItem` y `ProveedorItem` expandidos + DTOs de request |
| `ComprasDtos.cs` | Eliminado `ProveedorItem` (ahora solo en CatalogoDtos.cs) |

### Fase 2 — Funcionalidades Nuevas

#### NexoApi — Nuevos endpoints y servicios

| Módulo | Qué se agregó |
|---|---|
| Producción | `GET /api/produccion/ordenes/{id}/consumos` — lista consumos de MP de una OP |
| Producción | `PATCH /api/produccion/ordenes/consumo/{consumoId}` — ajusta cantidad real consumida |
| Producción | `GET /api/produccion/ordenes/motivos-exceso` — lista motivos de exceso |
| Dashboard | `GET /api/dashboard/cumplimiento-planificacion` — % cumplimiento por centro de costo |
| Inventario | `GET /api/inventario/kardex` — consulta de movimientos (TOP 500, filtros opcionales) |

DTOs nuevos en NexoApi:
- `ConsumoOpItem`, `MotivoExcesoItem`, `AjustarConsumoRealRequest` (en `OrdenProduccionDtos.cs`)
- `CumplimientoCentroCostoItem` (en `DashboardDtos.cs`)
- `KardexMovimientoItem` (en `InventarioDtos.cs`)

#### NexoWeb — Nuevos componentes

| Componente | Ruta | Descripción |
|---|---|---|
| `ConsultaKardex.razor` | `/inventario/kardex` | Filtros + tabla de hasta 500 movimientos, chips color por tipo de movimiento |
| `Clientes.razor` | `/catalogo/clientes` | CRUD completo de clientes |
| `ClienteDialog.razor` | — | Diálogo crear/editar cliente |
| `Proveedores.razor` | `/catalogo/proveedores` | CRUD completo de proveedores |
| `ProveedorDialog.razor` | — | Diálogo crear/editar proveedor |
| `AjustarConsumoDialog.razor` | — | Diálogo para ajustar consumo real de MP en OP en proceso |
| `TraspasoDetalleDialog.razor` | — | Diálogo de confirmación de recepción de traspaso con detalle |

#### NexoWeb — Mejoras a componentes existentes

| Componente | Cambio |
|---|---|
| `ListaOrdenes.razor` | Confirmación con `ShowMessageBox` antes de iniciar OP; botón "Ajustar Consumo" en OPs En Proceso |
| `RegistrarBaja.razor` | Confirmación con detalle completo (artículo, bodega, cantidad, motivo) antes de registrar |
| `ListaTraspasos.razor` | Recepción de traspaso muestra `TraspasoDetalleDialog` antes de confirmar |
| `Dashboard.razor` | Nueva sección de cumplimiento de planificación con tabla + chips de color |
| `NavMenu.razor` | Agregados links: Kardex (Inventario), Clientes (Catálogo), Proveedores (Catálogo) |

#### NexoWeb — Infraestructura

| Archivo | Cambio |
|---|---|
| `INexoApiClient.cs` | Agregado `PatchAsync<TRequest, TResponse>` a la interfaz |
| `NexoApiClient.cs` | Implementación de `PatchAsync` usando `HttpClient.PatchAsJsonAsync` |
| `ProduccionDtos.cs` | Agregados `ConsumoOpItem`, `MotivoExcesoItem`, `AjustarConsumoRealRequest` |
| `DashboardDtos.cs` | Agregado `CumplimientoCentroCostoItem` |
| `InventarioDtos.cs` | Agregado `KardexMovimientoItem` |

---

## 2. Problemas Encontrados y Cómo se Resolvieron

| Problema | Causa | Solución |
|---|---|---|
| `IMudDialogInstance` (CS0246) | El tipo correcto en MudBlazor 7.x es `MudDialogInstance`, no `IMudDialogInstance` | `replace_all` en los 4 archivos de diálogo nuevos |
| `ProveedorItem` duplicado | Existía en `ComprasDtos.cs` (2 campos) y se agregó en `CatalogoDtos.cs` (8 campos) — mismo namespace, colisión | Eliminado del archivo de Compras; consolidado en CatalogoDtos |
| Error 51020 mapeando a 400 | El middleware procesaba todos los errores 50000-59999 como 400/409 sin excepción para el 51020 | Agregado `if (ex.Number is 51020) { WriteResponse 404; return; }` antes del handler genérico |
| `PatchAsync` no disponible | No existía en `INexoApiClient` | Agregado a interfaz e implementación |
| NexoWeb no alcanzaba la API en entorno de prueba | `appsettings.json` tenía `https://localhost:7144/` pero el servidor de prueba corrió en `http://localhost:5000` | `appsettings.json` cambiado a `http://localhost:5000/` para pruebas — **restaurado a `https://localhost:7144/` al cerrar sesión** |
| Login fallaba en entorno de prueba | El sandbox de Claude no tiene acceso al SQL Server real del usuario | Prueba manual realizada por el usuario en su máquina |

---

## 3. Decisiones de Arquitectura

1. **Sin cambio de patrón**: todos los elementos nuevos siguen exactamente el mismo patrón que los existentes (Dapper raw, Feature Slice, record positional, MudDialogInstance, etc.)

2. **ClienteItem / ProveedorItem expandidos con backward compatibility**: los campos existentes mantienen exactamente el mismo orden positional en el record, nuevos campos se agregan al final. Las páginas existentes que solo accedían a los primeros 2 campos siguen funcionando sin cambios.

3. **Kardex con TOP 500**: el kardex puede tener miles de filas. En lugar de paginación (que requeriría más infraestructura), se limita a los 500 movimientos más recientes. Los filtros de artículo, bodega y fechas reducen el conjunto antes del TOP.

4. **Confirmaciones obligatorias**: todas las operaciones irreversibles (iniciar OP, recibir traspaso, registrar baja) tienen confirmación explícita del usuario antes de llamar al API.

5. **ExceptionHandlingMiddleware como único punto de manejo de errores**: no hay try/catch en los controladores ni en los servicios para errores de negocio. Los SPs lanzan THROW y el middleware los captura.

---

## 4. Estado del Proyecto al Cierre de Sesión

### Módulos completados (funcionalidad completa BD → API → Web)

| Módulo | Estado |
|---|---|
| Autenticación y gestión de usuarios | ✅ Completo |
| Dashboard (5 KPIs) | ✅ Completo |
| Catálogo — Artículos | ✅ Completo |
| Catálogo — Bodegas | ✅ Completo |
| Catálogo — Centros de Costo | ✅ Completo |
| Catálogo — Clientes | ✅ Completo (agregado en Fase 2) |
| Catálogo — Proveedores | ✅ Completo (agregado en Fase 2) |
| Inventario — Consulta de Stock | ✅ Completo |
| Inventario — Consulta Kardex | ✅ Completo (agregado en Fase 2) |
| Inventario — Registrar Baja | ✅ Completo |
| Inventario — Traspasos | ✅ Completo |
| Compras — Órdenes de Compra | ✅ Completo |
| Producción — Recetas BOM | ✅ Completo |
| Producción — Órdenes de Producción (ciclo completo) | ✅ Completo |
| Producción — Ajuste de Consumo Real | ✅ Completo (agregado en Fase 2) |
| Integración con Visions (agente) | ✅ Completo (NexoSyncAgent independiente) |

---

## 5. Pendientes / Fase 3

### Alta Prioridad

| # | Item | Archivo | Descripción |
|---|---|---|---|
| 1 | `UsuarioDialog` — CentroCostoID como Select | `Admin/UsuarioDialog.razor` | Actualmente es un `MudNumericField` libre; debería ser `<MudSelect>` que carga `/api/catalogo/centros-costo` |
| 2 | Endpoint `/api/auth/refresh-token` | `Auth/AuthController.cs`, `AuthService.cs` | El refresh token se genera y almacena en BD pero no hay endpoint para renovar el access token. Actualmente la sesión expira a los 60 min sin opción de renovación automática. |
| 3 | DataAnnotations en Request DTOs | `NexoApi/Features/*/Dtos/*.cs` | Ningún DTO de request tiene `[Required]`, `[MaxLength]`, `[Range]` etc. La validación de formato ocurre en la BD o no ocurre. |

### Media Prioridad

| # | Item | Descripción |
|---|---|---|
| 4 | Checkbox "Recordarme" en Login | `Auth/Login.razor` — el checkbox existe en la UI pero no hace nada. Si se activa, debería usar `ProtectedLocalStorage` en lugar de `ProtectedSessionStorage` para que la sesión persista entre pestañas y reinicios del navegador. |
| 5 | `Auditoria.LogAuditoria` | La tabla existe y está diseñada correctamente, pero nunca se escribe. Agregar llamadas desde los servicios críticos (crear/editar artículos, usuarios, OPs, etc.). |
| 6 | Kardex — paginación real | Actualmente TOP 500. Si el volumen crece, considerar paginación con `OFFSET/FETCH`. |

### Baja Prioridad

| # | Item | Descripción |
|---|---|---|
| 7 | `TipoArticuloID` hardcodeado | En `Dashboard.razor` se filtra `?tipoArticuloId=3` hardcodeado para "Producto Terminado". Debería venir de la tabla `catalogo.TiposArticulo`. |
| 8 | Página 404 personalizada | `NotFound.razor` existe pero no tiene diseño del sistema (usa el layout por defecto). |
| 9 | NavMenu — Dashboard sin `AuthorizeView` explícito | El link del Dashboard visible para todos los autenticados; está manejado por `@attribute [Authorize(Roles=...)]` en la página, que es correcto, pero el NavMenu podría ser más limpio con `<AuthorizeView>` explícito. |

---

## 6. Bugs Conocidos

| Bug | Impacto | Estado |
|---|---|---|
| Sesión no se renueva automáticamente | Al expirar los 60 min del JWT, el usuario es redirigido al login sin aviso previo | Conocido — requiere implementar refresh token (Pendiente #2) |
| Kardex no muestra Lote | `KardexMovimientoItem` no incluye `NumeroLote`; la consulta SQL hace JOIN con Lotes pero no retorna el campo | Menor — fácil de agregar cuando se requiera |

---

## 7. Riesgos Técnicos

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Crecimiento del Kardex sin índices secundarios | Alta (con el tiempo) | Medio (queries lentas) | Agregar índice en (ArticuloID, BodegaID, Fecha) en KardexMovimientos |
| JWT sin rotación | Media | Alto (si el token se filtra) | Implementar refresh token y rotación |
| Sin DataAnnotations en DTOs | Baja (la BD valida) | Bajo (errores llegan al usuario como 400/409 con mensaje) | Agregar anotaciones para validación anticipada |
| Contraseña JWT en appsettings.json sin cifrado | Baja (servidor local) | Alto (si el repo se sube a GitHub) | Mover a variables de entorno o Azure Key Vault en producción |

---

## 8. Comandos Útiles para la Próxima Sesión

```bash
# Compilar todo el proyecto
dotnet build C:\Produccion\NexoApi\NexoApi.csproj
dotnet build C:\Produccion\NexoWeb\NexoWeb.csproj

# Verificar que appsettings de NexoWeb apunte al API correcto
cat C:\Produccion\NexoWeb\appsettings.json
# Debe tener: "BaseUrl": "https://localhost:7144/"

# Correr la BD (si se necesita recrear):
# 1. Ejecutar en SSMS: C:\Produccion\ScriptsSQL\ScriptsCompletos\sqlportablenexo.sql
#    ADVERTENCIA: elimina y recrea NEXO_ERP desde cero
# 2. Luego ejecutar: C:\Produccion\ScriptsSQL\ScriptsProcesos\DatosSemilla.sql
#    (inserta roles, tipos, estados, unidades de medida, etc.)
#    Sin este paso el primer registro de usuario falla con FK violation en Roles.

# Registrar el primer usuario admin (solo si la BD esta vacia de usuarios)
# POST https://localhost:7144/api/auth/registrar
# Body: { "nombres": "Admin", "apellidos": "Sistema", "email": "admin@nexo.com",
#         "username": "admin", "password": "Admin123!", "rolID": 1 }
```
