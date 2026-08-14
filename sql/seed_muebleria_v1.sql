-- =============================================================================
-- seed_muebleria_v1.sql
-- Datos de prueba: Distribuidora y Fábrica de Muebles "MaderArte"
-- Negocio: fabricación y venta de muebles de madera en Colombia
-- Precios en COP. IVA 19%.
-- ATENCION: ejecutar sobre NEXO_ERP, NO sobre VISIONSDBL1
-- =============================================================================

USE NEXO_ERP;
GO

-- ─── 1. MARCAS ───────────────────────────────────────────────────────────────

MERGE catalogo.Marca AS dest
USING (VALUES
    ('ARAU',  'ARAUCO',   'Tableros MDF y aglomerado ARAUCO'),
    ('MASI',  'MASISA',   'Tableros y maderas MASISA'),
    ('FORM',  'FORMICA',  'Laminados decorativos Formica'),
    ('HAFE',  'HAFELE',   'Herrajes de precision Hafele'),
    ('STAN',  'STANLEY',  'Herramientas y ferreteria Stanley'),
    ('LEGI',  'LEGIOFIX', 'Adhesivos y pegantes Legiofix'),
    ('3M',    '3M',       'Abrasivos y cintas 3M'),
    ('TEKN',  'TEKNO',    'Pinturas y barnices Tekno')
) AS src(Codigo, Marca, Descripcion)
ON dest.Codigo = src.Codigo
WHEN NOT MATCHED THEN INSERT (Codigo, Marca) VALUES (src.Codigo, src.Marca);

PRINT CAST(@@ROWCOUNT AS NVARCHAR) + ' marcas insertadas.';
GO

-- ─── 2. GRUPOS MAYORES ───────────────────────────────────────────────────────

MERGE catalogo.GrupoMayor AS dest
USING (VALUES
    ('MADE', 'Maderas y Tableros'),
    ('HERR', 'Herrajes y Ferreteria'),
    ('PINT', 'Pinturas y Acabados'),
    ('MUEB', 'Muebles Terminados'),
    ('CONS', 'Consumibles de Taller'),
    ('SERV', 'Servicios Profesionales')
) AS src(Codigo, Nombre)
ON dest.Codigo = src.Codigo
WHEN NOT MATCHED THEN INSERT (Codigo, Nombre) VALUES (src.Codigo, src.Nombre);

PRINT CAST(@@ROWCOUNT AS NVARCHAR) + ' grupos mayores insertados.';
GO

-- ─── 3. GRUPOS MENORES ───────────────────────────────────────────────────────

MERGE catalogo.GrupoMenor AS dest
USING (VALUES
    ('TABL', 'Tableros MDF y Aglomerado', 'MADE'),
    ('MACI', 'Madera Maciza y Perfiles',  'MADE'),
    ('BISA', 'Bisagras y Pernos',          'HERR'),
    ('CORR', 'Correderas y Rieles',        'HERR'),
    ('JALA', 'Jaladores y Tiraderas',      'HERR'),
    ('TORN', 'Tornilleria y Anclajes',     'HERR'),
    ('BARN', 'Barnices y Preservativos',   'PINT'),
    ('LAMI', 'Laminados y Enchapes',       'PINT'),
    ('SALA', 'Sala y Comedor',             'MUEB'),
    ('DORM', 'Dormitorio y Alcoba',        'MUEB'),
    ('OFIC', 'Muebles de Oficina',         'MUEB'),
    ('PEGA', 'Adhesivos y Pegantes',       'CONS'),
    ('ABRA', 'Abrasivos y Lijas',          'CONS'),
    ('INST', 'Instalacion y Montaje',      'SERV'),
    ('DISE', 'Diseno y Consultoria',       'SERV')
) AS src(Codigo, Nombre, GrupoMayor)
ON dest.Codigo = src.Codigo AND dest.GrupoMayor = src.GrupoMayor
WHEN NOT MATCHED THEN INSERT (Codigo, Nombre, GrupoMayor) VALUES (src.Codigo, src.Nombre, src.GrupoMayor);

PRINT CAST(@@ROWCOUNT AS NVARCHAR) + ' grupos menores insertados.';
GO

