-- ============================================================
-- SCRIPT 3 DE 3 — ejecutar DESPUES de 01_alter_sp.sql y 02_fix_data.sql
-- Insercion de ENTRADA_PT historicos para articulos BOM + recalculo stock PT
--
-- PROBLEMA: ventas Visions de articulos BOM ya registradas en Kardex como
-- SALIDA_VENTA_VISIONS (-Q) no tienen ENTRADA_PT correspondiente (+Q).
-- Resultado: PT siempre en negativo aunque el fisico es correcto.
--
-- SOLUCION:
--   PASO 1: Por cada SALIDA_VENTA_VISIONS de articulo BOM sin ENTRADA_PT par:
--           - Si el articulo tiene AJU_INV: insertar solo si Fecha >= FechaUltimoAJU_INV
--           - Si el articulo NO tiene AJU_INV: insertar para todo su historial
--   PASO 2: Recalcular InventarioStock para todos los PT (BOM), usando la misma
--           logica de exclusion de pre-AJU_INV que 02_fix_data.sql.
--
-- IDEMPOTENTE: verifica ObservacionDetallada antes de insertar.
--              PASO 2 hace SET (no ADD), se puede correr N veces.
--
-- Patrones de ObservacionDetallada usados:
--   SALIDA_VENTA_VISIONS  : 'Venta Visions - Evento #<EventoEntranteID>'
--   ENTRADA_PT            : 'Produccion implicita - Venta Visions Evento #<EventoEntranteID>'
-- ============================================================

-- ============================================================
USE nexoVisions;
GO
BEGIN TRANSACTION;

DECLARE @TipoEntradaPT_nv  INT = (SELECT TipoMovID FROM Kardex.TiposMovimientoKardex WHERE Codigo = 'ENTRADA_PT');
DECLARE @UsuarioSistema_nv INT = (SELECT UsuarioID FROM Seguridad.Usuarios WHERE Username = 'sistema.sync');

IF @TipoEntradaPT_nv IS NULL
    THROW 59001, 'ENTRADA_PT no encontrado en TiposMovimientoKardex', 1;
IF @UsuarioSistema_nv IS NULL
    THROW 59002, 'Usuario sistema.sync no encontrado', 1;

-- PASO 1: Insertar ENTRADA_PT faltantes para ventas BOM
;WITH VentasBOM AS (
    SELECT
        sv.Fecha,
        sv.ArticuloID,
        sv.BodegaID,
        sv.CentroCostoID,
        ABS(sv.Cantidad)            AS Cantidad,
        ABS(sv.CostoUnitario)       AS CostoUnitario,
        ABS(sv.CostoPromedioSaldo)  AS CostoPromedioSaldo,
        TRY_CAST(
            SUBSTRING(sv.ObservacionDetallada,
                      CHARINDEX('Evento #', sv.ObservacionDetallada) + 8,
                      LEN(sv.ObservacionDetallada))
            AS BIGINT) AS EventoEntranteID
    FROM Kardex.KardexMovimientos sv
    JOIN Kardex.TiposMovimientoKardex tm ON tm.TipoMovID = sv.TipoMovID AND tm.Codigo = 'SALIDA_VENTA_VISIONS'
    -- Solo articulos que son producto terminado con receta activa
    WHERE sv.ObservacionDetallada LIKE 'Venta Visions - Evento #%'
      AND sv.ArticuloID IN (
          SELECT DISTINCT ProductoTerminadoID FROM Produccion.RecetaBOM WHERE Estado = 1
      )
)
INSERT INTO Kardex.KardexMovimientos
    (Fecha, ArticuloID, BodegaID, LoteID, TipoMovID, CentroCostoID,
     Cantidad, CostoUnitario, CantidadSaldo, CostoPromedioSaldo,
     ObservacionDetallada, UsuarioID)
SELECT
    vb.Fecha,
    vb.ArticuloID,
    vb.BodegaID,
    NULL,
    @TipoEntradaPT_nv,
    vb.CentroCostoID,
    vb.Cantidad,
    vb.CostoUnitario,
    0,       -- saldo historico no calculable en batch; campo de display
    vb.CostoPromedioSaldo,
    CONCAT('Produccion implicita - Venta Visions Evento #', vb.EventoEntranteID),
    @UsuarioSistema_nv
