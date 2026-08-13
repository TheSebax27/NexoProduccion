-- ============================================================
-- Datos de prueba: Cafetería & Pastelería "La Dulce Mañana"
-- sqlcmd -S DESKTOP-V83PQ7M\JONATHAN -d NEXO_ERP -i C:\Produccion\sql\test_cafeteria.sql
-- ============================================================
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;

-- ── 0. Unidades de medida ─────────────────────────────────────
DECLARE @UndID INT = (SELECT TOP 1 UnidadID FROM Catalogo.UnidadesMedida WHERE Abreviatura = 'und');
DECLARE @KgID  INT = (SELECT TOP 1 UnidadID FROM Catalogo.UnidadesMedida WHERE Abreviatura = 'kg');
DECLARE @GrID  INT = (SELECT TOP 1 UnidadID FROM Catalogo.UnidadesMedida WHERE Abreviatura = 'g');
DECLARE @LtID  INT = (SELECT TOP 1 UnidadID FROM Catalogo.UnidadesMedida WHERE Abreviatura = 'L');
DECLARE @MlID  INT = (SELECT TOP 1 UnidadID FROM Catalogo.UnidadesMedida WHERE Abreviatura = 'ml');

IF @UndID IS NULL OR @KgID IS NULL OR @GrID IS NULL
BEGIN
    RAISERROR('Faltan unidades de medida (und / kg / g). Verifica Catalogo.UnidadesMedida.', 16, 1);
    RETURN;
END

-- Si ml o L no existen, caen a und
IF @MlID IS NULL SET @MlID = @UndID;
IF @LtID  IS NULL SET @LtID  = @UndID;

-- ── 1. Centro de costo y bodega ───────────────────────────────
DECLARE @CcID  INT = (SELECT TOP 1 CentroCostoID FROM Organizacion.CentrosCosto  WHERE Estado = 1);
DECLARE @BodID INT = (SELECT TOP 1 BodegaID      FROM Inventario.Bodegas         WHERE Estado = 1);

PRINT 'CentroCostoID=' + ISNULL(CAST(@CcID  AS VARCHAR),'NULL')
    + '  BodegaID='    + ISNULL(CAST(@BodID AS VARCHAR),'NULL');

-- ── 2. TipoArticuloID ─────────────────────────────────────────
DECLARE @TipoMP INT = (SELECT TOP 1 TipoArticuloID FROM Catalogo.TiposArticulo WHERE Nombre = 'Materia Prima');
DECLARE @TipoPT INT = (SELECT TOP 1 TipoArticuloID FROM Catalogo.TiposArticulo WHERE Nombre = 'Producto Terminado');

IF @TipoMP IS NULL OR @TipoPT IS NULL
BEGIN
    RAISERROR('No se encontraron los tipos de artículo MP / PT.', 16, 1);
    RETURN;
END

-- ── 3. Materias Primas ────────────────────────────────────────
-- Insertar solo si no existen (idempotente por SKU)

IF NOT EXISTS (SELECT 1 FROM Catalogo.Articulos WHERE SKU = 'MP-CF-HARINA')
    INSERT INTO Catalogo.Articulos (SKU, Nombre, TipoArticuloID, UnidadID, PrecioVenta, CostoPromedio, StockMinimo, PuntoReorden, Estado)
    VALUES ('MP-CF-HARINA', 'Harina de trigo', @TipoMP, @KgID, 0, 2500, 20, 40, 1);

IF NOT EXISTS (SELECT 1 FROM Catalogo.Articulos WHERE SKU = 'MP-CF-MANTEQUILLA')
    INSERT INTO Catalogo.Articulos (SKU, Nombre, TipoArticuloID, UnidadID, PrecioVenta, CostoPromedio, StockMinimo, PuntoReorden, Estado)
    VALUES ('MP-CF-MANTEQUILLA', 'Mantequilla sin sal', @TipoMP, @KgID, 0, 15000, 5, 10, 1);

IF NOT EXISTS (SELECT 1 FROM Catalogo.Articulos WHERE SKU = 'MP-CF-AZUCAR')
    INSERT INTO Catalogo.Articulos (SKU, Nombre, TipoArticuloID, UnidadID, PrecioVenta, CostoPromedio, StockMinimo, PuntoReorden, Estado)
    VALUES ('MP-CF-AZUCAR', 'Azúcar blanca', @TipoMP, @KgID, 0, 3200, 10, 20, 1);

IF NOT EXISTS (SELECT 1 FROM Catalogo.Articulos WHERE SKU = 'MP-CF-HUEVO')
    INSERT INTO Catalogo.Articulos (SKU, Nombre, TipoArticuloID, UnidadID, PrecioVenta, CostoPromedio, StockMinimo, PuntoReorden, Estado)
    VALUES ('MP-CF-HUEVO', 'Huevo (unidad)', @TipoMP, @UndID, 0, 600, 30, 60, 1);

IF NOT EXISTS (SELECT 1 FROM Catalogo.Articulos WHERE SKU = 'MP-CF-LECHE')
    INSERT INTO Catalogo.Articulos (SKU, Nombre, TipoArticuloID, UnidadID, PrecioVenta, CostoPromedio, StockMinimo, PuntoReorden, Estado)
    VALUES ('MP-CF-LECHE', 'Leche entera (L)', @TipoMP, @LtID, 0, 3500, 10, 20, 1);

IF NOT EXISTS (SELECT 1 FROM Catalogo.Articulos WHERE SKU = 'MP-CF-SAL')
    INSERT INTO Catalogo.Articulos (SKU, Nombre, TipoArticuloID, UnidadID, PrecioVenta, CostoPromedio, StockMinimo, PuntoReorden, Estado)
    VALUES ('MP-CF-SAL', 'Sal fina', @TipoMP, @KgID, 0, 1500, 2, 5, 1);

