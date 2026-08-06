# Documentación de Base de Datos — NEXO ERP

**Instancia**: `DESKTOP-V83PQ7M\JONATHAN`
**Base de datos**: `NEXO_ERP`
**Autenticación**: Windows (Trusted Connection)
**Compatibilidad**: SQL Server 2019 (nivel 160)
**Script maestro**: `ScriptsSQL/ScriptsCompletos/sqlportablenexo.sql`
**Script de datos semilla**: `ScriptsSQL/ScriptsProcesos/DatosSemilla.sql`

> El script maestro crea solo la estructura. Ejecutar `DatosSemilla.sql` inmediatamente
> después para poblar las tablas de catálogo (Roles, TiposArticulo, UnidadesMedida, etc.).
> Sin los datos semilla, el primer registro de usuario falla con FK violation.

---

## 1. Esquemas

| Esquema | Propósito |
|---|---|
| `Auditoria` | Trazabilidad de cambios en registros críticos |
| `catalogo` | Catálogos maestros (artículos, proveedores, unidades) — minúscula por legacy. **Clientes ya NO vive aquí, se movió a `Crm`** (agosto 2026) |
| `Compras` | Órdenes de compra y recepción |
| `Crm` | Clientes (contactos comerciales) y bitácora de interacciones (agosto 2026) — movido desde `Catalogo.Clientes` vía `ALTER SCHEMA TRANSFER` |
| `Integracion` | Eventos de sincronización con Visions ERP |
| `Inventario` | Stock, bodegas, lotes, traspasos, bajas |
| `Kardex` | Registro histórico de todos los movimientos de inventario |
| `Logistica` | Despachos a clientes y guías (TMS, agosto 2026) — sin vehículos ni rutas todavía. Descuenta stock real vía `sp_CrearDespacho` |
| `Organizacion` | Centros de costo y centros de trabajo |
| `Planificacion` | Demanda proyectada de producción y metas de venta (agosto 2026) — comparado contra lo real vía subquery a Kardex, sin tabla de snapshot |
| `Produccion` | Órdenes de producción, recetas BOM, consumos |
| `Proyectos` | Proyectos, tareas y costos imputados (agosto 2026) — costos son valor $ manual, no automático desde RRHH/Inventario |
| `Rrhh` | Directorio de personal (agosto 2026) — sin nómina/contabilidad, eso vive en otro sistema del cliente |
| `Seguridad` | Usuarios, roles, permisos, sesiones |

---

## 2. Tablas por Esquema

### `Auditoria`

#### `LogAuditoria`
Registro de auditoría general. Actualmente creado pero no se escribe desde la API (pendiente de integrar).

| Columna | Tipo | Descripción |
|---|---|---|
| `LogID` | bigint PK IDENTITY | ID del log |
| `EsquemaTabla` | nvarchar(100) | Ej: `Produccion.OrdenesProduccion` |
| `RegistroID` | nvarchar(50) | ID del registro afectado |
| `Accion` | nvarchar(10) | INSERT / UPDATE / DELETE |
| `UsuarioID` | int NULL | FK → Seguridad.Usuarios |
| `Fecha` | datetime2(7) | Fecha UTC del cambio |
| `ValoresAnteriores` | nvarchar(max) NULL | JSON con valores previos |
| `ValoresNuevos` | nvarchar(max) NULL | JSON con valores nuevos |

---

### `catalogo`

#### `Articulos`
Catálogo maestro de artículos (materias primas, producto terminado, insumos).

| Columna | Tipo | Restricciones |
|---|---|---|
| `ArticuloID` | int PK IDENTITY | |
| `SKU` | nvarchar(30) | UNIQUE NOT NULL |
| `Nombre` | nvarchar(150) | NOT NULL |
| `Descripcion` | nvarchar(300) | NULL |
| `TipoArticuloID` | int | FK → catalogo.TiposArticulo |
| `UnidadID` | int | FK → catalogo.UnidadesMedida |
| `CostoPromedio` | decimal(18,4) | Calculado por los SPs de producción |
| `PrecioVenta` | decimal(18,4) | |
| `StockMinimo` | decimal(18,4) | |
| `StockMaximo` | decimal(18,4) | NULL |
| `PuntoReorden` | decimal(18,4) | Umbral para alerta `RequierePedido` |
| `DiasVidaUtil` | int | NULL — para artículos perecederos |
| `Estado` | bit | 1=Activo |
| `FechaCreacion` | datetime2(7) | |

#### `TiposArticulo`
Catálogo de tipos: Materia Prima, Producto Terminado, Insumo, etc.

| Columna | Tipo |
|---|---|
| `TipoArticuloID` | int PK IDENTITY |
| `Codigo` | nvarchar(20) UNIQUE |
| `Nombre` | nvarchar(50) |

> **Nota**: el TipoArticuloID=3 es convencionalmente Producto Terminado (usado en Dashboard para filtrar artículos al graficar tendencia de costo).

#### `UnidadesMedida`

| Columna | Tipo |
|---|---|
| `UnidadID` | int PK IDENTITY |
| `Nombre` | nvarchar(30) |
| `Abreviatura` | nvarchar(10) UNIQUE |
| `Tipo` | nvarchar(20) — CHECK: `'PESO'` / `'VOLUMEN'` / `'UNIDAD'` / `'LONGITUD'` |

#### `UnidadesConversion`
Factores de conversión entre unidades de medida.

| Columna | Tipo |
|---|---|
| `UnidadOrigenID` | int PK FK |
| `UnidadDestinoID` | int PK FK |
| `Factor` | decimal(18,8) |

#### `Proveedores`

| Columna | Tipo | Restricciones |
|---|---|---|
| `ProveedorID` | int PK IDENTITY | |
| `RazonSocial` | nvarchar(150) NOT NULL | |
| `NIT` | nvarchar(30) NOT NULL | UNIQUE |
| `Contacto` | nvarchar(100) NULL | |
| `Telefono` | nvarchar(30) NULL | |
| `Email` | nvarchar(150) NULL | |
| `Direccion` | nvarchar(200) NULL | |
| `Estado` | bit | |

#### `ArticuloProveedor`
Relación N:M entre artículos y proveedores.

| Columna | Tipo |
|---|---|
| `ArticuloID` | int PK FK |
| `ProveedorID` | int PK FK |
| `CodigoProveedor` | nvarchar(50) NULL |
| `CostoUltimaCompra` | decimal(18,4) NULL |
| `TiempoEntregaDias` | int NULL |

---

### `Compras`

#### `OrdenesCompra`

| Columna | Tipo | Restricciones |
|---|---|---|
| `OrdenCompraID` | int PK IDENTITY | |
| `Codigo` | nvarchar(30) | UNIQUE NOT NULL |
| `ProveedorID` | int | FK → catalogo.Proveedores |
| `BodegaDestinoID` | int | FK → Inventario.Bodegas |
| `EstadoOC` | nvarchar(20) | Pendiente / Parcial / Recibida / Anulada |
| `FechaEmision` | datetime2(7) | |
| `FechaRecepcion` | datetime2(7) NULL | |
| `UsuarioID` | int | FK → Seguridad.Usuarios |

#### `OrdenesCompraDetalle`

| Columna | Tipo |
|---|---|
| `OrdenCompraDetalleID` | int PK IDENTITY |
| `OrdenCompraID` | int FK |
| `ArticuloID` | int FK |
| `CantidadSolicitada` | decimal(18,4) |
| `CantidadRecibida` | decimal(18,4) |
| `CostoUnitario` | decimal(18,4) |
| `LoteID` | int NULL FK |

---

### `Integracion`

#### `AgentesSync`
Registro de agentes NexoSyncAgent autorizados.

| Columna | Tipo | Descripción |
|---|---|---|
| `AgenteSyncID` | int PK IDENTITY | |
| `CentroCostoID` | int FK | Centro de costo que maneja este agente |
| `ApiKeyHash` | char(64) UNIQUE | SHA256 del API key en hex |
| `Descripcion` | nvarchar(150) NULL | |
| `Activo` | bit | |
| `FechaCreacion` | datetime2(7) | |
| `UltimaConexion` | datetime2(7) NULL | Se actualiza en cada autenticación |

#### `EventosSalientes`
Eventos generados en NEXO que deben enviarse a Visions (salida de inventario por cierre de OP).

| Columna | Tipo |
|---|---|
| `EventoID` | bigint PK IDENTITY |
| `TipoEvento` | nvarchar(50) |
| `CentroCostoID` | int FK |
| `ArticuloID` | int FK |
| `Cantidad` | decimal(18,4) |
| `CostoUnitario` | decimal(18,4) |
| `KardexID` | bigint NULL FK |
| `Estado` | nvarchar(20) — PENDIENTE / ENVIADO / ERROR |
| `IntentosEnvio` | int |
| `UltimoError` | nvarchar(500) NULL |
| `FechaCreacion` | datetime2(7) |
| `FechaEnvio` | datetime2(7) NULL |

#### `EventosEntrantes`
Eventos recibidos de Visions (ventas que deben descontar inventario en NEXO).

| Columna | Tipo |
|---|---|
| `EventoEntranteID` | bigint PK IDENTITY |
| `IdEventoExterno` | nvarchar(150) UNIQUE |
| `TipoEvento` | nvarchar(50) |
| `CentroCostoID` | int FK |
| `CodigoArticuloVisions` | nvarchar(30) |
| `Cantidad` | decimal(18,4) |
| `FechaEventoOrigen` | datetime2(7) |
| `Procesado` | bit |
| `FechaRecepcion` | datetime2(7) |
| `FechaProcesado` | datetime2(7) NULL |
| `NombreArticuloVisions` | nvarchar(255) NULL | Agregado agosto 2026 — nombre del artículo tal como lo tenía Visions (`dbo.TARJETA.DETALLE`) al momento de la venta, viaja desde `TareaExportarVentas` |
| `CostoArticuloVisions` | decimal(18,4) NULL | Agregado agosto 2026 — `dbo.TARJETA.COSTO` al momento de la venta |
| `PrecioArticuloVisions` | decimal(18,4) NULL | Agregado agosto 2026 — `dbo.TARJETA.PPUBLICO` al momento de la venta |

