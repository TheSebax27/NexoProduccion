-- Registra pagos retroactivos para facturas confirmadas en Visions que no tienen pago.
-- Solo inserta si: VisionsConfirmado = 1, sin pagos en Facturacion.Pagos, total > 0.
-- Ejecutar UNA sola vez en NEXO_ERP.

INSERT INTO Facturacion.Pagos (FacturaID, Monto, FechaPago, MetodoPago, Notas, UsuarioID)
SELECT
    f.FacturaID,
    ISNULL(SUM(fl.Cantidad * fl.PrecioUnitario), 0) AS Monto,
    GETDATE()                                        AS FechaPago,
    'VISIONS'                                        AS MetodoPago,
    'Pago retroactivo — facturado en Visions (' + ISNULL(f.NroDoc, 'sin nro') + ')' AS Notas,
    NULL                                             AS UsuarioID  -- nullable, sistema automatico
FROM Facturacion.Facturas f
INNER JOIN Facturacion.FacturaLineas fl ON fl.FacturaID = f.FacturaID
WHERE f.VisionsConfirmado = 1
  AND NOT EXISTS (
      SELECT 1 FROM Facturacion.Pagos p WHERE p.FacturaID = f.FacturaID
  )
GROUP BY f.FacturaID, f.NroDoc
HAVING ISNULL(SUM(fl.Cantidad * fl.PrecioUnitario), 0) > 0;

-- Verificacion: facturas afectadas
SELECT f.FacturaID, f.NroDoc, p.Monto, p.FechaPago
FROM Facturacion.Pagos p
INNER JOIN Facturacion.Facturas f ON f.FacturaID = p.FacturaID
WHERE p.MetodoPago = 'VISIONS'
  AND p.Notas LIKE 'Pago retroactivo%'
ORDER BY p.FechaPago DESC;