-- ─── 4. ARTICULOS ─────────────────────────────────────────────────────────────
-- Se usa MERGE por Referencia para ser idempotente.
-- TipoArticuloID se resuelve por nombre para no asumir IDs.
-- Fracciones vienen de la presentacion (tabla catalogo.Presentacion).
-- ─────────────────────────────────────────────────────────────────────────────

DECLARE
    @MP   INT = (SELECT TipoArticuloID FROM catalogo.TiposArticulo WHERE Nombre = 'Materia Prima'),
    @IN   INT = (SELECT TipoArticuloID FROM catalogo.TiposArticulo WHERE Nombre = 'Insumo'),
    @PT   INT = (SELECT TipoArticuloID FROM catalogo.TiposArticulo WHERE Nombre = 'Producto Terminado'),
    @SV   INT = (SELECT TipoArticuloID FROM catalogo.TiposArticulo WHERE Nombre = 'Servicio');

IF @MP IS NULL OR @IN IS NULL OR @PT IS NULL OR @SV IS NULL
BEGIN
    RAISERROR('No se encontraron todos los TiposArticulo. Verificar que esten seeded.', 16, 1);
    RETURN;
END

-- ── 4a. Materias Primas ──────────────────────────────────────────────────────
MERGE catalogo.Tarjetas AS dest
USING (VALUES

    -- Referencia, Nombre, Descripcion, TipoID,
    -- StockMin, PtoReorden, DiasVida, Fracciona,
    -- Costo, PPublico, PBodega, PCredito, UPublico, UBodega, UCredito,
    -- Marca, GrupoMenor, Presentacion, Peso,
    -- IvaSiNo, IvaValor, IvaDesc

    ('2026-MP-001',
     'Tablero MDF 15mm 244x122cm',
     'Tablero de fibra de densidad media 15mm. Superficie lisa ideal para enchape y pintura. Formato estandar 244x122cm.',
     @MP,   10, 5, NULL, 'SI',
     85000, NULL, NULL, NULL, NULL, NULL, NULL,
     'ARAU', 'TABL', 'UND', NULL,
     'SI', 19, 'IVA 19%'),

    ('2026-MP-002',
     'Tablero MDF 18mm 244x122cm',
     'Tablero MDF 18mm de alta densidad. Mayor resistencia para estructuras de muebles. Acabado listo para laca o melamina.',
     @MP,   8, 4, NULL, 'SI',
     98000, NULL, NULL, NULL, NULL, NULL, NULL,
     'ARAU', 'TABL', 'UND', NULL,
     'SI', 19, 'IVA 19%'),

    ('2026-MP-003',
     'Tablero Aglomerado 15mm Blanco 244x122cm',
     'Aglomerado con melamina blanca por ambas caras. Listo para usar en fabricacion de closets y modulares.',
     @MP,   12, 6, NULL, 'SI',
     68000, NULL, NULL, NULL, NULL, NULL, NULL,
     'MASI', 'TABL', 'UND', NULL,
     'SI', 19, 'IVA 19%'),

    ('2026-MP-004',
     'Madera Pino Cepillada 2x4 3mts',
     'Pino radiata cepillado seco al horno. Seccion 2x4 pulgadas x 3 metros. Para estructuras y marcos internos.',
     @MP,   30, 15, NULL, 'SI',
     28000, NULL, NULL, NULL, NULL, NULL, NULL,
     'MASI', 'MACI', 'UND', NULL,
     'SI', 19, 'IVA 19%'),

    ('2026-MP-005',
     'Madera Cedro 1x6 4mts',
     'Cedro macizo seleccionado, seccion 1x6 pulgadas x 4 metros. Ideal para piezas visibles por su veta y olor natural.',
     @MP,   20, 8, NULL, 'SI',
     42000, NULL, NULL, NULL, NULL, NULL, NULL,
     'MASI', 'MACI', 'UND', NULL,
     'SI', 19, 'IVA 19%'),

    ('2026-MP-006',
     'Laminado Formica Blanco Polar 244x122cm',
     'Lamina de alta presion Formica color blanco polar mate. Para enchape de superficies en modulos de cocina y bano.',
     @MP,   15, 5, NULL, 'SI',
     72000, NULL, NULL, NULL, NULL, NULL, NULL,
     'FORM', 'LAMI', 'UND', NULL,
     'SI', 19, 'IVA 19%')

) AS src(Ref, Nom, Desc, TipoID, StockMin, PtoReorden, DiasVida, Fracciona,
          Costo, PPublico, PBodega, PCredito, UPublico, UBodega, UCredito,
          Marca, GrupoMenor, Presentacion, Peso,
          IvaSiNo, IvaValor, IvaDesc)
