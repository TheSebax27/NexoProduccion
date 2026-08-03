/* ============================================================================
   NOTA DE INSTALACION (agosto 2026) -- este script fue exportado antes de
   varios fixes incrementales de la sesion de agosto 2026 que se aplicaron
   directamente contra la BD en vivo (no siempre se re-exporto este archivo
   completo despues de cada uno). Para levantar un ambiente NUEVO con el
   estado actual, ejecutar EN ORDEN:
     1. Este script (sqlportablenexo.sql) -- estructura base
     2. ScriptsProcesos/DatosSemilla.sql -- catalogos base
     3. ScriptsProcesos/LogicaNegocio.sql -- SPs (ya actualizado, es la fuente
        de verdad para los procedimientos)
     4. ScriptsProcesos/AjusteInventario.sql -- tabla Kardex.AjustesInventario
        + columna KardexMovimientos.AjusteID + sp_AjustePositivoInventario
     5. Agregar manualmente: ALTER TABLE Catalogo.Articulos ADD
        UnidadesPorEmbalaje DECIMAL(18,4) NULL; y ALTER COLUMN UnidadID INT NULL;
        (ver CLAUDE.md seccion 20.7 -- estos dos cambios de columna en
        Catalogo.Articulos nunca se volcaron a un script de ScriptsProcesos/
        por separado, solo se aplicaron en vivo)
     6. ScriptsProcesos/EditarCancelarOrdenProduccion.sql,
        FixConversionCajaUnidad.sql, FixTraspasoMultiLote.sql,
        FixDuplicadosMotivosExceso.sql -- resto de fixes de SPs, ya idempotentes
   Ver CLAUDE.md seccion 20 para el detalle de cada fix.
   ============================================================================ */

USE [master]
GO
/****** Bloque agregado: elimina la BD si ya existe en este equipo, para poder
        re-ejecutar el script las veces que sea necesario sin errores de
        "already exists" ******/
IF DB_ID(N'NEXO_ERP') IS NOT NULL
BEGIN
    ALTER DATABASE [NEXO_ERP] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [NEXO_ERP];
END
GO
/****** Object:  Database [NEXO_ERP]    Script Date: 1/08/2026 11:00:06 a. m. ******/
/****** CREATE DATABASE portable: SIN rutas de archivo fijas.
        SQL Server usara automaticamente la carpeta DATA por defecto
        de la instancia donde se ejecute el script (funciona igual
        en cualquier equipo/instancia, sin tocar nada). ******/
CREATE DATABASE [NEXO_ERP]
 CONTAINMENT = NONE
 WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF
