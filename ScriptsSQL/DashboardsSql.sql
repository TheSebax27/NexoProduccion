/* ============================================================================
   SISTEMA NEXO - Script 04: Vistas para Dashboard Blazor
   Ejecutar despues de 01, 02 y 03.
   Estas vistas alimentan directamente los graficos descritos en la
   documentacion (7.2 Dashboard Interactivo de Produccion).
   ============================================================================ */
USE NEXO_ERP;
GO

-- ----------------------------------------------------------------------------
-- KPI: Produccion Planificada vs Real (grafico de barras, por dia)
-- ----------------------------------------------------------------------------
CREATE OR ALTER VIEW Produccion.vw_ProduccionPlanVsReal AS
SELECT
    CAST(op.FechaPlanificada AS DATE) AS Fecha,
    cc.CentroCostoID,
    cc.Nombre AS CentroCosto,
    a.Nombre AS Producto,
    SUM(op.CantidadProgramada) AS TotalPlanificado,
    SUM(ISNULL(op.CantidadProducidaReal,0)) AS TotalReal
FROM Produccion.OrdenesProduccion op
JOIN Organizacion.CentrosCosto cc ON cc.CentroCostoID = op.CentroCostoDestinoID
JOIN Catalogo.Articulos a ON a.ArticuloID = op.ProductoTerminadoID
GROUP BY CAST(op.FechaPlanificada AS DATE), cc.CentroCostoID, cc.Nombre, a.Nombre;
GO

-- ----------------------------------------------------------------------------
-- KPI: Distribucion de produccion por centro de costo (grafico de torta)
-- ----------------------------------------------------------------------------
CREATE OR ALTER VIEW Produccion.vw_DistribucionPorCentroCosto AS
SELECT
    cc.CentroCostoID,
    cc.Nombre AS CentroCosto,
    COUNT(op.OrdenProduccionID) AS TotalOrdenes,
    SUM(ISNULL(op.CantidadProducidaReal,0)) AS TotalUnidadesProducidas,
    SUM(op.CostoMateriales + op.CostoMOD + op.CostoCIF) AS InversionTotal
FROM Produccion.OrdenesProduccion op
JOIN Organizacion.CentrosCosto cc ON cc.CentroCostoID = op.CentroCostoDestinoID
WHERE op.EstadoOPID = (SELECT EstadoOPID FROM Produccion.EstadosOP WHERE Nombre = 'Finalizada')
GROUP BY cc.CentroCostoID, cc.Nombre;
GO

-- ----------------------------------------------------------------------------
-- KPI: Perdidas y mermas por motivo (grafico de pastel)
-- ----------------------------------------------------------------------------
CREATE OR ALTER VIEW Kardex.vw_PerdidasPorMotivo AS
SELECT
    m.Nombre AS Motivo,
    CAST(b.Fecha AS DATE) AS Fecha,
    COUNT(*) AS TotalEventos,
    SUM(b.CantidadPerdida) AS CantidadTotalPerdida,
    SUM(b.CostoTotal) AS ValorTotalPerdido
FROM Kardex.BajasInventarioPerdidas b
JOIN Kardex.TiposMotivoLoss m ON m.MotivoID = b.MotivoID
WHERE b.Estado = 'CONFIRMADA'
GROUP BY m.Nombre, CAST(b.Fecha AS DATE);
GO

-- ----------------------------------------------------------------------------
-- KPI: Tendencia de costo unitario real por producto (grafico de lineas)
-- ----------------------------------------------------------------------------
CREATE OR ALTER VIEW Produccion.vw_TendenciaCostoUnitario AS
SELECT
    a.ArticuloID,
    a.Nombre AS Producto,
    CAST(op.FechaFin AS DATE) AS Fecha,
    op.CostoUnitarioReal
FROM Produccion.OrdenesProduccion op
JOIN Catalogo.Articulos a ON a.ArticuloID = op.ProductoTerminadoID
WHERE op.EstadoOPID = (SELECT EstadoOPID FROM Produccion.EstadosOP WHERE Nombre = 'Finalizada')
  AND op.FechaFin IS NOT NULL;
GO

-- ----------------------------------------------------------------------------
-- KPI: Cumplimiento de planificacion (% ordenes completadas a tiempo)
-- ----------------------------------------------------------------------------
CREATE OR ALTER VIEW Produccion.vw_CumplimientoPlanificacion AS
SELECT
    cc.CentroCostoID,
    cc.Nombre AS CentroCosto,
    COUNT(*) AS TotalOrdenesFinalizadas,
    SUM(CASE WHEN op.FechaFin <= op.FechaPlanificada THEN 1 ELSE 0 END) AS OrdenesATiempo,
    CAST(SUM(CASE WHEN op.FechaFin <= op.FechaPlanificada THEN 1 ELSE 0 END) AS DECIMAL(18,4))
        / NULLIF(COUNT(*),0) * 100 AS PorcentajeCumplimiento
FROM Produccion.OrdenesProduccion op
JOIN Organizacion.CentrosCosto cc ON cc.CentroCostoID = op.CentroCostoDestinoID
WHERE op.EstadoOPID = (SELECT EstadoOPID FROM Produccion.EstadosOP WHERE Nombre = 'Finalizada')
GROUP BY cc.CentroCostoID, cc.Nombre;
GO

-- ----------------------------------------------------------------------------
-- Consulta rapida: Stock consolidado multibodega / multicentro de costo
-- ----------------------------------------------------------------------------
CREATE OR ALTER VIEW Inventario.vw_StockConsolidado AS
SELECT
    a.ArticuloID, a.SKU, a.Nombre AS Articulo, ta.Nombre AS TipoArticulo,
    b.BodegaID, b.Nombre AS Bodega, cc.CentroCostoID, cc.Nombre AS CentroCosto,
    l.LoteID, l.NumeroLote, l.FechaVencimiento,
    s.CantidadActual, s.CostoUnitarioLote,
    (s.CantidadActual * s.CostoUnitarioLote) AS ValorTotal,
    CASE WHEN s.CantidadActual <= a.PuntoReorden THEN 1 ELSE 0 END AS RequierePedido
FROM Inventario.InventarioStock s
JOIN Catalogo.Articulos a ON a.ArticuloID = s.ArticuloID
JOIN Catalogo.TiposArticulo ta ON ta.TipoArticuloID = a.TipoArticuloID
JOIN Inventario.Bodegas b ON b.BodegaID = s.BodegaID
JOIN Organizacion.CentrosCosto cc ON cc.CentroCostoID = b.CentroCostoID
LEFT JOIN Inventario.Lotes l ON l.LoteID = s.LoteID
WHERE s.CantidadActual > 0;
GO

PRINT 'Vistas de dashboard creadas correctamente.';