-- migration_leads_v1.sql
-- Extiende Crm.Leads con todos los campos necesarios para
-- capturar la información fiscal/ubicación del prospecto
-- antes de convertirlo a Cliente, de modo que la conversión
-- traiga NIT, TipoPersona, Departamento, etc. completos.
-- Ejecutar una sola vez en la BD de produccion.
-- Verificar con: SELECT TOP 1 * FROM Crm.Leads

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Crm.Leads') AND name = 'NIT')
    ALTER TABLE Crm.Leads ADD NIT nvarchar(20) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Crm.Leads') AND name = 'Direccion')
    ALTER TABLE Crm.Leads ADD Direccion nvarchar(300) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Crm.Leads') AND name = 'TipoCliente')
    ALTER TABLE Crm.Leads ADD TipoCliente nvarchar(50) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Crm.Leads') AND name = 'TipoPersona')
    ALTER TABLE Crm.Leads ADD TipoPersona nvarchar(20) NULL;  -- 'Natural' | 'Juridica'

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Crm.Leads') AND name = 'TipoIdentificacion')
    ALTER TABLE Crm.Leads ADD TipoIdentificacion nvarchar(10) NULL;  -- '13'=CC, '31'=NIT, etc.

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Crm.Leads') AND name = 'PrimerNombre')
    ALTER TABLE Crm.Leads ADD PrimerNombre nvarchar(100) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Crm.Leads') AND name = 'SegundoNombre')
    ALTER TABLE Crm.Leads ADD SegundoNombre nvarchar(100) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Crm.Leads') AND name = 'PrimerApellido')
    ALTER TABLE Crm.Leads ADD PrimerApellido nvarchar(100) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Crm.Leads') AND name = 'SegundoApellido')
    ALTER TABLE Crm.Leads ADD SegundoApellido nvarchar(100) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Crm.Leads') AND name = 'CodigoDept')
    ALTER TABLE Crm.Leads ADD CodigoDept nvarchar(10) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Crm.Leads') AND name = 'CodigoMuni')
    ALTER TABLE Crm.Leads ADD CodigoMuni nvarchar(10) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Crm.Leads') AND name = 'Departamento')
    ALTER TABLE Crm.Leads ADD Departamento nvarchar(100) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Crm.Leads') AND name = 'Ciudad')
    ALTER TABLE Crm.Leads ADD Ciudad nvarchar(100) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Crm.Leads') AND name = 'DigitoVerificacion')
    ALTER TABLE Crm.Leads ADD DigitoVerificacion int NULL;

GO

PRINT 'migration_leads_v1 OK — columnas agregadas a Crm.Leads';
