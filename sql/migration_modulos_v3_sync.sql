-- ============================================================
-- migration_modulos_v3_sync.sql
-- Sincroniza Seguridad.Modulos con el estado real del NavMenu
-- (septiembre 2026)
--
-- Cambios:
--   1. Elimina OPERACIONES.MOVIMIENTOS (ruta /operaciones/movimientos
--      ya no existe en el proyecto)
--   2. Agrega módulos nuevos referenciados en NavMenu pero ausentes en DB:
--      FINANZAS + FINANZAS.GASTOS, FORMULARIOS.GESTOR, SOPORTE.TICKETS
--   3. Agrega módulos para rutas que estaban sin control de visibilidad:
--      CATALOGO.MAESTROS, PRODUCCION.CENTROS, CRM.CONOCIMIENTO
--   4. Otorga permisos apropiados a los módulos nuevos
-- Ejecutar UNA sola vez sobre cada BD.
-- ============================================================

-- ──────────────────────────────────────────────────────────
-- 1. Eliminar módulo obsoleto: OPERACIONES.MOVIMIENTOS
--    (la página /operaciones/movimientos fue eliminada del proyecto)
-- ──────────────────────────────────────────────────────────
DELETE FROM Seguridad.PermisoModuloUsuario
WHERE ModuloID = (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'OPERACIONES.MOVIMIENTOS');

DELETE FROM Seguridad.PermisoModuloRol
WHERE ModuloID = (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'OPERACIONES.MOVIMIENTOS');

DELETE FROM Seguridad.Modulos WHERE Codigo = 'OPERACIONES.MOVIMIENTOS';

-- ──────────────────────────────────────────────────────────
-- 2. Insertar módulos nuevos (idempotente con IF NOT EXISTS)
-- ──────────────────────────────────────────────────────────

-- ── FINANZAS (grupo padre) ──
IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'FINANZAS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('FINANZAS', 'Finanzas', NULL, NULL, 'MoneyOff', 15, 1);

-- ── FINANZAS.GASTOS (/finanzas/gastos) ──
-- Aparece en grupo "Comercial" del nav junto a Facturación
IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'FINANZAS.GASTOS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('FINANZAS.GASTOS', 'Gastos Operativos', '/finanzas/gastos',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'FINANZAS'), NULL, 1, 0);

-- ── FORMULARIOS.GESTOR (/formularios) ──
-- Aparece dentro del grupo CRM en el nav
IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'FORMULARIOS.GESTOR')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('FORMULARIOS.GESTOR', 'Formularios', '/formularios',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CRM'), NULL, 8, 0);

-- ── SOPORTE.TICKETS (/soporte/tickets) ──
-- Aparece dentro del grupo CRM en el nav
IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'SOPORTE.TICKETS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('SOPORTE.TICKETS', 'Tickets de Soporte', '/soporte/tickets',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CRM'), NULL, 9, 0);

-- ── CATALOGO.MAESTROS (/catalogo/maestros) ──
-- Catálogos maestros: tipos de artículo, presentaciones, etc.
-- Antes no tenía código → siempre visible. Ahora controlable.
IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CATALOGO.MAESTROS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CATALOGO.MAESTROS', 'Catálogos Maestros', '/catalogo/maestros',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CATALOGO'), NULL, 6, 0);

-- ── PRODUCCION.CENTROS (/catalogo/centros) ──
-- Gestión de centros de costo y trabajo; aparece en el grupo Producción del nav
IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'PRODUCCION.CENTROS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('PRODUCCION.CENTROS', 'Centros', '/catalogo/centros',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'PRODUCCION'), NULL, 4, 0);

-- ── CRM.CONOCIMIENTO (/conocimiento) ──
-- Base de conocimiento interna; aparece en el grupo CRM del nav
IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CRM.CONOCIMIENTO')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CRM.CONOCIMIENTO', 'Base de Conocimiento', '/conocimiento',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CRM'), NULL, 10, 0);

-- ──────────────────────────────────────────────────────────
-- 3. Permisos para los módulos nuevos
--    Regla general: sin fila en PermisoModuloRol => visible por defecto.
--    Aquí se insertan las filas de acceso explícito para cada rol.
-- ──────────────────────────────────────────────────────────

