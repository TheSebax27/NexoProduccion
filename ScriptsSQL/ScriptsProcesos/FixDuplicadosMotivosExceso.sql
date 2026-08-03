/* ============================================================================
   NEXO ERP - FIX: Produccion.MotivosExcesoConsumo no tenia restriccion UNIQUE
   en Nombre, asi que cada vez que se re-ejecuto DatosSemilla.sql se insertaron
   duplicados en vez de fallar (a diferencia del resto de tablas semilla, que
   si tienen UNIQUE y por eso el reintento simplemente falla "y eso es
   normal", segun el propio comentario del script). Resultado: 12 filas para
   4 motivos reales, con dos de ellas ademas con el texto mal codificado
   ("producci�n" en vez de "producción").
   ============================================================================ */

USE NEXO_ERP;
GO

BEGIN TRANSACTION;

-- Solo el ID 8 esta realmente en uso (3 consumos lo referencian); se conserva
-- ese y se corrige su texto con la tilde correcta.
UPDATE Produccion.MotivosExcesoConsumo SET Nombre = N'Ajuste de receta en producción' WHERE MotivoExcesoID = 8;
UPDATE Produccion.MotivosExcesoConsumo SET Nombre = N'Merma superior a la estándar' WHERE MotivoExcesoID = 5;

-- Reasigna cualquier referencia de un duplicado hacia el ID que se conserva
-- (por si en el futuro algo quedo apuntando a uno de los que se van a borrar).
UPDATE Produccion.OrdenesProduccionConsumo SET MotivoExcesoID = 8  WHERE MotivoExcesoID IN (12, 4);
UPDATE Produccion.OrdenesProduccionConsumo SET MotivoExcesoID = 2  WHERE MotivoExcesoID IN (6, 10);
UPDATE Produccion.OrdenesProduccionConsumo SET MotivoExcesoID = 3  WHERE MotivoExcesoID IN (7, 11);
UPDATE Produccion.OrdenesProduccionConsumo SET MotivoExcesoID = 5  WHERE MotivoExcesoID IN (9, 1);

DELETE FROM Produccion.MotivosExcesoConsumo WHERE MotivoExcesoID IN (12, 4, 6, 10, 7, 11, 9, 1);

-- Evita que este bug vuelva a pasar en el futuro.
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('Produccion.MotivosExcesoConsumo') AND name = 'UQ_MotivoExcesoConsumo_Nombre'
)
    ALTER TABLE Produccion.MotivosExcesoConsumo ADD CONSTRAINT UQ_MotivoExcesoConsumo_Nombre UNIQUE (Nombre);

COMMIT TRANSACTION;

SELECT MotivoExcesoID, Nombre FROM Produccion.MotivosExcesoConsumo ORDER BY Nombre;
GO
