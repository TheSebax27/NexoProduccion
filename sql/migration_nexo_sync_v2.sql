-- migration_nexo_sync_v2.sql
-- NEXO_ERP: multi-agente seguro para exportación de facturas a Visions.
-- Reemplaza ExportadaVisions BIT (columna única, no escala con múltiples agentes)
-- por una tabla de tracking por (FacturaID, CentroCostoID).
-- EJECUTAR UNA VEZ en NEXO_ERP (en SSMS).

-- 1. Columna CentroCostoID en Facturas (qué CC generó la venta)
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA='Facturacion' AND TABLE_NAME='Facturas' AND COLUMN_NAME='CentroCostoID')
BEGIN
    ALTER TABLE Facturacion.Facturas
        ADD CentroCostoID INT NULL
        CONSTRAINT FK_Facturas_CentrosCosto
            FOREIGN KEY REFERENCES Organizacion.CentrosCosto(CentroCostoID);
END
GO

-- 2. Tabla de tracking por agente (sustituye ExportadaVisions BIT)
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA='Facturacion' AND TABLE_NAME='FacturasExportadasVisions')
BEGIN
    CREATE TABLE Facturacion.FacturasExportadasVisions (
        FacturaID       INT          NOT NULL,
        CentroCostoID   INT          NOT NULL,
        FechaExportado  DATETIME2    NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_FacturasExportadasVisions PRIMARY KEY (FacturaID, CentroCostoID),
        CONSTRAINT FK_FEV_Facturas      FOREIGN KEY (FacturaID)     REFERENCES Facturacion.Facturas(FacturaID),
        CONSTRAINT FK_FEV_CentrosCosto  FOREIGN KEY (CentroCostoID) REFERENCES Organizacion.CentrosCosto(CentroCostoID)
    );
END
GO

-- 3. Eliminar columna ExportadaVisions (ya reemplazada por la tabla anterior)
IF EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA='Facturacion' AND TABLE_NAME='Facturas' AND COLUMN_NAME='ExportadaVisions')
BEGIN
    -- Eliminar constraint DEFAULT primero si existe
    DECLARE @constraintName NVARCHAR(200) = (
        SELECT dc.name
        FROM sys.default_constraints dc
        JOIN sys.columns c ON c.object_id = dc.parent_object_id AND c.column_id = dc.parent_column_id
        JOIN sys.tables t  ON t.object_id = dc.parent_object_id
        JOIN sys.schemas s ON s.schema_id = t.schema_id
        WHERE s.name = 'Facturacion' AND t.name = 'Facturas' AND c.name = 'ExportadaVisions'
    );
    IF @constraintName IS NOT NULL
        EXEC('ALTER TABLE Facturacion.Facturas DROP CONSTRAINT ' + @constraintName);

    ALTER TABLE Facturacion.Facturas DROP COLUMN ExportadaVisions;
END
GO

PRINT 'migration_nexo_sync_v2.sql ejecutado correctamente.';
