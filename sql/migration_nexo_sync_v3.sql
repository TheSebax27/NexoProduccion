-- migration_nexo_sync_v3.sql
-- NEXO_ERP: columnas de documento en EventosEntrantes para trazabilidad de ventas Visions.
-- Permite mostrar las ventas de Visions (TipDoc/NroDoc) en la pestaña de Facturación de NEXO Web
-- sin necesidad de conectar el API directamente a la BD de Visions (arquitectura multi-tenant).
-- EJECUTAR UNA VEZ en NEXO_ERP (en SSMS o sqlcmd).

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA='Integracion' AND TABLE_NAME='EventosEntrantes' AND COLUMN_NAME='TipDoc')
    ALTER TABLE Integracion.EventosEntrantes ADD TipDoc NVARCHAR(30) NULL;
GO

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA='Integracion' AND TABLE_NAME='EventosEntrantes' AND COLUMN_NAME='NroDoc')
    ALTER TABLE Integracion.EventosEntrantes ADD NroDoc NVARCHAR(80) NULL;
GO

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA='Integracion' AND TABLE_NAME='EventosEntrantes' AND COLUMN_NAME='NitCliente')
    ALTER TABLE Integracion.EventosEntrantes ADD NitCliente NVARCHAR(20) NULL;
GO

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA='Integracion' AND TABLE_NAME='EventosEntrantes' AND COLUMN_NAME='NombreCliente')
    ALTER TABLE Integracion.EventosEntrantes ADD NombreCliente NVARCHAR(200) NULL;
GO

-- Índice filtrado para acelerar la consulta de ventas Visions (solo filas con TipDoc)
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_EventosEntrantes_VentasVisions'
      AND object_id = OBJECT_ID('Integracion.EventosEntrantes'))
BEGIN
    SET QUOTED_IDENTIFIER ON;
    CREATE INDEX IX_EventosEntrantes_VentasVisions
        ON Integracion.EventosEntrantes (CentroCostoID, TipoEvento, FechaEventoOrigen)
        INCLUDE (TipDoc, NroDoc, NitCliente, NombreCliente, CodigoArticuloVisions, Cantidad, PrecioArticuloVisions)
        WHERE TipDoc IS NOT NULL;
END
GO

PRINT 'migration_nexo_sync_v3.sql ejecutado correctamente.';
