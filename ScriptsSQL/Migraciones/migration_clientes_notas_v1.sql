-- migration_clientes_notas_v1.sql
-- Agrega columna Notas a Crm.Clientes
-- Ejecutar en produccion: 45.171.180.182\VISIONS (cada BD de cliente)

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('Crm.Clientes') AND name = 'Notas'
)
    ALTER TABLE Crm.Clientes ADD [Notas] [nvarchar](2000) NULL;
GO
