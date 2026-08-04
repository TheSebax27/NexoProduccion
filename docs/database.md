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
| `catalogo` | Catálogos maestros (artículos, clientes, proveedores, unidades) — minúscula por legacy |
| `Compras` | Órdenes de compra y recepción |
| `Integracion` | Eventos de sincronización con Visions ERP |
| `Inventario` | Stock, bodegas, lotes, traspasos, bajas |
| `Kardex` | Registro histórico de todos los movimientos de inventario |
| `Organizacion` | Centros de costo y centros de trabajo |
| `Produccion` | Órdenes de producción, recetas BOM, consumos |
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

#### `Clientes`

| Columna | Tipo |
|---|---|
| `ClienteID` | int PK IDENTITY |
| `Nombre` | nvarchar(150) NOT NULL |
| `NIT` | nvarchar(30) NULL |
| `Contacto` | nvarchar(100) NULL |
| `Telefono` | nvarchar(30) NULL |
| `Email` | nvarchar(150) NULL |
| `Direccion` | nvarchar(200) NULL |
| `Estado` | bit |

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

#### `MapeoArticulos`
Mapeo entre artículos de NEXO y códigos de Visions.

| Columna | Tipo | Restricciones |
|---|---|---|
| `MapeoID` | int PK IDENTITY | |
| `ArticuloID` | int | UNIQUE(ArticuloID, CentroCostoID) |
| `CentroCostoID` | int | UNIQUE(CentroCostoID, CodigoArticuloVisions) |
| `CodigoArticuloVisions` | nvarchar(30) | |
| `Estado` | bit | |
| `FechaCreacion` | datetime2(7) | |

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
| `IdentificadorClienteVisions` | nvarchar(50) NULL | Código de cliente en Visions |

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

### `Compras.sp_RecibirOrdenCompra`
Recibe una línea de orden de compra.
- Actualiza `CantidadRecibida` en `OrdenesCompraDetalle`
- Actualiza estado de la OC (Parcial / Recibida)
- Crea o actualiza lote en `Inventario.Lotes`
- Actualiza `Inventario.InventarioStock` (UPSERT)
- Registra movimiento en `Kardex.KardexMovimientos`
- **Errores**: 52001 (OC ya recibida), 52000 (cantidad inválida)

### `Integracion.sp_ProcesarEventoEntrante`
Procesa un evento de venta recibido de Visions.
- Busca el mapeo de artículo
- Descuenta del inventario de ventas (`InventarioReportadoVisions`)
- Genera evento saliente si aplica
- Marca el evento como procesado

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
| `Integracion.EventosSalientes` | `TipoEvento` | `'ENTRADA_PRODUCTO_TERMINADO'`, `'TRASPASO_RECIBIDO'` |
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
Guarda preferencias personales por usuario (tema oscuro, vista lista/tarjetas por pantalla) como pares Clave/Valor genéricos, para no migrar el esquema cada vez que se agregue una nueva preferencia.
```sql
CREATE TABLE Seguridad.PreferenciasUsuario (
    UsuarioID INT NOT NULL,
    Clave NVARCHAR(50) NOT NULL,
    Valor NVARCHAR(50) NOT NULL,
    FechaModificacion DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_PreferenciasUsuario PRIMARY KEY (UsuarioID, Clave),
    CONSTRAINT FK_PreferenciasUsuario_Usuario FOREIGN KEY (UsuarioID) REFERENCES Seguridad.Usuarios(UsuarioID)
);
```
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
