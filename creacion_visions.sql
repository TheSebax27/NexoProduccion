-- =============================================================================
-- SCRIPT: creacion_visions.sql
-- Base   : VISIONSDBL1 en .\JONATHAN
-- Objeto : Crear TODOS los objetos SQL que NEXO necesita en la base de datos
--          de Visions para que la integracion funcione:
--          - Tablas NEXO_* (staging, cambios, facturas, clientes)
--          - Triggers sobre tablas de Visions (TARJETA, MOVDETALLES)
--          - Stored Procedures (ACTUALIZARTARJETA, helpers para boton Visions)
-- Uso    : Ejecutar COMPLETO en SSMS contra VISIONSDBL1.
--          Idempotente: usa IF NOT EXISTS / IF OBJECT_ID en cada objeto.
--          El agente NexoSyncAgent ejecuta TareaInicializarVisions al arrancar
--          y crea la mayoria de estos objetos automaticamente; este script sirve
--          para instalacion manual, revision o recreacion tras un disaster.
-- IMPORTANTE: Visions NO acepta NULL en columnas de texto ni numericas.
--             Todas las columnas tienen DEFAULT '' o DEFAULT 0 segun tipo.
-- =============================================================================
USE VISIONSDBL1;
GO

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
PRINT 'Iniciando creacion de objetos NEXO en VISIONSDBL1...';
PRINT 'Fecha: ' + CONVERT(NVARCHAR(30), GETDATE(), 120);
GO

-- =============================================================================
-- SECCIÓN 1: TABLAS DE CONFIGURACION Y ESTADO
-- =============================================================================

-- -----------------------------------------------------------------------------
-- NEXO_ConfiguracionSync: pares clave-valor para configuracion de la sincronizacion
-- Ejemplo: UltimaSync = '2026-08-21 15:00:00'
-- -----------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NEXO_ConfiguracionSync')
BEGIN
    CREATE TABLE dbo.NEXO_ConfiguracionSync (
        ConfigID            INT IDENTITY(1,1) NOT NULL,
        Clave               NVARCHAR(50)  NOT NULL,
        Valor               NVARCHAR(200) NOT NULL DEFAULT '',
        FechaActualizacion  DATETIME      NOT NULL DEFAULT GETDATE(),
        CONSTRAINT PK_NEXO_ConfiguracionSync PRIMARY KEY (ConfigID),
        CONSTRAINT UQ_NEXO_ConfiguracionSync_Clave UNIQUE (Clave)
    );
    -- Valores iniciales de configuracion
    INSERT INTO dbo.NEXO_ConfiguracionSync (Clave, Valor)
    VALUES
        ('Version',          '1.0'),
        ('AgentVersion',     '1.0'),
        ('UltimaSync',       ''),
        ('EstadoConexion',   'OK');
    PRINT 'Tabla NEXO_ConfiguracionSync creada con valores iniciales.';
END
ELSE
    PRINT 'NEXO_ConfiguracionSync ya existe. OK.';
GO

-- =============================================================================
-- SECCIÓN 2: TABLA DE EXPORTACION DE VENTAS
-- El agente lee ventas de Visions para importarlas a NEXO como facturas.
-- =============================================================================
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NEXO_VentasExportadas')
BEGIN
    CREATE TABLE dbo.NEXO_VentasExportadas (
        ExportID    INT IDENTITY(1,1) NOT NULL,
        TARJETA     NVARCHAR(30)      NOT NULL DEFAULT '',  -- REFERENCIA en dbo.TARJETA
        CANTIDAD    DECIMAL(18,4)     NOT NULL DEFAULT 0,
        PRECIO      DECIMAL(18,4)     NOT NULL DEFAULT 0,
        FECHA       DATETIME          NOT NULL DEFAULT GETDATE(),
        NRODOC      NVARCHAR(20)      NOT NULL DEFAULT '',  -- numero de documento Visions
        PROCESADO   BIT               NOT NULL DEFAULT 0,   -- 0=pendiente, 1=importado a NEXO
        CONSTRAINT PK_NEXO_VentasExportadas PRIMARY KEY (ExportID)
    );
    CREATE INDEX IX_NEXO_VentasExportadas_Procesado ON dbo.NEXO_VentasExportadas (PROCESADO);
    PRINT 'Tabla NEXO_VentasExportadas creada.';
