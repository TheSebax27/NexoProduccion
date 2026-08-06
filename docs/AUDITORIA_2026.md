# Auditoría Integral — NEXO ERP
**Fecha**: 2026-08-06 · **Alcance**: Arquitectura, CRM, integración ERP+CRM, navegación, UX/UI, base de datos, seguridad, rendimiento, funcionalidades faltantes, automatizaciones, IA, escalabilidad, nivel profesional.

> Este documento es un **informe de auditoría**, no un backlog ejecutado. Cada hallazgo describe el problema, por qué importa, su impacto, prioridad y una recomendación concreta. Las prioridades (Alta/Media/Baja) reflejan riesgo + esfuerzo, no solo severidad — algo de impacto alto pero esfuerzo bajo puede quedar en Alta aunque "no truene nada" hoy.
>
> **Metodología**: no es una lista de opiniones genéricas — cada hallazgo de esta ronda se verificó contra el código y la base de datos reales (`sys.columns`, `sys.indexes`, `appsettings.json`, controllers, DTOs) el mismo día de esta auditoría. Donde se cita un archivo o una consulta, es porque se leyó directamente.

---

## Resumen ejecutivo

NEXO ERP es, para ser un sistema construido internamente sin equipo dedicado de arquitectura, **sorprendentemente consistente**: un patrón de Feature Slices disciplinado, separación de capas real (Web nunca toca la BD directo), convenciones de error bien pensadas (`THROW` en SQL → middleware → HTTP status), y un historial de decisiones documentado en `CLAUDE.md` que la mayoría de proyectos de este tamaño no tiene.

Los huecos reales no son de "mal código" — son los típicos de un sistema que creció **módulo por módulo, resolviendo el problema inmediato**, sin una capa transversal (seguridad centralizada, auditoría, notificaciones unificadas, IA, multi-tenencia). Ese es exactamente el tipo de deuda que separa "un ERP interno que funciona" de "un producto que se puede vender a terceros" — y es corregible sin reescribir nada, porque la base (Feature Slices + Dapper + Blazor Server) escala bien si se le agregan esas capas transversales.

**Los 5 hallazgos de mayor prioridad** (detalle en cada sección):
1. **Clave JWT hardcodeada en texto plano en `appsettings.json`**, dentro del repositorio — riesgo de seguridad real, no teórico (sección 9).
2. **Sistema mono-inquilino (single-tenant) de raíz** — no hay ni una columna `EmpresaID`/`TenantID` en ninguna tabla. Vender esto a más de un cliente hoy significa una instalación completa por cliente, no una fila nueva (sección 14).
3. **CRM y ERP se sienten como dos sistemas pegados, no uno solo** — no hay embudo de ventas, cotizaciones, ni conversión de una oportunidad en una Orden de Producción/Despacho/Factura sin volver a teclear todo (secciones 3 y 4).
4. **El buscador global y las notificaciones no conocen los 6 módulos construidos este año** (RRHH, CRM, Planificación, Logística, Proyectos, Facturación) — quedaron fuera cuando se construyeron (secciones 5 y 6).
5. **Documentación de arquitectura desactualizada** (`docs/architecture.md` solo documentaba 6 módulos de los 19 que existen) — corregido como parte de esta misma auditoría, ver sección "Documentación actualizada" al final.

---

## 1. Arquitectura

### 1.1 — La estructura general es sólida y consistente
**No es un problema, es una fortaleza a preservar.** Cada módulo backend sigue el mismo patrón (`Dtos/`, `Servicio.cs` con interfaz+implementación en el mismo archivo, `Controller.cs`), documentado en `docs/architecture.md` sección 4 y aplicado sin excepciones en 19 módulos. Blazor Server nunca toca la base de datos directo — todo pasa por `NexoApiClient`. Esto es exactamente el nivel de disciplina que un evaluador externo (o un nuevo desarrollador) esperaría encontrar.

### 1.2 — Sin capa de dominio compartida entre módulos que se solapan
**Problema**: `Kardex.KardexMovimientos` es el registro central de verdad de inventario, pero **6 módulos distintos** le escriben directamente con su propio SQL repetido (Producción al iniciar/cerrar OP, Compras al recibir, Inventario en bajas/traspasos/ajustes, Logística en despachos, Integración en eventos de Visions). No hay un "InventarioDomainService" único que centralice "descuenta stock siguiendo FEFO y registra Kardex" — cada módulo reimplementa su propio cursor FEFO.
**Por qué es un problema**: si mañana cambia la regla de negocio de FEFO (ej. agregar prioridad por vencimiento próximo + rotación ABC), hay que tocar 4-5 stored procedures distintos en paralelo, con riesgo real de que uno quede desactualizado.
**Impacto**: Medio-Alto — no rompe nada hoy, pero es la fuente más probable de un bug futuro por inconsistencia entre módulos.
**Prioridad**: Media.
**Recomendación**: extraer la lógica FEFO común a un único stored procedure parametrizable (`Kardex.sp_DescontarStockFEFO`) que los demás SPs invoquen, en vez de repetir el cursor. No requiere reescribir nada del lado C#, es un refactor puramente de SQL.

### 1.3 — `IDbConnectionFactory` es la única abstracción de datos — está bien, pero sin política de resiliencia
**Problema**: `SqlConnectionFactory.CreateConnection()` crea una conexión ADO.NET simple, sin retry policy (`Polly` o similar) ante caídas transitorias de red/BD.
**Por qué es un problema**: en un entorno on-premise con una sola instancia de SQL Server, un timeout momentáneo (reinicio del servicio SQL, saturación de red) tumba la request completa sin reintento, y el usuario ve un error genérico en vez de que el sistema se recupere solo.
**Impacto**: Bajo hoy (ambiente controlado, un solo servidor), pero crece si el sistema se despliega en un entorno con más latencia de red (nube, VPN).
**Prioridad**: Baja.
**Recomendación**: envolver `CreateConnection()` con una política de reintento simple (3 intentos, backoff exponencial) usando `Polly`, sin cambiar la interfaz `IDbConnectionFactory`.

### 1.4 — Escalabilidad de la arquitectura actual: buena para 1 empresa, no para varias (ver sección 14)
La arquitectura *interna* (Feature Slices, capas separadas) sí es escalable en el sentido de "crecer en funcionalidad durante años" — agregar un módulo 20 no es más difícil que agregar el módulo 19, el patrón ya está probado. El límite real no es de código, es de **modelo de datos** (sección 14).

### 1.5 — Dependencias: pocas y bien justificadas
Dapper (sin ORM pesado), MudBlazor (única librería de UI), QuestPDF (Community, gratis <1M USD de ingresos — **ojo con esto si la empresa crece**, ver 1.6). No hay dependencias huérfanas ni paquetes duplicados. Esto es inusualmente limpio para un proyecto de este tamaño.

