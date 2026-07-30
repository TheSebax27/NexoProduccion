/* ============================================================================
   SISTEMA NEXO - Script 07: Agentes de Sincronizacion (autenticacion maquina-a-maquina)
   Ejecutar en NEXO_ERP despues de 05 y 06.
   ============================================================================ */
USE NEXO_ERP;
GO

-- ----------------------------------------------------------------------------
-- Un Agente de Sincronizacion (instalado en el servidor de un cliente) se
-- identifica con un API Key propio, vinculado a UN centro de costo. Nunca
-- guardamos el API Key en texto plano -- igual que las contrasenas de
-- usuarios, guardamos su hash (aqui con SHA-256 simple, ya que es una clave
-- de alta entropia generada por nosotros, no una contrasena elegida por un
-- humano; no necesita el costo extra de PBKDF2).
-- ----------------------------------------------------------------------------
CREATE TABLE Integracion.AgentesSync (
    AgenteSyncID    INT IDENTITY(1,1) PRIMARY KEY,
    CentroCostoID   INT NOT NULL REFERENCES Organizacion.CentrosCosto(CentroCostoID),
    ApiKeyHash      CHAR(64) NOT NULL UNIQUE, -- SHA-256 en hexadecimal (32 bytes = 64 caracteres hex)
    Descripcion     NVARCHAR(150) NULL,
    Activo          BIT NOT NULL DEFAULT 1,
    FechaCreacion   DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UltimaConexion  DATETIME2 NULL
);
GO
CREATE INDEX IX_AgentesSync_CentroCosto ON Integracion.AgentesSync(CentroCostoID);
GO

PRINT 'Tabla de agentes de sincronizacion creada correctamente.';