Estas 3 columnas nuevas solo se usan si el artículo no está mapeado todavía (ver `Integracion.ArticulosPendientesMapeo` abajo) — sirven de sugerencia para que el Administrador no tenga que ir a consultar Visions manualmente.

#### `MapeoArticulos`
Mapeo entre artículos de NEXO y códigos de Visions. Solo aplica a `Catalogo.Articulos` con `TipoArticulo = 'Producto Terminado'` (validado en `IntegracionService.CrearMapeoAsync`) — Visions es un sistema de punto de venta, Materia Prima/Insumos/Servicios nunca se venden ahí.

| Columna | Tipo | Restricciones |
|---|---|---|
| `MapeoID` | int PK IDENTITY | |
| `ArticuloID` | int | UNIQUE(ArticuloID, CentroCostoID) |
| `CentroCostoID` | int | UNIQUE(CentroCostoID, CodigoArticuloVisions) |
| `CodigoArticuloVisions` | nvarchar(30) | |
| `Estado` | bit | |
| `FechaCreacion` | datetime2(7) | |

Crear una fila aquí (vía `POST api/integracion/mapeos`, pantalla `catalogo/mapeo-articulos-visions`) encola automáticamente un `Integracion.EventosSalientes` con `TipoEvento='SINCRONIZAR_ARTICULO'` para que el agente cree/actualice el artículo en `dbo.TARJETA` de Visions.

#### `ArticulosPendientesMapeo` (agosto 2026)
Cola de revisión: artículos que Visions reportó vendidos pero que todavía no tienen fila en `MapeoArticulos`. Se llena desde `Integracion.sp_ProcesarEventoEntrante` cuando no encuentra el mapeo (en vez de fallar con `THROW`). El Administrador los revisa en `catalogo/mapeo-articulos-visions` y decide vincularlos a un Producto Terminado existente o crear uno nuevo con los datos sugeridos.

| Columna | Tipo | Restricciones |
|---|---|---|
| `PendienteID` | int PK IDENTITY | |
| `CentroCostoID` | int FK | UNIQUE(CentroCostoID, CodigoArticuloVisions) |
| `CodigoArticuloVisions` | nvarchar(30) | |
| `NombreVisions` | nvarchar(255) NULL | |
| `CostoVisions` | decimal(18,4) NULL | |
| `PrecioVisions` | decimal(18,4) NULL | |
| `CantidadDetectada` | decimal(18,4) | Última cantidad vendida detectada (informativo, no acumula) |
| `FechaDetectado` | datetime2(7) | |
| `Resuelto` | bit | |
| `FechaResuelto` | datetime2(7) NULL | |

#### `InventarioReportadoVisions`
Control de cantidades vendidas reportadas a Visions.

| Columna | Tipo |
|---|---|
| `ArticuloID` | int PK |
| `CentroCostoID` | int PK |
| `CantidadVendidaAcumulada` | decimal(18,4) |
| `UltimaActualizacion` | datetime2(7) |

---

### `Inventario`

#### `Bodegas`

| Columna | Tipo | Valores |
|---|---|---|
| `BodegaID` | int PK IDENTITY | |
| `Nombre` | nvarchar(100) NOT NULL | |
| `CentroCostoID` | int FK | |
| `TipoBodega` | nvarchar(20) | MP / PT / General |
| `EsVirtual` | bit | Para bodegas de tránsito |
| `Estado` | bit | |

#### `Lotes`
Trazabilidad por número de lote.

| Columna | Tipo | Restricciones |
|---|---|---|
| `LoteID` | int PK IDENTITY | |
| `ArticuloID` | int FK | UNIQUE(ArticuloID, NumeroLote) |
| `NumeroLote` | nvarchar(50) | |
| `FechaFabricacion` | date NULL | |
| `FechaVencimiento` | date NULL | |
| `ProveedorID` | int NULL FK | |
| `Estado` | nvarchar(20) | Activo / Agotado / Vencido |
| `FechaCreacion` | datetime2(7) | |

#### `InventarioStock`
Saldo actual de inventario por artículo + bodega + lote.

| Columna | Tipo | Restricciones |
|---|---|---|
| `InventarioID` | int PK IDENTITY | |
| `ArticuloID` | int FK | UNIQUE(ArticuloID, BodegaID, LoteID) |
| `BodegaID` | int FK | |
| `LoteID` | int NULL FK | NULL = sin trazabilidad de lote |
| `CantidadActual` | decimal(18,4) | |
| `CostoUnitarioLote` | decimal(18,4) | Costo promedio ponderado |
| `FechaUltimaActualizacion` | datetime2(7) | |

#### `TraspasosBodega`

| Columna | Tipo |
|---|---|
| `TraspasoID` | int PK IDENTITY |
| `Codigo` | nvarchar(30) UNIQUE |
| `BodegaOrigenID` | int FK |
| `BodegaDestinoID` | int FK |
| `EstadoTraspaso` | nvarchar(20) — Creado / Enviado / Recibido |
| `FechaEnvio` | datetime2(7) NULL |
| `FechaRecepcion` | datetime2(7) NULL |
| `UsuarioEnviaID` | int NULL FK |
| `UsuarioRecibeID` | int NULL FK |
| `Observaciones` | nvarchar(300) NULL |
| `FechaCreacion` | datetime2(7) |

#### `TraspasosDetalle`

| Columna | Tipo |
|---|---|
| `TraspasoDetalleID` | int PK IDENTITY |
| `TraspasoID` | int FK |
| `ArticuloID` | int FK |
| `LoteID` | int NULL FK |
| `CantidadEnviada` | decimal(18,4) |
| `CantidadRecibida` | decimal(18,4) NULL |
| `CostoUnitario` | decimal(18,4) |

---

### `Kardex`

#### `KardexMovimientos`
Registro histórico e inmutable de cada movimiento de inventario.

| Columna | Tipo | Descripción |
|---|---|---|
| `KardexID` | bigint PK IDENTITY | |
| `Fecha` | datetime2(7) | Fecha del movimiento |
| `ArticuloID` | int FK | |
| `BodegaID` | int FK | |
| `LoteID` | int NULL FK | |
| `TipoMovID` | int FK | FK → TiposMovimientoKardex |
| `OrdenProduccionID` | int NULL FK | Si originó en OP |
| `TraspasoID` | int NULL FK | Si originó en traspaso |
| `OrdenCompraID` | int NULL FK | Si originó en OC |
| `BajaID` | int NULL FK | Si originó en baja |
| `CentroCostoID` | int FK | |
| `Cantidad` | decimal(18,4) | Positivo=entrada, Negativo=salida (según Signo del tipo) |
| `CostoUnitario` | decimal(18,4) | Costo en el momento del movimiento |
| `CantidadSaldo` | decimal(18,4) | Saldo acumulado en esa bodega |
| `CostoPromedioSaldo` | decimal(18,4) | Costo promedio ponderado después del movimiento |
| `ObservacionDetallada` | nvarchar(500) NULL | |
| `UsuarioID` | int FK | |
| `FechaRegistro` | datetime2(7) | Fecha de inserción del registro |

#### `TiposMovimientoKardex`

| Columna | Tipo |
|---|---|
| `TipoMovID` | int PK IDENTITY |
| `Codigo` | nvarchar(30) UNIQUE |
| `Nombre` | nvarchar(80) |
| `Signo` | smallint — 1=entrada, -1=salida |

Fila agregada agosto 2026: `Codigo='SALIDA_VENTA_VISIONS'`, `Signo=-1` — usada por `Integracion.sp_ProcesarEventoEntrante` al descontar stock por una venta reportada desde Visions.

Otra fila agregada agosto 2026: `Codigo='SALIDA_DESPACHO'`, `Signo=-1` — usada por `Logistica.sp_CrearDespacho` al descontar stock por un despacho a cliente.

Otra fila agregada agosto 2026: `Codigo='ENTRADA_ANULACION_DESPACHO'`, `Signo=1` — usada por `Logistica.sp_AnularDespacho` al devolver el stock de un despacho anulado.

#### `TiposMotivoLoss`
Catálogo de motivos de baja de inventario.

| Columna | Tipo |
|---|---|
| `MotivoID` | int PK IDENTITY |
| `Nombre` | nvarchar(100) UNIQUE |

#### `BajasInventarioPerdidas`

| Columna | Tipo | Restricciones |
|---|---|---|
| `BajaID` | int PK IDENTITY | |
| `CodigoBaja` | nvarchar(30) UNIQUE | |
| `Fecha` | datetime2(7) | |
| `ArticuloID` | int FK | |
| `BodegaID` | int FK | |
| `LoteID` | int NULL FK | |
| `CantidadPerdida` | decimal(18,4) | |
| `CostoUnitario` | decimal(18,4) | |
| `CostoTotal` | decimal(18,4) COMPUTED | CantidadPerdida × CostoUnitario (PERSISTED) |
| `MotivoID` | int FK | |
| `ObservacionDetallada` | nvarchar(500) NOT NULL | |
| `UsuarioRegistraID` | int FK | |
| `Estado` | nvarchar(20) | CONFIRMADA / ANULADA |

---

### `Crm` (agosto 2026)

#### `Clientes`
Movida desde `Catalogo.Clientes` vía `ALTER SCHEMA Crm TRANSFER Catalogo.Clientes` (preserva el FK existente desde `Produccion.OrdenesProduccion.ClienteID` automáticamente, sin tocar esa tabla). Ganó 2 columnas de seguimiento comercial.