### 1.6 — Riesgo de licenciamiento QuestPDF, silencioso
**Problema**: `Program.cs` fija `QuestPDF.Settings.License = LicenseType.Community`, válido solo para empresas con ingresos anuales **menores a 1M USD**. Es un `TODO` comentado en el código, no un control automático.
**Por qué es un problema**: si el sistema se vende como producto a una empresa que factura más de eso, seguir en modo Community es una violación de licencia — y nadie lo va a notar hasta una auditoría de software.
**Impacto**: Bajo probabilidad, pero Alto si ocurre (riesgo legal/reputacional, no técnico).
**Prioridad**: Baja (mientras sea un solo cliente interno) → **Alta** el día que se venda como producto a terceros.
**Recomendación**: dejar una nota explícita en `CLAUDE.md` (ya existe) y añadir una verificación en el proceso de onboarding de cada cliente nuevo: "¿factura más de 1M USD/año? → licencia comercial de QuestPDF".

---

## 2. Organización del ERP

### 2.1 — Los módulos actuales cubren el ciclo operativo real, pero faltan 2 piezas estructurales
Lo que existe (Producción, Inventario, Compras, Catálogo, CRM, RRHH, Planificación, Logística, Proyectos, Facturación, BI) cubre razonablemente bien una PyME industrial. **Falta Contabilidad/Finanzas** (fuera de alcance explícito, entendido) y **falta un módulo de Configuración de Negocio centralizado** — hoy "Settings" solo tiene nombre/logo de empresa; en un ERP profesional, Configuración es donde viven: numeración de documentos (folios de factura/despacho), impuestos, monedas, plantillas de documentos, campos personalizados por empresa.

### 2.2 — Facturación quedó desconectada de Logística/Inventario por decisión explícita — está bien documentado el porqué, pero genera doble captura
**Problema**: hoy, para vender algo con entrega física, un usuario podría tener que crear un **Despacho** (que sí descuenta stock) y por separado una **Factura** (que no lo hace) — dos formularios, mismos artículos, mismo cliente.
**Por qué es un problema**: doble captura de datos es la causa #1 de errores de digitación en cualquier ERP (cantidades que no cuadran entre el despacho y la factura).
**Impacto**: Alto a mediano plazo, en cuanto el volumen de ventas con entrega crezca.
**Prioridad**: Alta.
**Recomendación**: fue una decisión consciente y correcta para el primer release (evitar acoplar dos módulos nuevos a la vez). El siguiente paso natural es un botón "Generar Factura desde este Despacho" en `DetalleDespachoDialog.razor` que prellene cliente + líneas — el usuario sigue pudiendo facturar sin despacho (venta de mostrador) pero no vuelve a teclear cuando sí hay entrega física.

### 2.3 — Dependencias entre módulos: mayormente correctas, con una inconsistencia de nomenclatura
`Proyectos` depende de `Rrhh.Empleados` (responsables) y `Crm.Clientes` — correcto. `Logistica` depende de `Crm.Clientes` e `Inventario` — correcto. La única rareza: **`Catalogo.ClientesYCentrosTrabajoController.cs`** sigue con ese nombre aunque Clientes se movió a `Crm` hace varias fases (el comentario en el código lo explica, pero el nombre del archivo confunde a cualquiera que no haya leído `CLAUDE.md`).
**Prioridad**: Baja (cosmético, no rompe nada).
**Recomendación**: renombrar a `CentrosTrabajoController.cs` en el próximo refactor que toque ese archivo — no vale la pena un cambio aislado solo por el nombre.

### 2.4 — Propuesta de reestructuración del menú por "áreas de negocio" (no por módulo técnico)
Hoy el menú lateral lista módulos en el orden en que se construyeron (Producción, Inventario, Compras, Logística, Catálogo, Planificación, CRM, RRHH, Facturación, Administración). Un ERP de nivel profesional agrupa por **área funcional del negocio**, no por orden de creación:
- **Operaciones**: Producción, Inventario, Compras, Logística
- **Comercial**: CRM, Facturación, Planificación (demanda/metas son comerciales, no solo de producción)
- **Personas**: RRHH, Proyectos (si los proyectos son de servicio, van con RRHH; si son de producción, con Operaciones)
- **Configuración**: Catálogo, Administración

**Prioridad**: Media (impacto en UX real, esfuerzo bajo — es reordenar `NavMenu.razor`, no tocar lógica).

---

## 3. CRM

### 3.1 — Lo que existe es sólido para "gestión de relación" pero no cubre el ciclo comercial completo
Construido: Clientes (con responsable, NIT único, documentos, contactos múltiples), Interacciones/Bitácora, Historial unificado, Leads con pipeline de 5 etapas, Clientes Fríos (alertas). Esto es un CRM de **seguimiento**, no un CRM de **ventas**.

### 3.2 — Falta el corazón de un CRM comercial: Oportunidades y Cotizaciones
**Problema**: un Lead se convierte directo en Cliente (`ConvertirLeadAsync`) — no hay un paso intermedio de "Oportunidad" con valor estimado, probabilidad de cierre, y fecha esperada de cierre. Tampoco existe Cotización (una propuesta formal con líneas de artículos y precios, previa a la venta, que el cliente puede aceptar o rechazar).
**Por qué es un problema**: sin Oportunidades, no hay manera de responder "¿cuánto dinero tengo en el embudo este mes?" — que es la pregunta #1 que hace cualquier gerente comercial. Sin Cotizaciones, cada venta empieza desde cero en Facturación, sin registro de qué se le ofreció al cliente antes de que aceptara.
**Impacto**: Alto — es la funcionalidad que más se espera de "un CRM" y hoy no existe.
**Prioridad**: Alta.
**Recomendación**: agregar `Crm.Oportunidades` (LeadID/ClienteID, ValorEstimado, Probabilidad %, EtapaEmbudo [Prospección/Calificación/Propuesta/Negociación/Ganada/Perdida], FechaCierreEsperada) y `Crm.Cotizaciones` (Cliente, líneas artículo+cantidad+precio, validez, Estado [Enviada/Aceptada/Rechazada/Vencida]). Una Cotización Aceptada debería poder convertirse en Factura con un clic (mismo patrón ya usado para Lead→Cliente).
**Ejemplo de implementación**: mismo patrón que `ConvertirLeadAsync` — una transacción que crea la Factura con las líneas de la Cotización y marca la Cotización como `CONVERTIDA`.

### 3.3 — Falta Embudo de Ventas visual (Kanban de Oportunidades)
Depende de 3.2. Una vez existan Oportunidades, la vista natural es un Kanban por etapa (mismo componente que ya se construyó para Tareas de Proyectos — reutilizable).
**Prioridad**: Media (depende de que 3.2 exista primero).

### 3.4 — Falta Agenda/Actividades con recordatorio, más allá de "Próximo Contacto"
Hoy `Crm.Clientes.ProximoContacto` es una sola fecha por cliente, sin tipo de actividad (llamada/reunión/tarea) ni recordatorio. Un CRM profesional tiene actividades programadas independientes del cliente (ej. "llamar a 5 clientes fríos hoy") con vista de calendario/agenda del vendedor.
**Impacto**: Medio.
**Prioridad**: Media.
**Recomendación**: nueva tabla `Crm.Actividades` (Tipo, Titulo, FechaHora, ResponsableID, ClienteID NULL, Completada) + vista de agenda semanal por responsable.

