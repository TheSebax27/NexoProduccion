-- ============================================================
-- migration_modulos_v1.sql
-- Sistema de visibilidad de modulos por rol / usuario
-- Ejecutar UNA sola vez sobre la BD de produccion
-- ============================================================

-- ──────────────────────────────────────────────────────────
-- 1. Seguridad.Modulos  (catalogo de navegacion)
-- ──────────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'Seguridad.Modulos'))
BEGIN
    CREATE TABLE Seguridad.Modulos (
        ModuloID      INT IDENTITY(1,1) PRIMARY KEY,
        Codigo        NVARCHAR(60)  NOT NULL,
        Nombre        NVARCHAR(100) NOT NULL,
        Ruta          NVARCHAR(200) NULL,
        ModuloPadreID INT           NULL REFERENCES Seguridad.Modulos(ModuloID),
        Icono         NVARCHAR(100) NULL,
        Orden         INT           NOT NULL DEFAULT 0,
        EsGrupo       BIT           NOT NULL DEFAULT 0,
        CONSTRAINT UQ_Modulos_Codigo UNIQUE (Codigo)
    );
END
GO

-- ──────────────────────────────────────────────────────────
-- 2. Seguridad.PermisoModuloRol  (visibilidad por rol)
-- ──────────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'Seguridad.PermisoModuloRol'))
BEGIN
    CREATE TABLE Seguridad.PermisoModuloRol (
        RolID    INT NOT NULL REFERENCES Seguridad.Roles(RolID),
        ModuloID INT NOT NULL REFERENCES Seguridad.Modulos(ModuloID),
        Visible  BIT NOT NULL DEFAULT 1,
        CONSTRAINT PK_PermisoModuloRol PRIMARY KEY (RolID, ModuloID)
    );
END
GO

-- ──────────────────────────────────────────────────────────
-- 3. Seguridad.PermisoModuloUsuario  (override por usuario)
-- ──────────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'Seguridad.PermisoModuloUsuario'))
BEGIN
    CREATE TABLE Seguridad.PermisoModuloUsuario (
        UsuarioID INT NOT NULL REFERENCES Seguridad.Usuarios(UsuarioID),
        ModuloID  INT NOT NULL REFERENCES Seguridad.Modulos(ModuloID),
        Visible   BIT NOT NULL,
        CONSTRAINT PK_PermisoModuloUsuario PRIMARY KEY (UsuarioID, ModuloID)
    );
END
GO

-- ──────────────────────────────────────────────────────────
-- 4. Vincular Cargos con Rol predeterminado
-- ──────────────────────────────────────────────────────────
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'Rrhh.Cargos') AND name = N'RolPredeterminadoID'
)
BEGIN
    ALTER TABLE Rrhh.Cargos
    ADD RolPredeterminadoID INT NULL
        REFERENCES Seguridad.Roles(RolID);
END
GO

-- ──────────────────────────────────────────────────────────
-- 5. Seed: catalogo de modulos (grupos + hojas)
-- ──────────────────────────────────────────────────────────

-- BI (item raiz, no es grupo)
IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'BI')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('BI', 'Business Intelligence', '/', NULL, 'Insights', 1, 0);

-- Grupos principales
IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'PRODUCCION')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('PRODUCCION', 'Produccion', NULL, NULL, 'Factory', 2, 1);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'INVENTARIO')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('INVENTARIO', 'Inventario', NULL, NULL, 'Inventory2', 3, 1);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'OPERACIONES')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('OPERACIONES', 'Operaciones', NULL, NULL, 'SwapHoriz', 4, 1);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CATALOGO')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CATALOGO', 'Catalogo', NULL, NULL, 'Category', 5, 1);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'PLANIFICACION')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('PLANIFICACION', 'Planificacion', NULL, NULL, 'Timeline', 6, 1);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CRM')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CRM', 'CRM', NULL, NULL, 'Handshake', 7, 1);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'RRHH')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('RRHH', 'Recursos Humanos', NULL, NULL, 'Badge', 8, 1);

-- Hojas PRODUCCION
IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'PRODUCCION.ORDENES')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('PRODUCCION.ORDENES', 'Ordenes de Produccion', '/produccion/ordenes',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'PRODUCCION'), NULL, 1, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'PRODUCCION.RECETAS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('PRODUCCION.RECETAS', 'Recetas (BOM)', '/produccion/recetas',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'PRODUCCION'), NULL, 2, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'PRODUCCION.MAQUINARIA')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('PRODUCCION.MAQUINARIA', 'Maquinaria', '/produccion/maquinaria',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'PRODUCCION'), NULL, 3, 0);