| Columna | Tipo | Restricciones |
|---|---|---|
| `ClienteID` | int PK IDENTITY | |
| `Nombre` | nvarchar(150) NOT NULL | |
| `NIT` | nvarchar(30) NULL | |
| `Contacto` | nvarchar(100) NULL | |
| `Telefono` | nvarchar(30) NULL | |
| `Email` | nvarchar(150) NULL | |
| `Direccion` | nvarchar(200) NULL | |
| `Estado` | bit | |
| `FuenteContacto` | nvarchar(50) NULL | Agregada agosto 2026 — Referido / Redes Sociales / Llamada en Frío / Página Web / Otro |
| `TipoCliente` | nvarchar(30) NULL | Agregada agosto 2026 — Empresa / Persona Natural |
| `FechaCreacion` | datetime2 NULL | Agregada agosto 2026 (para BI, "clientes nuevos" por período) — filas migradas desde `Catalogo.Clientes` quedaron en `NULL`, solo los clientes creados después de este cambio la tienen |
| `ResponsableID` | int NULL FK → `Rrhh.Empleados` | Agregada agosto 2026 (CRM v2) — responsable comercial asignado |
| `ProximoContacto` | date NULL | Agregada agosto 2026 (CRM v2) — se agenda desde la pestaña "Bitácora" al registrar una interacción; usada por `sp`/query de clientes fríos |

**`UQ_Clientes_NIT`** (agosto 2026, CRM v2) — índice único filtrado: `CREATE UNIQUE INDEX UQ_Clientes_NIT ON Crm.Clientes(NIT) WHERE NIT IS NOT NULL AND NIT <> ''`. Permite muchos `NULL` pero rechaza NIT duplicado no vacío. Requirió `SET QUOTED_IDENTIFIER ON` explícito antes del `CREATE` (el default de `sqlcmd` lo tiene OFF, falla con error 1934 en índices filtrados).

**Nota**: la columna `Contacto` (texto libre) ya no se usa desde el código — reemplazada por la tabla `Crm.Contactos` (ver abajo). Se dejó en la tabla sin eliminar, pero no se lee/escribe.

#### `Interacciones`
Bitácora de llamadas/correos/reuniones por cliente.

| Columna | Tipo | Restricciones |
|---|---|---|
| `InteraccionID` | bigint PK IDENTITY | |
| `ClienteID` | int NOT NULL FK → `Crm.Clientes` | |
| `Tipo` | nvarchar(30) NOT NULL | Llamada / Correo / Reunion / Otro |
| `Notas` | nvarchar(1000) NOT NULL | |
| `Fecha` | datetime2(7) | |
| `UsuarioID` | int NULL FK → `Seguridad.Usuarios` | Quién la registró |

#### `Contactos` (agosto 2026, CRM v2)
Múltiples contactos por cliente (antes solo existía el campo suelto `Clientes.Contacto`). Migrado: 1 fila por cliente existente con `EsPrincipal=1`, tomando el valor de `Clientes.Contacto`.

| Columna | Tipo | Restricciones |
|---|---|---|
| `ContactoID` | int PK IDENTITY | |
| `ClienteID` | int NOT NULL FK → `Crm.Clientes` | |
| `Nombres` | nvarchar(150) NOT NULL | |
| `Cargo` | nvarchar(100) NULL | |
| `Telefono` | nvarchar(30) NULL | |
| `Email` | nvarchar(150) NULL | |
| `EsPrincipal` | bit | Máximo un principal por cliente — garantizado a nivel de aplicación (transacción en `CrmService`), no hay constraint en BD |
| `Estado` | bit | |
| `FechaCreacion` | datetime2 | |

#### `ClienteDocumentos` (agosto 2026, CRM v2)
Documentos adjuntos por cliente (RUT, Cámara de Comercio, Contrato, Otro). Límite 5MB validado en el controller. Descarga vía endpoint autenticado (no `[AllowAnonymous]`), a diferencia de imágenes de artículo/empleado.

| Columna | Tipo | Restricciones |
|---|---|---|
| `DocumentoID` | int PK IDENTITY | |
| `ClienteID` | int NOT NULL FK → `Crm.Clientes` | |
| `TipoDocumento` | nvarchar(30) NOT NULL | RUT / CAMARA_COMERCIO / CONTRATO / OTRO |
| `NombreArchivo` | nvarchar(255) NOT NULL | |
| `ContentType` | nvarchar(100) NOT NULL | |
| `Archivo` | varbinary(max) NOT NULL | |
| `FechaSubida` | datetime2 | |
| `UsuarioID` | int NULL FK → `Seguridad.Usuarios` | |

#### `Leads` (agosto 2026, CRM v2)
Pipeline de prospectos, previo a convertirse en `Clientes`.

| Columna | Tipo | Restricciones |
|---|---|---|
| `LeadID` | int PK IDENTITY | |
| `Nombre` | nvarchar(150) NOT NULL | |
| `Empresa` | nvarchar(150) NULL | |
| `Telefono` | nvarchar(30) NULL | |
| `Email` | nvarchar(150) NULL | |
| `FuenteContacto` | nvarchar(50) NULL | |
| `Etapa` | nvarchar(20) NOT NULL DEFAULT 'NUEVO' | NUEVO / CONTACTADO / CALIFICADO / CONVERTIDO / DESCARTADO |
| `Notas` | nvarchar(1000) NULL | |
| `ResponsableID` | int NULL FK → `Rrhh.Empleados` | |
| `ClienteIDConvertido` | int NULL FK → `Crm.Clientes` | Se llena solo al convertir |
| `FechaCreacion` | datetime2 | |
| `FechaConversion` | datetime2 NULL | |

Un Lead en Etapa `CONVERTIDO` no se puede editar (bloqueado en `CrmService.ActualizarLeadAsync`). La conversión (`ConvertirLeadAsync`) es una transacción: crea el `Cliente` con los datos del Lead + marca el Lead como `CONVERTIDO`.

---

### `Logistica` (agosto 2026)

#### `Despachos`
Despacho de Producto Terminado a un cliente. Descuenta stock real (FEFO) vía `Logistica.sp_CrearDespacho` — no es solo un registro documental. `NumeroGuia` no es columna, se genera en el `SELECT` (`'GUIA-' + DespachoID con ceros a la izquierda`).

| Columna | Tipo | Restricciones |
|---|---|---|
| `DespachoID` | int PK IDENTITY | |
| `ClienteID` | int NOT NULL FK → `Crm.Clientes` | |
| `CentroCostoID` | int NOT NULL FK → `Organizacion.CentrosCosto` | |
| `BodegaOrigenID` | int NOT NULL FK → `Inventario.Bodegas` | |
| `Direccion` | nvarchar(200) NULL | |
| `Observaciones` | nvarchar(500) NULL | |
| `Estado` | nvarchar(20) | `DESPACHADO` (default, stock ya descontado) / `ENTREGADO` / `ANULADO` |
| `FechaDespacho` | datetime2(7) | |
| `FechaEntrega` | datetime2(7) NULL | Se llena al confirmar entrega |
| `UsuarioID` | int NULL FK → `Seguridad.Usuarios` | |
| `MotivoAnulacion` | nvarchar(300) NULL | Agregada agosto 2026 |
| `FechaAnulacion` | datetime2(7) NULL | Agregada agosto 2026 |
| `UsuarioAnulaID` | int NULL FK → `Seguridad.Usuarios` | Agregada agosto 2026 — quién anuló, puede ser distinto de quién despachó

#### `DespachoDetalle`
Líneas del despacho (artículos y cantidades).

| Columna | Tipo | Restricciones |
|---|---|---|
| `DetalleID` | int PK IDENTITY | |
| `DespachoID` | int NOT NULL FK → `Logistica.Despachos` | |
| `ArticuloID` | int NOT NULL FK → `Catalogo.Articulos` | |
| `Cantidad` | decimal(18,4) NOT NULL | |

---

### `Proyectos` (agosto 2026)

#### `Proyectos`

| Columna | Tipo | Restricciones |
|---|---|---|
| `ProyectoID` | int PK IDENTITY | |
| `Nombre` | nvarchar(150) NOT NULL | |
| `ClienteID` | int NULL FK → `Crm.Clientes` | |
| `CentroCostoID` | int NULL FK → `Organizacion.CentrosCosto` | |
| `Descripcion` | nvarchar(500) NULL | |
| `FechaInicio` | date NOT NULL | |
| `FechaFin` | date NULL | |
| `Estado` | nvarchar(20) | `PLANEADO` / `EN_CURSO` / `FINALIZADO` / `CANCELADO` |
| `Presupuesto` | decimal(18,2) | |
| `FechaCreacion` | datetime2(7) | |
| `Prioridad` | nvarchar(10) NOT NULL DEFAULT 'MEDIA' | Agregada agosto 2026 (Proyectos v2) — `ALTA` / `MEDIA` / `BAJA` |

#### `Tareas`

| Columna | Tipo | Restricciones |
|---|---|---|
| `TareaID` | int PK IDENTITY | |
| `ProyectoID` | int NOT NULL FK → `Proyectos.Proyectos` | |
| `Titulo` | nvarchar(200) NOT NULL | |
| `ResponsableID` | int NULL FK → `Rrhh.Empleados` | |
| `Estado` | nvarchar(20) | `PENDIENTE` / `EN_CURSO` / `COMPLETADA` |
| `FechaLimite` | date NULL | |
| `FechaCreacion` | datetime2(7) | |

#### `TareaDependencias` (agosto 2026, Proyectos v2)
Una tarea no puede salir de `PENDIENTE` si alguna tarea de la que depende no está `COMPLETADA` — validado en `ProyectosService.ActualizarTareaAsync` (no hay trigger ni constraint que lo fuerce en BD).

| Columna | Tipo | Restricciones |
|---|---|---|
| `TareaID` | int NOT NULL FK → `Proyectos.Tareas` | PK compuesta con `DependeDeTareaID` |
| `DependeDeTareaID` | int NOT NULL FK → `Proyectos.Tareas` | |