FROM VentasBOM vb
WHERE vb.EventoEntranteID IS NOT NULL
-- Idempotencia: no insertar si ENTRADA_PT ya existe para este evento
AND NOT EXISTS (
    SELECT 1 FROM Kardex.KardexMovimientos ep
    JOIN Kardex.TiposMovimientoKardex tep ON tep.TipoMovID = ep.TipoMovID AND tep.Codigo = 'ENTRADA_PT'
    WHERE ep.ArticuloID          = vb.ArticuloID
      AND ep.BodegaID            = vb.BodegaID
      AND ep.ObservacionDetallada = CONCAT('Produccion implicita - Venta Visions Evento #', vb.EventoEntranteID)
)
-- Filtro de fecha: post-AJU_INV para articulos con ajuste, o todos si no hay ajuste
AND (
    -- Caso A: articulo sin ningun AJU_INV -> incluir todo su historial
    NOT EXISTS (
        SELECT 1 FROM Kardex.KardexMovimientos k2
        JOIN Kardex.TiposMovimientoKardex tm2 ON tm2.TipoMovID = k2.TipoMovID AND tm2.Codigo = 'AJU_INV'
        WHERE k2.ArticuloID = vb.ArticuloID AND k2.BodegaID = vb.BodegaID
    )
    OR
    -- Caso B: articulo con AJU_INV -> solo ventas posteriores al ultimo ajuste
    vb.Fecha >= (
        SELECT MAX(k3.Fecha)
        FROM Kardex.KardexMovimientos k3
        JOIN Kardex.TiposMovimientoKardex tm3 ON tm3.TipoMovID = k3.TipoMovID AND tm3.Codigo = 'AJU_INV'
        WHERE k3.ArticuloID = vb.ArticuloID AND k3.BodegaID = vb.BodegaID
    )
);
PRINT CONCAT('nexoVisions - PASO 1 ENTRADA_PT insertados: ', @@ROWCOUNT);

-- PASO 2: Recalcular InventarioStock para articulos PT (BOM)
-- Misma logica que 02_fix_data.sql: excluir SALIDA_VENTA_VISIONS y SALIDA_WIP pre-AJU_INV.
-- Para articulos sin AJU_INV: ua.FechaAjuste = NULL -> condicion NOT() = false -> se incluyen.
;WITH UltimoAjuste AS (
    SELECT k.ArticuloID, k.BodegaID, MAX(k.Fecha) AS FechaAjuste
    FROM Kardex.KardexMovimientos k
    JOIN Kardex.TiposMovimientoKardex tm ON tm.TipoMovID = k.TipoMovID AND tm.Codigo = 'AJU_INV'
    WHERE k.ArticuloID IN (SELECT DISTINCT ProductoTerminadoID FROM Produccion.RecetaBOM WHERE Estado = 1)
    GROUP BY k.ArticuloID, k.BodegaID
),
StockCorrecto AS (
    SELECT km.ArticuloID, km.BodegaID, SUM(km.Cantidad) AS StockCalculado
    FROM Kardex.KardexMovimientos km
    LEFT JOIN UltimoAjuste ua ON ua.ArticuloID = km.ArticuloID AND ua.BodegaID = km.BodegaID
    JOIN Kardex.TiposMovimientoKardex tmk ON tmk.TipoMovID = km.TipoMovID
    WHERE km.ArticuloID IN (SELECT DISTINCT ProductoTerminadoID FROM Produccion.RecetaBOM WHERE Estado = 1)
    AND NOT (
        tmk.Codigo IN ('SALIDA_VENTA_VISIONS', 'SALIDA_WIP')
        AND ua.FechaAjuste IS NOT NULL
        AND km.Fecha < ua.FechaAjuste
    )
    GROUP BY km.ArticuloID, km.BodegaID
)
UPDATE inv
SET inv.CantidadActual          = sc.StockCalculado,
    inv.FechaUltimaActualizacion = SYSUTCDATETIME()