-- Hojas INVENTARIO
IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'INVENTARIO.STOCK')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('INVENTARIO.STOCK', 'Consulta de Stock', '/inventario/stock',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'INVENTARIO'), NULL, 1, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'INVENTARIO.KARDEX')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('INVENTARIO.KARDEX', 'Kardex de Articulos', '/inventario/kardex',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'INVENTARIO'), NULL, 2, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'INVENTARIO.AJUSTES')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('INVENTARIO.AJUSTES', 'Ajuste de Inventario', '/inventario/ajustes',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'INVENTARIO'), NULL, 3, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'INVENTARIO.BAJAS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('INVENTARIO.BAJAS', 'Registrar Baja', '/inventario/bajas',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'INVENTARIO'), NULL, 4, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'INVENTARIO.TRASPASOS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('INVENTARIO.TRASPASOS', 'Traspasos', '/inventario/traspasos',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'INVENTARIO'), NULL, 5, 0);

-- Hojas OPERACIONES
IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'OPERACIONES.MOVIMIENTOS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('OPERACIONES.MOVIMIENTOS', 'Movimientos', '/operaciones/movimientos',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'OPERACIONES'), NULL, 1, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'OPERACIONES.COMPRAS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('OPERACIONES.COMPRAS', 'Ordenes de Compra', '/compras/ordenes',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'OPERACIONES'), NULL, 2, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'OPERACIONES.DESPACHOS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('OPERACIONES.DESPACHOS', 'Despachos', '/logistica/despachos',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'OPERACIONES'), NULL, 3, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'OPERACIONES.FACTURACION')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('OPERACIONES.FACTURACION', 'Facturacion', '/facturacion',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'OPERACIONES'), NULL, 4, 0);

-- Hojas CATALOGO
IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CATALOGO.ARTICULOS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CATALOGO.ARTICULOS', 'Articulos', '/catalogo/articulos',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CATALOGO'), NULL, 1, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CATALOGO.CENTROSCOSTO')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CATALOGO.CENTROSCOSTO', 'Centros de Costo', '/catalogo/centros-costo',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CATALOGO'), NULL, 2, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CATALOGO.CENTROSTRABAJO')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CATALOGO.CENTROSTRABAJO', 'Centros de Trabajo', '/catalogo/centros-trabajo',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CATALOGO'), NULL, 3, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CATALOGO.BODEGAS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CATALOGO.BODEGAS', 'Bodegas', '/catalogo/bodegas',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CATALOGO'), NULL, 4, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CATALOGO.PROVEEDORES')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CATALOGO.PROVEEDORES', 'Proveedores', '/catalogo/proveedores',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CATALOGO'), NULL, 5, 0);

-- Hojas PLANIFICACION
IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'PLANIFICACION.DEMANDA')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('PLANIFICACION.DEMANDA', 'Demanda Proyectada', '/planificacion/demanda',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'PLANIFICACION'), NULL, 1, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'PLANIFICACION.METAS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('PLANIFICACION.METAS', 'Metas de Venta', '/planificacion/metas-venta',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'PLANIFICACION'), NULL, 2, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'PLANIFICACION.CALENDARIO')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('PLANIFICACION.CALENDARIO', 'Calendario', '/planificacion/calendario',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'PLANIFICACION'), NULL, 3, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'PLANIFICACION.PROYECTOS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('PLANIFICACION.PROYECTOS', 'Proyectos', '/proyectos',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'PLANIFICACION'), NULL, 4, 0);

-- Hojas CRM
IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CRM.CLIENTES')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CRM.CLIENTES', 'Clientes', '/crm/clientes',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CRM'), NULL, 1, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CRM.LEADS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CRM.LEADS', 'Leads', '/crm/leads',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CRM'), NULL, 2, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CRM.OPORTUNIDADES')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CRM.OPORTUNIDADES', 'Oportunidades', '/crm/oportunidades',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CRM'), NULL, 3, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CRM.ACTIVIDADES')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CRM.ACTIVIDADES', 'Actividades', '/crm/actividades',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CRM'), NULL, 4, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CRM.COTIZACIONES')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CRM.COTIZACIONES', 'Cotizaciones', '/crm/cotizaciones',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CRM'), NULL, 5, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CRM.CAMPANAS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CRM.CAMPANAS', 'Campanas de Marketing', '/crm/campanas',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CRM'), NULL, 6, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CRM.COMBOS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CRM.COMBOS', 'Combos y Ofertas', '/marketing/combos',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CRM'), NULL, 7, 0);

-- Hojas RRHH
IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'RRHH.EMPLEADOS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('RRHH.EMPLEADOS', 'Empleados', '/rrhh/empleados',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'RRHH'), NULL, 1, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'RRHH.ASISTENCIA')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('RRHH.ASISTENCIA', 'Asistencia', '/rrhh/asistencia',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'RRHH'), NULL, 2, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'RRHH.HORARIOS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('RRHH.HORARIOS', 'Horarios', '/rrhh/horarios',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'RRHH'), NULL, 3, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'RRHH.CARGOS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('RRHH.CARGOS', 'Cargos y Departamentos', '/rrhh/cargos',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'RRHH'), NULL, 4, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'RRHH.AUSENCIAS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('RRHH.AUSENCIAS', 'Ausencias y Vacaciones', '/rrhh/ausencias',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'RRHH'), NULL, 5, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'RRHH.ORGANIGRAMA')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('RRHH.ORGANIGRAMA', 'Organigrama', '/rrhh/organigrama',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'RRHH'), NULL, 6, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'RRHH.USUARIOS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('RRHH.USUARIOS', 'Usuarios del Sistema', '/admin/usuarios',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'RRHH'), NULL, 7, 0);