ON dest.Referencia = src.Ref
WHEN NOT MATCHED THEN
    INSERT (Referencia, Nombre, Descripcion, TipoArticuloID,
            StockMinimo, PuntoReorden, DiasVidaUtil, Fracciona,
            Costo, PPublico, PBodega, PCredito, UPublico, UBodega, UCredito,
            MarcaCodigo, GrupoMenorCodigo, PresentacionCodigo, Peso,
            IvaSiNo, IvaValor, IvaDescripcion)
    VALUES (src.Ref, src.Nom, src.Desc, src.TipoID,
            src.StockMin, src.PtoReorden, src.DiasVida, src.Fracciona,
            src.Costo, src.PPublico, src.PBodega, src.PCredito, src.UPublico, src.UBodega, src.UCredito,
            src.Marca, src.GrupoMenor, src.Presentacion, src.Peso,
            src.IvaSiNo, src.IvaValor, src.IvaDesc);

PRINT CAST(@@ROWCOUNT AS NVARCHAR) + ' materias primas insertadas.';

-- ── 4b. Insumos ──────────────────────────────────────────────────────────────
MERGE catalogo.Tarjetas AS dest
USING (VALUES

    ('2026-IN-001',
     'Bisagra Copa 35mm Nickel (par)',
     'Bisagra de taza 35mm con amortiguador cierre suave. Regulacion 3D. Acabado nickel satinado. Par (2 unidades).',
     @IN,   50, 20, NULL, 'SI',
     3500, NULL, NULL, NULL, NULL, NULL, NULL,
     'HAFE', 'BISA', 'UND', NULL,
     'SI', 19, 'IVA 19%'),

    ('2026-IN-002',
     'Corredera Telescopica Acero 45cm (par)',
     'Corredera de extension total en acero con rodamientos. Carga maxima 35kg. 45cm. Par para un cajon.',
     @IN,   40, 15, NULL, 'SI',
     18500, NULL, NULL, NULL, NULL, NULL, NULL,
     'HAFE', 'CORR', 'UND', NULL,
     'SI', 19, 'IVA 19%'),

    ('2026-IN-003',
     'Jalador Barra Cromada 128mm',
     'Jalador tipo barra en cromo brillante. Intereje 128mm. Para puertas y cajones de cocina y closet.',
     @IN,   100, 40, NULL, 'NO',  -- se vende solo en cajas de 10
     4200, NULL, NULL, NULL, NULL, NULL, NULL,
     'HAFE', 'JALA', 'CAJA12', NULL,
     'SI', 19, 'IVA 19%'),

    ('2026-IN-004',
     'Pegante en Frio Legiofix 500cc',
     'Adhesivo PVA de alta resistencia para madera. Tiempo de ensamble 10 min, fraguado 24h. Frasco 500cc.',
     @IN,   30, 12, NULL, 'SI',
     14000, NULL, NULL, NULL, NULL, NULL, NULL,
     'LEGI', 'PEGA', 'UND', NULL,
     'SI', 19, 'IVA 19%'),

    ('2026-IN-005',
     'Tornillo Pocket Hole 8x32mm (caja x200)',
     'Tornillo autoperforante para pocket hole, punta avellanada. Acero zincado. Caja de 200 unidades.',
     @IN,   20, 8, NULL, 'SI',
     28000, NULL, NULL, NULL, NULL, NULL, NULL,
     'STAN', 'TORN', 'UND', NULL,
     'SI', 19, 'IVA 19%'),

    ('2026-IN-006',
     'Lija en Pliego Grano 120 (paquete x10)',
     'Lija oxido de aluminio grano 120. Para desbaste y lijado fino de madera antes de pintura. Paquete 10 pliegos.',
     @IN,   25, 10, NULL, 'NO',  -- solo por paquete
     18000, NULL, NULL, NULL, NULL, NULL, NULL,
     '3M', 'ABRA', 'PAQUETE', NULL,
     'SI', 19, 'IVA 19%'),

    ('2026-IN-007',
     'Barniz Brillante Tekno 1/4 Galon',
     'Barniz sintetico alto brillo para madera interior. Resistente a humedad y rayaduras. Presentacion 1/4 galon.',
     @IN,   20, 8, 360, 'SI',
     35000, NULL, NULL, NULL, NULL, NULL, NULL,
     'TEKN', 'BARN', 'UND', NULL,
     'SI', 19, 'IVA 19%'),

    ('2026-IN-008',
     'Sellador para Madera Tekno 1/4 Galon',
     'Sellador alquidalico para madera. Cierra poros y prepara la superficie para barniz o laca. 1/4 galon.',
     @IN,   15, 6, 360, 'SI',
     27000, NULL, NULL, NULL, NULL, NULL, NULL,
     'TEKN', 'BARN', 'UND', NULL,
     'SI', 19, 'IVA 19%')

) AS src(Ref, Nom, Desc, TipoID, StockMin, PtoReorden, DiasVida, Fracciona,
          Costo, PPublico, PBodega, PCredito, UPublico, UBodega, UCredito,
          Marca, GrupoMenor, Presentacion, Peso,
          IvaSiNo, IvaValor, IvaDesc)
