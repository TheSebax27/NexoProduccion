-- ============================================================
-- migration_modulos_v2_sync.sql
-- Sincroniza Seguridad.Modulos con el NavMenu actual:
--   1. Corrige el campo Orden para que el nav quede en secuencia
--      Ventas→CRM→Catalogo→Produccion→Inventario→Planificacion→RRHH→Admin
--   2. Inserta modulos nuevos que el nav referencia pero no estaban en la DB
--   3. NO elimina modulos obsoletos (pueden tener permisos configurados)
-- Ejecutar UNA sola vez sobre cada BD.
-- ============================================================

-- ──────────────────────────────────────────────────────────────────────
-- 1. Corregir Orden de grupos principales (refleja orden del nav lateral)
-- ──────────────────────────────────────────────────────────────────────
UPDATE Seguridad.Modulos SET Orden = 1  WHERE Codigo = 'BI';

-- Ventas agrupa: OPERACIONES + parte de CRM
UPDATE Seguridad.Modulos SET Orden = 10 WHERE Codigo = 'OPERACIONES';
UPDATE Seguridad.Modulos SET Orden = 11 WHERE Codigo = 'OPERACIONES.FACTURACION';
UPDATE Seguridad.Modulos SET Orden = 12 WHERE Codigo = 'OPERACIONES.DESPACHOS';
-- CRM.COTIZACIONES y CRM.CLIENTES aparecen bajo "Ventas" en el nav
UPDATE Seguridad.Modulos SET Orden = 13 WHERE Codigo = 'CRM.COTIZACIONES';
UPDATE Seguridad.Modulos SET Orden = 14 WHERE Codigo = 'CRM.CLIENTES';

-- CRM & Marketing (resto del grupo CRM)
UPDATE Seguridad.Modulos SET Orden = 20 WHERE Codigo = 'CRM';
UPDATE Seguridad.Modulos SET Orden = 21 WHERE Codigo = 'CRM.LEADS';
UPDATE Seguridad.Modulos SET Orden = 22 WHERE Codigo = 'CRM.OPORTUNIDADES';
UPDATE Seguridad.Modulos SET Orden = 23 WHERE Codigo = 'CRM.ACTIVIDADES';
UPDATE Seguridad.Modulos SET Orden = 24 WHERE Codigo = 'CRM.CAMPANAS';
UPDATE Seguridad.Modulos SET Orden = 25 WHERE Codigo = 'CRM.COMBOS';

-- Catalogo
UPDATE Seguridad.Modulos SET Orden = 30 WHERE Codigo = 'CATALOGO';
UPDATE Seguridad.Modulos SET Orden = 31 WHERE Codigo = 'CATALOGO.ARTICULOS';
UPDATE Seguridad.Modulos SET Orden = 32 WHERE Codigo = 'CATALOGO.PROVEEDORES';
UPDATE Seguridad.Modulos SET Orden = 33 WHERE Codigo = 'CATALOGO.CENTROSCOSTO';
UPDATE Seguridad.Modulos SET Orden = 34 WHERE Codigo = 'CATALOGO.CENTROSTRABAJO';
UPDATE Seguridad.Modulos SET Orden = 35 WHERE Codigo = 'CATALOGO.BODEGAS';

-- Produccion
UPDATE Seguridad.Modulos SET Orden = 40 WHERE Codigo = 'PRODUCCION';
UPDATE Seguridad.Modulos SET Orden = 41 WHERE Codigo = 'PRODUCCION.ORDENES';
UPDATE Seguridad.Modulos SET Orden = 42 WHERE Codigo = 'PRODUCCION.RECETAS';
UPDATE Seguridad.Modulos SET Orden = 43 WHERE Codigo = 'PRODUCCION.MAQUINARIA';

