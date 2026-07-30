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
JOIN Catalogo.TiposArticulos ta ON ta.TipoArticuloID = a.TipoArticuloID
JOIN Inventario.Bodegas b ON b.BodegaID = s.BodegaID
JOIN Organizacion.CentrosCosto cc ON cc.CentroCostoID = b.CentroCostoID
LEFT JOIN Inventario.Lotes l ON l.LoteID = s.LoteID
WHERE s.CantidadActual > 0;
GO