ON dest.Referencia = src.Ref
WHEN NOT MATCHED THEN
    INSERT (Referencia, Nombre, Descripcion, TipoArticuloID,
            StockMinimo, PuntoReorden, DiasVidaUtil, Fracciona,
            Costo, PPublico, PBodega, PCredito, UPublico, UBodega, UCredito,
            MarcaCodigo, GrupoMenorCodigo, PresentacionCodigo, Peso,
            IvaSiNo, IvaValor, IvaDescripcion)
    VALUES (src.Ref, src.Nom, src.Desc, src.TipoID,
            src.StockMin, src.PtoReorden, src.DiasVida, src.Fracciona,
            src.Costo, src.PPublico, src.PBodega, src.PCredito, src.UPublico, src.UBodega, src.UCredito,
            src.Marca, src.GrupoMenor, src.Presentacion, src.Peso,
            src.IvaSiNo, src.IvaValor, src.IvaDesc);

PRINT CAST(@@ROWCOUNT AS NVARCHAR) + ' insumos insertados.';

-- ── 4c. Productos Terminados ──────────────────────────────────────────────────
-- Precios COP con margen realista de fabricacion (60-120%)
-- PBodega = ~88% de PPublico, PCredito = ~94% de PPublico
-- U* = precio - costo

MERGE catalogo.Tarjetas AS dest
USING (VALUES

    ('2026-PT-001',
     'Mesa de Comedor 6 Puestos Roble',
     'Mesa de comedor para 6 personas en MDF enchapado roble americano. Patas metalicas negras. 160x90cm. Altura 76cm.',
     @PT,   3, 1, NULL, 'SI',
     680000,  1450000, 1280000, 1380000,  770000, 600000, 700000,
     NULL, 'SALA', 'UND', NULL,
     'SI', 19, 'IVA 19%'),

    ('2026-PT-002',
     'Silla Comedor Tapizada Gris',
     'Silla para comedor con estructura en madera maciza lacada en negro. Asiento tapizado en tela gris texturada.',
     @PT,   12, 4, NULL, 'SI',
     195000,  420000, 370000, 400000,  225000, 175000, 205000,
     NULL, 'SALA', 'UND', NULL,
     'SI', 19, 'IVA 19%'),

    ('2026-PT-003',
     'Cama Doble con Cabecero Tapizado',
     'Cama para colchon doble (140x190cm). Base en tablero MDF laqueado blanco. Cabecero tapizado en tela antifluido.',
     @PT,   2, 1, NULL, 'SI',
     890000,  1950000, 1720000, 1850000,  1060000, 830000, 960000,
     NULL, 'DORM', 'UND', NULL,
     'SI', 19, 'IVA 19%'),

    ('2026-PT-004',
     'Mesa de Noche con Cajon',
     'Mesa de noche con un cajon y espacio inferior abierto. MDF enchapado wengue. 50x40x55cm.',
     @PT,   6, 2, NULL, 'SI',
     165000,  355000, 315000, 335000,  190000, 150000, 170000,
     NULL, 'DORM', 'UND', NULL,
     'SI', 19, 'IVA 19%'),

    ('2026-PT-005',
     'Escritorio Ejecutivo en L 160cm',
     'Escritorio tipo L en tablero aglomerado wengue. Incluye cajonera movil con seguro. 160x120x75cm.',
     @PT,   2, 1, NULL, 'SI',
     620000,  1350000, 1195000, 1275000,  730000, 575000, 655000,
     NULL, 'OFIC', 'UND', NULL,
     'SI', 19, 'IVA 19%'),

    ('2026-PT-006',
     'Archivador Metalico 4 Gavetas',
     'Archivador vertical de 4 gavetas en lamina de acero calibre 22. Con seguro central y riel telescopico. Color gris.',
     @PT,   4, 2, NULL, 'SI',
     295000,  650000, 575000, 615000,  355000, 280000, 320000,
     NULL, 'OFIC', 'UND', NULL,
     'SI', 19, 'IVA 19%'),

    ('2026-PT-007',
     'Closet 3 Puertas Corredizas 180cm',
     'Closet modular en MDF blanco con 3 puertas corredizas en vidrio esmerilado. Interior con divisiones y colgador. 180x55x210cm.',
     @PT,   1, 1, NULL, 'SI',
     1250000,  2750000, 2430000, 2600000,  1500000, 1180000, 1350000,
     NULL, 'DORM', 'UND', NULL,
     'SI', 19, 'IVA 19%'),

    ('2026-PT-008',
     'Biblioteca Flotante 4 Niveles',
     'Modulo de biblioteca mural en MDF laqueado blanco. 4 repisas con capacidad de 20kg c/u. Incluye herrajes de pared. 120x25x150cm.',
     @PT,   5, 2, NULL, 'SI',
     245000,  540000, 475000, 510000,  295000, 230000, 265000,
     NULL, 'SALA', 'UND', NULL,
     'SI', 19, 'IVA 19%')

) AS src(Ref, Nom, Desc, TipoID, StockMin, PtoReorden, DiasVida, Fracciona,
          Costo, PPublico, PBodega, PCredito, UPublico, UBodega, UCredito,
          Marca, GrupoMenor, Presentacion, Peso,
          IvaSiNo, IvaValor, IvaDesc)
