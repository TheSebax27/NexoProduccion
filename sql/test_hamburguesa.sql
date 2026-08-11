-- ============================================================
-- Datos de prueba: Hamburguesa Doble Carne
-- sqlcmd -S DESKTOP-V83PQ7M\JONATHAN -d NEXO_ERP -i C:\Produccion\sql\test_hamburguesa.sql
-- ============================================================
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;

-- ── 1. Unidades de medida (ya existen: Unidad=6, Gramo=3) ─
DECLARE @UndID INT = (SELECT TOP 1 UnidadID FROM catalogo.UnidadesMedida WHERE Abreviatura = 'und');
DECLARE @GrID  INT = (SELECT TOP 1 UnidadID FROM catalogo.UnidadesMedida WHERE Abreviatura = 'g');

IF @UndID IS NULL OR @GrID IS NULL
BEGIN
    RAISERROR('No se encontraron las unidades "und" o "g". Verifica catalogo.UnidadesMedida.', 16, 1);
    RETURN;
END

-- ── 2. Centro de costo y bodega ───────────────────────────
DECLARE @CcID  INT = (SELECT TOP 1 CentroCostoID FROM Organizacion.CentrosCosto WHERE Estado = 1);
DECLARE @BodID INT = (SELECT TOP 1 BodegaID FROM Inventario.Bodegas WHERE Estado = 1);

PRINT 'UnidadID und=' + CAST(@UndID AS VARCHAR) + '  g=' + CAST(@GrID AS VARCHAR);
PRINT 'CentroCostoID=' + CAST(@CcID AS VARCHAR) + '  BodegaID=' + CAST(@BodID AS VARCHAR);

-- ── 3. Artículos Materias Primas (TipoArticuloID=1 MP) ───
IF NOT EXISTS (SELECT 1 FROM catalogo.Articulos WHERE SKU = 'MP-PAN-001')
    INSERT INTO catalogo.Articulos (SKU, Nombre, TipoArticuloID, UnidadID, Estado)
    VALUES ('MP-PAN-001', 'Pan hamburguesa', 1, @UndID, 1);

IF NOT EXISTS (SELECT 1 FROM catalogo.Articulos WHERE SKU = 'MP-CARNE-001')
    INSERT INTO catalogo.Articulos (SKU, Nombre, TipoArticuloID, UnidadID, Estado)
    VALUES ('MP-CARNE-001', 'Carne molida (200g)', 1, @UndID, 1);

IF NOT EXISTS (SELECT 1 FROM catalogo.Articulos WHERE SKU = 'MP-QUESO-001')
    INSERT INTO catalogo.Articulos (SKU, Nombre, TipoArticuloID, UnidadID, Estado)
    VALUES ('MP-QUESO-001', 'Queso cheddar (loncha)', 1, @UndID, 1);

IF NOT EXISTS (SELECT 1 FROM catalogo.Articulos WHERE SKU = 'MP-LECH-001')
    INSERT INTO catalogo.Articulos (SKU, Nombre, TipoArticuloID, UnidadID, Estado)
    VALUES ('MP-LECH-001', 'Lechuga (porción)', 1, @UndID, 1);

IF NOT EXISTS (SELECT 1 FROM catalogo.Articulos WHERE SKU = 'MP-TOM-001')
    INSERT INTO catalogo.Articulos (SKU, Nombre, TipoArticuloID, UnidadID, Estado)
    VALUES ('MP-TOM-001', 'Tomate (rodaja)', 1, @UndID, 1);

IF NOT EXISTS (SELECT 1 FROM catalogo.Articulos WHERE SKU = 'MP-SALSA-001')
    INSERT INTO catalogo.Articulos (SKU, Nombre, TipoArticuloID, UnidadID, Estado)
    VALUES ('MP-SALSA-001', 'Salsa especial', 1, @GrID, 1);

-- ── 4. Artículo Producto Terminado (TipoArticuloID=2 PT) ──
IF NOT EXISTS (SELECT 1 FROM catalogo.Articulos WHERE SKU = 'PT-HAMB-DC-001')
    INSERT INTO catalogo.Articulos (SKU, Nombre, TipoArticuloID, UnidadID, PrecioVenta, Estado)
    VALUES ('PT-HAMB-DC-001', 'Hamburguesa Doble Carne', 2, @UndID, 25000, 1);