`CHECK (TareaID <> DependeDeTareaID)` — evita que una tarea dependa de sí misma. No hay prevención de ciclos multi-tarea a nivel de BD (a diferencia del organigrama de RRHH que sí usa CTE recursivo) — alcance acotado a validar solo la dependencia directa al cambiar de estado.

#### `Hitos` (agosto 2026, Proyectos v2)
Fases/etapas del proyecto, con fecha objetivo — distinto del % de tareas completadas.

| Columna | Tipo | Restricciones |
|---|---|---|
| `HitoID` | int PK IDENTITY | |
| `ProyectoID` | int NOT NULL FK → `Proyectos.Proyectos` | |
| `Nombre` | nvarchar(150) NOT NULL | |
| `FechaObjetivo` | date NOT NULL | |
| `FechaCompletado` | date NULL | Se rellena solo la primera vez que el hito pasa a `COMPLETADO` (no se pisa si ya tenía valor) |
| `Estado` | nvarchar(20) NOT NULL DEFAULT 'PENDIENTE' | `PENDIENTE` / `EN_PROGRESO` / `COMPLETADO` |
| `Orden` | int NOT NULL DEFAULT 0 | |
| `FechaCreacion` | datetime2 | |

#### `ProyectoDocumentos` (agosto 2026, Proyectos v2)
Mismo patrón que `Crm.ClienteDocumentos`/`Rrhh.EmpleadoDocumentos` — descarga autenticada, límite 5MB.

| Columna | Tipo | Restricciones |
|---|---|---|
| `DocumentoID` | int PK IDENTITY | |
| `ProyectoID` | int NOT NULL FK → `Proyectos.Proyectos` | |
| `TipoDocumento` | nvarchar(30) NOT NULL | `CONTRATO` / `PLANO` / `COTIZACION` / `OTRO` |
| `NombreArchivo` | nvarchar(255) NOT NULL | |
| `ContentType` | nvarchar(100) NOT NULL | |
| `Archivo` | varbinary(max) NOT NULL | |
| `FechaSubida` | datetime2 | |
| `UsuarioID` | int NULL FK → `Seguridad.Usuarios` | |

#### `Comentarios` (agosto 2026, Proyectos v2)
Bitácora simple de notas del proyecto.

| Columna | Tipo | Restricciones |
|---|---|---|
| `ComentarioID` | int PK IDENTITY | |
| `ProyectoID` | int NOT NULL FK → `Proyectos.Proyectos` | |
| `Texto` | nvarchar(1000) NOT NULL | |
| `Fecha` | datetime2 | |
| `UsuarioID` | int NULL FK → `Seguridad.Usuarios` | |

#### `Costos`
Imputación de costos al proyecto. **`Valor` es ingresado manualmente por el usuario** — no se calcula automático desde horas de RRHH ni consumo de Inventario. `EmpleadoID`/`ArticuloID` son solo de trazabilidad, no disparan movimientos de Kardex ni afectan nómina.

| Columna | Tipo | Restricciones |
|---|---|---|
| `CostoID` | int PK IDENTITY | |
| `ProyectoID` | int NOT NULL FK → `Proyectos.Proyectos` | |
| `Tipo` | nvarchar(20) NOT NULL | `MANO_OBRA` / `MATERIAL` / `OTRO` |
| `Descripcion` | nvarchar(300) NOT NULL | |
| `Valor` | decimal(18,2) NOT NULL | |
| `EmpleadoID` | int NULL FK → `Rrhh.Empleados` | Solo si Tipo=MANO_OBRA |
| `ArticuloID` | int NULL FK → `Catalogo.Articulos` | Solo si Tipo=MATERIAL |
| `Fecha` | datetime2(7) | |
| `UsuarioID` | int NULL FK → `Seguridad.Usuarios` | |

---

### `Planificacion` (agosto 2026)

#### `DemandaProyectada`
Forecast de producción a futuro, por artículo y mes — distinto de las Órdenes de Producción ya creadas. `Periodo` siempre es el primer día del mes.

| Columna | Tipo | Restricciones |
|---|---|---|
| `DemandaID` | int PK IDENTITY | |
| `ArticuloID` | int NOT NULL FK → `Catalogo.Articulos` | |
| `CentroCostoID` | int NOT NULL FK → `Organizacion.CentrosCosto` | |
| `Periodo` | date NOT NULL | Primer día del mes |
| `CantidadProyectada` | decimal(18,4) NOT NULL | |
| `Notas` | nvarchar(300) NULL | |
| `FechaCreacion` | datetime2(7) | |

UNIQUE(ArticuloID, CentroCostoID, Periodo). Comparación contra lo real (`CantidadReal`) se calcula al vuelo en `PlanificacionService.ListarDemandaAsync`: suma de `Kardex.KardexMovimientos` con tipo `ENTRADA_PT` para el mismo Articulo+CentroCosto+mes.

#### `MetasVenta`
Objetivo comercial por Centro de Costo y mes.

| Columna | Tipo | Restricciones |
|---|---|---|
| `MetaID` | int PK IDENTITY | |
| `CentroCostoID` | int NOT NULL FK → `Organizacion.CentrosCosto` | |
| `Periodo` | date NOT NULL | Primer día del mes |
| `MetaValor` | decimal(18,2) NOT NULL | |
| `Notas` | nvarchar(300) NULL | |
| `FechaCreacion` | datetime2(7) | |

UNIQUE(CentroCostoID, Periodo). `VentaReal` se calcula al vuelo: `Cantidad * PrecioVenta` (precio **actual** del artículo, no histórico) sumado sobre `Kardex.KardexMovimientos` tipo `SALIDA_VENTA_VISIONS` del mismo CentroCosto+mes.

#### `MetasVentaHistorial` (agosto 2026, Planificación v2)
Versionado de metas — se inserta automático en `PlanificacionService.ActualizarMetaVentaAsync`, con el valor ANTERIOR, antes de sobrescribir. No hay endpoint para crear entradas a mano.

| Columna | Tipo | Restricciones |
|---|---|---|
| `HistorialID` | int PK IDENTITY | |
| `MetaID` | int NOT NULL FK → `Planificacion.MetasVenta` | |
| `MetaValorAnterior` | decimal(18,2) NOT NULL | |
| `NotasAnterior` | nvarchar(500) NULL | |
| `FechaCambio` | datetime2 | |
| `UsuarioID` | int NULL FK → `Seguridad.Usuarios` | |

**Nota de patrón SQL (agosto 2026)**: las consultas de cumplimiento (`DemandaProyectada`/`MetasVenta`) que promedian un porcentaje calculado a partir de una subconsulta con `SUM` **no pueden envolver el `AVG()` directamente alrededor de esa expresión** — SQL Server lo rechaza con error 130 ("Cannot perform an aggregate function on an expression containing an aggregate or a subquery"), incluso si la subconsulta está correlacionada dentro de un `CASE`. Hay que materializar el porcentaje por fila en una tabla derivada primero (`SELECT CASE ... AS Cumplimiento FROM ...) x`) y recién ahí aplicar `AVG()`/`GROUP BY` en la consulta externa. Bug real encontrado en `DashboardService.ObtenerResumenPlanificacionAsync` (ya corregido) — cualquier consulta nueva con este patrón debe usar la tabla derivada desde el inicio.

---

### `Facturacion` (agosto 2026)
Registro de ventas simple ("tipo guardado") — **independiente de Despachos/Inventario, no descuenta stock ni genera movimiento de Kardex**. Si en el futuro se necesita que Facturación sí afecte inventario, es un cambio de alcance explícito, no algo implícito en este schema.

#### `Facturas`

| Columna | Tipo | Restricciones |
|---|---|---|
| `FacturaID` | int PK IDENTITY | |
| `ClienteID` | int NOT NULL FK → `Crm.Clientes` | |
| `Fecha` | date NOT NULL | |
| `Notas` | nvarchar(500) NULL | |
| `FechaCreacion` | datetime2 | |
| `UsuarioID` | int NULL FK → `Seguridad.Usuarios` | |

#### `FacturaLineas`

| Columna | Tipo | Restricciones |
|---|---|---|
| `LineaID` | int PK IDENTITY | |
| `FacturaID` | int NOT NULL FK → `Facturacion.Facturas` | |
| `ArticuloID` | int NOT NULL FK → `Catalogo.Articulos` | |
| `Cantidad` | decimal(18,4) NOT NULL | |
| `PrecioUnitario` | decimal(18,2) NOT NULL | |

#### `Pagos`
Abonos/pagos parciales de una factura. **El estado (Pagada/Parcial/Pendiente) NO se guarda como columna** — se calcula en `FacturacionService.ListarFacturasAsync` comparando `SUM(Pagos.Monto)` contra `SUM(FacturaLineas.Cantidad * PrecioUnitario)`, así nunca queda desincronizado.

| Columna | Tipo | Restricciones |
|---|---|---|
| `PagoID` | int PK IDENTITY | |
| `FacturaID` | int NOT NULL FK → `Facturacion.Facturas` | |
| `Monto` | decimal(18,2) NOT NULL | |
| `FechaPago` | date NOT NULL | |
| `Notas` | nvarchar(300) NULL | |
| `FechaCreacion` | datetime2 | |
| `UsuarioID` | int NULL FK → `Seguridad.Usuarios` | |

---

### `Rrhh` (agosto 2026)

#### `Empleados`
Directorio básico de personal. **Deliberadamente separada de `Seguridad.Usuarios`** — un empleado no necesariamente tiene login al sistema, y un usuario de sistema no necesariamente es empleado formal. Sin nómina, sin cálculo de salario/horas, sin documentos adjuntos, sin asistencia — el cliente ya tiene nómina y contabilidad en otro sistema aparte.