-- Administracion: ve todos los módulos nuevos
INSERT INTO Seguridad.PermisoModuloRol (RolID, ModuloID, Visible)
SELECT r.RolID, m.ModuloID, 1
FROM Seguridad.Roles r
CROSS JOIN Seguridad.Modulos m
WHERE r.Nombre = 'Administracion'
  AND m.Codigo IN (
    'FINANZAS', 'FINANZAS.GASTOS',
    'FORMULARIOS.GESTOR', 'SOPORTE.TICKETS',
    'CATALOGO.MAESTROS', 'PRODUCCION.CENTROS', 'CRM.CONOCIMIENTO'
  )
  AND NOT EXISTS (
    SELECT 1 FROM Seguridad.PermisoModuloRol x
    WHERE x.RolID = r.RolID AND x.ModuloID = m.ModuloID
  );

-- Jefes: ve FINANZAS.GASTOS, FORMULARIOS.GESTOR, SOPORTE.TICKETS, CATALOGO.MAESTROS, PRODUCCION.CENTROS, CRM.CONOCIMIENTO
INSERT INTO Seguridad.PermisoModuloRol (RolID, ModuloID, Visible)
SELECT r.RolID, m.ModuloID, 1
FROM Seguridad.Roles r
CROSS JOIN Seguridad.Modulos m
WHERE r.Nombre = 'Jefes'
  AND m.Codigo IN (
    'FINANZAS', 'FINANZAS.GASTOS',
    'FORMULARIOS.GESTOR', 'SOPORTE.TICKETS',
    'CATALOGO.MAESTROS', 'PRODUCCION.CENTROS', 'CRM.CONOCIMIENTO'
  )
  AND NOT EXISTS (
    SELECT 1 FROM Seguridad.PermisoModuloRol x
    WHERE x.RolID = r.RolID AND x.ModuloID = m.ModuloID
  );

-- Empleados: ve SOPORTE.TICKETS y CRM.CONOCIMIENTO (utilidad diaria)
INSERT INTO Seguridad.PermisoModuloRol (RolID, ModuloID, Visible)
SELECT r.RolID, m.ModuloID, 1
FROM Seguridad.Roles r
CROSS JOIN Seguridad.Modulos m
WHERE r.Nombre = 'Empleados'
  AND m.Codigo IN ('SOPORTE.TICKETS', 'CRM.CONOCIMIENTO')
  AND NOT EXISTS (
    SELECT 1 FROM Seguridad.PermisoModuloRol x
    WHERE x.RolID = r.RolID AND x.ModuloID = m.ModuloID
  );

-- Ventas: ve SOPORTE.TICKETS, FORMULARIOS.GESTOR (para encuestas), CRM.CONOCIMIENTO
INSERT INTO Seguridad.PermisoModuloRol (RolID, ModuloID, Visible)
SELECT r.RolID, m.ModuloID, 1
FROM Seguridad.Roles r
CROSS JOIN Seguridad.Modulos m
WHERE r.Nombre = 'Ventas'
  AND m.Codigo IN ('SOPORTE.TICKETS', 'FORMULARIOS.GESTOR', 'CRM.CONOCIMIENTO')
  AND NOT EXISTS (
    SELECT 1 FROM Seguridad.PermisoModuloRol x
    WHERE x.RolID = r.RolID AND x.ModuloID = m.ModuloID
  );

-- Subempleados: solo CRM.CONOCIMIENTO
INSERT INTO Seguridad.PermisoModuloRol (RolID, ModuloID, Visible)
SELECT r.RolID, m.ModuloID, 1
FROM Seguridad.Roles r
CROSS JOIN Seguridad.Modulos m
WHERE r.Nombre = 'Subempleados'
  AND m.Codigo IN ('CRM.CONOCIMIENTO')
  AND NOT EXISTS (
    SELECT 1 FROM Seguridad.PermisoModuloRol x
    WHERE x.RolID = r.RolID AND x.ModuloID = m.ModuloID
  );

-- ──────────────────────────────────────────────────────────
-- 4. Verificación final
-- ──────────────────────────────────────────────────────────
SELECT ModuloID, Codigo, Nombre, Ruta, Orden, EsGrupo
FROM Seguridad.Modulos
ORDER BY Orden, ModuloID;

PRINT 'migration_modulos_v3_sync.sql completada correctamente.';
