-- =============================================================================
-- compat_nexovisions.sql
-- Base   : VISIONSDBL1 en .\JONATHAN (o cualquier instancia Visions)
-- Objeto : Instalar TODOS los objetos que NEXO crea en visionsdbl1.
--          Fuente autoritativa: NexoSyncAgent\Tareas\TareaInicializarVisions.cs
-- Uso    : Ejecutar COMPLETO en SSMS contra VISIONSDBL1.
--          Idempotente: usa IF NOT EXISTS / IF OBJECT_ID en cada objeto.
--          El agente ejecuta TareaInicializarVisions al arrancar y crea estos
--          mismos objetos; este script sirve para instalacion manual o DR.
-- NOTA   : Visions NO acepta NULL en texto ni numericos fuera de columnas
--          explicitamente NULLables. ACTUALIZARTARJETA usa ISNULL en cada param.
-- =============================================================================
USE VISIONSDBL1;
GO

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
PRINT 'Iniciando instalacion objetos NEXO en VISIONSDBL1...';
PRINT 'Fecha: ' + CONVERT(NVARCHAR(30), GETDATE(), 120);
GO

-- =============================================================================
-- SECCION 1: NEXO_ConfiguracionSync
-- Configuracion de la sincronizacion, una fila por CentroCosto.
-- =============================================================================
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NEXO_ConfiguracionSync')
    CREATE TABLE dbo.NEXO_ConfiguracionSync (
        CENTROCOSTO         INT           NOT NULL CONSTRAINT PK_NEXO_ConfiguracionSync PRIMARY KEY,
        Activo              BIT           NOT NULL DEFAULT 1,
        TiposDocumentoVenta NVARCHAR(500) NULL
    );
GO
PRINT 'NEXO_ConfiguracionSync OK.';
GO

-- =============================================================================
-- SECCION 2: NEXO_VentasExportadas
-- Log de deduplicacion: ventas de Visions ya exportadas a NEXO.
-- PK compuesta evita que el agente exporte la misma linea dos veces.
-- =============================================================================
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NEXO_VentasExportadas')
    CREATE TABLE dbo.NEXO_VentasExportadas (
        CENTROCOSTO INT           NOT NULL,
        TIPDOC      NVARCHAR(20)  NOT NULL,
        NRODOC      NVARCHAR(50)  NOT NULL,
        ORDEN       INT           NOT NULL,
        REFERENCIA  NVARCHAR(30)  NOT NULL,
        CANTIDAD    DECIMAL(18,4) NOT NULL,
        CONSTRAINT PK_NEXO_VentasExportadas PRIMARY KEY (CENTROCOSTO, TIPDOC, NRODOC, ORDEN, REFERENCIA)
    );
GO
PRINT 'NEXO_VentasExportadas OK.';
GO

-- =============================================================================
-- SECCION 3: NEXO_EntradasExportadas
-- Log de deduplicacion: entradas de Visions ya exportadas a NEXO.
-- =============================================================================
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NEXO_EntradasExportadas')
    CREATE TABLE dbo.NEXO_EntradasExportadas (
        CENTROCOSTO INT           NOT NULL,
        TIPDOC      NVARCHAR(20)  NOT NULL,
        NRODOC      NVARCHAR(50)  NOT NULL,
        ORDEN       INT           NOT NULL,
        REFERENCIA  NVARCHAR(30)  NOT NULL,
        CANTIDAD    DECIMAL(18,4) NOT NULL,
        CONSTRAINT PK_NEXO_EntradasExportadas PRIMARY KEY (CENTROCOSTO, TIPDOC, NRODOC, ORDEN, REFERENCIA)
    );
GO
PRINT 'NEXO_EntradasExportadas OK.';
GO

-- =============================================================================
-- SECCION 4: NEXO_EntradasInventario
-- Auditoria de movimientos de stock aplicados desde NEXO a Visions.
-- =============================================================================
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NEXO_EntradasInventario')
    CREATE TABLE dbo.NEXO_EntradasInventario (
        Id             BIGINT        NOT NULL IDENTITY CONSTRAINT PK_NEXO_EntradasInventario PRIMARY KEY,
        IdEventoOrigen BIGINT        NOT NULL,
        CENTROCOSTO    INT           NOT NULL,
        REFERENCIA     NVARCHAR(30)  NOT NULL,
        CANTIDAD       DECIMAL(18,4) NOT NULL,
        COSTO          DECIMAL(18,4) NOT NULL DEFAULT 0,
        Aplicado       BIT           NOT NULL DEFAULT 1,
        FechaAplicado  DATETIME      NOT NULL DEFAULT GETDATE()
    );