END
ELSE
    PRINT 'NEXO_VentasExportadas ya existe. OK.';
GO

-- =============================================================================
-- SECCIÓN 3: TABLA DE ENTRADAS DE INVENTARIO
-- El agente escribe aqui cuando NEXO emite un EventosSalientes.
-- El agente luego actualiza dbo.TARJETA.EXISTENCIAS directamente.
-- Esta tabla queda como auditoria de todo movimiento de stock desde NEXO.
-- =============================================================================
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NEXO_EntradasInventario')
BEGIN
    CREATE TABLE dbo.NEXO_EntradasInventario (
        EntradaID   INT IDENTITY(1,1) NOT NULL,
        REFERENCIA  NVARCHAR(30)      NOT NULL DEFAULT '',  -- codigo de articulo Visions
        CANTIDAD    DECIMAL(18,4)     NOT NULL DEFAULT 0,   -- positivo=entrada, negativo=salida
        COSTO       DECIMAL(18,4)     NOT NULL DEFAULT 0,
        FECHA       DATETIME          NOT NULL DEFAULT GETDATE(),
        TIPO        NVARCHAR(30)      NOT NULL DEFAULT '',  -- TipoEvento de NEXO
        PROCESADO   BIT               NOT NULL DEFAULT 0,
        CONSTRAINT PK_NEXO_EntradasInventario PRIMARY KEY (EntradaID)
    );
    CREATE INDEX IX_NEXO_EntradasInventario_Procesado ON dbo.NEXO_EntradasInventario (PROCESADO);
    PRINT 'Tabla NEXO_EntradasInventario creada.';
END
ELSE
    PRINT 'NEXO_EntradasInventario ya existe. OK.';
GO

-- =============================================================================
-- SECCIÓN 4: TABLA DE CAMBIOS EN TARJETA + TRIGGER
-- El trigger TR_TARJETA_NexoCambios registra aqui cada vez que Visions POS
-- actualiza EXISTENCIAS (o precios) en dbo.TARJETA.
-- El agente lee estos cambios y actualiza InventarioStock en NEXO
-- como movimiento SALIDA_VENTA_VISIONS.
-- =============================================================================
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NEXO_TarjetasCambios')
BEGIN
    CREATE TABLE dbo.NEXO_TarjetasCambios (
        CambioID        INT IDENTITY(1,1) NOT NULL,
        REFERENCIA      NVARCHAR(30)      NOT NULL DEFAULT '',
        CAMPO           NVARCHAR(50)      NOT NULL DEFAULT '',  -- ej: 'EXISTENCIAS'
        VALOR_ANTERIOR  NVARCHAR(200)     NOT NULL DEFAULT '',
        VALOR_NUEVO     NVARCHAR(200)     NOT NULL DEFAULT '',
        FECHA           DATETIME          NOT NULL DEFAULT GETDATE(),
        PROCESADO       BIT               NOT NULL DEFAULT 0,
        CONSTRAINT PK_NEXO_TarjetasCambios PRIMARY KEY (CambioID)
    );
    CREATE INDEX IX_NEXO_TarjetasCambios_Procesado ON dbo.NEXO_TarjetasCambios (PROCESADO);
    PRINT 'Tabla NEXO_TarjetasCambios creada.';
END
ELSE
    PRINT 'NEXO_TarjetasCambios ya existe. OK.';
GO

-- Trigger: captura cambios de existencias y precios en TARJETA de Visions
IF OBJECT_ID('dbo.TR_TARJETA_NexoCambios', 'TR') IS NOT NULL
    DROP TRIGGER dbo.TR_TARJETA_NexoCambios;
GO

