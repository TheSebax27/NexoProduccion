-- ===========================================================
-- NEXO ERP - migration_iva_v1.sql
-- Crea catalogo.Iva calca de dbo.IVA de Visions.
-- Calca exacta: columnas Iva (int) y Descripcion (nvarchar 50).
-- TARJETA.IVAVALOR / IVADESCRIPCION almacenan copias planas,
-- no hay FK hacia esta tabla (igual patron que en Visions).
-- ===========================================================

IF NOT EXISTS (
    SELECT 1
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'catalogo' AND t.name = 'Iva'
)
BEGIN
    CREATE TABLE catalogo.Iva (
        IvaID       int IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_Iva PRIMARY KEY,
        Iva         int NOT NULL,
        Descripcion nvarchar(50) NULL
    );

    INSERT INTO catalogo.Iva (Iva, Descripcion) VALUES
        (0,  'EXENTO'),
        (5,  'IVA 5%'),
        (16, 'IVA 16%'),
        (19, 'IVA 19%'),
        (0,  'EXCLUIDO'),
        (0,  'ICUI Saludable'),
        (0,  'ICL Licores'),
        (0,  'IBUA Bebidas'),
        (0,  'INPP Plasticos');

    PRINT 'Tabla catalogo.Iva creada y poblada.';
END
ELSE
BEGIN
    PRINT 'catalogo.Iva ya existe - sin cambios.';
END
GO
