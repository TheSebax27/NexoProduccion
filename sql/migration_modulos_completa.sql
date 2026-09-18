-- ============================================================
-- migration_modulos_completa.sql
-- Combina v1 + v2 + v3 en un solo script idempotente.
-- Ejecutar UNA sola vez sobre la BD de produccion.
-- ============================================================

-- ──────────────────────────────────────────────────────────
-- 1. Tablas (ya existen en nexosql_compat2016.sql — IF NOT EXISTS las salta)
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

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'Rrhh.Cargos') AND name = N'RolPredeterminadoID'
)
BEGIN
    ALTER TABLE Rrhh.Cargos
    ADD RolPredeterminadoID INT NULL REFERENCES Seguridad.Roles(RolID);
END
GO

-- ──────────────────────────────────────────────────────────
-- 2. Seed: grupos principales
-- ──────────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'BI')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('BI', 'Business Intelligence', '/', NULL, 'Insights', 1, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'OPERACIONES')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('OPERACIONES', 'Operaciones', NULL, NULL, 'SwapHoriz', 10, 1);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CRM')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CRM', 'CRM', NULL, NULL, 'Handshake', 20, 1);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'FINANZAS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('FINANZAS', 'Finanzas', NULL, NULL, 'MoneyOff', 15, 1);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CATALOGO')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CATALOGO', 'Catalogo', NULL, NULL, 'Category', 30, 1);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'PRODUCCION')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('PRODUCCION', 'Produccion', NULL, NULL, 'Factory', 40, 1);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'INVENTARIO')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('INVENTARIO', 'Inventario', NULL, NULL, 'Inventory2', 50, 1);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'PLANIFICACION')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('PLANIFICACION', 'Planificacion', NULL, NULL, 'Timeline', 60, 1);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'RRHH')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('RRHH', 'Recursos Humanos', NULL, NULL, 'Badge', 70, 1);

-- ──────────────────────────────────────────────────────────
-- 3. Seed: hojas OPERACIONES (Comercial en el nav)
-- ──────────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'OPERACIONES.FACTURACION')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('OPERACIONES.FACTURACION', 'Facturacion', '/facturacion',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'OPERACIONES'), NULL, 11, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'OPERACIONES.DESPACHOS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('OPERACIONES.DESPACHOS', 'Despachos', '/logistica/despachos',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'OPERACIONES'), NULL, 12, 0);

-- ──────────────────────────────────────────────────────────
-- 4. Seed: hojas CRM (bajo grupo CRM.CLIENTES y CRM.COTIZACIONES
--    aparecen en seccion "Comercial" del nav pero codigo es CRM.*)
-- ──────────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CRM.COTIZACIONES')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CRM.COTIZACIONES', 'Cotizaciones', '/crm/cotizaciones',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CRM'), NULL, 13, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CRM.CLIENTES')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CRM.CLIENTES', 'Clientes', '/crm/clientes',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CRM'), NULL, 14, 0);

-- Pipeline unifica Leads + Oportunidades. Los codigos CRM.LEADS y CRM.OPORTUNIDADES
-- se mantienen por compatibilidad pero CRM.PIPELINE es el modulo activo en el nav.
IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CRM.PIPELINE')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CRM.PIPELINE', 'Pipeline CRM', '/crm/pipeline',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CRM'), NULL, 21, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CRM.LEADS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CRM.LEADS', 'Leads (legado)', '/crm/leads',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CRM'), NULL, 29, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CRM.OPORTUNIDADES')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CRM.OPORTUNIDADES', 'Oportunidades (legado)', '/crm/oportunidades',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CRM'), NULL, 30, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CRM.ACTIVIDADES')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CRM.ACTIVIDADES', 'Actividades', '/crm/actividades',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CRM'), NULL, 23, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CRM.CAMPANAS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CRM.CAMPANAS', 'Campanas de Marketing', '/crm/campanas',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CRM'), NULL, 24, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CRM.COMBOS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CRM.COMBOS', 'Combos y Ofertas', '/marketing/combos',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CRM'), NULL, 25, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'FORMULARIOS.GESTOR')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('FORMULARIOS.GESTOR', 'Formularios', '/formularios',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CRM'), NULL, 26, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'SOPORTE.TICKETS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('SOPORTE.TICKETS', 'Tickets de Soporte', '/soporte/tickets',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CRM'), NULL, 27, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CRM.CONOCIMIENTO')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CRM.CONOCIMIENTO', 'Base de Conocimiento', '/conocimiento',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CRM'), NULL, 28, 0);

