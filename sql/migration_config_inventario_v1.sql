-- =============================================================================
-- Configuracion de inventario: manejo de vencimientos y modo de lotes
-- =============================================================================
SET NOCOUNT ON;

IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('Organizacion.ConfiguracionEmpresa')
                 AND name = 'ManejarVencimientos')
    ALTER TABLE Organizacion.ConfiguracionEmpresa
    ADD ManejarVencimientos BIT NOT NULL DEFAULT 0;

IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('Organizacion.ConfiguracionEmpresa')
                 AND name = 'DiasAlertaVencimiento')
    ALTER TABLE Organizacion.ConfiguracionEmpresa
    ADD DiasAlertaVencimiento INT NOT NULL DEFAULT 7;

IF NOT EXISTS (SELECT 1 FROM sys.columns
               WHERE object_id = OBJECT_ID('Organizacion.ConfiguracionEmpresa')
                 AND name = 'ModoLotes')
    ALTER TABLE Organizacion.ConfiguracionEmpresa
    ADD ModoLotes NVARCHAR(10) NOT NULL DEFAULT 'FIFO'
        CONSTRAINT CK_ConfigEmpresa_ModoLotes CHECK (ModoLotes IN ('FIFO','MANUAL'));

PRINT 'Migracion config inventario completada.';
