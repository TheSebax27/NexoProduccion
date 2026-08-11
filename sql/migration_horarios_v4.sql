-- ============================================================
-- Migración v4: RegistraSalida en Rrhh.Horarios
-- sqlcmd -S DESKTOP-V83PQ7M\JONATHAN -d NEXO_ERP -i C:\Produccion\sql\migration_horarios_v4.sql
-- ============================================================
SET NOCOUNT ON;

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA='Rrhh' AND TABLE_NAME='Horarios' AND COLUMN_NAME='RegistraSalida'
)
BEGIN
    ALTER TABLE Rrhh.Horarios ADD RegistraSalida BIT NOT NULL DEFAULT 1;
    PRINT '✓ Columna RegistraSalida agregada (DEFAULT 1 = sí registra salida).';
END
ELSE
    PRINT '! RegistraSalida ya existe, sin cambios.';
GO