CREATE TRIGGER dbo.TR_TARJETA_NexoCambios
ON dbo.TARJETA
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Capturar cambio de EXISTENCIAS
    IF UPDATE(EXISTENCIAS)
    BEGIN
        INSERT INTO dbo.NEXO_TarjetasCambios (REFERENCIA, CAMPO, VALOR_ANTERIOR, VALOR_NUEVO)
        SELECT
            i.REFERENCIA,
            'EXISTENCIAS',
            CAST(ISNULL(d.EXISTENCIAS, 0) AS NVARCHAR(200)),
            CAST(ISNULL(i.EXISTENCIAS, 0) AS NVARCHAR(200))
        FROM INSERTED i
        JOIN DELETED  d ON d.REFERENCIA = i.REFERENCIA
        WHERE ISNULL(i.EXISTENCIAS, 0) <> ISNULL(d.EXISTENCIAS, 0);
    END

    -- Capturar cambio de PRECIO1 (precio publico)
    IF UPDATE(PRECIO1)
    BEGIN
        INSERT INTO dbo.NEXO_TarjetasCambios (REFERENCIA, CAMPO, VALOR_ANTERIOR, VALOR_NUEVO)
        SELECT
            i.REFERENCIA,
            'PRECIO1',
            CAST(ISNULL(d.PRECIO1, 0) AS NVARCHAR(200)),
            CAST(ISNULL(i.PRECIO1, 0) AS NVARCHAR(200))
        FROM INSERTED i
        JOIN DELETED  d ON d.REFERENCIA = i.REFERENCIA
        WHERE ISNULL(i.PRECIO1, 0) <> ISNULL(d.PRECIO1, 0);
    END
END;
GO
PRINT 'Trigger TR_TARJETA_NexoCambios creado/actualizado.';
GO

-- =============================================================================
-- SECCIÓN 5: TABLA DE CLIENTES / PROVEEDORES
-- NEXO sincroniza clientes y proveedores aqui.
-- Visions los lee para mantener su tabla de USUARIOS actualizada.
-- La columna PROVEEDOR diferencia el rol: 0=cliente, 1=proveedor.
-- Un mismo NIT puede aparecer en ambos roles (un registro por cada rol).
-- =============================================================================
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NEXO_Clientes')
BEGIN
    CREATE TABLE dbo.NEXO_Clientes (
        NexoClienteID   INT IDENTITY(1,1) NOT NULL,
        NIT             NVARCHAR(20)      NOT NULL DEFAULT '',
        NOMBRE          NVARCHAR(100)     NOT NULL DEFAULT '',  -- nombre completo / razon social
        RAZON           NVARCHAR(100)     NOT NULL DEFAULT '',  -- razon social (mismo que NOMBRE para juridica)
        DIRECCION       NVARCHAR(200)     NOT NULL DEFAULT '',
        TELEFONO        NVARCHAR(50)      NOT NULL DEFAULT '',
        EMAIL           NVARCHAR(100)     NOT NULL DEFAULT '',
        CIUDAD          NVARCHAR(50)      NOT NULL DEFAULT '',
        PAISCODIGO      INT               NOT NULL DEFAULT 170, -- 170=Colombia
        PROVEEDOR       BIT               NOT NULL DEFAULT 0,   -- 0=cliente, 1=proveedor
        SINCRONIZADO    BIT               NOT NULL DEFAULT 0,   -- 1=ya aplicado a dbo.USUARIOS
        FechaSync       DATETIME          NOT NULL DEFAULT GETDATE(),
        CONSTRAINT PK_NEXO_Clientes PRIMARY KEY (NexoClienteID),
        CONSTRAINT UQ_NEXO_Clientes_NIT_Rol UNIQUE (NIT, PROVEEDOR)
    );
    CREATE INDEX IX_NEXO_Clientes_Sincronizado ON dbo.NEXO_Clientes (SINCRONIZADO);
    PRINT 'Tabla NEXO_Clientes creada.';
END
ELSE
    PRINT 'NEXO_Clientes ya existe. OK.';
GO