-- ──────────────────────────────────────────────────────────
-- 6. Seed: permisos por rol (refleja el NavMenu actual)
--    Regla: sin fila en PermisoModuloRol => visible por defecto
--    El seed inserta solo las filas de acceso permitido (Visible=1).
--    El admin puede luego poner Visible=0 para restringir.
-- ──────────────────────────────────────────────────────────

-- Administracion: todo visible
INSERT INTO Seguridad.PermisoModuloRol (RolID, ModuloID, Visible)
SELECT r.RolID, m.ModuloID, 1
FROM Seguridad.Roles r
CROSS JOIN Seguridad.Modulos m
WHERE r.Nombre = 'Administracion'
  AND NOT EXISTS (
    SELECT 1 FROM Seguridad.PermisoModuloRol x
    WHERE x.RolID = r.RolID AND x.ModuloID = m.ModuloID
  );

-- Jefes
INSERT INTO Seguridad.PermisoModuloRol (RolID, ModuloID, Visible)
SELECT r.RolID, m.ModuloID, 1
FROM Seguridad.Roles r
CROSS JOIN Seguridad.Modulos m
WHERE r.Nombre = 'Jefes'
  AND m.Codigo IN (
    'BI',
    'PRODUCCION','PRODUCCION.ORDENES','PRODUCCION.RECETAS','PRODUCCION.MAQUINARIA',
    'INVENTARIO','INVENTARIO.STOCK','INVENTARIO.KARDEX',
    'CATALOGO','CATALOGO.ARTICULOS',
    'PLANIFICACION','PLANIFICACION.DEMANDA','PLANIFICACION.METAS',
    'PLANIFICACION.CALENDARIO','PLANIFICACION.PROYECTOS',
    'CRM','CRM.CLIENTES','CRM.LEADS','CRM.OPORTUNIDADES',
    'CRM.ACTIVIDADES','CRM.COTIZACIONES','CRM.CAMPANAS','CRM.COMBOS'
  )
  AND NOT EXISTS (
    SELECT 1 FROM Seguridad.PermisoModuloRol x
    WHERE x.RolID = r.RolID AND x.ModuloID = m.ModuloID
  );

-- Empleados
INSERT INTO Seguridad.PermisoModuloRol (RolID, ModuloID, Visible)
SELECT r.RolID, m.ModuloID, 1
FROM Seguridad.Roles r
CROSS JOIN Seguridad.Modulos m
WHERE r.Nombre = 'Empleados'
  AND m.Codigo IN (
    'BI',
    'INVENTARIO','INVENTARIO.STOCK','INVENTARIO.KARDEX',
    'INVENTARIO.AJUSTES','INVENTARIO.BAJAS','INVENTARIO.TRASPASOS',
    'OPERACIONES','OPERACIONES.MOVIMIENTOS','OPERACIONES.COMPRAS',
    'OPERACIONES.DESPACHOS','OPERACIONES.FACTURACION'
  )
  AND NOT EXISTS (
    SELECT 1 FROM Seguridad.PermisoModuloRol x
    WHERE x.RolID = r.RolID AND x.ModuloID = m.ModuloID
  );

-- Subempleados
INSERT INTO Seguridad.PermisoModuloRol (RolID, ModuloID, Visible)
SELECT r.RolID, m.ModuloID, 1
FROM Seguridad.Roles r
CROSS JOIN Seguridad.Modulos m
WHERE r.Nombre = 'Subempleados'
  AND m.Codigo IN (
    'PRODUCCION','PRODUCCION.ORDENES',
    'INVENTARIO','INVENTARIO.STOCK'
  )
  AND NOT EXISTS (
    SELECT 1 FROM Seguridad.PermisoModuloRol x
    WHERE x.RolID = r.RolID AND x.ModuloID = m.ModuloID
  );

-- Ventas
INSERT INTO Seguridad.PermisoModuloRol (RolID, ModuloID, Visible)
SELECT r.RolID, m.ModuloID, 1
FROM Seguridad.Roles r
CROSS JOIN Seguridad.Modulos m
WHERE r.Nombre = 'Ventas'
  AND m.Codigo IN (
    'INVENTARIO','INVENTARIO.STOCK',
    'CRM','CRM.CLIENTES','CRM.LEADS','CRM.OPORTUNIDADES',
    'CRM.ACTIVIDADES','CRM.COTIZACIONES','CRM.CAMPANAS','CRM.COMBOS'
  )
  AND NOT EXISTS (
    SELECT 1 FROM Seguridad.PermisoModuloRol x
    WHERE x.RolID = r.RolID AND x.ModuloID = m.ModuloID
  );

PRINT 'migration_modulos_v1.sql completada correctamente.';