DECLARE @ArtPan   INT = (SELECT TOP 1 ArticuloID FROM catalogo.Articulos WHERE SKU = 'MP-PAN-001');
DECLARE @ArtCarne INT = (SELECT TOP 1 ArticuloID FROM catalogo.Articulos WHERE SKU = 'MP-CARNE-001');
DECLARE @ArtQueso INT = (SELECT TOP 1 ArticuloID FROM catalogo.Articulos WHERE SKU = 'MP-QUESO-001');
DECLARE @ArtLech  INT = (SELECT TOP 1 ArticuloID FROM catalogo.Articulos WHERE SKU = 'MP-LECH-001');
DECLARE @ArtTom   INT = (SELECT TOP 1 ArticuloID FROM catalogo.Articulos WHERE SKU = 'MP-TOM-001');
DECLARE @ArtSalsa INT = (SELECT TOP 1 ArticuloID FROM catalogo.Articulos WHERE SKU = 'MP-SALSA-001');
DECLARE @ArtHamb  INT = (SELECT TOP 1 ArticuloID FROM catalogo.Articulos WHERE SKU = 'PT-HAMB-DC-001');

-- ── 5. Receta BOM ──────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM Produccion.RecetaBOM WHERE ProductoTerminadoID = @ArtHamb)
    INSERT INTO Produccion.RecetaBOM
        (ProductoTerminadoID, NombreReceta, Version, CantidadRendimientoBase, UnidadRendimientoID, Estado)
    VALUES
        (@ArtHamb, 'Hamburguesa Doble Carne', 1, 1, @UndID, 1);

DECLARE @RecetaID INT = (SELECT TOP 1 RecetaID FROM Produccion.RecetaBOM WHERE ProductoTerminadoID = @ArtHamb);

-- ── 6. Detalle BOM ─────────────────────────────────────────
DELETE FROM Produccion.RecetaBOM_Detalle WHERE RecetaID = @RecetaID;

INSERT INTO Produccion.RecetaBOM_Detalle
    (RecetaID, InsumoID, CantidadRequerida, UnidadID, PorcentajeMermaEstandar, Orden)
VALUES
    (@RecetaID, @ArtPan,   1,  @UndID, 0,  1),
    (@RecetaID, @ArtCarne, 2,  @UndID, 5,  2),
    (@RecetaID, @ArtQueso, 2,  @UndID, 0,  3),
    (@RecetaID, @ArtLech,  1,  @UndID, 10, 4),
    (@RecetaID, @ArtTom,   1,  @UndID, 10, 5),
    (@RecetaID, @ArtSalsa, 30, @GrID,  0,  6);

-- ── 7. Stock inicial de materias primas ────────────────────
MERGE Inventario.InventarioStock AS T
USING (VALUES
    (@ArtPan,   @BodID, CAST(50   AS DECIMAL(18,4))),
    (@ArtCarne, @BodID, CAST(100  AS DECIMAL(18,4))),
    (@ArtQueso, @BodID, CAST(80   AS DECIMAL(18,4))),
    (@ArtLech,  @BodID, CAST(60   AS DECIMAL(18,4))),
    (@ArtTom,   @BodID, CAST(60   AS DECIMAL(18,4))),
    (@ArtSalsa, @BodID, CAST(2000 AS DECIMAL(18,4)))
) AS S (ArticuloID, BodegaID, Cantidad)
ON T.ArticuloID = S.ArticuloID AND T.BodegaID = S.BodegaID AND T.LoteID IS NULL
WHEN MATCHED THEN
    UPDATE SET T.CantidadActual = T.CantidadActual + S.Cantidad,
               T.FechaUltimaActualizacion = GETDATE()
WHEN NOT MATCHED THEN
    INSERT (ArticuloID, BodegaID, LoteID, CantidadActual, CostoUnitarioLote, FechaUltimaActualizacion)
    VALUES (S.ArticuloID, S.BodegaID, NULL, S.Cantidad, 0, GETDATE());

-- ── 8. Cliente de prueba ───────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM Crm.Clientes WHERE NIT = '9999999999')
    INSERT INTO Crm.Clientes (Nombre, NIT, Estado)
    VALUES ('Cliente Prueba Hamburguesa', '9999999999', 1);

PRINT '';
PRINT '=== Datos de prueba insertados OK ===';
PRINT 'ArticuloID Hamburguesa Doble Carne: ' + CAST(@ArtHamb  AS VARCHAR);
PRINT 'RecetaID                          : ' + CAST(@RecetaID AS VARCHAR);
PRINT 'BodegaID stock                    : ' + CAST(@BodID    AS VARCHAR);
GO