### 3.5 — Reportes de CRM: solo existen como parte de BI, no hay reportes dedicados de comercial
El Dashboard tiene "Clientes Nuevos" e "Interacciones" — no hay reporte de: vendedor con más cierres, tasa de conversión de Lead a Cliente, tiempo promedio de conversión, valor de cartera por responsable.
**Prioridad**: Media.
**Recomendación**: una vez exista Oportunidades (3.2), estos reportes son consultas SQL directas sobre esa tabla — bajo esfuerzo, alto valor percibido.

### 3.6 — Campañas, Automatizaciones, Email, WhatsApp — correctamente diferidos, no un hueco a llenar ahora
Esto ya se discutió explícitamente con el usuario y quedó en pausa por decisión consciente (requiere infraestructura de mensajería externa que no existe hoy). **No es un hallazgo de esta auditoría, es una decisión de producto ya tomada** — se documenta aquí solo para que quede registrado en el mismo lugar que el resto del análisis de CRM.

### 3.7 — Propuesta de estructura completa de CRM (objetivo, no todo de una vez)
```
CRM
├── Clientes (existe)
│   ├── Contactos (existe)
│   ├── Documentos (existe)
│   └── Historial unificado (existe)
├── Leads (existe)
├── Oportunidades (falta — 3.2)
│   └── Embudo Kanban (falta — 3.3)
├── Cotizaciones (falta — 3.2)
├── Actividades / Agenda (falta — 3.4)
├── Reportes Comerciales (falta — 3.5)
└── Marketing (en pausa por decisión del usuario)
```

---

## 4. ERP + CRM Integrados

### 4.1 — Hoy se sienten como dos sistemas con un puente delgado, no uno solo
**Problema concreto**: `Crm.Clientes` es compartida (correcto — un solo cliente, un solo registro), pero el flujo comercial completo (Lead → Oportunidad → Cotización → Orden de Producción/Despacho → Factura → Cobro) no existe como una cadena — cada eslabón hay que iniciarlo a mano desde su propia pantalla, sin "continuar desde aquí".
**Impacto**: Alto — es la diferencia entre "un ERP con un CRM adentro" y "un CRM y un ERP que comparten tabla de Clientes".
**Prioridad**: Alta.
**Recomendación concreta**: 3 botones de continuidad, cada uno reutilizando el patrón transaccional ya probado en `ConvertirLeadAsync`:
1. Cotización Aceptada → botón "Generar Factura" (prellenar líneas).
2. Despacho Entregado → botón "Generar Factura" (ya mencionado en 2.2).
3. Factura Pendiente con saldo vencido → aparece automáticamente en "Clientes Fríos" o una alerta de cartera nueva (ver 4.2).

### 4.2 — Información que debería compartirse automáticamente y hoy no se comparte
- **Historial unificado del cliente** (`ObtenerHistorialAsync` en CRM) incluye Pedidos y Despachos — **no incluye Facturas** (construidas después de esa función). Un vendedor viendo la ficha de un cliente no ve si tiene facturas pendientes de pago.
  **Prioridad**: Alta — es una consulta `UNION ALL` adicional, mismo patrón ya existente, bajo esfuerzo.
- **Alertas de Proyectos con sobrecosto** no consideran si ese sobrecosto viene de un cliente con facturas vencidas — no hay correlación entre "cliente moroso" y "proyecto en curso para ese cliente".
  **Prioridad**: Media.

### 4.3 — Automatizaciones que faltan entre ERP y CRM
| Automatización propuesta | Elimina trabajo manual de | Prioridad |
|---|---|---|
| Al crear una Orden de Producción con Cliente, registrar automáticamente una Interacción tipo "Pedido" en la bitácora del cliente | Anotar manualmente "hoy pidió X" en la bitácora | Media |
| Al marcar una Factura como `PAGADA`, si el cliente estaba en la lista de "Clientes Fríos" por facturas vencidas, quitarlo automáticamente | Revisar manualmente si ya se puso al día | Baja (ya se recalcula solo, ver 4.2) |
| Al convertir un Lead con `FuenteContacto` = "Página Web", asignar automáticamente el Responsable según reglas de territorio/rotación | Asignación manual de leads entrantes | Baja (requiere reglas de negocio que no existen aún) |

---

## 5. Navegación

### 5.1 — El menú de acordeón es correcto para la cantidad de opciones actual, pero crece sin límite
Con 11 grupos y ~35 links, el acordeón ya es largo. Cada módulo nuevo (Facturación, y los que sugiere esta auditoría) lo alarga más.
**Prioridad**: Media.
**Recomendación**: la reagrupación por área de negocio (2.4) ayuda, pero a mediano plazo (15-20 módulos) va a hacer falta un buscador de módulos dentro del propio menú, no solo la barra de búsqueda global de datos.

### 5.2 — Buscador global: gap real, ya verificado en el código
**Problema confirmado**: `BusquedaService.cs` solo indexa Stock, Traspasos, Artículos, Clientes, Proveedores, Centros de Costo, Bodegas, Órdenes de Producción y Órdenes de Compra. **Empleados, Proyectos, Facturas, Leads y Despachos nunca se agregaron** — cada módulo nuevo de este año quedó fuera.
**Impacto**: Alto — un usuario que busca "Jhon" (un empleado) o el número de una factura no encuentra nada, sin ningún indicio de que ese módulo simplemente no está conectado.
**Prioridad**: Alta.
**Recomendación**: agregar 5 bloques más a `BuscarAsync` siguiendo exactamente el mismo patrón que los 9 existentes (mismo `IsInRole` check, mismo límite `MaxPorCategoria`). Es mecánico, no hay diseño nuevo que inventar.

### 5.3 — Nombres de opciones: en general claros, una inconsistencia notable
"Facturación" (nombre correcto y claro) vs "Gestión de Proyectos" que en el menú aparece truncado como solo "Proyectos" — está bien, pero el `PageTitle` de varias páginas nuevas (Cargos y Departamentos, Ausencias y Vacaciones) son más largos que el resto del menú (Empleados, Clientes) — no es un error, pero rompe el ritmo visual de la lista.
**Prioridad**: Baja.

### 5.4 — Páginas que deberían fusionarse: Catálogo tiene demasiadas subpáginas de un solo campo
`Centros de Costo`, `Centros de Trabajo`, `Bodegas`, `Proveedores` son 4 páginas separadas, cada una un CRUD de 3-5 campos. Para un administrador configurando el sistema por primera vez, son 4 clics distintos para configurar la estructura base de la empresa.
**Prioridad**: Baja-Media.
**Recomendación**: no fusionar el CRUD (mantener cada tabla separada en backend), pero sí fusionar la **pantalla** en un solo `MudTabs` (mismo patrón ya usado en `CargosDepartamentos.razor` de RRHH) — "Configuración de Catálogo" con 4 pestañas en vez de 4 páginas.