GO
PRINT 'NEXO_EntradasInventario OK.';
GO

-- =============================================================================
-- SECCION 5: NEXO_TarjetasCambios + Trigger TR_TARJETA_NexoCambios
-- El trigger captura cambios de precio/detalle en dbo.TARJETA originados en
-- Visions POS. El agente lee estos cambios y sincroniza de vuelta a NEXO.
-- MERGE upserta para evitar acumulacion de filas pendientes por el mismo articulo.
-- APP_NAME()='NexoSyncAgent' identifica conexiones del agente (evita eco).
-- =============================================================================
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NEXO_TarjetasCambios')
    CREATE TABLE dbo.NEXO_TarjetasCambios (
        Id          BIGINT        NOT NULL IDENTITY CONSTRAINT PK_NEXO_TarjetasCambios PRIMARY KEY,
        CENTROCOSTO INT           NOT NULL,
        REFERENCIA  NVARCHAR(30)  NOT NULL,
        DETALLE     NVARCHAR(200) NULL,
        COSTO       DECIMAL(18,4) NULL,
        PPUBLICO    DECIMAL(18,4) NULL,
        VV3         SMALLINT      NULL,
        FechaCambio DATETIME      NOT NULL DEFAULT GETDATE(),
        Procesado   BIT           NOT NULL DEFAULT 0
    );
GO

-- Migracion: agregar columna VV3 si tabla existia sin ella.
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'NEXO_TarjetasCambios' AND COLUMN_NAME = 'VV3'
)
    ALTER TABLE dbo.NEXO_TarjetasCambios ADD VV3 SMALLINT NULL;
GO

-- Crear trigger stub si no existe, luego ALTER con logica real.
-- (CREATE OR ALTER requiere SQL 2016+; stub+ALTER compatible con 2008+.)
IF OBJECT_ID('dbo.TR_TARJETA_NexoCambios', 'TR') IS NULL
    EXEC('CREATE TRIGGER dbo.TR_TARJETA_NexoCambios ON dbo.TARJETA AFTER UPDATE AS SELECT 1');
GO

ALTER TRIGGER dbo.TR_TARJETA_NexoCambios ON dbo.TARJETA AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF APP_NAME() = 'NexoSyncAgent' RETURN;
    MERGE dbo.NEXO_TarjetasCambios AS destino
    USING (
        SELECT i.CENTROCOSTO, i.REFERENCIA, i.DETALLE, i.COSTO, i.PPUBLICO,
               CAST(i.VV3 AS SMALLINT) AS VV3, GETDATE() AS FechaCambio
        FROM inserted i
    ) AS origen
    ON destino.CENTROCOSTO = origen.CENTROCOSTO
       AND destino.REFERENCIA = origen.REFERENCIA
       AND destino.Procesado = 0
    WHEN MATCHED THEN UPDATE SET
        DETALLE = origen.DETALLE, COSTO = origen.COSTO,
        PPUBLICO = origen.PPUBLICO, VV3 = origen.VV3, FechaCambio = origen.FechaCambio
    WHEN NOT MATCHED THEN
        INSERT (CENTROCOSTO, REFERENCIA, DETALLE, COSTO, PPUBLICO, VV3, FechaCambio, Procesado)
        VALUES (origen.CENTROCOSTO, origen.REFERENCIA, origen.DETALLE, origen.COSTO,
                origen.PPUBLICO, origen.VV3, origen.FechaCambio, 0);
END;
GO
PRINT 'NEXO_TarjetasCambios + TR_TARJETA_NexoCambios OK.';
GO

-- =============================================================================
-- SECCION 6: NEXO_FacturasSalientes
-- Rastreo de facturas generadas en NEXO que ya se confirmaron en Visions.
-- FechaSyncBack NULL = pendiente de sincronizar de vuelta a NEXO_ERP.
-- =============================================================================
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NEXO_FacturasSalientes')
    CREATE TABLE dbo.NEXO_FacturasSalientes (
        FacturaID     INT         NOT NULL CONSTRAINT PK_NEXO_FacturasSalientes PRIMARY KEY,
        NexoNroDoc    VARCHAR(50) NOT NULL,
        TipDocVisions VARCHAR(20) NULL,
        NroDocVisions VARCHAR(50) NULL,
        FechaEnvio    DATETIME    NOT NULL DEFAULT GETDATE(),
        FechaSyncBack DATETIME    NULL
    );
