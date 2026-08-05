/*
    Instalar Sincronizacion Visions <-> NEXO ERP
    ---------------------------------------------
    Ejecutar este script contra la base de datos de Visions de UN CLIENTE
    (la que ya existe, con todas sus tablas: TARJETA, MOVDETALLES, EMPRESA, etc.).

    A diferencia del script de creacion de base de datos completo, este NO
    crea la base de datos ni toca ninguna tabla propia de Visions -- solo
    agrega las 3 tablas que el Agente de Sincronizacion (NexoSyncAgent)
    necesita para comunicarse con NEXO ERP. Es idempotente: se puede volver
    a ejecutar sin error si las tablas ya existen (no las vuelve a crear).

    Uso: abrir en SSMS, conectar contra la base de Visions del cliente,
    ejecutar. Luego, en NEXO ERP (Catalogo > Centros de Costo), activar
    "Este cliente tiene Visions", indicar el identificador del cliente y
    generar la API Key del Agente desde la misma pantalla.
*/

SET NOCOUNT ON;

-- 1) Configuracion de sincronizacion por Centro de Costo (uno por local/sucursal).
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

-- 2) Entradas de inventario pendientes de aplicar en Visions (NEXO -> Visions).
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

-- 3) Ventas de Visions ya exportadas a NEXO (Visions -> NEXO), evita duplicados.
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
