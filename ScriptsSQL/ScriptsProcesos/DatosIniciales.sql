SELECT s.name AS Esquema, t.name AS Tabla
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name IN ('Seguridad', 'Produccion', 'dbo')
ORDER BY s.name, t.name;