| Columna | Tipo | Restricciones |
|---|---|---|
| `EmpleadoID` | int PK IDENTITY | |
| `Nombres` | nvarchar(100) NOT NULL | |
| `Apellidos` | nvarchar(100) NOT NULL | |
| `Cargo` | nvarchar(100) NULL | |
| `CentroCostoID` | int NULL FK → `Organizacion.CentrosCosto` | |
| `FechaIngreso` | date NULL | |
| `Telefono` | nvarchar(30) NULL | |
| `Email` | nvarchar(150) NULL | |
| `Estado` | bit | |
| `FechaCreacion` | datetime2(7) | |
| `Foto` | varbinary(max) NULL | Agregada agosto 2026 — opcional, mismo patrón que `Catalogo.Articulos.Imagen` |
| `FotoContentType` | nvarchar(50) NULL | Agregada agosto 2026 |
| `CargoID` | int NULL FK → `Rrhh.Cargos` | Agregada agosto 2026 (RRHH v2) — reemplaza a `Cargo` (texto libre) |
| `JefeDirectoID` | int NULL FK → `Rrhh.Empleados` (auto-FK) | Agregada agosto 2026 (RRHH v2) — usado para el Organigrama; validado contra ciclos en `RrhhService.ActualizarEmpleadoAsync` |

**Nota**: la columna `Cargo` (texto libre) ya no se usa desde el código — reemplazada por `CargoID` → `Rrhh.Cargos`. Se dejó en la tabla sin eliminar (mismo criterio que `Crm.Clientes.Contacto`).

#### `Departamentos` (agosto 2026, RRHH v2)

| Columna | Tipo | Restricciones |
|---|---|---|
| `DepartamentoID` | int PK IDENTITY | |
| `Nombre` | nvarchar(100) NOT NULL | |
| `Estado` | bit | |
| `FechaCreacion` | datetime2 | |

#### `Cargos` (agosto 2026, RRHH v2)

| Columna | Tipo | Restricciones |
|---|---|---|
| `CargoID` | int PK IDENTITY | |
| `Nombre` | nvarchar(100) NOT NULL | |
| `DepartamentoID` | int NULL FK → `Rrhh.Departamentos` | |
| `Estado` | bit | |
| `FechaCreacion` | datetime2 | |

#### `HistorialLaboral` (agosto 2026, RRHH v2)
Se genera automático desde `RrhhService.ActualizarEmpleadoAsync` al detectar un cambio de `CargoID`/`CentroCostoID` — no hay endpoint para crear entradas a mano.

| Columna | Tipo | Restricciones |
|---|---|---|
| `HistorialID` | int PK IDENTITY | |
| `EmpleadoID` | int NOT NULL FK → `Rrhh.Empleados` | |
| `TipoEvento` | nvarchar(30) NOT NULL | CAMBIO_CARGO / CAMBIO_CENTRO_COSTO / OTRO |
| `ValorAnterior` | nvarchar(200) NULL | |
| `ValorNuevo` | nvarchar(200) NULL | |
| `Fecha` | datetime2 | |
| `Notas` | nvarchar(500) NULL | |
| `UsuarioID` | int NULL FK → `Seguridad.Usuarios` | |

#### `EmpleadoDocumentos` (agosto 2026, RRHH v2)
Mismo patrón que `Crm.ClienteDocumentos` — descarga autenticada (no `[AllowAnonymous]`), límite 5MB.

| Columna | Tipo | Restricciones |
|---|---|---|
| `DocumentoID` | int PK IDENTITY | |
| `EmpleadoID` | int NOT NULL FK → `Rrhh.Empleados` | |
| `TipoDocumento` | nvarchar(30) NOT NULL | CEDULA / HOJA_VIDA / CONTRATO / CERTIFICADO / OTRO |
| `NombreArchivo` | nvarchar(255) NOT NULL | |
| `ContentType` | nvarchar(100) NOT NULL | |
| `Archivo` | varbinary(max) NOT NULL | |
| `FechaSubida` | datetime2 | |
| `UsuarioID` | int NULL FK → `Seguridad.Usuarios` | |

#### `Ausencias` (agosto 2026, RRHH v2)
Solo control de disponibilidad — **sin ningún cálculo de nómina**.

| Columna | Tipo | Restricciones |
|---|---|---|
| `AusenciaID` | int PK IDENTITY | |
| `EmpleadoID` | int NOT NULL FK → `Rrhh.Empleados` | |
| `Tipo` | nvarchar(30) NOT NULL | VACACIONES / INCAPACIDAD / PERMISO / OTRO |
| `FechaInicio` | date NOT NULL | |
| `FechaFin` | date NOT NULL | |
| `Motivo` | nvarchar(300) NULL | |
| `Estado` | nvarchar(20) NOT NULL DEFAULT 'PENDIENTE' | PENDIENTE / APROBADA / RECHAZADA |
| `FechaCreacion` | datetime2 | |
| `UsuarioID` | int NULL FK → `Seguridad.Usuarios` | |

#### `Evaluaciones` (agosto 2026, RRHH v2)

| Columna | Tipo | Restricciones |
|---|---|---|
| `EvaluacionID` | int PK IDENTITY | |
| `EmpleadoID` | int NOT NULL FK → `Rrhh.Empleados` | |
| `ResponsableID` | int NULL FK → `Rrhh.Empleados` | |
| `Fecha` | date NOT NULL | |
| `Calificacion` | decimal(3,1) NOT NULL | 1.0 a 5.0, validado en el backend |
| `Comentarios` | nvarchar(1000) NULL | |
| `FechaCreacion` | datetime2 | |
| `UsuarioID` | int NULL FK → `Seguridad.Usuarios` | |

#### `Capacitaciones` (agosto 2026, RRHH v2)

| Columna | Tipo | Restricciones |
|---|---|---|
| `CapacitacionID` | int PK IDENTITY | |
| `EmpleadoID` | int NOT NULL FK → `Rrhh.Empleados` | |
| `Nombre` | nvarchar(200) NOT NULL | |
| `Institucion` | nvarchar(150) NULL | |
| `FechaRealizacion` | date NOT NULL | |
| `FechaVencimiento` | date NULL | La UI resalta en rojo si ya venció |
| `FechaCreacion` | datetime2 | |
| `UsuarioID` | int NULL FK → `Seguridad.Usuarios` | |

---

### `Organizacion`

#### `CentrosCosto`
Representa una planta, bodega central o punto de distribución.

| Columna | Tipo | Restricciones |
|---|---|---|
| `CentroCostoID` | int PK IDENTITY | |
| `Codigo` | nvarchar(20) UNIQUE NOT NULL | |
| `Nombre` | nvarchar(100) NOT NULL | |
| `TipoCentro` | nvarchar(20) | Planta / Bodega / Distribución |
| `Direccion` | nvarchar(200) NULL | |
| `Telefono` | nvarchar(30) NULL | |
| `Estado` | bit | |
| `FechaCreacion` | datetime2(7) | |
| `TieneVisions` | bit | Si está integrado con Visions ERP |
| `IdentificadorClienteVisions` | nvarchar(50) NULL | **NO es un identificador de cliente pese al nombre** — es el código `CENTROCOSTO` (smallint) que identifica esta sucursal dentro de la base de datos de Visions de este cliente (columna `CENTROCOSTO` en `dbo.TARJETA`/`dbo.MOVDETALLES` de Visions). nvarchar por flexibilidad histórica, pero siempre debe contener un número (agosto 2026, ver `Integracion.sp_ProcesarEventoEntrante`/`TareaSincronizarConfiguracion` que hacen `TRY_CAST(... AS INT)`) |
| `BodegaVentaVisionsID` | int NULL FK → `Inventario.Bodegas` | Bodega fija desde la que se descuenta stock cuando llega una venta reportada por Visions (agosto 2026, ver `Integracion.sp_ProcesarEventoEntrante`) |
| `PrefijosDocumentoVentaVisions` | nvarchar(200) NULL | Códigos TIPDOC de Visions (separados por coma, ej. `"POS,FV"`) que cuentan como venta a exportar. Editable solo por Administrador en NEXO Web; el `NexoSyncAgent` lo replica en `dbo.NEXO_ConfiguracionSync.TiposDocumentoVenta` de la base de Visions en cada ronda (agosto 2026) |

#### `CentrosTrabajo`
Líneas de producción o puestos de trabajo dentro de un centro de costo.

| Columna | Tipo |
|---|---|
| `CentroTrabajoID` | int PK IDENTITY |
| `Nombre` | nvarchar(100) NOT NULL |
| `CentroCostoID` | int FK |
| `CostoHoraManoObra` | decimal(18,4) |
| `CostoHoraCIF` | decimal(18,4) |
| `Estado` | bit |

---

### `Produccion`

#### `OrdenesProduccion`
Documento principal del proceso productivo.

| Columna | Tipo | Descripción |
|---|---|---|
| `OrdenProduccionID` | int PK IDENTITY | |
| `CodigoOP` | nvarchar(30) UNIQUE | Código único de la OP |
| `TipoProduccionID` | int FK | |
| `EstadoOPID` | int FK | FK → EstadosOP |
| `ProductoTerminadoID` | int FK | FK → catalogo.Articulos |
| `RecetaID` | int FK | FK → RecetaBOM |
| `CantidadProgramada` | decimal(18,4) | |
| `CantidadProducidaReal` | decimal(18,4) NULL | Se llena al cerrar |
| `ClienteID` | int NULL FK | Producción para cliente específico |
| `CentroCostoDestinoID` | int FK | |
| `BodegaOrigenMPID` | int FK | Bodega de donde salen las MP |
| `BodegaDestinoPTID` | int FK | Bodega donde entra el PT |
| `CentroTrabajoID` | int NULL FK | |
| `FechaPlanificada` | datetime2(7) NULL | |
| `FechaInicio` | datetime2(7) NULL | |
| `FechaFin` | datetime2(7) NULL | |
| `CostoMateriales` | decimal(18,4) | Calculado al cerrar |
| `CostoMOD` | decimal(18,4) | Mano de obra directa |
| `CostoCIF` | decimal(18,4) | Costos indirectos de fabricación |
| `CostoUnitarioReal` | decimal(18,4) NULL | (CostoMateriales+MOD+CIF)/CantidadProducida |
| `UsuarioCreaID` | int FK | |
| `UsuarioLiberaID` | int NULL FK | |
| `UsuarioCierraID` | int NULL FK | |
| `Observaciones` | nvarchar(500) NULL | |
| `FechaCreacion` | datetime2(7) | |

