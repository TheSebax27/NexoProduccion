-- migration_tarjetas_v5.sql
-- 1. Corrige typo: PPPublico → PPublico en Catalogo.Tarjetas
-- 2. Elimina Catalogo.Tarjetas.Fracciones (centralizado en Presentacion.Fracciones)
-- 3. Puebla catalogo.Presentacion con presentaciones estandar
-- 4. Actualiza Inventario.vw_StockConsolidado (usa JOIN a Presentacion para Fracciones)
-- ATENCION: ejecutar con conexion a NEXO_ERP, NO a VISIONSDBL1
-- =====================================================================

USE NEXO_ERP;
GO

-- ── 1. Renombrar PPPublico → PPublico ─────────────────────────────────
-- sp_rename advierte sobre referencias a objetos; es esperado y no es error.
IF EXISTS (SELECT 1 FROM sys.columns
           WHERE object_id = OBJECT_ID('Catalogo.Tarjetas') AND name = 'PPPublico')
BEGIN
    EXEC sp_rename 'Catalogo.Tarjetas.PPPublico', 'PPublico', 'COLUMN';
    PRINT 'Columna PPPublico renombrada a PPublico.';
END
ELSE IF EXISTS (SELECT 1 FROM sys.columns
                WHERE object_id = OBJECT_ID('Catalogo.Tarjetas') AND name = 'PPublico')
    PRINT 'PPublico ya existe (nada que hacer).';
ELSE
    PRINT 'ADVERTENCIA: no se encontro ni PPPublico ni PPublico en Catalogo.Tarjetas.';
GO

-- ── 2. Eliminar Catalogo.Tarjetas.Fracciones ──────────────────────────
-- Fracciones ahora vive en catalogo.Presentacion.Fracciones.
-- Un articulo obtiene sus fracciones via JOIN a Presentacion (por PresentacionCodigo).

-- 2a. Eliminar DEFAULT constraint si existe
DECLARE @constraintFrac NVARCHAR(256);
SELECT @constraintFrac = dc.name
FROM sys.default_constraints dc
JOIN sys.columns c ON c.default_object_id = dc.object_id
WHERE c.object_id = OBJECT_ID('Catalogo.Tarjetas') AND c.name = 'Fracciones';

IF @constraintFrac IS NOT NULL
BEGIN
    EXEC('ALTER TABLE Catalogo.Tarjetas DROP CONSTRAINT ' + @constraintFrac);
    PRINT 'DEFAULT constraint de Fracciones eliminado.';
END
GO

-- 2b. Eliminar la columna
IF EXISTS (SELECT 1 FROM sys.columns
           WHERE object_id = OBJECT_ID('Catalogo.Tarjetas') AND name = 'Fracciones')
BEGIN
    ALTER TABLE Catalogo.Tarjetas DROP COLUMN Fracciones;
    PRINT 'Columna Fracciones eliminada de Catalogo.Tarjetas.';
END
ELSE
    PRINT 'Fracciones ya no existe en Catalogo.Tarjetas (nada que hacer).';
GO

-- ── 3. Presentaciones estandar ────────────────────────────────────────
-- Se insertan solo si no existen; se usan MERGE para seguridad.
-- Tipo: NULL = unidades normales, 'PESO' = vendido por peso, 'VOLUMEN' = por volumen.
-- Fracciones: NULL = no aplica o variable segun producto;
--             valor > 0 = se auto-llena en el articulo al seleccionar la presentacion.

MERGE catalogo.Presentacion AS destino
USING (VALUES
    -- Codigo,    Descripcion,            Fracciones, Tipo
    ('UND',      'Unidad',                NULL,       NULL),
    ('DOCENA',   'Docena',                12,         NULL),
    ('MEDIA',    'Media Docena',          6,          NULL),
    ('CAJA6',    'Caja de 6 unidades',    6,          NULL),
    ('CAJA12',   'Caja de 12 unidades',   12,         NULL),
    ('CAJA24',   'Caja de 24 unidades',   24,         NULL),
    ('CAJA48',   'Caja de 48 unidades',   48,         NULL),
    ('PACK4',    'Paquete x4',            4,          NULL),
    ('BOLSA',    'Bolsa',                 NULL,       NULL),
    ('PAQUETE',  'Paquete',               NULL,       NULL),
    ('KG',       'Kilogramo',             NULL,       'PESO'),
    ('GR',       'Gramo',                 NULL,       'PESO'),
    ('TN',       'Tonelada',              NULL,       'PESO'),
    ('LB',       'Libra',                 NULL,       'PESO'),
    ('LT',       'Litro',                 NULL,       NULL),
    ('ML',       'Mililitro',             NULL,       NULL)
) AS origen (Codigo, Presentacion, Fracciones, Tipo)
ON destino.Codigo = origen.Codigo
WHEN NOT MATCHED THEN
    INSERT (Codigo, Presentacion, Fracciones, Tipo)
    VALUES (origen.Codigo, origen.Presentacion, origen.Fracciones, origen.Tipo);

