-- migration_finanzas_v1.sql
-- Módulo de Gastos Operativos: schema Finanzas.
-- Ejecutar una sola vez. Verificar con: SELECT TOP 5 * FROM Finanzas.GastosOperativos

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Finanzas')
    EXEC('CREATE SCHEMA Finanzas');
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('Finanzas.GastosOperativos'))
BEGIN
    CREATE TABLE Finanzas.GastosOperativos (
        GastoID         int             IDENTITY(1,1) PRIMARY KEY,
        Fecha           date            NOT NULL,
        Categoria       nvarchar(100)   NOT NULL,
        Descripcion     nvarchar(500)   NOT NULL,
        Monto           decimal(18,2)   NOT NULL,
        Proveedor       nvarchar(200)   NULL,
        Comprobante     nvarchar(200)   NULL,   -- número de factura/recibo
        CentroCostoID   int             NULL REFERENCES Organizacion.CentrosCosto(CentroCostoID),
        Notas           nvarchar(1000)  NULL,
        CreadoPor       int             NULL,
        FechaCreacion   datetime2       NOT NULL DEFAULT GETUTCDATE()
    );
END
GO

-- Índice para consultas por mes/categoría
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_GastosOp_Fecha_Cat' AND object_id = OBJECT_ID('Finanzas.GastosOperativos'))
    CREATE INDEX IX_GastosOp_Fecha_Cat ON Finanzas.GastosOperativos (Fecha DESC, Categoria);
GO

PRINT 'migration_finanzas_v1 OK';
