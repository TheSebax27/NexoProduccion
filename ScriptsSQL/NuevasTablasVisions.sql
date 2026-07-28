/* ============================================================================
   INTEGRACION NEXO <-> VISIONS
   Script para ejecutar en la base de datos de VISIONS de cada cliente
   (la misma que vino en VisionsInicial.sql / INICIAVISIONS2026.bak).

   REGLA DE ORO DE ESTE SCRIPT:
     - NO se hace ALTER TABLE sobre ninguna tabla existente de Visions.
     - NO se crean triggers, funciones ni stored procedures — Visions no
       tiene ninguno en toda su base, y este script tampoco agrega ninguno.
     - Solo se agregan tablas NUEVAS (prefijo NEXO_). Toda la logica de
       aplicar/leer datos vive en el Agente de Sincronizacion externo.
     - Todo lo que se necesita LEER de Visions (MOVDETALLES) se lee con
       SELECT normal desde el agente de sincronizacion; no se agrega nada
       sobre esa tabla.

   Basado en la revision real de VisionsInicial.sql:
     - TARJETA(CENTROCOSTO smallint, REFERENCIA nvarchar(30), ..., EXISTENCIAS numeric(18,2))
       es el maestro de producto + stock. PK(CENTROCOSTO, REFERENCIA).
     - MOVDETALLES(CENTROCOSTO, TIPDOC, NRODOC, ORDEN, REFERENCIA, CANTIDAD, ...)
       es el detalle de documentos (ventas, devoluciones, etc.), sin PK.
   ============================================================================ */

-- ----------------------------------------------------------------------------
-- Configuracion minima de la integracion, por centro de costo (sucursal).
-- Aqui defines que tipos de documento de MOVDETALLES cuentan como "venta
-- real" que debe descontarse/reportarse a Produccion NEXO.
-- ----------------------------------------------------------------------------
CREATE TABLE dbo.NEXO_ConfiguracionSync (
    CENTROCOSTO             SMALLINT NOT NULL PRIMARY KEY,
    Activo                  BIT NOT NULL DEFAULT 1,
    TiposDocumentoVenta     NVARCHAR(100) NULL, -- ej: 'FV,NV' (codigos de TIPDOC que se consideran venta; AJUSTAR segun TIPODOCUMENTO real del cliente)
    UltimaFechaExportada    DATETIME NULL,
    UltimaHoraExportada     NVARCHAR(20) NULL,
    FechaCreacion           DATETIME NOT NULL DEFAULT GETDATE()
);
GO

-- ----------------------------------------------------------------------------
-- Cola de ENTRADA de inventario: la llena el agente de sincronizacion con lo
-- que Produccion NEXO ya decidio que entro a esta sucursal (cierre de OP o
-- traspaso recibido). Nadie mas que el agente escribe aqui.
-- ----------------------------------------------------------------------------
CREATE TABLE dbo.NEXO_EntradasInventario (
    Id                  BIGINT IDENTITY(1,1) PRIMARY KEY,
    IdEventoOrigen      BIGINT NOT NULL,        -- EventoID de Integracion.EventosSalientes en NEXO
    CENTROCOSTO         SMALLINT NOT NULL,
    REFERENCIA          NVARCHAR(30) NOT NULL,
    CANTIDAD            NUMERIC(18,2) NOT NULL,
    COSTO               NUMERIC(18,2) NULL,
    FechaRecepcion      DATETIME NOT NULL DEFAULT GETDATE(),
    Aplicado            BIT NOT NULL DEFAULT 0,
    FechaAplicado       DATETIME NULL,
    Error               NVARCHAR(500) NULL,
    CONSTRAINT UQ_NEXO_EntradasInventario_Origen UNIQUE (IdEventoOrigen)
);
GO

-- ----------------------------------------------------------------------------
-- Cola de control de SALIDA (ventas ya informadas a Produccion NEXO), para
-- que el agente nunca reenvie la misma linea de MOVDETALLES dos veces.
-- La clave natural (CENTROCOSTO+TIPDOC+NRODOC+ORDEN+REFERENCIA) identifica
-- una linea de documento de forma unica aunque MOVDETALLES no tenga PK.
-- ----------------------------------------------------------------------------
CREATE TABLE dbo.NEXO_VentasExportadas (
    Id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    CENTROCOSTO     SMALLINT NOT NULL,
    TIPDOC          NVARCHAR(20) NOT NULL,
    NRODOC          NVARCHAR(30) NOT NULL,
    ORDEN           NUMERIC(18,0) NOT NULL,
    REFERENCIA      NVARCHAR(30) NOT NULL,
    CANTIDAD        NUMERIC(18,2) NOT NULL,
    FechaExportado  DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT UQ_NEXO_VentaLinea UNIQUE (CENTROCOSTO, TIPDOC, NRODOC, ORDEN, REFERENCIA)
);
GO

-- ----------------------------------------------------------------------------
-- NO SE CREA NINGUN STORED PROCEDURE EN VISIONS.
--
-- Visions no tiene un solo procedimiento, funcion o trigger en toda su base
-- (se verifico linea por linea del script completo). Meter un SP aqui seria
-- el unico objeto "de codigo" en una base que es 100% tablas planas, y
-- podria no sobrevivir la proxima actualizacion del instalador de Visions.
--
-- En su lugar, el UPDATE sobre TARJETA.EXISTENCIAS lo ejecuta directamente
-- el Agente de Sincronizacion (aplicacion externa en C#, ver README) con
-- SQL parametrizado comun y corriente -- exactamente como ya lo hace la
-- propia aplicacion de Visions desde su capa cliente. El agente:
--   1. Abre una transaccion en su conexion a esta base de datos.
--   2. UPDATE dbo.TARJETA SET EXISTENCIAS = EXISTENCIAS + @Cantidad
--      WHERE CENTROCOSTO = @CentroCosto AND REFERENCIA = @Referencia
--   3. UPDATE dbo.NEXO_EntradasInventario SET Aplicado = 1, FechaAplicado = GETDATE()
--      WHERE Id = @Id
--   4. Commit. Si algo falla, rollback y reintenta en la siguiente corrida
--      (es seguro reintentar: el paso 2 no se vuelve a ejecutar si el
--      agente primero revisa que Aplicado = 0 antes de tocar TARJETA).
-- ----------------------------------------------------------------------------

PRINT 'Objetos de integracion con NEXO creados correctamente en Visions.';
PRINT 'Recordatorio: cero procedimientos, funciones o triggers agregados. Solo tablas.';
PRINT 'IMPORTANTE: completar dbo.NEXO_ConfiguracionSync con el/los CENTROCOSTO reales';
PRINT 'y los codigos de TIPDOC que representan venta en esta instalacion.';