GO

-- Eliminar trigger obsoleto del flujo anterior (ya no se usa).
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'trg_NEXO_ActualizarFacturaSaliente')
    DROP TRIGGER dbo.trg_NEXO_ActualizarFacturaSaliente;
GO
PRINT 'NEXO_FacturasSalientes OK (trigger obsoleto eliminado si existia).';
GO

-- =============================================================================
-- SECCION 7: TIPOPRODUCTO_TIPOS
-- Tipos de producto (PT/MP/IN/SER). TipoID se guarda en TARJETA.VV3.
-- =============================================================================
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'TIPOPRODUCTO_TIPOS')
BEGIN
    CREATE TABLE dbo.TIPOPRODUCTO_TIPOS (
        TipoID smallint      NOT NULL CONSTRAINT PK_TIPOPRODUCTO_TIPOS PRIMARY KEY,
        Codigo nvarchar(10)  NOT NULL,
        Nombre nvarchar(100) NOT NULL
    );
    INSERT INTO dbo.TIPOPRODUCTO_TIPOS VALUES (1, 'PT',  'Producto Terminado');
    INSERT INTO dbo.TIPOPRODUCTO_TIPOS VALUES (2, 'MP',  'Materia Prima');
    INSERT INTO dbo.TIPOPRODUCTO_TIPOS VALUES (3, 'IN',  'Insumo');
    INSERT INTO dbo.TIPOPRODUCTO_TIPOS VALUES (4, 'SER', 'Servicio');
END
GO

-- Migracion: corregir codigo SV->SER en bases ya existentes.
IF EXISTS (SELECT 1 FROM dbo.TIPOPRODUCTO_TIPOS WHERE Codigo = 'SV')
    UPDATE dbo.TIPOPRODUCTO_TIPOS SET Codigo = 'SER' WHERE Codigo = 'SV';
GO
PRINT 'TIPOPRODUCTO_TIPOS OK.';
GO

-- =============================================================================
-- SECCION 8: NEXO_FacturasPendientes + NEXO_FacturasPendientesLineas
-- Staging de facturas generadas en NEXO que Visions debe registrar.
-- Visions lee con NEXO_SP_FacturasPendientes y confirma con NEXO_SP_ConfirmarFactura.
-- =============================================================================
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NEXO_FacturasPendientes')
    CREATE TABLE dbo.NEXO_FacturasPendientes (
        FacturaID       INT           NOT NULL CONSTRAINT PK_NEXO_FacturasPendientes PRIMARY KEY,
        NIT             NVARCHAR(30)  NOT NULL,
        NombreCliente   NVARCHAR(200) NOT NULL,
        Fecha           DATE          NOT NULL,
        TipDoc          NVARCHAR(20)  NOT NULL,
        TotalNexo       DECIMAL(18,4) NOT NULL DEFAULT 0,
        Estado          NVARCHAR(20)  NOT NULL DEFAULT 'PENDIENTE',
        FechaEnvio      DATETIME      NOT NULL DEFAULT GETDATE(),
        NroDocVisions   NVARCHAR(50)  NULL,
        TipDocVisions   NVARCHAR(20)  NULL,
        FechaConfirmada DATETIME      NULL
    );
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NEXO_FacturasPendientesLineas')
    CREATE TABLE dbo.NEXO_FacturasPendientesLineas (
        FacturaID      INT           NOT NULL,
        Orden          INT           NOT NULL,
        Referencia     NVARCHAR(30)  NOT NULL,
        Detalle        NVARCHAR(255) NULL,
        Cantidad       DECIMAL(18,4) NOT NULL DEFAULT 0,
        PrecioUnitario DECIMAL(18,4) NOT NULL DEFAULT 0,
        Total          DECIMAL(18,4) NOT NULL DEFAULT 0,
        CONSTRAINT PK_NEXO_FacturasPendientesLineas PRIMARY KEY (FacturaID, Orden)
    );
GO
PRINT 'NEXO_FacturasPendientes + Lineas OK.';
GO

