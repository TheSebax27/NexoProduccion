-- =============================================================
-- migration_tarjetas_v3.sql
-- NEXO ERP - Agosto 2026
-- Correcciones para alinear con Visions:
--   1. Renombrar tablas al singular (igual que Visions)
--      GruposMayores -> GrupoMayor
--      GruposMenores -> GrupoMenor
--      Marcas        -> Marca
--      Presentaciones -> Presentacion
--   2. Renombrar columna Marca.Nombre -> Marca.Marca
--      (en Visions la tabla MARCA tiene la columna MARCA, no NOMBRE)
--   3. Eliminar columna Tarjetas.Referencia
--      (el SKU de NEXO ES la Referencia de Visions; columna duplicada)
-- =============================================================

USE NEXO_ERP;
GO

-- =====================================================
-- 1. RENOMBRAR TABLAS (singular = igual que Visions)
-- =====================================================

-- GruposMayores -> GrupoMayor
IF EXISTS (SELECT 1 FROM sys.tables WHERE name='GruposMayores' AND schema_id=SCHEMA_ID('catalogo'))
AND NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='GrupoMayor' AND schema_id=SCHEMA_ID('catalogo'))
BEGIN
    EXEC sp_rename 'catalogo.GruposMayores', 'GrupoMayor';
    PRINT 'Tabla GruposMayores renombrada a GrupoMayor.';
END
ELSE
    PRINT 'GrupoMayor ya existe o GruposMayores no se encontro, se omite.';
GO

-- GruposMenores -> GrupoMenor
IF EXISTS (SELECT 1 FROM sys.tables WHERE name='GruposMenores' AND schema_id=SCHEMA_ID('catalogo'))
AND NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='GrupoMenor' AND schema_id=SCHEMA_ID('catalogo'))
BEGIN
    EXEC sp_rename 'catalogo.GruposMenores', 'GrupoMenor';
    PRINT 'Tabla GruposMenores renombrada a GrupoMenor.';
END
ELSE
    PRINT 'GrupoMenor ya existe o GruposMenores no se encontro, se omite.';
GO

-- Marcas -> Marca
IF EXISTS (SELECT 1 FROM sys.tables WHERE name='Marcas' AND schema_id=SCHEMA_ID('catalogo'))
AND NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='Marca' AND schema_id=SCHEMA_ID('catalogo'))
BEGIN
    EXEC sp_rename 'catalogo.Marcas', 'Marca';
    PRINT 'Tabla Marcas renombrada a Marca.';
END
ELSE
    PRINT 'Marca ya existe o Marcas no se encontro, se omite.';
GO

-- Presentaciones -> Presentacion
IF EXISTS (SELECT 1 FROM sys.tables WHERE name='Presentaciones' AND schema_id=SCHEMA_ID('catalogo'))
AND NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='Presentacion' AND schema_id=SCHEMA_ID('catalogo'))
BEGIN
    EXEC sp_rename 'catalogo.Presentaciones', 'Presentacion';
    PRINT 'Tabla Presentaciones renombrada a Presentacion.';
END
ELSE
    PRINT 'Presentacion ya existe o Presentaciones no se encontro, se omite.';
GO

-- =====================================================
-- 2. RENOMBRAR COLUMNA Marca.Nombre -> Marca.Marca
--    (en Visions la columna se llama MARCA, no NOMBRE)
-- =====================================================
IF EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('catalogo.Marca') AND name = 'Nombre'
)
BEGIN
    EXEC sp_rename 'catalogo.Marca.Nombre', 'Marca', 'COLUMN';
    PRINT 'Columna Marca.Nombre renombrada a Marca.Marca.';
END
ELSE
    PRINT 'La columna Marca.Marca ya existe o Nombre no se encontro, se omite.';
GO

-- =====================================================
-- 3. ELIMINAR columna Tarjetas.Referencia
--    El SKU de NEXO ES el REFERENCIA de Visions.
--    Ambos son nvarchar(30) / max_length=60. Duplicado.
-- =====================================================
IF EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('catalogo.Tarjetas') AND name = 'Referencia'
)
BEGIN
    ALTER TABLE catalogo.Tarjetas DROP COLUMN Referencia;
    PRINT 'Columna Tarjetas.Referencia eliminada (redundante con SKU = Visions REFERENCIA).';
END
ELSE
    PRINT 'La columna Tarjetas.Referencia no existe, se omite.';
GO

-- =====================================================
-- VERIFICACION FINAL
-- =====================================================
SELECT t.name AS Tabla, c.name AS Columna
FROM sys.tables t
JOIN sys.columns c ON c.object_id = t.object_id
WHERE t.name IN ('GrupoMayor','GrupoMenor','Marca','Presentacion','Tarjetas')
  AND SCHEMA_NAME(t.schema_id) = 'catalogo'
ORDER BY t.name, c.column_id;
GO

PRINT '=========================================';
PRINT 'migration_tarjetas_v3.sql COMPLETADA OK.';
PRINT '=========================================';
GO
