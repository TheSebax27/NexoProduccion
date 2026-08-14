-- ==========================================================================
-- migration_presentacion_v1.sql
-- Agrega Fracciones y Tipo a catalogo.Presentacion
-- Fracciones: cuantas unidades trae el embalaje (auto-llena el campo en Tarjetas)
-- Tipo: NULL/'UNIDADES' = embalaje de unidades, 'PESO' = embalaje por peso (activa campo Peso en articulo)
-- ==========================================================================

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('catalogo.Presentacion') AND name = 'Fracciones')
BEGIN
    ALTER TABLE catalogo.Presentacion ADD Fracciones decimal(10,2) NULL;
    PRINT 'Columna Fracciones agregada a catalogo.Presentacion.';
END
ELSE
    PRINT 'Fracciones ya existe.';

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('catalogo.Presentacion') AND name = 'Tipo')
BEGIN
    ALTER TABLE catalogo.Presentacion ADD Tipo nvarchar(20) NULL;
    PRINT 'Columna Tipo agregada a catalogo.Presentacion.';
END
ELSE
    PRINT 'Tipo ya existe.';
