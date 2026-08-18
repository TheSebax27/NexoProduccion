/* ============================================================================
   seed_panaderia_v1.sql
   NEXO ERP — Datos de prueba: Panaderia Industrial "PanArte S.A."
   Industria de panificacion y pasteleria en Colombia (COP).

   ORDEN DE EJECUCION:
     1. Primero ejecutar fix2_migration_recetas_sin_unidad_v1.sql (si no se ha hecho)
     2. Luego este script.

   QUE HACE:
     - Elimina todos los datos transaccionales y de catalogo de articulos
     - Inserta marcas, grupos, articulos realistas (con KG, LT y cajas)
     - Inserta lotes y stock suficiente para liberar las OPs
     - Inserta 2 recetas BOM sin UnidadID/UnidadRendimientoID
     - Inserta 3 ordenes de produccion en estado Planificada
   ============================================================================ */
USE NEXO_ERP;
GO
SET NOCOUNT ON;
GO

PRINT '==========================================================';
PRINT 'PARTE 0: Correccion de schema (por si fix2 no se ejecuto)';
PRINT '==========================================================';

-- Eliminar FK de RecetaBOM_Detalle.UnidadID si aun existe
DECLARE @sqlFk1 NVARCHAR(500);
SELECT @sqlFk1 = 'ALTER TABLE Produccion.RecetaBOM_Detalle DROP CONSTRAINT ' + fk.name
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
JOIN sys.columns c ON c.object_id = fk.parent_object_id AND c.column_id = fkc.parent_column_id
WHERE fk.parent_object_id = OBJECT_ID('Produccion.RecetaBOM_Detalle') AND c.name = 'UnidadID';
IF @sqlFk1 IS NOT NULL EXEC(@sqlFk1);
GO

DECLARE @sqlFk2 NVARCHAR(500);
SELECT @sqlFk2 = 'ALTER TABLE Produccion.RecetaBOM DROP CONSTRAINT ' + fk.name
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
JOIN sys.columns c ON c.object_id = fk.parent_object_id AND c.column_id = fkc.parent_column_id
WHERE fk.parent_object_id = OBJECT_ID('Produccion.RecetaBOM') AND c.name = 'UnidadRendimientoID';
IF @sqlFk2 IS NOT NULL EXEC(@sqlFk2);
GO

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Produccion.RecetaBOM_Detalle') AND name = 'UnidadID')
    ALTER TABLE Produccion.RecetaBOM_Detalle DROP COLUMN UnidadID;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Produccion.RecetaBOM') AND name = 'UnidadRendimientoID')
    ALTER TABLE Produccion.RecetaBOM DROP COLUMN UnidadRendimientoID;
GO

PRINT '>> Schema OK.';
GO

PRINT '';
PRINT '==========================================================';
PRINT 'PARTE 1: Limpieza de datos (orden correcto de FKs)';
PRINT '==========================================================';

-- 1. EventosSalientes → KardexMovimientos
DELETE FROM Integracion.EventosSalientes;
PRINT '  EventosSalientes: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' filas.';

-- 2. KardexMovimientos (referencia Articulos, Lotes, Bodegas, OPs)
DELETE FROM Kardex.KardexMovimientos;
PRINT '  KardexMovimientos: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' filas.';

-- 3. Bajas de inventario
DELETE FROM Kardex.BajasInventarioPerdidas;
PRINT '  BajasInventarioPerdidas: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' filas.';

-- 4. Consumos de OPs
DELETE FROM Produccion.OrdenesProduccionConsumo;
PRINT '  OrdenesProduccionConsumo: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' filas.';

-- 5. Ordenes de produccion (CASCADE elimina OrdenMaquinaria)
DELETE FROM Produccion.OrdenesProduccion;
PRINT '  OrdenesProduccion: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' filas.';

-- 6. Detalle de recetas
DELETE FROM Produccion.RecetaBOM_Detalle;
PRINT '  RecetaBOM_Detalle: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' filas.';

-- 7. Recetas (CASCADE elimina RecetaMaquinaria)
DELETE FROM Produccion.RecetaBOM;
PRINT '  RecetaBOM: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' filas.';

-- 8. Traspasos detalle
DELETE FROM Inventario.TraspasosDetalle;
PRINT '  TraspasosDetalle: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' filas.';

-- 9. Traspasos cabecera
DELETE FROM Inventario.TraspasosBodega;
PRINT '  TraspasosBodega: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' filas.';

-- 10. Stock fisico
DELETE FROM Inventario.InventarioStock;
PRINT '  InventarioStock: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' filas.';

-- 11. Lotes
DELETE FROM Inventario.Lotes;
PRINT '  Lotes: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' filas.';

-- 12. Detalle ordenes de compra
DELETE FROM Compras.OrdenesCompraDetalle;
PRINT '  OrdenesCompraDetalle: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' filas.';

-- 13. Ordenes de compra
DELETE FROM Compras.OrdenesCompra;
PRINT '  OrdenesCompra: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' filas.';

-- 14. Mapeo articulos (integracion Visions)
IF OBJECT_ID('Integracion.MapeoArticulos') IS NOT NULL
BEGIN
    DELETE FROM Integracion.MapeoArticulos;
    PRINT '  MapeoArticulos: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' filas.';
END

-- 15. Articulo-Proveedor
DELETE FROM Catalogo.ArticuloProveedor;
PRINT '  ArticuloProveedor: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' filas.';

-- 16. Articulos / Tarjetas
DELETE FROM Catalogo.Tarjetas;
PRINT '  Tarjetas (articulos): ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' filas.';

-- 17. Grupos menores y mayores
DELETE FROM Catalogo.GrupoMenor;
PRINT '  GrupoMenor: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' filas.';
DELETE FROM Catalogo.GrupoMayor;
PRINT '  GrupoMayor: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' filas.';

