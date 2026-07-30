/* ============================================================================
   SISTEMA NEXO - MODULO DE PRODUCCION, INVENTARIO Y MULTI-CENTRO DE COSTO
   Script 01: Creacion de Base de Datos, Esquemas y Tablas
   Motor: SQL Server 2019+
   ============================================================================
   Organizacion en esquemas (permite escalar por modulo, aplicar permisos
   granulares por schema, y en el futuro separar en microservicios sin
   reestructurar nombres de tablas):
     Seguridad    -> usuarios, roles, permisos, sesiones
     Organizacion -> centros de costo, centros de trabajo
     Catalogo     -> articulos, unidades, proveedores, clientes
     Inventario   -> bodegas, lotes, stock, traspasos
     Compras      -> ordenes de compra
     Produccion   -> recetas (BOM), ordenes de produccion
     Kardex       -> movimientos de inventario y bajas por merma
     Auditoria    -> log general de cambios
   ============================================================================ */

IF DB_ID('NEXO_ERP') IS NULL
BEGIN
    CREATE DATABASE NEXO_ERP;
END
GO

USE NEXO_ERP;
GO

-- ============================================================================
-- ESQUEMAS
-- ============================================================================
CREATE SCHEMA Seguridad AUTHORIZATION dbo;
GO
CREATE SCHEMA Organizacion AUTHORIZATION dbo;
GO
CREATE SCHEMA Catalogo AUTHORIZATION dbo;
GO
CREATE SCHEMA Inventario AUTHORIZATION dbo;
GO
CREATE SCHEMA Compras AUTHORIZATION dbo;
GO
CREATE SCHEMA Produccion AUTHORIZATION dbo;
GO
CREATE SCHEMA Kardex AUTHORIZATION dbo;
GO
CREATE SCHEMA Auditoria AUTHORIZATION dbo;
GO