-- =============================================================================
-- SECCIÓN 6: TABLAS DE FACTURAS (NEXO -> VISIONS y VISIONS -> NEXO)
-- NEXO_FacturasSalientes: facturas de NEXO que el agente exporto a Visions.
--   Trigger trg_NEXO_ActualizarFacturaSaliente actualiza el estado cuando
--   Visions confirma el documento (actualiza MOVDETALLES con NRODOC).
--
-- NEXO_FacturasPendientes: facturas que NEXO genera y quiere que Visions
--   las registre. Visions llama SP NEXO_SP_ConfirmarFactura para confirmar.
-- =============================================================================

-- Tabla de facturas exportadas desde NEXO a Visions
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NEXO_FacturasSalientes')
BEGIN
    CREATE TABLE dbo.NEXO_FacturasSalientes (
        FacturaID       INT              NOT NULL,   -- FacturaID en NEXO_ERP
        NIT             NVARCHAR(20)     NOT NULL DEFAULT '',
        NombreCliente   NVARCHAR(100)    NOT NULL DEFAULT '',
        Fecha           DATETIME         NOT NULL DEFAULT GETDATE(),
        NroDocVisions   NVARCHAR(20)     NOT NULL DEFAULT '',  -- NUMDOC del movimiento en Visions
        TipDocVisions   NVARCHAR(5)      NOT NULL DEFAULT '',  -- TIPDOC en Visions (FA, FC, etc.)
        TotalNexo       DECIMAL(18,2)    NOT NULL DEFAULT 0,
        TotalVisions    DECIMAL(18,2)    NOT NULL DEFAULT 0,
        Estado          NVARCHAR(20)     NOT NULL DEFAULT 'PENDIENTE', -- PENDIENTE / PROCESADA / ERROR
        FechaSync       DATETIME         NOT NULL DEFAULT GETDATE(),
        CONSTRAINT PK_NEXO_FacturasSalientes PRIMARY KEY (FacturaID)
    );
    CREATE INDEX IX_NEXO_FacturasSalientes_Estado ON dbo.NEXO_FacturasSalientes (Estado);
    PRINT 'Tabla NEXO_FacturasSalientes creada.';
END
ELSE
    PRINT 'NEXO_FacturasSalientes ya existe. OK.';
GO

