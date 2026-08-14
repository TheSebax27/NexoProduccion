-- ==========================================================================
-- migration_tarjetas_v4.sql
-- Refactor catalogo.Tarjetas: alinea columnas con Visions ERP
-- Todas las operaciones son IDEMPOTENTES (verifican IF EXISTS antes de actuar)
-- NO EJECUTAR mientras haya conexiones activas que usen estas columnas.
-- ==========================================================================

-- ---------------------------------------------------------------------------
-- 1. SKU -> Referencia
-- ---------------------------------------------------------------------------
IF EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('Catalogo.Tarjetas') AND name = 'SKU'
)
BEGIN
    EXEC sp_rename 'Catalogo.Tarjetas.SKU', 'Referencia', 'COLUMN';
    PRINT 'Columna SKU renombrada a Referencia.';
END
ELSE
    PRINT 'SKU ya no existe (o ya fue renombrada). Sin cambio.';

-- ---------------------------------------------------------------------------
-- 2. PrecioVenta -> PPPublico (migrar datos, luego eliminar columna)
-- ---------------------------------------------------------------------------
IF EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('Catalogo.Tarjetas') AND name = 'PrecioVenta'
)
BEGIN
    -- Copiar PrecioVenta a PPPublico solo donde PPPublico sea NULL
    UPDATE Catalogo.Tarjetas
    SET PPPublico = COALESCE(PPPublico, PrecioVenta)
    WHERE PPPublico IS NULL;

    -- Eliminar la columna antigua
    ALTER TABLE Catalogo.Tarjetas DROP COLUMN PrecioVenta;
    PRINT 'PrecioVenta migrado a PPPublico y columna eliminada.';
END
ELSE
    PRINT 'PrecioVenta ya no existe. Sin cambio.';

-- ---------------------------------------------------------------------------
-- 3. UnidadesPorEmbalaje -> Fracciones
-- ---------------------------------------------------------------------------
IF EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('Catalogo.Tarjetas') AND name = 'UnidadesPorEmbalaje'
)
BEGIN
    EXEC sp_rename 'Catalogo.Tarjetas.UnidadesPorEmbalaje', 'Fracciones', 'COLUMN';
    PRINT 'Columna UnidadesPorEmbalaje renombrada a Fracciones.';
END
ELSE
    PRINT 'UnidadesPorEmbalaje ya no existe (o ya fue renombrada). Sin cambio.';

-- ---------------------------------------------------------------------------
-- 4. ModoVentaCaja -> Fracciona  (con conversion de valores)
--    AMBOS => SI  (fracciona, vende suelto y en paquete)
--    CAJA  => NO  (no fracciona, solo paquete completo)
-- ---------------------------------------------------------------------------
IF EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('Catalogo.Tarjetas') AND name = 'ModoVentaCaja'
)
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
    PRINT 'ModoVentaCaja ya no existe (o ya fue renombrada). Sin cambio.';

-- ---------------------------------------------------------------------------
-- 5. Rebuild Inventario.vw_StockConsolidado
--    Corrige el JOIN que apuntaba a Catalogo.Articulos (inexistente) y
--    agrega alias para mantener compatibilidad con codigo C# que lee SKU/
--    UnidadesPorEmbalaje de la vista (InventarioService, BusquedaService).
-- ---------------------------------------------------------------------------
GO

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

PRINT 'Vista Inventario.vw_StockConsolidado reconstruida correctamente.';