IF NOT EXISTS (SELECT 1 FROM Catalogo.Articulos WHERE SKU = 'MP-CF-LEVADURA')
    INSERT INTO Catalogo.Articulos (SKU, Nombre, TipoArticuloID, UnidadID, PrecioVenta, CostoPromedio, StockMinimo, PuntoReorden, Estado)
    VALUES ('MP-CF-LEVADURA', 'Levadura seca (g)', @TipoMP, @GrID, 0, 80, 500, 1000, 1);

IF NOT EXISTS (SELECT 1 FROM Catalogo.Articulos WHERE SKU = 'MP-CF-CACAO')
    INSERT INTO Catalogo.Articulos (SKU, Nombre, TipoArticuloID, UnidadID, PrecioVenta, CostoPromedio, StockMinimo, PuntoReorden, Estado)
    VALUES ('MP-CF-CACAO', 'Cacao en polvo', @TipoMP, @KgID, 0, 18000, 3, 6, 1);

IF NOT EXISTS (SELECT 1 FROM Catalogo.Articulos WHERE SKU = 'MP-CF-QCREMA')
    INSERT INTO Catalogo.Articulos (SKU, Nombre, TipoArticuloID, UnidadID, PrecioVenta, CostoPromedio, StockMinimo, PuntoReorden, Estado)
    VALUES ('MP-CF-QCREMA', 'Queso crema', @TipoMP, @KgID, 0, 22000, 3, 6, 1);

IF NOT EXISTS (SELECT 1 FROM Catalogo.Articulos WHERE SKU = 'MP-CF-FRESA')
    INSERT INTO Catalogo.Articulos (SKU, Nombre, TipoArticuloID, UnidadID, PrecioVenta, CostoPromedio, StockMinimo, PuntoReorden, Estado)
    VALUES ('MP-CF-FRESA', 'Fresa fresca (kg)', @TipoMP, @KgID, 0, 8000, 3, 6, 1);

IF NOT EXISTS (SELECT 1 FROM Catalogo.Articulos WHERE SKU = 'MP-CF-CREMA')
    INSERT INTO Catalogo.Articulos (SKU, Nombre, TipoArticuloID, UnidadID, PrecioVenta, CostoPromedio, StockMinimo, PuntoReorden, Estado)
    VALUES ('MP-CF-CREMA', 'Crema de leche (L)', @TipoMP, @LtID, 0, 7500, 3, 6, 1);

IF NOT EXISTS (SELECT 1 FROM Catalogo.Articulos WHERE SKU = 'MP-CF-CHOCO')
    INSERT INTO Catalogo.Articulos (SKU, Nombre, TipoArticuloID, UnidadID, PrecioVenta, CostoPromedio, StockMinimo, PuntoReorden, Estado)
    VALUES ('MP-CF-CHOCO', 'Chocolate oscuro 70%', @TipoMP, @KgID, 0, 25000, 2, 4, 1);

IF NOT EXISTS (SELECT 1 FROM Catalogo.Articulos WHERE SKU = 'MP-CF-CAFE')
    INSERT INTO Catalogo.Articulos (SKU, Nombre, TipoArticuloID, UnidadID, PrecioVenta, CostoPromedio, StockMinimo, PuntoReorden, Estado)
    VALUES ('MP-CF-CAFE', 'Café molido (g)', @TipoMP, @GrID, 0, 120, 2000, 4000, 1);

IF NOT EXISTS (SELECT 1 FROM Catalogo.Articulos WHERE SKU = 'MP-CF-VAINILLA')
    INSERT INTO Catalogo.Articulos (SKU, Nombre, TipoArticuloID, UnidadID, PrecioVenta, CostoPromedio, StockMinimo, PuntoReorden, Estado)
    VALUES ('MP-CF-VAINILLA', 'Esencia de vainilla (ml)', @TipoMP, @MlID, 0, 500, 200, 400, 1);

IF NOT EXISTS (SELECT 1 FROM Catalogo.Articulos WHERE SKU = 'MP-CF-PAPEL')
    INSERT INTO Catalogo.Articulos (SKU, Nombre, TipoArticuloID, UnidadID, PrecioVenta, CostoPromedio, StockMinimo, PuntoReorden, Estado)
    VALUES ('MP-CF-PAPEL', 'Papel para hornear (pliego)', @TipoMP, @UndID, 0, 200, 100, 200, 1);

PRINT '✓ Materias primas insertadas.';

-- ── 4. Productos Terminados ───────────────────────────────────

IF NOT EXISTS (SELECT 1 FROM Catalogo.Articulos WHERE SKU = 'PT-CF-PAN-MOLDE')
    INSERT INTO Catalogo.Articulos (SKU, Nombre, TipoArticuloID, UnidadID, PrecioVenta, StockMinimo, PuntoReorden, Estado)
    VALUES ('PT-CF-PAN-MOLDE', 'Pan de molde artesanal (unidad)', @TipoPT, @UndID, 8500, 10, 20, 1);

IF NOT EXISTS (SELECT 1 FROM Catalogo.Articulos WHERE SKU = 'PT-CF-CROISSANT')
    INSERT INTO Catalogo.Articulos (SKU, Nombre, TipoArticuloID, UnidadID, PrecioVenta, StockMinimo, PuntoReorden, Estado)
    VALUES ('PT-CF-CROISSANT', 'Croissant de mantequilla', @TipoPT, @UndID, 4500, 20, 40, 1);