-- 18. Marcas
DELETE FROM Catalogo.Marca;
PRINT '  Marca: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' filas.';

PRINT '>> Limpieza completada.';
GO

PRINT '';
PRINT '==========================================================';
PRINT 'PARTE 2: Marcas y Grupos de articulos';
PRINT '==========================================================';

-- ── Marcas ─────────────────────────────────────────────────────────────────
MERGE Catalogo.Marca AS dest
USING (VALUES
    ('HVALL', 'Harinera del Valle',  'Harinas y derivados de trigo, Colombia'),
    ('INCAU', 'Incauca',             'Azucar refinada e industrial, Colombia'),
    ('DANLE', 'Dan Leb',             'Levaduras y mejoradores de panificacion'),
    ('VITRI', 'Vitarrico',           'Margarina y grasas industriales para panaderia'),
    ('MISOL', 'Mi Sol',              'Aceites vegetales comestibles'),
    ('PANTE', 'PanArte',             'Marca propia de productos terminados')
) AS src(Codigo, Marca, Descripcion)
ON dest.Codigo = src.Codigo
WHEN NOT MATCHED THEN INSERT (Codigo, Marca) VALUES (src.Codigo, src.Marca);
PRINT '  Marcas: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' insertadas.';

-- ── Grupos Mayores ──────────────────────────────────────────────────────────
MERGE Catalogo.GrupoMayor AS dest
USING (VALUES
    ('HARI', 'Harinas y Cereales'),
    ('GRSA', 'Grasas y Aceites'),
    ('LACTE', 'Lacteos y Huevos'),
    ('EMPAQ', 'Empaques y Envases'),
    ('PANIF', 'Panaderia y Pasteleria')
) AS src(Codigo, Nombre)
ON dest.Codigo = src.Codigo
WHEN NOT MATCHED THEN INSERT (Codigo, Nombre) VALUES (src.Codigo, src.Nombre);
PRINT '  GruposMayores: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' insertados.';

-- ── Grupos Menores ──────────────────────────────────────────────────────────
MERGE Catalogo.GrupoMenor AS dest
USING (VALUES
    ('TRIG', 'Harina de Trigo',         'HARI'),
    ('ALMI', 'Almidones y Feculas',     'HARI'),
    ('AZUC', 'Azucares y Endulzantes',  'HARI'),
    ('SALT', 'Sal e Ionizados',         'HARI'),
    ('LEVA', 'Levaduras y Fermentos',   'HARI'),
    ('MEJE', 'Mejoradores y Aditivos',  'HARI'),
    ('ACEI', 'Aceites Vegetales',       'GRSA'),
    ('MARG', 'Margarinas Industriales', 'GRSA'),
    ('HUEV', 'Huevos y Derivados',      'LACTE'),
    ('LECH', 'Leche y Suero en Polvo',  'LACTE'),
    ('EPCRT','Cajas y Carton',          'EMPAQ'),
    ('EPBOL','Bolsas y Peliculas',      'EMPAQ'),
    ('PAND', 'Panes de Molde y Tajado', 'PANIF'),
    ('GALL', 'Galletas y Biscochos',    'PANIF'),
    ('PAST', 'Pasteles y Reposteria',   'PANIF')
) AS src(Codigo, Nombre, GrupoMayor)
ON dest.Codigo = src.Codigo AND dest.GrupoMayor = src.GrupoMayor
WHEN NOT MATCHED THEN INSERT (Codigo, Nombre, GrupoMayor) VALUES (src.Codigo, src.Nombre, src.GrupoMayor);
PRINT '  GruposMenores: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' insertados.';
GO

PRINT '';
PRINT '==========================================================';
PRINT 'PARTE 3: Articulos (MP, Insumos, PT)';
PRINT '==========================================================';

DECLARE
    @MP  INT = (SELECT TipoArticuloID FROM Catalogo.TiposArticulo WHERE Nombre = 'Materia Prima'),
    @INS INT = (SELECT TipoArticuloID FROM Catalogo.TiposArticulo WHERE Nombre = 'Insumo'),
    @PT  INT = (SELECT TipoArticuloID FROM Catalogo.TiposArticulo WHERE Nombre = 'Producto Terminado');

IF @MP IS NULL OR @INS IS NULL OR @PT IS NULL
BEGIN
    RAISERROR('ERROR: TiposArticulo no encontrados. Verificar seed de TiposArticulo.', 16, 1);
    RETURN;
END

