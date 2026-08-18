-- migration_facturacion_v2.sql
-- Agrega TipDoc, Turno, NroDoc, VisionsConfirmado a Facturacion.Facturas
-- y Nota a Facturacion.FacturaLineas.
-- EJECUTAR UNA VEZ en produccion.

-- 1. Columnas nuevas en Facturas
ALTER TABLE Facturacion.Facturas
    ADD TipDoc            VARCHAR(30)  NOT NULL CONSTRAINT DF_Facturas_TipDoc DEFAULT 'FACTURA',
        NroDoc            VARCHAR(50)  NULL,
        VisionsConfirmado BIT          NOT NULL CONSTRAINT DF_Facturas_VisionsConf DEFAULT 0;
GO

-- 2. CHECK en TipDoc
ALTER TABLE Facturacion.Facturas
    ADD CONSTRAINT CK_Facturas_TipDoc CHECK (
        TipDoc IN (
            'DEVOLUCION PROVEEDOR', 'EGRESO', 'FACTURA', 'GARANTIA',
            'NOTA DEBITO', 'NOTA DEVOLUCION', 'ORDEN COMPRA',
            'PERDIDA INVENTARIO', 'REMISION', 'SEPARADOS'
        )
    );
GO

-- 3. Nota por linea de factura
ALTER TABLE Facturacion.FacturaLineas
    ADD Nota VARCHAR(200) NULL;
GO

-- 4. Indice para filtrar por TipDoc + Fecha en el listado
CREATE INDEX IX_Facturas_TipDoc_Fecha
    ON Facturacion.Facturas (TipDoc, Fecha DESC);
GO