-- Inventario
UPDATE Seguridad.Modulos SET Orden = 50 WHERE Codigo = 'INVENTARIO';
UPDATE Seguridad.Modulos SET Orden = 51 WHERE Codigo = 'INVENTARIO.STOCK';
UPDATE Seguridad.Modulos SET Orden = 52 WHERE Codigo = 'INVENTARIO.KARDEX';
UPDATE Seguridad.Modulos SET Orden = 53 WHERE Codigo = 'INVENTARIO.AJUSTES';
UPDATE Seguridad.Modulos SET Orden = 54 WHERE Codigo = 'INVENTARIO.BAJAS';
UPDATE Seguridad.Modulos SET Orden = 55 WHERE Codigo = 'INVENTARIO.TRASPASOS';
UPDATE Seguridad.Modulos SET Orden = 56 WHERE Codigo = 'OPERACIONES.MOVIMIENTOS';

-- Planificacion
UPDATE Seguridad.Modulos SET Orden = 60 WHERE Codigo = 'PLANIFICACION';
UPDATE Seguridad.Modulos SET Orden = 61 WHERE Codigo = 'PLANIFICACION.DEMANDA';
UPDATE Seguridad.Modulos SET Orden = 62 WHERE Codigo = 'PLANIFICACION.METAS';
UPDATE Seguridad.Modulos SET Orden = 63 WHERE Codigo = 'PLANIFICACION.CALENDARIO';
UPDATE Seguridad.Modulos SET Orden = 64 WHERE Codigo = 'PLANIFICACION.PROYECTOS';

-- RRHH
UPDATE Seguridad.Modulos SET Orden = 70 WHERE Codigo = 'RRHH';
UPDATE Seguridad.Modulos SET Orden = 71 WHERE Codigo = 'RRHH.EMPLEADOS';
UPDATE Seguridad.Modulos SET Orden = 72 WHERE Codigo = 'RRHH.CARGOS';
UPDATE Seguridad.Modulos SET Orden = 73 WHERE Codigo = 'RRHH.HORARIOS';
UPDATE Seguridad.Modulos SET Orden = 74 WHERE Codigo = 'RRHH.ASISTENCIA';
UPDATE Seguridad.Modulos SET Orden = 75 WHERE Codigo = 'RRHH.AUSENCIAS';
UPDATE Seguridad.Modulos SET Orden = 76 WHERE Codigo = 'RRHH.ORGANIGRAMA';

-- Administracion
UPDATE Seguridad.Modulos SET Orden = 80 WHERE Codigo = 'RRHH.USUARIOS';

-- Modulos obsoletos (en DB pero no en nav actual) — dejarlos al final
UPDATE Seguridad.Modulos SET Orden = 900 WHERE Codigo = 'OPERACIONES.COMPRAS';

-- ──────────────────────────────────────────────────────────────────────
-- 2. Insertar modulos que puedan faltar (idempotente con IF NOT EXISTS)
-- ──────────────────────────────────────────────────────────────────────

-- CRM.COTIZACIONES (puede no estar si el seed no lo insertó bajo CRM)
IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CRM.COTIZACIONES')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CRM.COTIZACIONES', 'Cotizaciones', '/crm/cotizaciones',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CRM'), NULL, 13, 0);

-- CRM.CLIENTES
IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CRM.CLIENTES')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('CRM.CLIENTES', 'Clientes', '/crm/clientes',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CRM'), NULL, 14, 0);

-- PLANIFICACION.PROYECTOS
IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'PLANIFICACION.PROYECTOS')
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    VALUES ('PLANIFICACION.PROYECTOS', 'Proyectos', '/proyectos',
            (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'PLANIFICACION'), NULL, 64, 0);

-- ──────────────────────────────────────────────────────────────────────
-- 3. Verificacion: listar todos los modulos en el orden resultante
-- ──────────────────────────────────────────────────────────────────────
SELECT ModuloID, Codigo, Nombre, Orden, EsGrupo
FROM Seguridad.Modulos
ORDER BY Orden, ModuloID;

PRINT 'migration_modulos_v2_sync.sql completada correctamente.';