#### `EstadosOP`
Catálogo de estados: Planificada, Liberada, En Proceso, Finalizada, Cancelada.

#### `OrdenesProduccionConsumo`
Detalle de consumo de materias primas por OP.

| Columna | Tipo |
|---|---|
| `ConsumoID` | bigint PK IDENTITY |
| `OrdenProduccionID` | int FK |
| `ArticuloID` | int FK |
| `LoteID` | int NULL FK |
| `CantidadTeorica` | decimal(18,4) — de la receta BOM |
| `CantidadReal` | decimal(18,4) — ajustable post-inicio |
| `MotivoExcesoID` | int NULL FK — requerido si Real > Teórico |
| `Observacion` | nvarchar(300) NULL |

#### `MotivosExcesoConsumo`
Catálogo de motivos por los cuales el consumo real excedió el teórico.

| Columna | Tipo |
|---|---|
| `MotivoExcesoID` | int PK IDENTITY |
| `Nombre` | nvarchar(150) |

#### `RecetaBOM`
Receta (Bill of Materials) por producto terminado.

| Columna | Tipo |
|---|---|
| `RecetaID` | int PK IDENTITY |
| `ProductoTerminadoID` | int FK |
| `NombreReceta` | nvarchar(150) |
| `Version` | int — versionamiento de recetas |
| `CantidadRendimientoBase` | decimal(18,4) |
| `UnidadRendimientoID` | int FK |
| `Estado` | bit |
| `FechaCreacion` | datetime2(7) |

#### `RecetaBOM_Detalle`
Líneas de ingredientes/insumos de una receta.

| Columna | Tipo |
|---|---|
| `RecetaDetalleID` | int PK IDENTITY |
| `RecetaID` | int FK |
| `InsumoID` | int FK — artículo insumo |
| `CantidadRequerida` | decimal(18,4) |
| `UnidadID` | int FK |
| `PorcentajeMermaEstandar` | decimal(5,2) |
| `CentroTrabajoID` | int NULL FK |
| `Orden` | int — orden de procesamiento |

#### `TiposProduccion`
Catálogo de tipos: Estándar, Envasado, Reproceso, etc.

---

### `Seguridad`

#### `Usuarios`

| Columna | Tipo | Restricciones |
|---|---|---|
| `UsuarioID` | int PK IDENTITY | |
| `Nombres` | nvarchar(100) NOT NULL | |
| `Apellidos` | nvarchar(100) NOT NULL | |
| `Email` | nvarchar(150) NOT NULL | UNIQUE |
| `Username` | nvarchar(50) NOT NULL | UNIQUE |
| `PasswordHash` | varbinary(256) NOT NULL | PBKDF2 |
| `Salt` | varbinary(128) NOT NULL | Aleatorio por usuario |
| `RolID` | int FK | FK → Roles |
| `CentroCostoID` | int NULL FK | NULL = acceso a todos los CC |
| `Estado` | bit | |
| `FechaCreacion` | datetime2(7) | |
| `UltimoAcceso` | datetime2(7) NULL | Se actualiza en cada login |

Fila especial agregada agosto 2026: `Username='sistema.sync'`, `Estado=0` (nunca puede iniciar sesión, password aleatorio via `CRYPT_GEN_RANDOM`) — existe solo como FK de auditoría en `Kardex.KardexMovimientos.UsuarioID` para los movimientos generados automáticamente por `Integracion.sp_ProcesarEventoEntrante`.

#### `Roles`
Roles del sistema: Administrador, SupervisorPlanta, Bodeguero, Operario.

#### `Permisos`
Catálogo granular de permisos por módulo (no usado aún en la UI — la autorización es por rol).

#### `RolPermisos`
Tabla N:M entre Roles y Permisos.

#### `SesionesUsuario`
Registro de sesiones activas para control de RefreshToken.

| Columna | Tipo |
|---|---|
| `SesionID` | bigint PK IDENTITY |
| `UsuarioID` | int FK |
| `Token` | nvarchar(500) — JWT access token |
| `RefreshToken` | nvarchar(500) |
| `FechaInicio` | datetime2(7) |
| `FechaExpiracion` | datetime2(7) |
| `DireccionIP` | nvarchar(50) NULL |
| `Activa` | bit — se desactiva en logout o reseteo de password |

---

## 3. Vistas

| Vista | Esquema | Descripción |
|---|---|---|
| `vw_StockConsolidado` | `Inventario` | JOIN de InventarioStock + Artículos + Bodegas + CC + Lotes. Solo filas con CantidadActual > 0. Calcula ValorTotal y RequierePedido. |
| `vw_EventosPendientesParaVisions` | `Integracion` | Eventos salientes PENDIENTE donde el CC tiene TieneVisions=1, con mapeo a códigos Visions. |
| `vw_ProduccionPlanVsReal` | `Produccion` | Agrupado por fecha y CC: TotalPlanificado vs TotalReal. |
| `vw_DistribucionPorCentroCosto` | `Produccion` | Solo órdenes Finalizadas: total órdenes, unidades producidas e inversión por CC. |
| `vw_TendenciaCostoUnitario` | `Produccion` | CostoUnitarioReal por artículo y fecha de cierre. Solo órdenes Finalizadas. |
| `vw_CumplimientoPlanificacion` | `Produccion` | Por CC: total finalizadas, a tiempo (FechaFin ≤ FechaPlanificada), porcentaje de cumplimiento. |
| `vw_PerdidasPorMotivo` | `Kardex` | Bajas CONFIRMADAS: cantidad y valor total por motivo y fecha. |

---

## 4. Funciones

| Función | Esquema | Descripción |
|---|---|---|
| `fn_StockTotalArticulo(@ArticuloID)` | `catalogo` | Retorna `SUM(CantidadActual)` de `Inventario.InventarioStock` para un artículo. |

---

## 5. Stored Procedures