ON dest.Referencia = src.Ref
WHEN NOT MATCHED THEN
    INSERT (Referencia, Nombre, Descripcion, TipoArticuloID,
            StockMinimo, PuntoReorden, DiasVidaUtil, Fracciona,
            Costo, PPublico, PBodega, PCredito, UPublico, UBodega, UCredito,
            MarcaCodigo, GrupoMenorCodigo, PresentacionCodigo, Peso,
            IvaSiNo, IvaValor, IvaDescripcion)
    VALUES (src.Ref, src.Nom, src.Desc, src.TipoID,
            src.StockMin, src.PtoReorden, src.DiasVida, src.Fracciona,
            src.Costo, src.PPublico, src.PBodega, src.PCredito, src.UPublico, src.UBodega, src.UCredito,
            src.Marca, src.GrupoMenor, src.Presentacion, src.Peso,
            src.IvaSiNo, src.IvaValor, src.IvaDesc);

PRINT CAST(@@ROWCOUNT AS NVARCHAR) + ' productos terminados insertados.';

-- ── 4d. Servicios ─────────────────────────────────────────────────────────────
-- Servicios: sin costo de produccion fijo, sin unidad de medida.
-- StockMinimo = 0, no tiene presentacion fisica.

MERGE catalogo.Tarjetas AS dest
USING (VALUES

    ('2026-SV-001',
     'Instalacion y Montaje de Muebles (hora)',
     'Servicio de instalacion, armado y montaje de muebles en sitio. Incluye herramientas y fijaciones de pared. Cobro por hora de trabajo.',
     @SV,   0, 0, NULL, 'SI',
     NULL,  85000, 75000, 80000,  NULL, NULL, NULL,
     NULL, 'INST', 'UND', NULL,
     'SI', 19, 'IVA 19%'),

    ('2026-SV-002',
     'Diseno y Consultoria de Proyecto',
     'Consultoria personalizada de diseno de interiores y fabricacion a medida. Visita tecnica + planos + lista de materiales. Cobro por proyecto.',
     @SV,   0, 0, NULL, 'SI',
     NULL,  250000, 220000, 240000,  NULL, NULL, NULL,
     NULL, 'DISE', 'UND', NULL,
     'SI', 19, 'IVA 19%'),

    ('2026-SV-003',
     'Mantenimiento y Restauracion de Muebles',
     'Reparacion estructural, relacado, retapizado o restauracion completa de muebles. Presupuesto previo segun estado. Por unidad.',
     @SV,   0, 0, NULL, 'SI',
     NULL,  180000, 160000, 170000,  NULL, NULL, NULL,
     NULL, 'INST', 'UND', NULL,
     'SI', 19, 'IVA 19%'),

    ('2026-SV-004',
     'Acabado y Laqueado de Superficies',
     'Aplicacion de sellador + laca poliuretanica en cabina de pintura. Hasta 3 tonos. Cobro por metro cuadrado de superficie.',
     @SV,   0, 0, NULL, 'SI',
     NULL,  45000, 38000, 42000,  NULL, NULL, NULL,
     NULL, 'INST', 'UND', NULL,
     'SI', 19, 'IVA 19%')

) AS src(Ref, Nom, Desc, TipoID, StockMin, PtoReorden, DiasVida, Fracciona,
          Costo, PPublico, PBodega, PCredito, UPublico, UBodega, UCredito,
          Marca, GrupoMenor, Presentacion, Peso,
          IvaSiNo, IvaValor, IvaDesc)