PRINT CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' presentaciones insertadas (las ya existentes no se modifican).';
GO

-- ── 4. Reconstruir vw_StockConsolidado ───────────────────────────────
-- Ahora obtiene Fracciones via JOIN a Presentacion en lugar de a.Fracciones.
IF OBJECT_ID('Inventario.vw_StockConsolidado', 'V') IS NOT NULL
    DROP VIEW Inventario.vw_StockConsolidado;
GO

CREATE VIEW Inventario.vw_StockConsolidado AS
SELECT
    a.ArticuloID,
    a.Referencia AS SKU,
    a.Nombre AS Articulo,
    ta.Nombre AS TipoArticulo,
    u.Abreviatura AS Unidad,
    p.Fracciones AS UnidadesPorEmbalaje,
    b.BodegaID,
    b.Nombre AS Bodega,
    cc.CentroCostoID,
    cc.Nombre AS CentroCosto,
    l.LoteID,
    l.NumeroLote,
    l.FechaVencimiento,
    s.CantidadActual,
    s.CostoUnitarioLote,
    (s.CantidadActual * s.CostoUnitarioLote) AS ValorTotal,
    CASE WHEN s.CantidadActual <= a.PuntoReorden
         THEN CAST(1 AS BIT)
         ELSE CAST(0 AS BIT)
    END AS RequierePedido
FROM Inventario.InventarioStock s
JOIN Catalogo.Tarjetas a ON a.ArticuloID = s.ArticuloID
JOIN Catalogo.TiposArticulo ta ON ta.TipoArticuloID = a.TipoArticuloID
JOIN Inventario.Bodegas b ON b.BodegaID = s.BodegaID
JOIN Organizacion.CentrosCosto cc ON cc.CentroCostoID = b.CentroCostoID
LEFT JOIN Inventario.Lotes l ON l.LoteID = s.LoteID
LEFT JOIN Catalogo.UnidadesMedida u ON u.UnidadID = a.UnidadID
LEFT JOIN Catalogo.Presentacion p ON p.Codigo = a.PresentacionCodigo;
GO

PRINT 'Vista Inventario.vw_StockConsolidado reconstruida correctamente.';
GO

-- ── 5. Reconstruir Produccion.vw_ProduccionPlanVsReal ─────────────────
-- La vista estaba referenciando Catalogo.Articulos (inexistente) en lugar de
-- Catalogo.Tarjetas. Ademas, se agrega WHERE para excluir ordenes Canceladas
-- (el total planificado no debe contar ordenes que se cancelaron).
IF OBJECT_ID('Produccion.vw_ProduccionPlanVsReal', 'V') IS NOT NULL
    DROP VIEW Produccion.vw_ProduccionPlanVsReal;
GO

CREATE VIEW Produccion.vw_ProduccionPlanVsReal AS
SELECT
    CAST(op.FechaPlanificada AS DATE) AS Fecha,
    cc.CentroCostoID,
    cc.Nombre AS CentroCosto,
    a.Nombre  AS Producto,
    SUM(op.CantidadProgramada)                   AS TotalPlanificado,
    SUM(ISNULL(op.CantidadProducidaReal, 0))     AS TotalReal
FROM Produccion.OrdenesProduccion op
JOIN Organizacion.CentrosCosto cc ON cc.CentroCostoID = op.CentroCostoDestinoID
JOIN Catalogo.Tarjetas a          ON a.ArticuloID     = op.ProductoTerminadoID
WHERE op.EstadoOPID <> (SELECT EstadoOPID FROM Produccion.EstadosOP WHERE Nombre = 'Cancelada')
GROUP BY CAST(op.FechaPlanificada AS DATE), cc.CentroCostoID, cc.Nombre, a.Nombre;
GO

PRINT 'Vista Produccion.vw_ProduccionPlanVsReal reconstruida correctamente.';
GO

-- ── Verificacion final ────────────────────────────────────────────────
PRINT '--- Columnas de Catalogo.Tarjetas ---';
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'Catalogo' AND TABLE_NAME = 'Tarjetas'
ORDER BY ORDINAL_POSITION;

PRINT '--- Presentaciones en catalogo.Presentacion ---';
SELECT Codigo, Presentacion, Fracciones, Tipo FROM catalogo.Presentacion ORDER BY Codigo;
GO