-- =============================================================================
-- SECCION 9: NEXO_Pedidos + NEXO_PedidosLineas
-- Staging de ordenes de compra de NEXO que Visions debe registrar como Entradas.
-- Visions lee con NEXO_SP_PedidosPendientes y confirma con NEXO_SP_ConfirmarPedido.
-- =============================================================================
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NEXO_Pedidos')
    CREATE TABLE dbo.NEXO_Pedidos (
        PedidoID        INT           NOT NULL CONSTRAINT PK_NEXO_Pedidos PRIMARY KEY,
        Codigo          NVARCHAR(50)  NOT NULL DEFAULT '',
        NombreProveedor NVARCHAR(200) NOT NULL DEFAULT '',
        NITProveedor    NVARCHAR(30)  NOT NULL DEFAULT '',
        Fecha           DATE          NOT NULL,
        TotalNexo       DECIMAL(18,4) NOT NULL DEFAULT 0,
        TipoMovimiento  NVARCHAR(20)  NOT NULL DEFAULT 'COMPRA',
        Estado          NVARCHAR(20)  NOT NULL DEFAULT 'PENDIENTE',
        FechaEnvio      DATETIME      NOT NULL DEFAULT GETDATE(),
        NroDocVisions   NVARCHAR(50)  NULL,
        TipDocVisions   NVARCHAR(20)  NULL,
        FechaConfirmada DATETIME      NULL
    );
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NEXO_PedidosLineas')
    CREATE TABLE dbo.NEXO_PedidosLineas (
        PedidoID       INT           NOT NULL,
        Orden          INT           NOT NULL,
        Referencia     NVARCHAR(30)  NOT NULL,
        Detalle        NVARCHAR(255) NULL,
        Cantidad       DECIMAL(18,4) NOT NULL DEFAULT 0,
        PrecioUnitario DECIMAL(18,4) NOT NULL DEFAULT 0,
        Total          DECIMAL(18,4) NOT NULL DEFAULT 0,
        CONSTRAINT PK_NEXO_PedidosLineas PRIMARY KEY (PedidoID, Orden)
    );
GO
PRINT 'NEXO_Pedidos + PedidosLineas OK.';
GO

-- =============================================================================
-- SECCION 10: STORED PROCEDURES
-- Todos usan stub IF IS NULL + ALTER para compatibilidad SQL 2008+.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- ACTUALIZARTARJETA
-- El agente llama este SP para sincronizar articulos y existencias.
-- WHERE usa @CENTROCOSTO + @REFERENCIA (critico: sin esto actualiza toda la tabla).
-- ISNULL en cada campo evita escribir NULL en columnas no-nulables de TARJETA.
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.ACTUALIZARTARJETA', 'P') IS NULL
    EXEC('CREATE PROCEDURE dbo.ACTUALIZARTARJETA AS SELECT 1');
GO

