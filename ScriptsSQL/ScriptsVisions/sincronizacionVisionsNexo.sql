/*
    Instalar Sincronizacion Visions <-> NEXO ERP
    ---------------------------------------------
    Ejecutar contra la base de datos real del cliente (la que ya tienes en
    visionsbase.sql). No crea la base ni toca ninguna tabla propia de
    Visions -- solo agrega las 3 tablas nuevas que necesita el Agente de
    Sincronizacion. Idempotente: se puede volver a correr sin error.
*/

SET NOCOUNT ON;

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'NEXO_ConfiguracionSync' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.NEXO_ConfiguracionSync (
        CENTROCOSTO         SMALLINT        NOT NULL PRIMARY KEY,
        Activo              BIT             NOT NULL CONSTRAINT DF_NEXO_ConfigSync_Activo DEFAULT (1),
        TiposDocumentoVenta NVARCHAR(100)   NULL,
        UltimaFechaExportada DATETIME       NULL,
        UltimaHoraExportada NVARCHAR(20)    NULL,
        FechaCreacion       DATETIME        NOT NULL CONSTRAINT DF_NEXO_ConfigSync_FechaCreacion DEFAULT (GETDATE())
    );
    PRINT 'Tabla dbo.NEXO_ConfiguracionSync creada.';
END
ELSE
    PRINT 'Tabla dbo.NEXO_ConfiguracionSync ya existia, no se modifico.';

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'NEXO_EntradasInventario' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.NEXO_EntradasInventario (
        Id              BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        IdEventoOrigen  BIGINT          NOT NULL,
        CENTROCOSTO     SMALLINT        NOT NULL,
        REFERENCIA      NVARCHAR(30)    NOT NULL,
        CANTIDAD        NUMERIC(18,2)   NOT NULL,
        COSTO           NUMERIC(18,2)   NULL,
        FechaRecepcion  DATETIME        NOT NULL CONSTRAINT DF_NEXO_EntradasInv_FechaRecepcion DEFAULT (GETDATE()),
        Aplicado        BIT             NOT NULL CONSTRAINT DF_NEXO_EntradasInv_Aplicado DEFAULT (0),
        FechaAplicado   DATETIME        NULL,
        Error           NVARCHAR(500)   NULL,
        CONSTRAINT UQ_NEXO_EntradasInv_IdEventoOrigen UNIQUE (IdEventoOrigen)
    );
    PRINT 'Tabla dbo.NEXO_EntradasInventario creada.';
END
ELSE
    PRINT 'Tabla dbo.NEXO_EntradasInventario ya existia, no se modifico.';

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'NEXO_VentasExportadas' AND schema_id = SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.NEXO_VentasExportadas (
        Id              BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        CENTROCOSTO     SMALLINT        NOT NULL,
        TIPDOC          NVARCHAR(20)    NOT NULL,
        NRODOC          NVARCHAR(30)    NOT NULL,
        ORDEN           NUMERIC(18,0)   NOT NULL,
        REFERENCIA      NVARCHAR(30)    NOT NULL,
        CANTIDAD        NUMERIC(18,2)   NOT NULL,
        FechaExportado  DATETIME        NOT NULL CONSTRAINT DF_NEXO_VentasExp_FechaExportado DEFAULT (GETDATE()),
        CONSTRAINT UQ_NEXO_VentasExp_Documento UNIQUE (CENTROCOSTO, TIPDOC, NRODOC, ORDEN, REFERENCIA)
    );
    PRINT 'Tabla dbo.NEXO_VentasExportadas creada.';
END
ELSE
    PRINT 'Tabla dbo.NEXO_VentasExportadas ya existia, no se modifico.';

PRINT 'Instalacion de sincronizacion Visions finalizada.';