IF NOT EXISTS (SELECT 1 FROM Catalogo.Articulos WHERE SKU = 'PT-CF-MUFFIN-CHOCO')
    INSERT INTO Catalogo.Articulos (SKU, Nombre, TipoArticuloID, UnidadID, PrecioVenta, StockMinimo, PuntoReorden, Estado)
    VALUES ('PT-CF-MUFFIN-CHOCO', 'Muffin de chocolate', @TipoPT, @UndID, 4000, 20, 40, 1);

IF NOT EXISTS (SELECT 1 FROM Catalogo.Articulos WHERE SKU = 'PT-CF-TORTA-FRESA')
    INSERT INTO Catalogo.Articulos (SKU, Nombre, TipoArticuloID, UnidadID, PrecioVenta, StockMinimo, PuntoReorden, Estado)
    VALUES ('PT-CF-TORTA-FRESA', 'Torta de fresas (porción)', @TipoPT, @UndID, 12000, 5, 10, 1);

IF NOT EXISTS (SELECT 1 FROM Catalogo.Articulos WHERE SKU = 'PT-CF-CHEESECAKE')
    INSERT INTO Catalogo.Articulos (SKU, Nombre, TipoArticuloID, UnidadID, PrecioVenta, StockMinimo, PuntoReorden, Estado)
    VALUES ('PT-CF-CHEESECAKE', 'Cheesecake de fresas (porción)', @TipoPT, @UndID, 15000, 5, 10, 1);

IF NOT EXISTS (SELECT 1 FROM Catalogo.Articulos WHERE SKU = 'PT-CF-BROWNIE')
    INSERT INTO Catalogo.Articulos (SKU, Nombre, TipoArticuloID, UnidadID, PrecioVenta, StockMinimo, PuntoReorden, Estado)
    VALUES ('PT-CF-BROWNIE', 'Brownie de chocolate (unidad)', @TipoPT, @UndID, 5000, 15, 30, 1);

PRINT '✓ Productos terminados insertados.';

-- ── 5. IDs de artículos ───────────────────────────────────────
DECLARE @mpHarina     INT = (SELECT ArticuloID FROM Catalogo.Articulos WHERE SKU = 'MP-CF-HARINA');
DECLARE @mpMant       INT = (SELECT ArticuloID FROM Catalogo.Articulos WHERE SKU = 'MP-CF-MANTEQUILLA');
DECLARE @mpAzucar     INT = (SELECT ArticuloID FROM Catalogo.Articulos WHERE SKU = 'MP-CF-AZUCAR');
DECLARE @mpHuevo      INT = (SELECT ArticuloID FROM Catalogo.Articulos WHERE SKU = 'MP-CF-HUEVO');
DECLARE @mpLeche      INT = (SELECT ArticuloID FROM Catalogo.Articulos WHERE SKU = 'MP-CF-LECHE');
DECLARE @mpSal        INT = (SELECT ArticuloID FROM Catalogo.Articulos WHERE SKU = 'MP-CF-SAL');
DECLARE @mpLevadura   INT = (SELECT ArticuloID FROM Catalogo.Articulos WHERE SKU = 'MP-CF-LEVADURA');
DECLARE @mpCacao      INT = (SELECT ArticuloID FROM Catalogo.Articulos WHERE SKU = 'MP-CF-CACAO');
DECLARE @mpQcrema     INT = (SELECT ArticuloID FROM Catalogo.Articulos WHERE SKU = 'MP-CF-QCREMA');
DECLARE @mpFresa      INT = (SELECT ArticuloID FROM Catalogo.Articulos WHERE SKU = 'MP-CF-FRESA');
DECLARE @mpCrema      INT = (SELECT ArticuloID FROM Catalogo.Articulos WHERE SKU = 'MP-CF-CREMA');
DECLARE @mpChoco      INT = (SELECT ArticuloID FROM Catalogo.Articulos WHERE SKU = 'MP-CF-CHOCO');
DECLARE @mpCafe       INT = (SELECT ArticuloID FROM Catalogo.Articulos WHERE SKU = 'MP-CF-CAFE');
DECLARE @mpVainilla   INT = (SELECT ArticuloID FROM Catalogo.Articulos WHERE SKU = 'MP-CF-VAINILLA');
DECLARE @mpPapel      INT = (SELECT ArticuloID FROM Catalogo.Articulos WHERE SKU = 'MP-CF-PAPEL');

DECLARE @ptPanMolde   INT = (SELECT ArticuloID FROM Catalogo.Articulos WHERE SKU = 'PT-CF-PAN-MOLDE');
DECLARE @ptCroissant  INT = (SELECT ArticuloID FROM Catalogo.Articulos WHERE SKU = 'PT-CF-CROISSANT');
DECLARE @ptMuffin     INT = (SELECT ArticuloID FROM Catalogo.Articulos WHERE SKU = 'PT-CF-MUFFIN-CHOCO');
DECLARE @ptTorta      INT = (SELECT ArticuloID FROM Catalogo.Articulos WHERE SKU = 'PT-CF-TORTA-FRESA');
DECLARE @ptCheese     INT = (SELECT ArticuloID FROM Catalogo.Articulos WHERE SKU = 'PT-CF-CHEESECAKE');
DECLARE @ptBrownie    INT = (SELECT ArticuloID FROM Catalogo.Articulos WHERE SKU = 'PT-CF-BROWNIE');

-- ── 6. Recetas BOM ────────────────────────────────────────────

-- 6a. Pan de molde artesanal (rinde 1 pan)
IF NOT EXISTS (SELECT 1 FROM Produccion.RecetaBOM WHERE ProductoTerminadoID = @ptPanMolde)
    INSERT INTO Produccion.RecetaBOM (ProductoTerminadoID, NombreReceta, Version, CantidadRendimientoBase, UnidadRendimientoID, Estado)
    VALUES (@ptPanMolde, 'Pan de molde artesanal', 1, 1, @UndID, 1);