ALTER PROCEDURE [dbo].ACTUALIZARTARJETA
(
    @CENTROCOSTO smallint, @REFERENCIA nchar(30), @DETALLE nchar(255), @MARCA nchar(10),
    @COSTO numeric(18,0), @GRUPOMENOR nchar(10), @BARRAS nchar(30),
    @IVASINO nchar(2), @IVAVALOR smallint,
    @EXISTENCIAS numeric(18,0), @EXISTENCIASMINIMAS numeric(18,0),
    @FRACCIONES numeric(18,0), @CANTIDAD numeric(18,0),
    @PRESENTACION nchar(10), @VALORIZADO numeric(18,0),
    @PPUBLICO numeric(18,0), @PBODEGA numeric(18,0), @PCREDITO numeric(18,0),
    @UPUBLICO numeric(18,2), @UBODEGA numeric(18,2), @UCREDITO numeric(18,2),
    @FRACCIONA nchar(1),
    @VF1 numeric(18,0), @VV1 numeric(18,0), @VF2 numeric(18,0), @VV2 numeric(18,0),
    @VF3 numeric(18,0), @VV3 numeric(18,0), @VF4 numeric(18,0), @VV4 numeric(18,0),
    @TIPOTARJETA nchar(12),
    @ROTA1 numeric(18,0), @ROTA2 numeric(18,0), @SUGERIDO numeric(18,0),
    @FISICOE numeric(18,0), @FISICOF numeric(18,0), @COMBO numeric(18,0),
    @FULTV date, @FULTC date, @REVISAR nchar(10), @NOTA ntext,
    @PESO numeric(18,2), @DFI date, @DFF date,
    @DPO smallint, @DVA numeric(18,0), @PESAR nchar(2)
)
AS
SET NOCOUNT OFF;
UPDATE [dbo].[TARJETA] SET
    [CENTROCOSTO]       = @CENTROCOSTO,
    [DETALLE]           = ISNULL(@DETALLE, ''),
    [MARCA]             = ISNULL(@MARCA, ''),
    [COSTO]             = ISNULL(@COSTO, 0),
    [GRUPOMENOR]        = ISNULL(@GRUPOMENOR, ''),
    [BARRAS]            = ISNULL(@BARRAS, ''),
    [IVASINO]           = ISNULL(@IVASINO, 'SI'),
    [IVAVALOR]          = ISNULL(@IVAVALOR, 19),
    [EXISTENCIAS]       = ISNULL(@EXISTENCIAS, 0),
    [EXISTENCIASMINIMAS]= ISNULL(@EXISTENCIASMINIMAS, 0),
    [FRACCIONES]        = ISNULL(@FRACCIONES, 0),
    [CANTIDAD]          = ISNULL(@CANTIDAD, 0),
    [PRESENTACION]      = ISNULL(@PRESENTACION, ''),
    [VALORIZADO]        = ISNULL(@VALORIZADO, 0),
    [PPUBLICO]          = ISNULL(@PPUBLICO, 0),
    [PBODEGA]           = ISNULL(@PBODEGA, 0),
    [PCREDITO]          = ISNULL(@PCREDITO, 0),
    [UPUBLICO]          = ISNULL(@UPUBLICO, 0),
    [UBODEGA]           = ISNULL(@UBODEGA, 0),
    [UCREDITO]          = ISNULL(@UCREDITO, 0),
    [FRACCIONA]         = ISNULL(@FRACCIONA, ''),
    [VF1]  = ISNULL(@VF1, 0), [VV1] = ISNULL(@VV1, 0),
    [VF2]  = ISNULL(@VF2, 0), [VV2] = ISNULL(@VV2, 0),
    [VF3]  = ISNULL(@VF3, 0), [VV3] = ISNULL(@VV3, 0),
    [VF4]  = ISNULL(@VF4, 0), [VV4] = ISNULL(@VV4, 0),
    [TIPOTARJETA]       = ISNULL(@TIPOTARJETA, ''),
    [ROTA1]             = ISNULL(@ROTA1, 0), [ROTA2] = ISNULL(@ROTA2, 0),
    [SUGERIDO]          = ISNULL(@SUGERIDO, 0),
    [FISICOE]           = ISNULL(@FISICOE, 0), [FISICOF] = ISNULL(@FISICOF, 0),
    [COMBO]             = ISNULL(@COMBO, 0),
    [FULTV]             = ISNULL(@FULTV, '2000-01-01'),
    [FULTC]             = ISNULL(@FULTC, '2000-01-01'),
    [REVISAR]           = ISNULL(@REVISAR, ''),
    [NOTA]              = ISNULL(@NOTA, N''),
    [PESO]              = ISNULL(@PESO, 0),
    [DFI]               = ISNULL(@DFI, '2000-01-01'),
    [DFF]               = ISNULL(@DFF, '2099-12-31'),
    [DPO]               = ISNULL(@DPO, 0),
    [DVA]               = ISNULL(@DVA, 0),
    [PESAR]             = ISNULL(@PESAR, '')
WHERE [CENTROCOSTO] = @CENTROCOSTO AND [REFERENCIA] = @REFERENCIA;
GO
PRINT 'SP ACTUALIZARTARJETA OK.';
GO

-- -----------------------------------------------------------------------------
-- NEXO_SP_FacturasPendientes
-- Devuelve dos resultsets: cabeceras y lineas de facturas en estado PENDIENTE.
-- Visions llama este SP desde el modulo de integracion NEXO.
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.NEXO_SP_FacturasPendientes', 'P') IS NULL
    EXEC('CREATE PROCEDURE dbo.NEXO_SP_FacturasPendientes AS SELECT 1');
GO