-- ── Materias Primas (vendidas por PESO o VOLUMEN) ───────────────────────────
-- Presentacion KG (Tipo='PESO', Fracciones=NULL) → no se fracciona en cajas
-- Presentacion LT  → litros de aceite
MERGE Catalogo.Tarjetas AS dest
USING (VALUES
    -- Ref,          Nombre,                            Desc (corta),              TipoID,
    -- StockMin, PtoReorden, DiasVida, Fracciona,
    -- Costo,  PPubl, PBod,  PCred, UPubl, UBod,  UCred,
    -- Marca,  GrupoMenor,  Pres,  Peso,  IvaSN, IvaVal, IvaDesc

    ('PAH-MP-001',
     'Harina de Trigo OO Especial Panificacion',
     'Harina de trigo 000 de alta absorcion para pan de molde, baguette y pasteleria. Proteina 11-13%. Saco 50 kg.',
     @MP, 300, 150, NULL, 'SI',
     1850, NULL,NULL,NULL,NULL,NULL,NULL,
     'HVALL','TRIG','KG', 50.00,
     'NO', 0, 'Excluido de IVA'),

    ('PAH-MP-002',
     'Azucar Blanca Refinada Grado A',
     'Azucar refinada de cana de primer grado para panificacion y reposteria. Sin impurezas. Saco 50 kg.',
     @MP, 200, 100, NULL, 'SI',
     2100, NULL,NULL,NULL,NULL,NULL,NULL,
     'INCAU','AZUC','KG', 50.00,
     'NO', 0, 'Excluido de IVA'),

    ('PAH-MP-003',
     'Sal Refinada Iodada Extra Fina',
     'Sal de mesa refinada, iodada y fluorizada. Granulometria fina para uniformidad en masas. Saco 25 kg.',
     @MP, 80, 40, NULL, 'SI',
     820, NULL,NULL,NULL,NULL,NULL,NULL,
     NULL,'SALT','KG', 25.00,
     'NO', 0, 'Excluido de IVA'),

    ('PAH-MP-004',
     'Levadura Seca Instantanea Osmotolerante',
     'Levadura Saccharomyces cerevisiae deshidratada de accion rapida. Tolerante a altos contenidos de azucar. Bolsa 10 kg.',
     @MP, 15, 8, 365, 'SI',
     22000, NULL,NULL,NULL,NULL,NULL,NULL,
     'DANLE','LEVA','KG', 10.00,
     'SI', 19, 'IVA 19%'),

    ('PAH-MP-005',
     'Margarina Industrial Cremosa 84% Grasa',
     'Margarina vegetal hidrogenada para panaderia industrial. 84% materia grasa. Sabor mantequilla. Cubo 15 kg.',
     @MP, 60, 30, 180, 'SI',
     4500, NULL,NULL,NULL,NULL,NULL,NULL,
     'VITRI','MARG','KG', 15.00,
     'SI', 19, 'IVA 19%'),

    ('PAH-MP-006',
     'Aceite de Palma RBD Refinado',
     'Aceite de palma refinado, blanqueado y desodorizado para frituras y masas laminadas. Bidon 20 litros.',
     @MP, 80, 40, 365, 'SI',
     3400, NULL,NULL,NULL,NULL,NULL,NULL,
     'MISOL','ACEI','LT', 18.40,
     'SI', 19, 'IVA 19%')

) AS src(Ref, Nom, Desc, TipoID,
         StockMin, PtoReorden, DiasVida, Fracciona,
         Costo, PPubl, PBod, PCred, UPubl, UBod, UCred,
         Marca, GrupoMenor, Pres, Peso,
         IvaSN, IvaVal, IvaDesc)
ON dest.Referencia = src.Ref
WHEN NOT MATCHED THEN
    INSERT (Referencia, Nombre, Descripcion, TipoArticuloID,
            StockMinimo, PuntoReorden, DiasVidaUtil, Fracciona,
            Costo, PPublico, PBodega, PCredito, UPublico, UBodega, UCredito,
            MarcaCodigo, GrupoMenorCodigo, PresentacionCodigo, Peso,
            IvaSiNo, IvaValor, IvaDescripcion)
    VALUES (src.Ref, src.Nom, src.Desc, src.TipoID,
            src.StockMin, src.PtoReorden, src.DiasVida, src.Fracciona,
            src.Costo, src.PPubl, src.PBod, src.PCred, src.UPubl, src.UBod, src.UCred,
            src.Marca, src.GrupoMenor, src.Pres, src.Peso,
            src.IvaSN, src.IvaVal, src.IvaDesc);
PRINT '  MP insertadas: ' + CAST(@@ROWCOUNT AS NVARCHAR);

-- ── Insumos ─────────────────────────────────────────────────────────────────
-- PAH-IN-001: Huevos CAJA12 → Fracciones=12 (EsFraccionado=true, valida FormatearCantidad)
-- PAH-IN-002: Esencia CAJA24 → Fracciones=24 (otro caso de embalaje en caja)
-- PAH-IN-003: Polvo hornear KG → sin fracciones
-- PAH-IN-004: Bolsa polipropileno PAQUETE → sin fracciones fijas
MERGE Catalogo.Tarjetas AS dest
USING (VALUES
    ('PAH-IN-001',
     'Huevo de Gallina Rojo Extra AA',
     'Huevo de gallina raza Ross categoría Extra. Peso minimo 63g. Cascarón solido. Presentacion: bandeja plastica x 12 unidades.',
     @INS, 40, 20, 30, 'NO',
     6200, NULL,NULL,NULL,NULL,NULL,NULL,
     NULL,'HUEV','CAJA12', 0.72,
     'NO', 0, 'Excluido de IVA'),

    ('PAH-IN-002',
     'Esencia de Vainilla Artificial 30ml',
     'Esencia de vainilla sintetica de alta concentracion. Resiste temperatura de horneado hasta 220C. Frasco 30 ml. Caja x 24 frascos.',
     @INS, 6, 3, 730, 'NO',
     38000, NULL,NULL,NULL,NULL,NULL,NULL,
     NULL,'MEJE','CAJA24', NULL,
     'SI', 19, 'IVA 19%'),

    ('PAH-IN-003',
     'Polvo para Hornear Doble Accion',
     'Agente leudante de doble accion (tartrato + bicarb). Libre de aluminio. Activacion en frio y en calor. Bolsa 1 kg.',
     @INS, 10, 5, 720, 'SI',
     14500, NULL,NULL,NULL,NULL,NULL,NULL,
     NULL,'MEJE','KG', 1.00,
     'SI', 19, 'IVA 19%'),

    ('PAH-IN-004',
     'Bolsa Polipropileno Biorientado Pan Molde 36x18cm',
     'Bolsa BOPP transparente calibre 35 micras para empacar pan de molde individual. Perforada. Paquete x 100 unidades.',
     @INS, 20, 10, NULL, 'NO',
     8200, NULL,NULL,NULL,NULL,NULL,NULL,
     NULL,'EPBOL','PAQUETE', 0.45,
     'SI', 19, 'IVA 19%'),

    ('PAH-IN-005',
     'Leche Entera en Polvo 25kg',
     'Leche de vaca entera deshidratada por spray-dryer. Proteina min 24%. Grasa min 26%. Saco 25 kg. Vida util 12 meses.',
     @INS, 25, 12, 365, 'SI',
     9800, NULL,NULL,NULL,NULL,NULL,NULL,
     NULL,'LECH','KG', 25.00,
     'SI', 19, 'IVA 19%')

) AS src(Ref, Nom, Desc, TipoID,
         StockMin, PtoReorden, DiasVida, Fracciona,
         Costo, PPubl, PBod, PCred, UPubl, UBod, UCred,
         Marca, GrupoMenor, Pres, Peso,
         IvaSN, IvaVal, IvaDesc)