DECLARE @rPan INT = (SELECT TOP 1 RecetaID FROM Produccion.RecetaBOM WHERE ProductoTerminadoID = @ptPanMolde);
DELETE FROM Produccion.RecetaBOM_Detalle WHERE RecetaID = @rPan;
INSERT INTO Produccion.RecetaBOM_Detalle (RecetaID, InsumoID, CantidadRequerida, UnidadID, PorcentajeMermaEstandar, Orden) VALUES
    (@rPan, @mpHarina,    0.500, @KgID,  2, 1),
    (@rPan, @mpLeche,     0.300, @LtID,  0, 2),
    (@rPan, @mpMant,      0.050, @KgID,  0, 3),
    (@rPan, @mpAzucar,    0.030, @KgID,  0, 4),
    (@rPan, @mpSal,       0.008, @KgID,  0, 5),
    (@rPan, @mpLevadura,  7,     @GrID,  0, 6),
    (@rPan, @mpHuevo,     1,     @UndID, 5, 7),
    (@rPan, @mpPapel,     1,     @UndID, 0, 8);

-- 6b. Croissant de mantequilla (rinde 1 unidad)
IF NOT EXISTS (SELECT 1 FROM Produccion.RecetaBOM WHERE ProductoTerminadoID = @ptCroissant)
    INSERT INTO Produccion.RecetaBOM (ProductoTerminadoID, NombreReceta, Version, CantidadRendimientoBase, UnidadRendimientoID, Estado)
    VALUES (@ptCroissant, 'Croissant de mantequilla', 1, 1, @UndID, 1);

DECLARE @rCroi INT = (SELECT TOP 1 RecetaID FROM Produccion.RecetaBOM WHERE ProductoTerminadoID = @ptCroissant);
DELETE FROM Produccion.RecetaBOM_Detalle WHERE RecetaID = @rCroi;
INSERT INTO Produccion.RecetaBOM_Detalle (RecetaID, InsumoID, CantidadRequerida, UnidadID, PorcentajeMermaEstandar, Orden) VALUES
    (@rCroi, @mpHarina,   0.080, @KgID,  2, 1),
    (@rCroi, @mpMant,     0.045, @KgID,  0, 2),
    (@rCroi, @mpLeche,    0.040, @LtID,  0, 3),
    (@rCroi, @mpSal,      0.002, @KgID,  0, 4),
    (@rCroi, @mpAzucar,   0.008, @KgID,  0, 5),
    (@rCroi, @mpLevadura, 2,     @GrID,  0, 6);

-- 6c. Muffin de chocolate (rinde 1 unidad)
IF NOT EXISTS (SELECT 1 FROM Produccion.RecetaBOM WHERE ProductoTerminadoID = @ptMuffin)
    INSERT INTO Produccion.RecetaBOM (ProductoTerminadoID, NombreReceta, Version, CantidadRendimientoBase, UnidadRendimientoID, Estado)
    VALUES (@ptMuffin, 'Muffin de chocolate', 1, 1, @UndID, 1);

DECLARE @rMuff INT = (SELECT TOP 1 RecetaID FROM Produccion.RecetaBOM WHERE ProductoTerminadoID = @ptMuffin);
DELETE FROM Produccion.RecetaBOM_Detalle WHERE RecetaID = @rMuff;
INSERT INTO Produccion.RecetaBOM_Detalle (RecetaID, InsumoID, CantidadRequerida, UnidadID, PorcentajeMermaEstandar, Orden) VALUES
    (@rMuff, @mpHarina,   0.060, @KgID,  2, 1),
    (@rMuff, @mpCacao,    0.020, @KgID,  0, 2),
    (@rMuff, @mpAzucar,   0.050, @KgID,  0, 3),
    (@rMuff, @mpHuevo,    1,     @UndID, 5, 4),
    (@rMuff, @mpLeche,    0.060, @LtID,  0, 5),
    (@rMuff, @mpMant,     0.030, @KgID,  0, 6),
    (@rMuff, @mpVainilla, 2,     @MlID,  0, 7),
    (@rMuff, @mpPapel,    1,     @UndID, 0, 8);

-- 6d. Torta de fresas — porción (rinde 1 porción, base de 12)
IF NOT EXISTS (SELECT 1 FROM Produccion.RecetaBOM WHERE ProductoTerminadoID = @ptTorta)
    INSERT INTO Produccion.RecetaBOM (ProductoTerminadoID, NombreReceta, Version, CantidadRendimientoBase, UnidadRendimientoID, Estado)
    VALUES (@ptTorta, 'Torta de fresas (porción x12)', 1, 12, @UndID, 1);

DECLARE @rTort INT = (SELECT TOP 1 RecetaID FROM Produccion.RecetaBOM WHERE ProductoTerminadoID = @ptTorta);
DELETE FROM Produccion.RecetaBOM_Detalle WHERE RecetaID = @rTort;
INSERT INTO Produccion.RecetaBOM_Detalle (RecetaID, InsumoID, CantidadRequerida, UnidadID, PorcentajeMermaEstandar, Orden) VALUES
    (@rTort, @mpHarina,  0.250, @KgID,  2, 1),
    (@rTort, @mpAzucar,  0.200, @KgID,  0, 2),
    (@rTort, @mpHuevo,   4,     @UndID, 5, 3),
    (@rTort, @mpMant,    0.120, @KgID,  0, 4),
    (@rTort, @mpLeche,   0.100, @LtID,  0, 5),
    (@rTort, @mpFresa,   0.400, @KgID,  10,6),
    (@rTort, @mpCrema,   0.200, @LtID,  0, 7),
    (@rTort, @mpVainilla,5,     @MlID,  0, 8),
    (@rTort, @mpPapel,   2,     @UndID, 0, 9);

