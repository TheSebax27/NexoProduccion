-- Patch: agrega CRM.PIPELINE y migra permisos desde CRM.LEADS / CRM.OPORTUNIDADES
-- Ejecutar UNA VEZ en cada BD de cliente que ya tenga migration_modulos_completa ejecutado.
-- Idempotente: usa IF NOT EXISTS.

-- 1. Insertar modulo CRM.PIPELINE si no existe
IF NOT EXISTS (SELECT 1 FROM Seguridad.Modulos WHERE Codigo = 'CRM.PIPELINE')
BEGIN
    INSERT INTO Seguridad.Modulos (Codigo, Nombre, Ruta, ModuloPadreID, Icono, Orden, EsGrupo)
    SELECT 'CRM.PIPELINE', 'Pipeline CRM', '/crm/pipeline', ModuloID, NULL, 21, 0
    FROM Seguridad.Modulos WHERE Codigo = 'CRM';

    PRINT 'Modulo CRM.PIPELINE insertado.';
END
ELSE
    PRINT 'Modulo CRM.PIPELINE ya existe, omitido.';

-- 2. Actualizar Orden de CRM.LEADS y CRM.OPORTUNIDADES al fondo (son legado)
UPDATE Seguridad.Modulos SET Orden = 29, Nombre = 'Leads (legado)'        WHERE Codigo = 'CRM.LEADS';
UPDATE Seguridad.Modulos SET Orden = 30, Nombre = 'Oportunidades (legado)' WHERE Codigo = 'CRM.OPORTUNIDADES';

-- 3. Otorgar CRM.PIPELINE a roles que ya tienen CRM.LEADS o CRM.OPORTUNIDADES
INSERT INTO Seguridad.PermisoModuloRol (RolID, ModuloID, Visible)
SELECT DISTINCT pmr.RolID,
    (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CRM.PIPELINE'),
    1
FROM Seguridad.PermisoModuloRol pmr
JOIN Seguridad.Modulos m ON m.ModuloID = pmr.ModuloID
WHERE m.Codigo IN ('CRM.LEADS', 'CRM.OPORTUNIDADES')
  AND pmr.Visible = 1
  AND NOT EXISTS (
    SELECT 1 FROM Seguridad.PermisoModuloRol x
    WHERE x.RolID = pmr.RolID
      AND x.ModuloID = (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CRM.PIPELINE')
  );

PRINT 'Permisos CRM.PIPELINE asignados a roles con LEADS/OPORTUNIDADES.';

-- 4. Otorgar CRM.PIPELINE a usuarios con permiso individual en CRM.LEADS o CRM.OPORTUNIDADES
IF OBJECT_ID('Seguridad.PermisoModuloUsuario', 'U') IS NOT NULL
BEGIN
    INSERT INTO Seguridad.PermisoModuloUsuario (UsuarioID, ModuloID, Visible)
    SELECT DISTINCT pmu.UsuarioID,
        (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CRM.PIPELINE'),
        1
    FROM Seguridad.PermisoModuloUsuario pmu
    JOIN Seguridad.Modulos m ON m.ModuloID = pmu.ModuloID
    WHERE m.Codigo IN ('CRM.LEADS', 'CRM.OPORTUNIDADES')
      AND pmu.Visible = 1
      AND NOT EXISTS (
        SELECT 1 FROM Seguridad.PermisoModuloUsuario x
        WHERE x.UsuarioID = pmu.UsuarioID
          AND x.ModuloID = (SELECT ModuloID FROM Seguridad.Modulos WHERE Codigo = 'CRM.PIPELINE')
      );

    PRINT 'Permisos CRM.PIPELINE asignados a usuarios con override individual.';
END

SELECT 'patch_pipeline_modulo completado' AS Resultado;