ON dest.Referencia = src.Ref
WHEN NOT MATCHED THEN
    INSERT (Referencia, Nombre, Descripcion, TipoArticuloID,
            StockMinimo, PuntoReorden, DiasVidaUtil, Fracciona,
            Costo, PPublico, PBodega, PCredito, UPublico, UBodega, UCredito,
            MarcaCodigo, GrupoMenorCodigo, PresentacionCodigo, Peso,
            IvaSiNo, IvaValor, IvaDescripcion)
    VALUES (src.Ref, src.Nom, src.Desc, src.TipoID,
            src.StockMin, src.PtoReorden, src.DiasVida, src.Fracciona,
            src.Costo, src.PPublico, src.PBodega, src.PCredito, src.UPublico, src.UBodega, src.UCredito,
            src.Marca, src.GrupoMenor, src.Presentacion, src.Peso,
            src.IvaSiNo, src.IvaValor, src.IvaDesc);

PRINT CAST(@@ROWCOUNT AS NVARCHAR) + ' servicios insertados.';
GO

-- ─── 5. VERIFICACION FINAL ───────────────────────────────────────────────────

SELECT
    ta.Nombre AS Tipo,
    COUNT(*)  AS Cantidad
FROM catalogo.Tarjetas t
JOIN catalogo.TiposArticulo ta ON ta.TipoArticuloID = t.TipoArticuloID
WHERE t.Referencia LIKE '2026%'
GROUP BY ta.Nombre
ORDER BY ta.Nombre;

SELECT
    t.Referencia, t.Nombre,
    ta.Nombre          AS Tipo,
    t.MarcaCodigo      AS Marca,
    t.GrupoMenorCodigo AS GrupoMenor,
    t.PresentacionCodigo AS Presentacion,
    t.Costo, t.PPublico
FROM catalogo.Tarjetas t
JOIN catalogo.TiposArticulo ta ON ta.TipoArticuloID = t.TipoArticuloID
WHERE t.Referencia LIKE '2026%'
ORDER BY ta.Nombre, t.Referencia;
GO

PRINT '=== Seed muebleria_v1 finalizado. 25 articulos (6 MP + 8 Insumos + 8 PT + 4 Servicios) ===';
GO