-- 6e. Cheesecake de fresas — porción (rinde 1 porción, base de 10)
IF NOT EXISTS (SELECT 1 FROM Produccion.RecetaBOM WHERE ProductoTerminadoID = @ptCheese)
    INSERT INTO Produccion.RecetaBOM (ProductoTerminadoID, NombreReceta, Version, CantidadRendimientoBase, UnidadRendimientoID, Estado)
    VALUES (@ptCheese, 'Cheesecake de fresas (porción x10)', 1, 10, @UndID, 1);

DECLARE @rChes INT = (SELECT TOP 1 RecetaID FROM Produccion.RecetaBOM WHERE ProductoTerminadoID = @ptCheese);
DELETE FROM Produccion.RecetaBOM_Detalle WHERE RecetaID = @rChes;
INSERT INTO Produccion.RecetaBOM_Detalle (RecetaID, InsumoID, CantidadRequerida, UnidadID, PorcentajeMermaEstandar, Orden) VALUES
    (@rChes, @mpQcrema,  0.600, @KgID,  0, 1),
    (@rChes, @mpAzucar,  0.150, @KgID,  0, 2),
    (@rChes, @mpHuevo,   3,     @UndID, 5, 3),
    (@rChes, @mpCrema,   0.200, @LtID,  0, 4),
    (@rChes, @mpFresa,   0.300, @KgID,  10,5),
    (@rChes, @mpMant,    0.080, @KgID,  0, 6),
    (@rChes, @mpVainilla,3,     @MlID,  0, 7);

-- 6f. Brownie de chocolate (rinde 1 unidad)
IF NOT EXISTS (SELECT 1 FROM Produccion.RecetaBOM WHERE ProductoTerminadoID = @ptBrownie)
    INSERT INTO Produccion.RecetaBOM (ProductoTerminadoID, NombreReceta, Version, CantidadRendimientoBase, UnidadRendimientoID, Estado)
    VALUES (@ptBrownie, 'Brownie de chocolate', 1, 1, @UndID, 1);

DECLARE @rBrow INT = (SELECT TOP 1 RecetaID FROM Produccion.RecetaBOM WHERE ProductoTerminadoID = @ptBrownie);
DELETE FROM Produccion.RecetaBOM_Detalle WHERE RecetaID = @rBrow;
INSERT INTO Produccion.RecetaBOM_Detalle (RecetaID, InsumoID, CantidadRequerida, UnidadID, PorcentajeMermaEstandar, Orden) VALUES
    (@rBrow, @mpChoco,   0.050, @KgID,  0, 1),
    (@rBrow, @mpMant,    0.035, @KgID,  0, 2),
    (@rBrow, @mpAzucar,  0.060, @KgID,  0, 3),
    (@rBrow, @mpHuevo,   1,     @UndID, 5, 4),
    (@rBrow, @mpHarina,  0.030, @KgID,  2, 5),
    (@rBrow, @mpCacao,   0.010, @KgID,  0, 6),
    (@rBrow, @mpPapel,   1,     @UndID, 0, 7);

PRINT '✓ Recetas BOM insertadas.';

-- ── 7. Maquinaria de la cafetería ─────────────────────────────
DECLARE @TipoHorno  INT = (SELECT TipoMaquinariaID FROM Produccion.TiposMaquinaria WHERE Nombre = 'Horno Industrial');
DECLARE @TipoAmasa  INT = (SELECT TipoMaquinariaID FROM Produccion.TiposMaquinaria WHERE Nombre = 'Mezcladora / Amasadora');
DECLARE @TipoBasc   INT = (SELECT TipoMaquinariaID FROM Produccion.TiposMaquinaria WHERE Nombre = 'Báscula / Balanza');
DECLARE @TipoFrio   INT = (SELECT TipoMaquinariaID FROM Produccion.TiposMaquinaria WHERE Nombre = 'Equipo de frío');

IF @TipoHorno IS NULL SET @TipoHorno = (SELECT TOP 1 TipoMaquinariaID FROM Produccion.TiposMaquinaria);
IF @TipoAmasa IS NULL SET @TipoAmasa = (SELECT TOP 1 TipoMaquinariaID FROM Produccion.TiposMaquinaria);
IF @TipoBasc  IS NULL SET @TipoBasc  = (SELECT TOP 1 TipoMaquinariaID FROM Produccion.TiposMaquinaria);
IF @TipoFrio  IS NULL SET @TipoFrio  = (SELECT TOP 1 TipoMaquinariaID FROM Produccion.TiposMaquinaria);

IF NOT EXISTS (SELECT 1 FROM Produccion.Maquinaria WHERE Codigo = 'MAQ-HORNO-01')
    INSERT INTO Produccion.Maquinaria
        (Codigo, Nombre, TipoMaquinariaID, Estado, Marca, Modelo, NumeroSerie,
         FechaAdquisicion, VidaUtilAnios, CostoAdquisicion, CostoHoraOperacion,
         CapacidadMaxima, UnidadCapacidad, UbicacionFisica, Notas)
    VALUES
        ('MAQ-HORNO-01', 'Horno de convección A', @TipoHorno, 'Activa', 'Rational', 'SCC61E', 'RT-2021-00417',
         '2021-03-15', 12, 18500000, 2500,
         6, 'bandejas', 'Área de horneado', 'Horno principal, 6 bandejas GN 1/1');