### 5.5 — Notificaciones (campana): mismo gap que el buscador
**Problema confirmado**: `NotificacionesService.cs` solo genera notificaciones de Sin Stock, Bajo Stock y Órdenes en Proceso. Las 3 tarjetas de alerta construidas en BI este año (Clientes Fríos, Desviaciones de Planificación, Alertas de Proyectos) **no aparecen en la campana** — solo son visibles si el usuario entra manualmente a Business Intelligence.
**Impacto**: Alto — el propósito de una alerta es que te busque a ti, no al revés.
**Prioridad**: Alta.
**Recomendación**: agregar 3 bloques más a `ObtenerResumenAsync`, mismo patrón (`NotificacionItem` con categoría/severidad/mensaje/link), reusando las queries que ya existen en `CrmService.ListarClientesFriosAsync`, `PlanificacionService.ListarDesviacionesAsync` y `ProyectosService.ListarAlertasAsync` — no hay SQL nuevo que escribir, solo conectar lo que ya existe.

---

## 6. Experiencia de Usuario (UX)

### 6.1 — El patrón "Gestionar" (diálogo con tabs) es eficiente en clics, pero tenía un bug real de sincronización
Ya corregido en esta misma sesión (`DialogService.ShowAsync` no esperaba `.Result`) — se documenta aquí porque es un hallazgo de UX real: antes del fix, el usuario hacía una acción dentro de "Gestionar" y la lista de fondo no reflejaba el cambio hasta la siguiente interacción, lo cual **se percibe como "el sistema no guardó"**, aunque sí guardó. Este tipo de bug es el que más rápido erosiona la confianza de un usuario en un ERP nuevo.
**Prioridad**: Ya resuelto (referencia).

### 6.2 — Cantidad de clics para crear un registro con relación: consistente y razonable
Crear Cliente → Contacto → Interacción son 3 acciones independientes bien separadas (no hay wizard de 5 pasos innecesario). Está en línea con lo que se espera de un ERP profesional (rapidez sobre ceremonia).

### 6.3 — El ícono de ayuda (`InfoAyuda`) en cada página es una buena decisión de UX, subutilizada
Existe en casi todas las páginas, pero el texto es descriptivo ("qué hace esta pantalla") y no instructivo ("cómo hago X"). Para un cliente nuevo sin capacitación previa, la diferencia importa.
**Prioridad**: Baja.
**Recomendación**: no es urgente, pero si se piensa vender el producto, vale la pena convertir `InfoAyuda` en un mini-tour contextual (ej. "Paso 1: elige un cliente. Paso 2: agrega artículos...") en las pantallas de flujo más largo (Crear Orden de Producción, Crear Factura).

### 6.4 — Confirmaciones antes de acciones irreversibles: aplicadas de forma inconsistente
Bien implementado en Despachos (Anular con motivo obligatorio), Ausencias (Aprobar/Rechazar), Traspasos (detalle antes de confirmar). **No implementado** en: eliminar un documento (Cliente/Empleado/Proyecto) — el botón "Eliminar" en las tablas de documentos no pide confirmación, borra directo.
**Impacto**: Medio — pérdida de datos accidental sin forma de deshacer.
**Prioridad**: Media.
**Recomendación**: agregar `DialogService.ShowMessageBox` de confirmación antes de los 3 métodos `EliminarDocumentoAsync` (Crm, Rrhh, Proyectos) — mismo componente ya usado en otras confirmaciones, 3 cambios mecánicos idénticos.

### 6.5 — Dónde el usuario pierde tiempo hoy (basado en flujos reales del sistema)
- **Buscar un cliente para facturar**: el `MudSelect` de Cliente en `FacturaDialog` es una lista plana sin buscador de texto — con 200+ clientes, desplazarse es lento. MudBlazor soporta `MudAutocomplete` con búsqueda server-side; hoy se usa `MudSelect` con toda la lista cargada en memoria.
  **Prioridad**: Media (crece con el volumen de clientes).
- **Repetir Cliente + Fecha** entre Despacho y Factura de la misma venta (ya cubierto en 2.2/4.1).

---

## 7. Diseño (UI)

### 7.1 — El sistema de diseño es coherente y de nivel profesional real
Paleta morado/oscuro consistente (`#7C5CFF`→`#5A3BFF` en degradados de estado activo, `#13131F` sidebar/topbar), tipografía definida (Mango Dream/Plus Jakarta Sans/Inter), tarjetas (`nexo-item-card`) y tablas con el mismo lenguaje visual en los 19 módulos. Esto **no es trivial** — la mayoría de sistemas internos crecen con estilos inconsistentes entre pantallas hechas en momentos distintos, y este no es el caso.

### 7.2 — Iconografía: Material Icons de forma consistente, sin mezclar librerías
Correcto y sin hallazgos.

### 7.3 — Jerarquía visual en tarjetas de resumen (Proyectos, Clientes): funcional pero densa
Las tarjetas de `Proyectos.razor` muestran hasta 6 líneas de datos (Prioridad, Estado, Cliente, Tareas, Hitos, Presupuesto, Costo) antes de cualquier acción. Es información completa, pero visualmente compite por atención sin un elemento dominante claro.
**Prioridad**: Baja.
**Recomendación**: destacar UN dato por tarjeta (ej. % de avance como barra de progreso visual) y mover el resto a un tooltip o a la vista de detalle — patrón común en Trello/Asana/Monday para tarjetas de proyecto.

### 7.4 — Responsive: cubierto en los componentes más recientes, no verificado sistemáticamente en los antiguos
El Kanban de Proyectos tiene media query explícita para colapsar a 1 columna en pantallas angostas. No hay evidencia de que las tablas más antiguas (Producción, Compras) se hayan probado en mobile — MudBlazor da responsive básico gratis (`MudTable` se adapta a `DataLabel`), pero no se verificó visualmente en esta sesión (ver nota de riesgo transversal más abajo).
**Prioridad**: Media.

### 7.5 — Dashboard (BI): denso mucho valor, sin capacidad de personalización
El Dashboard tiene KPIs, gráficos, y ahora 3 tarjetas de alerta agregadas este año — para un Administrador es información completa; para un Operario que solo necesita ver Órdenes de Producción, es ruido. No hay forma de personalizar qué widgets ve cada rol/usuario.
**Prioridad**: Baja-Media (nice-to-have, no bloqueante).
**Recomendación**: en un futuro release, permitir ocultar/reordenar tarjetas del Dashboard por preferencia de usuario — reutilizando el mismo mecanismo de `PreferenciasUsuario` (clave/valor genérico) ya construido para Favoritos.

