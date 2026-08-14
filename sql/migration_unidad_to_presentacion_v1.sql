-- ============================================================
-- NEXO ERP — Migración: Eliminar UnidadesMedida de Tarjetas
-- migration_unidad_to_presentacion_v1.sql
-- Ejecutar en: NEXO_ERP (base de cada cliente)
-- Fecha:       2026-08-14
-- ============================================================
-- RESUMEN:
--   Antes: los módulos mostraban la "unidad" tomándola de
--          Catalogo.UnidadesMedida vía Tarjetas.UnidadID.
--   Ahora: se usa Tarjetas.PresentacionCodigo (Catalogo.Presentacion)
--          como fuente de la etiqueta de unidad/embalaje.
--   Se reconstruye vw_StockConsolidado para que su columna
--   Unidad devuelva PresentacionCodigo en lugar de la abreviatura
--   de UnidadesMedida.
--   PENDIENTE (paso 2, cuando no haya ningún JOIN en código):
--     - ALTER TABLE Catalogo.Tarjetas DROP COLUMN UnidadID
--     - DROP TABLE Catalogo.UnidadesMedida  (si no quedan FKs)
-- ============================================================

USE NEXO_ERP;
GO

-- ── 1. Reconstruir vw_StockConsolidado ───────────────────────────────────
--    Elimina el JOIN a UnidadesMedida; usa PresentacionCodigo como Unidad.

IF OBJECT_ID('Inventario.vw_StockConsolidado', 'V') IS NOT NULL
    DROP VIEW Inventario.vw_StockConsolidado;
GO

CREATE VIEW Inventario.vw_StockConsolidado AS
    SELECT
        a.ArticuloID,
        a.Referencia          AS SKU,
        a.Nombre              AS Articulo,
        ta.Nombre             AS TipoArticulo,
        a.PresentacionCodigo  AS Unidad,          -- antes: u.Abreviatura
        p.Fracciones          AS UnidadesPorEmbalaje,
        b.BodegaID,
        b.Nombre              AS Bodega,
        cc.CentroCostoID,
        cc.Nombre             AS CentroCosto,
        ist.LoteID,
        lot.NumeroLote,
        lot.FechaVencimiento,
        ist.CantidadActual,
        ist.CostoUnitarioLote,
        ist.CantidadActual * ist.CostoUnitarioLote  AS ValorTotal,
        CAST(
            CASE
                WHEN a.StockMinimo > 0
                 AND (SELECT ISNULL(SUM(s2.CantidadActual),0)
                      FROM Inventario.InventarioStock s2
                      WHERE s2.ArticuloID = a.ArticuloID) < a.StockMinimo
                THEN 1 ELSE 0
            END
        AS BIT) AS RequierePedido
    FROM Inventario.InventarioStock ist
    JOIN Catalogo.Tarjetas a
        ON a.ArticuloID = ist.ArticuloID
    JOIN Catalogo.TiposArticulo ta
        ON ta.TipoArticuloID = a.TipoArticuloID
    LEFT JOIN Catalogo.Presentacion p
        ON p.Codigo = a.PresentacionCodigo
    JOIN Inventario.Bodegas b
        ON b.BodegaID = ist.BodegaID
    JOIN Organizacion.CentrosCosto cc
        ON cc.CentroCostoID = b.CentroCostoID
    LEFT JOIN Inventario.Lotes lot
        ON lot.LoteID = ist.LoteID
    WHERE ist.CantidadActual <> 0;
GO

-- ── 2. (OPCIONAL - ejecutar SOLO cuando el código esté limpio) ───────────
--    Eliminar columna UnidadID de Tarjetas y eventualmente la tabla.
--
-- PASO 2A: quitar la FK si existe
-- IF EXISTS (
--     SELECT 1 FROM sys.foreign_keys
--     WHERE name = 'FK_Tarjetas_UnidadID'
--       AND parent_object_id = OBJECT_ID('Catalogo.Tarjetas')
-- )
--     ALTER TABLE Catalogo.Tarjetas DROP CONSTRAINT FK_Tarjetas_UnidadID;
-- GO
--
-- PASO 2B: eliminar la columna
-- ALTER TABLE Catalogo.Tarjetas DROP COLUMN UnidadID;
-- GO
--
-- PASO 2C: eliminar la tabla (solo si no hay otras FKs o referencias)
-- DROP TABLE Catalogo.UnidadesMedida;
-- GO

PRINT 'Migración migration_unidad_to_presentacion_v1 completada correctamente.';
GO