FROM Inventario.InventarioStock inv
JOIN StockCorrecto sc ON sc.ArticuloID = inv.ArticuloID AND sc.BodegaID = inv.BodegaID AND inv.LoteID IS NULL;
PRINT CONCAT('nexoVisions - PASO 2 PT stock recalculado: ', @@ROWCOUNT);

COMMIT TRANSACTION;
PRINT 'nexoVisions: OK';
GO

-- ============================================================
USE hokma;
GO
BEGIN TRANSACTION;

DECLARE @TipoEntradaPT_hk  INT = (SELECT TipoMovID FROM Kardex.TiposMovimientoKardex WHERE Codigo = 'ENTRADA_PT');
DECLARE @UsuarioSistema_hk INT = (SELECT UsuarioID FROM Seguridad.Usuarios WHERE Username = 'sistema.sync');

IF @TipoEntradaPT_hk IS NULL
    THROW 59001, 'ENTRADA_PT no encontrado en TiposMovimientoKardex', 1;
IF @UsuarioSistema_hk IS NULL
    THROW 59002, 'Usuario sistema.sync no encontrado', 1;

;WITH VentasBOM AS (
    SELECT
        sv.Fecha,
        sv.ArticuloID,
        sv.BodegaID,
        sv.CentroCostoID,
        ABS(sv.Cantidad)            AS Cantidad,
        ABS(sv.CostoUnitario)       AS CostoUnitario,
        ABS(sv.CostoPromedioSaldo)  AS CostoPromedioSaldo,
        TRY_CAST(
            SUBSTRING(sv.ObservacionDetallada,
                      CHARINDEX('Evento #', sv.ObservacionDetallada) + 8,
                      LEN(sv.ObservacionDetallada))
            AS BIGINT) AS EventoEntranteID
    FROM Kardex.KardexMovimientos sv
    JOIN Kardex.TiposMovimientoKardex tm ON tm.TipoMovID = sv.TipoMovID AND tm.Codigo = 'SALIDA_VENTA_VISIONS'
    WHERE sv.ObservacionDetallada LIKE 'Venta Visions - Evento #%'
      AND sv.ArticuloID IN (
          SELECT DISTINCT ProductoTerminadoID FROM Produccion.RecetaBOM WHERE Estado = 1
      )
)
INSERT INTO Kardex.KardexMovimientos
    (Fecha, ArticuloID, BodegaID, LoteID, TipoMovID, CentroCostoID,
     Cantidad, CostoUnitario, CantidadSaldo, CostoPromedioSaldo,
     ObservacionDetallada, UsuarioID)
SELECT
    vb.Fecha, vb.ArticuloID, vb.BodegaID, NULL,
    @TipoEntradaPT_hk, vb.CentroCostoID,
    vb.Cantidad, vb.CostoUnitario, 0, vb.CostoPromedioSaldo,
    CONCAT('Produccion implicita - Venta Visions Evento #', vb.EventoEntranteID),
    @UsuarioSistema_hk
FROM VentasBOM vb
WHERE vb.EventoEntranteID IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM Kardex.KardexMovimientos ep
    JOIN Kardex.TiposMovimientoKardex tep ON tep.TipoMovID = ep.TipoMovID AND tep.Codigo = 'ENTRADA_PT'
    WHERE ep.ArticuloID          = vb.ArticuloID
      AND ep.BodegaID            = vb.BodegaID
      AND ep.ObservacionDetallada = CONCAT('Produccion implicita - Venta Visions Evento #', vb.EventoEntranteID)
)
AND (
    NOT EXISTS (
        SELECT 1 FROM Kardex.KardexMovimientos k2
        JOIN Kardex.TiposMovimientoKardex tm2 ON tm2.TipoMovID = k2.TipoMovID AND tm2.Codigo = 'AJU_INV'
        WHERE k2.ArticuloID = vb.ArticuloID AND k2.BodegaID = vb.BodegaID
    )
    OR
    vb.Fecha >= (
        SELECT MAX(k3.Fecha)
        FROM Kardex.KardexMovimientos k3
        JOIN Kardex.TiposMovimientoKardex tm3 ON tm3.TipoMovID = k3.TipoMovID AND tm3.Codigo = 'AJU_INV'
        WHERE k3.ArticuloID = vb.ArticuloID AND k3.BodegaID = vb.BodegaID
    )
);
PRINT CONCAT('hokma - PASO 1 ENTRADA_PT insertados: ', @@ROWCOUNT);

