-- Agrega FechaModificacion a articulos y clientes para resolver conflictos de sync bidireccional.
-- Ejecutar una sola vez contra NEXO_ERP.

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Catalogo.Tarjetas') AND name = 'FechaModificacion')
BEGIN
    ALTER TABLE Catalogo.Tarjetas ADD FechaModificacion DATETIME NULL;
    EXEC('UPDATE Catalogo.Tarjetas SET FechaModificacion = GETDATE()');
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Crm.Clientes') AND name = 'FechaModificacion')
BEGIN
    ALTER TABLE Crm.Clientes ADD FechaModificacion DATETIME NULL;
    EXEC('SET QUOTED_IDENTIFIER ON; UPDATE Crm.Clientes SET FechaModificacion = GETDATE()');
END