### 7.6 — ¿Transmite "software empresarial premium"? Sí, con una salvedad
El lenguaje visual (dark sidebar + degradados morados + tarjetas limpias) está al nivel de SaaS modernos (Linear, Notion, HubSpot — de hecho la referencia que diste para el menú fue HubSpot). La salvedad: los diálogos de "Gestionar" con `MudTabs` densos (5-6 pestañas en Proyectos) empiezan a sentirse recargados comparado con productos que dedican una pantalla completa a cada entidad compleja. Es una decisión de espacio (modal vs. página completa) más que de estilo — ambos son válidos, pero vale la pena decidirlo conscientemente por tipo de entidad (ver 5.4 sobre fusionar/dividir páginas).

---

## 8. Base de Datos

### 8.1 — Estructura general: bien normalizada, sin señales de tablas redundantes
Los 19+ esquemas (`Catalogo`, `Produccion`, `Inventario`, `Kardex`, `Compras`, `Crm`, `Rrhh`, `Planificacion`, `Logistica`, `Proyectos`, `Facturacion`, `Seguridad`, `Organizacion`, `Auditoria`, `Integracion`) están correctamente separados por dominio, algo que muchos ERPs mal diseñados no logran (todo en `dbo`).

### 8.2 — Columnas heredadas que ya no se usan, dejadas a propósito — documentado pero acumulándose
`Crm.Clientes.Contacto` (reemplazado por `Crm.Contactos`), `Rrhh.Empleados.Cargo` (reemplazado por `CargoID`) — ambas se dejaron sin eliminar por seguridad al migrar, con nota explícita en `CLAUDE.md`. Es la decisión correcta en el momento de la migración, pero **ya pasó suficiente tiempo/varias fases** para limpiarlas con confianza.
**Impacto**: Bajo (no rompen nada), pero confunden a cualquiera que explore la BD directo sin leer la documentación primero.
**Prioridad**: Baja.
**Recomendación**: `ALTER TABLE ... DROP COLUMN` para ambas, ahora que se confirmó (por los datos migrados y verificados en esta misma sesión) que no queda ningún consumidor.

### 8.3 — `Seguridad.PreferenciasUsuario.Valor` como `NVARCHAR(MAX)` genérico: pragmático, con un límite a vigilar
Ya se amplió este año para poder guardar JSON (Favoritos). Es un patrón válido (Entity-Attribute-Value simplificado) para preferencias de usuario, pero si se usa para algo más estructurado en el futuro (ej. configuración compleja por módulo), un `NVARCHAR(MAX)` sin schema es difícil de consultar con SQL (no se puede hacer `WHERE` sobre un campo dentro del JSON sin `OPENJSON` en cada query).
**Prioridad**: Baja (mientras se use solo para preferencias simples).

### 8.4 — Sin auditoría real, a pesar de tener la tabla lista
**Problema confirmado**: `Auditoria.LogAuditoria` existe (mencionado ya en `session-summary.md` de meses atrás) **y sigue sin escribirse desde ningún servicio**, verificado en esta auditoría — ningún `Service.cs` de los 19 módulos inserta ahí.
**Por qué es un problema**: en un ERP empresarial, "¿quién cambió el precio de este artículo y cuándo?" es una pregunta que un cliente comercial **va a hacer**, y hoy no hay forma de responderla salvo revisando el historial manual de cada módulo (que además no todos tienen — Historial Laboral de RRHH sí, cambios de precio de Artículos no).
**Impacto**: Alto para venta como producto empresarial; Bajo-Medio para uso interno actual.
**Prioridad**: Alta (si se piensa comercializar) / Media (uso interno).
**Recomendación**: no revivir el patrón manual "cada servicio hace su propio INSERT a LogAuditoria" (no escala, se va a olvidar en el módulo 20). Mejor: un `IAuditoriaService` inyectado centralmente + un filtro/middleware que capture automáticamente método+ruta+usuario+payload en cada `POST`/`PUT`/`DELETE`, sin que cada desarrollador tenga que acordarse de llamarlo.

### 8.5 — Índices: correctos donde se verificaron, sin evidencia de problema de rendimiento hoy
`Kardex.KardexMovimientos` tiene 3 índices no-clustered bien elegidos (`Articulo+Bodega+Fecha`, `CentroCosto+Fecha`, `OrdenProduccion`) — cubren los patrones de consulta reales del sistema. Esto **contradice** el riesgo que `docs/session-summary.md` (desactualizado) todavía listaba como pendiente — ya está resuelto, solo faltaba actualizar la documentación (corregido como parte de esta auditoría).

### 8.6 — Sin partición/archivado de datos históricos
`Kardex.KardexMovimientos`, `Auditoria` (cuando exista), y los históricos de Facturación van a crecer indefinidamente sin estrategia de archivado. No es un problema hoy (volumen bajo), pero es la clase de decisión que es 10x más barata tomarla ahora (con tablas pequeñas) que en 3 años (con millones de filas).
**Prioridad**: Baja hoy → Media en 2-3 años.
**Recomendación**: no implementar particionamiento todavía (complejidad innecesaria a este volumen), pero sí definir ahora una política de retención (ej. "Kardex se consulta completo, pero un job archiva a una tabla `_Historico` lo mayor a 3 años") para no tener que diseñarla bajo presión cuando ya sea un problema de rendimiento real.

### 8.7 — Sin `EmpresaID`/`TenantID` en ninguna tabla — ver sección 14 (Escalabilidad) para el análisis completo
Se menciona aquí porque es, estructuralmente, un hallazgo de base de datos: cada tabla de negocio necesitaría esa columna + su índice correspondiente para soportar más de una empresa en la misma base.

---

## 9. Seguridad

### 9.1 — Clave JWT hardcodeada en `appsettings.json`, en texto plano, dentro del repositorio
**Problema confirmado** (leído directo del archivo): `"Jwt": { "Key": "NexoERP_ClaveSecretaSuperSegura2026_SistemaIntegrado#99", ... }`.
**Por qué es un problema**: cualquiera con acceso al repositorio (o a una copia de este) puede firmar sus propios tokens JWT válidos, incluyendo el rol `Administrador`, sin necesidad de credenciales. Es la vulnerabilidad más seria detectada en toda la auditoría.
**Impacto**: Alto — compromiso total de autenticación si el repo se filtra o se sube a un control de versiones público/compartido.
**Prioridad**: **Alta — la más alta de todo este informe.**
**Recomendación**: mover la clave a `appsettings.Development.json` (fuera de control de versiones, en `.gitignore`) para desarrollo, y a una variable de entorno o `dotnet user-secrets` en producción. Rotar la clave actual inmediatamente después del cambio (todas las sesiones activas se invalidan, pero es el costo correcto de cerrar el hueco).
**Ejemplo de implementación**:
```csharp
// Program.cs — en vez de leer directo de appsettings.json:
var jwtKey = builder.Configuration["Jwt:Key"]
    ?? Environment.GetEnvironmentVariable("NEXO_JWT_KEY")
    ?? throw new InvalidOperationException("Falta configurar NEXO_JWT_KEY");
```