ON dest.Referencia = src.Ref
WHEN NOT MATCHED THEN
    INSERT (Referencia, Nombre, Descripcion, TipoArticuloID,
            StockMinimo, PuntoReorden, DiasVidaUtil, Fracciona,
            Costo, PPublico, PBodega, PCredito, UPublico, UBodega, UCredito,
            MarcaCodigo, GrupoMenorCodigo, PresentacionCodigo, Peso,
            IvaSiNo, IvaValor, IvaDescripcion)
    VALUES (src.Ref, src.Nom, src.Desc, src.TipoID,
            src.StockMin, src.PtoReorden, src.DiasVida, src.Fracciona,
            src.Costo, src.PPubl, src.PBod, src.PCred, src.UPubl, src.UBod, src.UCred,
            src.Marca, src.GrupoMenor, src.Pres, src.Peso,
            src.IvaSN, src.IvaVal, src.IvaDesc);
PRINT '  Insumos insertados: ' + CAST(@@ROWCOUNT AS NVARCHAR);

-- ── Productos Terminados ────────────────────────────────────────────────────
-- Todos en presentacion CAJA (fraccionados), distintos tamaños:
-- CAJA6, CAJA12, CAJA24 → validan EsFraccionado y FormatearCantidad en la UI
MERGE Catalogo.Tarjetas AS dest
USING (VALUES
    ('PAH-PT-001',
     'Pan de Molde Blanco 500g x 18 Tajadas',
     'Pan de molde blanco enriquecido con leche y margarina. 18 tajadas de 2.7cm. Empacado en bolsa BOPP sellada. Caja x 6 unidades.',
     @PT, 30, 15, 5, 'NO',
     3200, 6500, 5800, 6200,  3300, 2600, 3000,
     'PANTE','PAND','CAJA6', 0.51,
     'NO', 0, 'Excluido de IVA'),

    ('PAH-PT-002',
     'Pan de Molde Integral 500g x 18 Tajadas',
     'Pan integral con salvado de trigo y semillas de linaza. 18 tajadas. Libre de conservantes artificiales. Caja x 6 unidades.',
     @PT, 20, 10, 4, 'NO',
     3800, 7500, 6700, 7100,  3700, 2900, 3300,
     'PANTE','PAND','CAJA6', 0.52,
     'NO', 0, 'Excluido de IVA'),

    ('PAH-PT-003',
     'Galleta de Vainilla 180g x 12 Unidades',
     'Galleta tipo mantequilla sabor vainilla. Textura crocante. 12 unidades en bolsa individual sellada al vacio. Caja x 12 bolsas.',
     @PT, 50, 25, 60, 'NO',
     2800, 5500, 4900, 5200,  2700, 2100, 2400,
     'PANTE','GALL','CAJA12', 0.18,
     'NO', 0, 'Excluido de IVA'),

    ('PAH-PT-004',
     'Alfajor Clasico de Maizena 30g',
     'Alfajor tradicional de maizena relleno de arequipe y baneado con azucar glass. Individual en papel aluminio. Caja x 24 unidades.',
     @PT, 60, 30, 15, 'NO',
     1100, 2200, 1950, 2100,  1100,  850, 1000,
     'PANTE','PAST','CAJA24', 0.031,
     'NO', 0, 'Excluido de IVA'),

    ('PAH-PT-005',
     'Croissant Mantequilla 80g',
     'Croissant artesanal de masa hojaldrada con margarina cremosa. Crujiente por fuera, suave por dentro. Caja x 6 unidades.',
     @PT, 24, 12, 3, 'NO',
     4200, 8500, 7600, 8000,  4300, 3400, 3800,
     'PANTE','PAST','CAJA6', 0.082,
     'NO', 0, 'Excluido de IVA')

) AS src(Ref, Nom, Desc, TipoID,
         StockMin, PtoReorden, DiasVida, Fracciona,
         Costo, PPubl, PBod, PCred, UPubl, UBod, UCred,
         Marca, GrupoMenor, Pres, Peso,
         IvaSN, IvaVal, IvaDesc)
ON dest.Referencia = src.Ref
WHEN NOT MATCHED THEN
    INSERT (Referencia, Nombre, Descripcion, TipoArticuloID,
            StockMinimo, PuntoReorden, DiasVidaUtil, Fracciona,
            Costo, PPublico, PBodega, PCredito, UPublico, UBodega, UCredito,
            MarcaCodigo, GrupoMenorCodigo, PresentacionCodigo, Peso,
            IvaSiNo, IvaValor, IvaDescripcion)
    VALUES (src.Ref, src.Nom, src.Desc, src.TipoID,
            src.StockMin, src.PtoReorden, src.DiasVida, src.Fracciona,
            src.Costo, src.PPubl, src.PBod, src.PCred, src.UPubl, src.UBod, src.UCred,
            src.Marca, src.GrupoMenor, src.Pres, src.Peso,
            src.IvaSN, src.IvaVal, src.IvaDesc);
PRINT '  PT insertados: ' + CAST(@@ROWCOUNT AS NVARCHAR);
GO

PRINT '';
PRINT '==========================================================';
PRINT 'PARTE 4: Lotes y Stock en Bodega de Materia Prima';
PRINT '==========================================================';

