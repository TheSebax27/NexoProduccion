-- Agrega FechaInicioSyncVentas a Integracion.AgentesSync
-- NULL = traer todas las ventas; DATE = ignorar ventas anteriores a esa fecha.
--
-- EJECUTAR contra NEXO_ERP:
--   sqlcmd -S .\JONATHAN -d NEXO_ERP -E -i "C:\Produccion\migration_fecha_inicio_sync_ventas.sql"

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('Integracion.AgentesSync')
      AND name = 'FechaInicioSyncVentas'
)
BEGIN
    ALTER TABLE Integracion.AgentesSync
        ADD FechaInicioSyncVentas DATE NULL;
    PRINT 'Columna FechaInicioSyncVentas agregada a Integracion.AgentesSync.';
END
ELSE
    PRINT 'Columna FechaInicioSyncVentas ya existe — nada que hacer.';