### 9.2 — Sin endpoint de refresh token, a pesar de que el refresh token se genera y guarda
**Problema**: ya documentado desde `session-summary.md` (meses atrás) y **sigue sin resolverse** — el token de acceso expira a los 60 minutos y el usuario es expulsado sin aviso, sin poder renovar automáticamente aunque el sistema ya generó y guardó un refresh token de 7 días que nunca se usa.
**Impacto**: Medio — molestia real para el usuario (pierde trabajo no guardado si estaba a mitad de un formulario largo al expirar la sesión), pero no es una brecha de seguridad.
**Prioridad**: Alta (por antigüedad del pendiente y por impacto directo en UX diario).
**Recomendación**: `POST /api/auth/refresh` que reciba el refresh token, lo valide contra `Seguridad.SesionesUsuario`, y emita un nuevo access token — el frontend ya tiene `NexoApiClient` centralizado, es el lugar correcto para interceptar un 401 y reintentar con refresh antes de forzar logout.

### 9.3 — Sin validación declarativa en los DTOs de request (`DataAnnotations`)
**Problema confirmado**: `grep` sobre los DTOs de Request de todos los módulos → 0 coincidencias de `[Required]`, `[MaxLength]`, `[Range]`. Toda la validación de formato depende de que la base de datos rechace el INSERT (ej. `NVARCHAR(50)` truncaría silenciosamente o fallaría según el driver) o de checks manuales dispersos en los servicios.
**Impacto**: Medio — hoy funciona porque el equipo que escribe el frontend conoce las reglas de memoria, pero es frágil ante cualquier cliente de la API que no sea el propio NexoWeb (ej. una integración futura, o un ataque directo al endpoint).
**Prioridad**: Media.
**Recomendación**: no es necesario anotar los 19 módulos de una vez — empezar por los de datos financieros/sensibles (Facturación, Usuarios) con `[Required]`/`[Range(0, double.MaxValue)]` en montos y cantidades.

### 9.4 — Sin rate limiting en la API
**Problema confirmado**: no hay configuración de `AddRateLimiter` en `Program.cs`. Un endpoint como `/api/auth/login` puede recibir intentos ilimitados de fuerza bruta sin ningún throttling.
**Impacto**: Medio-Alto si el sistema queda expuesto a internet en algún momento (hoy, uso interno, riesgo bajo).
**Prioridad**: Media (uso interno actual) → Alta (si se expone a internet).
**Recomendación**: `AddRateLimiter` de ASP.NET Core (nativo desde .NET 7+, sin paquete adicional) con una política específica y más estricta para `/api/auth/*`.

### 9.5 — Roles: correctamente aplicados por endpoint, pero sin granularidad de permisos por acción dentro de un rol
Hoy son 4 roles fijos (Administrador, SupervisorPlanta, Operario, Bodeguero) codificados como strings en cada `[Authorize(Roles=...)]`. No hay tabla de permisos configurable — si mañana un cliente quiere un rol "Contador" que solo vea Facturación sin poder editar Producción, hay que tocar código y desplegar, no configurar desde la UI.
**Impacto**: Medio — limita qué tan personalizable es el sistema por cliente sin intervención del desarrollador.
**Prioridad**: Media (no bloqueante hoy, importante si se vende a terceros con necesidades distintas).
**Recomendación**: no es urgente reescribir el sistema de roles ahora, pero si se piensa comercializar, un modelo de "Rol → Permisos (tabla) → Feature" configurable es el estándar de cualquier ERP vendible (ver sección 15).

### 9.6 — Manejo de errores: patrón centralizado y bien pensado
`ExceptionHandlingMiddleware` mapea `SqlException` por rango de número a HTTP status correcto (404/409/400/500), sin filtrar detalles internos de la BD al cliente en el caso genérico. Esto es mejor práctica que lo que se ve en la mayoría de APIs internas — se destaca porque es una fortaleza real, no un hallazgo negativo.

### 9.7 — Sin protección explícita contra SQL Injection más allá de Dapper parametrizado
Dapper usa parámetros (`@Nombre`, etc.) en absolutamente todas las queries revisadas en esta sesión — no se encontró concatenación de string de usuario en ningún SQL. Esto es correcto y suficiente; se documenta para dejar registrado que sí se verificó, no se asumió.

---

## 10. Rendimiento

### 10.1 — Sin caché en ningún nivel
**Problema**: catálogos que cambian con poca frecuencia (Centros de Costo, Bodegas, Tipos de Artículo, Roles) se piden a la API completos en cada carga de página que los necesita — no hay `IMemoryCache` ni caché de cliente.
**Impacto**: Bajo con el volumen actual (una empresa, pocos usuarios concurrentes), pero es de las primeras optimizaciones que rinden con más usuarios/empresas.
**Prioridad**: Baja hoy → Media con más escala.
**Recomendación**: `IMemoryCache` con expiración corta (5-10 min) para los endpoints de catálogo puro (`GET /api/catalogo/centros-costo`, `/bodegas`, etc.) — cambio de una línea por endpoint, sin tocar el modelo de datos.

### 10.2 — Varios `Task.WhenAll` de 4-6 llamadas por página — patrón correcto, pero sin ninguna con caché
El patrón (`Task.WhenAll` de listas de catálogo + datos propios) es el correcto en Blazor Server para minimizar el tiempo de carga percibido. El problema no es el patrón, es que se ejecuta desde cero en cada navegación, sin aprovechar que Centros de Costo no cambió desde la última pantalla (relacionado con 10.1).

### 10.3 — Kardex limitado a `TOP 500` sin paginación real
Documentado desde hace meses como pendiente (`session-summary.md`), sigue así. Con el volumen actual no es un problema, pero es una limitación de diseño (el usuario no puede ver "la página 2" del histórico, solo los 500 más recientes filtrados).
**Prioridad**: Baja hoy → Media cuando el volumen de movimientos crezca lo suficiente para que 500 no cubra un día completo de operación.
**Recomendación**: `OFFSET/FETCH` con paginación real cuando se llegue a ese punto — no antes, sería complejidad prematura.