-- Capturar IDs de articulos recien insertados
DECLARE
    @idHarina   INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'PAH-MP-001'),
    @idAzucar   INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'PAH-MP-002'),
    @idSal      INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'PAH-MP-003'),
    @idLevadura INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'PAH-MP-004'),
    @idMargarin INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'PAH-MP-005'),
    @idAceite   INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'PAH-MP-006'),
    @idHuevos   INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'PAH-IN-001'),
    @idEsencia  INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'PAH-IN-002'),
    @idPolvoBH  INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'PAH-IN-003'),
    @idBolsas   INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'PAH-IN-004'),
    @idLeche    INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'PAH-IN-005');

-- Tomar la primera bodega de materia prima disponible
DECLARE @bodegaMP INT = (
    SELECT TOP 1 BodegaID
    FROM Inventario.Bodegas
    WHERE TipoBodega = 'MATERIA_PRIMA' AND Estado = 1
    ORDER BY BodegaID
);

IF @bodegaMP IS NULL
BEGIN
    RAISERROR('ERROR: No existe bodega de tipo MATERIA_PRIMA. Crear una bodega primero.', 16, 1);
    RETURN;
END

PRINT '  Bodega MP seleccionada: ' + CAST(@bodegaMP AS NVARCHAR);

-- Insertar lotes (uno por articulo, fecha fabricacion hoy)
DECLARE @lotHarina   INT, @lotAzucar INT, @lotSal INT,
        @lotLevadura INT, @lotMarg   INT, @lotAceite INT,
        @lotHuevos   INT, @lotEsenc  INT, @lotPolvo INT,
        @lotBolsas   INT, @lotLeche  INT;

INSERT INTO Inventario.Lotes (ArticuloID, NumeroLote, FechaFabricacion, FechaVencimiento, Estado)
VALUES (@idHarina,   'LOT-HAR-2026001', '2026-08-01', '2027-08-01', 'APROBADO');
SET @lotHarina = SCOPE_IDENTITY();

INSERT INTO Inventario.Lotes (ArticuloID, NumeroLote, FechaFabricacion, FechaVencimiento, Estado)
VALUES (@idAzucar,   'LOT-AZU-2026001', '2026-08-01', '2027-08-01', 'APROBADO');
SET @lotAzucar = SCOPE_IDENTITY();

INSERT INTO Inventario.Lotes (ArticuloID, NumeroLote, FechaFabricacion, FechaVencimiento, Estado)
VALUES (@idSal,      'LOT-SAL-2026001', '2026-08-01', '2028-12-31', 'APROBADO');
SET @lotSal = SCOPE_IDENTITY();

INSERT INTO Inventario.Lotes (ArticuloID, NumeroLote, FechaFabricacion, FechaVencimiento, Estado)
VALUES (@idLevadura, 'LOT-LEV-2026001', '2026-08-01', '2027-02-01', 'APROBADO');
SET @lotLevadura = SCOPE_IDENTITY();

INSERT INTO Inventario.Lotes (ArticuloID, NumeroLote, FechaFabricacion, FechaVencimiento, Estado)
VALUES (@idMargarin, 'LOT-MAR-2026001', '2026-08-01', '2027-02-01', 'APROBADO');
SET @lotMarg = SCOPE_IDENTITY();

INSERT INTO Inventario.Lotes (ArticuloID, NumeroLote, FechaFabricacion, FechaVencimiento, Estado)
VALUES (@idAceite,   'LOT-ACE-2026001', '2026-08-01', '2027-08-01', 'APROBADO');
SET @lotAceite = SCOPE_IDENTITY();

INSERT INTO Inventario.Lotes (ArticuloID, NumeroLote, FechaFabricacion, FechaVencimiento, Estado)
VALUES (@idHuevos,   'LOT-HUE-2026001', '2026-08-14', '2026-09-14', 'APROBADO');
SET @lotHuevos = SCOPE_IDENTITY();

INSERT INTO Inventario.Lotes (ArticuloID, NumeroLote, FechaFabricacion, FechaVencimiento, Estado)
VALUES (@idEsencia,  'LOT-ESE-2026001', '2026-08-01', '2028-08-01', 'APROBADO');
SET @lotEsenc = SCOPE_IDENTITY();

INSERT INTO Inventario.Lotes (ArticuloID, NumeroLote, FechaFabricacion, FechaVencimiento, Estado)
VALUES (@idPolvoBH,  'LOT-POL-2026001', '2026-08-01', '2027-08-01', 'APROBADO');
SET @lotPolvo = SCOPE_IDENTITY();

INSERT INTO Inventario.Lotes (ArticuloID, NumeroLote, FechaFabricacion, FechaVencimiento, Estado)
VALUES (@idBolsas,   'LOT-BOL-2026001', '2026-08-01', NULL, 'APROBADO');
SET @lotBolsas = SCOPE_IDENTITY();

INSERT INTO Inventario.Lotes (ArticuloID, NumeroLote, FechaFabricacion, FechaVencimiento, Estado)
VALUES (@idLeche,    'LOT-LEC-2026001', '2026-08-01', '2027-08-01', 'APROBADO');
SET @lotLeche = SCOPE_IDENTITY();

PRINT '  11 lotes creados.';

-- Insertar stock en bodega MP
-- Cantidades: generosas para poder liberar varias OPs
-- Harina  300 kg, Azucar 100 kg, Sal 40 kg, Levadura 8 kg,
-- Margarina 40 kg, Aceite 60 lt
-- Huevos 20 bandejas (CAJA12), Esencia 5 cajas (CAJA24),
-- Polvo 5 kg, Bolsas 15 paquetes, Leche 30 kg

INSERT INTO Inventario.InventarioStock
    (ArticuloID, BodegaID, LoteID, CantidadActual, CostoUnitarioLote)
