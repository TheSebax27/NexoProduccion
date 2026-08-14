-- =============================================================
-- migration_tarjetas_v2.sql
-- NEXO ERP - Agosto 2026
-- Cambios:
--   1. Crea tablas catalogo: GruposMayores, GruposMenores, Marcas, Presentaciones
--      (calca exacta de Visions GRUPOMAYOR, GRUPOMENOR, MARCA, PRESENTACION)
--   2. Renombra catalogo.Articulos -> catalogo.Tarjetas
--   3. Agrega columnas Visions a catalogo.Tarjetas:
--      Referencia, Costo, PPPublico, PBodega, PCredito,
--      UPublico, UBodega, UCredito, MarcaCodigo, GrupoMenorCodigo,
--      PresentacionCodigo, Peso, IvaSiNo, IvaValor, IvaDescripcion,
--      Iva2(*), IvaDescripcion2(*)   (*) = adicion NEXO, no existe en Visions
-- =============================================================

USE NEXO_ERP;
GO

-- =====================================================
-- 1. NUEVAS TABLAS CATALOGO (calca de Visions)
-- =====================================================

-- GruposMayores  (= dbo.GRUPOMAYOR en Visions)
IF NOT EXISTS (
    SELECT 1 FROM sys.tables
    WHERE name = 'GruposMayores' AND schema_id = SCHEMA_ID('catalogo')
)
BEGIN
    CREATE TABLE catalogo.GruposMayores (
        Codigo  NVARCHAR(10)  NOT NULL,
        Nombre  NVARCHAR(255) NULL,
        CONSTRAINT PK_GruposMayores PRIMARY KEY (Codigo)
    );
    PRINT 'Tabla catalogo.GruposMayores creada.';
END
ELSE
    PRINT 'catalogo.GruposMayores ya existia, se omite.';
GO

-- GruposMenores  (= dbo.GRUPOMENOR en Visions)
-- PK compuesta (Codigo, GrupoMayor), igual que Visions
IF NOT EXISTS (
    SELECT 1 FROM sys.tables
    WHERE name = 'GruposMenores' AND schema_id = SCHEMA_ID('catalogo')
)
BEGIN
    CREATE TABLE catalogo.GruposMenores (
        Codigo      NVARCHAR(10)  NOT NULL,
        Nombre      NVARCHAR(255) NULL,
        GrupoMayor  NVARCHAR(10)  NOT NULL,
        CONSTRAINT PK_GruposMenores PRIMARY KEY (Codigo, GrupoMayor),
        CONSTRAINT FK_GruposMenores_GruposMayores
            FOREIGN KEY (GrupoMayor) REFERENCES catalogo.GruposMayores (Codigo)
    );
    PRINT 'Tabla catalogo.GruposMenores creada.';
END
ELSE
    PRINT 'catalogo.GruposMenores ya existia, se omite.';
GO

-- Marcas  (= dbo.MARCA en Visions)
IF NOT EXISTS (
    SELECT 1 FROM sys.tables
    WHERE name = 'Marcas' AND schema_id = SCHEMA_ID('catalogo')
)
BEGIN
    CREATE TABLE catalogo.Marcas (
        Codigo  NVARCHAR(10)  NOT NULL,
        Nombre  NVARCHAR(255) NULL,
        CONSTRAINT PK_Marcas PRIMARY KEY (Codigo)
    );
    PRINT 'Tabla catalogo.Marcas creada.';
END
ELSE
    PRINT 'catalogo.Marcas ya existia, se omite.';
GO

-- Presentaciones  (= dbo.PRESENTACION en Visions)
IF NOT EXISTS (
    SELECT 1 FROM sys.tables
    WHERE name = 'Presentaciones' AND schema_id = SCHEMA_ID('catalogo')
)
BEGIN
    CREATE TABLE catalogo.Presentaciones (
        Codigo        NVARCHAR(10) NOT NULL,
        Presentacion  NVARCHAR(50) NOT NULL,
        CONSTRAINT PK_Presentaciones PRIMARY KEY (Codigo)
    );
    PRINT 'Tabla catalogo.Presentaciones creada.';
END
ELSE
    PRINT 'catalogo.Presentaciones ya existia, se omite.';
GO

-- =====================================================
-- 2. RENOMBRAR catalogo.Articulos -> catalogo.Tarjetas
-- =====================================================
IF EXISTS (
    SELECT 1 FROM sys.tables WHERE name = 'Articulos' AND schema_id = SCHEMA_ID('catalogo')
)
AND NOT EXISTS (
    SELECT 1 FROM sys.tables WHERE name = 'Tarjetas' AND schema_id = SCHEMA_ID('catalogo')
)
BEGIN
    EXEC sp_rename 'catalogo.Articulos', 'Tarjetas';
    PRINT 'Tabla catalogo.Articulos renombrada a catalogo.Tarjetas.';
END
ELSE IF EXISTS (
    SELECT 1 FROM sys.tables WHERE name = 'Tarjetas' AND schema_id = SCHEMA_ID('catalogo')
)
    PRINT 'catalogo.Tarjetas ya existe, se omite el rename.';
ELSE
    PRINT 'ADVERTENCIA: catalogo.Articulos no existe. Verifica la base de datos.';
GO

-- =====================================================
-- 3. NUEVAS COLUMNAS EN catalogo.Tarjetas
-- =====================================================

-- Referencia Visions (codigo de TARJETA.REFERENCIA)
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('catalogo.Tarjetas') AND name = 'Referencia'
)
BEGIN
    ALTER TABLE catalogo.Tarjetas ADD Referencia NVARCHAR(30) NULL;
    PRINT 'Columna Referencia agregada.';
END
GO

