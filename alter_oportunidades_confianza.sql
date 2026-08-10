-- Reemplaza Probabilidad (INT) por ConfianzaCierre (NVARCHAR) en Crm.Oportunidades
-- OPTIMISTA | NEUTRO | BAJA

-- 1. Agregar nueva columna con default NEUTRO
ALTER TABLE Crm.Oportunidades
    ADD ConfianzaCierre NVARCHAR(20) NOT NULL DEFAULT 'NEUTRO';
GO

-- 2. Migrar datos existentes: probabilidad >= 70 → OPTIMISTA, < 40 → BAJA
UPDATE Crm.Oportunidades
SET ConfianzaCierre = CASE
    WHEN Probabilidad >= 70 THEN 'OPTIMISTA'
    WHEN Probabilidad < 40  THEN 'BAJA'
    ELSE 'NEUTRO'
END;
GO

-- 3. Eliminar columna antigua
ALTER TABLE Crm.Oportunidades DROP COLUMN Probabilidad;
GO

PRINT 'Oportunidades.ConfianzaCierre OK';