VALUES
    (@idHarina,   @bodegaMP, @lotHarina,   300.0000, 1850.0000),  -- 300 kg de harina
    (@idAzucar,   @bodegaMP, @lotAzucar,   100.0000, 2100.0000),  -- 100 kg de azucar
    (@idSal,      @bodegaMP, @lotSal,        40.0000,  820.0000),  -- 40 kg de sal
    (@idLevadura, @bodegaMP, @lotLevadura,    8.0000, 22000.0000), -- 8 kg de levadura
    (@idMargarin, @bodegaMP, @lotMarg,       40.0000, 4500.0000),  -- 40 kg de margarina
    (@idAceite,   @bodegaMP, @lotAceite,     60.0000, 3400.0000),  -- 60 lt de aceite
    (@idHuevos,   @bodegaMP, @lotHuevos,     20.0000, 6200.0000),  -- 20 bandejas x12 = 240 huevos
    (@idEsencia,  @bodegaMP, @lotEsenc,       5.0000, 38000.0000), -- 5 cajas x24 frascos
    (@idPolvoBH,  @bodegaMP, @lotPolvo,       5.0000, 14500.0000), -- 5 kg polvo hornear
    (@idBolsas,   @bodegaMP, @lotBolsas,     15.0000, 8200.0000),  -- 15 paquetes x100 bolsas
    (@idLeche,    @bodegaMP, @lotLeche,      30.0000, 9800.0000);  -- 30 kg leche en polvo

PRINT '  Stock inicial insertado: ' + CAST(@@ROWCOUNT AS NVARCHAR) + ' lineas en bodega ' + CAST(@bodegaMP AS NVARCHAR);
GO

PRINT '';
PRINT '==========================================================';
PRINT 'PARTE 5: Recetas BOM';
PRINT '==========================================================';

DECLARE
    @idHarina   INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'PAH-MP-001'),
    @idAzucar   INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'PAH-MP-002'),
    @idSal      INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'PAH-MP-003'),
    @idLevadura INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'PAH-MP-004'),
    @idMargarin INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'PAH-MP-005'),
    @idAceite   INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'PAH-MP-006'),
    @idHuevos   INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'PAH-IN-001'),
    @idEsencia  INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'PAH-IN-002'),
    @idPolvoBH  INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'PAH-IN-003'),
    @idBolsas   INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'PAH-IN-004'),
    @idLeche    INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'PAH-IN-005'),
    @ptPanBlanco INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'PAH-PT-001'),
    @ptPanInteg  INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'PAH-PT-002'),
    @ptGalleta   INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'PAH-PT-003'),
    @ptAlfajor   INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'PAH-PT-004');

-- ── Receta 1: Pan de Molde Blanco ──────────────────────────────────────────
-- Rinde 50 panes de molde en una corrida de produccion
-- Insumos con mix de KG (peso), CAJA12 (huevos = fraccionado) y PAQUETE (bolsas)
DECLARE @recPanBlanco INT;
INSERT INTO Produccion.RecetaBOM
    (ProductoTerminadoID, NombreReceta, Version, CantidadRendimientoBase, Estado)
VALUES (@ptPanBlanco, 'BOM Pan de Molde Blanco v1', 1, 50.0000, 1);
SET @recPanBlanco = SCOPE_IDENTITY();

-- Detalle: cantidades por corrida (50 panes)
-- Huevos: 0.5 bandejas (6 huevos de una bandeja de 12) → EsFraccionado=true, 0.50 cajas
-- UI mostrara: "0.5 cajas · 6 und"
INSERT INTO Produccion.RecetaBOM_Detalle
    (RecetaID, InsumoID, CantidadRequerida, PorcentajeMermaEstandar, Orden)
VALUES
    (@recPanBlanco, @idHarina,    10.0000, 1.50, 1),  -- 10 kg harina OO, merma 1.5%
    (@recPanBlanco, @idAzucar,     0.8000, 0.00, 2),  -- 0.8 kg azucar
    (@recPanBlanco, @idSal,        0.1500, 0.00, 3),  -- 0.15 kg sal
    (@recPanBlanco, @idLevadura,   0.2000, 0.00, 4),  -- 0.2 kg levadura
    (@recPanBlanco, @idMargarin,   0.5000, 0.00, 5),  -- 0.5 kg margarina
    (@recPanBlanco, @idLeche,      0.3000, 0.00, 6),  -- 0.3 kg leche en polvo
    (@recPanBlanco, @idHuevos,     0.5000, 0.00, 7),  -- 0.5 bandejas (6 huevos)
    (@recPanBlanco, @idBolsas,     0.5000, 0.00, 8);  -- 0.5 paquetes (50 bolsas)

PRINT '  Receta Pan Molde Blanco creada (RecetaID=' + CAST(@recPanBlanco AS NVARCHAR) + '). 8 insumos.';

-- ── Receta 2: Pan de Molde Integral ────────────────────────────────────────
-- Rinde 40 panes integrales por corrida
DECLARE @recPanInteg INT;
INSERT INTO Produccion.RecetaBOM
    (ProductoTerminadoID, NombreReceta, Version, CantidadRendimientoBase, Estado)
VALUES (@ptPanInteg, 'BOM Pan de Molde Integral v1', 1, 40.0000, 1);
SET @recPanInteg = SCOPE_IDENTITY();

INSERT INTO Produccion.RecetaBOM_Detalle
    (RecetaID, InsumoID, CantidadRequerida, PorcentajeMermaEstandar, Orden)
