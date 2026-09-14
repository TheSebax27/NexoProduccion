-- Agrega el estado 'Retrasada' a Produccion.EstadosOP
-- Requerido para la automatización G: auto-marcar OPs vencidas

IF NOT EXISTS (SELECT 1 FROM Produccion.EstadosOP WHERE Nombre = 'Retrasada')
BEGIN
    INSERT INTO Produccion.EstadosOP (Nombre, Orden)
    VALUES ('Retrasada', 6)
    PRINT 'Estado "Retrasada" insertado correctamente.'
END
ELSE
BEGIN
    PRINT 'Estado "Retrasada" ya existe. No se insertó nada.'
END