IF NOT EXISTS (SELECT 1 FROM Produccion.Maquinaria WHERE Codigo = 'MAQ-HORNO-02')
    INSERT INTO Produccion.Maquinaria
        (Codigo, Nombre, TipoMaquinariaID, Estado, Marca, Modelo, NumeroSerie,
         FechaAdquisicion, VidaUtilAnios, CostoAdquisicion, CostoHoraOperacion,
         CapacidadMaxima, UnidadCapacidad, UbicacionFisica, Notas)
    VALUES
        ('MAQ-HORNO-02', 'Horno de convección B', @TipoHorno, 'Activa', 'Rational', 'SCC61E', 'RT-2022-00832',
         '2022-07-10', 12, 18500000, 2500,
         6, 'bandejas', 'Área de horneado', 'Horno de respaldo y producción adicional');

IF NOT EXISTS (SELECT 1 FROM Produccion.Maquinaria WHERE Codigo = 'MAQ-AMASADORA-01')
    INSERT INTO Produccion.Maquinaria
        (Codigo, Nombre, TipoMaquinariaID, Estado, Marca, Modelo, NumeroSerie,
         FechaAdquisicion, VidaUtilAnios, CostoAdquisicion, CostoHoraOperacion,
         CapacidadMaxima, UnidadCapacidad, UbicacionFisica, Notas)
    VALUES
        ('MAQ-AMASADORA-01', 'Amasadora espiral 20kg', @TipoAmasa, 'Activa', 'Sammic', 'AM-20', 'SM-2020-01132',
         '2020-11-08', 10, 9800000, 1200,
         20, 'kg', 'Área de panadería', 'Amasadora para pan y masas fermentadas');

IF NOT EXISTS (SELECT 1 FROM Produccion.Maquinaria WHERE Codigo = 'MAQ-BATIDORA-01')
    INSERT INTO Produccion.Maquinaria
        (Codigo, Nombre, TipoMaquinariaID, Estado, Marca, Modelo, NumeroSerie,
         FechaAdquisicion, VidaUtilAnios, CostoAdquisicion, CostoHoraOperacion,
         CapacidadMaxima, UnidadCapacidad, UbicacionFisica, Notas)
    VALUES
        ('MAQ-BATIDORA-01', 'Batidora planetaria 20L', @TipoAmasa, 'Activa', 'KitchenAid', 'KSM8990', 'KA-2022-05514',
         '2022-02-14', 8, 4500000, 800,
         20, 'litros', 'Área de repostería', 'Para cremas, merengues, rellenos y masas blandas');

IF NOT EXISTS (SELECT 1 FROM Produccion.Maquinaria WHERE Codigo = 'MAQ-BASCULA-01')
    INSERT INTO Produccion.Maquinaria
        (Codigo, Nombre, TipoMaquinariaID, Estado, Marca, Modelo, NumeroSerie,
         FechaAdquisicion, VidaUtilAnios, CostoAdquisicion, CostoHoraOperacion,
         CapacidadMaxima, UnidadCapacidad, UbicacionFisica, Notas)
    VALUES
        ('MAQ-BASCULA-01', 'Báscula de precisión 30kg', @TipoBasc, 'Activa', 'Ohaus', 'RC30', 'OH-2023-00291',
         '2023-01-20', 10, 1200000, 0,
         30, 'kg', 'Área de pesaje', 'Precisión 1g, para control de recetas');

IF NOT EXISTS (SELECT 1 FROM Produccion.Maquinaria WHERE Codigo = 'MAQ-CAMARA-01')
    INSERT INTO Produccion.Maquinaria
        (Codigo, Nombre, TipoMaquinariaID, Estado, Marca, Modelo, NumeroSerie,
         FechaAdquisicion, VidaUtilAnios, CostoAdquisicion, CostoHoraOperacion,
         CapacidadMaxima, UnidadCapacidad, UbicacionFisica, Notas)
    VALUES
        ('MAQ-CAMARA-01', 'Cámara de refrigeración 1000L', @TipoFrio, 'Activa', 'Coldline', 'MR1000', 'CL-2021-00078',
         '2021-06-01', 15, 22000000, 1800,
         1000, 'litros', 'Bodega de ingredientes', 'Para conservación de lácteos, frutas y cremas');

PRINT '✓ Maquinaria insertada.';

-- ── 8. Máquinas por receta (RecetaMaquinaria) ─────────────────
DECLARE @maqHorno1   INT = (SELECT MaquinariaID FROM Produccion.Maquinaria WHERE Codigo = 'MAQ-HORNO-01');
DECLARE @maqHorno2   INT = (SELECT MaquinariaID FROM Produccion.Maquinaria WHERE Codigo = 'MAQ-HORNO-02');
DECLARE @maqAmasa    INT = (SELECT MaquinariaID FROM Produccion.Maquinaria WHERE Codigo = 'MAQ-AMASADORA-01');
DECLARE @maqBati     INT = (SELECT MaquinariaID FROM Produccion.Maquinaria WHERE Codigo = 'MAQ-BATIDORA-01');