VALUES
    (@recPanInteg, @idHarina,    7.5000, 1.50, 1),  -- 7.5 kg harina integral base
    (@recPanInteg, @idAzucar,    0.4000, 0.00, 2),  -- menos azucar que el blanco
    (@recPanInteg, @idSal,       0.1200, 0.00, 3),
    (@recPanInteg, @idLevadura,  0.1800, 0.00, 4),
    (@recPanInteg, @idMargarin,  0.6000, 0.00, 5),  -- mas grasa para suavidad
    (@recPanInteg, @idLeche,     0.4000, 0.00, 6),  -- mas leche para sabor
    (@recPanInteg, @idHuevos,    0.6667, 0.00, 7),  -- ~8 huevos = 0.6667 bandejas
    (@recPanInteg, @idAceite,    0.5000, 0.00, 8),  -- 0.5 lt aceite
    (@recPanInteg, @idBolsas,    0.4000, 0.00, 9);  -- 40 bolsas = 0.4 paquetes

PRINT '  Receta Pan Integral creada (RecetaID=' + CAST(@recPanInteg AS NVARCHAR) + '). 9 insumos.';

-- ── Receta 3: Galleta de Vainilla ──────────────────────────────────────────
-- Rinde 120 unidades de galleta por corrida
DECLARE @recGalleta INT;
INSERT INTO Produccion.RecetaBOM
    (ProductoTerminadoID, NombreReceta, Version, CantidadRendimientoBase, Estado)
VALUES (@ptGalleta, 'BOM Galleta de Vainilla v1', 1, 120.0000, 1);
SET @recGalleta = SCOPE_IDENTITY();

-- Esencia: 2 frascos = 2/24 = 0.0833 cajas → EsFraccionado=true, valida la logica
INSERT INTO Produccion.RecetaBOM_Detalle
    (RecetaID, InsumoID, CantidadRequerida, PorcentajeMermaEstandar, Orden)
VALUES
    (@recGalleta, @idHarina,   3.0000, 1.50, 1),
    (@recGalleta, @idAzucar,   1.2000, 0.00, 2),
    (@recGalleta, @idSal,      0.0500, 0.00, 3),
    (@recGalleta, @idMargarin, 1.5000, 0.00, 4),
    (@recGalleta, @idHuevos,   0.5000, 0.00, 5),  -- 6 huevos = 0.5 bandejas
    (@recGalleta, @idEsencia,  0.0833, 0.00, 6),  -- 2 frascos de 24 por caja = 0.0833 cajas
    (@recGalleta, @idPolvoBH,  0.0300, 0.00, 7);  -- 30g polvo hornear

PRINT '  Receta Galleta Vainilla creada (RecetaID=' + CAST(@recGalleta AS NVARCHAR) + '). 7 insumos.';
GO

PRINT '';
PRINT '==========================================================';
PRINT 'PARTE 6: Ordenes de Produccion (estado Planificada)';
PRINT '==========================================================';

-- Capturar IDs de infraestructura
DECLARE
    @usuID     INT = (SELECT TOP 1 UsuarioID FROM Seguridad.Usuarios WHERE Estado = 1 ORDER BY UsuarioID),
    @ccID      INT = (SELECT TOP 1 CentroCostoID FROM Organizacion.CentrosCosto WHERE Estado = 1 ORDER BY CentroCostoID),
    @bodMP     INT = (SELECT TOP 1 BodegaID FROM Inventario.Bodegas WHERE TipoBodega = 'MATERIA_PRIMA'  AND Estado = 1 ORDER BY BodegaID),
    @bodPT     INT = (SELECT TOP 1 BodegaID FROM Inventario.Bodegas WHERE TipoBodega = 'PRODUCTO_TERMINADO' AND Estado = 1 ORDER BY BodegaID),
    @tipoMTS   INT = (SELECT TOP 1 TipoProduccionID FROM Produccion.TiposProduccion ORDER BY TipoProduccionID),
    @estadoPlan INT = (SELECT EstadoOPID FROM Produccion.EstadosOP WHERE Nombre = 'Planificada');

DECLARE
    @ptPanBlanco INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'PAH-PT-001'),
    @ptPanInteg  INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'PAH-PT-002'),
    @ptGalleta   INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'PAH-PT-003'),
    @recPanBlanco INT = (SELECT RecetaID FROM Produccion.RecetaBOM WHERE NombreReceta = 'BOM Pan de Molde Blanco v1'),
    @recPanInteg  INT = (SELECT RecetaID FROM Produccion.RecetaBOM WHERE NombreReceta = 'BOM Pan de Molde Integral v1'),
    @recGalleta   INT = (SELECT RecetaID FROM Produccion.RecetaBOM WHERE NombreReceta = 'BOM Galleta de Vainilla v1');

IF @usuID IS NULL OR @ccID IS NULL OR @bodMP IS NULL OR @bodPT IS NULL
BEGIN
    RAISERROR('ERROR: Falta usuario, centro de costo o bodegas. Verificar datos de organizacion.', 16, 1);
    RETURN;
END

IF @tipoMTS IS NULL OR @estadoPlan IS NULL
BEGIN
    RAISERROR('ERROR: TiposProduccion o EstadosOP vacios. Verificar seed de produccion.', 16, 1);
    RETURN;
END

PRINT '  UsuarioID=' + CAST(@usuID AS NVARCHAR) +
      ', CentroCostoID=' + CAST(@ccID AS NVARCHAR) +
      ', BodegaMP=' + CAST(@bodMP AS NVARCHAR) +
      ', BodegaPT=' + CAST(@bodPT AS NVARCHAR);

-- OP-001: 100 panes de molde blanco (2 corridas de receta)
-- CantidadRendimientoBase=50 → FactorEscala = 100/50 = 2
INSERT INTO Produccion.OrdenesProduccion
    (CodigoOP, TipoProduccionID, EstadoOPID, ProductoTerminadoID, RecetaID,
     CantidadProgramada, CentroCostoDestinoID, BodegaOrigenMPID, BodegaDestinoPTID,
     FechaPlanificada, Observaciones, UsuarioCreaID)
