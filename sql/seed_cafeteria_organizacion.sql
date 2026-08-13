-- =============================================================================
-- Seed cafeteria / panaderia: fix encoding + datos organizacion
-- Ejecutar en orden: TiposMaquinaria -> CentrosCosto -> CentrosTrabajo -> Bodegas
-- =============================================================================
SET NOCOUNT ON;

-- =============================================================================
-- 1. FIX ENCODING en datos ya existentes
-- =============================================================================

-- Funcion inline que aplica todos los reemplazos sobre un texto
-- (SQL Server no tiene CREATE FUNCTION inline sin GO, asi que usamos subconsultas)

-- Fix Articulos.Nombre y Articulos.Descripcion
UPDATE Catalogo.Articulos
SET
    Nombre = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
             REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
             Nombre,
             N'Ã¡',N'a')  -- a con tilde -> a (sin tilde, ASCII seguro)
            ,N'Ã©',N'e')
            ,N'Ã­',N'i')
            ,N'Ã³',N'o')
            ,N'Ãº',N'u')
            ,N'Ã±',N'n')
            ,N'Ã‰',N'E')
            ,N'Ã"',N'O')
            ,N'Ãš',N'U')
            ,N'Ã',N'A')
            ,N'Ã¨',N'e')
            ,N'Ã²',N'o'),
    Descripcion = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                  REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                  ISNULL(Descripcion,N''),
                  N'Ã¡',N'a'),N'Ã©',N'e'),N'Ã­',N'i'),N'Ã³',N'o'),
                  N'Ãº',N'u'),N'Ã±',N'n'),N'Ã‰',N'E'),N'Ã"',N'O'),
                  N'Ãš',N'U'),N'Ã',N'A'),N'Ã¨',N'e'),N'Ã²',N'o')
WHERE Nombre LIKE N'%Ã%' OR Descripcion LIKE N'%Ã%';
PRINT '✓ Articulos corregidos.';

-- Fix TiposMaquinaria (tipos como "Bascula / Balanza", "Equipo de frio")
UPDATE Produccion.TiposMaquinaria
SET
    Nombre = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
             REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
             Nombre,
             N'Ã¡',N'a'),N'Ã©',N'e'),N'Ã­',N'i'),N'Ã³',N'o'),
             N'Ãº',N'u'),N'Ã±',N'n'),N'Ã‰',N'E'),N'Ã"',N'O'),
             N'Ãš',N'U'),N'Ã',N'A'),N'Ã¨',N'e'),N'Ã²',N'o'),
    Descripcion = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                  REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                  ISNULL(Descripcion,N''),
                  N'Ã¡',N'a'),N'Ã©',N'e'),N'Ã­',N'i'),N'Ã³',N'o'),
                  N'Ãº',N'u'),N'Ã±',N'n'),N'Ã‰',N'E'),N'Ã"',N'O'),
                  N'Ãš',N'U'),N'Ã',N'A'),N'Ã¨',N'e'),N'Ã²',N'o')
WHERE Nombre LIKE N'%Ã%' OR Descripcion LIKE N'%Ã%';
PRINT '✓ TiposMaquinaria corregidos.';

-- Fix Maquinaria (nombres de maquinas ingresadas como seed)
UPDATE Produccion.Maquinaria
SET
    Nombre = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
             REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
             Nombre,
             N'Ã¡',N'a'),N'Ã©',N'e'),N'Ã­',N'i'),N'Ã³',N'o'),
             N'Ãº',N'u'),N'Ã±',N'n'),N'Ã‰',N'E'),N'Ã"',N'O'),
             N'Ãš',N'U'),N'Ã',N'A'),N'Ã¨',N'e'),N'Ã²',N'o'),
    Modelo = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
             REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
             ISNULL(Modelo,N''),
             N'Ã¡',N'a'),N'Ã©',N'e'),N'Ã­',N'i'),N'Ã³',N'o'),
             N'Ãº',N'u'),N'Ã±',N'n'),N'Ã‰',N'E'),N'Ã"',N'O'),
             N'Ãš',N'U'),N'Ã',N'A'),N'Ã¨',N'e'),N'Ã²',N'o')
WHERE Nombre LIKE N'%Ã%' OR Modelo LIKE N'%Ã%';
PRINT '✓ Maquinaria corregida.';

-- Fix RecetaBOM (nombres de recetas)
UPDATE Produccion.RecetaBOM
SET NombreReceta = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                  REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                  NombreReceta,
                  N'Ã¡',N'a'),N'Ã©',N'e'),N'Ã­',N'i'),N'Ã³',N'o'),
                  N'Ãº',N'u'),N'Ã±',N'n'),N'Ã‰',N'E'),N'Ã"',N'O'),
                  N'Ãš',N'U'),N'Ã',N'A'),N'Ã¨',N'e'),N'Ã²',N'o')
WHERE NombreReceta LIKE N'%Ã%';
PRINT '✓ Recetas corregidas.';


-- =============================================================================
-- 2. CENTROS DE COSTO
-- =============================================================================
-- Codigo: CC-PROD, CC-VENTA, CC-ADMIN, CC-BODEGA, CC-DESPACHO