ALTER PROCEDURE dbo.NEXO_SP_FacturasPendientes
AS
BEGIN
    SET NOCOUNT ON;
    SELECT FacturaID, NIT, NombreCliente, Fecha, TipDoc, TotalNexo, FechaEnvio
    FROM dbo.NEXO_FacturasPendientes
    WHERE Estado = 'PENDIENTE'
    ORDER BY Fecha, FacturaID;

    SELECT l.FacturaID, l.Orden, l.Referencia, l.Detalle, l.Cantidad, l.PrecioUnitario, l.Total
    FROM dbo.NEXO_FacturasPendientesLineas l
    INNER JOIN dbo.NEXO_FacturasPendientes f ON f.FacturaID = l.FacturaID
    WHERE f.Estado = 'PENDIENTE'
    ORDER BY l.FacturaID, l.Orden;
END;
GO
PRINT 'SP NEXO_SP_FacturasPendientes OK.';
GO

-- -----------------------------------------------------------------------------
-- NEXO_SP_ConfirmarFactura
-- Visions llama este SP al registrar la factura, pasando el numero real asignado.
-- El agente detecta Estado='PROCESADA' y actualiza la factura en NEXO_ERP.
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.NEXO_SP_ConfirmarFactura', 'P') IS NULL
    EXEC('CREATE PROCEDURE dbo.NEXO_SP_ConfirmarFactura @FacturaID INT, @NroDocVisions NVARCHAR(50), @TipDocVisions NVARCHAR(20) AS SELECT 1');
GO

ALTER PROCEDURE dbo.NEXO_SP_ConfirmarFactura
    @FacturaID     INT,
    @NroDocVisions NVARCHAR(50),
    @TipDocVisions NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.NEXO_FacturasPendientes
    SET Estado          = 'PROCESADA',
        NroDocVisions   = @NroDocVisions,
        TipDocVisions   = @TipDocVisions,
        FechaConfirmada = GETDATE()
    WHERE FacturaID = @FacturaID;
END;
GO
PRINT 'SP NEXO_SP_ConfirmarFactura OK.';
GO

-- -----------------------------------------------------------------------------
-- NEXO_SP_PedidosPendientes
-- Devuelve dos resultsets: cabeceras y lineas de pedidos en estado PENDIENTE.
-- Visions llama este SP desde el modulo de Entradas NEXO.
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.NEXO_SP_PedidosPendientes', 'P') IS NULL
    EXEC('CREATE PROCEDURE dbo.NEXO_SP_PedidosPendientes AS SELECT 1');
GO

ALTER PROCEDURE dbo.NEXO_SP_PedidosPendientes
AS
BEGIN
    SET NOCOUNT ON;
    SELECT PedidoID, Codigo, NombreProveedor, NITProveedor, Fecha, TotalNexo, TipoMovimiento, FechaEnvio
    FROM dbo.NEXO_Pedidos
    WHERE Estado = 'PENDIENTE'
    ORDER BY Fecha, PedidoID;

    SELECT l.PedidoID, l.Orden, l.Referencia, l.Detalle, l.Cantidad, l.PrecioUnitario, l.Total
    FROM dbo.NEXO_PedidosLineas l
    INNER JOIN dbo.NEXO_Pedidos p ON p.PedidoID = l.PedidoID
    WHERE p.Estado = 'PENDIENTE'
    ORDER BY l.PedidoID, l.Orden;
END;
GO
PRINT 'SP NEXO_SP_PedidosPendientes OK.';
GO

-- -----------------------------------------------------------------------------
-- NEXO_SP_ConfirmarPedido
-- Visions llama este SP al registrar la entrada, pasando el numero real asignado.
-- -----------------------------------------------------------------------------
IF OBJECT_ID('dbo.NEXO_SP_ConfirmarPedido', 'P') IS NULL
    EXEC('CREATE PROCEDURE dbo.NEXO_SP_ConfirmarPedido @PedidoID INT, @NroDocVisions NVARCHAR(50), @TipDocVisions NVARCHAR(20) AS SELECT 1');
GO

ALTER PROCEDURE dbo.NEXO_SP_ConfirmarPedido
    @PedidoID      INT,
    @NroDocVisions NVARCHAR(50),
    @TipDocVisions NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.NEXO_Pedidos
    SET Estado          = 'PROCESADA',
        NroDocVisions   = @NroDocVisions,
        TipDocVisions   = @TipDocVisions,
        FechaConfirmada = GETDATE()
    WHERE PedidoID = @PedidoID;
END;
GO
PRINT 'SP NEXO_SP_ConfirmarPedido OK.';
GO