VALUES
    ('OP-2026-001', @tipoMTS, @estadoPlan, @ptPanBlanco, @recPanBlanco,
     100.0000, @ccID, @bodMP, @bodPT,
     '2026-08-18 06:00:00', 'Produccion regular semana 33. Pedido interno + distribucion.', @usuID);

PRINT '  OP-2026-001 creada: 100 panes de molde blanco.';

-- OP-002: 80 panes integrales (2 corridas de receta)
INSERT INTO Produccion.OrdenesProduccion
    (CodigoOP, TipoProduccionID, EstadoOPID, ProductoTerminadoID, RecetaID,
     CantidadProgramada, CentroCostoDestinoID, BodegaOrigenMPID, BodegaDestinoPTID,
     FechaPlanificada, Observaciones, UsuarioCreaID)
VALUES
    ('OP-2026-002', @tipoMTS, @estadoPlan, @ptPanInteg, @recPanInteg,
     80.0000, @ccID, @bodMP, @bodPT,
     '2026-08-19 06:00:00', 'Lote integral para tiendas naturistas. Coordinado con ventas.', @usuID);

PRINT '  OP-2026-002 creada: 80 panes integrales.';

-- OP-003: 360 galletas de vainilla (3 corridas de receta, rinde 120 c/u)
INSERT INTO Produccion.OrdenesProduccion
    (CodigoOP, TipoProduccionID, EstadoOPID, ProductoTerminadoID, RecetaID,
     CantidadProgramada, CentroCostoDestinoID, BodegaOrigenMPID, BodegaDestinoPTID,
     FechaPlanificada, Observaciones, UsuarioCreaID)
VALUES
    ('OP-2026-003', @tipoMTS, @estadoPlan, @ptGalleta, @recGalleta,
     360.0000, @ccID, @bodMP, @bodPT,
     '2026-08-20 07:00:00', 'Galletas para pedido supermercado. Fecha compromiso 22-ago.', @usuID);

PRINT '  OP-2026-003 creada: 360 galletas de vainilla.';
GO

PRINT '';
PRINT '==========================================================';
PRINT 'VERIFICACION FINAL';
PRINT '==========================================================';

SELECT
    ta.Nombre AS Tipo,
    p.Codigo AS Presentacion,
    p.Fracciones,
    p.Tipo AS TipoPresentacion,
    COUNT(*) AS Cantidad
FROM Catalogo.Tarjetas t
JOIN Catalogo.TiposArticulo ta ON ta.TipoArticuloID = t.TipoArticuloID
LEFT JOIN Catalogo.Presentacion p ON p.Codigo = t.PresentacionCodigo
WHERE t.Referencia LIKE 'PAH-%'
GROUP BY ta.Nombre, p.Codigo, p.Fracciones, p.Tipo
ORDER BY ta.Nombre, p.Codigo;

SELECT
    t.Referencia, t.Nombre, ta.Nombre AS Tipo,
    t.PresentacionCodigo AS Pres,
    ISNULL(p.Fracciones, 0) AS Fracciones,
    p.Tipo AS TipoPres,
    t.Peso, t.Costo
FROM Catalogo.Tarjetas t
JOIN Catalogo.TiposArticulo ta ON ta.TipoArticuloID = t.TipoArticuloID
LEFT JOIN Catalogo.Presentacion p ON p.Codigo = t.PresentacionCodigo
WHERE t.Referencia LIKE 'PAH-%'
ORDER BY ta.Nombre, t.Referencia;

SELECT
    r.RecetaID, r.NombreReceta, r.Version,
    a.Nombre AS ProductoTerminado,
    a.PresentacionCodigo AS PresentacionPT,
    p.Fracciones AS FraccionesPT,
    r.CantidadRendimientoBase,
    COUNT(d.RecetaDetalleID) AS NumInsumos
FROM Produccion.RecetaBOM r
JOIN Catalogo.Tarjetas a ON a.ArticuloID = r.ProductoTerminadoID
LEFT JOIN Catalogo.Presentacion p ON p.Codigo = a.PresentacionCodigo
JOIN Produccion.RecetaBOM_Detalle d ON d.RecetaID = r.RecetaID
GROUP BY r.RecetaID, r.NombreReceta, r.Version, a.Nombre, a.PresentacionCodigo, p.Fracciones, r.CantidadRendimientoBase;

SELECT
    op.CodigoOP, e.Nombre AS Estado,
    a.Nombre AS Producto,
    op.CantidadProgramada,
    r.NombreReceta,
    op.FechaPlanificada
FROM Produccion.OrdenesProduccion op
JOIN Produccion.EstadosOP e ON e.EstadoOPID = op.EstadoOPID
JOIN Catalogo.Tarjetas a ON a.ArticuloID = op.ProductoTerminadoID
JOIN Produccion.RecetaBOM r ON r.RecetaID = op.RecetaID
ORDER BY op.CodigoOP;

SELECT
    t.Referencia, t.Nombre,
    s.CantidadActual, t.PresentacionCodigo AS Pres,
    ISNULL(p.Fracciones,0) AS Fracciones,
    s.CostoUnitarioLote AS CostoUnitario,
    s.CantidadActual * s.CostoUnitarioLote AS ValorTotal
FROM Inventario.InventarioStock s
JOIN Catalogo.Tarjetas t ON t.ArticuloID = s.ArticuloID
LEFT JOIN Catalogo.Presentacion p ON p.Codigo = t.PresentacionCodigo
ORDER BY t.Referencia;
GO

PRINT '=== seed_panaderia_v1 completado. ===';
PRINT '>>> 6 MP + 5 Insumos + 5 PT = 16 articulos';
PRINT '>>> 3 recetas BOM con 24 lineas de detalle';
PRINT '>>> 3 OPs en estado Planificada';
PRINT '>>> 11 lotes con stock suficiente para liberar todas las OPs';
GO