-- Costo (TARJETA.COSTO)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('catalogo.Tarjetas') AND name='Costo')
BEGIN
    ALTER TABLE catalogo.Tarjetas ADD Costo DECIMAL(18,2) NULL;
    PRINT 'Columna Costo agregada.';
END
GO

-- Precios publico, bodega, credito
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('catalogo.Tarjetas') AND name='PPPublico')
BEGIN
    ALTER TABLE catalogo.Tarjetas ADD PPPublico DECIMAL(18,0) NULL;
    PRINT 'Columna PPPublico agregada.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('catalogo.Tarjetas') AND name='PBodega')
BEGIN
    ALTER TABLE catalogo.Tarjetas ADD PBodega DECIMAL(18,0) NULL;
    PRINT 'Columna PBodega agregada.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('catalogo.Tarjetas') AND name='PCredito')
BEGIN
    ALTER TABLE catalogo.Tarjetas ADD PCredito DECIMAL(18,0) NULL;
    PRINT 'Columna PCredito agregada.';
END
GO

-- Unidades publico, bodega, credito
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('catalogo.Tarjetas') AND name='UPublico')
BEGIN
    ALTER TABLE catalogo.Tarjetas ADD UPublico DECIMAL(18,2) NULL;
    PRINT 'Columna UPublico agregada.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('catalogo.Tarjetas') AND name='UBodega')
BEGIN
    ALTER TABLE catalogo.Tarjetas ADD UBodega DECIMAL(18,2) NULL;
    PRINT 'Columna UBodega agregada.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('catalogo.Tarjetas') AND name='UCredito')
BEGIN
    ALTER TABLE catalogo.Tarjetas ADD UCredito DECIMAL(18,2) NULL;
    PRINT 'Columna UCredito agregada.';
END
GO

-- Catalogo: Marca (TARJETA.MARCA -> Marcas.Codigo)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('catalogo.Tarjetas') AND name='MarcaCodigo')
BEGIN
    ALTER TABLE catalogo.Tarjetas ADD MarcaCodigo NVARCHAR(10) NULL;
    PRINT 'Columna MarcaCodigo agregada.';
END
GO

-- Catalogo: GrupoMenor (TARJETA.GRUPOMENOR -> GruposMenores.Codigo, ref sin FK formal)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('catalogo.Tarjetas') AND name='GrupoMenorCodigo')
BEGIN
    ALTER TABLE catalogo.Tarjetas ADD GrupoMenorCodigo NVARCHAR(10) NULL;
    PRINT 'Columna GrupoMenorCodigo agregada.';
END
GO

-- Catalogo: Presentacion (TARJETA.PRESENTACION -> Presentaciones.Codigo)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('catalogo.Tarjetas') AND name='PresentacionCodigo')
BEGIN
    ALTER TABLE catalogo.Tarjetas ADD PresentacionCodigo NVARCHAR(10) NULL;
    PRINT 'Columna PresentacionCodigo agregada.';
END
GO

-- Peso
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('catalogo.Tarjetas') AND name='Peso')
BEGIN
    ALTER TABLE catalogo.Tarjetas ADD Peso DECIMAL(18,2) NULL;
    PRINT 'Columna Peso agregada.';
END
GO

-- IVA (calca de Visions)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('catalogo.Tarjetas') AND name='IvaSiNo')
BEGIN
    ALTER TABLE catalogo.Tarjetas ADD IvaSiNo NVARCHAR(2) NULL; -- 'SI' / 'NO'
    PRINT 'Columna IvaSiNo agregada.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('catalogo.Tarjetas') AND name='IvaValor')
BEGIN
    ALTER TABLE catalogo.Tarjetas ADD IvaValor SMALLINT NULL; -- ej. 19 (para 19%)
    PRINT 'Columna IvaValor agregada.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('catalogo.Tarjetas') AND name='IvaDescripcion')
BEGIN
    ALTER TABLE catalogo.Tarjetas ADD IvaDescripcion NVARCHAR(50) NULL; -- ej. 'IVA 19%'
    PRINT 'Columna IvaDescripcion agregada.';
END
GO

-- IVA 2 (adicion NEXO: productos con doble impuesto, no existe en Visions)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('catalogo.Tarjetas') AND name='Iva2')
BEGIN
    ALTER TABLE catalogo.Tarjetas ADD Iva2 SMALLINT NULL;
    PRINT 'Columna Iva2 agregada.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('catalogo.Tarjetas') AND name='IvaDescripcion2')
BEGIN
    ALTER TABLE catalogo.Tarjetas ADD IvaDescripcion2 NVARCHAR(50) NULL;
    PRINT 'Columna IvaDescripcion2 agregada.';
END
GO

-- =====================================================
-- 4. FK LIGERAS (Marca y Presentacion tienen PK simple)
-- =====================================================
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Tarjetas_Marcas')
BEGIN
    ALTER TABLE catalogo.Tarjetas
        ADD CONSTRAINT FK_Tarjetas_Marcas
        FOREIGN KEY (MarcaCodigo) REFERENCES catalogo.Marcas (Codigo);
    PRINT 'FK_Tarjetas_Marcas creada.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_Tarjetas_Presentaciones')
BEGIN
    ALTER TABLE catalogo.Tarjetas
        ADD CONSTRAINT FK_Tarjetas_Presentaciones
        FOREIGN KEY (PresentacionCodigo) REFERENCES catalogo.Presentaciones (Codigo);
    PRINT 'FK_Tarjetas_Presentaciones creada.';
END
GO

-- GrupoMenorCodigo: sin FK formal (PK compuesta hace la relacion implicita, igual que Visions)

PRINT '=========================================';
PRINT 'migration_tarjetas_v2.sql COMPLETADA OK.';
PRINT '=========================================';
GO