INSERT INTO Organizacion.CentrosCosto (Codigo, Nombre, TipoCentro, Direccion, Telefono)
SELECT Codigo, Nombre, TipoCentro, Direccion, Telefono
FROM (VALUES
    ('CC-COCINA',   'Cocina y Produccion',       'PLANTA_CENTRAL', 'Zona de cocina principal',     NULL),
    ('CC-PANADERIA','Panaderia y Pasteleria',     'PLANTA_CENTRAL', 'Area de horneado y masas',     NULL),
    ('CC-VENTA',    'Punto de Venta',             'PUNTO_VENTA',    'Mostrador y caja principal',   NULL),
    ('CC-SALON',    'Salon de Clientes',          'PUNTO_VENTA',    'Area de mesas y atencion',     NULL),
    ('CC-BODEGA',   'Bodega y Logistica',         'PLANTA_CENTRAL', 'Zona de almacenamiento',       NULL),
    ('CC-ADMIN',    'Administracion',             'PLANTA_CENTRAL', 'Oficinas administrativas',     NULL),
    ('CC-DESPACHO', 'Despacho y Domicilios',      'PLANTA_CENTRAL', 'Zona de empaque y entregas',   NULL)
) AS T(Codigo, Nombre, TipoCentro, Direccion, Telefono)
WHERE NOT EXISTS (
    SELECT 1 FROM Organizacion.CentrosCosto WHERE Codigo = T.Codigo
);
PRINT '✓ Centros de Costo insertados.';


-- =============================================================================
-- 3. CENTROS DE TRABAJO
-- (dependen de CentrosCosto ya insertados)
-- =============================================================================

INSERT INTO Organizacion.CentrosTrabajo (Nombre, CentroCostoID, CostoHoraManoObra, CostoHoraCIF)
SELECT T.Nombre, cc.CentroCostoID, T.MO, T.CIF
FROM (VALUES
    -- Cocina
    ('Zona de Hornos',          'CC-COCINA',    12000, 8000),
    ('Prep Caliente y Salsas',  'CC-COCINA',    10000, 5000),
    ('Fritura y Plancha',       'CC-COCINA',    10000, 6000),
    -- Panaderia
    ('Amasado y Laminado',      'CC-PANADERIA', 11000, 7000),
    ('Decoracion y Acabados',   'CC-PANADERIA', 12000, 4000),
    ('Prep Fria y Mousse',      'CC-PANADERIA', 11000, 4000),
    -- Bodega
    ('Recepcion de Insumos',    'CC-BODEGA',     8000, 3000),
    ('Empaque y Etiquetado',    'CC-BODEGA',     8000, 3500),
    -- Despacho
    ('Despacho Domicilios',     'CC-DESPACHO',   9000, 4000),
    ('Control de Calidad',      'CC-DESPACHO',  11000, 3000),
    -- Venta
    ('Caja y Atencion',         'CC-VENTA',      8000, 2000),
    ('Preparacion Express',     'CC-VENTA',      9000, 3000)
) AS T(Nombre, CodigoCentro, MO, CIF)
JOIN Organizacion.CentrosCosto cc ON cc.Codigo = T.CodigoCentro
WHERE NOT EXISTS (
    SELECT 1 FROM Organizacion.CentrosTrabajo ct
    WHERE ct.Nombre = T.Nombre AND ct.CentroCostoID = cc.CentroCostoID
);
PRINT '✓ Centros de Trabajo insertados.';


-- =============================================================================
-- 4. BODEGAS
-- =============================================================================

INSERT INTO Inventario.Bodegas (Nombre, CentroCostoID, TipoBodega, EsVirtual)
SELECT T.Nombre, cc.CentroCostoID, T.Tipo, T.Virtual
FROM (VALUES
    -- Materias primas y semielaborados
    ('Bodega Materias Primas',      'CC-BODEGA',    'MATERIA_PRIMA',      0),
    ('Bodega Lacteos y Frios',      'CC-BODEGA',    'MATERIA_PRIMA',      0),
    ('Bodega Harinas y Secos',      'CC-BODEGA',    'MATERIA_PRIMA',      0),
    ('Bodega Empaques e Insumos',   'CC-BODEGA',    'MATERIA_PRIMA',      0),
    -- WIP (Work in Progress): productos en proceso dentro de produccion
    ('WIP Cocina',                  'CC-COCINA',    'WIP',                0),
    ('WIP Panaderia',               'CC-PANADERIA', 'WIP',                0),
    -- Producto terminado
    ('Bodega Producto Terminado',   'CC-BODEGA',    'PRODUCTO_TERMINADO', 0),
    ('Vitrina Punto de Venta',      'CC-VENTA',     'PRODUCTO_TERMINADO', 0),
    -- Transito (para traspasos entre bodegas)
    ('Transito Cocina a Venta',     'CC-DESPACHO',  'TRANSITO',           1),
    ('Transito Domicilios',         'CC-DESPACHO',  'TRANSITO',           1)
) AS T(Nombre, CodigoCentro, Tipo, Virtual)
JOIN Organizacion.CentrosCosto cc ON cc.Codigo = T.CodigoCentro
WHERE NOT EXISTS (
    SELECT 1 FROM Inventario.Bodegas b
    WHERE b.Nombre = T.Nombre AND b.CentroCostoID = cc.CentroCostoID
);
PRINT '✓ Bodegas insertadas.';


-- =============================================================================
-- Verificacion final
-- =============================================================================
SELECT 'CentrosCosto'    AS Tabla, COUNT(*) AS Total FROM Organizacion.CentrosCosto
UNION ALL
SELECT 'CentrosTrabajo',            COUNT(*) FROM Organizacion.CentrosTrabajo
UNION ALL
SELECT 'Bodegas',                   COUNT(*) FROM Inventario.Bodegas;
