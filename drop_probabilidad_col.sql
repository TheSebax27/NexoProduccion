-- Eliminar constraint default de Probabilidad y luego la columna
DECLARE @constraint NVARCHAR(200)
SELECT @constraint = dc.name
FROM sys.default_constraints dc
JOIN sys.columns c ON c.default_object_id = dc.object_id
JOIN sys.tables t ON t.object_id = c.object_id
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name = 'Crm' AND t.name = 'Oportunidades' AND c.name = 'Probabilidad';

IF @constraint IS NOT NULL
BEGIN
    EXEC('ALTER TABLE Crm.Oportunidades DROP CONSTRAINT ' + @constraint);
    PRINT 'Default constraint eliminado: ' + @constraint;
END

ALTER TABLE Crm.Oportunidades DROP COLUMN Probabilidad;
PRINT 'Columna Probabilidad eliminada OK';
