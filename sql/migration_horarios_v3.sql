-- ============================================================
-- Migración v3: Hacer nullable columnas legacy en Rrhh.Horarios
-- sqlcmd -S DESKTOP-V83PQ7M\JONATHAN -d NEXO_ERP -i C:\Produccion\sql\migration_horarios_v3.sql
-- ============================================================
SET NOCOUNT ON;

-- Eliminar defaults existentes si los hay antes de alterar columnas
DECLARE @df NVARCHAR(200);

SELECT @df = d.name FROM sys.default_constraints d
JOIN sys.columns c ON c.default_object_id = d.object_id
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name='Rrhh' AND t.name='Horarios' AND c.name='HoraEntrada';
IF @df IS NOT NULL EXEC('ALTER TABLE Rrhh.Horarios DROP CONSTRAINT ' + @df);

SELECT @df = d.name FROM sys.default_constraints d
JOIN sys.columns c ON c.default_object_id = d.object_id
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name='Rrhh' AND t.name='Horarios' AND c.name='HoraSalida';
IF @df IS NOT NULL EXEC('ALTER TABLE Rrhh.Horarios DROP CONSTRAINT ' + @df);

-- Hacer nullable las columnas legacy (ya reemplazadas por HorarioDias)
ALTER TABLE Rrhh.Horarios ALTER COLUMN HoraEntrada         TIME NULL;
ALTER TABLE Rrhh.Horarios ALTER COLUMN HoraSalida          TIME NULL;
ALTER TABLE Rrhh.Horarios ALTER COLUMN LunesActivo         BIT  NULL;
ALTER TABLE Rrhh.Horarios ALTER COLUMN MartesActivo        BIT  NULL;
ALTER TABLE Rrhh.Horarios ALTER COLUMN MiercolesActivo     BIT  NULL;
ALTER TABLE Rrhh.Horarios ALTER COLUMN JuevesActivo        BIT  NULL;
ALTER TABLE Rrhh.Horarios ALTER COLUMN ViernesActivo       BIT  NULL;
ALTER TABLE Rrhh.Horarios ALTER COLUMN SabadoActivo        BIT  NULL;
ALTER TABLE Rrhh.Horarios ALTER COLUMN DomingoActivo       BIT  NULL;

PRINT '✓ Columnas legacy de Rrhh.Horarios ahora son nullable.';
GO