-- Verificar que la tabla RecetaMaquinaria exista antes de insertar
IF EXISTS (SELECT 1 FROM sys.tables WHERE name='RecetaMaquinaria' AND schema_id=SCHEMA_ID('Produccion'))
BEGIN
    -- Pan de molde → Horno + Amasadora
    IF NOT EXISTS (SELECT 1 FROM Produccion.RecetaMaquinaria WHERE RecetaID=@rPan AND MaquinariaID=@maqHorno1)
        INSERT INTO Produccion.RecetaMaquinaria (RecetaID,MaquinariaID,HorasEstimadasPorLote,Notas)
        VALUES (@rPan,@maqHorno1,0.75,'Horneado 35 min a 180°C');
    IF NOT EXISTS (SELECT 1 FROM Produccion.RecetaMaquinaria WHERE RecetaID=@rPan AND MaquinariaID=@maqAmasa)
        INSERT INTO Produccion.RecetaMaquinaria (RecetaID,MaquinariaID,HorasEstimadasPorLote,Notas)
        VALUES (@rPan,@maqAmasa,0.25,'Amasado 15 min velocidad media');

    -- Croissant → Horno + Amasadora
    IF NOT EXISTS (SELECT 1 FROM Produccion.RecetaMaquinaria WHERE RecetaID=@rCroi AND MaquinariaID=@maqHorno1)
        INSERT INTO Produccion.RecetaMaquinaria (RecetaID,MaquinariaID,HorasEstimadasPorLote,Notas)
        VALUES (@rCroi,@maqHorno1,0.42,'Horneado 25 min a 200°C');
    IF NOT EXISTS (SELECT 1 FROM Produccion.RecetaMaquinaria WHERE RecetaID=@rCroi AND MaquinariaID=@maqAmasa)
        INSERT INTO Produccion.RecetaMaquinaria (RecetaID,MaquinariaID,HorasEstimadasPorLote,Notas)
        VALUES (@rCroi,@maqAmasa,0.20,'Amasado de masa hojaldrada');

    -- Muffin → Horno + Batidora
    IF NOT EXISTS (SELECT 1 FROM Produccion.RecetaMaquinaria WHERE RecetaID=@rMuff AND MaquinariaID=@maqHorno2)
        INSERT INTO Produccion.RecetaMaquinaria (RecetaID,MaquinariaID,HorasEstimadasPorLote,Notas)
        VALUES (@rMuff,@maqHorno2,0.30,'Horneado 20 min a 175°C');
    IF NOT EXISTS (SELECT 1 FROM Produccion.RecetaMaquinaria WHERE RecetaID=@rMuff AND MaquinariaID=@maqBati)
        INSERT INTO Produccion.RecetaMaquinaria (RecetaID,MaquinariaID,HorasEstimadasPorLote,Notas)
        VALUES (@rMuff,@maqBati,0.15,'Batido de masa húmeda 10 min');

    -- Torta de fresas → Horno + Batidora
    IF NOT EXISTS (SELECT 1 FROM Produccion.RecetaMaquinaria WHERE RecetaID=@rTort AND MaquinariaID=@maqHorno1)
        INSERT INTO Produccion.RecetaMaquinaria (RecetaID,MaquinariaID,HorasEstimadasPorLote,Notas)
        VALUES (@rTort,@maqHorno1,0.67,'Horneado base 40 min a 170°C');
    IF NOT EXISTS (SELECT 1 FROM Produccion.RecetaMaquinaria WHERE RecetaID=@rTort AND MaquinariaID=@maqBati)
        INSERT INTO Produccion.RecetaMaquinaria (RecetaID,MaquinariaID,HorasEstimadasPorLote,Notas)
        VALUES (@rTort,@maqBati,0.25,'Batido de crema y relleno');

    -- Cheesecake → Horno + Batidora (en baño María)
    IF NOT EXISTS (SELECT 1 FROM Produccion.RecetaMaquinaria WHERE RecetaID=@rChes AND MaquinariaID=@maqHorno2)
        INSERT INTO Produccion.RecetaMaquinaria (RecetaID,MaquinariaID,HorasEstimadasPorLote,Notas)
        VALUES (@rChes,@maqHorno2,1.25,'Horneado en baño María 75 min a 150°C');
    IF NOT EXISTS (SELECT 1 FROM Produccion.RecetaMaquinaria WHERE RecetaID=@rChes AND MaquinariaID=@maqBati)
        INSERT INTO Produccion.RecetaMaquinaria (RecetaID,MaquinariaID,HorasEstimadasPorLote,Notas)
        VALUES (@rChes,@maqBati,0.20,'Mezcla suave del relleno de queso');

    -- Brownie → Horno + Batidora
    IF NOT EXISTS (SELECT 1 FROM Produccion.RecetaMaquinaria WHERE RecetaID=@rBrow AND MaquinariaID=@maqHorno2)
        INSERT INTO Produccion.RecetaMaquinaria (RecetaID,MaquinariaID,HorasEstimadasPorLote,Notas)
        VALUES (@rBrow,@maqHorno2,0.42,'Horneado 25 min a 180°C, centro húmedo');
    IF NOT EXISTS (SELECT 1 FROM Produccion.RecetaMaquinaria WHERE RecetaID=@rBrow AND MaquinariaID=@maqBati)
        INSERT INTO Produccion.RecetaMaquinaria (RecetaID,MaquinariaID,HorasEstimadasPorLote,Notas)
        VALUES (@rBrow,@maqBati,0.10,'Integración de ingredientes');

    PRINT '✓ Maquinaria por receta insertada.';
END
ELSE
    PRINT '! RecetaMaquinaria no existe, ejecuta migration_maquinaria_v2.sql primero.';