-- ============================================================================
-- SCHEMA: Seguridad
-- ============================================================================
CREATE TABLE Seguridad.Roles (
    RolID           INT IDENTITY(1,1) PRIMARY KEY,
    Nombre          NVARCHAR(50) NOT NULL UNIQUE,
    Descripcion     NVARCHAR(200) NULL,
    Estado          BIT NOT NULL DEFAULT 1,
    FechaCreacion   DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE Seguridad.Permisos (
    PermisoID       INT IDENTITY(1,1) PRIMARY KEY,
    Codigo          NVARCHAR(80) NOT NULL UNIQUE,   -- ej: PRODUCCION.LIBERAR_OP
    Modulo          NVARCHAR(50) NOT NULL,           -- ej: PRODUCCION, INVENTARIO, COMPRAS
    Descripcion     NVARCHAR(200) NULL
);
GO

CREATE TABLE Seguridad.RolPermisos (
    RolID           INT NOT NULL REFERENCES Seguridad.Roles(RolID),
    PermisoID       INT NOT NULL REFERENCES Seguridad.Permisos(PermisoID),
    PRIMARY KEY (RolID, PermisoID)
);
GO

CREATE TABLE Organizacion.CentrosCosto (
    CentroCostoID   INT IDENTITY(1,1) PRIMARY KEY,
    Codigo          NVARCHAR(20) NOT NULL UNIQUE,
    Nombre          NVARCHAR(100) NOT NULL,
    TipoCentro      NVARCHAR(20) NOT NULL
                    CHECK (TipoCentro IN ('PLANTA_CENTRAL','SUCURSAL','PUNTO_VENTA','FRANQUICIA')),
    Direccion       NVARCHAR(200) NULL,
    Telefono        NVARCHAR(30) NULL,
    Estado          BIT NOT NULL DEFAULT 1,
    FechaCreacion   DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE Seguridad.Usuarios (
    UsuarioID       INT IDENTITY(1,1) PRIMARY KEY,
    Nombres         NVARCHAR(100) NOT NULL,
    Apellidos       NVARCHAR(100) NOT NULL,
    Email           NVARCHAR(150) NOT NULL UNIQUE,
    Username        NVARCHAR(50) NOT NULL UNIQUE,
    PasswordHash    VARBINARY(256) NOT NULL,
    Salt            VARBINARY(128) NOT NULL,
    RolID           INT NOT NULL REFERENCES Seguridad.Roles(RolID),
    CentroCostoID   INT NULL REFERENCES Organizacion.CentrosCosto(CentroCostoID), -- NULL = acceso global (ej. Administrador)
    Estado          BIT NOT NULL DEFAULT 1,
    FechaCreacion   DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UltimoAcceso    DATETIME2 NULL
);
GO

CREATE TABLE Seguridad.SesionesUsuario (
    SesionID        BIGINT IDENTITY(1,1) PRIMARY KEY,
    UsuarioID       INT NOT NULL REFERENCES Seguridad.Usuarios(UsuarioID),
    Token           NVARCHAR(500) NOT NULL,
    RefreshToken    NVARCHAR(500) NOT NULL,
    FechaInicio     DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    FechaExpiracion DATETIME2 NOT NULL,
    DireccionIP     NVARCHAR(50) NULL,
    Activa          BIT NOT NULL DEFAULT 1
);
GO
CREATE INDEX IX_Sesiones_Usuario ON Seguridad.SesionesUsuario(UsuarioID, Activa);
GO

-- ============================================================================
-- SCHEMA: Organizacion (continuacion)
-- ============================================================================
CREATE TABLE Organizacion.CentrosTrabajo (
    CentroTrabajoID     INT IDENTITY(1,1) PRIMARY KEY,
    Nombre              NVARCHAR(100) NOT NULL,
    CentroCostoID       INT NOT NULL REFERENCES Organizacion.CentrosCosto(CentroCostoID),
    CostoHoraManoObra   DECIMAL(18,4) NOT NULL DEFAULT 0,
    CostoHoraCIF        DECIMAL(18,4) NOT NULL DEFAULT 0,
    Estado              BIT NOT NULL DEFAULT 1
);
GO

-- ============================================================================
-- SCHEMA: Catalogo
-- ============================================================================
CREATE TABLE Catalogo.TiposArticulo (
    TipoArticuloID  INT IDENTITY(1,1) PRIMARY KEY,
    Codigo          NVARCHAR(20) NOT NULL UNIQUE, -- MP, INSUMO, PT, SUBPROD, EMPAQUE
    Nombre          NVARCHAR(50) NOT NULL
);
GO

CREATE TABLE Catalogo.UnidadesMedida (
    UnidadID        INT IDENTITY(1,1) PRIMARY KEY,
    Nombre          NVARCHAR(30) NOT NULL,
    Abreviatura     NVARCHAR(10) NOT NULL UNIQUE,
    Tipo            NVARCHAR(20) NOT NULL CHECK (Tipo IN ('PESO','VOLUMEN','UNIDAD','LONGITUD'))
);
GO

CREATE TABLE Catalogo.UnidadesConversion (
    UnidadOrigenID  INT NOT NULL REFERENCES Catalogo.UnidadesMedida(UnidadID),
    UnidadDestinoID INT NOT NULL REFERENCES Catalogo.UnidadesMedida(UnidadID),
    Factor          DECIMAL(18,8) NOT NULL, -- 1 unidad origen = Factor unidades destino
    PRIMARY KEY (UnidadOrigenID, UnidadDestinoID)
);
GO

CREATE TABLE Catalogo.Articulos (
    ArticuloID      INT IDENTITY(1,1) PRIMARY KEY,
    SKU             NVARCHAR(30) NOT NULL UNIQUE,
    Nombre          NVARCHAR(150) NOT NULL,
    Descripcion     NVARCHAR(300) NULL,
    TipoArticuloID  INT NOT NULL REFERENCES Catalogo.TiposArticulo(TipoArticuloID),
    UnidadID        INT NOT NULL REFERENCES Catalogo.UnidadesMedida(UnidadID),
    CostoPromedio   DECIMAL(18,4) NOT NULL DEFAULT 0,
    PrecioVenta     DECIMAL(18,4) NOT NULL DEFAULT 0,
    StockMinimo     DECIMAL(18,4) NOT NULL DEFAULT 0,
    StockMaximo     DECIMAL(18,4) NULL,
    PuntoReorden    DECIMAL(18,4) NOT NULL DEFAULT 0,
    DiasVidaUtil    INT NULL,
    Estado          BIT NOT NULL DEFAULT 1,
    FechaCreacion   DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO
CREATE INDEX IX_Articulos_Tipo ON Catalogo.Articulos(TipoArticuloID);
GO

CREATE TABLE Catalogo.Proveedores (
    ProveedorID     INT IDENTITY(1,1) PRIMARY KEY,
    RazonSocial     NVARCHAR(150) NOT NULL,
    NIT             NVARCHAR(30) NOT NULL UNIQUE,
    Contacto        NVARCHAR(100) NULL,
    Telefono        NVARCHAR(30) NULL,
    Email           NVARCHAR(150) NULL,
    Direccion       NVARCHAR(200) NULL,
    Estado          BIT NOT NULL DEFAULT 1
);
GO

CREATE TABLE Catalogo.ArticuloProveedor (
    ArticuloID          INT NOT NULL REFERENCES Catalogo.Articulos(ArticuloID),
    ProveedorID         INT NOT NULL REFERENCES Catalogo.Proveedores(ProveedorID),
    CodigoProveedor     NVARCHAR(50) NULL,
    CostoUltimaCompra   DECIMAL(18,4) NULL,
    TiempoEntregaDias   INT NULL,
    PRIMARY KEY (ArticuloID, ProveedorID)
);
GO

CREATE TABLE Catalogo.Clientes (
    ClienteID       INT IDENTITY(1,1) PRIMARY KEY,
    Nombre          NVARCHAR(150) NOT NULL,
    NIT             NVARCHAR(30) NULL,
    Contacto        NVARCHAR(100) NULL,
    Telefono        NVARCHAR(30) NULL,
    Email           NVARCHAR(150) NULL,
    Direccion       NVARCHAR(200) NULL,
    Estado          BIT NOT NULL DEFAULT 1
);
GO

-- ============================================================================
-- SCHEMA: Inventario
-- ============================================================================
CREATE TABLE Inventario.Bodegas (
    BodegaID        INT IDENTITY(1,1) PRIMARY KEY,
    Nombre          NVARCHAR(100) NOT NULL,
    CentroCostoID   INT NOT NULL REFERENCES Organizacion.CentrosCosto(CentroCostoID),
    TipoBodega      NVARCHAR(20) NOT NULL
                    CHECK (TipoBodega IN ('MATERIA_PRIMA','PRODUCTO_TERMINADO','WIP','TRANSITO')),
    EsVirtual       BIT NOT NULL DEFAULT 0,
    Estado          BIT NOT NULL DEFAULT 1
);
GO

CREATE TABLE Inventario.Lotes (
    LoteID              INT IDENTITY(1,1) PRIMARY KEY,
    ArticuloID          INT NOT NULL REFERENCES Catalogo.Articulos(ArticuloID),
    NumeroLote          NVARCHAR(50) NOT NULL,
    FechaFabricacion    DATE NULL,
    FechaVencimiento    DATE NULL,
    ProveedorID         INT NULL REFERENCES Catalogo.Proveedores(ProveedorID),
    Estado              NVARCHAR(20) NOT NULL DEFAULT 'APROBADO'
                        CHECK (Estado IN ('APROBADO','CUARENTENA','RECHAZADO','AGOTADO')),
    FechaCreacion       DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT UQ_Lote_Articulo UNIQUE (ArticuloID, NumeroLote)
);
GO
CREATE INDEX IX_Lotes_Vencimiento ON Inventario.Lotes(ArticuloID, FechaVencimiento) INCLUDE (Estado);
GO

CREATE TABLE Inventario.InventarioStock (
    InventarioID        BIGINT IDENTITY(1,1) PRIMARY KEY,
    ArticuloID          INT NOT NULL REFERENCES Catalogo.Articulos(ArticuloID),
    BodegaID            INT NOT NULL REFERENCES Inventario.Bodegas(BodegaID),
    LoteID              INT NULL REFERENCES Inventario.Lotes(LoteID),
    CantidadActual      DECIMAL(18,4) NOT NULL DEFAULT 0 CHECK (CantidadActual >= 0),
    CostoUnitarioLote   DECIMAL(18,4) NOT NULL DEFAULT 0,
    FechaUltimaActualizacion DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT UQ_Stock_Articulo_Bodega_Lote UNIQUE (ArticuloID, BodegaID, LoteID)
);
GO
CREATE INDEX IX_Stock_ArticuloBodega ON Inventario.InventarioStock(ArticuloID, BodegaID);
GO

CREATE TABLE Inventario.TraspasosBodega (
    TraspasoID              INT IDENTITY(1,1) PRIMARY KEY,
    Codigo                  NVARCHAR(30) NOT NULL UNIQUE,
    BodegaOrigenID          INT NOT NULL REFERENCES Inventario.Bodegas(BodegaID),
    BodegaDestinoID         INT NOT NULL REFERENCES Inventario.Bodegas(BodegaID),
    EstadoTraspaso          NVARCHAR(20) NOT NULL DEFAULT 'PENDIENTE'
                            CHECK (EstadoTraspaso IN ('PENDIENTE','EN_TRANSITO','RECIBIDO','CANCELADO')),
    FechaEnvio              DATETIME2 NULL,
    FechaRecepcion          DATETIME2 NULL,
    UsuarioEnviaID          INT NULL REFERENCES Seguridad.Usuarios(UsuarioID),
    UsuarioRecibeID         INT NULL REFERENCES Seguridad.Usuarios(UsuarioID),
    Observaciones           NVARCHAR(300) NULL,
    FechaCreacion           DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE Inventario.TraspasosDetalle (
    TraspasoDetalleID   INT IDENTITY(1,1) PRIMARY KEY,
    TraspasoID          INT NOT NULL REFERENCES Inventario.TraspasosBodega(TraspasoID),
    ArticuloID          INT NOT NULL REFERENCES Catalogo.Articulos(ArticuloID),
    LoteID              INT NULL REFERENCES Inventario.Lotes(LoteID),
    CantidadEnviada     DECIMAL(18,4) NOT NULL CHECK (CantidadEnviada > 0),
    CantidadRecibida    DECIMAL(18,4) NULL,
    CostoUnitario       DECIMAL(18,4) NOT NULL
);
GO

-- ============================================================================
-- SCHEMA: Compras
-- ============================================================================
CREATE TABLE Compras.OrdenesCompra (
    OrdenCompraID   INT IDENTITY(1,1) PRIMARY KEY,
    Codigo          NVARCHAR(30) NOT NULL UNIQUE,
    ProveedorID     INT NOT NULL REFERENCES Catalogo.Proveedores(ProveedorID),
    BodegaDestinoID INT NOT NULL REFERENCES Inventario.Bodegas(BodegaID),
    EstadoOC        NVARCHAR(20) NOT NULL DEFAULT 'PENDIENTE'
                    CHECK (EstadoOC IN ('PENDIENTE','PARCIAL','RECIBIDA','CANCELADA')),
    FechaEmision    DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    FechaRecepcion  DATETIME2 NULL,
    UsuarioID       INT NOT NULL REFERENCES Seguridad.Usuarios(UsuarioID)
);
GO

CREATE TABLE Compras.OrdenesCompraDetalle (
    OrdenCompraDetalleID    INT IDENTITY(1,1) PRIMARY KEY,
    OrdenCompraID           INT NOT NULL REFERENCES Compras.OrdenesCompra(OrdenCompraID),
    ArticuloID              INT NOT NULL REFERENCES Catalogo.Articulos(ArticuloID),
    CantidadSolicitada      DECIMAL(18,4) NOT NULL CHECK (CantidadSolicitada > 0),
    CantidadRecibida        DECIMAL(18,4) NOT NULL DEFAULT 0,
    CostoUnitario           DECIMAL(18,4) NOT NULL,
    LoteID                  INT NULL REFERENCES Inventario.Lotes(LoteID)
);
GO

-- ============================================================================
-- SCHEMA: Produccion
-- ============================================================================
CREATE TABLE Produccion.RecetaBOM (
    RecetaID                INT IDENTITY(1,1) PRIMARY KEY,
    ProductoTerminadoID      INT NOT NULL REFERENCES Catalogo.Articulos(ArticuloID),
    NombreReceta             NVARCHAR(150) NOT NULL,
    Version                  INT NOT NULL DEFAULT 1,
    CantidadRendimientoBase  DECIMAL(18,4) NOT NULL CHECK (CantidadRendimientoBase > 0),
    UnidadRendimientoID      INT NOT NULL REFERENCES Catalogo.UnidadesMedida(UnidadID),
    Estado                   BIT NOT NULL DEFAULT 1,
    FechaCreacion            DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

CREATE TABLE Produccion.RecetaBOM_Detalle (
    RecetaDetalleID         INT IDENTITY(1,1) PRIMARY KEY,
    RecetaID                INT NOT NULL REFERENCES Produccion.RecetaBOM(RecetaID),
    InsumoID                INT NOT NULL REFERENCES Catalogo.Articulos(ArticuloID),
    CantidadRequerida       DECIMAL(18,4) NOT NULL CHECK (CantidadRequerida > 0),
    UnidadID                INT NOT NULL REFERENCES Catalogo.UnidadesMedida(UnidadID),
    PorcentajeMermaEstandar DECIMAL(5,2) NOT NULL DEFAULT 0,
    CentroTrabajoID         INT NULL REFERENCES Organizacion.CentrosTrabajo(CentroTrabajoID),
    Orden                   INT NOT NULL DEFAULT 1
);
GO
CREATE INDEX IX_RecetaDetalle_Insumo ON Produccion.RecetaBOM_Detalle(InsumoID);
GO

CREATE TABLE Produccion.TiposProduccion (
    TipoProduccionID    INT IDENTITY(1,1) PRIMARY KEY,
    Codigo              NVARCHAR(20) NOT NULL UNIQUE, -- MTO, MTS_MASA, MTS_REPOSICION
    Nombre              NVARCHAR(80) NOT NULL,
    Descripcion         NVARCHAR(200) NULL
);
GO

CREATE TABLE Produccion.EstadosOP (
    EstadoOPID  INT IDENTITY(1,1) PRIMARY KEY,
    Nombre      NVARCHAR(30) NOT NULL UNIQUE, -- Planificada, Liberada, En Proceso, Finalizada, Cancelada
    Orden       INT NOT NULL
);
GO

CREATE TABLE Produccion.MotivosExcesoConsumo (
    MotivoExcesoID  INT IDENTITY(1,1) PRIMARY KEY,
    Nombre          NVARCHAR(150) NOT NULL
);
GO

CREATE TABLE Produccion.OrdenesProduccion (
    OrdenProduccionID   INT IDENTITY(1,1) PRIMARY KEY,
    CodigoOP            NVARCHAR(30) NOT NULL UNIQUE,
    TipoProduccionID    INT NOT NULL REFERENCES Produccion.TiposProduccion(TipoProduccionID),
    EstadoOPID          INT NOT NULL REFERENCES Produccion.EstadosOP(EstadoOPID),
    ProductoTerminadoID INT NOT NULL REFERENCES Catalogo.Articulos(ArticuloID),
    RecetaID            INT NOT NULL REFERENCES Produccion.RecetaBOM(RecetaID),
    CantidadProgramada  DECIMAL(18,4) NOT NULL CHECK (CantidadProgramada > 0),
    CantidadProducidaReal DECIMAL(18,4) NULL,
    ClienteID           INT NULL REFERENCES Catalogo.Clientes(ClienteID),          -- solo si TipoProduccion = MTO
    CentroCostoDestinoID INT NOT NULL REFERENCES Organizacion.CentrosCosto(CentroCostoID),
    BodegaOrigenMPID    INT NOT NULL REFERENCES Inventario.Bodegas(BodegaID),
    BodegaDestinoPTID   INT NOT NULL REFERENCES Inventario.Bodegas(BodegaID),
    CentroTrabajoID     INT NULL REFERENCES Organizacion.CentrosTrabajo(CentroTrabajoID),
    FechaPlanificada    DATETIME2 NULL,
    FechaInicio         DATETIME2 NULL,
    FechaFin            DATETIME2 NULL,
    CostoMateriales     DECIMAL(18,4) NOT NULL DEFAULT 0,
    CostoMOD            DECIMAL(18,4) NOT NULL DEFAULT 0,
    CostoCIF            DECIMAL(18,4) NOT NULL DEFAULT 0,
    CostoUnitarioReal   DECIMAL(18,4) NULL,
    UsuarioCreaID       INT NOT NULL REFERENCES Seguridad.Usuarios(UsuarioID),
    UsuarioLiberaID     INT NULL REFERENCES Seguridad.Usuarios(UsuarioID),
    UsuarioCierraID     INT NULL REFERENCES Seguridad.Usuarios(UsuarioID),
    Observaciones       NVARCHAR(500) NULL,
    FechaCreacion       DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO
CREATE INDEX IX_OP_CentroCosto ON Produccion.OrdenesProduccion(CentroCostoDestinoID, EstadoOPID);
CREATE INDEX IX_OP_Fechas ON Produccion.OrdenesProduccion(FechaInicio, FechaFin);
GO

CREATE TABLE Produccion.OrdenesProduccionConsumo (
    ConsumoID           BIGINT IDENTITY(1,1) PRIMARY KEY,
    OrdenProduccionID   INT NOT NULL REFERENCES Produccion.OrdenesProduccion(OrdenProduccionID),
    ArticuloID          INT NOT NULL REFERENCES Catalogo.Articulos(ArticuloID),
    LoteID              INT NULL REFERENCES Inventario.Lotes(LoteID),
    CantidadTeorica     DECIMAL(18,4) NOT NULL,
    CantidadReal        DECIMAL(18,4) NOT NULL,
    MotivoExcesoID      INT NULL REFERENCES Produccion.MotivosExcesoConsumo(MotivoExcesoID),
    Observacion         NVARCHAR(300) NULL
);
GO

-- ============================================================================
-- SCHEMA: Kardex
-- ============================================================================
CREATE TABLE Kardex.TiposMovimientoKardex (
    TipoMovID   INT IDENTITY(1,1) PRIMARY KEY,
    Codigo      NVARCHAR(30) NOT NULL UNIQUE,  -- ENTRADA_COMPRA, SALIDA_WIP, ENTRADA_PT, BAJA_MERMA, TRASPASO_SALIDA, TRASPASO_ENTRADA
    Nombre      NVARCHAR(80) NOT NULL,
    Signo       SMALLINT NOT NULL CHECK (Signo IN (1,-1))
);
GO

CREATE TABLE Kardex.TiposMotivoLoss (
    MotivoID    INT IDENTITY(1,1) PRIMARY KEY,
    Nombre      NVARCHAR(100) NOT NULL UNIQUE -- Daño Fisico, Vencimiento, Humedad/Contaminacion, Error de Manipulacion
);
GO

CREATE TABLE Kardex.BajasInventarioPerdidas (
    BajaID              INT IDENTITY(1,1) PRIMARY KEY,
    CodigoBaja          NVARCHAR(30) NOT NULL UNIQUE,
    Fecha               DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    ArticuloID          INT NOT NULL REFERENCES Catalogo.Articulos(ArticuloID),
    BodegaID            INT NOT NULL REFERENCES Inventario.Bodegas(BodegaID),
    LoteID              INT NULL REFERENCES Inventario.Lotes(LoteID),
    CantidadPerdida     DECIMAL(18,4) NOT NULL CHECK (CantidadPerdida > 0),
    CostoUnitario       DECIMAL(18,4) NOT NULL,
    CostoTotal          AS (CantidadPerdida * CostoUnitario) PERSISTED,
    MotivoID            INT NOT NULL REFERENCES Kardex.TiposMotivoLoss(MotivoID),
    ObservacionDetallada NVARCHAR(500) NOT NULL,
    UsuarioRegistraID   INT NOT NULL REFERENCES Seguridad.Usuarios(UsuarioID),
    Estado              NVARCHAR(20) NOT NULL DEFAULT 'CONFIRMADA'
);
GO

CREATE TABLE Kardex.KardexMovimientos (
    KardexID            BIGINT IDENTITY(1,1) PRIMARY KEY,
    Fecha               DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    ArticuloID          INT NOT NULL REFERENCES Catalogo.Articulos(ArticuloID),
    BodegaID            INT NOT NULL REFERENCES Inventario.Bodegas(BodegaID),
    LoteID              INT NULL REFERENCES Inventario.Lotes(LoteID),
    TipoMovID           INT NOT NULL REFERENCES Kardex.TiposMovimientoKardex(TipoMovID),
    OrdenProduccionID   INT NULL REFERENCES Produccion.OrdenesProduccion(OrdenProduccionID),
    TraspasoID          INT NULL REFERENCES Inventario.TraspasosBodega(TraspasoID),
    OrdenCompraID       INT NULL REFERENCES Compras.OrdenesCompra(OrdenCompraID),
    BajaID              INT NULL REFERENCES Kardex.BajasInventarioPerdidas(BajaID),
    CentroCostoID       INT NOT NULL REFERENCES Organizacion.CentrosCosto(CentroCostoID),
    Cantidad            DECIMAL(18,4) NOT NULL,       -- siempre positiva; el signo lo da TipoMovID
    CostoUnitario       DECIMAL(18,4) NOT NULL,
    CantidadSaldo       DECIMAL(18,4) NOT NULL,        -- saldo resultante en esa bodega/articulo/lote
    CostoPromedioSaldo  DECIMAL(18,4) NOT NULL,
    ObservacionDetallada NVARCHAR(500) NULL,
    UsuarioID           INT NOT NULL REFERENCES Seguridad.Usuarios(UsuarioID),
    FechaRegistro       DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO
CREATE INDEX IX_Kardex_Articulo_Bodega_Fecha ON Kardex.KardexMovimientos(ArticuloID, BodegaID, Fecha);
CREATE INDEX IX_Kardex_OP ON Kardex.KardexMovimientos(OrdenProduccionID);
CREATE INDEX IX_Kardex_CentroCosto_Fecha ON Kardex.KardexMovimientos(CentroCostoID, Fecha);
GO

-- ============================================================================
-- SCHEMA: Auditoria
-- ============================================================================
CREATE TABLE Auditoria.LogAuditoria (
    LogID           BIGINT IDENTITY(1,1) PRIMARY KEY,
    EsquemaTabla    NVARCHAR(100) NOT NULL,
    RegistroID      NVARCHAR(50) NOT NULL,
    Accion          NVARCHAR(10) NOT NULL CHECK (Accion IN ('INSERT','UPDATE','DELETE')),
    UsuarioID       INT NULL REFERENCES Seguridad.Usuarios(UsuarioID),
    Fecha           DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    ValoresAnteriores NVARCHAR(MAX) NULL, -- JSON
    ValoresNuevos     NVARCHAR(MAX) NULL  -- JSON
);
GO
CREATE INDEX IX_Log_Tabla_Registro ON Auditoria.LogAuditoria(EsquemaTabla, RegistroID);
GO

PRINT 'Estructura de base de datos NEXO_ERP creada correctamente.';