### 10.4 — Sin lazy loading de componentes pesados en Blazor Server
Blazor Server ya evita el problema de "bundle grande" que tendría una SPA (todo corre en el servidor), así que el lazy loading tradicional de JS no aplica igual. El riesgo real en Blazor Server es otro: **componentes que hacen demasiado trabajo en `OnInitializedAsync`** bloqueando el circuito para ese usuario. No se detectó ningún caso extremo en esta sesión, pero el Dashboard (con 6+ llamadas paralelas + 2 gráficos SVG generados en C#) es el candidato más pesado del sistema.
**Prioridad**: Baja (no hay evidencia de problema real, es una zona a vigilar).

### 10.5 — Sin límite de tamaño de respuesta / streaming para exportaciones grandes
`DashboardExportService` (Excel/PDF) genera el archivo completo en memoria antes de enviarlo. Con el volumen actual está bien; si un reporte de Kardex sin filtros se exportara completo (miles de filas), podría generar presión de memoria en el servidor.
**Prioridad**: Baja.

---

## 11. Funcionalidades Faltantes (qué esperaría un cliente empresarial)

Pensando como si NEXO ERP se vendiera hoy a una empresa mediana, esto es lo que un evaluador de compra buscaría y no encontraría (más allá de lo ya cubierto en CRM/Facturación):

| Funcionalidad | Por qué se espera | Prioridad |
|---|---|---|
| Numeración configurable de documentos (folios de Factura/Despacho/OC personalizables por empresa, ej. "FAC-2026-00001") | Requisito casi universal, muchos países lo exigen para facturación legal | Alta |
| Exportar cualquier tabla a Excel (no solo Dashboard) | Estándar mínimo esperado — "dame esto en Excel" es la pregunta #1 de cualquier gerente | Alta |
| Adjuntar archivos genéricos a cualquier entidad (no solo Cliente/Empleado/Proyecto) | Ej. adjuntar foto de un artículo dañado en una Baja de Inventario | Media |
| Papelera de reciclaje / soft-delete | Hoy varios `DELETE` son físicos e inmediatos (documentos) — sin posibilidad de recuperar | Media |
| Impresión de documentos (Despacho, Factura, Orden de Compra) en formato imprimible | Aunque no haya factura electrónica legal todavía, un PDF imprimible de cada transacción se espera | Alta |
| Historial de cambios de precio de artículos | Relacionado con 8.4 (auditoría) — hoy no se puede responder "¿cuánto costaba esto hace 3 meses?" | Media |
| Backup/restore desde la propia aplicación (no solo scripts SQL manuales) | Un cliente sin DBA propio necesita un botón, no un script | Media |
| Perfil de empresa multi-sucursal (más allá de Centro de Costo) | Centro de Costo cubre "área de negocio" pero no necesariamente "ubicación física" con dirección/impuestos propios | Baja |
| Términos y condiciones / firma digital en Cotizaciones | Una vez exista Cotizaciones (3.2) | Baja |

---

## 12. Automatizaciones

Más allá de las ya mencionadas en la sección 4 (ERP+CRM), automatizaciones inter-módulo con alto retorno:

| Automatización | Módulos que conecta | Elimina | Prioridad |
|---|---|---|---|
| Alerta automática cuando Stock de un artículo con Órdenes de Producción planificadas cae bajo lo necesario para cumplirlas | Inventario + Producción + Planificación | Revisar manualmente si hay materia prima suficiente antes de liberar una OP | Alta |
| Sugerencia automática de Orden de Compra cuando un artículo llega a su punto de reorden (ya existe el dato `RequierePedido`, falta la acción) | Inventario + Compras | Crear la OC desde cero cada vez, buscando manualmente qué está bajo | Alta |
| Al cerrar una Orden de Producción, sugerir automáticamente crear un Despacho si el Producto Terminado tiene Cliente asociado (MTO) | Producción + Logística | Acordarse manualmente de despachar lo recién producido | Media |
| Recordatorio automático de Ausencias próximas a vencer sin aprobar | RRHH | Revisar manualmente la lista de pendientes | Baja |
| Al vencer una Cotización sin respuesta (una vez exista, 3.2), marcarla automáticamente como Vencida y generar una tarea de seguimiento | CRM | Revisar manualmente fechas de vencimiento | Baja (depende de 3.2) |

---

## 13. Inteligencia Artificial

Dónde la IA aporta valor real (no "IA porque sí") dado el modelo de datos que ya existe:

| Aplicación de IA | Datos que ya existen para alimentarla | Valor | Prioridad |
|---|---|---|---|
| **Pronóstico de demanda** (sugerir `CantidadProyectada` en Planificación) | Ya existe una versión simple (promedio de 3 meses, `ObtenerSugerenciaDemandaAsync`) — el siguiente nivel es un modelo de series de tiempo real (estacionalidad, tendencia) | Alto | Media |
| **Predicción de quiebre de stock** | `Kardex.KardexMovimientos` histórico + `StockMinimo`/`PuntoReorden` ya existentes | Alto | Media |
| **Asistente en lenguaje natural sobre datos del ERP** ("¿cuánto vendimos el mes pasado a Cliente X?") | Todo el modelo relacional ya existe — un asistente con acceso de solo-lectura a un set curado de consultas | Alto (diferenciador comercial fuerte) | Media-Alta |
| **Detección de clientes en riesgo de abandono** (churn) | Historial de Interacciones + Facturas + fecha de última compra | Medio | Baja |
| **Recomendación de siguiente acción comercial** (ej. "este Lead lleva 10 días sin contacto, tiene alta probabilidad de perderse") | Una vez exista Oportunidades con probabilidad (3.2) | Medio | Baja (depende de 3.2) |
| **Generación automática de resúmenes de reportes** (texto en lenguaje natural sobre el Dashboard) | Los datos de BI ya están agregados y estructurados — es "solo" conectar un LLM a esos números | Medio | Media |
| **OCR de facturas/documentos de proveedor** para precargar Órdenes de Compra | No existe hoy, requeriría almacenamiento de imagen + servicio de OCR | Medio | Baja |

**Recomendación general**: el punto de entrada de más valor por menor esfuerzo es el **asistente en lenguaje natural** — no reemplaza reportes, los complementa para usuarios que no saben qué filtro usar. Puede construirse hoy mismo como una capa delgada: un endpoint que traduce la pregunta a una de un set curado de consultas parametrizadas (no SQL libre generado por IA, por seguridad) y devuelve el resultado + una respuesta en texto.

---

## 14. Escalabilidad (10 / 100 / 1000 empresas)

### 14.1 — Hoy: 1 empresa. Confirmado por diseño, no por configuración.
**Verificado en esta auditoría**: no existe ninguna columna `EmpresaID`/`TenantID` en ninguna tabla del sistema. `Organizacion.ConfiguracionEmpresa` es una fila única (`ConfiguracionID = 1`) — literalmente diseñada para una sola empresa. La cadena de conexión apunta a una única instancia de SQL Server, hardcodeada en `appsettings.json`.

### 14.2 — Para 10 empresas: viable hoy, pero por fuerza bruta (una instalación por cliente)
Con la arquitectura actual, "soportar 10 empresas" significa 10 bases de datos independientes + 10 despliegues de NexoApi/NexoWeb (aislamiento total, cero código compartido en runtime). Es operacionalmente viable para un producto vendido como "instalación on-premise por cliente", **no** para un SaaS donde 10 empresas comparten infraestructura.
**Esfuerzo para llegar aquí**: ya se está ahí. Es el modelo "un cliente, una instalación" — válido como estrategia comercial (muchos ERPs empiezan así), pero no escala en costo operativo pasado cierto número de clientes.

### 14.3 — Para 100 empresas: requiere multi-tenencia real — cambio estructural, no cosmético
**Qué cambiaría**: cada tabla de negocio necesita `EmpresaID`, cada query necesita filtrar por él (o usar Row-Level Security de SQL Server, que permite hacerlo sin tocar cada query manualmente), y la autenticación necesita resolver "a qué empresa pertenece este usuario" antes de emitir el JWT (agregar `EmpresaID` como claim).
**Impacto de no hacerlo**: a 100 empresas, 100 instalaciones independientes ya no es sostenible operacionalmente (100 bases de datos que mantener, actualizar, respaldar por separado).
**Prioridad**: Alta **si la estrategia comercial es SaaS multi-cliente**; Baja/no aplica si la estrategia sigue siendo "una instalación por cliente" (modelo on-premise/licenciado).
**Recomendación concreta**: la ruta de menor riesgo es **Row-Level Security (RLS) de SQL Server** — se agrega `EmpresaID` a cada tabla + una función de seguridad que filtra automáticamente según el `EmpresaID` de la sesión, sin tener que reescribir cada uno de los cientos de `SELECT`/`INSERT` ya existentes en los 19 módulos. Es el cambio de mayor apalancamiento: una vez la columna y la política RLS existen, el código Dapper actual sigue funcionando prácticamente sin cambios.

### 14.4 — Para 1000 empresas: además de multi-tenencia, se necesita arquitectura de despliegue distinta
A esa escala, una sola instancia de SQL Server y un solo proceso de NexoApi ya no alcanzan — se necesita: connection pooling agresivo, posible sharding de base de datos por grupo de clientes, balanceo de carga entre múltiples instancias de NexoApi (hoy son Scoped/stateless así que esto es viable sin rediseño), y Blazor Server necesitaría revisarse (cada usuario mantiene un circuito SignalR persistente en el servidor — a miles de usuarios concurrentes, el consumo de memoria del servidor crece linealmente; Blazor WebAssembly o un modelo híbrido podría ser necesario a esa escala).
**Prioridad**: Baja hoy — es una decisión a tomar cuando el negocio se acerque a esa escala, no antes (sobre-diseñar para 1000 empresas hoy sería la clase de complejidad prematura que ralentiza llegar a las primeras 10).

---

## 15. Nivel Profesional (frente a SAP B1, Dynamics 365, Odoo, NetSuite, Zoho)

No se trata de copiar esas plataformas — se trata de identificar **qué estándares** adoptan que NEXO todavía no tiene, independientemente del tamaño de la plataforma:

| Estándar de la industria | ¿NEXO lo tiene? | Comentario |
|---|---|---|
| Numeración de documentos configurable por empresa | No | Ver 11 — alta prioridad |
| Auditoría de cambios (quién, qué, cuándo) | No (tabla existe, sin uso) | Ver 8.4 — alta prioridad si se comercializa |
| Roles y permisos configurables (no solo hardcodeados) | Parcial (roles fijos) | Ver 9.5 |
| Multi-moneda | No | No evaluado como urgente — depende del mercado objetivo |
| Multi-idioma | No (todo en español) | Aceptable si el mercado objetivo es solo hispanohablante |
| Flujos de aprobación configurables (ej. una OC > $X requiere aprobación de un superior) | No | Hoy las validaciones son de rol fijo, no de monto/jerarquía |
| API pública documentada para integraciones de terceros | Parcial (Swagger existe, pero es para consumo interno de NexoWeb/NexoSyncAgent, no diseñada como API pública de producto) | Si se vende como plataforma, la API necesitaría versión (`/api/v1/`), rate limiting por cliente, y documentación orientada a terceros |
| Exportación masiva de datos (para no encerrar al cliente) | No | Un ERP de nivel profesional siempre permite "llevarte tus datos" — hoy no hay exportación completa de una empresa |
| Trazabilidad de lote/serie end-to-end | Parcial (lotes en Producción/Inventario con FEFO, pero no serializado individualmente) | Suficiente para la mayoría de PyMEs industriales, no para sectores regulados (farma/alimentos con trazabilidad serializada) |
| Panel de administración de la plataforma (para el proveedor, no el cliente) | No existe — no hay forma de ver "cuántas empresas usan el sistema, cuánto espacio ocupan, cuándo vence su licencia" | Necesario solo si el modelo de negocio es SaaS multi-cliente (ver sección 14) |

**Conclusión de esta sección**: NEXO ERP ya iguala o supera a soluciones genéricas tipo Odoo **en experiencia de usuario y coherencia visual** (el diseño no tiene nada que envidiarle a un SaaS moderno). Lo que lo separa de SAP B1/Dynamics/NetSuite no es calidad de ingeniería — es **madurez de plataforma**: multi-tenencia, auditoría, permisos configurables, y una API pensada para terceros. Todo eso es agregable sin reescribir lo que ya existe, porque la base arquitectónica (Feature Slices, capas separadas, patrón consistente) es exactamente el tipo de cimiento sobre el que esas capas se construyen sin fricción.

---

## Roadmap sugerido (orden de ataque, no todo a la vez)

**Ahora mismo (riesgo/esfuerzo bajo, impacto alto):**
1. Rotar y mover la clave JWT fuera del repositorio (9.1)
2. Conectar Clientes Fríos / Desviaciones / Alertas de Proyectos a la campana de notificaciones (5.5)
3. Agregar Empleados/Proyectos/Facturas/Leads/Despachos al buscador global (5.2)
4. Endpoint de refresh token (9.2)
5. Confirmación antes de eliminar documentos (6.4)

**Siguiente fase (construye el "CRM real"):**
6. Oportunidades + Cotizaciones (3.2, 3.3)
7. Botón "Generar Factura" desde Despacho/Cotización (2.2, 4.1)
8. Incluir Facturas en el historial unificado del cliente (4.2)

**Cuando se piense en vender el producto a terceros:**
9. Auditoría centralizada vía middleware (8.4)
10. Numeración configurable de documentos + exportación a Excel/PDF universal (11)
11. Decisión consciente sobre estrategia de escalamiento: on-premise por cliente vs. multi-tenencia real (14.3)
12. Roles/permisos configurables + API pública versionada (15)

---

## Documentación actualizada como parte de esta auditoría

- **`docs/architecture.md`**: actualizado — solo documentaba 6 de los 19 módulos existentes (faltaban RRHH, CRM, Planificación, Logística, Proyectos, Facturación, Traspasos, Notificaciones, Búsqueda, Preferencias, Configuración, Recetas). Ver ese archivo para el mapa completo y actualizado de endpoints por módulo.
- **`CLAUDE.md`**: se agregó un índice al inicio del archivo (30 secciones acumuladas) para que futuras sesiones ubiquen la sección relevante sin tener que leer el archivo completo — reduce consumo de tokens en sesiones futuras, que era uno de los objetivos explícitos de esta auditoría.
- **`docs/session-summary.md`**: quedó desactualizado (fechado 2026-08-01, antes de la mayoría de los módulos que existen hoy) — se marcó como histórico/superado al inicio del archivo, con referencia a `CLAUDE.md` como la fuente viva de decisiones y cambios.