-- ── 9. Stock inicial de materias primas con costo ─────────────
MERGE Inventario.InventarioStock AS T
USING (VALUES
    (@mpHarina,    @BodID, CAST(50    AS DECIMAL(18,4)), CAST(2500  AS DECIMAL(18,4))),
    (@mpMant,      @BodID, CAST(10    AS DECIMAL(18,4)), CAST(15000 AS DECIMAL(18,4))),
    (@mpAzucar,    @BodID, CAST(20    AS DECIMAL(18,4)), CAST(3200  AS DECIMAL(18,4))),
    (@mpHuevo,     @BodID, CAST(120   AS DECIMAL(18,4)), CAST(600   AS DECIMAL(18,4))),
    (@mpLeche,     @BodID, CAST(20    AS DECIMAL(18,4)), CAST(3500  AS DECIMAL(18,4))),
    (@mpSal,       @BodID, CAST(5     AS DECIMAL(18,4)), CAST(1500  AS DECIMAL(18,4))),
    (@mpLevadura,  @BodID, CAST(2000  AS DECIMAL(18,4)), CAST(80    AS DECIMAL(18,4))),
    (@mpCacao,     @BodID, CAST(5     AS DECIMAL(18,4)), CAST(18000 AS DECIMAL(18,4))),
    (@mpQcrema,    @BodID, CAST(6     AS DECIMAL(18,4)), CAST(22000 AS DECIMAL(18,4))),
    (@mpFresa,     @BodID, CAST(8     AS DECIMAL(18,4)), CAST(8000  AS DECIMAL(18,4))),
    (@mpCrema,     @BodID, CAST(6     AS DECIMAL(18,4)), CAST(7500  AS DECIMAL(18,4))),
    (@mpChoco,     @BodID, CAST(4     AS DECIMAL(18,4)), CAST(25000 AS DECIMAL(18,4))),
    (@mpCafe,      @BodID, CAST(5000  AS DECIMAL(18,4)), CAST(120   AS DECIMAL(18,4))),
    (@mpVainilla,  @BodID, CAST(500   AS DECIMAL(18,4)), CAST(500   AS DECIMAL(18,4))),
    (@mpPapel,     @BodID, CAST(500   AS DECIMAL(18,4)), CAST(200   AS DECIMAL(18,4)))
) AS S (ArticuloID, BodegaID, Cantidad, CostoUnitario)
ON T.ArticuloID = S.ArticuloID AND T.BodegaID = S.BodegaID AND T.LoteID IS NULL
WHEN MATCHED THEN
    UPDATE SET T.CantidadActual              = T.CantidadActual + S.Cantidad,
               T.CostoUnitarioLote           = S.CostoUnitario,
               T.FechaUltimaActualizacion    = GETDATE()
WHEN NOT MATCHED THEN
    INSERT (ArticuloID, BodegaID, LoteID, CantidadActual, CostoUnitarioLote, FechaUltimaActualizacion)
    VALUES (S.ArticuloID, S.BodegaID, NULL, S.Cantidad, S.CostoUnitario, GETDATE());

-- Actualizar CostoPromedio en el catálogo de artículos
UPDATE Catalogo.Articulos SET CostoPromedio = 2500  WHERE SKU = 'MP-CF-HARINA';
UPDATE Catalogo.Articulos SET CostoPromedio = 15000 WHERE SKU = 'MP-CF-MANTEQUILLA';
UPDATE Catalogo.Articulos SET CostoPromedio = 3200  WHERE SKU = 'MP-CF-AZUCAR';
UPDATE Catalogo.Articulos SET CostoPromedio = 600   WHERE SKU = 'MP-CF-HUEVO';
UPDATE Catalogo.Articulos SET CostoPromedio = 3500  WHERE SKU = 'MP-CF-LECHE';
UPDATE Catalogo.Articulos SET CostoPromedio = 1500  WHERE SKU = 'MP-CF-SAL';
UPDATE Catalogo.Articulos SET CostoPromedio = 80    WHERE SKU = 'MP-CF-LEVADURA';
UPDATE Catalogo.Articulos SET CostoPromedio = 18000 WHERE SKU = 'MP-CF-CACAO';
UPDATE Catalogo.Articulos SET CostoPromedio = 22000 WHERE SKU = 'MP-CF-QCREMA';
UPDATE Catalogo.Articulos SET CostoPromedio = 8000  WHERE SKU = 'MP-CF-FRESA';
UPDATE Catalogo.Articulos SET CostoPromedio = 7500  WHERE SKU = 'MP-CF-CREMA';
UPDATE Catalogo.Articulos SET CostoPromedio = 25000 WHERE SKU = 'MP-CF-CHOCO';
UPDATE Catalogo.Articulos SET CostoPromedio = 120   WHERE SKU = 'MP-CF-CAFE';
UPDATE Catalogo.Articulos SET CostoPromedio = 500   WHERE SKU = 'MP-CF-VAINILLA';
UPDATE Catalogo.Articulos SET CostoPromedio = 200   WHERE SKU = 'MP-CF-PAPEL';

PRINT '✓ Stock inicial con costos insertado.';

-- ── 10. Clientes de prueba (cafetería) ────────────────────────
IF NOT EXISTS (SELECT 1 FROM Crm.Clientes WHERE NIT = '800112233-1')
    INSERT INTO Crm.Clientes (Nombre, NIT, Email, Telefono, Estado)
    VALUES ('Cafetería Central Oficinas', '800112233-1', 'pedidos@centraloficinas.co', '3012345678', 1);

IF NOT EXISTS (SELECT 1 FROM Crm.Clientes WHERE NIT = '900445566-2')
    INSERT INTO Crm.Clientes (Nombre, NIT, Email, Telefono, Estado)
    VALUES ('Hotel Boutique La Palma', '900445566-2', 'alimentos@lapalmahotel.co', '3109876543', 1);

IF NOT EXISTS (SELECT 1 FROM Crm.Clientes WHERE NIT = '52001234-5')
    INSERT INTO Crm.Clientes (Nombre, NIT, Email, Telefono, Estado)
    VALUES ('María Elena Rodríguez', '52001234-5', 'mariaelena@gmail.com', '3154567890', 1);

PRINT '✓ Clientes de prueba insertados.';

PRINT '';
PRINT '=== Seed Cafetería & Pastelería completado ===';
PRINT 'Productos: 6 PT + 15 MP | Recetas: 6 | Maquinaria: 6 | Clientes: 3';
PRINT 'Ejecuta este script de nuevo en cualquier momento (es idempotente).';
GO