-- ──────────────────────────────────────────────────────────
-- 5. Seed: hojas FINANZAS
-- ──────────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'FINANZAS.GASTOS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('FINANZAS.GASTOS', 'Gastos Operativos', '/finanzas/gastos',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'FINANZAS'), NULL, 16, 0);

-- ──────────────────────────────────────────────────────────
-- 6. Seed: hojas CATALOGO
-- ──────────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CATALOGO.ARTICULOS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CATALOGO.ARTICULOS', 'Articulos', '/catalogo/articulos',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CATALOGO'), NULL, 31, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CATALOGO.MAESTROS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CATALOGO.MAESTROS', 'Catalogos Maestros', '/catalogo/maestros',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CATALOGO'), NULL, 32, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CATALOGO.PROVEEDORES')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CATALOGO.PROVEEDORES', 'Proveedores', '/catalogo/proveedores',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CATALOGO'), NULL, 33, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CATALOGO.BODEGAS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CATALOGO.BODEGAS', 'Bodegas', '/catalogo/bodegas',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CATALOGO'), NULL, 34, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CATALOGO.CENTROSCOSTO')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CATALOGO.CENTROSCOSTO', 'Centros de Costo', '/catalogo/centros-costo',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CATALOGO'), NULL, 35, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CATALOGO.CENTROSTRABAJO')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CATALOGO.CENTROSTRABAJO', 'Centros de Trabajo', '/catalogo/centros-trabajo',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CATALOGO'), NULL, 36, 0);

-- ──────────────────────────────────────────────────────────
-- 7. Seed: hojas PRODUCCION
-- ──────────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'PRODUCCION.ORDENES')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('PRODUCCION.ORDENES', 'Ordenes de Produccion', '/produccion/ordenes',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'PRODUCCION'), NULL, 41, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'PRODUCCION.RECETAS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('PRODUCCION.RECETAS', 'Recetas (BOM)', '/produccion/recetas',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'PRODUCCION'), NULL, 42, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'PRODUCCION.MAQUINARIA')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('PRODUCCION.MAQUINARIA', 'Maquinaria', '/produccion/maquinaria',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'PRODUCCION'), NULL, 43, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'PRODUCCION.CENTROS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('PRODUCCION.CENTROS', 'Centros', '/catalogo/centros',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'PRODUCCION'), NULL, 44, 0);

-- ──────────────────────────────────────────────────────────
-- 8. Seed: hojas INVENTARIO
-- ──────────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'INVENTARIO.STOCK')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('INVENTARIO.STOCK', 'Consulta de Stock', '/inventario/stock',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'INVENTARIO'), NULL, 51, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'INVENTARIO.KARDEX')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('INVENTARIO.KARDEX', 'Kardex de Articulos', '/inventario/kardex',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'INVENTARIO'), NULL, 52, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'INVENTARIO.AJUSTES')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('INVENTARIO.AJUSTES', 'Ajuste de Inventario', '/inventario/ajustes',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'INVENTARIO'), NULL, 53, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'INVENTARIO.BAJAS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('INVENTARIO.BAJAS', 'Registrar Baja', '/inventario/bajas',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'INVENTARIO'), NULL, 54, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'INVENTARIO.TRASPASOS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('INVENTARIO.TRASPASOS', 'Traspasos', '/inventario/traspasos',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'INVENTARIO'), NULL, 55, 0);

-- ──────────────────────────────────────────────────────────
-- 9. Seed: hojas PLANIFICACION
-- ──────────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'PLANIFICACION.DEMANDA')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('PLANIFICACION.DEMANDA', 'Demanda Proyectada', '/planificacion/demanda',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'PLANIFICACION'), NULL, 61, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'PLANIFICACION.METAS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('PLANIFICACION.METAS', 'Metas de Venta', '/planificacion/metas-venta',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'PLANIFICACION'), NULL, 62, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'PLANIFICACION.CALENDARIO')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('PLANIFICACION.CALENDARIO', 'Calendario', '/planificacion/calendario',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'PLANIFICACION'), NULL, 63, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'PLANIFICACION.PROYECTOS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('PLANIFICACION.PROYECTOS', 'Proyectos', '/proyectos',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'PLANIFICACION'), NULL, 64, 0);

