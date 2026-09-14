-- Agrega soporte para ICO (Impuesto al Consumo) en Catalogo.Iva
-- Paso 1: columna TipoImpuesto (IVA por defecto para no romper filas existentes)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Catalogo.Iva') AND name = 'TipoImpuesto')
BEGIN
    ALTER TABLE Catalogo.Iva
    ADD TipoImpuesto NVARCHAR(10) NOT NULL CONSTRAINT DF_Iva_TipoImpuesto DEFAULT 'IVA'
    PRINT 'Columna TipoImpuesto agregada.'
END
ELSE
BEGIN
    PRINT 'Columna TipoImpuesto ya existe.'
END
GO

-- Paso 2: ICO 8%
IF NOT EXISTS (SELECT 1 FROM Catalogo.Iva WHERE TipoImpuesto = 'ICO' AND Iva = 8)
BEGIN
    INSERT INTO Catalogo.Iva (Iva, Descripcion, TipoImpuesto)
    VALUES (8, N'ICO 8%', N'ICO')
    PRINT 'ICO 8% insertado.'
END
ELSE
BEGIN
    PRINT 'ICO 8% ya existe.'
END