;WITH UltimoAjuste AS (
    SELECT k.ArticuloID, k.BodegaID, MAX(k.Fecha) AS FechaAjuste
    FROM Kardex.KardexMovimientos k
    JOIN Kardex.TiposMovimientoKardex tm ON tm.TipoMovID = k.TipoMovID AND tm.Codigo = 'AJU_INV'
    WHERE k.ArticuloID IN (SELECT DISTINCT ProductoTerminadoID FROM Produccion.RecetaBOM WHERE Estado = 1)
    GROUP BY k.ArticuloID, k.BodegaID
),
StockCorrecto AS (
    SELECT km.ArticuloID, km.BodegaID, SUM(km.Cantidad) AS StockCalculado
    FROM Kardex.KardexMovimientos km
    LEFT JOIN UltimoAjuste ua ON ua.ArticuloID = km.ArticuloID AND ua.BodegaID = km.BodegaID
    JOIN Kardex.TiposMovimientoKardex tmk ON tmk.TipoMovID = km.TipoMovID
    WHERE km.ArticuloID IN (SELECT DISTINCT ProductoTerminadoID FROM Produccion.RecetaBOM WHERE Estado = 1)
    AND NOT (
        tmk.Codigo IN ('SALIDA_VENTA_VISIONS', 'SALIDA_WIP')
        AND ua.FechaAjuste IS NOT NULL
        AND km.Fecha < ua.FechaAjuste
    )
    GROUP BY km.ArticuloID, km.BodegaID
)
UPDATE inv
SET inv.CantidadActual          = sc.StockCalculado,
    inv.FechaUltimaActualizacion = SYSUTCDATETIME()
FROM Inventario.InventarioStock inv
JOIN StockCorrecto sc ON sc.ArticuloID = inv.ArticuloID AND sc.BodegaID = inv.BodegaID AND inv.LoteID IS NULL;
PRINT CONCAT('hokma - PASO 2 PT stock recalculado: ', @@ROWCOUNT);

COMMIT TRANSACTION;
PRINT 'hokma: OK';
GO

-- ============================================================
USE vecco;
GO
BEGIN TRANSACTION;

DECLARE @TipoEntradaPT_vc  INT = (SELECT TipoMovID FROM Kardex.TiposMovimientoKardex WHERE Codigo = 'ENTRADA_PT');
DECLARE @UsuarioSistema_vc INT = (SELECT UsuarioID FROM Seguridad.Usuarios WHERE Username = 'sistema.sync');

IF @TipoEntradaPT_vc IS NULL
    THROW 59001, 'ENTRADA_PT no encontrado en TiposMovimientoKardex', 1;
IF @UsuarioSistema_vc IS NULL
    THROW 59002, 'Usuario sistema.sync no encontrado', 1;

;WITH VentasBOM AS (
    SELECT
        sv.Fecha,
        sv.ArticuloID,
        sv.BodegaID,
        sv.CentroCostoID,
        ABS(sv.Cantidad)            AS Cantidad,
        ABS(sv.CostoUnitario)       AS CostoUnitario,
        ABS(sv.CostoPromedioSaldo)  AS CostoPromedioSaldo,
        TRY_CAST(
            SUBSTRING(sv.ObservacionDetallada,
                      CHARINDEX('Evento #', sv.ObservacionDetallada) + 8,
                      LEN(sv.ObservacionDetallada))
            AS BIGINT) AS EventoEntranteID
    FROM Kardex.KardexMovimientos sv
    JOIN Kardex.TiposMovimientoKardex tm ON tm.TipoMovID = sv.TipoMovID AND tm.Codigo = 'SALIDA_VENTA_VISIONS'
    WHERE sv.ObservacionDetallada LIKE 'Venta Visions - Evento #%'
      AND sv.ArticuloID IN (
          SELECT DISTINCT ProductoTerminadoID FROM Produccion.RecetaBOM WHERE Estado = 1
      )
)
INSERT INTO Kardex.KardexMovimientos
    (Fecha, ArticuloID, BodegaID, LoteID, TipoMovID, CentroCostoID,
     Cantidad, CostoUnitario, CantidadSaldo, CostoPromedioSaldo,
     ObservacionDetallada, UsuarioID)