-- ──────────────────────────────────────────────────────────
-- 10. Seed: hojas RRHH
-- ──────────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'RRHH.EMPLEADOS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('RRHH.EMPLEADOS', 'Empleados', '/rrhh/empleados',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'RRHH'), NULL, 71, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'RRHH.CARGOS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('RRHH.CARGOS', 'Cargos y Departamentos', '/rrhh/cargos',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'RRHH'), NULL, 72, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'RRHH.HORARIOS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('RRHH.HORARIOS', 'Horarios', '/rrhh/horarios',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'RRHH'), NULL, 73, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'RRHH.ASISTENCIA')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('RRHH.ASISTENCIA', 'Asistencia', '/rrhh/asistencia',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'RRHH'), NULL, 74, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'RRHH.AUSENCIAS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('RRHH.AUSENCIAS', 'Ausencias y Vacaciones', '/rrhh/ausencias',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'RRHH'), NULL, 75, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'RRHH.ORGANIGRAMA')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('RRHH.ORGANIGRAMA', 'Organigrama', '/rrhh/organigrama',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'RRHH'), NULL, 76, 0);

IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'RRHH.USUARIOS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('RRHH.USUARIOS', 'Usuarios del Sistema', '/admin/usuarios',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'RRHH'), NULL, 80, 0);

-- ──────────────────────────────────────────────────────────
-- 11. Eliminar modulo obsoleto (v3)
-- ──────────────────────────────────────────────────────────
DELETE FROM Seguridad.PermisoModuloUsuario
WHERE ModuloID = (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'OPERACIONES.MOVIMIENTOS');

DELETE FROM Seguridad.PermisoModuloRol
WHERE ModuloID = (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'OPERACIONES.MOVIMIENTOS');

DELETE FROM Seguridad.Modulos WHERE Codigo = 'OPERACIONES.MOVIMIENTOS';

-- ──────────────────────────────────────────────────────────
-- 12. Permisos por rol (idempotente)
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
    'OPERACIONES','OPERACIONES.FACTURACION','OPERACIONES.DESPACHOS',
    'CRM','CRM.CLIENTES','CRM.COTIZACIONES','CRM.PIPELINE',
    'CRM.ACTIVIDADES','CRM.CAMPANAS','CRM.COMBOS','CRM.CONOCIMIENTO',
    'FINANZAS','FINANZAS.GASTOS',
    'FORMULARIOS.GESTOR','SOPORTE.TICKETS',
    'CATALOGO','CATALOGO.ARTICULOS','CATALOGO.MAESTROS','CATALOGO.PROVEEDORES',
    'CATALOGO.BODEGAS','CATALOGO.CENTROSCOSTO','CATALOGO.CENTROSTRABAJO',
    'PRODUCCION','PRODUCCION.ORDENES','PRODUCCION.RECETAS',
    'PRODUCCION.MAQUINARIA','PRODUCCION.CENTROS',
    'INVENTARIO','INVENTARIO.STOCK','INVENTARIO.KARDEX',
    'PLANIFICACION','PLANIFICACION.DEMANDA','PLANIFICACION.METAS',
    'PLANIFICACION.CALENDARIO','PLANIFICACION.PROYECTOS'
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
    'OPERACIONES','OPERACIONES.FACTURACION','OPERACIONES.DESPACHOS',
    'SOPORTE.TICKETS','CRM.CONOCIMIENTO'
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
    'INVENTARIO','INVENTARIO.STOCK',
    'CRM.CONOCIMIENTO'
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
    'CRM','CRM.CLIENTES','CRM.PIPELINE',
    'CRM.ACTIVIDADES','CRM.COTIZACIONES','CRM.CAMPANAS','CRM.COMBOS',
    'SOPORTE.TICKETS','FORMULARIOS.GESTOR','CRM.CONOCIMIENTO'
  )
  AND NOT EXISTS (
    SELECT 1 FROM Seguridad.PermisoModuloRol x
    WHERE x.RolID = r.RolID AND x.ModuloID = m.ModuloID
  );

-- ──────────────────────────────────────────────────────────
-- 13. Verificacion final
-- ──────────────────────────────────────────────────────────
SELECT ModuloID, Codigo, Nombre, Orden, EsGrupo
FROM Seguridad.Modulos
ORDER BY Orden, ModuloID;

PRINT 'migration_modulos_completa.sql ejecutada correctamente.';