-- =============================================================================
-- SECCION 11: PARAMETROS requeridos por Visions para la integracion NEXO
-- 1518 (SINCANTSA): habilita busqueda de cantidades al grabar salidas.
-- 1905 (NEXO): activa combo TipoProducto en FRMTARJETA y btn_nexo en FRMVENTAS.
-- =============================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.PARAMETROS WHERE CONSECUTIVO = 1518)
    INSERT INTO dbo.PARAMETROS (CONSECUTIVO, PARAMETRO, VALOR, DESCRIPCION, TIPOGRUPO)
    VALUES (1518, 'SINCANTSA', '0', 'BUSCAR CANTIDADES AL GRABAR SALIDAS', 'HABILITAR');

IF NOT EXISTS (SELECT 1 FROM dbo.PARAMETROS WHERE CONSECUTIVO = 1905)
    INSERT INTO dbo.PARAMETROS (CONSECUTIVO, PARAMETRO, VALOR, DESCRIPCION, TIPOGRUPO)
    VALUES (1905, 'NEXO', '1', 'MANEJAN NEXO', 'HABILITAR')
ELSE IF EXISTS (SELECT 1 FROM dbo.PARAMETROS WHERE CONSECUTIVO = 1905 AND VALOR = '0')
    UPDATE dbo.PARAMETROS SET VALOR = '1' WHERE CONSECUTIVO = 1905;
GO
PRINT 'PARAMETROS 1518 (SINCANTSA) y 1905 (NEXO) OK.';
GO

-- =============================================================================
-- SECCION 12: SANEAMIENTO DE DATOS (aplica en instalacion inicial)
-- Corrige NULLs heredados en NEXO_TarjetasCambios y fechas NULL en TARJETA.
-- Dapper falla con DateTime NULL si el campo no es Nullable<DateTime> en C#.
-- Fechas NULL en TARJETA impiden que Visions muestre el articulo en ventas.
-- =============================================================================
UPDATE dbo.NEXO_TarjetasCambios
SET FechaCambio = GETDATE()
WHERE Procesado = 0 AND FechaCambio IS NULL;

UPDATE dbo.TARJETA
SET FULTV = ISNULL(FULTV, '2000-01-01'),
    FULTC = ISNULL(FULTC, '2000-01-01'),
    DFI   = ISNULL(DFI,   '2000-01-01'),
    DFF   = ISNULL(DFF,   '2099-12-31')
WHERE FULTV IS NULL OR FULTC IS NULL OR DFI IS NULL OR DFF IS NULL;
GO
PRINT 'Saneamiento de NULLs OK.';
GO

-- =============================================================================
-- VERIFICACION FINAL
-- =============================================================================
PRINT '';
PRINT '=== VERIFICACION DE OBJETOS NEXO EN VISIONSDBL1 ===';

SELECT
    o.type_desc AS Tipo,
    o.name AS Nombre,
    o.create_date AS Creado,
    o.modify_date AS Modificado
FROM sys.objects o
WHERE o.name LIKE 'NEXO%'
   OR o.name = 'ACTUALIZARTARJETA'
   OR o.name = 'TIPOPRODUCTO_TIPOS'
   OR o.name = 'TR_TARJETA_NexoCambios'
ORDER BY o.type_desc, o.name;

PRINT '';
PRINT 'RESUMEN DE OBJETOS:';
PRINT '  TABLAS (9): NEXO_ConfiguracionSync, NEXO_VentasExportadas, NEXO_EntradasExportadas,';
PRINT '              NEXO_EntradasInventario, NEXO_TarjetasCambios, NEXO_FacturasSalientes,';
PRINT '              NEXO_FacturasPendientes, NEXO_FacturasPendientesLineas,';
PRINT '              NEXO_Pedidos, NEXO_PedidosLineas, TIPOPRODUCTO_TIPOS';
PRINT '  TRIGGERS (1): TR_TARJETA_NexoCambios (sobre dbo.TARJETA)';
PRINT '  SPS (5): ACTUALIZARTARJETA, NEXO_SP_FacturasPendientes, NEXO_SP_ConfirmarFactura,';
PRINT '           NEXO_SP_PedidosPendientes, NEXO_SP_ConfirmarPedido';
PRINT '  PARAMETROS: 1518 (SINCANTSA), 1905 (NEXO)';
PRINT '  TRIGGER ELIMINADO: trg_NEXO_ActualizarFacturaSaliente (flujo viejo)';
PRINT '=== FIN ===';
GO