SELECT
    vb.Fecha, vb.ArticuloID, vb.BodegaID, NULL,
    @TipoEntradaPT_vc, vb.CentroCostoID,
    vb.Cantidad, vb.CostoUnitario, 0, vb.CostoPromedioSaldo,
    CONCAT('Produccion implicita - Venta Visions Evento #', vb.EventoEntranteID),
    @UsuarioSistema_vc
FROM VentasBOM vb
WHERE vb.EventoEntranteID IS NOT NULL
AND NOT EXISTS (
    SELECT 1 FROM Kardex.KardexMovimientos ep
    JOIN Kardex.TiposMovimientoKardex tep ON tep.TipoMovID = ep.TipoMovID AND tep.Codigo = 'ENTRADA_PT'
    WHERE ep.ArticuloID          = vb.ArticuloID
      AND ep.BodegaID            = vb.BodegaID
      AND ep.ObservacionDetallada = CONCAT('Produccion implicita - Venta Visions Evento #', vb.EventoEntranteID)
)
AND (
    NOT EXISTS (
        SELECT 1 FROM Kardex.KardexMovimientos k2
        JOIN Kardex.TiposMovimientoKardex tm2 ON tm2.TipoMovID = k2.TipoMovID AND tm2.Codigo = 'AJU_INV'
        WHERE k2.ArticuloID = vb.ArticuloID AND k2.BodegaID = vb.BodegaID
    )
    OR
    vb.Fecha >= (
        SELECT MAX(k3.Fecha)
        FROM Kardex.KardexMovimientos k3
        JOIN Kardex.TiposMovimientoKardex tm3 ON tm3.TipoMovID = k3.TipoMovID AND tm3.Codigo = 'AJU_INV'
        WHERE k3.ArticuloID = vb.ArticuloID AND k3.BodegaID = vb.BodegaID
    )
);
PRINT CONCAT('vecco - PASO 1 ENTRADA_PT insertados: ', @@ROWCOUNT);

;WITH UltimoAjuste AS (
    SELECT k.ArticuloID, k.BodegaID, MAX(k.Fecha) AS FechaAjuste
    FROM Kardex.KardexMovimientos k
    JOIN Kardex.TiposMovimientoKardex tm ON tm.TipoMovID = k.TipoMovID AND tm.Codigo = 'AJU_INV'
    WHERE k.ArticuloID IN (SELECT DISTINCT ProductoTerminadoID FROM Produccion.RecetaBOM WHERE Estado = 1)
    GROUP BY k.ArticuloID, k.BodegaID
),
StockCorrecto AS (
    SELECT km.ArticuloID, km.BodegaID, SUM(km.Cantidad) AS StockCalculado
    FROM Kardex.KardexMovimientos km
    LEFT JOIN UltimoAjuste ua ON ua.ArticuloID = km.ArticuloID AND ua.BodegaID = km.BodegaID
    JOIN Kardex.TiposMovimientoKardex tmk ON tmk.TipoMovID = km.TipoMovID
    WHERE km.ArticuloID IN (SELECT DISTINCT ProductoTerminadoID FROM Produccion.RecetaBOM WHERE Estado = 1)
    AND NOT (
        tmk.Codigo IN ('SALIDA_VENTA_VISIONS', 'SALIDA_WIP')
        AND ua.FechaAjuste IS NOT NULL
        AND km.Fecha < ua.FechaAjuste
    )
    GROUP BY km.ArticuloID, km.BodegaID
)
UPDATE inv
SET inv.CantidadActual          = sc.StockCalculado,
    inv.FechaUltimaActualizacion = SYSUTCDATETIME()
FROM Inventario.InventarioStock inv
JOIN StockCorrecto sc ON sc.ArticuloID = inv.ArticuloID AND sc.BodegaID = inv.BodegaID AND inv.LoteID IS NULL;
PRINT CONCAT('vecco - PASO 2 PT stock recalculado: ', @@ROWCOUNT);

COMMIT TRANSACTION;
PRINT 'vecco: OK';
GO
