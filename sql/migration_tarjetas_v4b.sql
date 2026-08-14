-- ==========================================================================
-- migration_tarjetas_v4b.sql
-- Correccion de migration_tarjetas_v4.sql
-- Pendiente: DROP PrecioVenta, rename UnidadesPorEmbalaje->Fracciones,
--            rename ModoVentaCaja->Fracciona, rebuild vw_StockConsolidado
-- ==========================================================================

-- ---------------------------------------------------------------------------
-- 1. Eliminar DEFAULT constraint de PrecioVenta, luego DROP la columna
-- ---------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = 'DF__Articulos__Preci__1DB06A4F')
BEGIN
    ALTER TABLE Catalogo.Tarjetas DROP CONSTRAINT DF__Articulos__Preci__1DB06A4F;
    PRINT 'Constraint DF__Articulos__Preci__1DB06A4F eliminado.';
END

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Catalogo.Tarjetas') AND name = 'PrecioVenta')
BEGIN
    -- Por seguridad: copiar a PPPublico donde sea null (idempotente)
    UPDATE Catalogo.Tarjetas SET PPPublico = COALESCE(PPPublico, PrecioVenta) WHERE PPPublico IS NULL;
    ALTER TABLE Catalogo.Tarjetas DROP COLUMN PrecioVenta;
    PRINT 'PrecioVenta eliminado. Datos migrados a PPPublico.';
END
ELSE
    PRINT 'PrecioVenta ya no existe.';

-- ---------------------------------------------------------------------------
-- 2. Eliminar DEFAULT constraint de ModoVentaCaja (si existe) antes de rename
-- ---------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = 'DF__Articulos__ModoV__68F2894D')
BEGIN
    ALTER TABLE Catalogo.Tarjetas DROP CONSTRAINT DF__Articulos__ModoV__68F2894D;
    PRINT 'Constraint DF__Articulos__ModoV__68F2894D eliminado.';
END

-- ---------------------------------------------------------------------------
-- 3. UnidadesPorEmbalaje -> Fracciones
-- ---------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Catalogo.Tarjetas') AND name = 'UnidadesPorEmbalaje')
BEGIN
    EXEC sp_rename 'Catalogo.Tarjetas.UnidadesPorEmbalaje', 'Fracciones', 'COLUMN';
    PRINT 'UnidadesPorEmbalaje renombrado a Fracciones.';
END
ELSE
    PRINT 'UnidadesPorEmbalaje ya no existe.';

-- ---------------------------------------------------------------------------
-- 4. ModoVentaCaja -> Fracciona (convertir valores AMBOS->SI, CAJA->NO)
-- ---------------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Catalogo.Tarjetas') AND name = 'ModoVentaCaja')
BEGIN
    UPDATE Catalogo.Tarjetas
    SET ModoVentaCaja = CASE ModoVentaCaja
        WHEN 'AMBOS' THEN 'SI'
        WHEN 'CAJA'  THEN 'NO'
        ELSE ModoVentaCaja
    END
    WHERE ModoVentaCaja IN ('AMBOS', 'CAJA');

    EXEC sp_rename 'Catalogo.Tarjetas.ModoVentaCaja', 'Fracciona', 'COLUMN';
    PRINT 'ModoVentaCaja convertido (AMBOS->SI, CAJA->NO) y renombrado a Fracciona.';
END
ELSE
    PRINT 'ModoVentaCaja ya no existe.';
GO

-- ---------------------------------------------------------------------------
-- 5. Rebuild vw_StockConsolidado (fue dropeada por v4, recrear correctamente)
-- ---------------------------------------------------------------------------
IF OBJECT_ID('Inventario.vw_StockConsolidado', 'V') IS NOT NULL
    DROP VIEW Inventario.vw_StockConsolidado;
GO

CREATE VIEW Inventario.vw_StockConsolidado AS
SELECT
    a.ArticuloID,
    a.Referencia          AS SKU,
    a.Nombre              AS Articulo,
    ta.Nombre             AS TipoArticulo,
    u.Abreviatura         AS Unidad,
    a.Fracciones          AS UnidadesPorEmbalaje,
    b.BodegaID,
    b.Nombre              AS Bodega,
    cc.CentroCostoID,
    cc.Nombre             AS CentroCosto,
    l.LoteID,
    l.NumeroLote,
    l.FechaVencimiento,
    s.CantidadActual,
    s.CostoUnitarioLote,
    (s.CantidadActual * s.CostoUnitarioLote) AS ValorTotal,
    CASE
        WHEN s.CantidadActual <= a.PuntoReorden THEN CAST(1 AS BIT)
        ELSE CAST(0 AS BIT)
    END AS RequierePedido
FROM Inventario.InventarioStock s
JOIN Catalogo.Tarjetas         a   ON a.ArticuloID      = s.ArticuloID
JOIN Catalogo.TiposArticulo    ta  ON ta.TipoArticuloID = a.TipoArticuloID
JOIN Inventario.Bodegas        b   ON b.BodegaID        = s.BodegaID
JOIN Organizacion.CentrosCosto cc  ON cc.CentroCostoID  = b.CentroCostoID
LEFT JOIN Inventario.Lotes     l   ON l.LoteID          = s.LoteID
LEFT JOIN Catalogo.UnidadesMedida u ON u.UnidadID       = a.UnidadID;
GO

PRINT 'vw_StockConsolidado creada correctamente.';
