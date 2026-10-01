-- ============================================================
-- SCRIPT 2 DE 2 — ejecutar DESPUES de 01_alter_sp.sql
-- Correccion de datos historicos en las 3 BDs
--
-- IDEMPOTENTE: se puede correr varias veces sin dano.
--
-- PASO 1: corrige KardexMovimientos.Fecha a fecha real de venta
-- PASO 2: recalcula InventarioStock desde cero para articulos
--         con AJU_INV, excluyendo movimientos pre-ajuste
--
-- POR QUE ES SEGURO:
--   PASO 2 hace SET (no ADD), calcula el stock correcto sumando
--   todos los movimientos Kardex menos los que son SALIDA anterior
--   al ultimo AJU_INV. Si se corre 2 veces, el resultado es igual.
-- ============================================================

-- ============================================================
USE nexoVisions;
GO
BEGIN TRANSACTION;

-- PASO 1a: fecha real para SALIDA_VENTA_VISIONS
UPDATE km
SET km.Fecha = ee.FechaEventoOrigen
FROM Kardex.KardexMovimientos km
JOIN Kardex.TiposMovimientoKardex tm ON tm.TipoMovID = km.TipoMovID AND tm.Codigo = 'SALIDA_VENTA_VISIONS'
JOIN Integracion.EventosEntrantes ee
    ON km.ObservacionDetallada = CONCAT('Venta Visions - Evento #', ee.EventoEntranteID)
WHERE km.Fecha <> ee.FechaEventoOrigen;
PRINT CONCAT('nexoVisions - SALIDA_VENTA_VISIONS fechas corregidas: ', @@ROWCOUNT);

-- PASO 1b: fecha real para SALIDA_WIP
UPDATE km
SET km.Fecha = ee.FechaEventoOrigen
FROM Kardex.KardexMovimientos km
JOIN Kardex.TiposMovimientoKardex tm ON tm.TipoMovID = km.TipoMovID AND tm.Codigo = 'SALIDA_WIP'
JOIN Integracion.EventosEntrantes ee
    ON ee.EventoEntranteID = TRY_CAST(
        SUBSTRING(km.ObservacionDetallada,
                  CHARINDEX('Evento #', km.ObservacionDetallada) + 8,
                  LEN(km.ObservacionDetallada)) AS BIGINT)
WHERE km.ObservacionDetallada LIKE '%Venta Visions Evento #%'
  AND km.Fecha <> ee.FechaEventoOrigen;
PRINT CONCAT('nexoVisions - SALIDA_WIP fechas corregidas: ', @@ROWCOUNT);

-- PASO 2: recalcular stock (idempotente - SET no ADD)
-- Solo afecta articulos que tienen al menos un AJU_INV
;WITH UltimoAjuste AS (
    SELECT k.ArticuloID, k.BodegaID, MAX(k.Fecha) AS FechaAjuste
    FROM Kardex.KardexMovimientos k
    JOIN Kardex.TiposMovimientoKardex tm ON tm.TipoMovID = k.TipoMovID AND tm.Codigo = 'AJU_INV'
    GROUP BY k.ArticuloID, k.BodegaID
),
StockCorrecto AS (
    SELECT km.ArticuloID, km.BodegaID, SUM(km.Cantidad) AS StockCalculado
    FROM Kardex.KardexMovimientos km
    LEFT JOIN UltimoAjuste ua ON ua.ArticuloID = km.ArticuloID AND ua.BodegaID = km.BodegaID
    JOIN Kardex.TiposMovimientoKardex tmk ON tmk.TipoMovID = km.TipoMovID
    WHERE NOT (
        tmk.Codigo IN ('SALIDA_VENTA_VISIONS', 'SALIDA_WIP')
        AND ua.FechaAjuste IS NOT NULL
        AND km.Fecha < ua.FechaAjuste
    )
    GROUP BY km.ArticuloID, km.BodegaID
)
UPDATE inv
SET inv.CantidadActual = sc.StockCalculado,
    inv.FechaUltimaActualizacion = SYSUTCDATETIME()
FROM Inventario.InventarioStock inv
JOIN UltimoAjuste ua ON ua.ArticuloID = inv.ArticuloID AND ua.BodegaID = inv.BodegaID AND inv.LoteID IS NULL
JOIN StockCorrecto sc ON sc.ArticuloID = inv.ArticuloID AND sc.BodegaID = inv.BodegaID;
PRINT CONCAT('nexoVisions - articulos con stock recalculado: ', @@ROWCOUNT);

COMMIT TRANSACTION;
PRINT 'nexoVisions: OK';
GO

-- ============================================================
USE hokma;
GO
BEGIN TRANSACTION;

UPDATE km
SET km.Fecha = ee.FechaEventoOrigen
FROM Kardex.KardexMovimientos km
JOIN Kardex.TiposMovimientoKardex tm ON tm.TipoMovID = km.TipoMovID AND tm.Codigo = 'SALIDA_VENTA_VISIONS'
JOIN Integracion.EventosEntrantes ee
    ON km.ObservacionDetallada = CONCAT('Venta Visions - Evento #', ee.EventoEntranteID)
WHERE km.Fecha <> ee.FechaEventoOrigen;
PRINT CONCAT('hokma - SALIDA_VENTA_VISIONS fechas corregidas: ', @@ROWCOUNT);

UPDATE km
SET km.Fecha = ee.FechaEventoOrigen
FROM Kardex.KardexMovimientos km
JOIN Kardex.TiposMovimientoKardex tm ON tm.TipoMovID = km.TipoMovID AND tm.Codigo = 'SALIDA_WIP'
JOIN Integracion.EventosEntrantes ee
    ON ee.EventoEntranteID = TRY_CAST(
        SUBSTRING(km.ObservacionDetallada,
                  CHARINDEX('Evento #', km.ObservacionDetallada) + 8,
                  LEN(km.ObservacionDetallada)) AS BIGINT)