-- Trigger: cuando Visions actualiza MOVDETALLES con el numero real de documento,
--          marca la factura en NEXO_FacturasSalientes como PROCESADA.
IF OBJECT_ID('dbo.trg_NEXO_ActualizarFacturaSaliente', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_NEXO_ActualizarFacturaSaliente;
GO

CREATE TRIGGER dbo.trg_NEXO_ActualizarFacturaSaliente
ON dbo.MOVDETALLES
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE fs
    SET
        fs.NroDocVisions = i.NRODOC,
        fs.TipDocVisions = ISNULL(i.TIPDOC, ''),
        fs.TotalVisions  = ISNULL(i.TOTDOC, 0),
        fs.Estado        = 'PROCESADA',
        fs.FechaSync     = GETDATE()
    FROM dbo.NEXO_FacturasSalientes fs
    JOIN INSERTED i ON i.NUMDOC = fs.NroDocVisions
    WHERE ISNULL(i.NRODOC, '') <> ''
      AND fs.Estado = 'PENDIENTE';
END;
GO
PRINT 'Trigger trg_NEXO_ActualizarFacturaSaliente creado/actualizado.';
GO

-- Tabla de facturas pendientes para que Visions procese y confirme
-- NEXO las escribe; Visions las lee con NEXO_SP_FacturasPendientes
-- y confirma con NEXO_SP_ConfirmarFactura.
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NEXO_FacturasPendientes')
BEGIN
    CREATE TABLE dbo.NEXO_FacturasPendientes (
        FacturaID       INT              NOT NULL,    -- FacturaID en NEXO_ERP (clave natural)
        NIT             NVARCHAR(20)     NOT NULL DEFAULT '',
        NombreCliente   NVARCHAR(100)    NOT NULL DEFAULT '',
        Fecha           DATETIME         NOT NULL DEFAULT GETDATE(),
        TipDoc          NVARCHAR(5)      NOT NULL DEFAULT 'FA',  -- tipo de doc solicitado en Visions
        TotalNexo       DECIMAL(18,2)    NOT NULL DEFAULT 0,
        Estado          NVARCHAR(20)     NOT NULL DEFAULT 'PENDIENTE', -- PENDIENTE / PROCESADA / ERROR
        FechaEnvio      DATETIME         NOT NULL DEFAULT GETDATE(),
        TipDocVisions   NVARCHAR(5)      NULL,        -- completado por Visions al confirmar
        NroDocVisions   NVARCHAR(20)     NULL,        -- completado por Visions al confirmar
        FechaProceso    DATETIME         NULL,
        CONSTRAINT PK_NEXO_FacturasPendientes PRIMARY KEY (FacturaID)
    );
    CREATE INDEX IX_NEXO_FacturasPendientes_Estado ON dbo.NEXO_FacturasPendientes (Estado);
    PRINT 'Tabla NEXO_FacturasPendientes creada.';
END
ELSE
    PRINT 'NEXO_FacturasPendientes ya existe. OK.';
GO

-- Lineas de las facturas pendientes
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NEXO_FacturasPendientesLineas')
BEGIN
    CREATE TABLE dbo.NEXO_FacturasPendientesLineas (
        LineaID         INT IDENTITY(1,1) NOT NULL,
        FacturaID       INT               NOT NULL,   -- FK a NEXO_FacturasPendientes
        Orden           INT               NOT NULL DEFAULT 0,
        Referencia      NVARCHAR(30)      NOT NULL DEFAULT '',  -- REFERENCIA en dbo.TARJETA
        Detalle         NVARCHAR(200)     NOT NULL DEFAULT '',
        Cantidad        DECIMAL(18,4)     NOT NULL DEFAULT 0,
        PrecioUnitario  DECIMAL(18,4)     NOT NULL DEFAULT 0,
        Total           DECIMAL(18,2)     NOT NULL DEFAULT 0,
        CONSTRAINT PK_NEXO_FacturasPendientesLineas PRIMARY KEY (LineaID),
        CONSTRAINT FK_NEXO_FPL_FacturasPendientes
            FOREIGN KEY (FacturaID) REFERENCES dbo.NEXO_FacturasPendientes(FacturaID)
    );
    CREATE INDEX IX_NEXO_FacturasPendientesLineas_FacturaID ON dbo.NEXO_FacturasPendientesLineas (FacturaID);
    PRINT 'Tabla NEXO_FacturasPendientesLineas creada.';
END
ELSE
    PRINT 'NEXO_FacturasPendientesLineas ya existe. OK.';
GO

-- =============================================================================
-- SECCIÓN 7: STORED PROCEDURES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- ACTUALIZARTARJETA: actualiza EXISTENCIAS y precios en dbo.TARJETA.
-- El agente NexoSyncAgent llama este SP para sincronizar articulos y stock.
-- IMPORTANTE: el WHERE usa REFERENCIA (no TARJETA ni otro campo).
--             Esta es la version corregida del SP original que tenia el
--             WHERE mal puesto y actualizaba todos los registros.
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.ACTUALIZARTARJETA', 'P') IS NOT NULL
    DROP PROCEDURE dbo.ACTUALIZARTARJETA;
GO

CREATE PROCEDURE dbo.ACTUALIZARTARJETA
    @REFERENCIA     NVARCHAR(30),
    @EXISTENCIAS    DECIMAL(18,4) = NULL,
    @PRECIO1        DECIMAL(18,4) = NULL,
    @PRECIO2        DECIMAL(18,4) = NULL,
    @PRECIO3        DECIMAL(18,4) = NULL,
    @NOMBRE         NVARCHAR(100) = NULL,
    @DETALLE        NVARCHAR(200) = NULL,
    @UNIDAD         NVARCHAR(10)  = NULL,
    @IVA            DECIMAL(5,2)  = NULL,
    @ACTIVO         BIT           = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @REFERENCIA IS NULL OR LTRIM(RTRIM(@REFERENCIA)) = ''
    BEGIN
        RAISERROR('REFERENCIA es obligatoria.', 16, 1);
        RETURN;
    END

    -- Verificar que el articulo existe
    IF NOT EXISTS (SELECT 1 FROM dbo.TARJETA WHERE REFERENCIA = @REFERENCIA)
    BEGIN
        RAISERROR('Articulo con REFERENCIA %s no existe en Visions.', 16, 1, @REFERENCIA);
        RETURN;
    END

    -- Actualizar solo los campos que vienen con valor (actualizacion parcial)
    UPDATE dbo.TARJETA
    SET
        EXISTENCIAS = CASE WHEN @EXISTENCIAS IS NOT NULL THEN @EXISTENCIAS ELSE EXISTENCIAS END,
        PRECIO1     = CASE WHEN @PRECIO1     IS NOT NULL THEN @PRECIO1     ELSE PRECIO1     END,
        PRECIO2     = CASE WHEN @PRECIO2     IS NOT NULL THEN @PRECIO2     ELSE PRECIO2     END,
        PRECIO3     = CASE WHEN @PRECIO3     IS NOT NULL THEN @PRECIO3     ELSE PRECIO3     END,
        NOMBRE      = CASE WHEN @NOMBRE      IS NOT NULL THEN @NOMBRE      ELSE NOMBRE      END,
        DETALLE     = CASE WHEN @DETALLE     IS NOT NULL THEN @DETALLE     ELSE DETALLE     END,
        UNIDAD      = CASE WHEN @UNIDAD      IS NOT NULL THEN @UNIDAD      ELSE UNIDAD      END,
        IVA         = CASE WHEN @IVA         IS NOT NULL THEN @IVA         ELSE IVA         END,
        ACTIVO      = CASE WHEN @ACTIVO      IS NOT NULL THEN @ACTIVO      ELSE ACTIVO      END
    WHERE REFERENCIA = @REFERENCIA;  -- WHERE CRITICO: solo el articulo indicado

    IF @@ROWCOUNT = 0
        RAISERROR('UPDATE sin efecto en REFERENCIA %s.', 16, 1, @REFERENCIA);
END;
GO
PRINT 'SP ACTUALIZARTARJETA creado/actualizado.';
GO

-- -----------------------------------------------------------------------------
-- NEXO_SP_FacturasPendientes: devuelve las facturas pendientes de procesar.
-- Uso: el modulo de Visions que integra con NEXO llama este SP para obtener
-- la lista de facturas que NEXO genero y que Visions debe registrar en su
-- sistema de facturacion.
-- Devuelve: cabecera + lineas en dos result sets.
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.NEXO_SP_FacturasPendientes', 'P') IS NOT NULL
    DROP PROCEDURE dbo.NEXO_SP_FacturasPendientes;
GO

CREATE PROCEDURE dbo.NEXO_SP_FacturasPendientes
    @Top INT = 50   -- maximo de facturas a devolver por llamada
AS
BEGIN
    SET NOCOUNT ON;

    -- Result set 1: cabecera de facturas pendientes
    SELECT TOP (@Top)
        fp.FacturaID,
        ISNULL(fp.NIT, '')           AS NIT,
        ISNULL(fp.NombreCliente, '') AS NombreCliente,
        fp.Fecha,
        ISNULL(fp.TipDoc, 'FA')      AS TipDoc,
        ISNULL(fp.TotalNexo, 0)      AS TotalNexo,
        fp.FechaEnvio
    FROM dbo.NEXO_FacturasPendientes fp
    WHERE fp.Estado = 'PENDIENTE'
    ORDER BY fp.FacturaID ASC;

    -- Result set 2: lineas de esas mismas facturas
    SELECT
        l.FacturaID,
        l.Orden,
        ISNULL(l.Referencia, '')     AS Referencia,
        ISNULL(l.Detalle, '')        AS Detalle,
        ISNULL(l.Cantidad, 0)        AS Cantidad,
        ISNULL(l.PrecioUnitario, 0)  AS PrecioUnitario,
        ISNULL(l.Total, 0)           AS Total
    FROM dbo.NEXO_FacturasPendientesLineas l
    WHERE l.FacturaID IN (
        SELECT TOP (@Top) FacturaID
        FROM dbo.NEXO_FacturasPendientes
        WHERE Estado = 'PENDIENTE'
        ORDER BY FacturaID ASC
    )
    ORDER BY l.FacturaID, l.Orden;
END;
GO
PRINT 'SP NEXO_SP_FacturasPendientes creado/actualizado.';
GO

-- -----------------------------------------------------------------------------
-- NEXO_SP_ConfirmarFactura: Visions llama este SP una vez que registro la
-- factura en su sistema, informando el numero real de documento asignado.
-- El agente NEXO lee el estado PROCESADA y actualiza la factura en NEXO_ERP.
-- Parametros:
--   @FacturaID    = ID de la factura en NEXO (viene de NEXO_FacturasPendientes)
--   @TipDocVisions = tipo de documento Visions (FA, FC, etc.)
--   @NroDocVisions = numero de documento asignado por Visions
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.NEXO_SP_ConfirmarFactura', 'P') IS NOT NULL
    DROP PROCEDURE dbo.NEXO_SP_ConfirmarFactura;
GO

CREATE PROCEDURE dbo.NEXO_SP_ConfirmarFactura
    @FacturaID      INT,
    @TipDocVisions  NVARCHAR(5),
    @NroDocVisions  NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Validar parametros
    IF @FacturaID IS NULL OR @FacturaID <= 0
    BEGIN
        RAISERROR('FacturaID invalido.', 16, 1);
        RETURN;
    END

    IF ISNULL(LTRIM(RTRIM(@NroDocVisions)), '') = ''
    BEGIN
        RAISERROR('NroDocVisions es obligatorio.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM dbo.NEXO_FacturasPendientes WHERE FacturaID = @FacturaID)
    BEGIN
        RAISERROR('Factura ID %d no existe en NEXO_FacturasPendientes.', 16, 1, @FacturaID);
        RETURN;
    END

    DECLARE @EstadoActual NVARCHAR(20);
    SELECT @EstadoActual = Estado FROM dbo.NEXO_FacturasPendientes WHERE FacturaID = @FacturaID;

    IF @EstadoActual = 'PROCESADA'
    BEGIN
        -- Ya confirmada, retornar sin error (idempotente)
        SELECT FacturaID, TipDocVisions, NroDocVisions, Estado, FechaProceso
        FROM dbo.NEXO_FacturasPendientes WHERE FacturaID = @FacturaID;
        RETURN;
    END

    -- Marcar como PROCESADA con los datos del documento Visions
    UPDATE dbo.NEXO_FacturasPendientes
    SET
        Estado          = 'PROCESADA',
        TipDocVisions   = @TipDocVisions,
        NroDocVisions   = @NroDocVisions,
        FechaProceso    = GETDATE()
    WHERE FacturaID = @FacturaID;

    -- Devolver el registro actualizado para que el llamador confirme
    SELECT FacturaID, TipDocVisions, NroDocVisions, Estado, FechaProceso
    FROM dbo.NEXO_FacturasPendientes WHERE FacturaID = @FacturaID;

    PRINT 'Factura ' + CAST(@FacturaID AS NVARCHAR) + ' confirmada como ' + @TipDocVisions + ' ' + @NroDocVisions;
END;
GO
PRINT 'SP NEXO_SP_ConfirmarFactura creado/actualizado.';
GO

-- -----------------------------------------------------------------------------
-- NEXO_SP_MarcarErrorFactura: registra un error si Visions no pudo procesar
-- una factura (NIT no existe, precio invalido, etc.)
-- El agente NEXO detecta el error y puede reintentarlo o alertar al usuario.
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.NEXO_SP_MarcarErrorFactura', 'P') IS NOT NULL
    DROP PROCEDURE dbo.NEXO_SP_MarcarErrorFactura;
GO

CREATE PROCEDURE dbo.NEXO_SP_MarcarErrorFactura
    @FacturaID  INT,
    @Motivo     NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.NEXO_FacturasPendientes
    SET
        Estado       = 'ERROR',
        NroDocVisions = ISNULL(LEFT(@Motivo, 20), 'ERROR'),
        FechaProceso = GETDATE()
    WHERE FacturaID = @FacturaID
      AND Estado    = 'PENDIENTE';

    IF @@ROWCOUNT = 0
        PRINT 'Factura ' + CAST(@FacturaID AS NVARCHAR) + ' no estaba en estado PENDIENTE o no existe.';
    ELSE
        PRINT 'Factura ' + CAST(@FacturaID AS NVARCHAR) + ' marcada como ERROR: ' + ISNULL(@Motivo, '');
END;
GO
PRINT 'SP NEXO_SP_MarcarErrorFactura creado/actualizado.';
GO

-- =============================================================================
-- SECCIÓN 8: VERIFICACION DE OBJETOS CREADOS
-- =============================================================================
PRINT '';
PRINT '======================================================================';
PRINT 'VERIFICACION DE OBJETOS NEXO EN VISIONSDBL1:';
PRINT '======================================================================';

SELECT
    o.type_desc AS Tipo,
    s.name + '.' + o.name AS Nombre,
    o.create_date AS FechaCreacion,
    o.modify_date AS UltimaModificacion
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE s.name = 'dbo'
  AND o.name LIKE 'NEXO%' OR o.name = 'ACTUALIZARTARJETA'
ORDER BY o.type_desc, o.name;

PRINT '';
PRINT 'Tablas con conteo de filas:';
SELECT
    t.name AS Tabla,
    p.rows AS Filas
FROM sys.tables t
JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0,1)
WHERE t.name LIKE 'NEXO%'
ORDER BY t.name;

PRINT '';
PRINT '======================================================================';
PRINT 'RESUMEN DE OBJETOS CREADOS:';
PRINT '';
PRINT '  TABLAS (8):';
PRINT '    dbo.NEXO_ConfiguracionSync        - Configuracion de sincronizacion';
PRINT '    dbo.NEXO_VentasExportadas         - Ventas de Visions importadas a NEXO';
PRINT '    dbo.NEXO_EntradasInventario       - Auditoria de movimientos de stock';
PRINT '    dbo.NEXO_TarjetasCambios          - Cambios capturados por trigger';
PRINT '    dbo.NEXO_Clientes                 - Clientes y proveedores sincronizados';
PRINT '    dbo.NEXO_FacturasSalientes        - Facturas NEXO exportadas a Visions';
PRINT '    dbo.NEXO_FacturasPendientes       - Facturas NEXO que Visions debe procesar';
PRINT '    dbo.NEXO_FacturasPendientesLineas - Lineas de facturas pendientes';
PRINT '';
PRINT '  TRIGGERS (2):';
PRINT '    dbo.TR_TARJETA_NexoCambios            - Captura cambios en dbo.TARJETA';
PRINT '    dbo.trg_NEXO_ActualizarFacturaSaliente - Actualiza estado factura exportada';
PRINT '';
PRINT '  STORED PROCEDURES (4):';
PRINT '    dbo.ACTUALIZARTARJETA           - Actualiza articulo/existencias (usa el agente)';
PRINT '    dbo.NEXO_SP_FacturasPendientes  - Lee facturas pendientes (usa Visions)';
PRINT '    dbo.NEXO_SP_ConfirmarFactura    - Confirma factura procesada (usa Visions)';
PRINT '    dbo.NEXO_SP_MarcarErrorFactura  - Registra error de procesamiento (usa Visions)';
PRINT '';
PRINT '  FLUJO DE INTEGRACION:';
PRINT '    1. Agente arrancar -> TareaInicializarVisions crea todos estos objetos';
PRINT '    2. NEXO genera movimientos -> EventosSalientes -> Agente -> ACTUALIZARTARJETA';
PRINT '    3. Visions POS vende -> TR_TARJETA_NexoCambios -> Agente detecta -> NEXO';
PRINT '    4. NEXO factura -> NEXO_FacturasPendientes -> Visions NEXO_SP_FacturasPendientes';
PRINT '    5. Visions procesa -> NEXO_SP_ConfirmarFactura -> Agente actualiza NEXO';
PRINT '======================================================================';
GO