GO
ALTER DATABASE [NEXO_ERP] SET COMPATIBILITY_LEVEL = 160
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [NEXO_ERP].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [NEXO_ERP] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [NEXO_ERP] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [NEXO_ERP] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [NEXO_ERP] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [NEXO_ERP] SET ARITHABORT OFF 
GO
ALTER DATABASE [NEXO_ERP] SET AUTO_CLOSE ON 
GO
ALTER DATABASE [NEXO_ERP] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [NEXO_ERP] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [NEXO_ERP] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [NEXO_ERP] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [NEXO_ERP] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [NEXO_ERP] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [NEXO_ERP] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [NEXO_ERP] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [NEXO_ERP] SET  ENABLE_BROKER 
GO
ALTER DATABASE [NEXO_ERP] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [NEXO_ERP] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [NEXO_ERP] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [NEXO_ERP] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [NEXO_ERP] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [NEXO_ERP] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [NEXO_ERP] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [NEXO_ERP] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [NEXO_ERP] SET  MULTI_USER 
GO
ALTER DATABASE [NEXO_ERP] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [NEXO_ERP] SET DB_CHAINING OFF 
GO
ALTER DATABASE [NEXO_ERP] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [NEXO_ERP] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [NEXO_ERP] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [NEXO_ERP] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO
ALTER DATABASE [NEXO_ERP] SET QUERY_STORE = ON
GO
ALTER DATABASE [NEXO_ERP] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 1000, QUERY_CAPTURE_MODE = AUTO, SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)
GO
USE [NEXO_ERP]
GO
/****** Object:  Schema [Auditoria]    Script Date: 1/08/2026 11:00:07 a. m. ******/
CREATE SCHEMA [Auditoria]
GO
/****** Object:  Schema [catalogo]    Script Date: 1/08/2026 11:00:07 a. m. ******/
CREATE SCHEMA [catalogo]
GO
/****** Object:  Schema [Compras]    Script Date: 1/08/2026 11:00:07 a. m. ******/
CREATE SCHEMA [Compras]
GO
/****** Object:  Schema [Integracion]    Script Date: 1/08/2026 11:00:07 a. m. ******/
CREATE SCHEMA [Integracion]
GO
/****** Object:  Schema [Inventario]    Script Date: 1/08/2026 11:00:07 a. m. ******/
CREATE SCHEMA [Inventario]
GO
/****** Object:  Schema [Kardex]    Script Date: 1/08/2026 11:00:07 a. m. ******/
CREATE SCHEMA [Kardex]
GO
/****** Object:  Schema [Organizacion]    Script Date: 1/08/2026 11:00:07 a. m. ******/
CREATE SCHEMA [Organizacion]
GO
/****** Object:  Schema [Produccion]    Script Date: 1/08/2026 11:00:07 a. m. ******/
CREATE SCHEMA [Produccion]
GO
/****** Object:  Schema [Seguridad]    Script Date: 1/08/2026 11:00:07 a. m. ******/
CREATE SCHEMA [Seguridad]
GO
/****** Object:  UserDefinedFunction [catalogo].[fn_StockTotalArticulo]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   FUNCTION [catalogo].[fn_StockTotalArticulo] (@ArticuloID INT)
RETURNS DECIMAL(18,4)
AS
BEGIN
    DECLARE @Total DECIMAL(18,4);
    SELECT @Total = ISNULL(SUM(CantidadActual),0)
    FROM Inventario.InventarioStock WHERE ArticuloID = @ArticuloID;
    RETURN @Total;
END
GO
/****** Object:  Table [Organizacion].[CentrosCosto]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Organizacion].[CentrosCosto](
	[CentroCostoID] [int] IDENTITY(1,1) NOT NULL,
	[Codigo] [nvarchar](20) NOT NULL,
	[Nombre] [nvarchar](100) NOT NULL,
	[TipoCentro] [nvarchar](20) NOT NULL,
	[Direccion] [nvarchar](200) NULL,
	[Telefono] [nvarchar](30) NULL,
	[Estado] [bit] NOT NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
	[TieneVisions] [bit] NOT NULL,
	[IdentificadorClienteVisions] [nvarchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[CentroCostoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Integracion].[MapeoArticulos]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Integracion].[MapeoArticulos](
	[MapeoID] [int] IDENTITY(1,1) NOT NULL,
	[ArticuloID] [int] NOT NULL,
	[CentroCostoID] [int] NOT NULL,
	[CodigoArticuloVisions] [nvarchar](30) NOT NULL,
	[Estado] [bit] NOT NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[MapeoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_Mapeo_Articulo] UNIQUE NONCLUSTERED 
(
	[ArticuloID] ASC,
	[CentroCostoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_Mapeo_Referencia] UNIQUE NONCLUSTERED 
(
	[CentroCostoID] ASC,
	[CodigoArticuloVisions] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Integracion].[EventosSalientes]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Integracion].[EventosSalientes](
	[EventoID] [bigint] IDENTITY(1,1) NOT NULL,
	[TipoEvento] [nvarchar](50) NOT NULL,
	[CentroCostoID] [int] NOT NULL,
	[ArticuloID] [int] NOT NULL,
	[Cantidad] [decimal](18, 4) NOT NULL,
	[CostoUnitario] [decimal](18, 4) NOT NULL,
	[KardexID] [bigint] NULL,
	[Estado] [nvarchar](20) NOT NULL,
	[IntentosEnvio] [int] NOT NULL,
	[UltimoError] [nvarchar](500) NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
	[FechaEnvio] [datetime2](7) NULL,
PRIMARY KEY CLUSTERED 
(
	[EventoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [Integracion].[vw_EventosPendientesParaVisions]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   VIEW [Integracion].[vw_EventosPendientesParaVisions] AS
SELECT
    e.EventoID, e.TipoEvento, e.Cantidad, e.CostoUnitario, e.FechaCreacion,
    cc.IdentificadorClienteVisions AS CentroCostoVisions,
    m.CodigoArticuloVisions AS ReferenciaVisions
FROM Integracion.EventosSalientes e
JOIN Organizacion.CentrosCosto cc ON cc.CentroCostoID = e.CentroCostoID
JOIN Integracion.MapeoArticulos m ON m.ArticuloID = e.ArticuloID AND m.CentroCostoID = e.CentroCostoID
WHERE e.Estado = 'PENDIENTE' AND cc.TieneVisions = 1;
GO
/****** Object:  Table [catalogo].[Articulos]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [catalogo].[Articulos](
	[ArticuloID] [int] IDENTITY(1,1) NOT NULL,
	[SKU] [nvarchar](30) NOT NULL,
	[Nombre] [nvarchar](150) NOT NULL,
	[Descripcion] [nvarchar](300) NULL,
	[TipoArticuloID] [int] NOT NULL,
	[UnidadID] [int] NOT NULL,
	[CostoPromedio] [decimal](18, 4) NOT NULL,
	[PrecioVenta] [decimal](18, 4) NOT NULL,
	[StockMinimo] [decimal](18, 4) NOT NULL,
	[StockMaximo] [decimal](18, 4) NULL,
	[PuntoReorden] [decimal](18, 4) NOT NULL,
	[DiasVidaUtil] [int] NULL,
	[Estado] [bit] NOT NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ArticuloID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[SKU] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Produccion].[OrdenesProduccion]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Produccion].[OrdenesProduccion](
	[OrdenProduccionID] [int] IDENTITY(1,1) NOT NULL,
	[CodigoOP] [nvarchar](30) NOT NULL,
	[TipoProduccionID] [int] NOT NULL,
	[EstadoOPID] [int] NOT NULL,
	[ProductoTerminadoID] [int] NOT NULL,
	[RecetaID] [int] NOT NULL,
	[CantidadProgramada] [decimal](18, 4) NOT NULL,
	[CantidadProducidaReal] [decimal](18, 4) NULL,
	[ClienteID] [int] NULL,
	[CentroCostoDestinoID] [int] NOT NULL,
	[BodegaOrigenMPID] [int] NOT NULL,
	[BodegaDestinoPTID] [int] NOT NULL,
	[CentroTrabajoID] [int] NULL,
	[FechaPlanificada] [datetime2](7) NULL,
	[FechaInicio] [datetime2](7) NULL,
	[FechaFin] [datetime2](7) NULL,
	[CostoMateriales] [decimal](18, 4) NOT NULL,
	[CostoMOD] [decimal](18, 4) NOT NULL,
	[CostoCIF] [decimal](18, 4) NOT NULL,
	[CostoUnitarioReal] [decimal](18, 4) NULL,
	[UsuarioCreaID] [int] NOT NULL,
	[UsuarioLiberaID] [int] NULL,
	[UsuarioCierraID] [int] NULL,
	[Observaciones] [nvarchar](500) NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[OrdenProduccionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[CodigoOP] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [Produccion].[vw_ProduccionPlanVsReal]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   VIEW [Produccion].[vw_ProduccionPlanVsReal] AS
SELECT
    CAST(op.FechaPlanificada AS DATE) AS Fecha,
    cc.CentroCostoID,
    cc.Nombre AS CentroCosto,
    a.Nombre AS Producto,
    SUM(op.CantidadProgramada) AS TotalPlanificado,
    SUM(ISNULL(op.CantidadProducidaReal,0)) AS TotalReal
FROM Produccion.OrdenesProduccion op
JOIN Organizacion.CentrosCosto cc ON cc.CentroCostoID = op.CentroCostoDestinoID
JOIN Catalogo.Articulos a ON a.ArticuloID = op.ProductoTerminadoID
GROUP BY CAST(op.FechaPlanificada AS DATE), cc.CentroCostoID, cc.Nombre, a.Nombre;
GO
/****** Object:  Table [Produccion].[EstadosOP]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Produccion].[EstadosOP](
	[EstadoOPID] [int] IDENTITY(1,1) NOT NULL,
	[Nombre] [nvarchar](30) NOT NULL,
	[Orden] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[EstadoOPID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[Nombre] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [Produccion].[vw_DistribucionPorCentroCosto]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ----------------------------------------------------------------------------
CREATE   VIEW [Produccion].[vw_DistribucionPorCentroCosto] AS
SELECT
    cc.CentroCostoID,
    cc.Nombre AS CentroCosto,
    COUNT(op.OrdenProduccionID) AS TotalOrdenes,
    SUM(ISNULL(op.CantidadProducidaReal,0)) AS TotalUnidadesProducidas,
    SUM(op.CostoMateriales + op.CostoMOD + op.CostoCIF) AS InversionTotal
FROM Produccion.OrdenesProduccion op
JOIN Organizacion.CentrosCosto cc ON cc.CentroCostoID = op.CentroCostoDestinoID
WHERE op.EstadoOPID = (SELECT EstadoOPID FROM Produccion.EstadosOP WHERE Nombre = 'Finalizada')
GROUP BY cc.CentroCostoID, cc.Nombre;
GO
/****** Object:  Table [Kardex].[TiposMotivoLoss]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Kardex].[TiposMotivoLoss](
	[MotivoID] [int] IDENTITY(1,1) NOT NULL,
	[Nombre] [nvarchar](100) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[MotivoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[Nombre] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Kardex].[BajasInventarioPerdidas]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Kardex].[BajasInventarioPerdidas](
	[BajaID] [int] IDENTITY(1,1) NOT NULL,
	[CodigoBaja] [nvarchar](30) NOT NULL,
	[Fecha] [datetime2](7) NOT NULL,
	[ArticuloID] [int] NOT NULL,
	[BodegaID] [int] NOT NULL,
	[LoteID] [int] NULL,
	[CantidadPerdida] [decimal](18, 4) NOT NULL,
	[CostoUnitario] [decimal](18, 4) NOT NULL,
	[CostoTotal]  AS ([CantidadPerdida]*[CostoUnitario]) PERSISTED,
	[MotivoID] [int] NOT NULL,
	[ObservacionDetallada] [nvarchar](500) NOT NULL,
	[UsuarioRegistraID] [int] NOT NULL,
	[Estado] [nvarchar](20) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[BajaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[CodigoBaja] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [Kardex].[vw_PerdidasPorMotivo]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   VIEW [Kardex].[vw_PerdidasPorMotivo] AS
SELECT
    m.Nombre AS Motivo,
    CAST(b.Fecha AS DATE) AS Fecha,
    COUNT(*) AS TotalEventos,
    SUM(b.CantidadPerdida) AS CantidadTotalPerdida,
    SUM(b.CostoTotal) AS ValorTotalPerdido
FROM Kardex.BajasInventarioPerdidas b
JOIN Kardex.TiposMotivoLoss m ON m.MotivoID = b.MotivoID
WHERE b.Estado = 'CONFIRMADA'
GROUP BY m.Nombre, CAST(b.Fecha AS DATE);
GO
/****** Object:  View [Produccion].[vw_TendenciaCostoUnitario]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   VIEW [Produccion].[vw_TendenciaCostoUnitario] AS
SELECT
    a.ArticuloID,
    a.Nombre AS Producto,
    CAST(op.FechaFin AS DATE) AS Fecha,
    op.CostoUnitarioReal
FROM Produccion.OrdenesProduccion op
JOIN Catalogo.Articulos a ON a.ArticuloID = op.ProductoTerminadoID
WHERE op.EstadoOPID = (SELECT EstadoOPID FROM Produccion.EstadosOP WHERE Nombre = 'Finalizada')
  AND op.FechaFin IS NOT NULL;
GO
/****** Object:  View [Produccion].[vw_CumplimientoPlanificacion]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   VIEW [Produccion].[vw_CumplimientoPlanificacion] AS
SELECT
    cc.CentroCostoID,
    cc.Nombre AS CentroCosto,
    COUNT(*) AS TotalOrdenesFinalizadas,
    SUM(CASE WHEN op.FechaFin <= op.FechaPlanificada THEN 1 ELSE 0 END) AS OrdenesATiempo,
    CAST(SUM(CASE WHEN op.FechaFin <= op.FechaPlanificada THEN 1 ELSE 0 END) AS DECIMAL(18,4))
        / NULLIF(COUNT(*),0) * 100 AS PorcentajeCumplimiento
FROM Produccion.OrdenesProduccion op
JOIN Organizacion.CentrosCosto cc ON cc.CentroCostoID = op.CentroCostoDestinoID
WHERE op.EstadoOPID = (SELECT EstadoOPID FROM Produccion.EstadosOP WHERE Nombre = 'Finalizada')
GROUP BY cc.CentroCostoID, cc.Nombre;
GO
/****** Object:  Table [Inventario].[Bodegas]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Inventario].[Bodegas](
	[BodegaID] [int] IDENTITY(1,1) NOT NULL,
	[Nombre] [nvarchar](100) NOT NULL,
	[CentroCostoID] [int] NOT NULL,
	[TipoBodega] [nvarchar](20) NOT NULL,
	[EsVirtual] [bit] NOT NULL,
	[Estado] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[BodegaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Inventario].[Lotes]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Inventario].[Lotes](
	[LoteID] [int] IDENTITY(1,1) NOT NULL,
	[ArticuloID] [int] NOT NULL,
	[NumeroLote] [nvarchar](50) NOT NULL,
	[FechaFabricacion] [date] NULL,
	[FechaVencimiento] [date] NULL,
	[ProveedorID] [int] NULL,
	[Estado] [nvarchar](20) NOT NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[LoteID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_Lote_Articulo] UNIQUE NONCLUSTERED 
(
	[ArticuloID] ASC,
	[NumeroLote] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Inventario].[InventarioStock]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Inventario].[InventarioStock](
	[InventarioID] [int] IDENTITY(1,1) NOT NULL,
	[ArticuloID] [int] NOT NULL,
	[BodegaID] [int] NOT NULL,
	[LoteID] [int] NULL,
	[CantidadActual] [decimal](18, 4) NOT NULL,
	[CostoUnitarioLote] [decimal](18, 4) NOT NULL,
	[FechaUltimaActualizacion] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[InventarioID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_Stock_Articulo_Bodega_Lote] UNIQUE NONCLUSTERED 
(
	[ArticuloID] ASC,
	[BodegaID] ASC,
	[LoteID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [catalogo].[TiposArticulo]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [catalogo].[TiposArticulo](
	[TipoArticuloID] [int] IDENTITY(1,1) NOT NULL,
	[Codigo] [nvarchar](20) NOT NULL,
	[Nombre] [nvarchar](50) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[TipoArticuloID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [Inventario].[vw_StockConsolidado]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [Inventario].[vw_StockConsolidado] AS
SELECT
    a.ArticuloID, a.SKU, a.Nombre AS Articulo, ta.Nombre AS TipoArticulo,
    u.Abreviatura AS Unidad, a.UnidadesPorEmbalaje,
    b.BodegaID, b.Nombre AS Bodega, cc.CentroCostoID, cc.Nombre AS CentroCosto,
    l.LoteID, l.NumeroLote, l.FechaVencimiento,
    s.CantidadActual, s.CostoUnitarioLote,
    (s.CantidadActual * s.CostoUnitarioLote) AS ValorTotal,
    CASE WHEN s.CantidadActual <= a.PuntoReorden THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS RequierePedido
FROM Inventario.InventarioStock s
JOIN Catalogo.Articulos a ON a.ArticuloID = s.ArticuloID
JOIN Catalogo.TiposArticulo ta ON ta.TipoArticuloID = a.TipoArticuloID
JOIN Inventario.Bodegas b ON b.BodegaID = s.BodegaID
JOIN Organizacion.CentrosCosto cc ON cc.CentroCostoID = b.CentroCostoID
LEFT JOIN Inventario.Lotes l ON l.LoteID = s.LoteID
LEFT JOIN Catalogo.UnidadesMedida u ON u.UnidadID = a.UnidadID;
-- Nota: sin filtro de CantidadActual > 0 -- los articulos en 0 se siguen
-- mostrando (con alerta "Sin stock" en el frontend) en vez de desaparecer.
GO
/****** Object:  Table [Auditoria].[LogAuditoria]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Auditoria].[LogAuditoria](
	[LogID] [bigint] IDENTITY(1,1) NOT NULL,
	[EsquemaTabla] [nvarchar](100) NOT NULL,
	[RegistroID] [nvarchar](50) NOT NULL,
	[Accion] [nvarchar](10) NOT NULL,
	[UsuarioID] [int] NULL,
	[Fecha] [datetime2](7) NOT NULL,
	[ValoresAnteriores] [nvarchar](max) NULL,
	[ValoresNuevos] [nvarchar](max) NULL,
PRIMARY KEY CLUSTERED 
(
	[LogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [catalogo].[ArticuloProveedor]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [catalogo].[ArticuloProveedor](
	[ArticuloID] [int] NOT NULL,
	[ProveedorID] [int] NOT NULL,
	[CodigoProveedor] [nvarchar](50) NULL,
	[CostoUltimaCompra] [decimal](18, 4) NULL,
	[TiempoEntregaDias] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[ArticuloID] ASC,
	[ProveedorID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [catalogo].[Clientes]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [catalogo].[Clientes](
	[ClienteID] [int] IDENTITY(1,1) NOT NULL,
	[Nombre] [nvarchar](150) NOT NULL,
	[NIT] [nvarchar](30) NULL,
	[Contacto] [nvarchar](100) NULL,
	[Telefono] [nvarchar](30) NULL,
	[Email] [nvarchar](150) NULL,
	[Direccion] [nvarchar](200) NULL,
	[Estado] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ClienteID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [catalogo].[Proveedores]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [catalogo].[Proveedores](
	[ProveedorID] [int] IDENTITY(1,1) NOT NULL,
	[RazonSocial] [nvarchar](150) NOT NULL,
	[NIT] [nvarchar](30) NOT NULL,
	[Contacto] [nvarchar](100) NULL,
	[Telefono] [nvarchar](30) NULL,
	[Email] [nvarchar](150) NULL,
	[Direccion] [nvarchar](200) NULL,
	[Estado] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ProveedorID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[NIT] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [catalogo].[UnidadesConversion]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [catalogo].[UnidadesConversion](
	[UnidadOrigenID] [int] NOT NULL,
	[UnidadDestinoID] [int] NOT NULL,
	[Factor] [decimal](18, 8) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[UnidadOrigenID] ASC,
	[UnidadDestinoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [catalogo].[UnidadesMedida]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [catalogo].[UnidadesMedida](
	[UnidadID] [int] IDENTITY(1,1) NOT NULL,
	[Nombre] [nvarchar](30) NOT NULL,
	[Abreviatura] [nvarchar](10) NOT NULL,
	[Tipo] [nvarchar](20) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[UnidadID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[Abreviatura] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Compras].[OrdenesCompra]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Compras].[OrdenesCompra](
	[OrdenCompraID] [int] IDENTITY(1,1) NOT NULL,
	[Codigo] [nvarchar](30) NOT NULL,
	[ProveedorID] [int] NOT NULL,
	[BodegaDestinoID] [int] NOT NULL,
	[EstadoOC] [nvarchar](20) NOT NULL,
	[FechaEmision] [datetime2](7) NOT NULL,
	[FechaRecepcion] [datetime2](7) NULL,
	[UsuarioID] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[OrdenCompraID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Compras].[OrdenesCompraDetalle]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Compras].[OrdenesCompraDetalle](
	[OrdenCompraDetalleID] [int] IDENTITY(1,1) NOT NULL,
	[OrdenCompraID] [int] NOT NULL,
	[ArticuloID] [int] NOT NULL,
	[CantidadSolicitada] [decimal](18, 4) NOT NULL,
	[CantidadRecibida] [decimal](18, 4) NOT NULL,
	[CostoUnitario] [decimal](18, 4) NOT NULL,
	[LoteID] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[OrdenCompraDetalleID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Integracion].[AgentesSync]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Integracion].[AgentesSync](
	[AgenteSyncID] [int] IDENTITY(1,1) NOT NULL,
	[CentroCostoID] [int] NOT NULL,
	[ApiKeyHash] [char](64) NOT NULL,
	[Descripcion] [nvarchar](150) NULL,
	[Activo] [bit] NOT NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
	[UltimaConexion] [datetime2](7) NULL,
PRIMARY KEY CLUSTERED 
(
	[AgenteSyncID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[ApiKeyHash] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Integracion].[EventosEntrantes]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Integracion].[EventosEntrantes](
	[EventoEntranteID] [bigint] IDENTITY(1,1) NOT NULL,
	[IdEventoExterno] [nvarchar](150) NOT NULL,
	[TipoEvento] [nvarchar](50) NOT NULL,
	[CentroCostoID] [int] NOT NULL,
	[CodigoArticuloVisions] [nvarchar](30) NOT NULL,
	[Cantidad] [decimal](18, 4) NOT NULL,
	[FechaEventoOrigen] [datetime2](7) NOT NULL,
	[Procesado] [bit] NOT NULL,
	[FechaRecepcion] [datetime2](7) NOT NULL,
	[FechaProcesado] [datetime2](7) NULL,
PRIMARY KEY CLUSTERED 
(
	[EventoEntranteID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[IdEventoExterno] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Integracion].[InventarioReportadoVisions]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Integracion].[InventarioReportadoVisions](
	[ArticuloID] [int] NOT NULL,
	[CentroCostoID] [int] NOT NULL,
	[CantidadVendidaAcumulada] [decimal](18, 4) NOT NULL,
	[UltimaActualizacion] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ArticuloID] ASC,
	[CentroCostoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Inventario].[TraspasosBodega]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Inventario].[TraspasosBodega](
	[TraspasoID] [int] IDENTITY(1,1) NOT NULL,
	[Codigo] [nvarchar](30) NOT NULL,
	[BodegaOrigenID] [int] NOT NULL,
	[BodegaDestinoID] [int] NOT NULL,
	[EstadoTraspaso] [nvarchar](20) NOT NULL,
	[FechaEnvio] [datetime2](7) NULL,
	[FechaRecepcion] [datetime2](7) NULL,
	[UsuarioEnviaID] [int] NULL,
	[UsuarioRecibeID] [int] NULL,
	[Observaciones] [nvarchar](300) NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[TraspasoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Inventario].[TraspasosDetalle]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Inventario].[TraspasosDetalle](
	[TraspasoDetalleID] [int] IDENTITY(1,1) NOT NULL,
	[TraspasoID] [int] NOT NULL,
	[ArticuloID] [int] NOT NULL,
	[LoteID] [int] NULL,
	[CantidadEnviada] [decimal](18, 4) NOT NULL,
	[CantidadRecibida] [decimal](18, 4) NULL,
	[CostoUnitario] [decimal](18, 4) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[TraspasoDetalleID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Kardex].[KardexMovimientos]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Kardex].[KardexMovimientos](
	[KardexID] [bigint] IDENTITY(1,1) NOT NULL,
	[Fecha] [datetime2](7) NOT NULL,
	[ArticuloID] [int] NOT NULL,
	[BodegaID] [int] NOT NULL,
	[LoteID] [int] NULL,
	[TipoMovID] [int] NOT NULL,
	[OrdenProduccionID] [int] NULL,
	[TraspasoID] [int] NULL,
	[OrdenCompraID] [int] NULL,
	[BajaID] [int] NULL,
	[CentroCostoID] [int] NOT NULL,
	[Cantidad] [decimal](18, 4) NOT NULL,
	[CostoUnitario] [decimal](18, 4) NOT NULL,
	[CantidadSaldo] [decimal](18, 4) NOT NULL,
	[CostoPromedioSaldo] [decimal](18, 4) NOT NULL,
	[ObservacionDetallada] [nvarchar](500) NULL,
	[UsuarioID] [int] NOT NULL,
	[FechaRegistro] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[KardexID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Kardex].[TiposMovimientoKardex]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Kardex].[TiposMovimientoKardex](
	[TipoMovID] [int] IDENTITY(1,1) NOT NULL,
	[Codigo] [nvarchar](30) NOT NULL,
	[Nombre] [nvarchar](80) NOT NULL,
	[Signo] [smallint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[TipoMovID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Organizacion].[CentrosTrabajo]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Organizacion].[CentrosTrabajo](
	[CentroTrabajoID] [int] IDENTITY(1,1) NOT NULL,
	[Nombre] [nvarchar](100) NOT NULL,
	[CentroCostoID] [int] NOT NULL,
	[CostoHoraManoObra] [decimal](18, 4) NOT NULL,
	[CostoHoraCIF] [decimal](18, 4) NOT NULL,
	[Estado] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[CentroTrabajoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Produccion].[MotivosExcesoConsumo]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Produccion].[MotivosExcesoConsumo](
	[MotivoExcesoID] [int] IDENTITY(1,1) NOT NULL,
	[Nombre] [nvarchar](150) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[MotivoExcesoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Produccion].[OrdenesProduccionConsumo]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Produccion].[OrdenesProduccionConsumo](
	[ConsumoID] [bigint] IDENTITY(1,1) NOT NULL,
	[OrdenProduccionID] [int] NOT NULL,
	[ArticuloID] [int] NOT NULL,
	[LoteID] [int] NULL,
	[CantidadTeorica] [decimal](18, 4) NOT NULL,
	[CantidadReal] [decimal](18, 4) NOT NULL,
	[MotivoExcesoID] [int] NULL,
	[Observacion] [nvarchar](300) NULL,
PRIMARY KEY CLUSTERED 
(
	[ConsumoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Produccion].[RecetaBOM]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Produccion].[RecetaBOM](
	[RecetaID] [int] IDENTITY(1,1) NOT NULL,
	[ProductoTerminadoID] [int] NOT NULL,
	[NombreReceta] [nvarchar](150) NOT NULL,
	[Version] [int] NOT NULL,
	[CantidadRendimientoBase] [decimal](18, 4) NOT NULL,
	[UnidadRendimientoID] [int] NOT NULL,
	[Estado] [bit] NOT NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[RecetaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Produccion].[RecetaBOM_Detalle]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Produccion].[RecetaBOM_Detalle](
	[RecetaDetalleID] [int] IDENTITY(1,1) NOT NULL,
	[RecetaID] [int] NOT NULL,
	[InsumoID] [int] NOT NULL,
	[CantidadRequerida] [decimal](18, 4) NOT NULL,
	[UnidadID] [int] NOT NULL,
	[PorcentajeMermaEstandar] [decimal](5, 2) NOT NULL,
	[CentroTrabajoID] [int] NULL,
	[Orden] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[RecetaDetalleID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Produccion].[TiposProduccion]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Produccion].[TiposProduccion](
	[TipoProduccionID] [int] IDENTITY(1,1) NOT NULL,
	[Codigo] [nvarchar](20) NOT NULL,
	[Nombre] [nvarchar](80) NOT NULL,
	[Descripcion] [nvarchar](200) NULL,
PRIMARY KEY CLUSTERED 
(
	[TipoProduccionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Seguridad].[Permisos]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Seguridad].[Permisos](
	[PermisoID] [int] IDENTITY(1,1) NOT NULL,
	[Codigo] [nvarchar](80) NOT NULL,
	[Modulo] [nvarchar](50) NOT NULL,
	[Descripcion] [nvarchar](200) NULL,
PRIMARY KEY CLUSTERED 
(
	[PermisoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Seguridad].[Roles]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Seguridad].[Roles](
	[RolID] [int] IDENTITY(1,1) NOT NULL,
	[Nombre] [nvarchar](50) NOT NULL,
	[Descripcion] [nvarchar](200) NULL,
	[Estado] [bit] NOT NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[RolID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[Nombre] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Seguridad].[RolPermisos]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Seguridad].[RolPermisos](
	[RolID] [int] NOT NULL,
	[PermisoID] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[RolID] ASC,
	[PermisoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Seguridad].[SesionesUsuario]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Seguridad].[SesionesUsuario](
	[SesionID] [bigint] IDENTITY(1,1) NOT NULL,
	[UsuarioID] [int] NOT NULL,
	[Token] [nvarchar](500) NOT NULL,
	[RefreshToken] [nvarchar](500) NOT NULL,
	[FechaInicio] [datetime2](7) NOT NULL,
	[FechaExpiracion] [datetime2](7) NOT NULL,
	[DireccionIP] [nvarchar](50) NULL,
	[Activa] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[SesionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Seguridad].[Usuarios]    Script Date: 1/08/2026 11:00:07 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Seguridad].[Usuarios](
	[UsuarioID] [int] IDENTITY(1,1) NOT NULL,
	[Nombres] [nvarchar](100) NOT NULL,
	[Apellidos] [nvarchar](100) NOT NULL,
	[Email] [nvarchar](150) NOT NULL,
	[Username] [nvarchar](50) NOT NULL,
	[PasswordHash] [varbinary](256) NOT NULL,
	[Salt] [varbinary](128) NOT NULL,
	[RolID] [int] NOT NULL,
	[CentroCostoID] [int] NULL,
	[Estado] [bit] NOT NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
	[UltimoAcceso] [datetime2](7) NULL,
PRIMARY KEY CLUSTERED 
(
	[UsuarioID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[Username] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[Email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Log_Tabla_Registro]    Script Date: 1/08/2026 11:00:07 a. m. ******/