### `Logistica.sp_CrearDespacho` (agosto 2026, ampliado el mismo día)
Crea un despacho a cliente y descuenta stock real (FEFO), todo en una transacción.
- Recibe las líneas del despacho como **JSON** (`@LineasJson`, parseado con `OPENJSON` — no hay un tipo de tabla (TVP) registrado, se eligió JSON por ser más simple de mandar desde C#)
- Valida, en orden, ANTES de insertar nada: líneas no vacías, cantidades > 0, sin artículo repetido entre líneas, cliente existe y está activo, la bodega de origen pertenece al Centro de Costo elegido, y stock suficiente de TODAS las líneas (el mensaje de este último **nombra el SKU y nombre exacto** del/los artículo(s) que faltan, vía `STRING_AGG` + JOIN a `Catalogo.Articulos`) — si algo falla, `THROW` y no se crea el despacho (a diferencia de `sp_ProcesarEventoEntrante`, aquí SÍ se bloquea: es un despacho creado por un usuario interno, no una venta externa ya consumada)
- Inserta el encabezado (`Logistica.Despachos`, `Estado='DESPACHADO'`) y cada línea (`Logistica.DespachoDetalle`)
- Por cada línea, descuenta stock FEFO de la bodega de origen (cursor anidado: uno por línea, uno por lote — mismo patrón que `sp_ProcesarEventoEntrante`/`sp_CrearYEnviarTraspaso`) y genera `Kardex.KardexMovimientos` tipo `SALIDA_DESPACHO`
- Devuelve el `DespachoID` generado
- **Errores**: 56000 (sin líneas), 56001 (stock insuficiente, nombra artículos), 56004 (cliente inválido/inactivo), 56005 (bodega no pertenece al CC), 56006 (artículo repetido), 56007 (cantidad ≤ 0)
- Verificado con una prueba real dentro de una transacción con `ROLLBACK` (agosto 2026) antes de darlo por terminado, incluyendo las 5 validaciones nuevas una por una

### `Logistica.sp_AnularDespacho` (agosto 2026)
Revierte un despacho `DESPACHADO` (no `ENTREGADO` ni ya `ANULADO`) — devuelve el stock exacto a los mismos lotes/bodega de donde salió.
- Recorre `Kardex.KardexMovimientos` con tipo `SALIDA_DESPACHO` y `ObservacionDetallada = 'Despacho #N'` (no hay FK directa Kardex→Despacho, se identifican por texto — mismo patrón usado al crearlos)
- Por cada movimiento encontrado, suma la cantidad de vuelta a `Inventario.InventarioStock` (mismo `ArticuloID`+`BodegaID`+`LoteID`) y genera un movimiento compensatorio `ENTRADA_ANULACION_DESPACHO`
- Marca `Logistica.Despachos.Estado = 'ANULADO'`, `MotivoAnulacion`, `FechaAnulacion`, `UsuarioAnulaID`
- **Errores**: 56002 (despacho no existe), 56003 (no está en estado `DESPACHADO`)
- Verificado con una prueba real de ciclo completo (crear → anular → comparar stock final vs inicial) dentro de una transacción con `ROLLBACK`, confirmó coincidencia exacta

### `Compras.sp_RecibirOrdenCompra`
Recibe una línea de orden de compra.
- Actualiza `CantidadRecibida` en `OrdenesCompraDetalle`
- Actualiza estado de la OC (Parcial / Recibida)
- Crea o actualiza lote en `Inventario.Lotes`
- Actualiza `Inventario.InventarioStock` (UPSERT)
- Registra movimiento en `Kardex.KardexMovimientos`
- **Errores**: 52001 (OC ya recibida), 52000 (cantidad inválida)

### `Integracion.sp_ProcesarEventoEntrante`
Procesa un evento de venta recibido de Visions. Reescrito agosto 2026 (dos veces) — primero para descontar stock real (antes solo acumulaba en `InventarioReportadoVisions`); después para dejar de fallar con `THROW` cuando el artículo no está mapeado.
- Si el evento ya estaba `Procesado=1`, no hace nada (idempotente)
- Busca el mapeo de artículo (`Integracion.MapeoArticulos`); **si no existe, YA NO hace `THROW`** — registra/actualiza una fila en `Integracion.ArticulosPendientesMapeo` (con `NombreArticuloVisions`/`CostoArticuloVisions`/`PrecioArticuloVisions` que trae el evento, como sugerencia) y hace `RETURN` dejando el evento `Procesado=0` — se reintenta solo la próxima ronda, y en cuanto el Administrador cree el mapeo (`catalogo/mapeo-articulos-visions`) la venta se procesa normal
- Resuelve `Organizacion.CentrosCosto.BodegaVentaVisionsID`; si es NULL, `THROW 54001` (falta configurar la bodega en Catálogo > Centros de Costo)
- Actualiza `InventarioReportadoVisions` (MERGE, acumulador de seguimiento, no cambia)
- Descuenta `Inventario.InventarioStock` con cursor FEFO (mismo patrón que `sp_CrearYEnviarTraspaso`/`sp_IniciarOrdenProduccion`) sobre la bodega de venta Visions del Centro de Costo, generando `Kardex.KardexMovimientos` (tipo `SALIDA_VENTA_VISIONS`) por cada lote tocado
- A propósito **no bloquea por stock insuficiente**: si el pendiente no se cubre con los lotes disponibles, se aplica igual y el stock queda en negativo (la venta en Visions ya es un hecho consumado, no se puede revertir)
- Los movimientos de Kardex se atribuyen al usuario de sistema `Seguridad.Usuarios.Username = 'sistema.sync'` (`Estado=0`, no puede iniciar sesión, es solo un FK de auditoría para procesos automáticos)
- Marca el evento como procesado (`Procesado=1`, `FechaProcesado`)

### `Inventario.sp_CrearYEnviarTraspaso`
Crea el traspaso y lo envía inmediatamente.
- Valida stock disponible en bodega origen
- Descuenta de `InventarioStock` origen
- Crea registros en `TraspasosBodega` y `TraspasosDetalle`
- Registra salida en Kardex
- **Errores**: 53000 (stock insuficiente), 53010 (traspaso ya en proceso)

### `Inventario.sp_RecibirTraspaso`
Recibe el traspaso en la bodega destino.
- Valida que el traspaso esté en estado Enviado
- Actualiza `InventarioStock` en bodega destino (UPSERT)
- Actualiza `TraspasosDetalle.CantidadRecibida`
- Cierra el traspaso (estado Recibido)
- Registra entrada en Kardex
- **Errores**: 53000 (traspaso no encontrado o ya recibido)

### `Kardex.sp_RegistrarBajaInventario`
Registra una pérdida/merma de inventario.
- Valida stock en `InventarioStock`
- Descuenta la cantidad
- Registra en `BajasInventarioPerdidas`
- Registra salida en `KardexMovimientos`
- **Errores**: 51001 (stock insuficiente para la baja)

### `Produccion.sp_AjustarConsumoReal`
Ajusta la cantidad real consumida de un insumo en una OP en proceso.
- Valida que la OP esté En Proceso
- Actualiza `OrdenesProduccionConsumo`
- Si la cantidad supera la teórica, requiere `MotivoExcesoID`
- **Errores**: 51020 (consumo no encontrado → 404)

### `Produccion.sp_CerrarOrdenProduccion`
Cierra la OP y genera el producto terminado.
- Valida estado En Proceso
- Calcula costos (materiales, MOD, CIF)
- Actualiza `OrdenesProduccion` con cantidades y costos reales
- Crea lote de PT en `Inventario.Lotes`
- Ingresa PT al inventario (`InventarioStock` UPSERT)
- Registra entrada en Kardex
- Genera `Integracion.EventosSalientes` si el CC tiene Visions
- Retorna `CostoUnitarioReal` y `LoteProductoTerminadoID`
- **Errores**: 51010 (estado inválido), 51011 (cantidad producida 0)

### `Produccion.sp_IniciarOrdenProduccion`
Inicia la OP y descuenta las materias primas.
- Valida estado Liberada
- Para cada insumo de la receta: descuenta de `InventarioStock`
- Registra salidas en `KardexMovimientos`
- Crea registros en `OrdenesProduccionConsumo` (con cantidades teóricas)
- Actualiza estado a En Proceso
- **Errores**: 51001 (stock insuficiente), 51002 (OP en estado inválido)

### `Produccion.sp_LiberarOrdenProduccion`
Libera la OP (pre-validación antes de iniciar).
- Valida estado Planificada
- Verifica stock disponible de todos los insumos de la receta
- Si todo OK: cambia estado a Liberada
- **Errores**: 51030 (stock insuficiente para liberar), 51001 (OP en estado inválido)

---

## 6. CHECK Constraints Importantes

Estos valores son los únicos aceptados por la BD. Usar cualquier otro valor produce error 547.

| Tabla | Columna | Valores permitidos |
|---|---|---|
| `Catalogo.UnidadesMedida` | `Tipo` | `'PESO'`, `'VOLUMEN'`, `'UNIDAD'`, `'LONGITUD'` |
| `Inventario.Bodegas` | `TipoBodega` | `'MATERIA_PRIMA'`, `'PRODUCTO_TERMINADO'`, `'WIP'`, `'TRANSITO'` |
| `Organizacion.CentrosCosto` | `TipoCentro` | `'PLANTA_CENTRAL'`, `'SUCURSAL'`, `'PUNTO_VENTA'`, `'FRANQUICIA'` |
| `Integracion.EventosSalientes` | `TipoEvento` | `'ENTRADA_PRODUCTO_TERMINADO'`, `'TRASPASO_RECIBIDO'`, `'SINCRONIZAR_ARTICULO'` (agosto 2026 — crea/actualiza el maestro del artículo en `dbo.TARJETA` de Visions, nunca toca `EXISTENCIAS`) |
| `Integracion.EventosEntrantes` | `TipoEvento` | `'VENTA'`, `'AJUSTE_INVENTARIO'` |
| `Kardex.TiposMovimientoKardex` | `Signo` | `1` (entrada), `-1` (salida) |
| `Auditoria.LogAuditoria` | `Accion` | `'INSERT'`, `'UPDATE'`, `'DELETE'` |

---

## 7. Convenciones SQL

- PKs: `{Entidad}ID INT IDENTITY(1,1)` — siempre entero autoincremental
- Fechas: `datetime2(7)` — precisión de 100 nanosegundos
- Decimales: `decimal(18,4)` para cantidades, `decimal(5,2)` para porcentajes
- Strings: `nvarchar` siempre (Unicode)
- Bits: `bit NOT NULL DEFAULT 0` para flags de Estado
- Todos los SPs transaccionales usan `BEGIN TRANSACTION` / `COMMIT` / `ROLLBACK`
- Los errores de negocio se lanzan con `THROW 5XXXX, 'mensaje', 1`
- No se usa `SELECT *` — siempre columnas explícitas

---

## 7. Índices Notables

- `Kardex.KardexMovimientos`: índice implícito por PK (KardexID). Sin índices secundarios declarados aún — considerar índice en (ArticuloID, BodegaID, Fecha) para búsquedas frecuentes del Kardex.
- `Inventario.InventarioStock`: índice UNIQUE en (ArticuloID, BodegaID, LoteID) — garantiza un registro por combinación.
- `Integracion.EventosSalientes`: sin índice en Estado — considerar agregar si los PENDING se acumulan.

---

## 8. Flujo de Datos — Producción Completa

```
Crear OP → OrdenesProduccion (EstadoOPID = Planificada)
Liberar OP → Valida stock → EstadoOPID = Liberada
Iniciar OP → Descuenta InventarioStock (MP) → KardexMovimientos (salida)
           → OrdenesProduccionConsumo (cantidades teóricas)
           → EstadoOPID = En Proceso
[Opcional] Ajustar consumo → OrdenesProduccionConsumo.CantidadReal
                           → Delta vs. lo ya descontado se refleja en
                             InventarioStock y KardexMovimientos (ver 9.4)
Cerrar OP  → Calcula costos
           → Lotes (crea lote PT)
           → InventarioStock (entrada PT)
           → KardexMovimientos (entrada PT)
           → EventosSalientes (si TieneVisions)
           → OrdenesProduccion.CostoUnitarioReal, EstadoOPID = Finalizada
```

---

## 9. Cambios de Esquema — Agosto 2026

Todos aplicados directamente contra la BD en vivo y versionados en `ScriptsSQL/ScriptsProcesos/` (scripts idempotentes, `CREATE OR ALTER` / `IF NOT EXISTS`).

### 9.1 — Tabla nueva: `Kardex.AjustesInventario`
Registra entradas positivas de inventario sin pasar por una Orden de Compra (carga de stock inicial, corrección por conteo físico). Columnas: `AjusteID, CodigoAjuste, Fecha, ArticuloID, BodegaID, LoteID, CantidadAjustada, CostoUnitario, CostoTotal (computed), Motivo, UsuarioRegistraID`. SP: `Kardex.sp_AjustePositivoInventario`.

### 9.2 — Columna nueva: `Kardex.KardexMovimientos.AjusteID`
Nullable, referencia a `Kardex.AjustesInventario` (mismo patrón que `OrdenProduccionID`/`TraspasoID`/`OrdenCompraID`/`BajaID`, sin FK física declarada — igual que el resto de esas columnas).

### 9.3 — `Catalogo.Articulos` — dos cambios
- `UnidadID` pasó de `NOT NULL` a `NULL` — un artículo `Servicio` no siempre tiene unidad física.
- Columna nueva `UnidadesPorEmbalaje DECIMAL(18,4) NULL` — cuántas unidades base trae 1 "Caja". Solo informativo/de presentación, no participa en ningún cálculo de stock.

### 9.4 — `Produccion.sp_AjustarConsumoReal` — reescrito
Antes solo hacía `UPDATE OrdenesProduccionConsumo SET CantidadReal = ...`. Ahora calcula el delta contra la cantidad real anterior y lo aplica a `InventarioStock` + `KardexMovimientos` (descuenta si el ajuste es mayor al consumo ya reflejado, devuelve al stock — vía `Kardex.TiposMovimientoKardex` código `AJU_INV` — si es menor). Firma nueva: agregó `@UsuarioID INT` (requerido, sin default).

### 9.5 — `Produccion.sp_LiberarOrdenProduccion` / `sp_IniciarOrdenProduccion` — redondeo por Unidad + conversión Caja↔Unidad
El cálculo de cantidad necesaria (`CantidadRequerida * FactorEscala * (1 + Merma%)`) aplica `CEILING()` cuando `Catalogo.UnidadesMedida.Tipo = 'UNIDAD'` para esa línea de receta (no se puede tomar una fracción de un artículo indivisible). Además, **desde el segundo fix** (ver `CLAUDE.md` secciones 20.5, 20.8 y 20.9), si `RecetaBOM_Detalle.UnidadID` no coincide con `Articulos.UnidadID` y el par es Caja/Unidad, convierte usando `Articulos.UnidadesPorEmbalaje` antes de comparar contra el stock. Sin esto, cualquier artículo comprado por caja pero recetado en unidades sueltas (o viceversa) daba faltantes falsos.

### 9.6 — Procedimientos nuevos para Órdenes de Producción
- `Produccion.sp_ActualizarOrdenProduccion` — edita una OP mientras está en estado `Planificada` (aún no se ha descontado stock).
- `Produccion.sp_CancelarOrdenProduccion` — mueve una OP `Planificada` al estado `Cancelada` (ya sembrado en `Produccion.EstadosOP` desde el inicio, pero nunca usado hasta ahora).

### 9.7 — `Kardex.TiposMovimientoKardex` y `Produccion.MotivosExcesoConsumo` — datos corregidos
Los `Codigo` sembrados en `DatosSemilla.sql` no coincidían con los que buscan los stored procedures (ver `CLAUDE.md` sección 20.2) — se corrigieron con `UPDATE` directo más el script fuente. `MotivosExcesoConsumo` tenía además 12 filas duplicadas para 4 motivos reales (sin `UNIQUE` en `Nombre`); se limpiaron y se agregó `UQ_MotivoExcesoConsumo_Nombre`.

### 9.8 — Vista `Inventario.vw_StockConsolidado` — columnas nuevas
Agregó `Unidad` y `UnidadesPorEmbalaje` (LEFT JOIN a `UnidadesMedida`, porque `UnidadID` ahora es nullable) para que Consulta de Stock pueda mostrar la conversión caja→unidades.

### 9.9 — `Inventario.sp_CrearYEnviarTraspaso` — reescrito (multi-lote FEFO)
Antes solo buscaba stock con `LoteID IS NULL` cuando el detalle no especificaba un lote (que es siempre, porque la UI no deja elegir lote) — como casi todo el stock real tiene lote (Compras y Producción siempre crean uno), **cualquier traspaso fallaba** con "Stock insuficiente" aunque sobrara inventario. Ahora, cuando no se pide un lote específico, consume de todos los lotes disponibles por FEFO (mismo patrón que `sp_IniciarOrdenProduccion`), generando una línea de `TraspasosDetalle`/`KardexMovimientos` por cada lote tocado. Ver `CLAUDE.md` sección 20.10.

### 9.10 — `Auth.AuthService.LoginAsync` — acepta Username o Email
`WHERE Username = @Username OR Email = @Username`. Ver `CLAUDE.md` sección 20.11.

### 9.11 — Tabla nueva: `Seguridad.PreferenciasUsuario`
Guarda preferencias personales por usuario (tema oscuro, vista lista/tarjetas por pantalla, favoritos del menú) como pares Clave/Valor genéricos, para no migrar el esquema cada vez que se agregue una nueva preferencia.
```sql
CREATE TABLE Seguridad.PreferenciasUsuario (
    UsuarioID INT NOT NULL,
    Clave NVARCHAR(50) NOT NULL,
    Valor NVARCHAR(MAX) NOT NULL,
    FechaModificacion DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_PreferenciasUsuario PRIMARY KEY (UsuarioID, Clave),
    CONSTRAINT FK_PreferenciasUsuario_Usuario FOREIGN KEY (UsuarioID) REFERENCES Seguridad.Usuarios(UsuarioID)
);
```
**`Valor` se amplió de `NVARCHAR(50)` a `NVARCHAR(MAX)` en agosto 2026** (sección 27 de `CLAUDE.md`) — la clave `"Favoritos"` guarda un array JSON (`[{"Href":"...","Etiqueta":"..."}]`) de páginas marcadas en el menú lateral, que no cabía en 50 caracteres. Los valores simples anteriores (`"true"`/`"false"`, `"lista"`/`"tarjetas"`) siguen funcionando igual, `NVARCHAR(MAX)` es compatible hacia atrás.
Claves usadas hasta ahora: `TemaOscuro` (`"true"`/`"false"`), `VistaListado` (`"lista"`/`"tarjetas"` — control único y global, ya no es por pantalla). Ver `CLAUDE.md` sección 20.20. **Ya aplicado en la base de datos** — no requiere ejecución manual.

### 9.12 — Columna nueva: `Compras.OrdenesCompraDetalle.FechaUltimaRecepcion`
Guarda la fecha del último `sp_RecibirOrdenCompra` sobre esa línea (una orden puede recibirse en partes, en días distintos, línea por línea). `Compras.OrdenesCompra.FechaRecepcion` (cabecera) ya existía y solo se setea cuando **todas** las líneas quedan completas — eso no cambió.
```sql
ALTER TABLE Compras.OrdenesCompraDetalle ADD FechaUltimaRecepcion DATETIME2 NULL;
```
`Compras.sp_RecibirOrdenCompra` (`CREATE OR ALTER`) ahora hace `SET FechaUltimaRecepcion = SYSUTCDATETIME()` junto con el `UPDATE` que suma `CantidadRecibida`. Ver `CLAUDE.md` sección 20.21. **Ya aplicado en la base de datos** — no requiere ejecución manual.

### 9.13 — `Produccion.vw_ProduccionPlanVsReal` — excluye órdenes Canceladas (bug real de datos)
La vista sumaba `CantidadProgramada` de **todas** las órdenes con esa `FechaPlanificada`, sin importar el estado — una OP cancelada seguía contando en "Planificado" para siempre, aunque nunca se fuera a producir (0 en "Real"), inflando artificialmente el desfase Plan vs Real de ese día. Se agregó `JOIN Produccion.EstadosOP e ON e.EstadoOPID = op.EstadoOPID WHERE e.Nombre <> 'Cancelada'`. Ver `CLAUDE.md` sección 20.22. **Ya aplicado en la base de datos** (`CREATE OR ALTER VIEW`) — no requiere ejecución manual.

### 9.14 — Columnas nuevas: `Seguridad.Usuarios.FotoPerfil` / `FotoPerfilContentType`
Foto de perfil opcional, editable por el propio usuario (cualquier rol) desde el menú del avatar en el Top Bar. Se guarda como blob en la misma fila del usuario — un `UPDATE` simplemente sobrescribe el valor anterior, así que "reemplazar la foto" no requiere borrar nada aparte, el valor viejo deja de existir en cuanto se pisa.
```sql
ALTER TABLE Seguridad.Usuarios ADD FotoPerfil VARBINARY(MAX) NULL, FotoPerfilContentType NVARCHAR(50) NULL;
```
Límite de 1 MB validado tanto en el cliente (`PerfilMenu.razor`) como en el servidor (`AuthController.ActualizarFotoPerfil`). Ver `CLAUDE.md` sección 20.28. **Ya aplicado en la base de datos** — no requiere ejecución manual.

### 9.15 — Columnas nuevas: `Catalogo.Articulos.Imagen` / `ImagenContentType`
Imagen opcional (una sola por artículo), editable desde `ArticuloDialog.razor` al crear o editar. Mismo patrón que la foto de perfil: `UPDATE` reemplaza la anterior, límite 1 MB.
```sql
ALTER TABLE Catalogo.Articulos ADD Imagen VARBINARY(MAX) NULL, ImagenContentType NVARCHAR(50) NULL;
```
Ver `CLAUDE.md` sección 20.29. **Ya aplicado en la base de datos** — no requiere ejecución manual.

### 9.16 — Tabla nueva: `Organizacion.ConfiguracionEmpresa`
Fila única (`ConfiguracionID = 1`) con el nombre y logo de la empresa que ve **todo el mundo** en el sidebar — a diferencia de `Seguridad.PreferenciasUsuario` (por usuario) y `Catalogo.Articulos.Imagen` (por artículo), esto es una configuración global, editable solo por Administrador desde Settings > "Mi Negocio".
```sql
CREATE TABLE Organizacion.ConfiguracionEmpresa (
    ConfiguracionID INT NOT NULL PRIMARY KEY,
    NombreEmpresa NVARCHAR(100) NOT NULL,
    Logo VARBINARY(MAX) NULL,
    LogoContentType NVARCHAR(50) NULL,
    CONSTRAINT CK_ConfiguracionEmpresa_Singleton CHECK (ConfiguracionID = 1)
);
INSERT INTO Organizacion.ConfiguracionEmpresa (ConfiguracionID, NombreEmpresa) VALUES (1, 'NEXO ERP');
```
Ver `CLAUDE.md` sección 20.29. **Ya aplicado en la base de datos** — no requiere ejecución manual.
