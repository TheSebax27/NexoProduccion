INSERT INTO Produccion.TiposProduccion (Codigo, Nombre)
SELECT 'MTO', 'Por Cliente (Make to Order)'
WHERE NOT EXISTS (SELECT 1 FROM Produccion.TiposProduccion WHERE Codigo = 'MTO');
GO
PRINT 'Tipo MTO agregado OK';