CREATE NONCLUSTERED INDEX [IX_Log_Tabla_Registro] ON [Auditoria].[LogAuditoria]
(
	[EsquemaTabla] ASC,
	[RegistroID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Articulos_Tipo]    Script Date: 1/08/2026 11:00:07 a. m. ******/
CREATE NONCLUSTERED INDEX [IX_Articulos_Tipo] ON [catalogo].[Articulos]
(
	[TipoArticuloID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_AgentesSync_CentroCosto]    Script Date: 1/08/2026 11:00:07 a. m. ******/
CREATE NONCLUSTERED INDEX [IX_AgentesSync_CentroCosto] ON [Integracion].[AgentesSync]
(
	[CentroCostoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_EventosEntrantes_Pendientes]    Script Date: 1/08/2026 11:00:07 a. m. ******/
CREATE NONCLUSTERED INDEX [IX_EventosEntrantes_Pendientes] ON [Integracion].[EventosEntrantes]
(
	[Procesado] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_EventosSalientes_Pendientes]    Script Date: 1/08/2026 11:00:07 a. m. ******/
CREATE NONCLUSTERED INDEX [IX_EventosSalientes_Pendientes] ON [Integracion].[EventosSalientes]
(
	[Estado] ASC,
	[CentroCostoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Stock_ArticuloBodega]    Script Date: 1/08/2026 11:00:07 a. m. ******/
CREATE NONCLUSTERED INDEX [IX_Stock_ArticuloBodega] ON [Inventario].[InventarioStock]
(
	[ArticuloID] ASC,
	[BodegaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Lotes_Vencimiento]    Script Date: 1/08/2026 11:00:07 a. m. ******/
CREATE NONCLUSTERED INDEX [IX_Lotes_Vencimiento] ON [Inventario].[Lotes]
(
	[ArticuloID] ASC,
	[FechaVencimiento] ASC
)
INCLUDE([Estado]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Kardex_Articulo_Bodega_Fecha]    Script Date: 1/08/2026 11:00:07 a. m. ******/
CREATE NONCLUSTERED INDEX [IX_Kardex_Articulo_Bodega_Fecha] ON [Kardex].[KardexMovimientos]
(
	[ArticuloID] ASC,
	[BodegaID] ASC,
	[Fecha] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Kardex_CentroCosto_Fecha]    Script Date: 1/08/2026 11:00:07 a. m. ******/
CREATE NONCLUSTERED INDEX [IX_Kardex_CentroCosto_Fecha] ON [Kardex].[KardexMovimientos]
(
	[CentroCostoID] ASC,
	[Fecha] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Kardex_OP]    Script Date: 1/08/2026 11:00:07 a. m. ******/
CREATE NONCLUSTERED INDEX [IX_Kardex_OP] ON [Kardex].[KardexMovimientos]
(
	[OrdenProduccionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_OP_CentroCosto]    Script Date: 1/08/2026 11:00:07 a. m. ******/
CREATE NONCLUSTERED INDEX [IX_OP_CentroCosto] ON [Produccion].[OrdenesProduccion]
(
	[CentroCostoDestinoID] ASC,
	[EstadoOPID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_OP_Fechas]    Script Date: 1/08/2026 11:00:07 a. m. ******/
CREATE NONCLUSTERED INDEX [IX_OP_Fechas] ON [Produccion].[OrdenesProduccion]
(
	[FechaInicio] ASC,
	[FechaFin] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_RecetaDetalle_Insumo]    Script Date: 1/08/2026 11:00:07 a. m. ******/
CREATE NONCLUSTERED INDEX [IX_RecetaDetalle_Insumo] ON [Produccion].[RecetaBOM_Detalle]
(
	[InsumoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Sesiones_Usuario]    Script Date: 1/08/2026 11:00:07 a. m. ******/
CREATE NONCLUSTERED INDEX [IX_Sesiones_Usuario] ON [Seguridad].[SesionesUsuario]
(
	[UsuarioID] ASC,
	[Activa] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [Auditoria].[LogAuditoria] ADD  DEFAULT (sysutcdatetime()) FOR [Fecha]
GO
ALTER TABLE [catalogo].[Articulos] ADD  DEFAULT ((0)) FOR [CostoPromedio]
GO
ALTER TABLE [catalogo].[Articulos] ADD  DEFAULT ((0)) FOR [PrecioVenta]
GO
ALTER TABLE [catalogo].[Articulos] ADD  DEFAULT ((0)) FOR [StockMinimo]
GO
ALTER TABLE [catalogo].[Articulos] ADD  DEFAULT ((0)) FOR [PuntoReorden]
GO
ALTER TABLE [catalogo].[Articulos] ADD  DEFAULT ((1)) FOR [Estado]
GO
ALTER TABLE [catalogo].[Articulos] ADD  DEFAULT (sysutcdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [catalogo].[Clientes] ADD  DEFAULT ((1)) FOR [Estado]
GO
ALTER TABLE [catalogo].[Proveedores] ADD  DEFAULT ((1)) FOR [Estado]
GO
ALTER TABLE [Compras].[OrdenesCompra] ADD  DEFAULT ('PENDIENTE') FOR [EstadoOC]
GO
ALTER TABLE [Compras].[OrdenesCompra] ADD  DEFAULT (sysutcdatetime()) FOR [FechaEmision]
GO
ALTER TABLE [Compras].[OrdenesCompraDetalle] ADD  DEFAULT ((0)) FOR [CantidadRecibida]
GO
ALTER TABLE [Integracion].[AgentesSync] ADD  DEFAULT ((1)) FOR [Activo]
GO
ALTER TABLE [Integracion].[AgentesSync] ADD  DEFAULT (sysutcdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Integracion].[EventosEntrantes] ADD  DEFAULT ((0)) FOR [Procesado]
GO
ALTER TABLE [Integracion].[EventosEntrantes] ADD  DEFAULT (sysutcdatetime()) FOR [FechaRecepcion]
GO
ALTER TABLE [Integracion].[EventosSalientes] ADD  DEFAULT ('PENDIENTE') FOR [Estado]
GO
ALTER TABLE [Integracion].[EventosSalientes] ADD  DEFAULT ((0)) FOR [IntentosEnvio]
GO
ALTER TABLE [Integracion].[EventosSalientes] ADD  DEFAULT (sysutcdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Integracion].[InventarioReportadoVisions] ADD  DEFAULT ((0)) FOR [CantidadVendidaAcumulada]
GO
ALTER TABLE [Integracion].[InventarioReportadoVisions] ADD  DEFAULT (sysutcdatetime()) FOR [UltimaActualizacion]
GO
ALTER TABLE [Integracion].[MapeoArticulos] ADD  DEFAULT ((1)) FOR [Estado]
GO
ALTER TABLE [Integracion].[MapeoArticulos] ADD  DEFAULT (sysutcdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Inventario].[Bodegas] ADD  DEFAULT ((0)) FOR [EsVirtual]
GO
ALTER TABLE [Inventario].[Bodegas] ADD  DEFAULT ((1)) FOR [Estado]
GO
ALTER TABLE [Inventario].[InventarioStock] ADD  DEFAULT ((0)) FOR [CantidadActual]
GO
ALTER TABLE [Inventario].[InventarioStock] ADD  DEFAULT ((0)) FOR [CostoUnitarioLote]
GO
ALTER TABLE [Inventario].[InventarioStock] ADD  DEFAULT (sysutcdatetime()) FOR [FechaUltimaActualizacion]
GO
ALTER TABLE [Inventario].[Lotes] ADD  DEFAULT ('APROBADO') FOR [Estado]
GO
ALTER TABLE [Inventario].[Lotes] ADD  DEFAULT (sysutcdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Inventario].[TraspasosBodega] ADD  DEFAULT ('PENDIENTE') FOR [EstadoTraspaso]
GO
ALTER TABLE [Inventario].[TraspasosBodega] ADD  DEFAULT (sysutcdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Kardex].[BajasInventarioPerdidas] ADD  DEFAULT (sysutcdatetime()) FOR [Fecha]
GO
ALTER TABLE [Kardex].[BajasInventarioPerdidas] ADD  DEFAULT ('CONFIRMADA') FOR [Estado]
GO
ALTER TABLE [Kardex].[KardexMovimientos] ADD  DEFAULT (sysutcdatetime()) FOR [Fecha]
GO
ALTER TABLE [Kardex].[KardexMovimientos] ADD  DEFAULT (sysutcdatetime()) FOR [FechaRegistro]
GO
ALTER TABLE [Organizacion].[CentrosCosto] ADD  DEFAULT ((1)) FOR [Estado]
GO
ALTER TABLE [Organizacion].[CentrosCosto] ADD  DEFAULT (sysutcdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Organizacion].[CentrosCosto] ADD  DEFAULT ((0)) FOR [TieneVisions]
GO
ALTER TABLE [Organizacion].[CentrosTrabajo] ADD  DEFAULT ((0)) FOR [CostoHoraManoObra]
GO
ALTER TABLE [Organizacion].[CentrosTrabajo] ADD  DEFAULT ((0)) FOR [CostoHoraCIF]
GO
ALTER TABLE [Organizacion].[CentrosTrabajo] ADD  DEFAULT ((1)) FOR [Estado]
GO
ALTER TABLE [Produccion].[OrdenesProduccion] ADD  DEFAULT ((0)) FOR [CostoMateriales]
GO
ALTER TABLE [Produccion].[OrdenesProduccion] ADD  DEFAULT ((0)) FOR [CostoMOD]
GO
ALTER TABLE [Produccion].[OrdenesProduccion] ADD  DEFAULT ((0)) FOR [CostoCIF]
GO
ALTER TABLE [Produccion].[OrdenesProduccion] ADD  DEFAULT (sysutcdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Produccion].[RecetaBOM] ADD  DEFAULT ((1)) FOR [Version]
GO
ALTER TABLE [Produccion].[RecetaBOM] ADD  DEFAULT ((1)) FOR [Estado]
GO
ALTER TABLE [Produccion].[RecetaBOM] ADD  DEFAULT (sysutcdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Produccion].[RecetaBOM_Detalle] ADD  DEFAULT ((0)) FOR [PorcentajeMermaEstandar]
GO
ALTER TABLE [Produccion].[RecetaBOM_Detalle] ADD  DEFAULT ((1)) FOR [Orden]
GO
ALTER TABLE [Seguridad].[Roles] ADD  DEFAULT ((1)) FOR [Estado]
GO
ALTER TABLE [Seguridad].[Roles] ADD  DEFAULT (sysutcdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Seguridad].[SesionesUsuario] ADD  DEFAULT (sysutcdatetime()) FOR [FechaInicio]
GO
ALTER TABLE [Seguridad].[SesionesUsuario] ADD  DEFAULT ((1)) FOR [Activa]
GO
ALTER TABLE [Seguridad].[Usuarios] ADD  DEFAULT ((1)) FOR [Estado]
GO
ALTER TABLE [Seguridad].[Usuarios] ADD  DEFAULT (sysutcdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Auditoria].[LogAuditoria]  WITH CHECK ADD FOREIGN KEY([UsuarioID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [catalogo].[ArticuloProveedor]  WITH CHECK ADD FOREIGN KEY([ArticuloID])
REFERENCES [catalogo].[Articulos] ([ArticuloID])
GO
ALTER TABLE [catalogo].[ArticuloProveedor]  WITH CHECK ADD FOREIGN KEY([ProveedorID])
REFERENCES [catalogo].[Proveedores] ([ProveedorID])
GO
ALTER TABLE [catalogo].[Articulos]  WITH CHECK ADD FOREIGN KEY([TipoArticuloID])
REFERENCES [catalogo].[TiposArticulo] ([TipoArticuloID])
GO
ALTER TABLE [catalogo].[Articulos]  WITH CHECK ADD FOREIGN KEY([UnidadID])
REFERENCES [catalogo].[UnidadesMedida] ([UnidadID])
GO
ALTER TABLE [catalogo].[UnidadesConversion]  WITH CHECK ADD FOREIGN KEY([UnidadOrigenID])
REFERENCES [catalogo].[UnidadesMedida] ([UnidadID])
GO
ALTER TABLE [catalogo].[UnidadesConversion]  WITH CHECK ADD FOREIGN KEY([UnidadDestinoID])
REFERENCES [catalogo].[UnidadesMedida] ([UnidadID])
GO
ALTER TABLE [Compras].[OrdenesCompra]  WITH CHECK ADD FOREIGN KEY([BodegaDestinoID])
REFERENCES [Inventario].[Bodegas] ([BodegaID])
GO
ALTER TABLE [Compras].[OrdenesCompra]  WITH CHECK ADD FOREIGN KEY([ProveedorID])
REFERENCES [catalogo].[Proveedores] ([ProveedorID])
GO
ALTER TABLE [Compras].[OrdenesCompra]  WITH CHECK ADD FOREIGN KEY([UsuarioID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Compras].[OrdenesCompraDetalle]  WITH CHECK ADD FOREIGN KEY([ArticuloID])
REFERENCES [catalogo].[Articulos] ([ArticuloID])
GO
ALTER TABLE [Compras].[OrdenesCompraDetalle]  WITH CHECK ADD FOREIGN KEY([LoteID])
REFERENCES [Inventario].[Lotes] ([LoteID])
GO
ALTER TABLE [Compras].[OrdenesCompraDetalle]  WITH CHECK ADD FOREIGN KEY([OrdenCompraID])
REFERENCES [Compras].[OrdenesCompra] ([OrdenCompraID])
GO
ALTER TABLE [Integracion].[AgentesSync]  WITH CHECK ADD FOREIGN KEY([CentroCostoID])
REFERENCES [Organizacion].[CentrosCosto] ([CentroCostoID])
GO
ALTER TABLE [Integracion].[EventosEntrantes]  WITH CHECK ADD FOREIGN KEY([CentroCostoID])
REFERENCES [Organizacion].[CentrosCosto] ([CentroCostoID])
GO
ALTER TABLE [Integracion].[EventosSalientes]  WITH CHECK ADD FOREIGN KEY([ArticuloID])
REFERENCES [catalogo].[Articulos] ([ArticuloID])
GO
ALTER TABLE [Integracion].[EventosSalientes]  WITH CHECK ADD FOREIGN KEY([CentroCostoID])
REFERENCES [Organizacion].[CentrosCosto] ([CentroCostoID])
GO
ALTER TABLE [Integracion].[EventosSalientes]  WITH CHECK ADD FOREIGN KEY([KardexID])
REFERENCES [Kardex].[KardexMovimientos] ([KardexID])
GO
ALTER TABLE [Integracion].[InventarioReportadoVisions]  WITH CHECK ADD FOREIGN KEY([ArticuloID])
REFERENCES [catalogo].[Articulos] ([ArticuloID])
GO
ALTER TABLE [Integracion].[InventarioReportadoVisions]  WITH CHECK ADD FOREIGN KEY([CentroCostoID])
REFERENCES [Organizacion].[CentrosCosto] ([CentroCostoID])
GO
ALTER TABLE [Integracion].[MapeoArticulos]  WITH CHECK ADD FOREIGN KEY([ArticuloID])
REFERENCES [catalogo].[Articulos] ([ArticuloID])
GO
ALTER TABLE [Integracion].[MapeoArticulos]  WITH CHECK ADD FOREIGN KEY([CentroCostoID])
REFERENCES [Organizacion].[CentrosCosto] ([CentroCostoID])
GO
ALTER TABLE [Inventario].[Bodegas]  WITH CHECK ADD FOREIGN KEY([CentroCostoID])
REFERENCES [Organizacion].[CentrosCosto] ([CentroCostoID])
GO
ALTER TABLE [Inventario].[InventarioStock]  WITH CHECK ADD FOREIGN KEY([ArticuloID])
REFERENCES [catalogo].[Articulos] ([ArticuloID])
GO
ALTER TABLE [Inventario].[InventarioStock]  WITH CHECK ADD FOREIGN KEY([BodegaID])
REFERENCES [Inventario].[Bodegas] ([BodegaID])
GO
ALTER TABLE [Inventario].[InventarioStock]  WITH CHECK ADD FOREIGN KEY([LoteID])
REFERENCES [Inventario].[Lotes] ([LoteID])
GO
ALTER TABLE [Inventario].[Lotes]  WITH CHECK ADD FOREIGN KEY([ArticuloID])
REFERENCES [catalogo].[Articulos] ([ArticuloID])
GO
ALTER TABLE [Inventario].[Lotes]  WITH CHECK ADD FOREIGN KEY([ProveedorID])
REFERENCES [catalogo].[Proveedores] ([ProveedorID])
GO
ALTER TABLE [Inventario].[TraspasosBodega]  WITH CHECK ADD FOREIGN KEY([BodegaOrigenID])
REFERENCES [Inventario].[Bodegas] ([BodegaID])
GO
ALTER TABLE [Inventario].[TraspasosBodega]  WITH CHECK ADD FOREIGN KEY([BodegaDestinoID])
REFERENCES [Inventario].[Bodegas] ([BodegaID])
GO
ALTER TABLE [Inventario].[TraspasosBodega]  WITH CHECK ADD FOREIGN KEY([UsuarioEnviaID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Inventario].[TraspasosBodega]  WITH CHECK ADD FOREIGN KEY([UsuarioRecibeID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Inventario].[TraspasosDetalle]  WITH CHECK ADD FOREIGN KEY([ArticuloID])
REFERENCES [catalogo].[Articulos] ([ArticuloID])
GO
ALTER TABLE [Inventario].[TraspasosDetalle]  WITH CHECK ADD FOREIGN KEY([LoteID])
REFERENCES [Inventario].[Lotes] ([LoteID])
GO
ALTER TABLE [Inventario].[TraspasosDetalle]  WITH CHECK ADD FOREIGN KEY([TraspasoID])
REFERENCES [Inventario].[TraspasosBodega] ([TraspasoID])
GO
ALTER TABLE [Kardex].[BajasInventarioPerdidas]  WITH CHECK ADD FOREIGN KEY([ArticuloID])
REFERENCES [catalogo].[Articulos] ([ArticuloID])
GO
ALTER TABLE [Kardex].[BajasInventarioPerdidas]  WITH CHECK ADD FOREIGN KEY([BodegaID])
REFERENCES [Inventario].[Bodegas] ([BodegaID])
GO
ALTER TABLE [Kardex].[BajasInventarioPerdidas]  WITH CHECK ADD FOREIGN KEY([LoteID])
REFERENCES [Inventario].[Lotes] ([LoteID])
GO
ALTER TABLE [Kardex].[BajasInventarioPerdidas]  WITH CHECK ADD FOREIGN KEY([MotivoID])
REFERENCES [Kardex].[TiposMotivoLoss] ([MotivoID])
GO
ALTER TABLE [Kardex].[BajasInventarioPerdidas]  WITH CHECK ADD FOREIGN KEY([UsuarioRegistraID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Kardex].[KardexMovimientos]  WITH CHECK ADD FOREIGN KEY([ArticuloID])
REFERENCES [catalogo].[Articulos] ([ArticuloID])
GO
ALTER TABLE [Kardex].[KardexMovimientos]  WITH CHECK ADD FOREIGN KEY([BajaID])
REFERENCES [Kardex].[BajasInventarioPerdidas] ([BajaID])
GO
ALTER TABLE [Kardex].[KardexMovimientos]  WITH CHECK ADD FOREIGN KEY([BodegaID])
REFERENCES [Inventario].[Bodegas] ([BodegaID])
GO
ALTER TABLE [Kardex].[KardexMovimientos]  WITH CHECK ADD FOREIGN KEY([CentroCostoID])
REFERENCES [Organizacion].[CentrosCosto] ([CentroCostoID])
GO
ALTER TABLE [Kardex].[KardexMovimientos]  WITH CHECK ADD FOREIGN KEY([LoteID])
REFERENCES [Inventario].[Lotes] ([LoteID])
GO
ALTER TABLE [Kardex].[KardexMovimientos]  WITH CHECK ADD FOREIGN KEY([OrdenProduccionID])
REFERENCES [Produccion].[OrdenesProduccion] ([OrdenProduccionID])
GO
ALTER TABLE [Kardex].[KardexMovimientos]  WITH CHECK ADD FOREIGN KEY([OrdenCompraID])
REFERENCES [Compras].[OrdenesCompra] ([OrdenCompraID])
GO
ALTER TABLE [Kardex].[KardexMovimientos]  WITH CHECK ADD FOREIGN KEY([TipoMovID])
REFERENCES [Kardex].[TiposMovimientoKardex] ([TipoMovID])
GO
ALTER TABLE [Kardex].[KardexMovimientos]  WITH CHECK ADD FOREIGN KEY([TraspasoID])
REFERENCES [Inventario].[TraspasosBodega] ([TraspasoID])
GO
ALTER TABLE [Kardex].[KardexMovimientos]  WITH CHECK ADD FOREIGN KEY([UsuarioID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Organizacion].[CentrosTrabajo]  WITH CHECK ADD FOREIGN KEY([CentroCostoID])
REFERENCES [Organizacion].[CentrosCosto] ([CentroCostoID])
GO
ALTER TABLE [Produccion].[OrdenesProduccion]  WITH CHECK ADD FOREIGN KEY([BodegaOrigenMPID])
REFERENCES [Inventario].[Bodegas] ([BodegaID])
GO
ALTER TABLE [Produccion].[OrdenesProduccion]  WITH CHECK ADD FOREIGN KEY([BodegaDestinoPTID])
REFERENCES [Inventario].[Bodegas] ([BodegaID])
GO
ALTER TABLE [Produccion].[OrdenesProduccion]  WITH CHECK ADD FOREIGN KEY([CentroCostoDestinoID])
REFERENCES [Organizacion].[CentrosCosto] ([CentroCostoID])
GO
ALTER TABLE [Produccion].[OrdenesProduccion]  WITH CHECK ADD FOREIGN KEY([CentroTrabajoID])
REFERENCES [Organizacion].[CentrosTrabajo] ([CentroTrabajoID])
GO
ALTER TABLE [Produccion].[OrdenesProduccion]  WITH CHECK ADD FOREIGN KEY([ClienteID])
REFERENCES [catalogo].[Clientes] ([ClienteID])
GO
ALTER TABLE [Produccion].[OrdenesProduccion]  WITH CHECK ADD FOREIGN KEY([EstadoOPID])
REFERENCES [Produccion].[EstadosOP] ([EstadoOPID])
GO
ALTER TABLE [Produccion].[OrdenesProduccion]  WITH CHECK ADD FOREIGN KEY([ProductoTerminadoID])
REFERENCES [catalogo].[Articulos] ([ArticuloID])
GO
ALTER TABLE [Produccion].[OrdenesProduccion]  WITH CHECK ADD FOREIGN KEY([RecetaID])
REFERENCES [Produccion].[RecetaBOM] ([RecetaID])
GO
ALTER TABLE [Produccion].[OrdenesProduccion]  WITH CHECK ADD FOREIGN KEY([TipoProduccionID])
REFERENCES [Produccion].[TiposProduccion] ([TipoProduccionID])
GO
ALTER TABLE [Produccion].[OrdenesProduccion]  WITH CHECK ADD FOREIGN KEY([UsuarioCreaID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Produccion].[OrdenesProduccion]  WITH CHECK ADD FOREIGN KEY([UsuarioLiberaID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Produccion].[OrdenesProduccion]  WITH CHECK ADD FOREIGN KEY([UsuarioCierraID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Produccion].[OrdenesProduccionConsumo]  WITH CHECK ADD FOREIGN KEY([ArticuloID])
REFERENCES [catalogo].[Articulos] ([ArticuloID])
GO
ALTER TABLE [Produccion].[OrdenesProduccionConsumo]  WITH CHECK ADD FOREIGN KEY([LoteID])
REFERENCES [Inventario].[Lotes] ([LoteID])
GO
ALTER TABLE [Produccion].[OrdenesProduccionConsumo]  WITH CHECK ADD FOREIGN KEY([MotivoExcesoID])
REFERENCES [Produccion].[MotivosExcesoConsumo] ([MotivoExcesoID])
GO
ALTER TABLE [Produccion].[OrdenesProduccionConsumo]  WITH CHECK ADD FOREIGN KEY([OrdenProduccionID])
REFERENCES [Produccion].[OrdenesProduccion] ([OrdenProduccionID])
GO
ALTER TABLE [Produccion].[RecetaBOM]  WITH CHECK ADD FOREIGN KEY([ProductoTerminadoID])
REFERENCES [catalogo].[Articulos] ([ArticuloID])
GO
ALTER TABLE [Produccion].[RecetaBOM]  WITH CHECK ADD FOREIGN KEY([UnidadRendimientoID])
REFERENCES [catalogo].[UnidadesMedida] ([UnidadID])
GO
ALTER TABLE [Produccion].[RecetaBOM_Detalle]  WITH CHECK ADD FOREIGN KEY([CentroTrabajoID])
REFERENCES [Organizacion].[CentrosTrabajo] ([CentroTrabajoID])
GO
ALTER TABLE [Produccion].[RecetaBOM_Detalle]  WITH CHECK ADD FOREIGN KEY([InsumoID])
REFERENCES [catalogo].[Articulos] ([ArticuloID])
GO
ALTER TABLE [Produccion].[RecetaBOM_Detalle]  WITH CHECK ADD FOREIGN KEY([RecetaID])
REFERENCES [Produccion].[RecetaBOM] ([RecetaID])
GO
ALTER TABLE [Produccion].[RecetaBOM_Detalle]  WITH CHECK ADD FOREIGN KEY([UnidadID])
REFERENCES [catalogo].[UnidadesMedida] ([UnidadID])
GO
ALTER TABLE [Seguridad].[RolPermisos]  WITH CHECK ADD FOREIGN KEY([PermisoID])
REFERENCES [Seguridad].[Permisos] ([PermisoID])
GO
ALTER TABLE [Seguridad].[RolPermisos]  WITH CHECK ADD FOREIGN KEY([RolID])
REFERENCES [Seguridad].[Roles] ([RolID])
GO
ALTER TABLE [Seguridad].[SesionesUsuario]  WITH CHECK ADD FOREIGN KEY([UsuarioID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Seguridad].[Usuarios]  WITH CHECK ADD FOREIGN KEY([CentroCostoID])
REFERENCES [Organizacion].[CentrosCosto] ([CentroCostoID])
GO
ALTER TABLE [Seguridad].[Usuarios]  WITH CHECK ADD FOREIGN KEY([RolID])
REFERENCES [Seguridad].[Roles] ([RolID])
GO
ALTER TABLE [Auditoria].[LogAuditoria]  WITH CHECK ADD CHECK  (([Accion]='DELETE' OR [Accion]='UPDATE' OR [Accion]='INSERT'))
GO
ALTER TABLE [catalogo].[UnidadesMedida]  WITH CHECK ADD CHECK  (([Tipo]='LONGITUD' OR [Tipo]='UNIDAD' OR [Tipo]='VOLUMEN' OR [Tipo]='PESO'))
GO
ALTER TABLE [Compras].[OrdenesCompra]  WITH CHECK ADD CHECK  (([EstadoOC]='CANCELADA' OR [EstadoOC]='RECIBIDA' OR [EstadoOC]='PARCIAL' OR [EstadoOC]='PENDIENTE'))
GO
ALTER TABLE [Compras].[OrdenesCompraDetalle]  WITH CHECK ADD CHECK  (([CantidadSolicitada]>(0)))
GO
ALTER TABLE [Integracion].[EventosEntrantes]  WITH CHECK ADD CHECK  (([TipoEvento]='AJUSTE_INVENTARIO' OR [TipoEvento]='VENTA'))
GO
ALTER TABLE [Integracion].[EventosSalientes]  WITH CHECK ADD CHECK  (([Estado]='ERROR' OR [Estado]='CONFIRMADO' OR [Estado]='ENVIADO' OR [Estado]='PENDIENTE'))
GO
ALTER TABLE [Integracion].[EventosSalientes]  WITH CHECK ADD CHECK  (([TipoEvento]='TRASPASO_RECIBIDO' OR [TipoEvento]='ENTRADA_PRODUCTO_TERMINADO'))
GO
ALTER TABLE [Inventario].[Bodegas]  WITH CHECK ADD CHECK  (([TipoBodega]='TRANSITO' OR [TipoBodega]='WIP' OR [TipoBodega]='PRODUCTO_TERMINADO' OR [TipoBodega]='MATERIA_PRIMA'))
GO
ALTER TABLE [Inventario].[InventarioStock]  WITH CHECK ADD CHECK  (([CantidadActual]>=(0)))
GO
ALTER TABLE [Inventario].[Lotes]  WITH CHECK ADD CHECK  (([Estado]='AGOTADO' OR [Estado]='RECHAZADO' OR [Estado]='CUARENTENA' OR [Estado]='APROBADO'))
GO
ALTER TABLE [Inventario].[TraspasosBodega]  WITH CHECK ADD CHECK  (([EstadoTraspaso]='CANCELADO' OR [EstadoTraspaso]='RECIBIDO' OR [EstadoTraspaso]='EN_TRANSITO' OR [EstadoTraspaso]='PENDIENTE'))
GO
ALTER TABLE [Inventario].[TraspasosDetalle]  WITH CHECK ADD  CONSTRAINT [CK_TraspasosDetalle_CantidadEnviada] CHECK  (([CantidadEnviada]>(0)))
GO
ALTER TABLE [Inventario].[TraspasosDetalle] CHECK CONSTRAINT [CK_TraspasosDetalle_CantidadEnviada]
GO
ALTER TABLE [Kardex].[BajasInventarioPerdidas]  WITH CHECK ADD CHECK  (([CantidadPerdida]>(0)))
GO
ALTER TABLE [Kardex].[TiposMovimientoKardex]  WITH CHECK ADD CHECK  (([Signo]=(-1) OR [Signo]=(1)))
GO
ALTER TABLE [Organizacion].[CentrosCosto]  WITH CHECK ADD CHECK  (([TipoCentro]='FRANQUICIA' OR [TipoCentro]='PUNTO_VENTA' OR [TipoCentro]='SUCURSAL' OR [TipoCentro]='PLANTA_CENTRAL'))
GO
ALTER TABLE [Produccion].[OrdenesProduccion]  WITH CHECK ADD CHECK  (([CantidadProgramada]>(0)))
GO
ALTER TABLE [Produccion].[RecetaBOM]  WITH CHECK ADD CHECK  (([CantidadRendimientoBase]>(0)))
GO
ALTER TABLE [Produccion].[RecetaBOM_Detalle]  WITH CHECK ADD CHECK  (([CantidadRequerida]>(0)))
GO
/****** Object:  StoredProcedure [Compras].[sp_RecibirOrdenCompra]    Script Date: 1/08/2026 11:00:08 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [Compras].[sp_RecibirOrdenCompra]
    @OrdenCompraDetalleID INT,
    @CantidadRecibida DECIMAL(18,4),
    @NumeroLote NVARCHAR(50),
    @FechaVencimiento DATE = NULL,
    @UsuarioID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @OrdenCompraID INT, @ArticuloID INT, @CostoUnitario DECIMAL(18,4), @BodegaDestinoID INT, @CentroCostoID INT, @ProveedorID INT;

    SELECT @OrdenCompraID = ocd.OrdenCompraID, @ArticuloID = ocd.ArticuloID, @CostoUnitario = ocd.CostoUnitario
    FROM Compras.OrdenesCompraDetalle ocd WHERE ocd.OrdenCompraDetalleID = @OrdenCompraDetalleID;

    SELECT @BodegaDestinoID = BodegaDestinoID, @ProveedorID = ProveedorID FROM Compras.OrdenesCompra WHERE OrdenCompraID = @OrdenCompraID;
    SELECT @CentroCostoID = CentroCostoID FROM Inventario.Bodegas WHERE BodegaID = @BodegaDestinoID;

    BEGIN TRANSACTION;

    -- Costo promedio ponderado ANTES de sumar la nueva entrada
    DECLARE @StockPrevio DECIMAL(18,4) = Catalogo.fn_StockTotalArticulo(@ArticuloID);
    DECLARE @CostoPromedioPrevio DECIMAL(18,4) = (SELECT CostoPromedio FROM Catalogo.Articulos WHERE ArticuloID = @ArticuloID);
    DECLARE @NuevoCostoPromedio DECIMAL(18,4) =
        CASE WHEN (@StockPrevio + @CantidadRecibida) = 0 THEN @CostoUnitario
             ELSE ((@StockPrevio * @CostoPromedioPrevio) + (@CantidadRecibida * @CostoUnitario)) / (@StockPrevio + @CantidadRecibida)
        END;

    DECLARE @LoteID INT;
    INSERT INTO Inventario.Lotes (ArticuloID, NumeroLote, FechaFabricacion, FechaVencimiento, ProveedorID, Estado)
    VALUES (@ArticuloID, @NumeroLote, CAST(SYSUTCDATETIME() AS DATE), @FechaVencimiento, @ProveedorID, 'APROBADO');
    SET @LoteID = SCOPE_IDENTITY();

    INSERT INTO Inventario.InventarioStock (ArticuloID, BodegaID, LoteID, CantidadActual, CostoUnitarioLote)
    VALUES (@ArticuloID, @BodegaDestinoID, @LoteID, @CantidadRecibida, @CostoUnitario);

    UPDATE Compras.OrdenesCompraDetalle SET CantidadRecibida = CantidadRecibida + @CantidadRecibida, LoteID = @LoteID
    WHERE OrdenCompraDetalleID = @OrdenCompraDetalleID;

    DECLARE @NuevoSaldo DECIMAL(18,4) = (SELECT SUM(CantidadActual) FROM Inventario.InventarioStock WHERE ArticuloID=@ArticuloID AND BodegaID=@BodegaDestinoID);
    DECLARE @TipoEntradaCompra INT = (SELECT TipoMovID FROM Kardex.TiposMovimientoKardex WHERE Codigo='ENTRADA_COMPRA');

    INSERT INTO Kardex.KardexMovimientos
        (ArticuloID, BodegaID, LoteID, TipoMovID, OrdenCompraID, CentroCostoID, Cantidad, CostoUnitario, CantidadSaldo, CostoPromedioSaldo, ObservacionDetallada, UsuarioID)
    VALUES
        (@ArticuloID, @BodegaDestinoID, @LoteID, @TipoEntradaCompra, @OrdenCompraID, @CentroCostoID, @CantidadRecibida, @CostoUnitario, @NuevoSaldo, @NuevoCostoPromedio,
         CONCAT('Recepcion de compra OC #', @OrdenCompraID), @UsuarioID);

    UPDATE Catalogo.Articulos SET CostoPromedio = @NuevoCostoPromedio WHERE ArticuloID = @ArticuloID;

    -- Actualiza estado de la OC si ya se recibio todo
    IF NOT EXISTS (
        SELECT 1 FROM Compras.OrdenesCompraDetalle
        WHERE OrdenCompraID = @OrdenCompraID AND CantidadRecibida < CantidadSolicitada
    )
        UPDATE Compras.OrdenesCompra SET EstadoOC = 'RECIBIDA', FechaRecepcion = SYSUTCDATETIME() WHERE OrdenCompraID = @OrdenCompraID;
    ELSE
        UPDATE Compras.OrdenesCompra SET EstadoOC = 'PARCIAL' WHERE OrdenCompraID = @OrdenCompraID;

    COMMIT TRANSACTION;
    SELECT 'OK' AS Resultado, @LoteID AS LoteID, @NuevoCostoPromedio AS NuevoCostoPromedio;
END
GO
/****** Object:  StoredProcedure [Integracion].[sp_ProcesarEventoEntrante]    Script Date: 1/08/2026 11:00:08 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [Integracion].[sp_ProcesarEventoEntrante]
    @EventoEntranteID BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ArticuloID INT, @CentroCostoID INT, @Cantidad DECIMAL(18,4), @Procesado BIT;

    SELECT
        @ArticuloID = m.ArticuloID,
        @CentroCostoID = e.CentroCostoID,
        @Cantidad = e.Cantidad,
        @Procesado = e.Procesado
    FROM Integracion.EventosEntrantes e
    JOIN Integracion.MapeoArticulos m
        ON m.CodigoArticuloVisions = e.CodigoArticuloVisions AND m.CentroCostoID = e.CentroCostoID
    WHERE e.EventoEntranteID = @EventoEntranteID;

    IF @ArticuloID IS NULL
        THROW 54000, 'No existe mapeo de articulo para este evento entrante; revisar Integracion.MapeoArticulos.', 1;

    IF @Procesado = 1
        RETURN;

    BEGIN TRANSACTION;

    MERGE Integracion.InventarioReportadoVisions AS destino
    USING (SELECT @ArticuloID AS ArticuloID, @CentroCostoID AS CentroCostoID) AS origen
    ON destino.ArticuloID = origen.ArticuloID AND destino.CentroCostoID = origen.CentroCostoID
    WHEN MATCHED THEN UPDATE SET
        CantidadVendidaAcumulada = destino.CantidadVendidaAcumulada + @Cantidad,
        UltimaActualizacion = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN INSERT (ArticuloID, CentroCostoID, CantidadVendidaAcumulada)
        VALUES (@ArticuloID, @CentroCostoID, @Cantidad);

    UPDATE Integracion.EventosEntrantes
    SET Procesado = 1, FechaProcesado = SYSUTCDATETIME()
    WHERE EventoEntranteID = @EventoEntranteID;

    COMMIT TRANSACTION;
END
GO
/****** Object:  StoredProcedure [Inventario].[sp_CrearYEnviarTraspaso]    Script Date: 1/08/2026 11:00:08 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [Inventario].[sp_CrearYEnviarTraspaso]
    @BodegaOrigenID INT,
    @BodegaDestinoID INT,
    @UsuarioEnviaID INT,
    @DetalleJSON NVARCHAR(MAX) -- [{"ArticuloID":1,"LoteID":null,"Cantidad":10}]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRANSACTION;

    DECLARE @TraspasoID INT, @Codigo NVARCHAR(30) = CONCAT('TRSP-', FORMAT(SYSUTCDATETIME(),'yyyyMMddHHmmss'));

    INSERT INTO Inventario.TraspasosBodega (Codigo, BodegaOrigenID, BodegaDestinoID, EstadoTraspaso, FechaEnvio, UsuarioEnviaID)
    VALUES (@Codigo, @BodegaOrigenID, @BodegaDestinoID, 'EN_TRANSITO', SYSUTCDATETIME(), @UsuarioEnviaID);
    SET @TraspasoID = SCOPE_IDENTITY();

    DECLARE @ArticuloID INT, @LoteID INT, @Cantidad DECIMAL(18,4);
    DECLARE @TipoSalida INT = (SELECT TipoMovID FROM Kardex.TiposMovimientoKardex WHERE Codigo='TRASPASO_SALIDA');
    DECLARE @CentroCostoOrigen INT = (SELECT CentroCostoID FROM Inventario.Bodegas WHERE BodegaID = @BodegaOrigenID);

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT ArticuloID, LoteID, Cantidad FROM OPENJSON(@DetalleJSON)
        WITH (ArticuloID INT, LoteID INT, Cantidad DECIMAL(18,4));
    OPEN cur; FETCH NEXT FROM cur INTO @ArticuloID, @LoteID, @Cantidad;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @Disponible DECIMAL(18,4), @CostoUnitario DECIMAL(18,4), @InventarioID BIGINT;
        SELECT @Disponible = CantidadActual, @CostoUnitario = CostoUnitarioLote, @InventarioID = InventarioID
        FROM Inventario.InventarioStock
        WHERE ArticuloID = @ArticuloID AND BodegaID = @BodegaOrigenID
              AND ((@LoteID IS NULL AND LoteID IS NULL) OR LoteID = @LoteID);

        IF @Disponible IS NULL OR @Disponible < @Cantidad
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 53000, 'Stock insuficiente para el traspaso de al menos un articulo.', 1;
        END

        UPDATE Inventario.InventarioStock SET CantidadActual = CantidadActual - @Cantidad, FechaUltimaActualizacion = SYSUTCDATETIME()
        WHERE InventarioID = @InventarioID;

        INSERT INTO Inventario.TraspasosDetalle (TraspasoID, ArticuloID, LoteID, CantidadEnviada, CostoUnitario)
        VALUES (@TraspasoID, @ArticuloID, @LoteID, @Cantidad, @CostoUnitario);

        DECLARE @NuevoSaldo DECIMAL(18,4) = (SELECT SUM(CantidadActual) FROM Inventario.InventarioStock WHERE ArticuloID=@ArticuloID AND BodegaID=@BodegaOrigenID);

        INSERT INTO Kardex.KardexMovimientos
            (ArticuloID, BodegaID, LoteID, TipoMovID, TraspasoID, CentroCostoID, Cantidad, CostoUnitario, CantidadSaldo, CostoPromedioSaldo, ObservacionDetallada, UsuarioID)
        VALUES
            (@ArticuloID, @BodegaOrigenID, @LoteID, @TipoSalida, @TraspasoID, @CentroCostoOrigen, @Cantidad, @CostoUnitario, @NuevoSaldo, @CostoUnitario,
             CONCAT('Envio por traspaso ', @Codigo), @UsuarioEnviaID);

        FETCH NEXT FROM cur INTO @ArticuloID, @LoteID, @Cantidad;
    END
    CLOSE cur; DEALLOCATE cur;

    COMMIT TRANSACTION;
    SELECT 'OK' AS Resultado, @TraspasoID AS TraspasoID, @Codigo AS Codigo;
END
GO
/****** Object:  StoredProcedure [Inventario].[sp_RecibirTraspaso]    Script Date: 1/08/2026 11:00:08 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [Inventario].[sp_RecibirTraspaso]
    @TraspasoID INT,
    @UsuarioRecibeID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM Inventario.TraspasosBodega WHERE TraspasoID = @TraspasoID AND EstadoTraspaso = 'EN_TRANSITO')
        THROW 53010, 'El traspaso no existe o no esta en transito.', 1;

    BEGIN TRANSACTION;

    DECLARE @BodegaDestinoID INT, @CentroCostoDestino INT;
    SELECT @BodegaDestinoID = BodegaDestinoID FROM Inventario.TraspasosBodega WHERE TraspasoID = @TraspasoID;
    SELECT @CentroCostoDestino = CentroCostoID FROM Inventario.Bodegas WHERE BodegaID = @BodegaDestinoID;
    DECLARE @TipoEntrada INT = (SELECT TipoMovID FROM Kardex.TiposMovimientoKardex WHERE Codigo='TRASPASO_ENTRADA');
    DECLARE @DestinoTieneVisions BIT = ISNULL((SELECT TieneVisions FROM Organizacion.CentrosCosto WHERE CentroCostoID = @CentroCostoDestino), 0);

    DECLARE @ArticuloID INT, @LoteID INT, @Cantidad DECIMAL(18,4), @CostoUnitario DECIMAL(18,4), @DetalleID INT;
    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT TraspasoDetalleID, ArticuloID, LoteID, CantidadEnviada, CostoUnitario
        FROM Inventario.TraspasosDetalle WHERE TraspasoID = @TraspasoID;
    OPEN cur; FETCH NEXT FROM cur INTO @DetalleID, @ArticuloID, @LoteID, @Cantidad, @CostoUnitario;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        MERGE Inventario.InventarioStock AS destino
        USING (SELECT @ArticuloID AS ArticuloID, @BodegaDestinoID AS BodegaID, @LoteID AS LoteID) AS origen
        ON destino.ArticuloID = origen.ArticuloID AND destino.BodegaID = origen.BodegaID
           AND ((destino.LoteID IS NULL AND origen.LoteID IS NULL) OR destino.LoteID = origen.LoteID)
        WHEN MATCHED THEN UPDATE SET CantidadActual = destino.CantidadActual + @Cantidad, FechaUltimaActualizacion = SYSUTCDATETIME()
        WHEN NOT MATCHED THEN INSERT (ArticuloID, BodegaID, LoteID, CantidadActual, CostoUnitarioLote)
                              VALUES (@ArticuloID, @BodegaDestinoID, @LoteID, @Cantidad, @CostoUnitario);

        UPDATE Inventario.TraspasosDetalle SET CantidadRecibida = @Cantidad WHERE TraspasoDetalleID = @DetalleID;

        DECLARE @NuevoSaldo DECIMAL(18,4) = (SELECT SUM(CantidadActual) FROM Inventario.InventarioStock WHERE ArticuloID=@ArticuloID AND BodegaID=@BodegaDestinoID);

        INSERT INTO Kardex.KardexMovimientos
            (ArticuloID, BodegaID, LoteID, TipoMovID, TraspasoID, CentroCostoID, Cantidad, CostoUnitario, CantidadSaldo, CostoPromedioSaldo, ObservacionDetallada, UsuarioID)
        VALUES
            (@ArticuloID, @BodegaDestinoID, @LoteID, @TipoEntrada, @TraspasoID, @CentroCostoDestino, @Cantidad, @CostoUnitario, @NuevoSaldo, @CostoUnitario,
             CONCAT('Recepcion de traspaso #', @TraspasoID), @UsuarioRecibeID);

        DECLARE @KardexIDGenerado BIGINT = SCOPE_IDENTITY();

        -- ====== UNICO AGREGADO: emitir evento de integracion si aplica ======
        IF @DestinoTieneVisions = 1
        BEGIN
            INSERT INTO Integracion.EventosSalientes
                (TipoEvento, CentroCostoID, ArticuloID, Cantidad, CostoUnitario, KardexID)
            VALUES
                ('TRASPASO_RECIBIDO', @CentroCostoDestino, @ArticuloID, @Cantidad, @CostoUnitario, @KardexIDGenerado);
        END
        -- ====================================================================

        FETCH NEXT FROM cur INTO @DetalleID, @ArticuloID, @LoteID, @Cantidad, @CostoUnitario;
    END
    CLOSE cur; DEALLOCATE cur;

    UPDATE Inventario.TraspasosBodega
    SET EstadoTraspaso = 'RECIBIDO', FechaRecepcion = SYSUTCDATETIME(), UsuarioRecibeID = @UsuarioRecibeID
    WHERE TraspasoID = @TraspasoID;

    COMMIT TRANSACTION;
    SELECT 'OK' AS Resultado;
END
GO
/****** Object:  StoredProcedure [Kardex].[sp_RegistrarBajaInventario]    Script Date: 1/08/2026 11:00:08 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [Kardex].[sp_RegistrarBajaInventario]
    @ArticuloID INT,
    @BodegaID INT,
    @LoteID INT = NULL,
    @CantidadPerdida DECIMAL(18,4),
    @MotivoID INT,
    @ObservacionDetallada NVARCHAR(500),
    @UsuarioRegistraID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @ObservacionDetallada IS NULL OR LEN(TRIM(@ObservacionDetallada)) < 5
        THROW 52000, 'Debe indicar una observacion detallada de al menos 5 caracteres.', 1;

    DECLARE @Disponible DECIMAL(18,4), @CostoUnitario DECIMAL(18,4), @CentroCostoID INT, @InventarioID BIGINT;

    SELECT TOP 1 @Disponible = s.CantidadActual, @CostoUnitario = s.CostoUnitarioLote,
                 @InventarioID = s.InventarioID, @CentroCostoID = b.CentroCostoID
    FROM Inventario.InventarioStock s
    JOIN Inventario.Bodegas b ON b.BodegaID = s.BodegaID
    WHERE s.ArticuloID = @ArticuloID AND s.BodegaID = @BodegaID
          AND ((@LoteID IS NULL AND s.LoteID IS NULL) OR s.LoteID = @LoteID);

    IF @Disponible IS NULL OR @Disponible < @CantidadPerdida
        THROW 52001, 'No hay stock suficiente en esa bodega/lote para registrar la baja.', 1;

    BEGIN TRANSACTION;

    DECLARE @CodigoBaja NVARCHAR(30) = CONCAT('BAJA-', FORMAT(SYSUTCDATETIME(),'yyyyMMddHHmmss'));
    DECLARE @BajaID INT;

    INSERT INTO Kardex.BajasInventarioPerdidas
        (CodigoBaja, ArticuloID, BodegaID, LoteID, CantidadPerdida, CostoUnitario, MotivoID, ObservacionDetallada, UsuarioRegistraID)
    VALUES
        (@CodigoBaja, @ArticuloID, @BodegaID, @LoteID, @CantidadPerdida, @CostoUnitario, @MotivoID, @ObservacionDetallada, @UsuarioRegistraID);
    SET @BajaID = SCOPE_IDENTITY();

    UPDATE Inventario.InventarioStock
    SET CantidadActual = CantidadActual - @CantidadPerdida, FechaUltimaActualizacion = SYSUTCDATETIME()
    WHERE InventarioID = @InventarioID;

    DECLARE @NuevoSaldo DECIMAL(18,4) = (SELECT SUM(CantidadActual) FROM Inventario.InventarioStock WHERE ArticuloID=@ArticuloID AND BodegaID=@BodegaID);
    DECLARE @TipoBaja INT = (SELECT TipoMovID FROM Kardex.TiposMovimientoKardex WHERE Codigo='BAJA_MERMA');

    INSERT INTO Kardex.KardexMovimientos
        (ArticuloID, BodegaID, LoteID, TipoMovID, BajaID, CentroCostoID,
         Cantidad, CostoUnitario, CantidadSaldo, CostoPromedioSaldo, ObservacionDetallada, UsuarioID)
    VALUES
        (@ArticuloID, @BodegaID, @LoteID, @TipoBaja, @BajaID, @CentroCostoID,
         @CantidadPerdida, @CostoUnitario, @NuevoSaldo, @CostoUnitario, @ObservacionDetallada, @UsuarioRegistraID);

    COMMIT TRANSACTION;
    SELECT 'OK' AS Resultado, @CodigoBaja AS CodigoBaja, @BajaID AS BajaID;
END
GO
/****** Object:  StoredProcedure [Produccion].[sp_AjustarConsumoReal]    Script Date: 1/08/2026 11:00:08 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [Produccion].[sp_AjustarConsumoReal]
    @ConsumoID BIGINT,
    @CantidadReal DECIMAL(18,4),
    @MotivoExcesoID INT = NULL,
    @Observacion NVARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Teorica DECIMAL(18,4);
    SELECT @Teorica = CantidadTeorica FROM Produccion.OrdenesProduccionConsumo WHERE ConsumoID = @ConsumoID;

    IF @Teorica IS NULL
        THROW 51020, 'Registro de consumo no encontrado.', 1;

    IF @CantidadReal > @Teorica AND @MotivoExcesoID IS NULL
        THROW 51021, 'Debe indicar un motivo de exceso de consumo cuando la cantidad real supera la teorica.', 1;

    UPDATE Produccion.OrdenesProduccionConsumo
    SET CantidadReal = @CantidadReal, MotivoExcesoID = @MotivoExcesoID, Observacion = @Observacion
    WHERE ConsumoID = @ConsumoID;

    SELECT 'OK' AS Resultado;
END
GO
/****** Object:  StoredProcedure [Produccion].[sp_CerrarOrdenProduccion]    Script Date: 1/08/2026 11:00:08 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [Produccion].[sp_CerrarOrdenProduccion]
    @OrdenProduccionID INT,
    @CantidadProducidaReal DECIMAL(18,4),
    @HorasManoObra DECIMAL(18,4) = 0,
    @HorasCIF DECIMAL(18,4) = 0,
    @NumeroLotePT NVARCHAR(50),
    @FechaVencimientoPT DATE = NULL,
    @UsuarioID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EstadoActual NVARCHAR(30), @ProductoTerminadoID INT, @BodegaDestinoPTID INT,
            @CentroCostoID INT, @CentroTrabajoID INT,
            @TipoEntradaPT INT = (SELECT TipoMovID FROM Kardex.TiposMovimientoKardex WHERE Codigo='ENTRADA_PT');

    SELECT
        @EstadoActual = e.Nombre, @ProductoTerminadoID = op.ProductoTerminadoID,
        @BodegaDestinoPTID = op.BodegaDestinoPTID, @CentroCostoID = op.CentroCostoDestinoID,
        @CentroTrabajoID = op.CentroTrabajoID
    FROM Produccion.OrdenesProduccion op
    JOIN Produccion.EstadosOP e ON e.EstadoOPID = op.EstadoOPID
    WHERE op.OrdenProduccionID = @OrdenProduccionID;

    IF @EstadoActual <> 'En Proceso'
        THROW 51030, 'Solo se pueden cerrar ordenes en estado En Proceso.', 1;

    DECLARE @CostoMateriales DECIMAL(18,4);
    SELECT @CostoMateriales = SUM(CantidadReal * ISNULL(k.CostoUnitario, a.CostoPromedio))
    FROM Produccion.OrdenesProduccionConsumo c
    JOIN Catalogo.Articulos a ON a.ArticuloID = c.ArticuloID
    OUTER APPLY (
        SELECT TOP 1 CostoUnitario FROM Kardex.KardexMovimientos
        WHERE OrdenProduccionID = @OrdenProduccionID AND ArticuloID = c.ArticuloID
        ORDER BY KardexID DESC
    ) k
    WHERE c.OrdenProduccionID = @OrdenProduccionID;

    DECLARE @CostoHoraMOD DECIMAL(18,4) = 0, @CostoHoraCIF DECIMAL(18,4) = 0;
    IF @CentroTrabajoID IS NOT NULL
        SELECT @CostoHoraMOD = CostoHoraManoObra, @CostoHoraCIF = CostoHoraCIF
        FROM Organizacion.CentrosTrabajo WHERE CentroTrabajoID = @CentroTrabajoID;

    DECLARE @CostoMOD DECIMAL(18,4) = @HorasManoObra * @CostoHoraMOD;
    DECLARE @CostoCIF DECIMAL(18,4) = @HorasCIF * @CostoHoraCIF;
    DECLARE @CostoTotal DECIMAL(18,4) = ISNULL(@CostoMateriales,0) + @CostoMOD + @CostoCIF;
    DECLARE @CostoUnitarioReal DECIMAL(18,4) = @CostoTotal / NULLIF(@CantidadProducidaReal,0);

    BEGIN TRANSACTION;

    DECLARE @LoteID INT;
    INSERT INTO Inventario.Lotes (ArticuloID, NumeroLote, FechaFabricacion, FechaVencimiento, Estado)
    VALUES (@ProductoTerminadoID, @NumeroLotePT, CAST(SYSUTCDATETIME() AS DATE), @FechaVencimientoPT, 'APROBADO');
    SET @LoteID = SCOPE_IDENTITY();

    MERGE Inventario.InventarioStock AS destino
    USING (SELECT @ProductoTerminadoID AS ArticuloID, @BodegaDestinoPTID AS BodegaID, @LoteID AS LoteID) AS origen
    ON destino.ArticuloID = origen.ArticuloID AND destino.BodegaID = origen.BodegaID AND destino.LoteID = origen.LoteID
    WHEN MATCHED THEN UPDATE SET CantidadActual = destino.CantidadActual + @CantidadProducidaReal,
                                  CostoUnitarioLote = @CostoUnitarioReal,
                                  FechaUltimaActualizacion = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN INSERT (ArticuloID, BodegaID, LoteID, CantidadActual, CostoUnitarioLote)
                          VALUES (@ProductoTerminadoID, @BodegaDestinoPTID, @LoteID, @CantidadProducidaReal, @CostoUnitarioReal);

    DECLARE @NuevoSaldo DECIMAL(18,4) = (SELECT SUM(CantidadActual) FROM Inventario.InventarioStock WHERE ArticuloID=@ProductoTerminadoID AND BodegaID=@BodegaDestinoPTID);

    INSERT INTO Kardex.KardexMovimientos
        (ArticuloID, BodegaID, LoteID, TipoMovID, OrdenProduccionID, CentroCostoID,
         Cantidad, CostoUnitario, CantidadSaldo, CostoPromedioSaldo, ObservacionDetallada, UsuarioID)
    VALUES
        (@ProductoTerminadoID, @BodegaDestinoPTID, @LoteID, @TipoEntradaPT, @OrdenProduccionID, @CentroCostoID,
         @CantidadProducidaReal, @CostoUnitarioReal, @NuevoSaldo, @CostoUnitarioReal,
         CONCAT('Ingreso de producto terminado OP #', @OrdenProduccionID), @UsuarioID);

    DECLARE @KardexIDGenerado BIGINT = SCOPE_IDENTITY();

    UPDATE Catalogo.Articulos SET CostoPromedio = @CostoUnitarioReal WHERE ArticuloID = @ProductoTerminadoID;

    UPDATE Produccion.OrdenesProduccion
    SET EstadoOPID = (SELECT EstadoOPID FROM Produccion.EstadosOP WHERE Nombre = 'Finalizada'),
        CantidadProducidaReal = @CantidadProducidaReal,
        CostoMateriales = ISNULL(@CostoMateriales,0),
        CostoMOD = @CostoMOD,
        CostoCIF = @CostoCIF,
        CostoUnitarioReal = @CostoUnitarioReal,
        FechaFin = SYSUTCDATETIME(),
        UsuarioCierraID = @UsuarioID
    WHERE OrdenProduccionID = @OrdenProduccionID;

    -- ====== UNICO AGREGADO: emitir evento de integracion si aplica ======
    IF EXISTS (SELECT 1 FROM Organizacion.CentrosCosto WHERE CentroCostoID = @CentroCostoID AND TieneVisions = 1)
    BEGIN
        INSERT INTO Integracion.EventosSalientes
            (TipoEvento, CentroCostoID, ArticuloID, Cantidad, CostoUnitario, KardexID)
        VALUES
            ('ENTRADA_PRODUCTO_TERMINADO', @CentroCostoID, @ProductoTerminadoID, @CantidadProducidaReal, @CostoUnitarioReal, @KardexIDGenerado);
    END
    -- ====================================================================

    COMMIT TRANSACTION;

    SELECT 'OK' AS Resultado, @CostoUnitarioReal AS CostoUnitarioReal, @LoteID AS LoteProductoTerminadoID;
END
GO
/****** Object:  StoredProcedure [Produccion].[sp_IniciarOrdenProduccion]    Script Date: 1/08/2026 11:00:08 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [Produccion].[sp_IniciarOrdenProduccion]
    @OrdenProduccionID INT,
    @UsuarioID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EstadoActual NVARCHAR(30), @RecetaID INT, @CantidadProgramada DECIMAL(18,4),
            @RendimientoBase DECIMAL(18,4), @BodegaOrigenMPID INT, @CentroCostoID INT,
            @TipoSalidaWIP INT = (SELECT TipoMovID FROM Kardex.TiposMovimientoKardex WHERE Codigo='SALIDA_WIP');

    SELECT
        @EstadoActual = e.Nombre, @RecetaID = op.RecetaID, @CantidadProgramada = op.CantidadProgramada,
        @BodegaOrigenMPID = op.BodegaOrigenMPID, @CentroCostoID = op.CentroCostoDestinoID
    FROM Produccion.OrdenesProduccion op
    JOIN Produccion.EstadosOP e ON e.EstadoOPID = op.EstadoOPID
    WHERE op.OrdenProduccionID = @OrdenProduccionID;

    IF @EstadoActual <> 'Liberada'
        THROW 51010, 'Solo se pueden iniciar ordenes en estado Liberada.', 1;

    SELECT @RendimientoBase = CantidadRendimientoBase FROM Produccion.RecetaBOM WHERE RecetaID = @RecetaID;
    DECLARE @FactorEscala DECIMAL(18,8) = @CantidadProgramada / @RendimientoBase;

    BEGIN TRANSACTION;

    DECLARE @InsumoID INT, @CantidadNecesaria DECIMAL(18,4);
    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT rd.InsumoID, (rd.CantidadRequerida * @FactorEscala) * (1 + rd.PorcentajeMermaEstandar/100.0)
        FROM Produccion.RecetaBOM_Detalle rd WHERE rd.RecetaID = @RecetaID;

    OPEN cur;
    FETCH NEXT FROM cur INTO @InsumoID, @CantidadNecesaria;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @Pendiente DECIMAL(18,4) = @CantidadNecesaria;

        DECLARE @LoteID INT, @CantidadLote DECIMAL(18,4), @CostoLote DECIMAL(18,4), @InventarioID BIGINT;

        DECLARE curLotes CURSOR LOCAL FAST_FORWARD FOR
            SELECT s.InventarioID, s.LoteID, s.CantidadActual, s.CostoUnitarioLote
            FROM Inventario.InventarioStock s
            LEFT JOIN Inventario.Lotes l ON l.LoteID = s.LoteID
            WHERE s.ArticuloID = @InsumoID AND s.BodegaID = @BodegaOrigenMPID AND s.CantidadActual > 0
                  AND (l.Estado IS NULL OR l.Estado = 'APROBADO')
            ORDER BY ISNULL(l.FechaVencimiento,'9999-12-31') ASC; -- FEFO

        OPEN curLotes;
        FETCH NEXT FROM curLotes INTO @InventarioID, @LoteID, @CantidadLote, @CostoLote;

        WHILE @@FETCH_STATUS = 0 AND @Pendiente > 0
        BEGIN
            DECLARE @Tomar DECIMAL(18,4) = CASE WHEN @CantidadLote >= @Pendiente THEN @Pendiente ELSE @CantidadLote END;

            UPDATE Inventario.InventarioStock
            SET CantidadActual = CantidadActual - @Tomar, FechaUltimaActualizacion = SYSUTCDATETIME()
            WHERE InventarioID = @InventarioID;

            DECLARE @NuevoSaldo DECIMAL(18,4) = (SELECT SUM(CantidadActual) FROM Inventario.InventarioStock WHERE ArticuloID=@InsumoID AND BodegaID=@BodegaOrigenMPID);

            INSERT INTO Kardex.KardexMovimientos
                (ArticuloID, BodegaID, LoteID, TipoMovID, OrdenProduccionID, CentroCostoID,
                 Cantidad, CostoUnitario, CantidadSaldo, CostoPromedioSaldo, ObservacionDetallada, UsuarioID)
            VALUES
                (@InsumoID, @BodegaOrigenMPID, @LoteID, @TipoSalidaWIP, @OrdenProduccionID, @CentroCostoID,
                 @Tomar, @CostoLote, @NuevoSaldo, @CostoLote, 'Consumo teorico a produccion (FEFO)', @UsuarioID);

            INSERT INTO Produccion.OrdenesProduccionConsumo (OrdenProduccionID, ArticuloID, LoteID, CantidadTeorica, CantidadReal)
            VALUES (@OrdenProduccionID, @InsumoID, @LoteID, @Tomar, @Tomar);

            SET @Pendiente -= @Tomar;
            FETCH NEXT FROM curLotes INTO @InventarioID, @LoteID, @CantidadLote, @CostoLote;
        END
        CLOSE curLotes; DEALLOCATE curLotes;

        IF @Pendiente > 0
        BEGIN
            ROLLBACK TRANSACTION;
            CLOSE cur; DEALLOCATE cur;
            THROW 51011, 'Stock insuficiente detectado al iniciar la OP (condicion de carrera). Reintente.', 1;
        END

        FETCH NEXT FROM cur INTO @InsumoID, @CantidadNecesaria;
    END
    CLOSE cur; DEALLOCATE cur;

    UPDATE Produccion.OrdenesProduccion
    SET EstadoOPID = (SELECT EstadoOPID FROM Produccion.EstadosOP WHERE Nombre = 'En Proceso'),
        FechaInicio = SYSUTCDATETIME()
    WHERE OrdenProduccionID = @OrdenProduccionID;

    COMMIT TRANSACTION;
    SELECT 'OK' AS Resultado, 'Orden iniciada, materia prima descontada.' AS Mensaje;
END
GO
/****** Object:  StoredProcedure [Produccion].[sp_LiberarOrdenProduccion]    Script Date: 1/08/2026 11:00:08 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [Produccion].[sp_LiberarOrdenProduccion]
    @OrdenProduccionID INT,
    @UsuarioID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EstadoActual NVARCHAR(30), @RecetaID INT, @CantidadProgramada DECIMAL(18,4),
            @RendimientoBase DECIMAL(18,4), @BodegaOrigenMPID INT;

    SELECT
        @EstadoActual = e.Nombre,
        @RecetaID = op.RecetaID,
        @CantidadProgramada = op.CantidadProgramada,
        @BodegaOrigenMPID = op.BodegaOrigenMPID
    FROM Produccion.OrdenesProduccion op
    JOIN Produccion.EstadosOP e ON e.EstadoOPID = op.EstadoOPID
    WHERE op.OrdenProduccionID = @OrdenProduccionID;

    IF @EstadoActual IS NULL
        THROW 51000, 'La orden de produccion no existe.', 1;
    IF @EstadoActual <> 'Planificada'
        THROW 51001, 'Solo se pueden liberar ordenes en estado Planificada.', 1;

    SELECT @RendimientoBase = CantidadRendimientoBase FROM Produccion.RecetaBOM WHERE RecetaID = @RecetaID;

    DECLARE @FactorEscala DECIMAL(18,8) = @CantidadProgramada / @RendimientoBase;

    -- Requerimiento total por insumo (incluyendo merma estandar)
    IF OBJECT_ID('tempdb..#Requerido') IS NOT NULL DROP TABLE #Requerido;
    SELECT
        rd.InsumoID,
        a.Nombre AS NombreInsumo,
        (rd.CantidadRequerida * @FactorEscala) * (1 + rd.PorcentajeMermaEstandar/100.0) AS CantidadNecesaria
    INTO #Requerido
    FROM Produccion.RecetaBOM_Detalle rd
    JOIN Catalogo.Articulos a ON a.ArticuloID = rd.InsumoID
    WHERE rd.RecetaID = @RecetaID;

    -- Disponible en la bodega de origen de materia prima
    IF OBJECT_ID('tempdb..#Faltantes') IS NOT NULL DROP TABLE #Faltantes;
    SELECT
        r.InsumoID,
        r.NombreInsumo,
        r.CantidadNecesaria,
        ISNULL(s.Disponible,0) AS Disponible,
        (r.CantidadNecesaria - ISNULL(s.Disponible,0)) AS Faltante
    INTO #Faltantes
    FROM #Requerido r
    OUTER APPLY (
        SELECT SUM(CantidadActual) AS Disponible
        FROM Inventario.InventarioStock
        WHERE ArticuloID = r.InsumoID AND BodegaID = @BodegaOrigenMPID
    ) s
    WHERE r.CantidadNecesaria > ISNULL(s.Disponible,0);

    IF EXISTS (SELECT 1 FROM #Faltantes)
    BEGIN
        DECLARE @Detalle NVARCHAR(MAX) = (
            SELECT STRING_AGG(CONCAT(NombreInsumo, ': faltan ', CAST(ROUND(Faltante,4) AS NVARCHAR(30))), ' | ')
            FROM #Faltantes
        );
        DECLARE @Msg NVARCHAR(MAX) = CONCAT('Stock insuficiente para liberar la OP. Detalle: ', @Detalle);
        THROW 51002, @Msg, 1;
    END

    UPDATE Produccion.OrdenesProduccion
    SET EstadoOPID = (SELECT EstadoOPID FROM Produccion.EstadosOP WHERE Nombre = 'Liberada'),
        UsuarioLiberaID = @UsuarioID
    WHERE OrdenProduccionID = @OrdenProduccionID;

    SELECT 'OK' AS Resultado, 'Orden liberada correctamente.' AS Mensaje;
END
GO
USE [master]
GO
ALTER DATABASE [NEXO_ERP] SET  READ_WRITE 
GO