WHERE km.ObservacionDetallada LIKE '%Venta Visions Evento #%'
  AND km.Fecha <> ee.FechaEventoOrigen;
PRINT CONCAT('hokma - SALIDA_WIP fechas corregidas: ', @@ROWCOUNT);

;WITH UltimoAjuste AS (
    SELECT k.ArticuloID, k.BodegaID, MAX(k.Fecha) AS FechaAjuste
    FROM Kardex.KardexMovimientos k
    JOIN Kardex.TiposMovimientoKardex tm ON tm.TipoMovID = k.TipoMovID AND tm.Codigo = 'AJU_INV'
    GROUP BY k.ArticuloID, k.BodegaID
),
StockCorrecto AS (
    SELECT km.ArticuloID, km.BodegaID, SUM(km.Cantidad) AS StockCalculado
    FROM Kardex.KardexMovimientos km
    LEFT JOIN UltimoAjuste ua ON ua.ArticuloID = km.ArticuloID AND ua.BodegaID = km.BodegaID
    JOIN Kardex.TiposMovimientoKardex tmk ON tmk.TipoMovID = km.TipoMovID
    WHERE NOT (
        tmk.Codigo IN ('SALIDA_VENTA_VISIONS', 'SALIDA_WIP')
        AND ua.FechaAjuste IS NOT NULL
        AND km.Fecha < ua.FechaAjuste
    )
    GROUP BY km.ArticuloID, km.BodegaID
)
UPDATE inv
SET inv.CantidadActual = sc.StockCalculado,
    inv.FechaUltimaActualizacion = SYSUTCDATETIME()
FROM Inventario.InventarioStock inv
JOIN UltimoAjuste ua ON ua.ArticuloID = inv.ArticuloID AND ua.BodegaID = inv.BodegaID AND inv.LoteID IS NULL
JOIN StockCorrecto sc ON sc.ArticuloID = inv.ArticuloID AND sc.BodegaID = inv.BodegaID;
PRINT CONCAT('hokma - articulos con stock recalculado: ', @@ROWCOUNT);

COMMIT TRANSACTION;
PRINT 'hokma: OK';
GO

-- ============================================================
USE vecco;
GO
BEGIN TRANSACTION;

UPDATE km
SET km.Fecha = ee.FechaEventoOrigen
FROM Kardex.KardexMovimientos km
JOIN Kardex.TiposMovimientoKardex tm ON tm.TipoMovID = km.TipoMovID AND tm.Codigo = 'SALIDA_VENTA_VISIONS'
JOIN Integracion.EventosEntrantes ee
    ON km.ObservacionDetallada = CONCAT('Venta Visions - Evento #', ee.EventoEntranteID)
WHERE km.Fecha <> ee.FechaEventoOrigen;
PRINT CONCAT('vecco - SALIDA_VENTA_VISIONS fechas corregidas: ', @@ROWCOUNT);

UPDATE km
SET km.Fecha = ee.FechaEventoOrigen
FROM Kardex.KardexMovimientos km
JOIN Kardex.TiposMovimientoKardex tm ON tm.TipoMovID = km.TipoMovID AND tm.Codigo = 'SALIDA_WIP'
JOIN Integracion.EventosEntrantes ee
    ON ee.EventoEntranteID = TRY_CAST(
        SUBSTRING(km.ObservacionDetallada,
                  CHARINDEX('Evento #', km.ObservacionDetallada) + 8,
                  LEN(km.ObservacionDetallada)) AS BIGINT)
WHERE km.ObservacionDetallada LIKE '%Venta Visions Evento #%'
  AND km.Fecha <> ee.FechaEventoOrigen;
PRINT CONCAT('vecco - SALIDA_WIP fechas corregidas: ', @@ROWCOUNT);

;WITH UltimoAjuste AS (
    SELECT k.ArticuloID, k.BodegaID, MAX(k.Fecha) AS FechaAjuste
    FROM Kardex.KardexMovimientos k
    JOIN Kardex.TiposMovimientoKardex tm ON tm.TipoMovID = k.TipoMovID AND tm.Codigo = 'AJU_INV'
    GROUP BY k.ArticuloID, k.BodegaID
),
StockCorrecto AS (
    SELECT km.ArticuloID, km.BodegaID, SUM(km.Cantidad) AS StockCalculado
    FROM Kardex.KardexMovimientos km
    LEFT JOIN UltimoAjuste ua ON ua.ArticuloID = km.ArticuloID AND ua.BodegaID = km.BodegaID
    JOIN Kardex.TiposMovimientoKardex tmk ON tmk.TipoMovID = km.TipoMovID
    WHERE NOT (
        tmk.Codigo IN ('SALIDA_VENTA_VISIONS', 'SALIDA_WIP')
        AND ua.FechaAjuste IS NOT NULL
        AND km.Fecha < ua.FechaAjuste
    )
    GROUP BY km.ArticuloID, km.BodegaID
)
UPDATE inv
SET inv.CantidadActual = sc.StockCalculado,
    inv.FechaUltimaActualizacion = SYSUTCDATETIME()
FROM Inventario.InventarioStock inv
JOIN UltimoAjuste ua ON ua.ArticuloID = inv.ArticuloID AND ua.BodegaID = inv.BodegaID AND inv.LoteID IS NULL
JOIN StockCorrecto sc ON sc.ArticuloID = inv.ArticuloID AND sc.BodegaID = inv.BodegaID;
PRINT CONCAT('vecco - articulos con stock recalculado: ', @@ROWCOUNT);

COMMIT TRANSACTION;
PRINT 'vecco: OK';
GO
