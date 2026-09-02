USE [master]
GO
/****** Object:  Database [NEXO_ERP]    Script Date: 1/09/2026 5:35:41 p. m. ******/
CREATE DATABASE [NEXO_ERP]
 WITH CATALOG_COLLATION = DATABASE_DEFAULT
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
ALTER DATABASE [NEXO_ERP] SET AUTO_CLOSE OFF
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
/****** Object:  Schema [Auditoria]    Script Date: 1/09/2026 5:35:41 p. m. ******/
CREATE SCHEMA [Auditoria]
GO
/****** Object:  Schema [Calendario]    Script Date: 1/09/2026 5:35:41 p. m. ******/
CREATE SCHEMA [Calendario]
GO
/****** Object:  Schema [catalogo]    Script Date: 1/09/2026 5:35:41 p. m. ******/
CREATE SCHEMA [catalogo]
GO
/****** Object:  Schema [Compras]    Script Date: 1/09/2026 5:35:41 p. m. ******/
CREATE SCHEMA [Compras]
GO
/****** Object:  Schema [Conocimiento]    Script Date: 1/09/2026 5:35:41 p. m. ******/
CREATE SCHEMA [Conocimiento]
GO
/****** Object:  Schema [Crm]    Script Date: 1/09/2026 5:35:41 p. m. ******/
CREATE SCHEMA [Crm]
GO
/****** Object:  Schema [Facturacion]    Script Date: 1/09/2026 5:35:41 p. m. ******/
CREATE SCHEMA [Facturacion]
GO
/****** Object:  Schema [Finanzas]    Script Date: 1/09/2026 5:35:41 p. m. ******/
CREATE SCHEMA [Finanzas]
GO
/****** Object:  Schema [Formularios]    Script Date: 1/09/2026 5:35:41 p. m. ******/
CREATE SCHEMA [Formularios]
GO
/****** Object:  Schema [Integracion]    Script Date: 1/09/2026 5:35:41 p. m. ******/
CREATE SCHEMA [Integracion]
GO
/****** Object:  Schema [Inventario]    Script Date: 1/09/2026 5:35:41 p. m. ******/
CREATE SCHEMA [Inventario]
GO
/****** Object:  Schema [Kardex]    Script Date: 1/09/2026 5:35:41 p. m. ******/
CREATE SCHEMA [Kardex]
GO
/****** Object:  Schema [Logistica]    Script Date: 1/09/2026 5:35:41 p. m. ******/
CREATE SCHEMA [Logistica]
GO
/****** Object:  Schema [Marketing]    Script Date: 1/09/2026 5:35:41 p. m. ******/
CREATE SCHEMA [Marketing]
GO
/****** Object:  Schema [Organizacion]    Script Date: 1/09/2026 5:35:41 p. m. ******/
CREATE SCHEMA [Organizacion]
GO
/****** Object:  Schema [Planificacion]    Script Date: 1/09/2026 5:35:41 p. m. ******/
CREATE SCHEMA [Planificacion]
GO
/****** Object:  Schema [Produccion]    Script Date: 1/09/2026 5:35:41 p. m. ******/
CREATE SCHEMA [Produccion]
GO
/****** Object:  Schema [Proyectos]    Script Date: 1/09/2026 5:35:41 p. m. ******/
CREATE SCHEMA [Proyectos]
GO
/****** Object:  Schema [Rrhh]    Script Date: 1/09/2026 5:35:41 p. m. ******/
CREATE SCHEMA [Rrhh]
GO
/****** Object:  Schema [Seguridad]    Script Date: 1/09/2026 5:35:41 p. m. ******/
CREATE SCHEMA [Seguridad]
GO
/****** Object:  Schema [Soporte]    Script Date: 1/09/2026 5:35:41 p. m. ******/
CREATE SCHEMA [Soporte]
GO
/****** Object:  UserDefinedFunction [catalogo].[fn_StockTotalArticulo]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================================================
-- FUNCION AUXILIAR: costo promedio ponderado total del articulo
-- ============================================================================
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
/****** Object:  UserDefinedFunction [Crm].[CalcularDV]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [Crm].[CalcularDV](@nit NVARCHAR(20))
RETURNS INT
AS
BEGIN
    IF @nit IS NULL OR LEN(@nit)=0 OR @nit LIKE '%[^0-9]%' RETURN NULL;
    DECLARE @primos TABLE (idx INT PRIMARY KEY, val INT);
    INSERT INTO @primos VALUES (0,0),(1,3),(2,7),(3,13),(4,17),(5,19),(6,23),(7,29),(8,37),(9,41),(10,43),(11,47),(12,53),(13,59),(14,67),(15,71);
    DECLARE @n INT = LEN(@nit), @total INT = 0, @i INT = 0;
    WHILE @i < @n
    BEGIN
        SET @total = @total + CAST(SUBSTRING(@nit,@i+1,1) AS INT) * (SELECT val FROM @primos WHERE idx = @n-@i);
        SET @i = @i + 1;
    END;
    DECLARE @r INT = @total % 11;
    RETURN CASE WHEN @r > 1 THEN 11-@r ELSE @r END;
END;

GO
/****** Object:  Table [Organizacion].[CentrosCosto]    Script Date: 1/09/2026 5:35:41 p. m. ******/
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
	[BodegaVentaVisionsID] [int] NULL,
	[PrefijosDocumentoVentaVisions] [nvarchar](200) NULL,
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
/****** Object:  Table [catalogo].[Tarjetas]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [catalogo].[Tarjetas](
	[ArticuloID] [int] IDENTITY(1,1) NOT NULL,
	[Referencia] [nvarchar](30) NOT NULL,
	[Nombre] [nvarchar](150) NOT NULL,
	[Descripcion] [nvarchar](300) NULL,
	[TipoArticuloID] [int] NOT NULL,
	[UnidadID] [int] NULL,
	[CostoPromedio] [decimal](18, 4) NOT NULL,
	[StockMinimo] [decimal](18, 4) NOT NULL,
	[StockMaximo] [decimal](18, 4) NULL,
	[PuntoReorden] [decimal](18, 4) NOT NULL,
	[DiasVidaUtil] [int] NULL,
	[Estado] [bit] NOT NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
	[Imagen] [varbinary](max) NULL,
	[ImagenContentType] [nvarchar](50) NULL,
	[Fracciona] [nvarchar](10) NOT NULL,
	[PrecioVentaUnidad] [decimal](18, 4) NULL,
	[Costo] [decimal](18, 2) NULL,
	[PPublico] [decimal](18, 0) NULL,
	[PBodega] [decimal](18, 0) NULL,
	[PCredito] [decimal](18, 0) NULL,
	[UPublico] [decimal](18, 2) NULL,
	[UBodega] [decimal](18, 2) NULL,
	[UCredito] [decimal](18, 2) NULL,
	[MarcaCodigo] [nvarchar](10) NULL,
	[GrupoMenorCodigo] [nvarchar](10) NULL,
	[PresentacionCodigo] [nvarchar](10) NULL,
	[Peso] [decimal](18, 2) NULL,
	[IvaSiNo] [nvarchar](2) NULL,
	[IvaValor] [smallint] NULL,
	[IvaDescripcion] [nvarchar](50) NULL,
	[Iva2] [smallint] NULL,
	[IvaDescripcion2] [nvarchar](50) NULL,
	[FechaModificacion] [datetime] NULL,
	[ArticuloPadreID] [int] NULL,
	[NombreVariante] [nvarchar](100) NULL,
PRIMARY KEY CLUSTERED 
(
	[ArticuloID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[Referencia] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [Produccion].[OrdenesProduccion]    Script Date: 1/09/2026 5:35:41 p. m. ******/
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
/****** Object:  Table [Produccion].[EstadosOP]    Script Date: 1/09/2026 5:35:41 p. m. ******/
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
/****** Object:  View [Produccion].[vw_ProduccionPlanVsReal]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [Produccion].[vw_ProduccionPlanVsReal] AS
SELECT
    CAST(op.FechaPlanificada AS DATE) AS Fecha,
    cc.CentroCostoID,
    cc.Nombre AS CentroCosto,
    a.Nombre  AS Producto,
    SUM(op.CantidadProgramada)                   AS TotalPlanificado,
    SUM(ISNULL(op.CantidadProducidaReal, 0))     AS TotalReal
FROM Produccion.OrdenesProduccion op
JOIN Organizacion.CentrosCosto cc ON cc.CentroCostoID = op.CentroCostoDestinoID
JOIN Catalogo.Tarjetas a          ON a.ArticuloID     = op.ProductoTerminadoID
WHERE op.EstadoOPID <> (SELECT EstadoOPID FROM Produccion.EstadosOP WHERE Nombre = 'Cancelada')
GROUP BY CAST(op.FechaPlanificada AS DATE), cc.CentroCostoID, cc.Nombre, a.Nombre;

GO
/****** Object:  Table [Inventario].[Bodegas]    Script Date: 1/09/2026 5:35:41 p. m. ******/
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
/****** Object:  Table [Inventario].[Lotes]    Script Date: 1/09/2026 5:35:41 p. m. ******/
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
/****** Object:  Table [Inventario].[InventarioStock]    Script Date: 1/09/2026 5:35:41 p. m. ******/
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
/****** Object:  Table [catalogo].[TiposArticulo]    Script Date: 1/09/2026 5:35:41 p. m. ******/
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
/****** Object:  Table [catalogo].[Presentacion]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [catalogo].[Presentacion](
	[Codigo] [nvarchar](10) NOT NULL,
	[Presentacion] [nvarchar](50) NOT NULL,
	[Fracciones] [decimal](10, 2) NULL,
	[Tipo] [nvarchar](20) NULL,
 CONSTRAINT [PK_Presentaciones] PRIMARY KEY CLUSTERED 
(
	[Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [Inventario].[vw_StockConsolidado]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [Inventario].[vw_StockConsolidado] AS
    SELECT
        a.ArticuloID,
        a.Referencia          AS SKU,
        a.Nombre              AS Articulo,
        ta.Nombre             AS TipoArticulo,
        a.PresentacionCodigo  AS Unidad,          -- antes: u.Abreviatura
        p.Fracciones          AS UnidadesPorEmbalaje,
        b.BodegaID,
        b.Nombre              AS Bodega,
        cc.CentroCostoID,
        cc.Nombre             AS CentroCosto,
        ist.LoteID,
        lot.NumeroLote,
        lot.FechaVencimiento,
        ist.CantidadActual,
        ist.CostoUnitarioLote,
        ist.CantidadActual * ist.CostoUnitarioLote  AS ValorTotal,
        CAST(
            CASE
                WHEN a.StockMinimo > 0
                 AND (SELECT ISNULL(SUM(s2.CantidadActual),0)
                      FROM Inventario.InventarioStock s2
                      WHERE s2.ArticuloID = a.ArticuloID) < a.StockMinimo
                THEN 1 ELSE 0
            END
        AS BIT) AS RequierePedido
    FROM Inventario.InventarioStock ist
    JOIN Catalogo.Tarjetas a
        ON a.ArticuloID = ist.ArticuloID
    JOIN Catalogo.TiposArticulo ta
        ON ta.TipoArticuloID = a.TipoArticuloID
    LEFT JOIN Catalogo.Presentacion p
        ON p.Codigo = a.PresentacionCodigo
    JOIN Inventario.Bodegas b
        ON b.BodegaID = ist.BodegaID
    JOIN Organizacion.CentrosCosto cc
        ON cc.CentroCostoID = b.CentroCostoID
    LEFT JOIN Inventario.Lotes lot
        ON lot.LoteID = ist.LoteID
    WHERE ist.CantidadActual <> 0;

GO
/****** Object:  Table [Integracion].[MapeoArticulos]    Script Date: 1/09/2026 5:35:41 p. m. ******/
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
/****** Object:  Table [Integracion].[EventosSalientes]    Script Date: 1/09/2026 5:35:41 p. m. ******/
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
/****** Object:  View [Integracion].[vw_EventosPendientesParaVisions]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Vista que el agente de sincronizacion consulta directamente: ya trae
-- el codigo de centro de costo y de referencia en el formato que Visions
-- necesita, sin que el agente tenga que hacer los JOIN.
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
/****** Object:  View [Produccion].[vw_DistribucionPorCentroCosto]    Script Date: 1/09/2026 5:35:41 p. m. ******/
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
/****** Object:  Table [Kardex].[TiposMotivoLoss]    Script Date: 1/09/2026 5:35:41 p. m. ******/
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
/****** Object:  Table [Kardex].[BajasInventarioPerdidas]    Script Date: 1/09/2026 5:35:41 p. m. ******/
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
/****** Object:  View [Kardex].[vw_PerdidasPorMotivo]    Script Date: 1/09/2026 5:35:41 p. m. ******/
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
/****** Object:  View [Produccion].[vw_TendenciaCostoUnitario]    Script Date: 1/09/2026 5:35:41 p. m. ******/
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
JOIN Catalogo.Tarjetas a ON a.ArticuloID = op.ProductoTerminadoID
WHERE op.EstadoOPID = (SELECT EstadoOPID FROM Produccion.EstadosOP WHERE Nombre = 'Finalizada')
  AND op.FechaFin IS NOT NULL;
GO
/****** Object:  View [Produccion].[vw_CumplimientoPlanificacion]    Script Date: 1/09/2026 5:35:41 p. m. ******/
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
/****** Object:  Table [Auditoria].[HistorialPrecios]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Auditoria].[HistorialPrecios](
	[HistorialID] [int] IDENTITY(1,1) NOT NULL,
	[ArticuloID] [int] NOT NULL,
	[UsuarioID] [int] NOT NULL,
	[NombreUsuario] [nvarchar](100) NOT NULL,
	[Campo] [nvarchar](50) NOT NULL,
	[ValorAnterior] [decimal](18, 2) NULL,
	[ValorNuevo] [decimal](18, 2) NULL,
	[FechaCambio] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[HistorialID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Auditoria].[LogAuditoria]    Script Date: 1/09/2026 5:35:41 p. m. ******/
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
/****** Object:  Table [Calendario].[EventoAsistentes]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Calendario].[EventoAsistentes](
	[EventoID] [int] NOT NULL,
	[UsuarioID] [int] NOT NULL,
	[Estado] [nvarchar](20) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[EventoID] ASC,
	[UsuarioID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Calendario].[Eventos]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Calendario].[Eventos](
	[EventoID] [int] IDENTITY(1,1) NOT NULL,
	[Titulo] [nvarchar](200) NOT NULL,
	[TipoEvento] [nvarchar](50) NOT NULL,
	[FechaInicio] [datetime2](7) NOT NULL,
	[FechaFin] [datetime2](7) NOT NULL,
	[Lugar] [nvarchar](200) NULL,
	[LinkVirtual] [nvarchar](500) NULL,
	[Descripcion] [nvarchar](2000) NULL,
	[CentroCostoID] [int] NULL,
	[CreadoPorUsuarioID] [int] NOT NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
	[Activo] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[EventoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [catalogo].[ArticuloProveedor]    Script Date: 1/09/2026 5:35:41 p. m. ******/
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
/****** Object:  Table [catalogo].[GrupoMayor]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [catalogo].[GrupoMayor](
	[Codigo] [nvarchar](10) NOT NULL,
	[Nombre] [nvarchar](255) NULL,
 CONSTRAINT [PK_GruposMayores] PRIMARY KEY CLUSTERED 
(
	[Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [catalogo].[GrupoMenor]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [catalogo].[GrupoMenor](
	[Codigo] [nvarchar](10) NOT NULL,
	[Nombre] [nvarchar](255) NULL,
	[GrupoMayor] [nvarchar](10) NOT NULL,
 CONSTRAINT [PK_GruposMenores] PRIMARY KEY CLUSTERED 
(
	[Codigo] ASC,
	[GrupoMayor] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [catalogo].[Iva]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [catalogo].[Iva](
	[IvaID] [int] IDENTITY(1,1) NOT NULL,
	[Iva] [int] NOT NULL,
	[Descripcion] [nvarchar](50) NULL,
 CONSTRAINT [PK_Iva] PRIMARY KEY CLUSTERED 
(
	[IvaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [catalogo].[Marca]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [catalogo].[Marca](
	[Codigo] [nvarchar](10) NOT NULL,
	[Marca] [nvarchar](255) NULL,
 CONSTRAINT [PK_Marcas] PRIMARY KEY CLUSTERED 
(
	[Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [catalogo].[Municipios]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [catalogo].[Municipios](
	[CodigoDept] [nvarchar](3) NOT NULL,
	[NombreDept] [nvarchar](80) NULL,
	[CodigoMuni] [nvarchar](3) NOT NULL,
	[NombreMuni] [nvarchar](80) NULL,
 CONSTRAINT [PK_Municipios] PRIMARY KEY CLUSTERED 
(
	[CodigoDept] ASC,
	[CodigoMuni] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [catalogo].[Paises]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [catalogo].[Paises](
	[Codigo1] [nvarchar](4) NOT NULL,
	[Codigo2] [nvarchar](4) NULL,
	[Codigo3] [nvarchar](4) NULL,
	[Nombre] [nvarchar](255) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Codigo1] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [catalogo].[Proveedores]    Script Date: 1/09/2026 5:35:41 p. m. ******/
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
	[TipoPersona] [nvarchar](20) NULL,
	[PrimerNombre] [nvarchar](100) NULL,
	[SegundoNombre] [nvarchar](100) NULL,
	[PrimerApellido] [nvarchar](100) NULL,
	[SegundoApellido] [nvarchar](100) NULL,
	[TipoIdentificacion] [nvarchar](10) NULL,
	[DigitoVerificacion] [int] NULL,
	[Departamento] [nvarchar](100) NULL,
	[Ciudad] [nvarchar](100) NULL,
	[CodigoDept] [nvarchar](5) NULL,
	[CodigoMuni] [nvarchar](5) NULL,
	[Pais] [nvarchar](100) NULL,
	[CodigoPais] [nvarchar](4) NULL,
	[FechaModificacion] [datetime] NULL,
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
/****** Object:  Table [catalogo].[TiposIdentificacion]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [catalogo].[TiposIdentificacion](
	[Codigo] [nvarchar](10) NOT NULL,
	[Detalle] [nvarchar](100) NULL,
PRIMARY KEY CLUSTERED 
(
	[Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [catalogo].[UnidadesConversion]    Script Date: 1/09/2026 5:35:41 p. m. ******/
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
/****** Object:  Table [catalogo].[UnidadesMedida]    Script Date: 1/09/2026 5:35:41 p. m. ******/
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
/****** Object:  Table [Compras].[OrdenesCompra]    Script Date: 1/09/2026 5:35:41 p. m. ******/
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
	[CentroCostoID] [int] NULL,
	[ExportadoVisions] [bit] NOT NULL,
	[NroDocVisions] [nvarchar](50) NULL,
	[TipDocVisions] [nvarchar](20) NULL,
	[TipoMovimiento] [nvarchar](20) NOT NULL,
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
/****** Object:  Table [Compras].[OrdenesCompraDetalle]    Script Date: 1/09/2026 5:35:41 p. m. ******/
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
	[FechaUltimaRecepcion] [datetime2](7) NULL,
PRIMARY KEY CLUSTERED 
(
	[OrdenCompraDetalleID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Conocimiento].[Articulos]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Conocimiento].[Articulos](
	[ArticuloID] [int] IDENTITY(1,1) NOT NULL,
	[Titulo] [nvarchar](300) NOT NULL,
	[Contenido] [nvarchar](max) NOT NULL,
	[Categoria] [nvarchar](100) NOT NULL,
	[Tags] [nvarchar](500) NULL,
	[AutorID] [int] NOT NULL,
	[FechaCreacion] [datetime] NOT NULL,
	[FechaActualizacion] [datetime] NOT NULL,
	[Activo] [bit] NOT NULL,
	[Vistas] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ArticuloID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [Crm].[Actividades]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Crm].[Actividades](
	[ActividadID] [int] IDENTITY(1,1) NOT NULL,
	[Tipo] [nvarchar](50) NOT NULL,
	[Titulo] [nvarchar](200) NOT NULL,
	[Notas] [nvarchar](2000) NULL,
	[FechaVencimiento] [datetime2](7) NULL,
	[Completada] [bit] NOT NULL,
	[FechaCompletada] [datetime2](7) NULL,
	[OportunidadID] [int] NULL,
	[ClienteID] [int] NULL,
	[ResponsableID] [int] NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ActividadID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Crm].[ClienteDocumentos]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Crm].[ClienteDocumentos](
	[DocumentoID] [int] IDENTITY(1,1) NOT NULL,
	[ClienteID] [int] NOT NULL,
	[TipoDocumento] [nvarchar](30) NOT NULL,
	[NombreArchivo] [nvarchar](255) NOT NULL,
	[ContentType] [nvarchar](100) NOT NULL,
	[Archivo] [varbinary](max) NOT NULL,
	[FechaSubida] [datetime2](7) NOT NULL,
	[UsuarioID] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[DocumentoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [Crm].[Clientes]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Crm].[Clientes](
	[ClienteID] [int] IDENTITY(1,1) NOT NULL,
	[Nombre] [nvarchar](150) NOT NULL,
	[NIT] [nvarchar](30) NULL,
	[Contacto] [nvarchar](100) NULL,
	[Telefono] [nvarchar](30) NULL,
	[Email] [nvarchar](150) NULL,
	[Direccion] [nvarchar](200) NULL,
	[Estado] [bit] NOT NULL,
	[FuenteContacto] [nvarchar](50) NULL,
	[TipoCliente] [nvarchar](30) NULL,
	[FechaCreacion] [datetime2](7) NULL,
	[ResponsableID] [int] NULL,
	[ProximoContacto] [date] NULL,
	[ClienteGuid] [uniqueidentifier] NOT NULL,
	[ExternalId] [nvarchar](12) NOT NULL,
	[FechaModificacion] [datetime] NULL,
	[TipoPersona] [nvarchar](20) NULL,
	[PrimerNombre] [nvarchar](100) NULL,
	[SegundoNombre] [nvarchar](100) NULL,
	[PrimerApellido] [nvarchar](100) NULL,
	[SegundoApellido] [nvarchar](100) NULL,
	[Departamento] [nvarchar](100) NULL,
	[Ciudad] [nvarchar](100) NULL,
	[TipoIdentificacion] [nvarchar](10) NULL,
	[CodigoDept] [nvarchar](3) NULL,
	[CodigoMuni] [nvarchar](3) NULL,
	[DigitoVerificacion] [int] NULL,
	[Pais] [nvarchar](100) NULL,
	[CodigoPais] [nvarchar](4) NULL,
PRIMARY KEY CLUSTERED 
(
	[ClienteID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Crm].[Contactos]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Crm].[Contactos](
	[ContactoID] [int] IDENTITY(1,1) NOT NULL,
	[ClienteID] [int] NOT NULL,
	[Nombres] [nvarchar](150) NOT NULL,
	[Cargo] [nvarchar](100) NULL,
	[Telefono] [nvarchar](30) NULL,
	[Email] [nvarchar](150) NULL,
	[EsPrincipal] [bit] NOT NULL,
	[Estado] [bit] NOT NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ContactoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Crm].[Cotizaciones]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Crm].[Cotizaciones](
	[CotizacionID] [int] IDENTITY(1,1) NOT NULL,
	[ClienteID] [int] NOT NULL,
	[OportunidadID] [int] NULL,
	[Fecha] [date] NOT NULL,
	[ValidoHasta] [date] NULL,
	[Estado] [nvarchar](20) NOT NULL,
	[Notas] [nvarchar](500) NULL,
	[FacturaID] [int] NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
	[UsuarioID] [int] NULL,
	[CentroCostoID] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[CotizacionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Crm].[CotizacionLineas]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Crm].[CotizacionLineas](
	[LineaID] [int] IDENTITY(1,1) NOT NULL,
	[CotizacionID] [int] NOT NULL,
	[ArticuloID] [int] NOT NULL,
	[Cantidad] [decimal](18, 4) NOT NULL,
	[PrecioUnitario] [decimal](18, 2) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[LineaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Crm].[EjecucionesAutomatizacion]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Crm].[EjecucionesAutomatizacion](
	[EjecucionID] [bigint] IDENTITY(1,1) NOT NULL,
	[ReglaID] [int] NOT NULL,
	[EntidadTipo] [nvarchar](50) NOT NULL,
	[EntidadID] [int] NOT NULL,
	[FechaEjecucion] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[EjecucionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Crm].[Interacciones]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Crm].[Interacciones](
	[InteraccionID] [bigint] IDENTITY(1,1) NOT NULL,
	[ClienteID] [int] NOT NULL,
	[Tipo] [nvarchar](30) NOT NULL,
	[Notas] [nvarchar](1000) NOT NULL,
	[Fecha] [datetime2](7) NOT NULL,
	[UsuarioID] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[InteraccionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Crm].[Leads]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Crm].[Leads](
	[LeadID] [int] IDENTITY(1,1) NOT NULL,
	[Nombre] [nvarchar](150) NOT NULL,
	[Empresa] [nvarchar](150) NULL,
	[Telefono] [nvarchar](30) NULL,
	[Email] [nvarchar](150) NULL,
	[FuenteContacto] [nvarchar](50) NULL,
	[Etapa] [nvarchar](20) NOT NULL,
	[Notas] [nvarchar](500) NULL,
	[ResponsableID] [int] NULL,
	[ClienteIDConvertido] [int] NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
	[FechaConversion] [datetime2](7) NULL,
	[NIT] [nvarchar](20) NULL,
	[Direccion] [nvarchar](300) NULL,
	[TipoCliente] [nvarchar](50) NULL,
	[TipoPersona] [nvarchar](20) NULL,
	[TipoIdentificacion] [nvarchar](10) NULL,
	[PrimerNombre] [nvarchar](100) NULL,
	[SegundoNombre] [nvarchar](100) NULL,
	[PrimerApellido] [nvarchar](100) NULL,
	[SegundoApellido] [nvarchar](100) NULL,
	[CodigoDept] [nvarchar](10) NULL,
	[CodigoMuni] [nvarchar](10) NULL,
	[Departamento] [nvarchar](100) NULL,
	[Ciudad] [nvarchar](100) NULL,
	[DigitoVerificacion] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[LeadID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Crm].[LineasCredito]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Crm].[LineasCredito](
	[ClienteID] [int] NOT NULL,
	[CupoCredito] [decimal](18, 2) NOT NULL,
	[Observaciones] [nvarchar](500) NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
	[FechaActualiza] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_LineasCredito] PRIMARY KEY CLUSTERED 
(
	[ClienteID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Crm].[Oportunidades]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Crm].[Oportunidades](
	[OportunidadID] [int] IDENTITY(1,1) NOT NULL,
	[LeadID] [int] NULL,
	[ClienteID] [int] NULL,
	[Nombre] [nvarchar](150) NOT NULL,
	[ValorEstimado] [decimal](18, 2) NOT NULL,
	[Etapa] [nvarchar](20) NOT NULL,
	[FechaCierreEsperada] [date] NULL,
	[ResponsableID] [int] NULL,
	[Notas] [nvarchar](1000) NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
	[FechaCierre] [datetime2](7) NULL,
	[ConfianzaCierre] [nvarchar](20) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[OportunidadID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Crm].[ReglasAutomatizacion]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Crm].[ReglasAutomatizacion](
	[ReglaID] [int] IDENTITY(1,1) NOT NULL,
	[Nombre] [nvarchar](100) NOT NULL,
	[Descripcion] [nvarchar](500) NULL,
	[Evento] [nvarchar](50) NOT NULL,
	[ParametrosJSON] [nvarchar](1000) NOT NULL,
	[Activa] [bit] NOT NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ReglaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Facturacion].[Devoluciones]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Facturacion].[Devoluciones](
	[DevolucionID] [int] IDENTITY(1,1) NOT NULL,
	[TipoDevolucion] [nvarchar](20) NOT NULL,
	[FacturaOrigenID] [int] NULL,
	[ClienteID] [int] NULL,
	[ProveedorID] [int] NULL,
	[CentroCostoID] [int] NULL,
	[Fecha] [date] NOT NULL,
	[Motivo] [nvarchar](500) NULL,
	[NroDoc] [nvarchar](50) NULL,
	[Total] [decimal](18, 4) NOT NULL,
	[StockRestituido] [bit] NOT NULL,
	[OrigenVisions] [bit] NOT NULL,
	[EventoEntranteID] [bigint] NULL,
	[UsuarioID] [int] NULL,
	[FechaRegistro] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_Devoluciones] PRIMARY KEY CLUSTERED 
(
	[DevolucionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Facturacion].[DevolucionLineas]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Facturacion].[DevolucionLineas](
	[LineaID] [int] IDENTITY(1,1) NOT NULL,
	[DevolucionID] [int] NOT NULL,
	[ArticuloID] [int] NOT NULL,
	[Cantidad] [decimal](18, 4) NOT NULL,
	[CostoUnitario] [decimal](18, 4) NOT NULL,
	[Subtotal]  AS ([Cantidad]*[CostoUnitario]),
	[Nota] [nvarchar](255) NULL,
 CONSTRAINT [PK_DevolucionLineas] PRIMARY KEY CLUSTERED 
(
	[LineaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Facturacion].[FacturaLineas]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Facturacion].[FacturaLineas](
	[LineaID] [int] IDENTITY(1,1) NOT NULL,
	[FacturaID] [int] NOT NULL,
	[ArticuloID] [int] NULL,
	[Cantidad] [decimal](18, 8) NULL,
	[PrecioUnitario] [decimal](18, 2) NOT NULL,
	[ComboID] [int] NULL,
	[DescripcionLinea] [nvarchar](200) NULL,
	[Nota] [varchar](200) NULL,
PRIMARY KEY CLUSTERED 
(
	[LineaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Facturacion].[Facturas]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Facturacion].[Facturas](
	[FacturaID] [int] IDENTITY(1,1) NOT NULL,
	[ClienteID] [int] NOT NULL,
	[Fecha] [date] NOT NULL,
	[Notas] [nvarchar](500) NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
	[UsuarioID] [int] NULL,
	[StockDescontado] [bit] NOT NULL,
	[ProduccionAutoEjecutada] [bit] NOT NULL,
	[TipDoc] [varchar](30) NOT NULL,
	[NroDoc] [varchar](50) NULL,
	[VisionsConfirmado] [bit] NOT NULL,
	[CentroCostoID] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[FacturaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Facturacion].[FacturasExportadasVisions]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Facturacion].[FacturasExportadasVisions](
	[FacturaID] [int] NOT NULL,
	[CentroCostoID] [int] NOT NULL,
	[FechaExportado] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_FacturasExportadasVisions] PRIMARY KEY CLUSTERED 
(
	[FacturaID] ASC,
	[CentroCostoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Facturacion].[Pagos]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Facturacion].[Pagos](
	[PagoID] [int] IDENTITY(1,1) NOT NULL,
	[FacturaID] [int] NOT NULL,
	[Monto] [decimal](18, 2) NOT NULL,
	[FechaPago] [date] NOT NULL,
	[Notas] [nvarchar](300) NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
	[UsuarioID] [int] NULL,
	[MetodoPago] [nvarchar](20) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[PagoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Finanzas].[GastosOperativos]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Finanzas].[GastosOperativos](
	[GastoID] [int] IDENTITY(1,1) NOT NULL,
	[Fecha] [date] NOT NULL,
	[Categoria] [nvarchar](100) NOT NULL,
	[Descripcion] [nvarchar](500) NOT NULL,
	[Monto] [decimal](18, 2) NOT NULL,
	[Proveedor] [nvarchar](200) NULL,
	[Comprobante] [nvarchar](200) NULL,
	[CentroCostoID] [int] NULL,
	[Notas] [nvarchar](1000) NULL,
	[CreadoPor] [int] NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[GastoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Formularios].[Campos]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Formularios].[Campos](
	[CampoID] [int] IDENTITY(1,1) NOT NULL,
	[FormularioID] [int] NOT NULL,
	[Tipo] [nvarchar](30) NOT NULL,
	[Etiqueta] [nvarchar](300) NOT NULL,
	[Placeholder] [nvarchar](300) NULL,
	[Requerido] [bit] NOT NULL,
	[Orden] [int] NOT NULL,
	[Opciones] [nvarchar](max) NULL,
PRIMARY KEY CLUSTERED 
(
	[CampoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [Formularios].[Formularios]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Formularios].[Formularios](
	[FormularioID] [int] IDENTITY(1,1) NOT NULL,
	[Titulo] [nvarchar](300) NOT NULL,
	[Descripcion] [nvarchar](1000) NULL,
	[Token] [nvarchar](64) NOT NULL,
	[Activo] [bit] NOT NULL,
	[AceptaRespuestas] [bit] NOT NULL,
	[MensajeExito] [nvarchar](500) NULL,
	[CreadoPor] [int] NOT NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
	[FechaActualizacion] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[FormularioID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[Token] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Formularios].[Respuestas]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Formularios].[Respuestas](
	[RespuestaID] [int] IDENTITY(1,1) NOT NULL,
	[FormularioID] [int] NOT NULL,
	[Datos] [nvarchar](max) NOT NULL,
	[IPOrigen] [nvarchar](45) NULL,
	[FechaRespuesta] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[RespuestaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [Integracion].[AgentesSync]    Script Date: 1/09/2026 5:35:41 p. m. ******/
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
	[UltimoLatido] [datetime2](7) NULL,
	[VersionAgente] [nvarchar](20) NULL,
	[IntervalMinutes] [int] NOT NULL,
	[VisionsDbConexion] [nvarchar](500) NULL,
	[NexoApiBaseUrl] [nvarchar](300) NULL,
	[AgentePath] [nvarchar](500) NULL,
	[IntervalSeconds] [int] NOT NULL,
	[FechaInicioSyncVentas] [date] NULL,
	[ApiKeyPlain] [nvarchar](200) NULL,
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
/****** Object:  Table [Integracion].[ArticulosPendientesMapeo]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Integracion].[ArticulosPendientesMapeo](
	[PendienteID] [int] IDENTITY(1,1) NOT NULL,
	[CentroCostoID] [int] NOT NULL,
	[CodigoArticuloVisions] [nvarchar](30) NOT NULL,
	[NombreVisions] [nvarchar](255) NULL,
	[CostoVisions] [decimal](18, 4) NULL,
	[PrecioVisions] [decimal](18, 4) NULL,
	[CantidadDetectada] [decimal](18, 4) NOT NULL,
	[FechaDetectado] [datetime2](7) NOT NULL,
	[Resuelto] [bit] NOT NULL,
	[FechaResuelto] [datetime2](7) NULL,
PRIMARY KEY CLUSTERED 
(
	[PendienteID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_ArticulosPendientesMapeo] UNIQUE NONCLUSTERED 
(
	[CentroCostoID] ASC,
	[CodigoArticuloVisions] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Integracion].[EventosEntrantes]    Script Date: 1/09/2026 5:35:41 p. m. ******/
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
	[NombreArticuloVisions] [nvarchar](255) NULL,
	[CostoArticuloVisions] [decimal](18, 4) NULL,
	[PrecioArticuloVisions] [decimal](18, 4) NULL,
	[TipDoc] [nvarchar](30) NULL,
	[NroDoc] [nvarchar](80) NULL,
	[NitCliente] [nvarchar](20) NULL,
	[NombreCliente] [nvarchar](200) NULL,
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
/****** Object:  Table [Integracion].[InventarioReportadoVisions]    Script Date: 1/09/2026 5:35:41 p. m. ******/
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
/****** Object:  Table [Integracion].[PendientesLimpiezaVisions]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Integracion].[PendientesLimpiezaVisions](
	[LimpiezaID] [int] IDENTITY(1,1) NOT NULL,
	[Tipo] [nvarchar](20) NOT NULL,
	[EntidadID] [int] NOT NULL,
	[FechaRegistro] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[LimpiezaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Inventario].[TraspasosBodega]    Script Date: 1/09/2026 5:35:41 p. m. ******/
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
/****** Object:  Table [Inventario].[TraspasosDetalle]    Script Date: 1/09/2026 5:35:41 p. m. ******/
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
/****** Object:  Table [Kardex].[AjustesInventario]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Kardex].[AjustesInventario](
	[AjusteID] [int] IDENTITY(1,1) NOT NULL,
	[CodigoAjuste] [nvarchar](30) NOT NULL,
	[Fecha] [datetime2](7) NOT NULL,
	[ArticuloID] [int] NOT NULL,
	[BodegaID] [int] NOT NULL,
	[LoteID] [int] NULL,
	[CantidadAjustada] [decimal](18, 4) NOT NULL,
	[CostoUnitario] [decimal](18, 4) NOT NULL,
	[CostoTotal]  AS ([CantidadAjustada]*[CostoUnitario]) PERSISTED,
	[Motivo] [nvarchar](300) NOT NULL,
	[UsuarioRegistraID] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[AjusteID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_AjusteInventario_Codigo] UNIQUE NONCLUSTERED 
(
	[CodigoAjuste] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Kardex].[KardexMovimientos]    Script Date: 1/09/2026 5:35:41 p. m. ******/
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
	[Cantidad] [decimal](18, 8) NULL,
	[CostoUnitario] [decimal](18, 4) NOT NULL,
	[CantidadSaldo] [decimal](18, 8) NULL,
	[CostoPromedioSaldo] [decimal](18, 4) NOT NULL,
	[ObservacionDetallada] [nvarchar](500) NULL,
	[UsuarioID] [int] NOT NULL,
	[FechaRegistro] [datetime2](7) NOT NULL,
	[AjusteID] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[KardexID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Kardex].[TiposMovimientoKardex]    Script Date: 1/09/2026 5:35:41 p. m. ******/
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
/****** Object:  Table [Logistica].[DespachoDetalle]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Logistica].[DespachoDetalle](
	[DetalleID] [int] IDENTITY(1,1) NOT NULL,
	[DespachoID] [int] NOT NULL,
	[ArticuloID] [int] NOT NULL,
	[Cantidad] [decimal](18, 8) NULL,
	[ValorUnitario] [decimal](18, 4) NULL,
PRIMARY KEY CLUSTERED 
(
	[DetalleID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Logistica].[Despachos]    Script Date: 1/09/2026 5:35:41 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Logistica].[Despachos](
	[DespachoID] [int] IDENTITY(1,1) NOT NULL,
	[ClienteID] [int] NOT NULL,
	[CentroCostoID] [int] NOT NULL,
	[BodegaOrigenID] [int] NOT NULL,
	[Direccion] [nvarchar](200) NULL,
	[Observaciones] [nvarchar](500) NULL,
	[Estado] [nvarchar](20) NOT NULL,
	[FechaDespacho] [datetime2](7) NOT NULL,
	[FechaEntrega] [datetime2](7) NULL,
	[UsuarioID] [int] NULL,
	[MotivoAnulacion] [nvarchar](300) NULL,
	[FechaAnulacion] [datetime2](7) NULL,
	[UsuarioAnulaID] [int] NULL,
	[DescuentaStock] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[DespachoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Marketing].[Campanas]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Marketing].[Campanas](
	[CampanaID] [int] IDENTITY(1,1) NOT NULL,
	[Nombre] [nvarchar](200) NOT NULL,
	[Descripcion] [nvarchar](500) NULL,
	[Asunto] [nvarchar](300) NOT NULL,
	[BloqueJSON] [nvarchar](max) NOT NULL,
	[Estado] [nvarchar](50) NOT NULL,
	[SegmentoTipo] [nvarchar](100) NULL,
	[SegmentoValor] [nvarchar](200) NULL,
	[TotalDestinatarios] [int] NOT NULL,
	[TotalEnviados] [int] NOT NULL,
	[TotalAbiertos] [int] NOT NULL,
	[TotalClicks] [int] NOT NULL,
	[TotalDesuscriptos] [int] NOT NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
	[FechaEnvio] [datetime2](7) NULL,
	[UsuarioID] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[CampanaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [Marketing].[ComboItems]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Marketing].[ComboItems](
	[ComboItemID] [int] IDENTITY(1,1) NOT NULL,
	[ComboID] [int] NOT NULL,
	[ArticuloID] [int] NOT NULL,
	[Cantidad] [decimal](18, 4) NOT NULL,
	[PrecioUnitarioSnapshot] [decimal](18, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[ComboItemID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Marketing].[Combos]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Marketing].[Combos](
	[ComboID] [int] IDENTITY(1,1) NOT NULL,
	[Nombre] [nvarchar](150) NOT NULL,
	[Descripcion] [nvarchar](500) NULL,
	[ImagenBase64] [nvarchar](max) NULL,
	[ImagenContentType] [nvarchar](100) NULL,
	[Estado] [nvarchar](20) NOT NULL,
	[FechaInicio] [date] NULL,
	[FechaFin] [date] NULL,
	[ModoPrecio] [nvarchar](10) NOT NULL,
	[PrecioManual] [decimal](18, 2) NULL,
	[PorcentajeDescuento] [decimal](5, 2) NOT NULL,
	[FechaCreacion] [datetime] NOT NULL,
	[UsuarioCreaID] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[ComboID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [Marketing].[EnviosDetalle]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Marketing].[EnviosDetalle](
	[EnvioID] [bigint] IDENTITY(1,1) NOT NULL,
	[CampanaID] [int] NOT NULL,
	[ClienteID] [int] NOT NULL,
	[Email] [nvarchar](200) NOT NULL,
	[NombreCliente] [nvarchar](200) NOT NULL,
	[EmpresaCliente] [nvarchar](200) NULL,
	[Token] [nvarchar](100) NOT NULL,
	[Enviado] [bit] NOT NULL,
	[FechaEnvio] [datetime2](7) NULL,
	[Abierto] [bit] NOT NULL,
	[FechaApertura] [datetime2](7) NULL,
	[Clicks] [int] NOT NULL,
	[UltimoClick] [datetime2](7) NULL,
	[Desuscripto] [bit] NOT NULL,
	[FechaDesuscripcion] [datetime2](7) NULL,
	[Error] [nvarchar](500) NULL,
PRIMARY KEY CLUSTERED 
(
	[EnvioID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Marketing].[Imagenes]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Marketing].[Imagenes](
	[ImagenID] [int] IDENTITY(1,1) NOT NULL,
	[Nombre] [nvarchar](200) NOT NULL,
	[ContentType] [nvarchar](100) NOT NULL,
	[DatosBase64] [nvarchar](max) NOT NULL,
	[FechaSubida] [datetime2](7) NOT NULL,
	[UsuarioID] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[ImagenID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [Organizacion].[CentrosTrabajo]    Script Date: 1/09/2026 5:35:42 p. m. ******/
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
/****** Object:  Table [Organizacion].[ConfiguracionEmail]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Organizacion].[ConfiguracionEmail](
	[ConfiguracionID] [int] NOT NULL,
	[Proveedor] [nvarchar](50) NOT NULL,
	[ApiKey] [nvarchar](500) NULL,
	[EmailFrom] [nvarchar](200) NULL,
	[NombreFrom] [nvarchar](200) NULL,
	[Activo] [bit] NOT NULL,
	[FechaModificacion] [datetime2](7) NOT NULL,
	[EmailsHoy] [int] NOT NULL,
	[FechaContador] [date] NULL,
PRIMARY KEY CLUSTERED 
(
	[ConfiguracionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Organizacion].[ConfiguracionEmpresa]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Organizacion].[ConfiguracionEmpresa](
	[ConfiguracionID] [int] NOT NULL,
	[NombreEmpresa] [nvarchar](100) NOT NULL,
	[Logo] [varbinary](max) NULL,
	[LogoContentType] [nvarchar](50) NULL,
	[UsaVisions] [bit] NOT NULL,
	[NombrePropietario] [nvarchar](200) NULL,
	[ManejarVencimientos] [bit] NOT NULL,
	[DiasAlertaVencimiento] [int] NOT NULL,
	[ModoLotes] [nvarchar](10) NOT NULL,
	[ModoNroDoc] [nvarchar](20) NOT NULL,
	[UltimoNroDocSecuencial] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ConfiguracionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [Organizacion].[ConfiguracionWhatsApp]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Organizacion].[ConfiguracionWhatsApp](
	[ConfiguracionID] [int] NOT NULL,
	[AccountSid] [nvarchar](100) NULL,
	[AuthToken] [nvarchar](200) NULL,
	[FromNumber] [nvarchar](50) NOT NULL,
	[Activo] [bit] NOT NULL,
	[FechaModificacion] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_ConfiguracionWhatsApp] PRIMARY KEY CLUSTERED 
(
	[ConfiguracionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Planificacion].[DemandaProyectada]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Planificacion].[DemandaProyectada](
	[DemandaID] [int] IDENTITY(1,1) NOT NULL,
	[ArticuloID] [int] NOT NULL,
	[CentroCostoID] [int] NOT NULL,
	[Periodo] [date] NOT NULL,
	[CantidadProyectada] [decimal](18, 4) NOT NULL,
	[Notas] [nvarchar](300) NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[DemandaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_DemandaProyectada] UNIQUE NONCLUSTERED 
(
	[ArticuloID] ASC,
	[CentroCostoID] ASC,
	[Periodo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Planificacion].[MetasVenta]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Planificacion].[MetasVenta](
	[MetaID] [int] IDENTITY(1,1) NOT NULL,
	[CentroCostoID] [int] NOT NULL,
	[Periodo] [date] NOT NULL,
	[MetaValor] [decimal](18, 2) NOT NULL,
	[Notas] [nvarchar](300) NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[MetaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_MetasVenta] UNIQUE NONCLUSTERED 
(
	[CentroCostoID] ASC,
	[Periodo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Planificacion].[MetasVentaHistorial]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Planificacion].[MetasVentaHistorial](
	[HistorialID] [int] IDENTITY(1,1) NOT NULL,
	[MetaID] [int] NOT NULL,
	[MetaValorAnterior] [decimal](18, 2) NOT NULL,
	[NotasAnterior] [nvarchar](500) NULL,
	[FechaCambio] [datetime2](7) NOT NULL,
	[UsuarioID] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[HistorialID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Produccion].[MantenimientoMaquinaria]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Produccion].[MantenimientoMaquinaria](
	[MantenimientoID] [int] IDENTITY(1,1) NOT NULL,
	[MaquinariaID] [int] NOT NULL,
	[TipoMantenimiento] [nvarchar](30) NOT NULL,
	[FechaRealizado] [date] NOT NULL,
	[Descripcion] [nvarchar](500) NOT NULL,
	[Costo] [decimal](18, 2) NULL,
	[HorasFueraServicio] [decimal](10, 2) NULL,
	[Tecnico] [nvarchar](200) NULL,
	[ProximoMantenimiento] [date] NULL,
	[Observaciones] [nvarchar](500) NULL,
	[UsuarioID] [int] NULL,
	[FechaRegistro] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[MantenimientoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Produccion].[Maquinaria]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Produccion].[Maquinaria](
	[MaquinariaID] [int] IDENTITY(1,1) NOT NULL,
	[Codigo] [nvarchar](50) NOT NULL,
	[Nombre] [nvarchar](150) NOT NULL,
	[TipoMaquinariaID] [int] NOT NULL,
	[CentroTrabajoID] [int] NULL,
	[Estado] [nvarchar](30) NOT NULL,
	[Marca] [nvarchar](100) NULL,
	[Modelo] [nvarchar](100) NULL,
	[NumeroSerie] [nvarchar](100) NULL,
	[FechaAdquisicion] [date] NULL,
	[VidaUtilAnios] [int] NULL,
	[CostoAdquisicion] [decimal](18, 2) NULL,
	[CostoHoraOperacion] [decimal](18, 4) NULL,
	[CapacidadMaxima] [decimal](18, 4) NULL,
	[UnidadCapacidad] [nvarchar](50) NULL,
	[UbicacionFisica] [nvarchar](200) NULL,
	[Notas] [nvarchar](max) NULL,
	[FechaCreacion] [datetime] NOT NULL,
	[Foto] [varbinary](max) NULL,
	[FotoContentType] [nvarchar](100) NULL,
PRIMARY KEY CLUSTERED 
(
	[MaquinariaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_Maquinaria_Codigo] UNIQUE NONCLUSTERED 
(
	[Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [Produccion].[MotivosExcesoConsumo]    Script Date: 1/09/2026 5:35:42 p. m. ******/
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_MotivoExcesoConsumo_Nombre] UNIQUE NONCLUSTERED 
(
	[Nombre] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Produccion].[OrdenEmpleado]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Produccion].[OrdenEmpleado](
	[OrdenEmpleadoID] [int] IDENTITY(1,1) NOT NULL,
	[OrdenProduccionID] [int] NOT NULL,
	[EmpleadoID] [int] NOT NULL,
	[HorasReales] [decimal](18, 4) NULL,
	[Notas] [nvarchar](500) NULL,
PRIMARY KEY CLUSTERED 
(
	[OrdenEmpleadoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_OrdenEmpleado] UNIQUE NONCLUSTERED 
(
	[OrdenProduccionID] ASC,
	[EmpleadoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Produccion].[OrdenesProduccionConsumo]    Script Date: 1/09/2026 5:35:42 p. m. ******/
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
/****** Object:  Table [Produccion].[OrdenMaquinaria]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Produccion].[OrdenMaquinaria](
	[OrdenProduccionID] [int] NOT NULL,
	[MaquinariaID] [int] NOT NULL,
	[HorasReales] [decimal](10, 2) NULL,
	[Notas] [nvarchar](300) NULL,
 CONSTRAINT [PK_OrdenMaquinaria] PRIMARY KEY CLUSTERED 
(
	[OrdenProduccionID] ASC,
	[MaquinariaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Produccion].[RecetaBOM]    Script Date: 1/09/2026 5:35:42 p. m. ******/
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
	[Estado] [bit] NOT NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[RecetaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Produccion].[RecetaBOM_Detalle]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Produccion].[RecetaBOM_Detalle](
	[RecetaDetalleID] [int] IDENTITY(1,1) NOT NULL,
	[RecetaID] [int] NOT NULL,
	[InsumoID] [int] NOT NULL,
	[CantidadRequerida] [decimal](18, 4) NOT NULL,
	[PorcentajeMermaEstandar] [decimal](5, 2) NOT NULL,
	[CentroTrabajoID] [int] NULL,
	[Orden] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[RecetaDetalleID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Produccion].[RecetaEmpleado]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Produccion].[RecetaEmpleado](
	[RecetaEmpleadoID] [int] IDENTITY(1,1) NOT NULL,
	[RecetaID] [int] NOT NULL,
	[EmpleadoID] [int] NOT NULL,
	[HorasEstimadasPorLote] [decimal](18, 4) NULL,
	[Notas] [nvarchar](500) NULL,
PRIMARY KEY CLUSTERED 
(
	[RecetaEmpleadoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_RecetaEmpleado] UNIQUE NONCLUSTERED 
(
	[RecetaID] ASC,
	[EmpleadoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Produccion].[RecetaMaquinaria]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Produccion].[RecetaMaquinaria](
	[RecetaID] [int] NOT NULL,
	[MaquinariaID] [int] NOT NULL,
	[HorasEstimadasPorLote] [decimal](10, 2) NULL,
	[Notas] [nvarchar](300) NULL,
 CONSTRAINT [PK_RecetaMaquinaria] PRIMARY KEY CLUSTERED 
(
	[RecetaID] ASC,
	[MaquinariaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Produccion].[TiposMaquinaria]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Produccion].[TiposMaquinaria](
	[TipoMaquinariaID] [int] IDENTITY(1,1) NOT NULL,
	[Nombre] [nvarchar](100) NOT NULL,
	[Descripcion] [nvarchar](300) NULL,
	[Activo] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[TipoMaquinariaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_TiposMaquinaria_Nombre] UNIQUE NONCLUSTERED 
(
	[Nombre] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Produccion].[TiposProduccion]    Script Date: 1/09/2026 5:35:42 p. m. ******/
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
/****** Object:  Table [Proyectos].[Comentarios]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Proyectos].[Comentarios](
	[ComentarioID] [int] IDENTITY(1,1) NOT NULL,
	[ProyectoID] [int] NOT NULL,
	[Texto] [nvarchar](1000) NOT NULL,
	[Fecha] [datetime2](7) NOT NULL,
	[UsuarioID] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[ComentarioID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Proyectos].[Costos]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Proyectos].[Costos](
	[CostoID] [int] IDENTITY(1,1) NOT NULL,
	[ProyectoID] [int] NOT NULL,
	[Tipo] [nvarchar](20) NOT NULL,
	[Descripcion] [nvarchar](300) NOT NULL,
	[Valor] [decimal](18, 2) NOT NULL,
	[EmpleadoID] [int] NULL,
	[ArticuloID] [int] NULL,
	[Fecha] [datetime2](7) NOT NULL,
	[UsuarioID] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[CostoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Proyectos].[Hitos]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Proyectos].[Hitos](
	[HitoID] [int] IDENTITY(1,1) NOT NULL,
	[ProyectoID] [int] NOT NULL,
	[Nombre] [nvarchar](150) NOT NULL,
	[FechaObjetivo] [date] NOT NULL,
	[FechaCompletado] [date] NULL,
	[Estado] [nvarchar](20) NOT NULL,
	[Orden] [int] NOT NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[HitoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Proyectos].[ProyectoDocumentos]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Proyectos].[ProyectoDocumentos](
	[DocumentoID] [int] IDENTITY(1,1) NOT NULL,
	[ProyectoID] [int] NOT NULL,
	[TipoDocumento] [nvarchar](30) NOT NULL,
	[NombreArchivo] [nvarchar](255) NOT NULL,
	[ContentType] [nvarchar](100) NOT NULL,
	[Archivo] [varbinary](max) NOT NULL,
	[FechaSubida] [datetime2](7) NOT NULL,
	[UsuarioID] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[DocumentoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [Proyectos].[Proyectos]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Proyectos].[Proyectos](
	[ProyectoID] [int] IDENTITY(1,1) NOT NULL,
	[Nombre] [nvarchar](150) NOT NULL,
	[ClienteID] [int] NULL,
	[CentroCostoID] [int] NULL,
	[Descripcion] [nvarchar](500) NULL,
	[FechaInicio] [date] NOT NULL,
	[FechaFin] [date] NULL,
	[Estado] [nvarchar](20) NOT NULL,
	[Presupuesto] [decimal](18, 2) NOT NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
	[Prioridad] [nvarchar](10) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ProyectoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Proyectos].[TareaDependencias]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Proyectos].[TareaDependencias](
	[TareaID] [int] NOT NULL,
	[DependeDeTareaID] [int] NOT NULL,
 CONSTRAINT [PK_TareaDependencias] PRIMARY KEY CLUSTERED 
(
	[TareaID] ASC,
	[DependeDeTareaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Proyectos].[Tareas]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Proyectos].[Tareas](
	[TareaID] [int] IDENTITY(1,1) NOT NULL,
	[ProyectoID] [int] NOT NULL,
	[Titulo] [nvarchar](200) NOT NULL,
	[ResponsableID] [int] NULL,
	[Estado] [nvarchar](20) NOT NULL,
	[FechaLimite] [date] NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[TareaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Rrhh].[Ausencias]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Rrhh].[Ausencias](
	[AusenciaID] [int] IDENTITY(1,1) NOT NULL,
	[EmpleadoID] [int] NOT NULL,
	[Tipo] [nvarchar](30) NOT NULL,
	[FechaInicio] [date] NOT NULL,
	[FechaFin] [date] NOT NULL,
	[Motivo] [nvarchar](300) NULL,
	[Estado] [nvarchar](20) NOT NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
	[UsuarioID] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[AusenciaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Rrhh].[Capacitaciones]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Rrhh].[Capacitaciones](
	[CapacitacionID] [int] IDENTITY(1,1) NOT NULL,
	[EmpleadoID] [int] NOT NULL,
	[Nombre] [nvarchar](200) NOT NULL,
	[Institucion] [nvarchar](150) NULL,
	[FechaRealizacion] [date] NOT NULL,
	[FechaVencimiento] [date] NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
	[UsuarioID] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[CapacitacionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Rrhh].[Cargos]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Rrhh].[Cargos](
	[CargoID] [int] IDENTITY(1,1) NOT NULL,
	[Nombre] [nvarchar](100) NOT NULL,
	[DepartamentoID] [int] NULL,
	[Estado] [bit] NOT NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
	[RolPredeterminadoID] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[CargoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Rrhh].[Departamentos]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Rrhh].[Departamentos](
	[DepartamentoID] [int] IDENTITY(1,1) NOT NULL,
	[Nombre] [nvarchar](100) NOT NULL,
	[Estado] [bit] NOT NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[DepartamentoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Rrhh].[EmpleadoDocumentos]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Rrhh].[EmpleadoDocumentos](
	[DocumentoID] [int] IDENTITY(1,1) NOT NULL,
	[EmpleadoID] [int] NOT NULL,
	[TipoDocumento] [nvarchar](30) NOT NULL,
	[NombreArchivo] [nvarchar](255) NOT NULL,
	[ContentType] [nvarchar](100) NOT NULL,
	[Archivo] [varbinary](max) NOT NULL,
	[FechaSubida] [datetime2](7) NOT NULL,
	[UsuarioID] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[DocumentoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [Rrhh].[EmpleadoHorario]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Rrhh].[EmpleadoHorario](
	[EmpleadoID] [int] NOT NULL,
	[HorarioID] [int] NOT NULL,
	[Desde] [date] NOT NULL,
	[Hasta] [date] NULL,
 CONSTRAINT [PK_EmpleadoHorario] PRIMARY KEY CLUSTERED 
(
	[EmpleadoID] ASC,
	[Desde] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Rrhh].[Empleados]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Rrhh].[Empleados](
	[EmpleadoID] [int] IDENTITY(1,1) NOT NULL,
	[Nombres] [nvarchar](100) NOT NULL,
	[Apellidos] [nvarchar](100) NOT NULL,
	[Cargo] [nvarchar](100) NULL,
	[CentroCostoID] [int] NULL,
	[FechaIngreso] [date] NULL,
	[Telefono] [nvarchar](30) NULL,
	[Email] [nvarchar](150) NULL,
	[Estado] [bit] NOT NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
	[Foto] [varbinary](max) NULL,
	[FotoContentType] [nvarchar](50) NULL,
	[CargoID] [int] NULL,
	[JefeDirectoID] [int] NULL,
	[TarifaHora] [decimal](18, 4) NULL,
PRIMARY KEY CLUSTERED 
(
	[EmpleadoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [Rrhh].[Evaluaciones]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Rrhh].[Evaluaciones](
	[EvaluacionID] [int] IDENTITY(1,1) NOT NULL,
	[EmpleadoID] [int] NOT NULL,
	[ResponsableID] [int] NULL,
	[Fecha] [date] NOT NULL,
	[Calificacion] [decimal](3, 1) NOT NULL,
	[Comentarios] [nvarchar](1000) NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
	[UsuarioID] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[EvaluacionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Rrhh].[HistorialLaboral]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Rrhh].[HistorialLaboral](
	[HistorialID] [int] IDENTITY(1,1) NOT NULL,
	[EmpleadoID] [int] NOT NULL,
	[TipoEvento] [nvarchar](30) NOT NULL,
	[ValorAnterior] [nvarchar](200) NULL,
	[ValorNuevo] [nvarchar](200) NULL,
	[Fecha] [datetime2](7) NOT NULL,
	[Notas] [nvarchar](500) NULL,
	[UsuarioID] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[HistorialID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Rrhh].[HorarioDias]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Rrhh].[HorarioDias](
	[HorarioDiaID] [int] IDENTITY(1,1) NOT NULL,
	[HorarioID] [int] NOT NULL,
	[Semana] [char](1) NULL,
	[DiaSemana] [tinyint] NOT NULL,
	[HoraEntrada] [time](7) NOT NULL,
	[HoraSalida] [time](7) NOT NULL,
	[TieneAlmuerzo] [bit] NOT NULL,
	[HoraInicioAlmuerzo] [time](7) NULL,
	[HoraFinAlmuerzo] [time](7) NULL,
PRIMARY KEY CLUSTERED 
(
	[HorarioDiaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_HorarioDias_Dia] UNIQUE NONCLUSTERED 
(
	[HorarioID] ASC,
	[Semana] ASC,
	[DiaSemana] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Rrhh].[Horarios]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Rrhh].[Horarios](
	[HorarioID] [int] IDENTITY(1,1) NOT NULL,
	[Nombre] [nvarchar](100) NOT NULL,
	[HoraEntrada] [time](7) NULL,
	[HoraSalida] [time](7) NULL,
	[ToleranciaTardanzaMin] [int] NOT NULL,
	[LunesActivo] [bit] NULL,
	[MartesActivo] [bit] NULL,
	[MiercolesActivo] [bit] NULL,
	[JuevesActivo] [bit] NULL,
	[ViernesActivo] [bit] NULL,
	[SabadoActivo] [bit] NULL,
	[DomingoActivo] [bit] NULL,
	[Activo] [bit] NOT NULL,
	[TipoCiclo] [nvarchar](10) NOT NULL,
	[RegistraSalida] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[HorarioID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Rrhh].[QrAsistenciaConfig]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Rrhh].[QrAsistenciaConfig](
	[ConfigID] [int] IDENTITY(1,1) NOT NULL,
	[Secreto] [nvarchar](64) NOT NULL,
	[ModoQr] [nvarchar](20) NOT NULL,
	[TokenActual] [nvarchar](64) NULL,
PRIMARY KEY CLUSTERED 
(
	[ConfigID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Rrhh].[RegistroAsistencia]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Rrhh].[RegistroAsistencia](
	[RegistroID] [int] IDENTITY(1,1) NOT NULL,
	[EmpleadoID] [int] NOT NULL,
	[Fecha] [date] NOT NULL,
	[HoraEntrada] [datetime2](7) NULL,
	[MetodoEntrada] [nvarchar](10) NULL,
	[EntradaRegistradaPor] [int] NULL,
	[EntradaNota] [nvarchar](500) NULL,
	[HoraSalida] [datetime2](7) NULL,
	[MetodoSalida] [nvarchar](10) NULL,
	[SalidaRegistradaPor] [int] NULL,
	[SalidaNota] [nvarchar](500) NULL,
	[MinutosTardanza] [int] NULL,
	[HoraEntrada2] [datetime] NULL,
	[MetodoEntrada2] [nvarchar](20) NULL,
	[Entrada2RegistradaPor] [int] NULL,
	[Entrada2Nota] [nvarchar](200) NULL,
	[HoraSalida2] [datetime] NULL,
	[MetodoSalida2] [nvarchar](20) NULL,
	[Salida2RegistradaPor] [int] NULL,
	[Salida2Nota] [nvarchar](200) NULL,
PRIMARY KEY CLUSTERED 
(
	[RegistroID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_Asistencia] UNIQUE NONCLUSTERED 
(
	[EmpleadoID] ASC,
	[Fecha] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Seguridad].[Modulos]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Seguridad].[Modulos](
	[ModuloID] [int] IDENTITY(1,1) NOT NULL,
	[Codigo] [nvarchar](60) NOT NULL,
	[Nombre] [nvarchar](100) NOT NULL,
	[Ruta] [nvarchar](200) NULL,
	[ModuloPadreID] [int] NULL,
	[Icono] [nvarchar](100) NULL,
	[Orden] [int] NOT NULL,
	[EsGrupo] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ModuloID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_Modulos_Codigo] UNIQUE NONCLUSTERED 
(
	[Codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Seguridad].[PermisoModuloRol]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Seguridad].[PermisoModuloRol](
	[RolID] [int] NOT NULL,
	[ModuloID] [int] NOT NULL,
	[Visible] [bit] NOT NULL,
 CONSTRAINT [PK_PermisoModuloRol] PRIMARY KEY CLUSTERED 
(
	[RolID] ASC,
	[ModuloID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Seguridad].[PermisoModuloUsuario]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Seguridad].[PermisoModuloUsuario](
	[UsuarioID] [int] NOT NULL,
	[ModuloID] [int] NOT NULL,
	[Visible] [bit] NOT NULL,
 CONSTRAINT [PK_PermisoModuloUsuario] PRIMARY KEY CLUSTERED 
(
	[UsuarioID] ASC,
	[ModuloID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Seguridad].[Permisos]    Script Date: 1/09/2026 5:35:42 p. m. ******/
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
/****** Object:  Table [Seguridad].[PreferenciasUsuario]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Seguridad].[PreferenciasUsuario](
	[UsuarioID] [int] NOT NULL,
	[Clave] [nvarchar](50) NOT NULL,
	[Valor] [nvarchar](max) NOT NULL,
	[FechaModificacion] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_PreferenciasUsuario] PRIMARY KEY CLUSTERED 
(
	[UsuarioID] ASC,
	[Clave] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [Seguridad].[Roles]    Script Date: 1/09/2026 5:35:42 p. m. ******/
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
/****** Object:  Table [Seguridad].[RolPermisos]    Script Date: 1/09/2026 5:35:42 p. m. ******/
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
/****** Object:  Table [Seguridad].[SesionesUsuario]    Script Date: 1/09/2026 5:35:42 p. m. ******/
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
/****** Object:  Table [Seguridad].[Usuarios]    Script Date: 1/09/2026 5:35:42 p. m. ******/
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
	[FotoPerfil] [varbinary](max) NULL,
	[FotoPerfilContentType] [nvarchar](50) NULL,
	[EmpleadoID] [int] NULL,
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
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [Soporte].[EncuestasNPS]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Soporte].[EncuestasNPS](
	[EncuestaNPSID] [int] IDENTITY(1,1) NOT NULL,
	[TicketID] [int] NOT NULL,
	[Puntuacion] [tinyint] NOT NULL,
	[Comentario] [nvarchar](500) NULL,
	[FechaRespuesta] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[EncuestaNPSID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Soporte].[TicketComentarios]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Soporte].[TicketComentarios](
	[ComentarioID] [int] IDENTITY(1,1) NOT NULL,
	[TicketID] [int] NOT NULL,
	[AutorID] [int] NOT NULL,
	[Texto] [nvarchar](max) NOT NULL,
	[EsInterno] [bit] NOT NULL,
	[Fecha] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ComentarioID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [Soporte].[Tickets]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Soporte].[Tickets](
	[TicketID] [int] IDENTITY(1,1) NOT NULL,
	[Titulo] [nvarchar](300) NOT NULL,
	[Descripcion] [nvarchar](max) NOT NULL,
	[Categoria] [nvarchar](100) NOT NULL,
	[Prioridad] [nvarchar](20) NOT NULL,
	[Estado] [nvarchar](30) NOT NULL,
	[ReportadoPor] [int] NOT NULL,
	[AsignadoA] [int] NULL,
	[ClienteID] [int] NULL,
	[FechaCreacion] [datetime2](7) NOT NULL,
	[FechaActualizacion] [datetime2](7) NOT NULL,
	[FechaResolucion] [datetime2](7) NULL,
	[Notas] [nvarchar](1000) NULL,
PRIMARY KEY CLUSTERED 
(
	[TicketID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Index [IX_HistorialPrecios_ArticuloFecha]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_HistorialPrecios_ArticuloFecha] ON [Auditoria].[HistorialPrecios]
(
	[ArticuloID] ASC,
	[FechaCambio] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Log_Tabla_Registro]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_Log_Tabla_Registro] ON [Auditoria].[LogAuditoria]
(
	[EsquemaTabla] ASC,
	[RegistroID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Articulos_Tipo]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_Articulos_Tipo] ON [catalogo].[Tarjetas]
(
	[TipoArticuloID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Tarjetas_Estado_Nombre]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_Tarjetas_Estado_Nombre] ON [catalogo].[Tarjetas]
(
	[Estado] ASC,
	[Nombre] ASC
)
INCLUDE([ArticuloID],[Referencia],[TipoArticuloID],[PresentacionCodigo],[MarcaCodigo],[GrupoMenorCodigo]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_OrdenesCompra_Estado_Fecha]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_OrdenesCompra_Estado_Fecha] ON [Compras].[OrdenesCompra]
(
	[EstadoOC] ASC,
	[FechaEmision] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Articulos_Categoria]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_Articulos_Categoria] ON [Conocimiento].[Articulos]
(
	[Categoria] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Actividades_Cliente]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_Actividades_Cliente] ON [Crm].[Actividades]
(
	[ClienteID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Actividades_Oportunidad]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_Actividades_Oportunidad] ON [Crm].[Actividades]
(
	[OportunidadID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Actividades_Responsable]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_Actividades_Responsable] ON [Crm].[Actividades]
(
	[ResponsableID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Actividades_Vencimiento]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_Actividades_Vencimiento] ON [Crm].[Actividades]
(
	[Completada] ASC,
	[FechaVencimiento] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Clientes_Departamento]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_Clientes_Departamento] ON [Crm].[Clientes]
(
	[Departamento] ASC
)
INCLUDE([ClienteID],[Nombre],[NIT]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Clientes_FechaCreacion]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_Clientes_FechaCreacion] ON [Crm].[Clientes]
(
	[FechaCreacion] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UQ_Clientes_ClienteGuid]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Clientes_ClienteGuid] ON [Crm].[Clientes]
(
	[ClienteGuid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ_Clientes_ExternalId]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Clientes_ExternalId] ON [Crm].[Clientes]
(
	[ExternalId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ_Clientes_NIT]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Clientes_NIT] ON [Crm].[Clientes]
(
	[NIT] ASC
)
WHERE ([NIT] IS NOT NULL AND [NIT]<>'')
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Cotizaciones_ClienteID_Fecha]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_Cotizaciones_ClienteID_Fecha] ON [Crm].[Cotizaciones]
(
	[ClienteID] ASC,
	[Fecha] DESC
)
INCLUDE([Estado],[ValidoHasta],[CentroCostoID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Cotizaciones_Estado_ValidoHasta]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_Cotizaciones_Estado_ValidoHasta] ON [Crm].[Cotizaciones]
(
	[Estado] ASC,
	[ValidoHasta] ASC
)
INCLUDE([ClienteID],[CentroCostoID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_CotizacionLineas_CotizacionID]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_CotizacionLineas_CotizacionID] ON [Crm].[CotizacionLineas]
(
	[CotizacionID] ASC
)
INCLUDE([ArticuloID],[Cantidad],[PrecioUnitario]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Ejecuciones_Dedup]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_Ejecuciones_Dedup] ON [Crm].[EjecucionesAutomatizacion]
(
	[ReglaID] ASC,
	[EntidadTipo] ASC,
	[EntidadID] ASC,
	[FechaEjecucion] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Interacciones_ClienteID_Fecha]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_Interacciones_ClienteID_Fecha] ON [Crm].[Interacciones]
(
	[ClienteID] ASC,
	[Fecha] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Interacciones_Fecha]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_Interacciones_Fecha] ON [Crm].[Interacciones]
(
	[Fecha] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_FacturaLineas_ArticuloID]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_FacturaLineas_ArticuloID] ON [Facturacion].[FacturaLineas]
(
	[ArticuloID] ASC
)
INCLUDE([FacturaID],[Cantidad],[PrecioUnitario]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_FacturaLineas_FacturaID]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_FacturaLineas_FacturaID] ON [Facturacion].[FacturaLineas]
(
	[FacturaID] ASC
)
INCLUDE([ArticuloID],[Cantidad],[PrecioUnitario]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Facturas_CentroCosto_Fecha]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_Facturas_CentroCosto_Fecha] ON [Facturacion].[Facturas]
(
	[CentroCostoID] ASC,
	[Fecha] DESC
)
INCLUDE([ClienteID],[TipDoc],[StockDescontado]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Facturas_ClienteID_Fecha]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_Facturas_ClienteID_Fecha] ON [Facturacion].[Facturas]
(
	[ClienteID] ASC,
	[Fecha] DESC
)
INCLUDE([CentroCostoID],[TipDoc],[NroDoc],[StockDescontado]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Facturas_TipDoc_Fecha]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_Facturas_TipDoc_Fecha] ON [Facturacion].[Facturas]
(
	[TipDoc] ASC,
	[Fecha] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Pagos_FacturaID]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_Pagos_FacturaID] ON [Facturacion].[Pagos]
(
	[FacturaID] ASC
)
INCLUDE([Monto]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_GastosOp_Fecha_Cat]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_GastosOp_Fecha_Cat] ON [Finanzas].[GastosOperativos]
(
	[Fecha] DESC,
	[Categoria] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Respuestas_FormularioID]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_Respuestas_FormularioID] ON [Formularios].[Respuestas]
(
	[FormularioID] ASC,
	[FechaRespuesta] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_AgentesSync_CentroCosto]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_AgentesSync_CentroCosto] ON [Integracion].[AgentesSync]
(
	[CentroCostoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_EventosEntrantes_Articulo_CC]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_EventosEntrantes_Articulo_CC] ON [Integracion].[EventosEntrantes]
(
	[CodigoArticuloVisions] ASC,
	[CentroCostoID] ASC
)
INCLUDE([Cantidad],[TipoEvento],[Procesado]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_EventosEntrantes_Pendientes]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_EventosEntrantes_Pendientes] ON [Integracion].[EventosEntrantes]
(
	[Procesado] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_EventosEntrantes_VentasVisions]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_EventosEntrantes_VentasVisions] ON [Integracion].[EventosEntrantes]
(
	[CentroCostoID] ASC,
	[TipoEvento] ASC,
	[FechaEventoOrigen] ASC
)
INCLUDE([TipDoc],[NroDoc],[NitCliente],[NombreCliente],[CodigoArticuloVisions],[Cantidad],[PrecioArticuloVisions]) 
WHERE ([TipDoc] IS NOT NULL)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_EventosSalientes_Pendientes]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_EventosSalientes_Pendientes] ON [Integracion].[EventosSalientes]
(
	[Estado] ASC,
	[CentroCostoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Stock_ArticuloBodega]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_Stock_ArticuloBodega] ON [Inventario].[InventarioStock]
(
	[ArticuloID] ASC,
	[BodegaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Lotes_Vencimiento]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_Lotes_Vencimiento] ON [Inventario].[Lotes]
(
	[ArticuloID] ASC,
	[FechaVencimiento] ASC
)
INCLUDE([Estado]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Kardex_Articulo_Bodega_Fecha]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_Kardex_Articulo_Bodega_Fecha] ON [Kardex].[KardexMovimientos]
(
	[ArticuloID] ASC,
	[BodegaID] ASC,
	[Fecha] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Kardex_CentroCosto_Fecha]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_Kardex_CentroCosto_Fecha] ON [Kardex].[KardexMovimientos]
(
	[CentroCostoID] ASC,
	[Fecha] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Kardex_OP]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_Kardex_OP] ON [Kardex].[KardexMovimientos]
(
	[OrdenProduccionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_ComboItems_Combo]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_ComboItems_Combo] ON [Marketing].[ComboItems]
(
	[ComboID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_EnviosDetalle_Campana]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_EnviosDetalle_Campana] ON [Marketing].[EnviosDetalle]
(
	[CampanaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_EnviosDetalle_Cliente]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_EnviosDetalle_Cliente] ON [Marketing].[EnviosDetalle]
(
	[ClienteID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UX_EnviosDetalle_Token]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_EnviosDetalle_Token] ON [Marketing].[EnviosDetalle]
(
	[Token] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Mant_Maquinaria]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_Mant_Maquinaria] ON [Produccion].[MantenimientoMaquinaria]
(
	[MaquinariaID] ASC,
	[FechaRealizado] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_OP_CentroCosto]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_OP_CentroCosto] ON [Produccion].[OrdenesProduccion]
(
	[CentroCostoDestinoID] ASC,
	[EstadoOPID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_OP_Fechas]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_OP_Fechas] ON [Produccion].[OrdenesProduccion]
(
	[FechaInicio] ASC,
	[FechaFin] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_OrdenMaquinaria_Maquinaria]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_OrdenMaquinaria_Maquinaria] ON [Produccion].[OrdenMaquinaria]
(
	[MaquinariaID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_RecetaDetalle_Insumo]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_RecetaDetalle_Insumo] ON [Produccion].[RecetaBOM_Detalle]
(
	[InsumoID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Sesiones_Usuario]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_Sesiones_Usuario] ON [Seguridad].[SesionesUsuario]
(
	[UsuarioID] ASC,
	[Activa] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UX_EncuestasNPS_Ticket]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE UNIQUE NONCLUSTERED INDEX [UX_EncuestasNPS_Ticket] ON [Soporte].[EncuestasNPS]
(
	[TicketID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Tickets_Estado]    Script Date: 1/09/2026 5:35:42 p. m. ******/
CREATE NONCLUSTERED INDEX [IX_Tickets_Estado] ON [Soporte].[Tickets]
(
	[Estado] ASC,
	[FechaCreacion] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [Auditoria].[HistorialPrecios] ADD  CONSTRAINT [DF_HistorialPrecios_Fecha]  DEFAULT (getdate()) FOR [FechaCambio]
GO
ALTER TABLE [Auditoria].[LogAuditoria] ADD  DEFAULT (sysutcdatetime()) FOR [Fecha]
GO
ALTER TABLE [Calendario].[EventoAsistentes] ADD  DEFAULT ('Pendiente') FOR [Estado]
GO
ALTER TABLE [Calendario].[Eventos] ADD  DEFAULT (getutcdate()) FOR [FechaCreacion]
GO
ALTER TABLE [Calendario].[Eventos] ADD  DEFAULT ((1)) FOR [Activo]
GO
ALTER TABLE [catalogo].[Proveedores] ADD  DEFAULT ((1)) FOR [Estado]
GO
ALTER TABLE [catalogo].[Tarjetas] ADD  DEFAULT ((0)) FOR [CostoPromedio]
GO
ALTER TABLE [catalogo].[Tarjetas] ADD  DEFAULT ((0)) FOR [StockMinimo]
GO
ALTER TABLE [catalogo].[Tarjetas] ADD  DEFAULT ((0)) FOR [PuntoReorden]
GO
ALTER TABLE [catalogo].[Tarjetas] ADD  DEFAULT ((1)) FOR [Estado]
GO
ALTER TABLE [catalogo].[Tarjetas] ADD  DEFAULT (sysutcdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Compras].[OrdenesCompra] ADD  DEFAULT ('PENDIENTE') FOR [EstadoOC]
GO
ALTER TABLE [Compras].[OrdenesCompra] ADD  DEFAULT (sysutcdatetime()) FOR [FechaEmision]
GO
ALTER TABLE [Compras].[OrdenesCompra] ADD  DEFAULT ((0)) FOR [ExportadoVisions]
GO
ALTER TABLE [Compras].[OrdenesCompra] ADD  DEFAULT ('COMPRA') FOR [TipoMovimiento]
GO
ALTER TABLE [Compras].[OrdenesCompraDetalle] ADD  DEFAULT ((0)) FOR [CantidadRecibida]
GO
ALTER TABLE [Conocimiento].[Articulos] ADD  DEFAULT ('General') FOR [Categoria]
GO
ALTER TABLE [Conocimiento].[Articulos] ADD  DEFAULT (getdate()) FOR [FechaCreacion]
GO
ALTER TABLE [Conocimiento].[Articulos] ADD  DEFAULT (getdate()) FOR [FechaActualizacion]
GO
ALTER TABLE [Conocimiento].[Articulos] ADD  DEFAULT ((1)) FOR [Activo]
GO
ALTER TABLE [Conocimiento].[Articulos] ADD  DEFAULT ((0)) FOR [Vistas]
GO
ALTER TABLE [Crm].[Actividades] ADD  DEFAULT ((0)) FOR [Completada]
GO
ALTER TABLE [Crm].[Actividades] ADD  DEFAULT (sysutcdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Crm].[ClienteDocumentos] ADD  CONSTRAINT [DF_ClienteDocumentos_FechaSubida]  DEFAULT (sysutcdatetime()) FOR [FechaSubida]
GO
ALTER TABLE [Crm].[Clientes] ADD  DEFAULT ((1)) FOR [Estado]
GO
ALTER TABLE [Crm].[Clientes] ADD  CONSTRAINT [DF_Clientes_FechaCreacion]  DEFAULT (sysutcdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Crm].[Clientes] ADD  DEFAULT (newid()) FOR [ClienteGuid]
GO
ALTER TABLE [Crm].[Clientes] ADD  CONSTRAINT [DF_Clientes_ExternalId]  DEFAULT (lower(left(replace(CONVERT([nvarchar](36),newid()),'-',''),(12)))) FOR [ExternalId]
GO
ALTER TABLE [Crm].[Contactos] ADD  CONSTRAINT [DF_Contactos_EsPrincipal]  DEFAULT ((0)) FOR [EsPrincipal]
GO
ALTER TABLE [Crm].[Contactos] ADD  CONSTRAINT [DF_Contactos_Estado]  DEFAULT ((1)) FOR [Estado]
GO
ALTER TABLE [Crm].[Contactos] ADD  CONSTRAINT [DF_Contactos_FechaCreacion]  DEFAULT (sysutcdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Crm].[Cotizaciones] ADD  DEFAULT ('BORRADOR') FOR [Estado]
GO
ALTER TABLE [Crm].[Cotizaciones] ADD  DEFAULT (sysdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Crm].[EjecucionesAutomatizacion] ADD  DEFAULT (sysutcdatetime()) FOR [FechaEjecucion]
GO
ALTER TABLE [Crm].[Interacciones] ADD  CONSTRAINT [DF_Interacciones_Fecha]  DEFAULT (sysutcdatetime()) FOR [Fecha]
GO
ALTER TABLE [Crm].[Leads] ADD  CONSTRAINT [DF_Leads_Etapa]  DEFAULT ('NUEVO') FOR [Etapa]
GO
ALTER TABLE [Crm].[Leads] ADD  CONSTRAINT [DF_Leads_FechaCreacion]  DEFAULT (sysutcdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Crm].[LineasCredito] ADD  DEFAULT ((0)) FOR [CupoCredito]
GO
ALTER TABLE [Crm].[LineasCredito] ADD  DEFAULT (getdate()) FOR [FechaCreacion]
GO
ALTER TABLE [Crm].[LineasCredito] ADD  DEFAULT (getdate()) FOR [FechaActualiza]
GO
ALTER TABLE [Crm].[Oportunidades] ADD  DEFAULT ((0)) FOR [ValorEstimado]
GO
ALTER TABLE [Crm].[Oportunidades] ADD  DEFAULT ('PROSPECCION') FOR [Etapa]
GO
ALTER TABLE [Crm].[Oportunidades] ADD  DEFAULT (sysdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Crm].[Oportunidades] ADD  DEFAULT ('NEUTRO') FOR [ConfianzaCierre]
GO
ALTER TABLE [Crm].[ReglasAutomatizacion] ADD  DEFAULT ('{}') FOR [ParametrosJSON]
GO
ALTER TABLE [Crm].[ReglasAutomatizacion] ADD  DEFAULT ((1)) FOR [Activa]
GO
ALTER TABLE [Crm].[ReglasAutomatizacion] ADD  DEFAULT (sysutcdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Facturacion].[Devoluciones] ADD  DEFAULT (CONVERT([date],getdate())) FOR [Fecha]
GO
ALTER TABLE [Facturacion].[Devoluciones] ADD  DEFAULT ((0)) FOR [Total]
GO
ALTER TABLE [Facturacion].[Devoluciones] ADD  DEFAULT ((0)) FOR [StockRestituido]
GO
ALTER TABLE [Facturacion].[Devoluciones] ADD  DEFAULT ((0)) FOR [OrigenVisions]
GO
ALTER TABLE [Facturacion].[Devoluciones] ADD  DEFAULT (sysutcdatetime()) FOR [FechaRegistro]
GO
ALTER TABLE [Facturacion].[DevolucionLineas] ADD  DEFAULT ((0)) FOR [CostoUnitario]
GO
ALTER TABLE [Facturacion].[Facturas] ADD  DEFAULT (sysdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Facturacion].[Facturas] ADD  DEFAULT ((0)) FOR [StockDescontado]
GO
ALTER TABLE [Facturacion].[Facturas] ADD  DEFAULT ((0)) FOR [ProduccionAutoEjecutada]
GO
ALTER TABLE [Facturacion].[Facturas] ADD  CONSTRAINT [DF_Facturas_TipDoc]  DEFAULT ('FACTURA') FOR [TipDoc]
GO
ALTER TABLE [Facturacion].[Facturas] ADD  CONSTRAINT [DF_Facturas_VisionsConf]  DEFAULT ((0)) FOR [VisionsConfirmado]
GO
ALTER TABLE [Facturacion].[FacturasExportadasVisions] ADD  DEFAULT (sysutcdatetime()) FOR [FechaExportado]
GO
ALTER TABLE [Facturacion].[Pagos] ADD  DEFAULT (sysdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Facturacion].[Pagos] ADD  DEFAULT ('EFECTIVO') FOR [MetodoPago]
GO
ALTER TABLE [Finanzas].[GastosOperativos] ADD  DEFAULT (getutcdate()) FOR [FechaCreacion]
GO
ALTER TABLE [Formularios].[Campos] ADD  DEFAULT ((0)) FOR [Requerido]
GO
ALTER TABLE [Formularios].[Campos] ADD  DEFAULT ((0)) FOR [Orden]
GO
ALTER TABLE [Formularios].[Formularios] ADD  DEFAULT ((1)) FOR [Activo]
GO
ALTER TABLE [Formularios].[Formularios] ADD  DEFAULT ((1)) FOR [AceptaRespuestas]
GO
ALTER TABLE [Formularios].[Formularios] ADD  DEFAULT (getutcdate()) FOR [FechaCreacion]
GO
ALTER TABLE [Formularios].[Formularios] ADD  DEFAULT (getutcdate()) FOR [FechaActualizacion]
GO
ALTER TABLE [Formularios].[Respuestas] ADD  DEFAULT (getutcdate()) FOR [FechaRespuesta]
GO
ALTER TABLE [Integracion].[AgentesSync] ADD  DEFAULT ((1)) FOR [Activo]
GO
ALTER TABLE [Integracion].[AgentesSync] ADD  DEFAULT (sysutcdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Integracion].[AgentesSync] ADD  DEFAULT ((5)) FOR [IntervalMinutes]
GO
ALTER TABLE [Integracion].[AgentesSync] ADD  DEFAULT ((0)) FOR [IntervalSeconds]
GO
ALTER TABLE [Integracion].[ArticulosPendientesMapeo] ADD  CONSTRAINT [DF_ArticulosPendientesMapeo_FechaDetectado]  DEFAULT (sysutcdatetime()) FOR [FechaDetectado]
GO
ALTER TABLE [Integracion].[ArticulosPendientesMapeo] ADD  CONSTRAINT [DF_ArticulosPendientesMapeo_Resuelto]  DEFAULT ((0)) FOR [Resuelto]
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
ALTER TABLE [Integracion].[PendientesLimpiezaVisions] ADD  DEFAULT (getdate()) FOR [FechaRegistro]
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
ALTER TABLE [Logistica].[Despachos] ADD  CONSTRAINT [DF_Despachos_Estado]  DEFAULT ('DESPACHADO') FOR [Estado]
GO
ALTER TABLE [Logistica].[Despachos] ADD  CONSTRAINT [DF_Despachos_FechaDespacho]  DEFAULT (sysutcdatetime()) FOR [FechaDespacho]
GO
ALTER TABLE [Logistica].[Despachos] ADD  DEFAULT ((1)) FOR [DescuentaStock]
GO
ALTER TABLE [Marketing].[Campanas] ADD  DEFAULT ('') FOR [Asunto]
GO
ALTER TABLE [Marketing].[Campanas] ADD  DEFAULT ('[]') FOR [BloqueJSON]
GO
ALTER TABLE [Marketing].[Campanas] ADD  DEFAULT ('BORRADOR') FOR [Estado]
GO
ALTER TABLE [Marketing].[Campanas] ADD  DEFAULT ((0)) FOR [TotalDestinatarios]
GO
ALTER TABLE [Marketing].[Campanas] ADD  DEFAULT ((0)) FOR [TotalEnviados]
GO
ALTER TABLE [Marketing].[Campanas] ADD  DEFAULT ((0)) FOR [TotalAbiertos]
GO
ALTER TABLE [Marketing].[Campanas] ADD  DEFAULT ((0)) FOR [TotalClicks]
GO
ALTER TABLE [Marketing].[Campanas] ADD  DEFAULT ((0)) FOR [TotalDesuscriptos]
GO
ALTER TABLE [Marketing].[Campanas] ADD  DEFAULT (sysutcdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Marketing].[Combos] ADD  DEFAULT ('Borrador') FOR [Estado]
GO
ALTER TABLE [Marketing].[Combos] ADD  DEFAULT ('MANUAL') FOR [ModoPrecio]
GO
ALTER TABLE [Marketing].[Combos] ADD  DEFAULT ((0)) FOR [PorcentajeDescuento]
GO
ALTER TABLE [Marketing].[Combos] ADD  DEFAULT (getdate()) FOR [FechaCreacion]
GO
ALTER TABLE [Marketing].[EnviosDetalle] ADD  DEFAULT ((0)) FOR [Enviado]
GO
ALTER TABLE [Marketing].[EnviosDetalle] ADD  DEFAULT ((0)) FOR [Abierto]
GO
ALTER TABLE [Marketing].[EnviosDetalle] ADD  DEFAULT ((0)) FOR [Clicks]
GO
ALTER TABLE [Marketing].[EnviosDetalle] ADD  DEFAULT ((0)) FOR [Desuscripto]
GO
ALTER TABLE [Marketing].[Imagenes] ADD  DEFAULT (sysutcdatetime()) FOR [FechaSubida]
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
ALTER TABLE [Organizacion].[ConfiguracionEmail] ADD  DEFAULT ('Resend') FOR [Proveedor]
GO
ALTER TABLE [Organizacion].[ConfiguracionEmail] ADD  DEFAULT ((0)) FOR [Activo]
GO
ALTER TABLE [Organizacion].[ConfiguracionEmail] ADD  DEFAULT (sysutcdatetime()) FOR [FechaModificacion]
GO
ALTER TABLE [Organizacion].[ConfiguracionEmail] ADD  DEFAULT ((0)) FOR [EmailsHoy]
GO
ALTER TABLE [Organizacion].[ConfiguracionEmpresa] ADD  DEFAULT ((1)) FOR [UsaVisions]
GO
ALTER TABLE [Organizacion].[ConfiguracionEmpresa] ADD  DEFAULT ((0)) FOR [ManejarVencimientos]
GO
ALTER TABLE [Organizacion].[ConfiguracionEmpresa] ADD  DEFAULT ((7)) FOR [DiasAlertaVencimiento]
GO
ALTER TABLE [Organizacion].[ConfiguracionEmpresa] ADD  DEFAULT ('FIFO') FOR [ModoLotes]
GO
ALTER TABLE [Organizacion].[ConfiguracionEmpresa] ADD  DEFAULT ('Manual') FOR [ModoNroDoc]
GO
ALTER TABLE [Organizacion].[ConfiguracionEmpresa] ADD  DEFAULT ((0)) FOR [UltimoNroDocSecuencial]
GO
ALTER TABLE [Organizacion].[ConfiguracionWhatsApp] ADD  DEFAULT ((1)) FOR [ConfiguracionID]
GO
ALTER TABLE [Organizacion].[ConfiguracionWhatsApp] ADD  DEFAULT (N'whatsapp:+14155238886') FOR [FromNumber]
GO
ALTER TABLE [Organizacion].[ConfiguracionWhatsApp] ADD  DEFAULT ((0)) FOR [Activo]
GO
ALTER TABLE [Organizacion].[ConfiguracionWhatsApp] ADD  DEFAULT (sysutcdatetime()) FOR [FechaModificacion]
GO
ALTER TABLE [Planificacion].[DemandaProyectada] ADD  CONSTRAINT [DF_DemandaProyectada_FechaCreacion]  DEFAULT (sysutcdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Planificacion].[MetasVenta] ADD  CONSTRAINT [DF_MetasVenta_FechaCreacion]  DEFAULT (sysutcdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Planificacion].[MetasVentaHistorial] ADD  DEFAULT (sysdatetime()) FOR [FechaCambio]
GO
ALTER TABLE [Produccion].[MantenimientoMaquinaria] ADD  DEFAULT (getdate()) FOR [FechaRegistro]
GO
ALTER TABLE [Produccion].[Maquinaria] ADD  DEFAULT ('Activa') FOR [Estado]
GO
ALTER TABLE [Produccion].[Maquinaria] ADD  DEFAULT (getdate()) FOR [FechaCreacion]
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
ALTER TABLE [Produccion].[TiposMaquinaria] ADD  DEFAULT ((1)) FOR [Activo]
GO
ALTER TABLE [Proyectos].[Comentarios] ADD  DEFAULT (sysdatetime()) FOR [Fecha]
GO
ALTER TABLE [Proyectos].[Costos] ADD  CONSTRAINT [DF_Costos_Fecha]  DEFAULT (sysutcdatetime()) FOR [Fecha]
GO
ALTER TABLE [Proyectos].[Hitos] ADD  DEFAULT ('PENDIENTE') FOR [Estado]
GO
ALTER TABLE [Proyectos].[Hitos] ADD  DEFAULT ((0)) FOR [Orden]
GO
ALTER TABLE [Proyectos].[Hitos] ADD  DEFAULT (sysdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Proyectos].[ProyectoDocumentos] ADD  DEFAULT (sysdatetime()) FOR [FechaSubida]
GO
ALTER TABLE [Proyectos].[Proyectos] ADD  CONSTRAINT [DF_Proyectos_Estado]  DEFAULT ('PLANEADO') FOR [Estado]
GO
ALTER TABLE [Proyectos].[Proyectos] ADD  CONSTRAINT [DF_Proyectos_Presupuesto]  DEFAULT ((0)) FOR [Presupuesto]
GO
ALTER TABLE [Proyectos].[Proyectos] ADD  CONSTRAINT [DF_Proyectos_FechaCreacion]  DEFAULT (sysutcdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Proyectos].[Proyectos] ADD  DEFAULT ('MEDIA') FOR [Prioridad]
GO
ALTER TABLE [Proyectos].[Tareas] ADD  CONSTRAINT [DF_Tareas_Estado]  DEFAULT ('PENDIENTE') FOR [Estado]
GO
ALTER TABLE [Proyectos].[Tareas] ADD  CONSTRAINT [DF_Tareas_FechaCreacion]  DEFAULT (sysutcdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Rrhh].[Ausencias] ADD  DEFAULT ('PENDIENTE') FOR [Estado]
GO
ALTER TABLE [Rrhh].[Ausencias] ADD  DEFAULT (sysdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Rrhh].[Capacitaciones] ADD  DEFAULT (sysdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Rrhh].[Cargos] ADD  DEFAULT ((1)) FOR [Estado]
GO
ALTER TABLE [Rrhh].[Cargos] ADD  DEFAULT (sysdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Rrhh].[Departamentos] ADD  DEFAULT ((1)) FOR [Estado]
GO
ALTER TABLE [Rrhh].[Departamentos] ADD  DEFAULT (sysdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Rrhh].[EmpleadoDocumentos] ADD  DEFAULT (sysdatetime()) FOR [FechaSubida]
GO
ALTER TABLE [Rrhh].[Empleados] ADD  CONSTRAINT [DF_Empleados_Estado]  DEFAULT ((1)) FOR [Estado]
GO
ALTER TABLE [Rrhh].[Empleados] ADD  CONSTRAINT [DF_Empleados_FechaCreacion]  DEFAULT (sysutcdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Rrhh].[Evaluaciones] ADD  DEFAULT (sysdatetime()) FOR [FechaCreacion]
GO
ALTER TABLE [Rrhh].[HistorialLaboral] ADD  DEFAULT (sysdatetime()) FOR [Fecha]
GO
ALTER TABLE [Rrhh].[HorarioDias] ADD  DEFAULT ((0)) FOR [TieneAlmuerzo]
GO
ALTER TABLE [Rrhh].[Horarios] ADD  DEFAULT ((5)) FOR [ToleranciaTardanzaMin]
GO
ALTER TABLE [Rrhh].[Horarios] ADD  DEFAULT ((1)) FOR [LunesActivo]
GO
ALTER TABLE [Rrhh].[Horarios] ADD  DEFAULT ((1)) FOR [MartesActivo]
GO
ALTER TABLE [Rrhh].[Horarios] ADD  DEFAULT ((1)) FOR [MiercolesActivo]
GO
ALTER TABLE [Rrhh].[Horarios] ADD  DEFAULT ((1)) FOR [JuevesActivo]
GO
ALTER TABLE [Rrhh].[Horarios] ADD  DEFAULT ((1)) FOR [ViernesActivo]
GO
ALTER TABLE [Rrhh].[Horarios] ADD  DEFAULT ((0)) FOR [SabadoActivo]
GO
ALTER TABLE [Rrhh].[Horarios] ADD  DEFAULT ((0)) FOR [DomingoActivo]
GO
ALTER TABLE [Rrhh].[Horarios] ADD  DEFAULT ((1)) FOR [Activo]
GO
ALTER TABLE [Rrhh].[Horarios] ADD  DEFAULT ('FIJO') FOR [TipoCiclo]
GO
ALTER TABLE [Rrhh].[Horarios] ADD  DEFAULT ((1)) FOR [RegistraSalida]
GO
ALTER TABLE [Rrhh].[QrAsistenciaConfig] ADD  DEFAULT (CONVERT([nvarchar](64),newid())) FOR [Secreto]
GO
ALTER TABLE [Rrhh].[QrAsistenciaConfig] ADD  DEFAULT ('TTL') FOR [ModoQr]
GO
ALTER TABLE [Seguridad].[Modulos] ADD  DEFAULT ((0)) FOR [Orden]
GO
ALTER TABLE [Seguridad].[Modulos] ADD  DEFAULT ((0)) FOR [EsGrupo]
GO
ALTER TABLE [Seguridad].[PermisoModuloRol] ADD  DEFAULT ((1)) FOR [Visible]
GO
ALTER TABLE [Seguridad].[PreferenciasUsuario] ADD  DEFAULT (sysdatetime()) FOR [FechaModificacion]
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
ALTER TABLE [Soporte].[EncuestasNPS] ADD  DEFAULT (getdate()) FOR [FechaRespuesta]
GO
ALTER TABLE [Soporte].[TicketComentarios] ADD  DEFAULT ((0)) FOR [EsInterno]
GO
ALTER TABLE [Soporte].[TicketComentarios] ADD  DEFAULT (getutcdate()) FOR [Fecha]
GO
ALTER TABLE [Soporte].[Tickets] ADD  DEFAULT ('MEDIA') FOR [Prioridad]
GO
ALTER TABLE [Soporte].[Tickets] ADD  DEFAULT ('ABIERTO') FOR [Estado]
GO
ALTER TABLE [Soporte].[Tickets] ADD  DEFAULT (getutcdate()) FOR [FechaCreacion]
GO
ALTER TABLE [Soporte].[Tickets] ADD  DEFAULT (getutcdate()) FOR [FechaActualizacion]
GO
ALTER TABLE [Auditoria].[HistorialPrecios]  WITH CHECK ADD  CONSTRAINT [FK_HistorialPrecios_Articulo] FOREIGN KEY([ArticuloID])
REFERENCES [catalogo].[Tarjetas] ([ArticuloID])
GO
ALTER TABLE [Auditoria].[HistorialPrecios] CHECK CONSTRAINT [FK_HistorialPrecios_Articulo]
GO
ALTER TABLE [Auditoria].[LogAuditoria]  WITH CHECK ADD FOREIGN KEY([UsuarioID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Calendario].[EventoAsistentes]  WITH CHECK ADD FOREIGN KEY([EventoID])
REFERENCES [Calendario].[Eventos] ([EventoID])
GO
ALTER TABLE [Calendario].[EventoAsistentes]  WITH CHECK ADD FOREIGN KEY([UsuarioID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Calendario].[Eventos]  WITH CHECK ADD FOREIGN KEY([CentroCostoID])
REFERENCES [Organizacion].[CentrosCosto] ([CentroCostoID])
GO
ALTER TABLE [Calendario].[Eventos]  WITH CHECK ADD FOREIGN KEY([CreadoPorUsuarioID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [catalogo].[ArticuloProveedor]  WITH CHECK ADD FOREIGN KEY([ArticuloID])
REFERENCES [catalogo].[Tarjetas] ([ArticuloID])
GO
ALTER TABLE [catalogo].[ArticuloProveedor]  WITH CHECK ADD FOREIGN KEY([ProveedorID])
REFERENCES [catalogo].[Proveedores] ([ProveedorID])
GO
ALTER TABLE [catalogo].[GrupoMenor]  WITH CHECK ADD  CONSTRAINT [FK_GruposMenores_GruposMayores] FOREIGN KEY([GrupoMayor])
REFERENCES [catalogo].[GrupoMayor] ([Codigo])
GO
ALTER TABLE [catalogo].[GrupoMenor] CHECK CONSTRAINT [FK_GruposMenores_GruposMayores]
GO
ALTER TABLE [catalogo].[Tarjetas]  WITH CHECK ADD FOREIGN KEY([TipoArticuloID])
REFERENCES [catalogo].[TiposArticulo] ([TipoArticuloID])
GO
ALTER TABLE [catalogo].[Tarjetas]  WITH CHECK ADD FOREIGN KEY([UnidadID])
REFERENCES [catalogo].[UnidadesMedida] ([UnidadID])
GO
ALTER TABLE [catalogo].[Tarjetas]  WITH CHECK ADD  CONSTRAINT [FK_Tarjetas_ArticuloPadre] FOREIGN KEY([ArticuloPadreID])
REFERENCES [catalogo].[Tarjetas] ([ArticuloID])
GO
ALTER TABLE [catalogo].[Tarjetas] CHECK CONSTRAINT [FK_Tarjetas_ArticuloPadre]
GO
ALTER TABLE [catalogo].[Tarjetas]  WITH CHECK ADD  CONSTRAINT [FK_Tarjetas_Marcas] FOREIGN KEY([MarcaCodigo])
REFERENCES [catalogo].[Marca] ([Codigo])
GO
ALTER TABLE [catalogo].[Tarjetas] CHECK CONSTRAINT [FK_Tarjetas_Marcas]
GO
ALTER TABLE [catalogo].[Tarjetas]  WITH CHECK ADD  CONSTRAINT [FK_Tarjetas_Presentaciones] FOREIGN KEY([PresentacionCodigo])
REFERENCES [catalogo].[Presentacion] ([Codigo])
GO
ALTER TABLE [catalogo].[Tarjetas] CHECK CONSTRAINT [FK_Tarjetas_Presentaciones]
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
ALTER TABLE [Compras].[OrdenesCompra]  WITH CHECK ADD  CONSTRAINT [FK_OrdenesCompra_CentroCosto] FOREIGN KEY([CentroCostoID])
REFERENCES [Organizacion].[CentrosCosto] ([CentroCostoID])
GO
ALTER TABLE [Compras].[OrdenesCompra] CHECK CONSTRAINT [FK_OrdenesCompra_CentroCosto]
GO
ALTER TABLE [Compras].[OrdenesCompraDetalle]  WITH CHECK ADD FOREIGN KEY([ArticuloID])
REFERENCES [catalogo].[Tarjetas] ([ArticuloID])
GO
ALTER TABLE [Compras].[OrdenesCompraDetalle]  WITH CHECK ADD FOREIGN KEY([LoteID])
REFERENCES [Inventario].[Lotes] ([LoteID])
GO
ALTER TABLE [Compras].[OrdenesCompraDetalle]  WITH CHECK ADD FOREIGN KEY([OrdenCompraID])
REFERENCES [Compras].[OrdenesCompra] ([OrdenCompraID])
GO
ALTER TABLE [Conocimiento].[Articulos]  WITH CHECK ADD FOREIGN KEY([AutorID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Crm].[Actividades]  WITH CHECK ADD FOREIGN KEY([ClienteID])
REFERENCES [Crm].[Clientes] ([ClienteID])
GO
ALTER TABLE [Crm].[Actividades]  WITH CHECK ADD FOREIGN KEY([OportunidadID])
REFERENCES [Crm].[Oportunidades] ([OportunidadID])
GO
ALTER TABLE [Crm].[Actividades]  WITH CHECK ADD FOREIGN KEY([ResponsableID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Crm].[ClienteDocumentos]  WITH CHECK ADD  CONSTRAINT [FK_ClienteDocumentos_Cliente] FOREIGN KEY([ClienteID])
REFERENCES [Crm].[Clientes] ([ClienteID])
GO
ALTER TABLE [Crm].[ClienteDocumentos] CHECK CONSTRAINT [FK_ClienteDocumentos_Cliente]
GO
ALTER TABLE [Crm].[ClienteDocumentos]  WITH CHECK ADD  CONSTRAINT [FK_ClienteDocumentos_Usuario] FOREIGN KEY([UsuarioID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Crm].[ClienteDocumentos] CHECK CONSTRAINT [FK_ClienteDocumentos_Usuario]
GO
ALTER TABLE [Crm].[Clientes]  WITH CHECK ADD  CONSTRAINT [FK_Clientes_Responsable] FOREIGN KEY([ResponsableID])
REFERENCES [Rrhh].[Empleados] ([EmpleadoID])
GO
ALTER TABLE [Crm].[Clientes] CHECK CONSTRAINT [FK_Clientes_Responsable]
GO
ALTER TABLE [Crm].[Contactos]  WITH CHECK ADD  CONSTRAINT [FK_Contactos_Cliente] FOREIGN KEY([ClienteID])
REFERENCES [Crm].[Clientes] ([ClienteID])
GO
ALTER TABLE [Crm].[Contactos] CHECK CONSTRAINT [FK_Contactos_Cliente]
GO
ALTER TABLE [Crm].[Cotizaciones]  WITH CHECK ADD FOREIGN KEY([ClienteID])
REFERENCES [Crm].[Clientes] ([ClienteID])
GO
ALTER TABLE [Crm].[Cotizaciones]  WITH CHECK ADD FOREIGN KEY([OportunidadID])
REFERENCES [Crm].[Oportunidades] ([OportunidadID])
GO
ALTER TABLE [Crm].[Cotizaciones]  WITH CHECK ADD FOREIGN KEY([UsuarioID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Crm].[Cotizaciones]  WITH CHECK ADD  CONSTRAINT [FK_Cotizaciones_CentroCosto] FOREIGN KEY([CentroCostoID])
REFERENCES [Organizacion].[CentrosCosto] ([CentroCostoID])
GO
ALTER TABLE [Crm].[Cotizaciones] CHECK CONSTRAINT [FK_Cotizaciones_CentroCosto]
GO
ALTER TABLE [Crm].[CotizacionLineas]  WITH CHECK ADD FOREIGN KEY([ArticuloID])
REFERENCES [catalogo].[Tarjetas] ([ArticuloID])
GO
ALTER TABLE [Crm].[CotizacionLineas]  WITH CHECK ADD FOREIGN KEY([CotizacionID])
REFERENCES [Crm].[Cotizaciones] ([CotizacionID])
GO
ALTER TABLE [Crm].[EjecucionesAutomatizacion]  WITH CHECK ADD FOREIGN KEY([ReglaID])
REFERENCES [Crm].[ReglasAutomatizacion] ([ReglaID])
ON DELETE CASCADE
GO
ALTER TABLE [Crm].[Interacciones]  WITH CHECK ADD  CONSTRAINT [FK_Interacciones_Cliente] FOREIGN KEY([ClienteID])
REFERENCES [Crm].[Clientes] ([ClienteID])
GO
ALTER TABLE [Crm].[Interacciones] CHECK CONSTRAINT [FK_Interacciones_Cliente]
GO
ALTER TABLE [Crm].[Interacciones]  WITH CHECK ADD  CONSTRAINT [FK_Interacciones_Usuario] FOREIGN KEY([UsuarioID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Crm].[Interacciones] CHECK CONSTRAINT [FK_Interacciones_Usuario]
GO
ALTER TABLE [Crm].[Leads]  WITH CHECK ADD  CONSTRAINT [FK_Leads_ClienteConvertido] FOREIGN KEY([ClienteIDConvertido])
REFERENCES [Crm].[Clientes] ([ClienteID])
GO
ALTER TABLE [Crm].[Leads] CHECK CONSTRAINT [FK_Leads_ClienteConvertido]
GO
ALTER TABLE [Crm].[Leads]  WITH CHECK ADD  CONSTRAINT [FK_Leads_Responsable] FOREIGN KEY([ResponsableID])
REFERENCES [Rrhh].[Empleados] ([EmpleadoID])
GO
ALTER TABLE [Crm].[Leads] CHECK CONSTRAINT [FK_Leads_Responsable]
GO
ALTER TABLE [Crm].[LineasCredito]  WITH CHECK ADD  CONSTRAINT [FK_LineasCredito_Cliente] FOREIGN KEY([ClienteID])
REFERENCES [Crm].[Clientes] ([ClienteID])
GO
ALTER TABLE [Crm].[LineasCredito] CHECK CONSTRAINT [FK_LineasCredito_Cliente]
GO
ALTER TABLE [Crm].[Oportunidades]  WITH CHECK ADD FOREIGN KEY([ClienteID])
REFERENCES [Crm].[Clientes] ([ClienteID])
GO
ALTER TABLE [Crm].[Oportunidades]  WITH CHECK ADD FOREIGN KEY([LeadID])
REFERENCES [Crm].[Leads] ([LeadID])
GO
ALTER TABLE [Crm].[Oportunidades]  WITH CHECK ADD FOREIGN KEY([ResponsableID])
REFERENCES [Rrhh].[Empleados] ([EmpleadoID])
GO
ALTER TABLE [Facturacion].[Devoluciones]  WITH CHECK ADD  CONSTRAINT [FK_Dev_CC] FOREIGN KEY([CentroCostoID])
REFERENCES [Organizacion].[CentrosCosto] ([CentroCostoID])
GO
ALTER TABLE [Facturacion].[Devoluciones] CHECK CONSTRAINT [FK_Dev_CC]
GO
ALTER TABLE [Facturacion].[Devoluciones]  WITH CHECK ADD  CONSTRAINT [FK_Dev_Cliente] FOREIGN KEY([ClienteID])
REFERENCES [Crm].[Clientes] ([ClienteID])
GO
ALTER TABLE [Facturacion].[Devoluciones] CHECK CONSTRAINT [FK_Dev_Cliente]
GO
ALTER TABLE [Facturacion].[Devoluciones]  WITH CHECK ADD  CONSTRAINT [FK_Dev_Factura] FOREIGN KEY([FacturaOrigenID])
REFERENCES [Facturacion].[Facturas] ([FacturaID])
GO
ALTER TABLE [Facturacion].[Devoluciones] CHECK CONSTRAINT [FK_Dev_Factura]
GO
ALTER TABLE [Facturacion].[Devoluciones]  WITH CHECK ADD  CONSTRAINT [FK_Dev_Proveedor] FOREIGN KEY([ProveedorID])
REFERENCES [catalogo].[Proveedores] ([ProveedorID])
GO
ALTER TABLE [Facturacion].[Devoluciones] CHECK CONSTRAINT [FK_Dev_Proveedor]
GO
ALTER TABLE [Facturacion].[Devoluciones]  WITH CHECK ADD  CONSTRAINT [FK_Dev_Usuario] FOREIGN KEY([UsuarioID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Facturacion].[Devoluciones] CHECK CONSTRAINT [FK_Dev_Usuario]
GO
ALTER TABLE [Facturacion].[DevolucionLineas]  WITH CHECK ADD  CONSTRAINT [FK_DevLin_Art] FOREIGN KEY([ArticuloID])
REFERENCES [catalogo].[Tarjetas] ([ArticuloID])
GO
ALTER TABLE [Facturacion].[DevolucionLineas] CHECK CONSTRAINT [FK_DevLin_Art]
GO
ALTER TABLE [Facturacion].[DevolucionLineas]  WITH CHECK ADD  CONSTRAINT [FK_DevLin_Dev] FOREIGN KEY([DevolucionID])
REFERENCES [Facturacion].[Devoluciones] ([DevolucionID])
GO
ALTER TABLE [Facturacion].[DevolucionLineas] CHECK CONSTRAINT [FK_DevLin_Dev]
GO
ALTER TABLE [Facturacion].[FacturaLineas]  WITH CHECK ADD FOREIGN KEY([ArticuloID])
REFERENCES [catalogo].[Tarjetas] ([ArticuloID])
GO
ALTER TABLE [Facturacion].[FacturaLineas]  WITH CHECK ADD FOREIGN KEY([FacturaID])
REFERENCES [Facturacion].[Facturas] ([FacturaID])
GO
ALTER TABLE [Facturacion].[FacturaLineas]  WITH CHECK ADD  CONSTRAINT [FK_FacturaLineas_Combo] FOREIGN KEY([ComboID])
REFERENCES [Marketing].[Combos] ([ComboID])
GO
ALTER TABLE [Facturacion].[FacturaLineas] CHECK CONSTRAINT [FK_FacturaLineas_Combo]
GO
ALTER TABLE [Facturacion].[Facturas]  WITH CHECK ADD FOREIGN KEY([ClienteID])
REFERENCES [Crm].[Clientes] ([ClienteID])
GO
ALTER TABLE [Facturacion].[Facturas]  WITH CHECK ADD FOREIGN KEY([UsuarioID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Facturacion].[Facturas]  WITH CHECK ADD  CONSTRAINT [FK_Facturas_CentrosCosto] FOREIGN KEY([CentroCostoID])
REFERENCES [Organizacion].[CentrosCosto] ([CentroCostoID])
GO
ALTER TABLE [Facturacion].[Facturas] CHECK CONSTRAINT [FK_Facturas_CentrosCosto]
GO
ALTER TABLE [Facturacion].[FacturasExportadasVisions]  WITH CHECK ADD  CONSTRAINT [FK_FEV_CentrosCosto] FOREIGN KEY([CentroCostoID])
REFERENCES [Organizacion].[CentrosCosto] ([CentroCostoID])
GO
ALTER TABLE [Facturacion].[FacturasExportadasVisions] CHECK CONSTRAINT [FK_FEV_CentrosCosto]
GO
ALTER TABLE [Facturacion].[FacturasExportadasVisions]  WITH CHECK ADD  CONSTRAINT [FK_FEV_Facturas] FOREIGN KEY([FacturaID])
REFERENCES [Facturacion].[Facturas] ([FacturaID])
GO
ALTER TABLE [Facturacion].[FacturasExportadasVisions] CHECK CONSTRAINT [FK_FEV_Facturas]
GO
ALTER TABLE [Facturacion].[Pagos]  WITH CHECK ADD FOREIGN KEY([FacturaID])
REFERENCES [Facturacion].[Facturas] ([FacturaID])
GO
ALTER TABLE [Facturacion].[Pagos]  WITH CHECK ADD FOREIGN KEY([UsuarioID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Finanzas].[GastosOperativos]  WITH CHECK ADD FOREIGN KEY([CentroCostoID])
REFERENCES [Organizacion].[CentrosCosto] ([CentroCostoID])
GO
ALTER TABLE [Formularios].[Campos]  WITH CHECK ADD FOREIGN KEY([FormularioID])
REFERENCES [Formularios].[Formularios] ([FormularioID])
ON DELETE CASCADE
GO
ALTER TABLE [Formularios].[Respuestas]  WITH CHECK ADD FOREIGN KEY([FormularioID])
REFERENCES [Formularios].[Formularios] ([FormularioID])
ON DELETE CASCADE
GO
ALTER TABLE [Integracion].[AgentesSync]  WITH CHECK ADD FOREIGN KEY([CentroCostoID])
REFERENCES [Organizacion].[CentrosCosto] ([CentroCostoID])
GO
ALTER TABLE [Integracion].[ArticulosPendientesMapeo]  WITH CHECK ADD  CONSTRAINT [FK_ArticulosPendientesMapeo_CentroCosto] FOREIGN KEY([CentroCostoID])
REFERENCES [Organizacion].[CentrosCosto] ([CentroCostoID])
GO
ALTER TABLE [Integracion].[ArticulosPendientesMapeo] CHECK CONSTRAINT [FK_ArticulosPendientesMapeo_CentroCosto]
GO
ALTER TABLE [Integracion].[EventosEntrantes]  WITH CHECK ADD FOREIGN KEY([CentroCostoID])
REFERENCES [Organizacion].[CentrosCosto] ([CentroCostoID])
GO
ALTER TABLE [Integracion].[EventosSalientes]  WITH CHECK ADD FOREIGN KEY([ArticuloID])
REFERENCES [catalogo].[Tarjetas] ([ArticuloID])
GO
ALTER TABLE [Integracion].[EventosSalientes]  WITH CHECK ADD FOREIGN KEY([CentroCostoID])
REFERENCES [Organizacion].[CentrosCosto] ([CentroCostoID])
GO
ALTER TABLE [Integracion].[EventosSalientes]  WITH CHECK ADD FOREIGN KEY([KardexID])
REFERENCES [Kardex].[KardexMovimientos] ([KardexID])
GO
ALTER TABLE [Integracion].[InventarioReportadoVisions]  WITH CHECK ADD FOREIGN KEY([ArticuloID])
REFERENCES [catalogo].[Tarjetas] ([ArticuloID])
GO
ALTER TABLE [Integracion].[InventarioReportadoVisions]  WITH CHECK ADD FOREIGN KEY([CentroCostoID])
REFERENCES [Organizacion].[CentrosCosto] ([CentroCostoID])
GO
ALTER TABLE [Integracion].[MapeoArticulos]  WITH CHECK ADD FOREIGN KEY([ArticuloID])
REFERENCES [catalogo].[Tarjetas] ([ArticuloID])
GO
ALTER TABLE [Integracion].[MapeoArticulos]  WITH CHECK ADD FOREIGN KEY([CentroCostoID])
REFERENCES [Organizacion].[CentrosCosto] ([CentroCostoID])
GO
ALTER TABLE [Inventario].[Bodegas]  WITH CHECK ADD FOREIGN KEY([CentroCostoID])
REFERENCES [Organizacion].[CentrosCosto] ([CentroCostoID])
GO
ALTER TABLE [Inventario].[InventarioStock]  WITH CHECK ADD FOREIGN KEY([ArticuloID])
REFERENCES [catalogo].[Tarjetas] ([ArticuloID])
GO
ALTER TABLE [Inventario].[InventarioStock]  WITH CHECK ADD FOREIGN KEY([BodegaID])
REFERENCES [Inventario].[Bodegas] ([BodegaID])
GO
ALTER TABLE [Inventario].[InventarioStock]  WITH CHECK ADD FOREIGN KEY([LoteID])
REFERENCES [Inventario].[Lotes] ([LoteID])
GO
ALTER TABLE [Inventario].[Lotes]  WITH CHECK ADD FOREIGN KEY([ArticuloID])
REFERENCES [catalogo].[Tarjetas] ([ArticuloID])
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
REFERENCES [catalogo].[Tarjetas] ([ArticuloID])
GO
ALTER TABLE [Inventario].[TraspasosDetalle]  WITH CHECK ADD FOREIGN KEY([LoteID])
REFERENCES [Inventario].[Lotes] ([LoteID])
GO
ALTER TABLE [Inventario].[TraspasosDetalle]  WITH CHECK ADD FOREIGN KEY([TraspasoID])
REFERENCES [Inventario].[TraspasosBodega] ([TraspasoID])
GO
ALTER TABLE [Kardex].[BajasInventarioPerdidas]  WITH CHECK ADD FOREIGN KEY([ArticuloID])
REFERENCES [catalogo].[Tarjetas] ([ArticuloID])
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
REFERENCES [catalogo].[Tarjetas] ([ArticuloID])
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
ALTER TABLE [Logistica].[DespachoDetalle]  WITH CHECK ADD  CONSTRAINT [FK_DespachoDetalle_Articulo] FOREIGN KEY([ArticuloID])
REFERENCES [catalogo].[Tarjetas] ([ArticuloID])
GO
ALTER TABLE [Logistica].[DespachoDetalle] CHECK CONSTRAINT [FK_DespachoDetalle_Articulo]
GO
ALTER TABLE [Logistica].[DespachoDetalle]  WITH CHECK ADD  CONSTRAINT [FK_DespachoDetalle_Despacho] FOREIGN KEY([DespachoID])
REFERENCES [Logistica].[Despachos] ([DespachoID])
GO
ALTER TABLE [Logistica].[DespachoDetalle] CHECK CONSTRAINT [FK_DespachoDetalle_Despacho]
GO
ALTER TABLE [Logistica].[Despachos]  WITH CHECK ADD  CONSTRAINT [FK_Despachos_BodegaOrigen] FOREIGN KEY([BodegaOrigenID])
REFERENCES [Inventario].[Bodegas] ([BodegaID])
GO
ALTER TABLE [Logistica].[Despachos] CHECK CONSTRAINT [FK_Despachos_BodegaOrigen]
GO
ALTER TABLE [Logistica].[Despachos]  WITH CHECK ADD  CONSTRAINT [FK_Despachos_CentroCosto] FOREIGN KEY([CentroCostoID])
REFERENCES [Organizacion].[CentrosCosto] ([CentroCostoID])
GO
ALTER TABLE [Logistica].[Despachos] CHECK CONSTRAINT [FK_Despachos_CentroCosto]
GO
ALTER TABLE [Logistica].[Despachos]  WITH CHECK ADD  CONSTRAINT [FK_Despachos_Cliente] FOREIGN KEY([ClienteID])
REFERENCES [Crm].[Clientes] ([ClienteID])
GO
ALTER TABLE [Logistica].[Despachos] CHECK CONSTRAINT [FK_Despachos_Cliente]
GO
ALTER TABLE [Logistica].[Despachos]  WITH CHECK ADD  CONSTRAINT [FK_Despachos_Usuario] FOREIGN KEY([UsuarioID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Logistica].[Despachos] CHECK CONSTRAINT [FK_Despachos_Usuario]
GO
ALTER TABLE [Logistica].[Despachos]  WITH CHECK ADD  CONSTRAINT [FK_Despachos_UsuarioAnula] FOREIGN KEY([UsuarioAnulaID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Logistica].[Despachos] CHECK CONSTRAINT [FK_Despachos_UsuarioAnula]
GO
ALTER TABLE [Marketing].[ComboItems]  WITH CHECK ADD  CONSTRAINT [FK_ComboItems_Articulo] FOREIGN KEY([ArticuloID])
REFERENCES [catalogo].[Tarjetas] ([ArticuloID])
GO
ALTER TABLE [Marketing].[ComboItems] CHECK CONSTRAINT [FK_ComboItems_Articulo]
GO
ALTER TABLE [Marketing].[ComboItems]  WITH CHECK ADD  CONSTRAINT [FK_ComboItems_Combo] FOREIGN KEY([ComboID])
REFERENCES [Marketing].[Combos] ([ComboID])
ON DELETE CASCADE
GO
ALTER TABLE [Marketing].[ComboItems] CHECK CONSTRAINT [FK_ComboItems_Combo]
GO
ALTER TABLE [Marketing].[Combos]  WITH CHECK ADD  CONSTRAINT [FK_Combos_Usuario] FOREIGN KEY([UsuarioCreaID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Marketing].[Combos] CHECK CONSTRAINT [FK_Combos_Usuario]
GO
ALTER TABLE [Marketing].[EnviosDetalle]  WITH CHECK ADD FOREIGN KEY([CampanaID])
REFERENCES [Marketing].[Campanas] ([CampanaID])
GO
ALTER TABLE [Organizacion].[CentrosCosto]  WITH CHECK ADD  CONSTRAINT [FK_CentrosCosto_BodegaVentaVisions] FOREIGN KEY([BodegaVentaVisionsID])
REFERENCES [Inventario].[Bodegas] ([BodegaID])
GO
ALTER TABLE [Organizacion].[CentrosCosto] CHECK CONSTRAINT [FK_CentrosCosto_BodegaVentaVisions]
GO
ALTER TABLE [Organizacion].[CentrosTrabajo]  WITH CHECK ADD FOREIGN KEY([CentroCostoID])
REFERENCES [Organizacion].[CentrosCosto] ([CentroCostoID])
GO
ALTER TABLE [Planificacion].[DemandaProyectada]  WITH CHECK ADD  CONSTRAINT [FK_DemandaProyectada_Articulo] FOREIGN KEY([ArticuloID])
REFERENCES [catalogo].[Tarjetas] ([ArticuloID])
GO
ALTER TABLE [Planificacion].[DemandaProyectada] CHECK CONSTRAINT [FK_DemandaProyectada_Articulo]
GO
ALTER TABLE [Planificacion].[DemandaProyectada]  WITH CHECK ADD  CONSTRAINT [FK_DemandaProyectada_CentroCosto] FOREIGN KEY([CentroCostoID])
REFERENCES [Organizacion].[CentrosCosto] ([CentroCostoID])
GO
ALTER TABLE [Planificacion].[DemandaProyectada] CHECK CONSTRAINT [FK_DemandaProyectada_CentroCosto]
GO
ALTER TABLE [Planificacion].[MetasVenta]  WITH CHECK ADD  CONSTRAINT [FK_MetasVenta_CentroCosto] FOREIGN KEY([CentroCostoID])
REFERENCES [Organizacion].[CentrosCosto] ([CentroCostoID])
GO
ALTER TABLE [Planificacion].[MetasVenta] CHECK CONSTRAINT [FK_MetasVenta_CentroCosto]
GO
ALTER TABLE [Planificacion].[MetasVentaHistorial]  WITH CHECK ADD FOREIGN KEY([MetaID])
REFERENCES [Planificacion].[MetasVenta] ([MetaID])
GO
ALTER TABLE [Planificacion].[MetasVentaHistorial]  WITH CHECK ADD FOREIGN KEY([UsuarioID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Produccion].[MantenimientoMaquinaria]  WITH CHECK ADD FOREIGN KEY([MaquinariaID])
REFERENCES [Produccion].[Maquinaria] ([MaquinariaID])
ON DELETE CASCADE
GO
ALTER TABLE [Produccion].[MantenimientoMaquinaria]  WITH CHECK ADD FOREIGN KEY([UsuarioID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Produccion].[Maquinaria]  WITH CHECK ADD FOREIGN KEY([CentroTrabajoID])
REFERENCES [Organizacion].[CentrosTrabajo] ([CentroTrabajoID])
GO
ALTER TABLE [Produccion].[Maquinaria]  WITH CHECK ADD FOREIGN KEY([TipoMaquinariaID])
REFERENCES [Produccion].[TiposMaquinaria] ([TipoMaquinariaID])
GO
ALTER TABLE [Produccion].[OrdenEmpleado]  WITH CHECK ADD  CONSTRAINT [FK_OrdenEmpleado_Empleado] FOREIGN KEY([EmpleadoID])
REFERENCES [Rrhh].[Empleados] ([EmpleadoID])
GO
ALTER TABLE [Produccion].[OrdenEmpleado] CHECK CONSTRAINT [FK_OrdenEmpleado_Empleado]
GO
ALTER TABLE [Produccion].[OrdenEmpleado]  WITH CHECK ADD  CONSTRAINT [FK_OrdenEmpleado_Orden] FOREIGN KEY([OrdenProduccionID])
REFERENCES [Produccion].[OrdenesProduccion] ([OrdenProduccionID])
ON DELETE CASCADE
GO
ALTER TABLE [Produccion].[OrdenEmpleado] CHECK CONSTRAINT [FK_OrdenEmpleado_Orden]
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
REFERENCES [Crm].[Clientes] ([ClienteID])
GO
ALTER TABLE [Produccion].[OrdenesProduccion]  WITH CHECK ADD FOREIGN KEY([EstadoOPID])
REFERENCES [Produccion].[EstadosOP] ([EstadoOPID])
GO
ALTER TABLE [Produccion].[OrdenesProduccion]  WITH CHECK ADD FOREIGN KEY([ProductoTerminadoID])
REFERENCES [catalogo].[Tarjetas] ([ArticuloID])
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
REFERENCES [catalogo].[Tarjetas] ([ArticuloID])
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
ALTER TABLE [Produccion].[OrdenMaquinaria]  WITH CHECK ADD FOREIGN KEY([MaquinariaID])
REFERENCES [Produccion].[Maquinaria] ([MaquinariaID])
GO
ALTER TABLE [Produccion].[OrdenMaquinaria]  WITH CHECK ADD FOREIGN KEY([OrdenProduccionID])
REFERENCES [Produccion].[OrdenesProduccion] ([OrdenProduccionID])
ON DELETE CASCADE
GO
ALTER TABLE [Produccion].[RecetaBOM]  WITH CHECK ADD FOREIGN KEY([ProductoTerminadoID])
REFERENCES [catalogo].[Tarjetas] ([ArticuloID])
GO
ALTER TABLE [Produccion].[RecetaBOM_Detalle]  WITH CHECK ADD FOREIGN KEY([CentroTrabajoID])
REFERENCES [Organizacion].[CentrosTrabajo] ([CentroTrabajoID])
GO
ALTER TABLE [Produccion].[RecetaBOM_Detalle]  WITH CHECK ADD FOREIGN KEY([InsumoID])
REFERENCES [catalogo].[Tarjetas] ([ArticuloID])
GO
ALTER TABLE [Produccion].[RecetaBOM_Detalle]  WITH CHECK ADD FOREIGN KEY([RecetaID])
REFERENCES [Produccion].[RecetaBOM] ([RecetaID])
GO
ALTER TABLE [Produccion].[RecetaEmpleado]  WITH CHECK ADD  CONSTRAINT [FK_RecetaEmpleado_Empleado] FOREIGN KEY([EmpleadoID])
REFERENCES [Rrhh].[Empleados] ([EmpleadoID])
GO
ALTER TABLE [Produccion].[RecetaEmpleado] CHECK CONSTRAINT [FK_RecetaEmpleado_Empleado]
GO
ALTER TABLE [Produccion].[RecetaEmpleado]  WITH CHECK ADD  CONSTRAINT [FK_RecetaEmpleado_Receta] FOREIGN KEY([RecetaID])
REFERENCES [Produccion].[RecetaBOM] ([RecetaID])
ON DELETE CASCADE
GO
ALTER TABLE [Produccion].[RecetaEmpleado] CHECK CONSTRAINT [FK_RecetaEmpleado_Receta]
GO
ALTER TABLE [Produccion].[RecetaMaquinaria]  WITH CHECK ADD FOREIGN KEY([MaquinariaID])
REFERENCES [Produccion].[Maquinaria] ([MaquinariaID])
GO
ALTER TABLE [Produccion].[RecetaMaquinaria]  WITH CHECK ADD FOREIGN KEY([RecetaID])
REFERENCES [Produccion].[RecetaBOM] ([RecetaID])
ON DELETE CASCADE
GO
ALTER TABLE [Proyectos].[Comentarios]  WITH CHECK ADD FOREIGN KEY([ProyectoID])
REFERENCES [Proyectos].[Proyectos] ([ProyectoID])
GO
ALTER TABLE [Proyectos].[Comentarios]  WITH CHECK ADD FOREIGN KEY([UsuarioID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Proyectos].[Costos]  WITH CHECK ADD  CONSTRAINT [FK_Costos_Articulo] FOREIGN KEY([ArticuloID])
REFERENCES [catalogo].[Tarjetas] ([ArticuloID])
GO
ALTER TABLE [Proyectos].[Costos] CHECK CONSTRAINT [FK_Costos_Articulo]
GO
ALTER TABLE [Proyectos].[Costos]  WITH CHECK ADD  CONSTRAINT [FK_Costos_Empleado] FOREIGN KEY([EmpleadoID])
REFERENCES [Rrhh].[Empleados] ([EmpleadoID])
GO
ALTER TABLE [Proyectos].[Costos] CHECK CONSTRAINT [FK_Costos_Empleado]
GO
ALTER TABLE [Proyectos].[Costos]  WITH CHECK ADD  CONSTRAINT [FK_Costos_Proyecto] FOREIGN KEY([ProyectoID])
REFERENCES [Proyectos].[Proyectos] ([ProyectoID])
GO
ALTER TABLE [Proyectos].[Costos] CHECK CONSTRAINT [FK_Costos_Proyecto]
GO
ALTER TABLE [Proyectos].[Costos]  WITH CHECK ADD  CONSTRAINT [FK_Costos_Usuario] FOREIGN KEY([UsuarioID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Proyectos].[Costos] CHECK CONSTRAINT [FK_Costos_Usuario]
GO
ALTER TABLE [Proyectos].[Hitos]  WITH CHECK ADD FOREIGN KEY([ProyectoID])
REFERENCES [Proyectos].[Proyectos] ([ProyectoID])
GO
ALTER TABLE [Proyectos].[ProyectoDocumentos]  WITH CHECK ADD FOREIGN KEY([ProyectoID])
REFERENCES [Proyectos].[Proyectos] ([ProyectoID])
GO
ALTER TABLE [Proyectos].[ProyectoDocumentos]  WITH CHECK ADD FOREIGN KEY([UsuarioID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Proyectos].[Proyectos]  WITH CHECK ADD  CONSTRAINT [FK_Proyectos_CentroCosto] FOREIGN KEY([CentroCostoID])
REFERENCES [Organizacion].[CentrosCosto] ([CentroCostoID])
GO
ALTER TABLE [Proyectos].[Proyectos] CHECK CONSTRAINT [FK_Proyectos_CentroCosto]
GO
ALTER TABLE [Proyectos].[Proyectos]  WITH CHECK ADD  CONSTRAINT [FK_Proyectos_Cliente] FOREIGN KEY([ClienteID])
REFERENCES [Crm].[Clientes] ([ClienteID])
GO
ALTER TABLE [Proyectos].[Proyectos] CHECK CONSTRAINT [FK_Proyectos_Cliente]
GO
ALTER TABLE [Proyectos].[TareaDependencias]  WITH CHECK ADD FOREIGN KEY([DependeDeTareaID])
REFERENCES [Proyectos].[Tareas] ([TareaID])
GO
ALTER TABLE [Proyectos].[TareaDependencias]  WITH CHECK ADD FOREIGN KEY([TareaID])
REFERENCES [Proyectos].[Tareas] ([TareaID])
GO
ALTER TABLE [Proyectos].[Tareas]  WITH CHECK ADD  CONSTRAINT [FK_Tareas_Proyecto] FOREIGN KEY([ProyectoID])
REFERENCES [Proyectos].[Proyectos] ([ProyectoID])
GO
ALTER TABLE [Proyectos].[Tareas] CHECK CONSTRAINT [FK_Tareas_Proyecto]
GO
ALTER TABLE [Proyectos].[Tareas]  WITH CHECK ADD  CONSTRAINT [FK_Tareas_Responsable] FOREIGN KEY([ResponsableID])
REFERENCES [Rrhh].[Empleados] ([EmpleadoID])
GO
ALTER TABLE [Proyectos].[Tareas] CHECK CONSTRAINT [FK_Tareas_Responsable]
GO
ALTER TABLE [Rrhh].[Ausencias]  WITH CHECK ADD FOREIGN KEY([EmpleadoID])
REFERENCES [Rrhh].[Empleados] ([EmpleadoID])
GO
ALTER TABLE [Rrhh].[Ausencias]  WITH CHECK ADD FOREIGN KEY([UsuarioID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Rrhh].[Capacitaciones]  WITH CHECK ADD FOREIGN KEY([EmpleadoID])
REFERENCES [Rrhh].[Empleados] ([EmpleadoID])
GO
ALTER TABLE [Rrhh].[Capacitaciones]  WITH CHECK ADD FOREIGN KEY([UsuarioID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Rrhh].[Cargos]  WITH CHECK ADD FOREIGN KEY([DepartamentoID])
REFERENCES [Rrhh].[Departamentos] ([DepartamentoID])
GO
ALTER TABLE [Rrhh].[Cargos]  WITH CHECK ADD FOREIGN KEY([RolPredeterminadoID])
REFERENCES [Seguridad].[Roles] ([RolID])
GO
ALTER TABLE [Rrhh].[EmpleadoDocumentos]  WITH CHECK ADD FOREIGN KEY([EmpleadoID])
REFERENCES [Rrhh].[Empleados] ([EmpleadoID])
GO
ALTER TABLE [Rrhh].[EmpleadoDocumentos]  WITH CHECK ADD FOREIGN KEY([UsuarioID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Rrhh].[EmpleadoHorario]  WITH CHECK ADD  CONSTRAINT [FK_EmpHorario_Emp] FOREIGN KEY([EmpleadoID])
REFERENCES [Rrhh].[Empleados] ([EmpleadoID])
GO
ALTER TABLE [Rrhh].[EmpleadoHorario] CHECK CONSTRAINT [FK_EmpHorario_Emp]
GO
ALTER TABLE [Rrhh].[EmpleadoHorario]  WITH CHECK ADD  CONSTRAINT [FK_EmpHorario_Hor] FOREIGN KEY([HorarioID])
REFERENCES [Rrhh].[Horarios] ([HorarioID])
GO
ALTER TABLE [Rrhh].[EmpleadoHorario] CHECK CONSTRAINT [FK_EmpHorario_Hor]
GO
ALTER TABLE [Rrhh].[Empleados]  WITH CHECK ADD FOREIGN KEY([CargoID])
REFERENCES [Rrhh].[Cargos] ([CargoID])
GO
ALTER TABLE [Rrhh].[Empleados]  WITH CHECK ADD FOREIGN KEY([JefeDirectoID])
REFERENCES [Rrhh].[Empleados] ([EmpleadoID])
GO
ALTER TABLE [Rrhh].[Empleados]  WITH CHECK ADD  CONSTRAINT [FK_Empleados_CentroCosto] FOREIGN KEY([CentroCostoID])
REFERENCES [Organizacion].[CentrosCosto] ([CentroCostoID])
GO
ALTER TABLE [Rrhh].[Empleados] CHECK CONSTRAINT [FK_Empleados_CentroCosto]
GO
ALTER TABLE [Rrhh].[Evaluaciones]  WITH CHECK ADD FOREIGN KEY([EmpleadoID])
REFERENCES [Rrhh].[Empleados] ([EmpleadoID])
GO
ALTER TABLE [Rrhh].[Evaluaciones]  WITH CHECK ADD FOREIGN KEY([ResponsableID])
REFERENCES [Rrhh].[Empleados] ([EmpleadoID])
GO
ALTER TABLE [Rrhh].[Evaluaciones]  WITH CHECK ADD FOREIGN KEY([UsuarioID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Rrhh].[HistorialLaboral]  WITH CHECK ADD FOREIGN KEY([EmpleadoID])
REFERENCES [Rrhh].[Empleados] ([EmpleadoID])
GO
ALTER TABLE [Rrhh].[HistorialLaboral]  WITH CHECK ADD FOREIGN KEY([UsuarioID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Rrhh].[HorarioDias]  WITH CHECK ADD FOREIGN KEY([HorarioID])
REFERENCES [Rrhh].[Horarios] ([HorarioID])
ON DELETE CASCADE
GO
ALTER TABLE [Rrhh].[RegistroAsistencia]  WITH CHECK ADD  CONSTRAINT [FK_Asist_Emp] FOREIGN KEY([EmpleadoID])
REFERENCES [Rrhh].[Empleados] ([EmpleadoID])
GO
ALTER TABLE [Rrhh].[RegistroAsistencia] CHECK CONSTRAINT [FK_Asist_Emp]
GO
ALTER TABLE [Seguridad].[Modulos]  WITH CHECK ADD FOREIGN KEY([ModuloPadreID])
REFERENCES [Seguridad].[Modulos] ([ModuloID])
GO
ALTER TABLE [Seguridad].[PermisoModuloRol]  WITH CHECK ADD FOREIGN KEY([ModuloID])
REFERENCES [Seguridad].[Modulos] ([ModuloID])
GO
ALTER TABLE [Seguridad].[PermisoModuloRol]  WITH CHECK ADD FOREIGN KEY([RolID])
REFERENCES [Seguridad].[Roles] ([RolID])
GO
ALTER TABLE [Seguridad].[PermisoModuloUsuario]  WITH CHECK ADD FOREIGN KEY([ModuloID])
REFERENCES [Seguridad].[Modulos] ([ModuloID])
GO
ALTER TABLE [Seguridad].[PermisoModuloUsuario]  WITH CHECK ADD FOREIGN KEY([UsuarioID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Seguridad].[PreferenciasUsuario]  WITH CHECK ADD  CONSTRAINT [FK_PreferenciasUsuario_Usuario] FOREIGN KEY([UsuarioID])
REFERENCES [Seguridad].[Usuarios] ([UsuarioID])
GO
ALTER TABLE [Seguridad].[PreferenciasUsuario] CHECK CONSTRAINT [FK_PreferenciasUsuario_Usuario]
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
ALTER TABLE [Seguridad].[Usuarios]  WITH CHECK ADD  CONSTRAINT [FK_Usuarios_Empleados] FOREIGN KEY([EmpleadoID])
REFERENCES [Rrhh].[Empleados] ([EmpleadoID])
GO
ALTER TABLE [Seguridad].[Usuarios] CHECK CONSTRAINT [FK_Usuarios_Empleados]
GO
ALTER TABLE [Soporte].[EncuestasNPS]  WITH CHECK ADD FOREIGN KEY([TicketID])
REFERENCES [Soporte].[Tickets] ([TicketID])
GO
ALTER TABLE [Soporte].[TicketComentarios]  WITH CHECK ADD FOREIGN KEY([TicketID])
REFERENCES [Soporte].[Tickets] ([TicketID])
ON DELETE CASCADE
GO
ALTER TABLE [Soporte].[Tickets]  WITH CHECK ADD FOREIGN KEY([ClienteID])
REFERENCES [Crm].[Clientes] ([ClienteID])
GO
ALTER TABLE [Auditoria].[LogAuditoria]  WITH CHECK ADD CHECK  (([Accion]='DELETE' OR [Accion]='UPDATE' OR [Accion]='INSERT'))
GO
ALTER TABLE [catalogo].[UnidadesMedida]  WITH CHECK ADD CHECK  (([Tipo]='LONGITUD' OR [Tipo]='UNIDAD' OR [Tipo]='VOLUMEN' OR [Tipo]='PESO'))
GO
ALTER TABLE [Compras].[OrdenesCompra]  WITH CHECK ADD CHECK  (([EstadoOC]='CANCELADA' OR [EstadoOC]='RECIBIDA' OR [EstadoOC]='PARCIAL' OR [EstadoOC]='PENDIENTE'))
GO
ALTER TABLE [Compras].[OrdenesCompraDetalle]  WITH CHECK ADD CHECK  (([CantidadSolicitada]>(0)))
GO
ALTER TABLE [Crm].[Actividades]  WITH CHECK ADD CHECK  (([Tipo]='TAREA' OR [Tipo]='REUNION' OR [Tipo]='EMAIL' OR [Tipo]='LLAMADA'))
GO
ALTER TABLE [Crm].[Oportunidades]  WITH CHECK ADD  CONSTRAINT [CK_Oportunidades_OrigenRequerido] CHECK  (([LeadID] IS NOT NULL OR [ClienteID] IS NOT NULL))
GO
ALTER TABLE [Crm].[Oportunidades] CHECK CONSTRAINT [CK_Oportunidades_OrigenRequerido]
GO
ALTER TABLE [Facturacion].[FacturaLineas]  WITH CHECK ADD  CONSTRAINT [CK_FacturaLineas_ArticuloOCombo] CHECK  (([ArticuloID] IS NOT NULL OR [ComboID] IS NOT NULL))
GO
ALTER TABLE [Facturacion].[FacturaLineas] CHECK CONSTRAINT [CK_FacturaLineas_ArticuloOCombo]
GO
ALTER TABLE [Facturacion].[Facturas]  WITH CHECK ADD  CONSTRAINT [CK_Facturas_TipDoc] CHECK  (([TipDoc]='SEPARADOS' OR [TipDoc]='REMISION' OR [TipDoc]='PERDIDA INVENTARIO' OR [TipDoc]='ORDEN COMPRA' OR [TipDoc]='NOTA DEVOLUCION' OR [TipDoc]='NOTA DEBITO' OR [TipDoc]='GARANTIA' OR [TipDoc]='FACTURA' OR [TipDoc]='EGRESO' OR [TipDoc]='DEVOLUCION PROVEEDOR'))
GO
ALTER TABLE [Facturacion].[Facturas] CHECK CONSTRAINT [CK_Facturas_TipDoc]
GO
ALTER TABLE [Integracion].[EventosEntrantes]  WITH CHECK ADD CHECK  (([TipoEvento]='AJUSTE_INVENTARIO' OR [TipoEvento]='VENTA'))
GO
ALTER TABLE [Integracion].[EventosSalientes]  WITH CHECK ADD CHECK  (([Estado]='ERROR' OR [Estado]='CONFIRMADO' OR [Estado]='ENVIADO' OR [Estado]='PENDIENTE'))
GO
ALTER TABLE [Integracion].[EventosSalientes]  WITH CHECK ADD  CONSTRAINT [CK_EventosSalientes_TipoEvento] CHECK  (([TipoEvento]='SINCRONIZAR_ARTICULO' OR [TipoEvento]='TRASPASO_RECIBIDO' OR [TipoEvento]='ENTRADA_PRODUCTO_TERMINADO'))
GO
ALTER TABLE [Integracion].[EventosSalientes] CHECK CONSTRAINT [CK_EventosSalientes_TipoEvento]
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
ALTER TABLE [Marketing].[Combos]  WITH CHECK ADD  CONSTRAINT [CK_Combos_Descuento] CHECK  (([PorcentajeDescuento]>=(0) AND [PorcentajeDescuento]<=(100)))
GO
ALTER TABLE [Marketing].[Combos] CHECK CONSTRAINT [CK_Combos_Descuento]
GO
ALTER TABLE [Marketing].[Combos]  WITH CHECK ADD  CONSTRAINT [CK_Combos_Estado] CHECK  (([Estado]='Borrador' OR [Estado]='Inactivo' OR [Estado]='Activo'))
GO
ALTER TABLE [Marketing].[Combos] CHECK CONSTRAINT [CK_Combos_Estado]
GO
ALTER TABLE [Marketing].[Combos]  WITH CHECK ADD  CONSTRAINT [CK_Combos_ModoPrecio] CHECK  (([ModoPrecio]='CALCULADO' OR [ModoPrecio]='MANUAL'))
GO
ALTER TABLE [Marketing].[Combos] CHECK CONSTRAINT [CK_Combos_ModoPrecio]
GO
ALTER TABLE [Organizacion].[CentrosCosto]  WITH CHECK ADD CHECK  (([TipoCentro]='FRANQUICIA' OR [TipoCentro]='PUNTO_VENTA' OR [TipoCentro]='SUCURSAL' OR [TipoCentro]='PLANTA_CENTRAL'))
GO
ALTER TABLE [Organizacion].[ConfiguracionEmail]  WITH CHECK ADD  CONSTRAINT [CK_ConfigEmail_Singleton] CHECK  (([ConfiguracionID]=(1)))
GO
ALTER TABLE [Organizacion].[ConfiguracionEmail] CHECK CONSTRAINT [CK_ConfigEmail_Singleton]
GO
ALTER TABLE [Organizacion].[ConfiguracionEmpresa]  WITH CHECK ADD  CONSTRAINT [CK_ConfigEmpresa_ModoLotes] CHECK  (([ModoLotes]='MANUAL' OR [ModoLotes]='FIFO'))
GO
ALTER TABLE [Organizacion].[ConfiguracionEmpresa] CHECK CONSTRAINT [CK_ConfigEmpresa_ModoLotes]
GO
ALTER TABLE [Organizacion].[ConfiguracionEmpresa]  WITH CHECK ADD  CONSTRAINT [CK_ConfiguracionEmpresa_Singleton] CHECK  (([ConfiguracionID]=(1)))
GO
ALTER TABLE [Organizacion].[ConfiguracionEmpresa] CHECK CONSTRAINT [CK_ConfiguracionEmpresa_Singleton]
GO
ALTER TABLE [Organizacion].[ConfiguracionWhatsApp]  WITH CHECK ADD  CONSTRAINT [CK_ConfigWhatsApp_Singleton] CHECK  (([ConfiguracionID]=(1)))
GO
ALTER TABLE [Organizacion].[ConfiguracionWhatsApp] CHECK CONSTRAINT [CK_ConfigWhatsApp_Singleton]
GO
ALTER TABLE [Produccion].[MantenimientoMaquinaria]  WITH CHECK ADD  CONSTRAINT [CK_Mant_Tipo] CHECK  (([TipoMantenimiento]='Predictivo' OR [TipoMantenimiento]='Correctivo' OR [TipoMantenimiento]='Preventivo'))
GO
ALTER TABLE [Produccion].[MantenimientoMaquinaria] CHECK CONSTRAINT [CK_Mant_Tipo]
GO
ALTER TABLE [Produccion].[Maquinaria]  WITH CHECK ADD  CONSTRAINT [CK_Maquinaria_Estado] CHECK  (([Estado]='BajaDefinitiva' OR [Estado]='Inactiva' OR [Estado]='EnMantenimiento' OR [Estado]='Activa'))
GO
ALTER TABLE [Produccion].[Maquinaria] CHECK CONSTRAINT [CK_Maquinaria_Estado]
GO
ALTER TABLE [Produccion].[OrdenesProduccion]  WITH CHECK ADD CHECK  (([CantidadProgramada]>(0)))
GO
ALTER TABLE [Produccion].[RecetaBOM]  WITH CHECK ADD CHECK  (([CantidadRendimientoBase]>(0)))
GO
ALTER TABLE [Produccion].[RecetaBOM_Detalle]  WITH CHECK ADD CHECK  (([CantidadRequerida]>(0)))
GO
ALTER TABLE [Proyectos].[TareaDependencias]  WITH CHECK ADD  CONSTRAINT [CK_TareaDependencias_NoAutoDependencia] CHECK  (([TareaID]<>[DependeDeTareaID]))
GO
ALTER TABLE [Proyectos].[TareaDependencias] CHECK CONSTRAINT [CK_TareaDependencias_NoAutoDependencia]
GO
ALTER TABLE [Rrhh].[HorarioDias]  WITH CHECK ADD  CONSTRAINT [CK_HorarioDias_DiaSemana] CHECK  (([DiaSemana]>=(1) AND [DiaSemana]<=(7)))
GO
ALTER TABLE [Rrhh].[HorarioDias] CHECK CONSTRAINT [CK_HorarioDias_DiaSemana]
GO
ALTER TABLE [Rrhh].[HorarioDias]  WITH CHECK ADD  CONSTRAINT [CK_HorarioDias_Semana] CHECK  (([Semana] IS NULL OR ([Semana]='D' OR [Semana]='C' OR [Semana]='B' OR [Semana]='A')))
GO
ALTER TABLE [Rrhh].[HorarioDias] CHECK CONSTRAINT [CK_HorarioDias_Semana]
GO
ALTER TABLE [Rrhh].[RegistroAsistencia]  WITH CHECK ADD  CONSTRAINT [CK_MetodoEntrada] CHECK  (([MetodoEntrada]='MANUAL' OR [MetodoEntrada]='QR' OR [MetodoEntrada] IS NULL))
GO
ALTER TABLE [Rrhh].[RegistroAsistencia] CHECK CONSTRAINT [CK_MetodoEntrada]
GO
ALTER TABLE [Rrhh].[RegistroAsistencia]  WITH CHECK ADD  CONSTRAINT [CK_MetodoSalida] CHECK  (([MetodoSalida]='MANUAL' OR [MetodoSalida]='QR' OR [MetodoSalida] IS NULL))
GO
ALTER TABLE [Rrhh].[RegistroAsistencia] CHECK CONSTRAINT [CK_MetodoSalida]
GO
ALTER TABLE [Soporte].[EncuestasNPS]  WITH CHECK ADD CHECK  (([Puntuacion]>=(0) AND [Puntuacion]<=(10)))
GO
/****** Object:  StoredProcedure [Compras].[sp_RecibirOrdenCompra]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================================================
-- SP: sp_RecibirOrdenCompra
-- Entrada de materia prima por compra: crea lote, actualiza stock, kardex
-- y recalcula costo promedio ponderado del articulo.
-- ============================================================================
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
    DECLARE @CostoPromedioPrevio DECIMAL(18,4) = (SELECT CostoPromedio FROM Catalogo.Tarjetas WHERE ArticuloID = @ArticuloID);
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

    UPDATE Catalogo.Tarjetas SET CostoPromedio = @NuevoCostoPromedio WHERE ArticuloID = @ArticuloID;

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
/****** Object:  StoredProcedure [Facturacion].[sp_DescontarStockFactura]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [Facturacion].[sp_DescontarStockFactura]
    @FacturaID INT,
    @UsuarioID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM Facturacion.Facturas WHERE FacturaID = @FacturaID)
        THROW 57001, 'Factura no encontrada.', 1;

    IF EXISTS (SELECT 1 FROM Facturacion.Facturas WHERE FacturaID = @FacturaID AND StockDescontado = 1)
        THROW 57002, 'El stock de esta factura ya fue descontado anteriormente.', 1;

    IF NOT EXISTS (SELECT 1 FROM Facturacion.FacturaLineas WHERE FacturaID = @FacturaID)
        THROW 57003, 'La factura no tiene lineas de articulos.', 1;

    -- Valida stock solo de lineas con articulo (combos no mueven stock)
    DECLARE @ArticulosSinStock NVARCHAR(2000);
    SELECT @ArticulosSinStock = STRING_AGG(a.SKU + ' - ' + a.Nombre
        + ' (necesario: ' + CAST(fl.Cantidad AS NVARCHAR(20))
        + ', disponible: ' + CAST(ISNULL(s.Total, 0) AS NVARCHAR(20)) + ')', '; ')
    FROM Facturacion.FacturaLineas fl
    JOIN Catalogo.Tarjetas a ON a.ArticuloID = fl.ArticuloID
    LEFT JOIN (
        SELECT ArticuloID, SUM(CantidadActual) AS Total
        FROM Inventario.InventarioStock
        GROUP BY ArticuloID
    ) s ON s.ArticuloID = fl.ArticuloID
    WHERE fl.FacturaID = @FacturaID
      AND fl.ArticuloID IS NOT NULL
      AND fl.Cantidad > ISNULL(s.Total, 0);

    IF @ArticulosSinStock IS NOT NULL
    BEGIN
        DECLARE @MsgStock NVARCHAR(2100) = 'Stock insuficiente: ' + @ArticulosSinStock;
        THROW 57004, @MsgStock, 1;
    END

    DECLARE @TipoSalida INT = (SELECT TipoMovID FROM Kardex.TiposMovimientoKardex WHERE Codigo = 'SALIDA_VENTA_FACTURA');

    BEGIN TRANSACTION;

    DECLARE @ArticuloID INT, @CantidadLinea DECIMAL(18,4);

    DECLARE curLineas CURSOR LOCAL FAST_FORWARD FOR
        SELECT ArticuloID, Cantidad
        FROM Facturacion.FacturaLineas
        WHERE FacturaID = @FacturaID AND ArticuloID IS NOT NULL;

    OPEN curLineas;
    FETCH NEXT FROM curLineas INTO @ArticuloID, @CantidadLinea;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @Pendiente DECIMAL(18,4) = @CantidadLinea;
        DECLARE @InvID INT, @LoteID INT, @BodegaID INT, @CentroCostoID INT, @CantidadLote DECIMAL(18,4), @CostoLote DECIMAL(18,4);

        DECLARE curLotes CURSOR LOCAL FAST_FORWARD FOR
            SELECT s.InventarioID, s.LoteID, s.BodegaID, b.CentroCostoID, s.CantidadActual, s.CostoUnitarioLote
            FROM Inventario.InventarioStock s
            JOIN Inventario.Bodegas b ON b.BodegaID = s.BodegaID
            LEFT JOIN Inventario.Lotes l ON l.LoteID = s.LoteID
            WHERE s.ArticuloID = @ArticuloID AND s.CantidadActual > 0
              AND (l.Estado IS NULL OR l.Estado = 'APROBADO')
            ORDER BY ISNULL(l.FechaVencimiento, '9999-12-31') ASC, s.InventarioID ASC;

        OPEN curLotes;
        FETCH NEXT FROM curLotes INTO @InvID, @LoteID, @BodegaID, @CentroCostoID, @CantidadLote, @CostoLote;

        WHILE @@FETCH_STATUS = 0 AND @Pendiente > 0
        BEGIN
            DECLARE @Tomar DECIMAL(18,4) = CASE WHEN @CantidadLote >= @Pendiente THEN @Pendiente ELSE @CantidadLote END;

            UPDATE Inventario.InventarioStock
            SET CantidadActual = CantidadActual - @Tomar, FechaUltimaActualizacion = SYSUTCDATETIME()
            WHERE InventarioID = @InvID;

            DECLARE @NuevoSaldo DECIMAL(18,4) = (
                SELECT SUM(CantidadActual) FROM Inventario.InventarioStock WHERE ArticuloID = @ArticuloID AND BodegaID = @BodegaID
            );

            INSERT INTO Kardex.KardexMovimientos
                (ArticuloID, BodegaID, LoteID, TipoMovID, CentroCostoID, Cantidad, CostoUnitario, CantidadSaldo, CostoPromedioSaldo, ObservacionDetallada, UsuarioID)
            VALUES
                (@ArticuloID, @BodegaID, @LoteID, @TipoSalida, @CentroCostoID, @Tomar, @CostoLote, @NuevoSaldo, @CostoLote,
                 CONCAT('Factura #', @FacturaID), @UsuarioID);

            SET @Pendiente -= @Tomar;
            FETCH NEXT FROM curLotes INTO @InvID, @LoteID, @BodegaID, @CentroCostoID, @CantidadLote, @CostoLote;
        END
        CLOSE curLotes; DEALLOCATE curLotes;

        FETCH NEXT FROM curLineas INTO @ArticuloID, @CantidadLinea;
    END
    CLOSE curLineas; DEALLOCATE curLineas;

    UPDATE Facturacion.Facturas SET StockDescontado = 1 WHERE FacturaID = @FacturaID;

    COMMIT TRANSACTION;

    SELECT @FacturaID AS FacturaID;
END;

GO
/****** Object:  StoredProcedure [Integracion].[sp_ProcesarDevolucionVisions]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
-- 4) SP para procesar devoluciones de cliente desde Visions (NOTA DEVOLUCION)
--    Equivalente a sp_ProcesarEventoEntrante pero SUMA stock en vez de restarlo.
CREATE   PROCEDURE [Integracion].[sp_ProcesarDevolucionVisions]
    @EventoEntranteID BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CentroCostoID INT, @CodigoArticuloVisions NVARCHAR(30), @Cantidad DECIMAL(18,4),
            @Procesado BIT, @CostoVisions DECIMAL(18,4), @PrecioVisions DECIMAL(18,4),
            @TipDoc NVARCHAR(20), @NroDoc NVARCHAR(50);

    SELECT
        @CentroCostoID          = CentroCostoID,
        @CodigoArticuloVisions  = CodigoArticuloVisions,
        @Cantidad               = Cantidad,
        @Procesado              = Procesado,
        @CostoVisions           = CostoArticuloVisions,
        @PrecioVisions          = PrecioArticuloVisions,
        @TipDoc                 = TipDoc,
        @NroDoc                 = NroDoc
    FROM Integracion.EventosEntrantes
    WHERE EventoEntranteID = @EventoEntranteID;

    IF @Procesado = 1 RETURN;

    DECLARE @ArticuloID INT = (
        SELECT ArticuloID FROM Integracion.MapeoArticulos
        WHERE CodigoArticuloVisions = @CodigoArticuloVisions AND CentroCostoID = @CentroCostoID AND Estado = 1);

    IF @ArticuloID IS NULL
        THROW 54000, 'Articulo no mapeado; no se puede procesar devolucion.', 1;

    DECLARE @BodegaVentaID INT = (SELECT BodegaVentaVisionsID FROM Organizacion.CentrosCosto WHERE CentroCostoID = @CentroCostoID);
    IF @BodegaVentaID IS NULL
        THROW 54001, 'El Centro de Costo no tiene Bodega de Venta Visions configurada.', 1;

    DECLARE @TipoEntrada INT = (SELECT TipoMovID FROM Kardex.TiposMovimientoKardex WHERE Codigo = 'ENTRADA_DEVOLUCION_VISIONS');
    DECLARE @UsuarioSistemaID INT = (SELECT UsuarioID FROM Seguridad.Usuarios WHERE Username = 'sistema.sync');
    DECLARE @Costo DECIMAL(18,4) = COALESCE(@CostoVisions, 0);

    BEGIN TRANSACTION;

    -- Sumar stock (sin FEFO: devoluciones van a fila sin lote especifico)
    MERGE Inventario.InventarioStock AS dest
    USING (SELECT @ArticuloID AS ArticuloID, @BodegaVentaID AS BodegaID) AS src
    ON dest.ArticuloID = src.ArticuloID AND dest.BodegaID = src.BodegaID AND dest.LoteID IS NULL
    WHEN MATCHED THEN
        UPDATE SET CantidadActual = CantidadActual + @Cantidad, FechaUltimaActualizacion = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN
        INSERT (ArticuloID, BodegaID, LoteID, CantidadActual, CostoUnitarioLote, FechaUltimaActualizacion)
        VALUES (@ArticuloID, @BodegaVentaID, NULL, @Cantidad, @Costo, SYSUTCDATETIME());

    DECLARE @NuevoSaldo DECIMAL(18,4) = (
        SELECT SUM(CantidadActual) FROM Inventario.InventarioStock
        WHERE ArticuloID = @ArticuloID AND BodegaID = @BodegaVentaID);

    INSERT INTO Kardex.KardexMovimientos
        (ArticuloID, BodegaID, LoteID, TipoMovID, CentroCostoID, Cantidad, CostoUnitario,
         CantidadSaldo, CostoPromedioSaldo, ObservacionDetallada, UsuarioID)
    VALUES
        (@ArticuloID, @BodegaVentaID, NULL, @TipoEntrada, @CentroCostoID, @Cantidad, @Costo,
         @NuevoSaldo, @Costo,
         CONCAT('Devolucion cliente Visions - ', ISNULL(@TipDoc,''), ' ', ISNULL(@NroDoc,''), ' - Evento #', @EventoEntranteID),
         @UsuarioSistemaID);

    -- Registrar en Facturacion.Devoluciones para trazabilidad
    IF NOT EXISTS (SELECT 1 FROM Facturacion.Devoluciones WHERE EventoEntranteID = @EventoEntranteID)
    BEGIN
        DECLARE @DevID INT;
        INSERT INTO Facturacion.Devoluciones
            (TipoDevolucion, CentroCostoID, Fecha, Motivo, NroDoc, Total, StockRestituido, OrigenVisions, EventoEntranteID, UsuarioID)
        VALUES
            ('CLIENTE', @CentroCostoID, CAST(GETDATE() AS DATE),
             CONCAT('Devolucion Visions ', ISNULL(@TipDoc,''), ' ', ISNULL(@NroDoc,'')),
             @NroDoc, @Cantidad * @Costo, 1, 1, @EventoEntranteID, @UsuarioSistemaID);

        SET @DevID = SCOPE_IDENTITY();

        INSERT INTO Facturacion.DevolucionLineas (DevolucionID, ArticuloID, Cantidad, CostoUnitario)
        VALUES (@DevID, @ArticuloID, @Cantidad, @Costo);
    END

    UPDATE Integracion.EventosEntrantes
    SET Procesado = 1, FechaProcesado = SYSUTCDATETIME()
    WHERE EventoEntranteID = @EventoEntranteID;

    COMMIT TRANSACTION;
END

GO
/****** Object:  StoredProcedure [Integracion].[sp_ProcesarEventoEntrante]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ----------------------------------------------------------------------------
-- SP: procesa un evento entrante (venta reportada por Visions) y actualiza
-- el acumulado de reporte. Idempotente: si el IdEventoExterno ya existe,
-- no hace nada (lo detecta el INSERT con UNIQUE antes de llamar este SP).
-- ----------------------------------------------------------------------------
CREATE   PROCEDURE [Integracion].[sp_ProcesarEventoEntrante]
    @EventoEntranteID BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ArticuloID INT, @CentroCostoID INT, @Cantidad DECIMAL(18,4), @Procesado BIT;

    -- Intenta resolver el articulo primero por MapeoArticulos (mapeo explicito)
    -- y como fallback por Catalogo.Tarjetas.Referencia (articulos cuya referencia
    -- coincide directamente con el codigo que usa Visions, sin necesidad de mapear).
    SELECT
        @ArticuloID = COALESCE(m.ArticuloID, t.ArticuloID),
        @CentroCostoID = e.CentroCostoID,
        @Cantidad = e.Cantidad,
        @Procesado = e.Procesado
    FROM Integracion.EventosEntrantes e
    LEFT JOIN Integracion.MapeoArticulos m
        ON m.CodigoArticuloVisions = e.CodigoArticuloVisions AND m.CentroCostoID = e.CentroCostoID
    LEFT JOIN Catalogo.Tarjetas t
        ON t.Referencia = e.CodigoArticuloVisions
    WHERE e.EventoEntranteID = @EventoEntranteID;

    IF @ArticuloID IS NULL
        THROW 54000, 'No existe mapeo de articulo para este evento entrante; revisar Integracion.MapeoArticulos o asegurar que la Referencia del articulo coincida con el codigo en Visions.', 1;

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
/****** Object:  StoredProcedure [Integracion].[sp_RegistrarLatido]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [Integracion].[sp_RegistrarLatido]
    @AgenteSyncID INT,
    @VersionAgente NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Integracion.AgentesSync
    SET UltimaConexion = SYSUTCDATETIME(),
        UltimoLatido   = SYSUTCDATETIME(),
        VersionAgente  = ISNULL(@VersionAgente, VersionAgente)
    WHERE AgenteSyncID = @AgenteSyncID AND Activo = 1;
    
    IF @@ROWCOUNT = 0
        THROW 58001, 'El agente no existe o esta desactivado.', 1;
END;

GO
/****** Object:  StoredProcedure [Inventario].[sp_CrearYEnviarTraspaso]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================================================
-- SP: sp_EnviarTraspaso / sp_RecibirTraspaso
-- Traspasos entre bodegas/centros de costo (planta central -> sucursales)
-- ============================================================================
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

    DECLARE @ArticuloID INT, @LoteIDPedido INT, @Cantidad DECIMAL(18,4);
    DECLARE @TipoSalida INT = (SELECT TipoMovID FROM Kardex.TiposMovimientoKardex WHERE Codigo='TRASPASO_SALIDA');
    DECLARE @CentroCostoOrigen INT = (SELECT CentroCostoID FROM Inventario.Bodegas WHERE BodegaID = @BodegaOrigenID);

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT ArticuloID, LoteID, Cantidad FROM OPENJSON(@DetalleJSON)
        WITH (ArticuloID INT, LoteID INT, Cantidad DECIMAL(18,4));
    OPEN cur; FETCH NEXT FROM cur INTO @ArticuloID, @LoteIDPedido, @Cantidad;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @LoteIDPedido IS NOT NULL
        BEGIN
            -- Se pidio un lote especifico: comportamiento exacto anterior.
            DECLARE @Disponible DECIMAL(18,4), @CostoUnitario DECIMAL(18,4), @InventarioID BIGINT;
            SELECT @Disponible = CantidadActual, @CostoUnitario = CostoUnitarioLote, @InventarioID = InventarioID
            FROM Inventario.InventarioStock
            WHERE ArticuloID = @ArticuloID AND BodegaID = @BodegaOrigenID AND LoteID = @LoteIDPedido;

            IF @Disponible IS NULL OR @Disponible < @Cantidad
            BEGIN
                ROLLBACK TRANSACTION;
                THROW 53000, 'Stock insuficiente para el traspaso de al menos un articulo.', 1;
            END

            UPDATE Inventario.InventarioStock SET CantidadActual = CantidadActual - @Cantidad, FechaUltimaActualizacion = SYSUTCDATETIME()
            WHERE InventarioID = @InventarioID;

            INSERT INTO Inventario.TraspasosDetalle (TraspasoID, ArticuloID, LoteID, CantidadEnviada, CostoUnitario)
            VALUES (@TraspasoID, @ArticuloID, @LoteIDPedido, @Cantidad, @CostoUnitario);

            DECLARE @NuevoSaldo1 DECIMAL(18,4) = (SELECT SUM(CantidadActual) FROM Inventario.InventarioStock WHERE ArticuloID=@ArticuloID AND BodegaID=@BodegaOrigenID);

            INSERT INTO Kardex.KardexMovimientos
                (ArticuloID, BodegaID, LoteID, TipoMovID, TraspasoID, CentroCostoID, Cantidad, CostoUnitario, CantidadSaldo, CostoPromedioSaldo, ObservacionDetallada, UsuarioID)
            VALUES
                (@ArticuloID, @BodegaOrigenID, @LoteIDPedido, @TipoSalida, @TraspasoID, @CentroCostoOrigen, @Cantidad, @CostoUnitario, @NuevoSaldo1, @CostoUnitario,
                 CONCAT('Envio por traspaso ', @Codigo), @UsuarioEnviaID);
        END
        ELSE
        BEGIN
            -- No se pidio un lote especifico (caso normal desde la UI, que no
            -- deja elegir lote): se toma de TODOS los lotes disponibles por
            -- FEFO -- igual criterio que sp_IniciarOrdenProduccion -- porque
            -- casi todo el stock real tiene lote (Compras y Produccion
            -- siempre asignan uno). Antes esto SIEMPRE fallaba con "stock
            -- insuficiente" para cualquier articulo con lote.
            DECLARE @Pendiente DECIMAL(18,4) = @Cantidad;
            DECLARE @LoteID INT, @CantidadLote DECIMAL(18,4), @CostoLote DECIMAL(18,4), @InvID BIGINT;

            DECLARE curLotes CURSOR LOCAL FAST_FORWARD FOR
                SELECT s.InventarioID, s.LoteID, s.CantidadActual, s.CostoUnitarioLote
                FROM Inventario.InventarioStock s
                LEFT JOIN Inventario.Lotes l ON l.LoteID = s.LoteID
                WHERE s.ArticuloID = @ArticuloID AND s.BodegaID = @BodegaOrigenID AND s.CantidadActual > 0
                      AND (l.Estado IS NULL OR l.Estado = 'APROBADO')
                ORDER BY ISNULL(l.FechaVencimiento,'9999-12-31') ASC; -- FEFO

            OPEN curLotes;
            FETCH NEXT FROM curLotes INTO @InvID, @LoteID, @CantidadLote, @CostoLote;

            WHILE @@FETCH_STATUS = 0 AND @Pendiente > 0
            BEGIN
                DECLARE @Tomar DECIMAL(18,4) = CASE WHEN @CantidadLote >= @Pendiente THEN @Pendiente ELSE @CantidadLote END;

                UPDATE Inventario.InventarioStock SET CantidadActual = CantidadActual - @Tomar, FechaUltimaActualizacion = SYSUTCDATETIME()
                WHERE InventarioID = @InvID;

                INSERT INTO Inventario.TraspasosDetalle (TraspasoID, ArticuloID, LoteID, CantidadEnviada, CostoUnitario)
                VALUES (@TraspasoID, @ArticuloID, @LoteID, @Tomar, @CostoLote);

                DECLARE @NuevoSaldo2 DECIMAL(18,4) = (SELECT SUM(CantidadActual) FROM Inventario.InventarioStock WHERE ArticuloID=@ArticuloID AND BodegaID=@BodegaOrigenID);

                INSERT INTO Kardex.KardexMovimientos
                    (ArticuloID, BodegaID, LoteID, TipoMovID, TraspasoID, CentroCostoID, Cantidad, CostoUnitario, CantidadSaldo, CostoPromedioSaldo, ObservacionDetallada, UsuarioID)
                VALUES
                    (@ArticuloID, @BodegaOrigenID, @LoteID, @TipoSalida, @TraspasoID, @CentroCostoOrigen, @Tomar, @CostoLote, @NuevoSaldo2, @CostoLote,
                     CONCAT('Envio por traspaso ', @Codigo), @UsuarioEnviaID);

                SET @Pendiente -= @Tomar;
                FETCH NEXT FROM curLotes INTO @InvID, @LoteID, @CantidadLote, @CostoLote;
            END
            CLOSE curLotes; DEALLOCATE curLotes;

            IF @Pendiente > 0
            BEGIN
                ROLLBACK TRANSACTION;
                CLOSE cur; DEALLOCATE cur;
                THROW 53000, 'Stock insuficiente para el traspaso de al menos un articulo.', 1;
            END
        END

        FETCH NEXT FROM cur INTO @ArticuloID, @LoteIDPedido, @Cantidad;
    END
    CLOSE cur; DEALLOCATE cur;

    COMMIT TRANSACTION;
    SELECT 'OK' AS Resultado, @TraspasoID AS TraspasoID, @Codigo AS Codigo;
END
GO
/****** Object:  StoredProcedure [Inventario].[sp_RecibirTraspaso]    Script Date: 1/09/2026 5:35:42 p. m. ******/
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
/****** Object:  StoredProcedure [Kardex].[sp_AjustePositivoInventario]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [Kardex].[sp_AjustePositivoInventario]
    @ArticuloID INT,
    @BodegaID INT,
    @Cantidad DECIMAL(18,4),
    @CostoUnitario DECIMAL(18,4),
    @Motivo NVARCHAR(300),
    @UsuarioID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Cantidad IS NULL OR @Cantidad <= 0
        THROW 54000, 'La cantidad a ajustar debe ser mayor a cero.', 1;

    IF @CostoUnitario IS NULL OR @CostoUnitario < 0
        THROW 54001, 'El costo unitario no puede ser negativo.', 1;

    IF @Motivo IS NULL OR LEN(TRIM(@Motivo)) < 5
        THROW 54002, 'Debe indicar un motivo de al menos 5 caracteres.', 1;

    DECLARE @CentroCostoID INT = (SELECT CentroCostoID FROM Inventario.Bodegas WHERE BodegaID = @BodegaID);
    IF @CentroCostoID IS NULL
        THROW 54003, 'La bodega indicada no existe.', 1;

    IF NOT EXISTS (SELECT 1 FROM Catalogo.Tarjetas WHERE ArticuloID = @ArticuloID)
        THROW 54004, 'El articulo indicado no existe.', 1;

    BEGIN TRANSACTION;

    DECLARE @CodigoAjuste NVARCHAR(30) = CONCAT('AJU-', FORMAT(SYSUTCDATETIME(),'yyyyMMddHHmmss'));
    DECLARE @AjusteID INT;

    INSERT INTO Kardex.AjustesInventario
        (CodigoAjuste, Fecha, ArticuloID, BodegaID, LoteID, CantidadAjustada, CostoUnitario, Motivo, UsuarioRegistraID)
    VALUES
        (@CodigoAjuste, SYSUTCDATETIME(), @ArticuloID, @BodegaID, NULL, @Cantidad, @CostoUnitario, @Motivo, @UsuarioID);
    SET @AjusteID = SCOPE_IDENTITY();

    -- Se ajusta siempre sobre el "cubo" de stock sin lote especifico (LoteID NULL),
    -- igual que hacen las bajas cuando no se indica un lote.
    MERGE Inventario.InventarioStock AS destino
    USING (SELECT @ArticuloID AS ArticuloID, @BodegaID AS BodegaID) AS origen
    ON destino.ArticuloID = origen.ArticuloID AND destino.BodegaID = origen.BodegaID AND destino.LoteID IS NULL
    WHEN MATCHED THEN
        UPDATE SET CantidadActual = destino.CantidadActual + @Cantidad, FechaUltimaActualizacion = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN
        INSERT (ArticuloID, BodegaID, LoteID, CantidadActual, CostoUnitarioLote, FechaUltimaActualizacion)
        VALUES (@ArticuloID, @BodegaID, NULL, @Cantidad, @CostoUnitario, SYSUTCDATETIME());

    -- Recalcula el costo promedio ponderado del articulo, igual criterio que las compras.
    DECLARE @StockTotalActual DECIMAL(18,4) = Catalogo.fn_StockTotalArticulo(@ArticuloID);
    DECLARE @StockPrevio DECIMAL(18,4) = @StockTotalActual - @Cantidad;
    DECLARE @CostoPromedioPrevio DECIMAL(18,4) = (SELECT CostoPromedio FROM Catalogo.Tarjetas WHERE ArticuloID = @ArticuloID);
    DECLARE @NuevoCostoPromedio DECIMAL(18,4) =
        CASE WHEN @StockPrevio IS NULL OR @StockPrevio <= 0 OR @CostoPromedioPrevio IS NULL THEN @CostoUnitario
             ELSE ((@StockPrevio * @CostoPromedioPrevio) + (@Cantidad * @CostoUnitario)) / (@StockPrevio + @Cantidad)
        END;

    UPDATE Catalogo.Tarjetas SET CostoPromedio = @NuevoCostoPromedio WHERE ArticuloID = @ArticuloID;

    DECLARE @NuevoSaldo DECIMAL(18,4) = (SELECT SUM(CantidadActual) FROM Inventario.InventarioStock WHERE ArticuloID = @ArticuloID AND BodegaID = @BodegaID);
    DECLARE @TipoAjuste INT = (SELECT TipoMovID FROM Kardex.TiposMovimientoKardex WHERE Codigo = 'AJU_INV');

    INSERT INTO Kardex.KardexMovimientos
        (ArticuloID, BodegaID, LoteID, TipoMovID, AjusteID, CentroCostoID,
         Cantidad, CostoUnitario, CantidadSaldo, CostoPromedioSaldo, ObservacionDetallada, UsuarioID)
    VALUES
        (@ArticuloID, @BodegaID, NULL, @TipoAjuste, @AjusteID, @CentroCostoID,
         @Cantidad, @CostoUnitario, @NuevoSaldo, @NuevoCostoPromedio, @Motivo, @UsuarioID);

    COMMIT TRANSACTION;

    -- Solo las columnas que coinciden con AjustarInventarioResponse (Dapper exige
    -- que el set de columnas calce exactamente con el constructor del record).
    SELECT @CodigoAjuste AS CodigoAjuste, @AjusteID AS AjusteID, @NuevoSaldo AS NuevoSaldo;
END

GO
/****** Object:  StoredProcedure [Kardex].[sp_RegistrarBajaInventario]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================================================
-- SP: sp_RegistrarBajaInventario
-- Registro de perdida/dano accidental. Descuenta stock, crea KARDEX y deja
-- la observacion detallada auditable, sin afectar costeo de OP activas.
-- ============================================================================
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
/****** Object:  StoredProcedure [Logistica].[sp_AnularDespacho]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE   PROCEDURE [Logistica].[sp_AnularDespacho]
    @DespachoID INT,
    @UsuarioID INT,
    @Motivo NVARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EstadoActual NVARCHAR(20) = (SELECT Estado FROM Logistica.Despachos WHERE DespachoID = @DespachoID);

    IF @EstadoActual IS NULL
        THROW 56002, 'El despacho no existe.', 1;

    IF @EstadoActual <> 'DESPACHADO'
        THROW 56003, 'Solo se puede anular un despacho en estado DESPACHADO -- ya fue entregado o ya estaba anulado.', 1;

    DECLARE @TipoEntradaAnulacion INT = (SELECT TipoMovID FROM Kardex.TiposMovimientoKardex WHERE Codigo = 'ENTRADA_ANULACION_DESPACHO');
    DECLARE @TipoSalidaDespacho INT = (SELECT TipoMovID FROM Kardex.TiposMovimientoKardex WHERE Codigo = 'SALIDA_DESPACHO');

    BEGIN TRANSACTION;

    -- Revierte, lote por lote, cada movimiento de salida que genero este
    -- despacho -- se identifican por ObservacionDetallada (no hay una FK
    -- directa Kardex->Despacho, se sigue el mismo patron de texto usado al crearlos).
    DECLARE @ArticuloID INT, @BodegaID INT, @LoteID INT, @CentroCostoID INT, @Cantidad DECIMAL(18,4), @CostoUnitario DECIMAL(18,4);

    DECLARE curMovs CURSOR LOCAL FAST_FORWARD FOR
        SELECT ArticuloID, BodegaID, LoteID, CentroCostoID, Cantidad, CostoUnitario
        FROM Kardex.KardexMovimientos
        WHERE TipoMovID = @TipoSalidaDespacho
          AND ObservacionDetallada = CONCAT('Despacho #', @DespachoID);

    OPEN curMovs;
    FETCH NEXT FROM curMovs INTO @ArticuloID, @BodegaID, @LoteID, @CentroCostoID, @Cantidad, @CostoUnitario;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF EXISTS (
            SELECT 1 FROM Inventario.InventarioStock
            WHERE ArticuloID = @ArticuloID AND BodegaID = @BodegaID AND ((@LoteID IS NULL AND LoteID IS NULL) OR LoteID = @LoteID)
        )
        BEGIN
            UPDATE Inventario.InventarioStock
            SET CantidadActual = CantidadActual + @Cantidad, FechaUltimaActualizacion = SYSUTCDATETIME()
            WHERE ArticuloID = @ArticuloID AND BodegaID = @BodegaID AND ((@LoteID IS NULL AND LoteID IS NULL) OR LoteID = @LoteID);
        END
        ELSE
        BEGIN
            INSERT INTO Inventario.InventarioStock (ArticuloID, BodegaID, LoteID, CantidadActual, CostoUnitarioLote)
            VALUES (@ArticuloID, @BodegaID, @LoteID, @Cantidad, @CostoUnitario);
        END

        DECLARE @NuevoSaldo DECIMAL(18,4) = (SELECT SUM(CantidadActual) FROM Inventario.InventarioStock WHERE ArticuloID = @ArticuloID AND BodegaID = @BodegaID);

        INSERT INTO Kardex.KardexMovimientos
            (ArticuloID, BodegaID, LoteID, TipoMovID, CentroCostoID, Cantidad, CostoUnitario, CantidadSaldo, CostoPromedioSaldo, ObservacionDetallada, UsuarioID)
        VALUES
            (@ArticuloID, @BodegaID, @LoteID, @TipoEntradaAnulacion, @CentroCostoID, @Cantidad, @CostoUnitario, @NuevoSaldo, @CostoUnitario,
             CONCAT('Anulacion Despacho #', @DespachoID, CASE WHEN @Motivo IS NOT NULL THEN ' - ' + @Motivo ELSE '' END), @UsuarioID);

        FETCH NEXT FROM curMovs INTO @ArticuloID, @BodegaID, @LoteID, @CentroCostoID, @Cantidad, @CostoUnitario;
    END
    CLOSE curMovs; DEALLOCATE curMovs;

    UPDATE Logistica.Despachos
    SET Estado = 'ANULADO', MotivoAnulacion = @Motivo, FechaAnulacion = SYSUTCDATETIME(), UsuarioAnulaID = @UsuarioID
    WHERE DespachoID = @DespachoID;

    COMMIT TRANSACTION;
END

GO
/****** Object:  StoredProcedure [Logistica].[sp_CrearDespacho]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [Logistica].[sp_CrearDespacho]
    @ClienteID      INT,
    @CentroCostoID  INT,
    @BodegaOrigenID INT,
    @UsuarioID      INT,
    @Direccion      NVARCHAR(200) = NULL,
    @Observaciones  NVARCHAR(500) = NULL,
    @LineasJson     NVARCHAR(MAX),
    @DescuentaStock BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM OPENJSON(@LineasJson))
        THROW 56000, 'El despacho debe tener al menos una linea.', 1;

    IF EXISTS (
        SELECT 1 FROM OPENJSON(@LineasJson)
        WITH (Cantidad DECIMAL(18,4) '$.Cantidad')
        WHERE Cantidad <= 0
    )
        THROW 56007, 'Las cantidades del despacho deben ser mayores a cero.', 1;

    IF (SELECT COUNT(*) FROM OPENJSON(@LineasJson)) <>
       (SELECT COUNT(DISTINCT ArticuloID)
        FROM OPENJSON(@LineasJson) WITH (ArticuloID INT '$.ArticuloID'))
        THROW 56006, 'No se puede repetir el mismo articulo en dos lineas del despacho.', 1;

    IF NOT EXISTS (SELECT 1 FROM Crm.Clientes WHERE ClienteID = @ClienteID AND Estado = 1)
        THROW 56004, 'El cliente no existe o esta inactivo.', 1;

    IF NOT EXISTS (SELECT 1 FROM Inventario.Bodegas WHERE BodegaID = @BodegaOrigenID AND CentroCostoID = @CentroCostoID)
        THROW 56005, 'La bodega de origen seleccionada no pertenece al Centro de Costo elegido.', 1;

    IF @DescuentaStock = 1
    BEGIN
        DECLARE @ArticulosSinStock NVARCHAR(MAX);
        SELECT @ArticulosSinStock = STRING_AGG(a.SKU + ' - ' + a.Nombre, ', ')
        FROM OPENJSON(@LineasJson) WITH (ArticuloID INT '$.ArticuloID', Cantidad DECIMAL(18,4) '$.Cantidad') l
        JOIN Catalogo.Tarjetas a ON a.ArticuloID = l.ArticuloID
        WHERE l.Cantidad > ISNULL((
            SELECT SUM(s.CantidadActual) FROM Inventario.InventarioStock s
            WHERE s.ArticuloID = l.ArticuloID AND s.BodegaID = @BodegaOrigenID
        ), 0);

        IF @ArticulosSinStock IS NOT NULL
        BEGIN
            DECLARE @MsgStock NVARCHAR(2000) = 'No hay stock suficiente en la bodega de origen para: ' + @ArticulosSinStock;
            THROW 56001, @MsgStock, 1;
        END
    END

    DECLARE @TipoSalida INT = (
        SELECT TipoMovID FROM Kardex.TiposMovimientoKardex WHERE Codigo = 'SALIDA_DESPACHO'
    );

    BEGIN TRANSACTION;

    INSERT INTO Logistica.Despachos
        (ClienteID, CentroCostoID, BodegaOrigenID, Direccion, Observaciones, UsuarioID, DescuentaStock)
    VALUES
        (@ClienteID, @CentroCostoID, @BodegaOrigenID, @Direccion, @Observaciones, @UsuarioID, @DescuentaStock);

    DECLARE @DespachoID INT = SCOPE_IDENTITY();

    DECLARE @ArticuloID    INT;
    DECLARE @CantidadLinea DECIMAL(18,4);
    DECLARE @ValorUnitario DECIMAL(18,4);

    DECLARE curLineas CURSOR LOCAL FAST_FORWARD FOR
        SELECT ArticuloID, Cantidad, ValorUnitario
        FROM OPENJSON(@LineasJson) WITH (
            ArticuloID    INT            '$.ArticuloID',
            Cantidad      DECIMAL(18,4)  '$.Cantidad',
            ValorUnitario DECIMAL(18,4)  '$.ValorUnitario'
        );

    OPEN curLineas;
    FETCH NEXT FROM curLineas INTO @ArticuloID, @CantidadLinea, @ValorUnitario;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT INTO Logistica.DespachoDetalle (DespachoID, ArticuloID, Cantidad, ValorUnitario)
        VALUES (@DespachoID, @ArticuloID, @CantidadLinea, @ValorUnitario);

        IF @DescuentaStock = 1
        BEGIN
            DECLARE @Pendiente DECIMAL(18,4) = @CantidadLinea;
            DECLARE @InvID BIGINT, @LoteID INT, @CantidadLote DECIMAL(18,4), @CostoLote DECIMAL(18,4);

            DECLARE curLotes CURSOR LOCAL FAST_FORWARD FOR
                SELECT s.InventarioID, s.LoteID, s.CantidadActual, s.CostoUnitarioLote
                FROM Inventario.InventarioStock s
                LEFT JOIN Inventario.Lotes l ON l.LoteID = s.LoteID
                WHERE s.ArticuloID = @ArticuloID AND s.BodegaID = @BodegaOrigenID AND s.CantidadActual > 0
                  AND (l.Estado IS NULL OR l.Estado = 'APROBADO')
                ORDER BY ISNULL(l.FechaVencimiento, '9999-12-31') ASC;

            OPEN curLotes;
            FETCH NEXT FROM curLotes INTO @InvID, @LoteID, @CantidadLote, @CostoLote;

            WHILE @@FETCH_STATUS = 0 AND @Pendiente > 0
            BEGIN
                DECLARE @Tomar DECIMAL(18,4) = CASE WHEN @CantidadLote >= @Pendiente THEN @Pendiente ELSE @CantidadLote END;

                UPDATE Inventario.InventarioStock
                SET CantidadActual = CantidadActual - @Tomar, FechaUltimaActualizacion = SYSUTCDATETIME()
                WHERE InventarioID = @InvID;

                DECLARE @NuevoSaldo DECIMAL(18,4) = (
                    SELECT SUM(CantidadActual) FROM Inventario.InventarioStock
                    WHERE ArticuloID = @ArticuloID AND BodegaID = @BodegaOrigenID
                );

                INSERT INTO Kardex.KardexMovimientos
                    (ArticuloID, BodegaID, LoteID, TipoMovID, CentroCostoID, Cantidad, CostoUnitario,
                     CantidadSaldo, CostoPromedioSaldo, ObservacionDetallada, UsuarioID)
                VALUES
                    (@ArticuloID, @BodegaOrigenID, @LoteID, @TipoSalida, @CentroCostoID, @Tomar, @CostoLote,
                     @NuevoSaldo, @CostoLote, CONCAT('Despacho #', @DespachoID), @UsuarioID);

                SET @Pendiente -= @Tomar;
                FETCH NEXT FROM curLotes INTO @InvID, @LoteID, @CantidadLote, @CostoLote;
            END
            CLOSE curLotes; DEALLOCATE curLotes;
        END

        FETCH NEXT FROM curLineas INTO @ArticuloID, @CantidadLinea, @ValorUnitario;
    END
    CLOSE curLineas; DEALLOCATE curLineas;

    COMMIT TRANSACTION;

    SELECT @DespachoID AS DespachoID;
END

GO
/****** Object:  StoredProcedure [Produccion].[sp_ActualizarOrdenProduccion]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [Produccion].[sp_ActualizarOrdenProduccion]
    @OrdenProduccionID INT,
    @TipoProduccionID INT,
    @ProductoTerminadoID INT,
    @RecetaID INT,
    @CantidadProgramada DECIMAL(18,4),
    @ClienteID INT = NULL,
    @CentroCostoDestinoID INT,
    @BodegaOrigenMPID INT,
    @BodegaDestinoPTID INT,
    @CentroTrabajoID INT = NULL,
    @FechaPlanificada DATETIME2 = NULL,
    @Observaciones NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EstadoActual NVARCHAR(30);
    SELECT @EstadoActual = e.Nombre
    FROM Produccion.OrdenesProduccion op
    JOIN Produccion.EstadosOP e ON e.EstadoOPID = op.EstadoOPID
    WHERE op.OrdenProduccionID = @OrdenProduccionID;

    IF @EstadoActual IS NULL
        THROW 51040, 'La orden de produccion no existe.', 1;

    IF @EstadoActual <> 'Planificada'
        THROW 51041, 'Solo se pueden editar ordenes en estado Planificada (antes de liberarlas).', 1;

    UPDATE Produccion.OrdenesProduccion
    SET TipoProduccionID = @TipoProduccionID,
        ProductoTerminadoID = @ProductoTerminadoID,
        RecetaID = @RecetaID,
        CantidadProgramada = @CantidadProgramada,
        ClienteID = @ClienteID,
        CentroCostoDestinoID = @CentroCostoDestinoID,
        BodegaOrigenMPID = @BodegaOrigenMPID,
        BodegaDestinoPTID = @BodegaDestinoPTID,
        CentroTrabajoID = @CentroTrabajoID,
        FechaPlanificada = @FechaPlanificada,
        Observaciones = @Observaciones
    WHERE OrdenProduccionID = @OrdenProduccionID;

    SELECT 'OK' AS Resultado;
END

GO
/****** Object:  StoredProcedure [Produccion].[sp_AjustarConsumoReal]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================================================
-- SP: sp_AjustarConsumoReal
-- Permite corregir la cantidad real consumida de un insumo dentro de una OP
-- En Proceso. Si CantidadReal > CantidadTeorica exige justificacion.
--
-- IMPORTANTE: no basta con actualizar el numero guardado -- el ajuste debe
-- reflejarse en InventarioStock y en Kardex, porque sp_IniciarOrdenProduccion
-- ya desconto la cantidad TEORICA del stock. Si el consumo real es mayor,
-- falta descontar la diferencia (exceso); si es menor, hay que devolverla.
-- ============================================================================
CREATE   PROCEDURE [Produccion].[sp_AjustarConsumoReal]
    @ConsumoID BIGINT,
    @CantidadReal DECIMAL(18,4),
    @MotivoExcesoID INT = NULL,
    @Observacion NVARCHAR(300) = NULL,
    @UsuarioID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Teorica DECIMAL(18,4), @CantidadRealAnterior DECIMAL(18,4), @ArticuloID INT,
            @LoteID INT, @OrdenProduccionID INT, @BodegaID INT, @CentroCostoID INT;

    SELECT @Teorica = c.CantidadTeorica, @CantidadRealAnterior = c.CantidadReal,
           @ArticuloID = c.ArticuloID, @LoteID = c.LoteID, @OrdenProduccionID = c.OrdenProduccionID
    FROM Produccion.OrdenesProduccionConsumo c
    WHERE c.ConsumoID = @ConsumoID;

    IF @Teorica IS NULL
        THROW 51020, 'Registro de consumo no encontrado.', 1;

    IF @CantidadReal <= 0
        THROW 51022, 'La cantidad real debe ser mayor a cero.', 1;

    IF @CantidadReal > @Teorica AND @MotivoExcesoID IS NULL
        THROW 51021, 'Debe indicar un motivo de exceso de consumo cuando la cantidad real supera la teorica.', 1;

    SELECT @BodegaID = op.BodegaOrigenMPID, @CentroCostoID = op.CentroCostoDestinoID
    FROM Produccion.OrdenesProduccion op WHERE op.OrdenProduccionID = @OrdenProduccionID;

    DECLARE @Delta DECIMAL(18,4) = @CantidadReal - @CantidadRealAnterior;

    BEGIN TRANSACTION;

    IF @Delta > 0
    BEGIN
        DECLARE @Disponible DECIMAL(18,4), @CostoUnitLote DECIMAL(18,4), @InventarioID BIGINT;

        SELECT @InventarioID = s.InventarioID, @Disponible = s.CantidadActual, @CostoUnitLote = s.CostoUnitarioLote
        FROM Inventario.InventarioStock s
        WHERE s.ArticuloID = @ArticuloID AND s.BodegaID = @BodegaID
              AND ((@LoteID IS NULL AND s.LoteID IS NULL) OR s.LoteID = @LoteID);

        IF @InventarioID IS NULL OR @Disponible < @Delta
            THROW 51023, 'No hay stock suficiente para cubrir el exceso de consumo ajustado.', 1;

        UPDATE Inventario.InventarioStock
        SET CantidadActual = CantidadActual - @Delta, FechaUltimaActualizacion = SYSUTCDATETIME()
        WHERE InventarioID = @InventarioID;

        DECLARE @NuevoSaldo1 DECIMAL(18,4) = (SELECT SUM(CantidadActual) FROM Inventario.InventarioStock WHERE ArticuloID=@ArticuloID AND BodegaID=@BodegaID);
        DECLARE @TipoSalida INT = (SELECT TipoMovID FROM Kardex.TiposMovimientoKardex WHERE Codigo='SALIDA_WIP');

        INSERT INTO Kardex.KardexMovimientos
            (ArticuloID, BodegaID, LoteID, TipoMovID, OrdenProduccionID, CentroCostoID,
             Cantidad, CostoUnitario, CantidadSaldo, CostoPromedioSaldo, ObservacionDetallada, UsuarioID)
        VALUES
            (@ArticuloID, @BodegaID, @LoteID, @TipoSalida, @OrdenProduccionID, @CentroCostoID,
             @Delta, @CostoUnitLote, @NuevoSaldo1, @CostoUnitLote,
             CONCAT('Ajuste de consumo real en OP #', @OrdenProduccionID, ' (exceso adicional)'), @UsuarioID);
    END
    ELSE IF @Delta < 0
    BEGIN
        DECLARE @Devolver DECIMAL(18,4) = -@Delta;
        DECLARE @CostoUnitDevolucion DECIMAL(18,4) = (
            SELECT TOP 1 CostoUnitarioLote FROM Inventario.InventarioStock
            WHERE ArticuloID = @ArticuloID AND BodegaID = @BodegaID
                  AND ((@LoteID IS NULL AND LoteID IS NULL) OR LoteID = @LoteID)
        );

        MERGE Inventario.InventarioStock AS destino
        USING (SELECT @ArticuloID AS ArticuloID, @BodegaID AS BodegaID, @LoteID AS LoteID) AS origen
        ON destino.ArticuloID = origen.ArticuloID AND destino.BodegaID = origen.BodegaID
           AND ((destino.LoteID IS NULL AND origen.LoteID IS NULL) OR destino.LoteID = origen.LoteID)
        WHEN MATCHED THEN
            UPDATE SET CantidadActual = destino.CantidadActual + @Devolver, FechaUltimaActualizacion = SYSUTCDATETIME()
        WHEN NOT MATCHED THEN
            INSERT (ArticuloID, BodegaID, LoteID, CantidadActual, CostoUnitarioLote, FechaUltimaActualizacion)
            VALUES (@ArticuloID, @BodegaID, @LoteID, @Devolver, ISNULL(@CostoUnitDevolucion,0), SYSUTCDATETIME());

        DECLARE @NuevoSaldo2 DECIMAL(18,4) = (SELECT SUM(CantidadActual) FROM Inventario.InventarioStock WHERE ArticuloID=@ArticuloID AND BodegaID=@BodegaID);
        DECLARE @TipoDevolucion INT = (SELECT TipoMovID FROM Kardex.TiposMovimientoKardex WHERE Codigo='AJU_INV');

        INSERT INTO Kardex.KardexMovimientos
            (ArticuloID, BodegaID, LoteID, TipoMovID, OrdenProduccionID, CentroCostoID,
             Cantidad, CostoUnitario, CantidadSaldo, CostoPromedioSaldo, ObservacionDetallada, UsuarioID)
        VALUES
            (@ArticuloID, @BodegaID, @LoteID, @TipoDevolucion, @OrdenProduccionID, @CentroCostoID,
             @Devolver, ISNULL(@CostoUnitDevolucion,0), @NuevoSaldo2, ISNULL(@CostoUnitDevolucion,0),
             CONCAT('Ajuste de consumo real en OP #', @OrdenProduccionID, ' (devolucion, se uso menos de lo previsto)'), @UsuarioID);
    END

    UPDATE Produccion.OrdenesProduccionConsumo
    SET CantidadReal = @CantidadReal, MotivoExcesoID = @MotivoExcesoID, Observacion = @Observacion
    WHERE ConsumoID = @ConsumoID;

    COMMIT TRANSACTION;
    SELECT 'OK' AS Resultado;
END
GO
/****** Object:  StoredProcedure [Produccion].[sp_CancelarOrdenProduccion]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [Produccion].[sp_CancelarOrdenProduccion]
    @OrdenProduccionID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EstadoActual NVARCHAR(30);
    SELECT @EstadoActual = e.Nombre
    FROM Produccion.OrdenesProduccion op
    JOIN Produccion.EstadosOP e ON e.EstadoOPID = op.EstadoOPID
    WHERE op.OrdenProduccionID = @OrdenProduccionID;

    IF @EstadoActual IS NULL
        THROW 51050, 'La orden de produccion no existe.', 1;

    IF @EstadoActual <> 'Planificada'
        THROW 51051, 'Solo se pueden cancelar ordenes en estado Planificada (aun no liberadas).', 1;

    UPDATE Produccion.OrdenesProduccion
    SET EstadoOPID = (SELECT EstadoOPID FROM Produccion.EstadosOP WHERE Nombre = 'Cancelada')
    WHERE OrdenProduccionID = @OrdenProduccionID;

    SELECT 'OK' AS Resultado;
END

GO
/****** Object:  StoredProcedure [Produccion].[sp_CerrarOrdenProduccion]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================================================
-- SP: sp_CerrarOrdenProduccion
-- Calcula costo real (materiales + MOD + CIF), ingresa el Producto Terminado
-- a la bodega destino, genera KARDEX de entrada y finaliza la OP.
-- ============================================================================
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
    JOIN Catalogo.Tarjetas a ON a.ArticuloID = c.ArticuloID
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

    -- Crear lote del producto terminado
    DECLARE @LoteID INT;
    INSERT INTO Inventario.Lotes (ArticuloID, NumeroLote, FechaFabricacion, FechaVencimiento, Estado)
    VALUES (@ProductoTerminadoID, @NumeroLotePT, CAST(SYSUTCDATETIME() AS DATE), @FechaVencimientoPT, 'APROBADO');
    SET @LoteID = SCOPE_IDENTITY();

    -- Entrada a inventario de producto terminado
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

    -- Actualizar costo promedio ponderado global del articulo terminado
    UPDATE Catalogo.Tarjetas SET CostoPromedio = @CostoUnitarioReal WHERE ArticuloID = @ProductoTerminadoID;

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

    COMMIT TRANSACTION;

    SELECT 'OK' AS Resultado, @CostoUnitarioReal AS CostoUnitarioReal, @LoteID AS LoteProductoTerminadoID;
END
GO
/****** Object:  StoredProcedure [Produccion].[sp_IniciarOrdenProduccion]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================================================
-- SP: sp_IniciarOrdenProduccion
-- Descuenta materia prima (FEFO: primero vence, primero sale) de la bodega
-- de origen, genera KARDEX de salida a WIP y dispara estado En Proceso.
-- ============================================================================
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
        SELECT rd.InsumoID,
               (rd.CantidadRequerida * @FactorEscala) * (1 + rd.PorcentajeMermaEstandar / 100.0)
        FROM Produccion.RecetaBOM_Detalle rd
        WHERE rd.RecetaID = @RecetaID;

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
/****** Object:  StoredProcedure [Produccion].[sp_LiberarOrdenProduccion]    Script Date: 1/09/2026 5:35:42 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================================================
-- SP: sp_LiberarOrdenProduccion
-- Valida stock suficiente de TODOS los insumos de la receta (escalado a la
-- cantidad programada) antes de permitir pasar de Planificada -> Liberada.
-- Si falta stock en cualquier insumo, BLOQUEA y devuelve el detalle faltante.
-- ============================================================================
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

    IF OBJECT_ID('tempdb..#Requerido') IS NOT NULL DROP TABLE #Requerido;
    SELECT
        rd.InsumoID,
        a.Nombre AS NombreInsumo,
        (rd.CantidadRequerida * @FactorEscala) * (1 + rd.PorcentajeMermaEstandar / 100.0) AS CantidadNecesaria
    INTO #Requerido
    FROM Produccion.RecetaBOM_Detalle rd
    JOIN Catalogo.Tarjetas a ON a.ArticuloID = rd.InsumoID
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



USE [NEXO_ERP]
GO
SET IDENTITY_INSERT [catalogo].[Iva] ON 

INSERT [catalogo].[Iva] ([IvaID], [Iva], [Descripcion]) VALUES (1, 0, N'EXENTO')
INSERT [catalogo].[Iva] ([IvaID], [Iva], [Descripcion]) VALUES (2, 5, N'IVA 5%')
INSERT [catalogo].[Iva] ([IvaID], [Iva], [Descripcion]) VALUES (3, 16, N'IVA 16%')
INSERT [catalogo].[Iva] ([IvaID], [Iva], [Descripcion]) VALUES (4, 19, N'IVA 19%')
INSERT [catalogo].[Iva] ([IvaID], [Iva], [Descripcion]) VALUES (5, 0, N'EXCLUIDO')
INSERT [catalogo].[Iva] ([IvaID], [Iva], [Descripcion]) VALUES (6, 0, N'ICUI Saludable')
INSERT [catalogo].[Iva] ([IvaID], [Iva], [Descripcion]) VALUES (7, 0, N'ICL Licores')
INSERT [catalogo].[Iva] ([IvaID], [Iva], [Descripcion]) VALUES (8, 0, N'IBUA Bebidas')
INSERT [catalogo].[Iva] ([IvaID], [Iva], [Descripcion]) VALUES (9, 0, N'INPP Plasticos')
SET IDENTITY_INSERT [catalogo].[Iva] OFF
GO
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'0', N'', N'0', N'')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'001', N'MEDELLIN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'002', N'ABEJORRAL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'004', N'ABRIAQUI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'021', N'ALEJANDRIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'030', N'AMAGA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'031', N'AMALFI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'034', N'ANDES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'036', N'ANGELOPOLIS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'038', N'ANGOSTURA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'040', N'ANORI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'042', N'SANTAFE DE ANTIOQUIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'044', N'ANZA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'045', N'APARTADO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'051', N'ARBOLETES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'055', N'ARGELIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'059', N'ARMENIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'079', N'BARBOSA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'086', N'BELMIRA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'088', N'BELLO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'091', N'BETANIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'093', N'BETULIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'101', N'CIUDAD BOLIVAR')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'107', N'BRICEÑO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'113', N'BURITICA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'120', N'CACERES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'125', N'CAICEDO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'129', N'CALDAS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'134', N'CAMPAMENTO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'138', N'CAÑASGORDAS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'142', N'CARACOLI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'145', N'CARAMANTA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'147', N'CAREPA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'148', N'EL CARMEN DE VIBORAL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'150', N'CAROLINA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'154', N'CAUCASIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'172', N'CHIGORODO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'190', N'CISNEROS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'197', N'COCORNA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'206', N'CONCEPCION')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'209', N'CONCORDIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'212', N'COPACABANA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'234', N'DABEIBA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'237', N'DON MATIAS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'240', N'EBEJICO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'250', N'EL BAGRE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'264', N'ENTRERRIOS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'266', N'ENVIGADO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'282', N'FREDONIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'284', N'FRONTINO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'306', N'GIRALDO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'308', N'GIRARDOTA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'310', N'GOMEZ PLATA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'313', N'GRANADA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'315', N'GUADALUPE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'318', N'GUARNE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'321', N'GUATAPE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'347', N'HELICONIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'353', N'HISPANIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'360', N'ITAGUI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'361', N'ITUANGO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'364', N'JARDIN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'368', N'JERICO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'376', N'LA CEJA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'380', N'LA ESTRELLA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'390', N'LA PINTADA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'400', N'LA UNION')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'411', N'LIBORINA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'425', N'MACEO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'440', N'MARINILLA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'467', N'MONTEBELLO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'475', N'MURINDO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'480', N'MUTATA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'483', N'NARIÑO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'490', N'NECOCLI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'495', N'NECHI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'501', N'OLAYA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'541', N'PEÐOL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'543', N'PEQUE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'576', N'PUEBLORRICO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'579', N'PUERTO BERRIO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'585', N'PUERTO NARE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'591', N'PUERTO TRIUNFO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'604', N'REMEDIOS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'607', N'RETIRO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'615', N'RIONEGRO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'628', N'SABANALARGA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'631', N'SABANETA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'642', N'SALGAR')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'647', N'SAN ANDRES DE CUERQUIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'649', N'SAN CARLOS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'652', N'SAN FRANCISCO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'656', N'SAN JERONIMO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'658', N'SAN JOSE DE LA MONTAÑA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'659', N'SAN JUAN DE URABA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'660', N'SAN LUIS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'664', N'SAN PEDRO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'665', N'SAN PEDRO DE URABA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'667', N'SAN RAFAEL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'670', N'SAN ROQUE')
GO
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'674', N'SAN VICENTE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'679', N'SANTA BARBARA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'686', N'SANTA ROSA DE OSOS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'690', N'SANTO DOMINGO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'697', N'EL SANTUARIO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'736', N'SEGOVIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'756', N'SONSON')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'761', N'SOPETRAN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'789', N'TAMESIS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'790', N'TARAZA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'792', N'TARSO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'809', N'TITIRIBI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'819', N'TOLEDO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'837', N'TURBO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'842', N'URAMITA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'847', N'URRAO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'854', N'VALDIVIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'856', N'VALPARAISO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'858', N'VEGACHI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'861', N'VENECIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'873', N'VIGIA DEL FUERTE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'885', N'YALI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'887', N'YARUMAL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'890', N'YOLOMBO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'893', N'YONDO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'05', N'ANTIOQUIA', N'895', N'ZARAGOZA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'08', N'ATLANTICO', N'001', N'BARRANQUILLA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'08', N'ATLANTICO', N'078', N'BARANOA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'08', N'ATLANTICO', N'137', N'CAMPO DE LA CRUZ')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'08', N'ATLANTICO', N'141', N'CANDELARIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'08', N'ATLANTICO', N'296', N'GALAPA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'08', N'ATLANTICO', N'372', N'JUAN DE ACOSTA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'08', N'ATLANTICO', N'421', N'LURUACO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'08', N'ATLANTICO', N'433', N'MALAMBO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'08', N'ATLANTICO', N'436', N'MANATI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'08', N'ATLANTICO', N'520', N'PALMAR DE VARELA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'08', N'ATLANTICO', N'549', N'PIOJO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'08', N'ATLANTICO', N'558', N'POLONUEVO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'08', N'ATLANTICO', N'560', N'PONEDERA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'08', N'ATLANTICO', N'573', N'PUERTO COLOMBIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'08', N'ATLANTICO', N'606', N'REPELON')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'08', N'ATLANTICO', N'634', N'SABANAGRANDE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'08', N'ATLANTICO', N'638', N'SABANALARGA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'08', N'ATLANTICO', N'675', N'SANTA LUCIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'08', N'ATLANTICO', N'685', N'SANTO TOMAS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'08', N'ATLANTICO', N'758', N'SOLEDAD')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'08', N'ATLANTICO', N'770', N'SUAN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'08', N'ATLANTICO', N'832', N'TUBARA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'08', N'ATLANTICO', N'849', N'USIACURI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'11', N'BOGOTA', N'001', N'BOGOTA, D.C.')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'001', N'CARTAGENA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'006', N'ACHI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'030', N'ALTOS DEL ROSARIO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'042', N'ARENAL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'052', N'ARJONA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'062', N'ARROYOHONDO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'074', N'BARRANCO DE LOBA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'140', N'CALAMAR')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'160', N'CANTAGALLO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'188', N'CICUCO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'212', N'CORDOBA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'222', N'CLEMENCIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'244', N'EL CARMEN DE BOLIVAR')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'248', N'EL GUAMO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'268', N'EL PEÑON')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'300', N'HATILLO DE LOBA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'430', N'MAGANGUE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'433', N'MAHATES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'440', N'MARGARITA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'442', N'MARIA LA BAJA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'458', N'MONTECRISTO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'468', N'MOMPOS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'473', N'MORALES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'490', N'NOROSI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'549', N'PINILLOS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'580', N'REGIDOR')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'600', N'RIO VIEJO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'620', N'SAN CRISTOBAL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'647', N'SAN ESTANISLAO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'650', N'SAN FERNANDO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'654', N'SAN JACINTO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'655', N'SAN JACINTO DEL CAUCA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'657', N'SAN JUAN NEPOMUCENO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'667', N'SAN MARTIN DE LOBA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'670', N'SAN PABLO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'673', N'SANTA CATALINA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'683', N'SANTA ROSA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'688', N'SANTA ROSA DEL SUR')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'744', N'SIMITI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'760', N'SOPLAVIENTO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'780', N'TALAIGUA NUEVO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'810', N'TIQUISIO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'836', N'TURBACO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'838', N'TURBANA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'873', N'VILLANUEVA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'13', N'BOLIVAR', N'894', N'ZAMBRANO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'001', N'TUNJA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'022', N'ALMEIDA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'047', N'AQUITANIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'051', N'ARCABUCO')
GO
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'087', N'BELEN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'090', N'BERBEO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'092', N'BETEITIVA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'097', N'BOAVITA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'104', N'BOYACA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'106', N'BRICEÑO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'109', N'BUENAVISTA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'114', N'BUSBANZA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'131', N'CALDAS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'135', N'CAMPOHERMOSO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'162', N'CERINZA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'172', N'CHINAVITA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'176', N'CHIQUINQUIRA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'180', N'CHISCAS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'183', N'CHITA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'185', N'CHITARAQUE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'187', N'CHIVATA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'189', N'CIENEGA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'204', N'COMBITA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'212', N'COPER')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'215', N'CORRALES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'218', N'COVARACHIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'223', N'CUBARA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'224', N'CUCAITA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'226', N'CUITIVA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'232', N'CHIQUIZA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'236', N'CHIVOR')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'238', N'DUITAMA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'244', N'EL COCUY')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'248', N'EL ESPINO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'272', N'FIRAVITOBA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'276', N'FLORESTA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'293', N'GACHANTIVA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'296', N'GAMEZA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'299', N'GARAGOA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'317', N'GUACAMAYAS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'322', N'GUATEQUE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'325', N'GUAYATA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'332', N'GsICAN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'362', N'IZA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'367', N'JENESANO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'368', N'JERICO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'377', N'LABRANZAGRANDE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'380', N'LA CAPILLA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'401', N'LA VICTORIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'403', N'LA UVITA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'407', N'VILLA DE LEYVA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'425', N'MACANAL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'442', N'MARIPI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'455', N'MIRAFLORES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'464', N'MONGUA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'466', N'MONGUI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'469', N'MONIQUIRA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'476', N'MOTAVITA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'480', N'MUZO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'491', N'NOBSA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'494', N'NUEVO COLON')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'500', N'OICATA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'507', N'OTANCHE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'511', N'PACHAVITA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'514', N'PAEZ')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'516', N'PAIPA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'518', N'PAJARITO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'522', N'PANQUEBA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'531', N'PAUNA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'533', N'PAYA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'537', N'PAZ DE RIO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'542', N'PESCA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'550', N'PISBA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'572', N'PUERTO BOYACA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'580', N'QUIPAMA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'599', N'RAMIRIQUI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'600', N'RAQUIRA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'621', N'RONDON')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'632', N'SABOYA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'638', N'SACHICA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'646', N'SAMACA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'660', N'SAN EDUARDO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'664', N'SAN JOSE DE PARE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'667', N'SAN LUIS DE GACENO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'673', N'SAN MATEO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'676', N'SAN MIGUEL DE SEMA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'681', N'SAN PABLO DE BORBUR')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'686', N'SANTANA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'690', N'SANTA MARIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'693', N'SANTA ROSA DE VITERBO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'696', N'SANTA SOFIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'720', N'SATIVANORTE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'723', N'SATIVASUR')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'740', N'SIACHOQUE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'753', N'SOATA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'755', N'SOCOTA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'757', N'SOCHA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'759', N'SOGAMOSO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'761', N'SOMONDOCO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'762', N'SORA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'763', N'SOTAQUIRA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'764', N'SORACA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'774', N'SUSACON')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'776', N'SUTAMARCHAN')
GO
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'778', N'SUTATENZA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'790', N'TASCO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'798', N'TENZA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'804', N'TIBANA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'806', N'TIBASOSA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'808', N'TINJACA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'810', N'TIPACOQUE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'814', N'TOCA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'816', N'TOGsI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'820', N'TOPAGA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'822', N'TOTA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'832', N'TUNUNGUA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'835', N'TURMEQUE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'837', N'TUTA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'839', N'TUTAZA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'842', N'UMBITA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'861', N'VENTAQUEMADA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'879', N'VIRACACHA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'15', N'BOYACA', N'897', N'ZETAQUIRA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'17', N'CALDAS', N'001', N'MANIZALES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'17', N'CALDAS', N'013', N'AGUADAS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'17', N'CALDAS', N'042', N'ANSERMA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'17', N'CALDAS', N'050', N'ARANZAZU')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'17', N'CALDAS', N'088', N'BELALCAZAR')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'17', N'CALDAS', N'174', N'CHINCHINA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'17', N'CALDAS', N'272', N'FILADELFIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'17', N'CALDAS', N'380', N'LA DORADA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'17', N'CALDAS', N'388', N'LA MERCED')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'17', N'CALDAS', N'433', N'MANZANARES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'17', N'CALDAS', N'442', N'MARMATO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'17', N'CALDAS', N'444', N'MARQUETALIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'17', N'CALDAS', N'446', N'MARULANDA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'17', N'CALDAS', N'486', N'NEIRA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'17', N'CALDAS', N'495', N'NORCASIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'17', N'CALDAS', N'513', N'PACORA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'17', N'CALDAS', N'524', N'PALESTINA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'17', N'CALDAS', N'541', N'PENSILVANIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'17', N'CALDAS', N'614', N'RIOSUCIO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'17', N'CALDAS', N'616', N'RISARALDA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'17', N'CALDAS', N'653', N'SALAMINA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'17', N'CALDAS', N'662', N'SAMANA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'17', N'CALDAS', N'665', N'SAN JOSE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'17', N'CALDAS', N'777', N'SUPIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'17', N'CALDAS', N'867', N'VICTORIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'17', N'CALDAS', N'873', N'VILLAMARIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'17', N'CALDAS', N'877', N'VITERBO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'18', N'CAQUETA', N'001', N'FLORENCIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'18', N'CAQUETA', N'029', N'ALBANIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'18', N'CAQUETA', N'094', N'BELEN DE LOS ANDAQUIES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'18', N'CAQUETA', N'150', N'CARTAGENA DEL CHAIRA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'18', N'CAQUETA', N'205', N'CURILLO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'18', N'CAQUETA', N'247', N'EL DONCELLO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'18', N'CAQUETA', N'256', N'EL PAUJIL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'18', N'CAQUETA', N'410', N'LA MONTAÑITA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'18', N'CAQUETA', N'460', N'MILAN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'18', N'CAQUETA', N'479', N'MORELIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'18', N'CAQUETA', N'592', N'PUERTO RICO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'18', N'CAQUETA', N'610', N'SAN JOSE DEL FRAGUA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'18', N'CAQUETA', N'753', N'SAN VICENTE DEL CAGUAN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'18', N'CAQUETA', N'756', N'SOLANO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'18', N'CAQUETA', N'785', N'SOLITA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'18', N'CAQUETA', N'860', N'VALPARAISO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'001', N'POPAYAN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'022', N'ALMAGUER')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'050', N'ARGELIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'075', N'BALBOA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'100', N'BOLIVAR')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'110', N'BUENOS AIRES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'130', N'CAJIBIO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'137', N'CALDONO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'142', N'CALOTO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'212', N'CORINTO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'256', N'EL TAMBO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'290', N'FLORENCIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'300', N'GUACHENE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'318', N'GUAPI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'355', N'INZA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'364', N'JAMBALO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'392', N'LA SIERRA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'397', N'LA VEGA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'418', N'LOPEZ')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'450', N'MERCADERES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'455', N'MIRANDA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'473', N'MORALES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'513', N'PADILLA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'517', N'PAEZ')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'532', N'PATIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'533', N'PIAMONTE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'548', N'PIENDAMO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'573', N'PUERTO TEJADA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'585', N'PURACE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'622', N'ROSAS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'693', N'SAN SEBASTIAN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'698', N'SANTANDER DE QUILICHAO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'701', N'SANTA ROSA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'743', N'SILVIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'760', N'SOTARA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'780', N'SUAREZ')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'785', N'SUCRE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'807', N'TIMBIO')
GO
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'809', N'TIMBIQUI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'821', N'TORIBIO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'824', N'TOTORO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'19', N'CAUCA', N'845', N'VILLA RICA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'20', N'CESAR', N'001', N'VALLEDUPAR')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'20', N'CESAR', N'011', N'AGUACHICA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'20', N'CESAR', N'013', N'AGUSTIN CODAZZI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'20', N'CESAR', N'032', N'ASTREA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'20', N'CESAR', N'045', N'BECERRIL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'20', N'CESAR', N'060', N'BOSCONIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'20', N'CESAR', N'175', N'CHIMICHAGUA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'20', N'CESAR', N'178', N'CHIRIGUANA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'20', N'CESAR', N'228', N'CURUMANI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'20', N'CESAR', N'238', N'EL COPEY')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'20', N'CESAR', N'250', N'EL PASO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'20', N'CESAR', N'295', N'GAMARRA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'20', N'CESAR', N'310', N'GONZALEZ')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'20', N'CESAR', N'383', N'LA GLORIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'20', N'CESAR', N'400', N'LA JAGUA DE IBIRICO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'20', N'CESAR', N'443', N'MANAURE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'20', N'CESAR', N'517', N'PAILITAS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'20', N'CESAR', N'550', N'PELAYA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'20', N'CESAR', N'570', N'PUEBLO BELLO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'20', N'CESAR', N'614', N'RIO DE ORO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'20', N'CESAR', N'621', N'LA PAZ')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'20', N'CESAR', N'710', N'SAN ALBERTO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'20', N'CESAR', N'750', N'SAN DIEGO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'20', N'CESAR', N'770', N'SAN MARTIN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'20', N'CESAR', N'787', N'TAMALAMEQUE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'23', N'CORDOBA', N'001', N'MONTERIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'23', N'CORDOBA', N'068', N'AYAPEL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'23', N'CORDOBA', N'079', N'BUENAVISTA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'23', N'CORDOBA', N'090', N'CANALETE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'23', N'CORDOBA', N'162', N'CERETE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'23', N'CORDOBA', N'168', N'CHIMA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'23', N'CORDOBA', N'182', N'CHINU')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'23', N'CORDOBA', N'189', N'CIENAGA DE ORO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'23', N'CORDOBA', N'300', N'COTORRA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'23', N'CORDOBA', N'350', N'LA APARTADA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'23', N'CORDOBA', N'417', N'LORICA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'23', N'CORDOBA', N'419', N'LOS CORDOBAS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'23', N'CORDOBA', N'464', N'MOMIL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'23', N'CORDOBA', N'466', N'MONTELIBANO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'23', N'CORDOBA', N'500', N'MOÑITOS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'23', N'CORDOBA', N'555', N'PLANETA RICA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'23', N'CORDOBA', N'570', N'PUEBLO NUEVO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'23', N'CORDOBA', N'574', N'PUERTO ESCONDIDO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'23', N'CORDOBA', N'580', N'PUERTO LIBERTADOR')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'23', N'CORDOBA', N'586', N'PURISIMA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'23', N'CORDOBA', N'660', N'SAHAGUN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'23', N'CORDOBA', N'670', N'SAN ANDRES SOTAVENTO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'23', N'CORDOBA', N'672', N'SAN ANTERO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'23', N'CORDOBA', N'675', N'SAN BERNARDO DEL VIENTO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'23', N'CORDOBA', N'678', N'SAN CARLOS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'23', N'CORDOBA', N'686', N'SAN PELAYO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'23', N'CORDOBA', N'807', N'TIERRALTA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'23', N'CORDOBA', N'855', N'VALENCIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'001', N'AGUA DE DIOS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'019', N'ALBAN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'035', N'ANAPOIMA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'040', N'ANOLAIMA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'053', N'ARBELAEZ')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'086', N'BELTRAN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'095', N'BITUIMA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'099', N'BOJACA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'120', N'CABRERA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'123', N'CACHIPAY')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'126', N'CAJICA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'148', N'CAPARRAPI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'151', N'CAQUEZA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'154', N'CARMEN DE CARUPA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'168', N'CHAGUANI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'175', N'CHIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'178', N'CHIPAQUE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'181', N'CHOACHI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'183', N'CHOCONTA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'200', N'COGUA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'214', N'COTA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'224', N'CUCUNUBA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'245', N'EL COLEGIO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'258', N'EL PEÑON')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'260', N'EL ROSAL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'269', N'FACATATIVA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'279', N'FOMEQUE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'281', N'FOSCA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'286', N'FUNZA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'288', N'FUQUENE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'290', N'FUSAGASUGA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'293', N'GACHALA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'295', N'GACHANCIPA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'297', N'GACHETA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'299', N'GAMA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'307', N'GIRARDOT')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'312', N'GRANADA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'317', N'GUACHETA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'320', N'GUADUAS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'322', N'GUASCA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'324', N'GUATAQUI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'326', N'GUATAVITA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'328', N'GUAYABAL DE SIQUIMA')
GO
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'335', N'GUAYABETAL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'339', N'GUTIERREZ')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'368', N'JERUSALEN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'372', N'JUNIN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'377', N'LA CALERA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'386', N'LA MESA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'394', N'LA PALMA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'398', N'LA PEÑA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'402', N'LA VEGA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'407', N'LENGUAZAQUE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'426', N'MACHETA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'430', N'MADRID')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'436', N'MANTA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'438', N'MEDINA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'473', N'MOSQUERA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'483', N'NARIÑO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'486', N'NEMOCON')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'488', N'NILO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'489', N'NIMAIMA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'491', N'NOCAIMA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'506', N'VENECIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'513', N'PACHO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'518', N'PAIME')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'524', N'PANDI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'530', N'PARATEBUENO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'535', N'PASCA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'572', N'PUERTO SALGAR')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'580', N'PULI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'592', N'QUEBRADANEGRA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'594', N'QUETAME')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'596', N'QUIPILE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'599', N'APULO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'612', N'RICAURTE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'645', N'SAN ANTONIO DEL TEQUENDAMA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'649', N'SAN BERNARDO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'653', N'SAN CAYETANO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'658', N'SAN FRANCISCO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'662', N'SAN JUAN DE RIO SECO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'718', N'SASAIMA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'736', N'SESQUILE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'740', N'SIBATE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'743', N'SILVANIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'745', N'SIMIJACA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'754', N'SOACHA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'758', N'SOPO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'769', N'SUBACHOQUE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'772', N'SUESCA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'777', N'SUPATA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'779', N'SUSA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'781', N'SUTATAUSA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'785', N'TABIO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'793', N'TAUSA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'797', N'TENA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'799', N'TENJO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'805', N'TIBACUY')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'807', N'TIBIRITA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'815', N'TOCAIMA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'817', N'TOCANCIPA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'823', N'TOPAIPI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'839', N'UBALA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'841', N'UBAQUE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'843', N'VILLA DE SAN DIEGO DE UBATE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'845', N'UNE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'851', N'UTICA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'862', N'VERGARA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'867', N'VIANI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'871', N'VILLAGOMEZ')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'873', N'VILLAPINZON')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'875', N'VILLETA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'878', N'VIOTA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'885', N'YACOPI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'898', N'ZIPACON')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'25', N'CUNDINAMARCA', N'899', N'ZIPAQUIRA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'27', N'CHOCO', N'001', N'QUIBDO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'27', N'CHOCO', N'006', N'ACANDI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'27', N'CHOCO', N'025', N'ALTO BAUDO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'27', N'CHOCO', N'050', N'ATRATO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'27', N'CHOCO', N'073', N'BAGADO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'27', N'CHOCO', N'075', N'BAHIA SOLANO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'27', N'CHOCO', N'077', N'BAJO BAUDO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'27', N'CHOCO', N'099', N'BOJAYA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'27', N'CHOCO', N'135', N'EL CANTON DEL SAN PABLO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'27', N'CHOCO', N'150', N'CARMEN DEL DARIEN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'27', N'CHOCO', N'160', N'CERTEGUI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'27', N'CHOCO', N'205', N'CONDOTO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'27', N'CHOCO', N'245', N'EL CARMEN DE ATRATO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'27', N'CHOCO', N'250', N'EL LITORAL DEL SAN JUAN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'27', N'CHOCO', N'361', N'ISTMINA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'27', N'CHOCO', N'372', N'JURADO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'27', N'CHOCO', N'413', N'LLORO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'27', N'CHOCO', N'425', N'MEDIO ATRATO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'27', N'CHOCO', N'430', N'MEDIO BAUDO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'27', N'CHOCO', N'450', N'MEDIO SAN JUAN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'27', N'CHOCO', N'491', N'NOVITA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'27', N'CHOCO', N'495', N'NUQUI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'27', N'CHOCO', N'580', N'RIO IRO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'27', N'CHOCO', N'600', N'RIO QUITO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'27', N'CHOCO', N'615', N'RIOSUCIO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'27', N'CHOCO', N'660', N'SAN JOSE DEL PALMAR')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'27', N'CHOCO', N'745', N'SIPI')
GO
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'27', N'CHOCO', N'787', N'TADO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'27', N'CHOCO', N'800', N'UNGUIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'27', N'CHOCO', N'810', N'UNION PANAMERICANA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'001', N'NEIVA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'006', N'ACEVEDO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'013', N'AGRADO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'016', N'AIPE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'020', N'ALGECIRAS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'026', N'ALTAMIRA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'078', N'BARAYA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'132', N'CAMPOALEGRE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'206', N'COLOMBIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'244', N'ELIAS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'298', N'GARZON')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'306', N'GIGANTE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'319', N'GUADALUPE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'349', N'HOBO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'357', N'IQUIRA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'359', N'ISNOS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'378', N'LA ARGENTINA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'396', N'LA PLATA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'483', N'NATAGA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'503', N'OPORAPA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'518', N'PAICOL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'524', N'PALERMO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'530', N'PALESTINA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'548', N'PITAL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'551', N'PITALITO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'615', N'RIVERA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'660', N'SALADOBLANCO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'668', N'SAN AGUSTIN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'676', N'SANTA MARIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'770', N'SUAZA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'791', N'TARQUI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'797', N'TESALIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'799', N'TELLO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'801', N'TERUEL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'807', N'TIMANA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'872', N'VILLAVIEJA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'41', N'HUILA', N'885', N'YAGUARA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'44', N'LA GUAJIRA', N'001', N'RIOHACHA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'44', N'LA GUAJIRA', N'035', N'ALBANIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'44', N'LA GUAJIRA', N'078', N'BARRANCAS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'44', N'LA GUAJIRA', N'090', N'DIBULLA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'44', N'LA GUAJIRA', N'098', N'DISTRACCION')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'44', N'LA GUAJIRA', N'110', N'EL MOLINO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'44', N'LA GUAJIRA', N'279', N'FONSECA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'44', N'LA GUAJIRA', N'378', N'HATONUEVO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'44', N'LA GUAJIRA', N'420', N'LA JAGUA DEL PILAR')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'44', N'LA GUAJIRA', N'430', N'MAICAO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'44', N'LA GUAJIRA', N'560', N'MANAURE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'44', N'LA GUAJIRA', N'650', N'SAN JUAN DEL CESAR')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'44', N'LA GUAJIRA', N'847', N'URIBIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'44', N'LA GUAJIRA', N'855', N'URUMITA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'44', N'LA GUAJIRA', N'874', N'VILLANUEVA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'47', N'MAGDALENA', N'001', N'SANTA MARTA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'47', N'MAGDALENA', N'030', N'ALGARROBO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'47', N'MAGDALENA', N'053', N'ARACATACA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'47', N'MAGDALENA', N'058', N'ARIGUANI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'47', N'MAGDALENA', N'161', N'CERRO SAN ANTONIO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'47', N'MAGDALENA', N'170', N'CHIBOLO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'47', N'MAGDALENA', N'189', N'CIENAGA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'47', N'MAGDALENA', N'205', N'CONCORDIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'47', N'MAGDALENA', N'245', N'EL BANCO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'47', N'MAGDALENA', N'258', N'EL PIÑON')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'47', N'MAGDALENA', N'268', N'EL RETEN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'47', N'MAGDALENA', N'288', N'FUNDACION')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'47', N'MAGDALENA', N'318', N'GUAMAL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'47', N'MAGDALENA', N'460', N'NUEVA GRANADA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'47', N'MAGDALENA', N'541', N'PEDRAZA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'47', N'MAGDALENA', N'545', N'PIJIÑO DEL CARMEN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'47', N'MAGDALENA', N'551', N'PIVIJAY')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'47', N'MAGDALENA', N'555', N'PLATO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'47', N'MAGDALENA', N'570', N'PUEBLOVIEJO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'47', N'MAGDALENA', N'605', N'REMOLINO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'47', N'MAGDALENA', N'660', N'SABANAS DE SAN ANGEL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'47', N'MAGDALENA', N'675', N'SALAMINA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'47', N'MAGDALENA', N'692', N'SAN SEBASTIAN DE BUENAVISTA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'47', N'MAGDALENA', N'703', N'SAN ZENON')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'47', N'MAGDALENA', N'707', N'SANTA ANA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'47', N'MAGDALENA', N'720', N'SANTA BARBARA DE PINTO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'47', N'MAGDALENA', N'745', N'SITIONUEVO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'47', N'MAGDALENA', N'798', N'TENERIFE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'47', N'MAGDALENA', N'960', N'ZAPAYAN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'47', N'MAGDALENA', N'980', N'ZONA BANANERA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'50', N'META', N'001', N'VILLAVICENCIO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'50', N'META', N'006', N'ACACIAS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'50', N'META', N'110', N'BARRANCA DE UPIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'50', N'META', N'124', N'CABUYARO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'50', N'META', N'150', N'CASTILLA LA NUEVA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'50', N'META', N'223', N'CUBARRAL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'50', N'META', N'226', N'CUMARAL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'50', N'META', N'245', N'EL CALVARIO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'50', N'META', N'251', N'EL CASTILLO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'50', N'META', N'270', N'EL DORADO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'50', N'META', N'287', N'FUENTE DE ORO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'50', N'META', N'313', N'GRANADA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'50', N'META', N'318', N'GUAMAL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'50', N'META', N'325', N'MAPIRIPAN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'50', N'META', N'330', N'MESETAS')
GO
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'50', N'META', N'350', N'LA MACARENA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'50', N'META', N'370', N'URIBE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'50', N'META', N'400', N'LEJANIAS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'50', N'META', N'450', N'PUERTO CONCORDIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'50', N'META', N'568', N'PUERTO GAITAN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'50', N'META', N'573', N'PUERTO LOPEZ')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'50', N'META', N'577', N'PUERTO LLERAS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'50', N'META', N'590', N'PUERTO RICO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'50', N'META', N'606', N'RESTREPO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'50', N'META', N'680', N'SAN CARLOS DE GUAROA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'50', N'META', N'683', N'SAN JUAN DE ARAMA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'50', N'META', N'686', N'SAN JUANITO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'50', N'META', N'689', N'SAN MARTIN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'50', N'META', N'711', N'VISTAHERMOSA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'001', N'PASTO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'019', N'ALBAN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'022', N'ALDANA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'036', N'ANCUYA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'051', N'ARBOLEDA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'079', N'BARBACOAS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'083', N'BELEN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'110', N'BUESACO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'203', N'COLON')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'207', N'CONSACA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'210', N'CONTADERO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'215', N'CORDOBA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'224', N'CUASPUD')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'227', N'CUMBAL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'233', N'CUMBITARA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'240', N'CHACHAGsI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'250', N'EL CHARCO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'254', N'EL PEÑOL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'256', N'EL ROSARIO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'258', N'EL TABLON DE GOMEZ')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'260', N'EL TAMBO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'287', N'FUNES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'317', N'GUACHUCAL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'320', N'GUAITARILLA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'323', N'GUALMATAN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'352', N'ILES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'354', N'IMUES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'356', N'IPIALES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'378', N'LA CRUZ')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'381', N'LA FLORIDA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'385', N'LA LLANADA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'390', N'LA TOLA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'399', N'LA UNION')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'405', N'LEIVA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'411', N'LINARES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'418', N'LOS ANDES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'427', N'MAGsI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'435', N'MALLAMA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'473', N'MOSQUERA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'480', N'NARIÑO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'490', N'OLAYA HERRERA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'506', N'OSPINA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'520', N'FRANCISCO PIZARRO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'540', N'POLICARPA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'560', N'POTOSI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'565', N'PROVIDENCIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'573', N'PUERRES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'585', N'PUPIALES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'612', N'RICAURTE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'621', N'ROBERTO PAYAN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'678', N'SAMANIEGO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'683', N'SANDONA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'685', N'SAN BERNARDO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'687', N'SAN LORENZO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'693', N'SAN PABLO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'694', N'SAN PEDRO DE CARTAGO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'696', N'SANTA BARBARA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'699', N'SANTACRUZ')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'720', N'SAPUYES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'786', N'TAMINANGO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'788', N'TANGUA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'835', N'SAN ANDRES DE TUMACO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'838', N'TUQUERRES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'52', N'NARIÑO', N'885', N'YACUANQUER')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'001', N'CUCUTA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'003', N'ABREGO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'051', N'ARBOLEDAS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'099', N'BOCHALEMA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'109', N'BUCARASICA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'125', N'CACOTA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'128', N'CACHIRA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'172', N'CHINACOTA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'174', N'CHITAGA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'206', N'CONVENCION')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'223', N'CUCUTILLA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'239', N'DURANIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'245', N'EL CARMEN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'250', N'EL TARRA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'261', N'EL ZULIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'313', N'GRAMALOTE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'344', N'HACARI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'347', N'HERRAN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'377', N'LABATECA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'385', N'LA ESPERANZA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'398', N'LA PLAYA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'405', N'LOS PATIOS')
GO
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'418', N'LOURDES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'480', N'MUTISCUA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'498', N'OCAÑA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'518', N'PAMPLONA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'520', N'PAMPLONITA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'553', N'PUERTO SANTANDER')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'599', N'RAGONVALIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'660', N'SALAZAR')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'670', N'SAN CALIXTO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'673', N'SAN CAYETANO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'680', N'SANTIAGO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'720', N'SARDINATA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'743', N'SILOS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'800', N'TEORAMA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'810', N'TIBU')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'820', N'TOLEDO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'871', N'VILLA CARO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'54', N'N. DE SANTANDER', N'874', N'VILLA DEL ROSARIO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'63', N'QUINDIO', N'001', N'ARMENIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'63', N'QUINDIO', N'111', N'BUENAVISTA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'63', N'QUINDIO', N'130', N'CALARCA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'63', N'QUINDIO', N'190', N'CIRCASIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'63', N'QUINDIO', N'212', N'CORDOBA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'63', N'QUINDIO', N'272', N'FILANDIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'63', N'QUINDIO', N'302', N'GENOVA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'63', N'QUINDIO', N'401', N'LA TEBAIDA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'63', N'QUINDIO', N'470', N'MONTENEGRO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'63', N'QUINDIO', N'548', N'PIJAO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'63', N'QUINDIO', N'594', N'QUIMBAYA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'63', N'QUINDIO', N'690', N'SALENTO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'66', N'RISARALDA', N'001', N'PEREIRA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'66', N'RISARALDA', N'045', N'APIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'66', N'RISARALDA', N'075', N'BALBOA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'66', N'RISARALDA', N'088', N'BELEN DE UMBRIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'66', N'RISARALDA', N'170', N'DOSQUEBRADAS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'66', N'RISARALDA', N'318', N'GUATICA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'66', N'RISARALDA', N'383', N'LA CELIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'66', N'RISARALDA', N'400', N'LA VIRGINIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'66', N'RISARALDA', N'440', N'MARSELLA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'66', N'RISARALDA', N'456', N'MISTRATO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'66', N'RISARALDA', N'572', N'PUEBLO RICO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'66', N'RISARALDA', N'594', N'QUINCHIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'66', N'RISARALDA', N'682', N'SANTA ROSA DE CABAL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'66', N'RISARALDA', N'687', N'SANTUARIO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'001', N'BUCARAMANGA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'013', N'AGUADA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'020', N'ALBANIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'051', N'ARATOCA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'077', N'BARBOSA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'079', N'BARICHARA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'081', N'BARRANCABERMEJA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'092', N'BETULIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'101', N'BOLIVAR')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'121', N'CABRERA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'132', N'CALIFORNIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'147', N'CAPITANEJO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'152', N'CARCASI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'160', N'CEPITA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'162', N'CERRITO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'167', N'CHARALA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'169', N'CHARTA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'176', N'CHIMA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'179', N'CHIPATA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'190', N'CIMITARRA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'207', N'CONCEPCION')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'209', N'CONFINES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'211', N'CONTRATACION')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'217', N'COROMORO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'229', N'CURITI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'235', N'EL CARMEN DE CHUCURI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'245', N'EL GUACAMAYO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'250', N'EL PEÑON')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'255', N'EL PLAYON')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'264', N'ENCINO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'266', N'ENCISO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'271', N'FLORIAN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'276', N'FLORIDABLANCA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'296', N'GALAN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'298', N'GAMBITA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'307', N'GIRON')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'318', N'GUACA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'320', N'GUADALUPE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'322', N'GUAPOTA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'324', N'GUAVATA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'327', N'GsEPSA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'344', N'HATO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'368', N'JESUS MARIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'370', N'JORDAN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'377', N'LA BELLEZA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'385', N'LANDAZURI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'397', N'LA PAZ')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'406', N'LEBRIJA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'418', N'LOS SANTOS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'425', N'MACARAVITA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'432', N'MALAGA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'444', N'MATANZA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'464', N'MOGOTES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'468', N'MOLAGAVITA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'498', N'OCAMONTE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'500', N'OIBA')
GO
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'502', N'ONZAGA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'522', N'PALMAR')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'524', N'PALMAS DEL SOCORRO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'533', N'PARAMO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'547', N'PIEDECUESTA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'549', N'PINCHOTE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'572', N'PUENTE NACIONAL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'573', N'PUERTO PARRA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'575', N'PUERTO WILCHES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'615', N'RIONEGRO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'655', N'SABANA DE TORRES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'669', N'SAN ANDRES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'673', N'SAN BENITO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'679', N'SAN GIL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'682', N'SAN JOAQUIN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'684', N'SAN JOSE DE MIRANDA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'686', N'SAN MIGUEL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'689', N'SAN VICENTE DE CHUCURI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'705', N'SANTA BARBARA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'720', N'SANTA HELENA DEL OPON')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'745', N'SIMACOTA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'755', N'SOCORRO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'770', N'SUAITA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'773', N'SUCRE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'780', N'SURATA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'820', N'TONA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'855', N'VALLE DE SAN JOSE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'861', N'VELEZ')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'867', N'VETAS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'872', N'VILLANUEVA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'68', N'SANTANDER', N'895', N'ZAPATOCA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'70', N'SUCRE', N'001', N'SINCELEJO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'70', N'SUCRE', N'110', N'BUENAVISTA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'70', N'SUCRE', N'124', N'CAIMITO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'70', N'SUCRE', N'204', N'COLOSO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'70', N'SUCRE', N'215', N'COROZAL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'70', N'SUCRE', N'221', N'COVEÑAS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'70', N'SUCRE', N'230', N'CHALAN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'70', N'SUCRE', N'233', N'EL ROBLE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'70', N'SUCRE', N'235', N'GALERAS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'70', N'SUCRE', N'265', N'GUARANDA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'70', N'SUCRE', N'400', N'LA UNION')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'70', N'SUCRE', N'418', N'LOS PALMITOS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'70', N'SUCRE', N'429', N'MAJAGUAL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'70', N'SUCRE', N'473', N'MORROA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'70', N'SUCRE', N'508', N'OVEJAS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'70', N'SUCRE', N'523', N'PALMITO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'70', N'SUCRE', N'670', N'SAMPUES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'70', N'SUCRE', N'678', N'SAN BENITO ABAD')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'70', N'SUCRE', N'702', N'SAN JUAN DE BETULIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'70', N'SUCRE', N'708', N'SAN MARCOS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'70', N'SUCRE', N'713', N'SAN ONOFRE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'70', N'SUCRE', N'717', N'SAN PEDRO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'70', N'SUCRE', N'742', N'SAN LUIS DE SINCE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'70', N'SUCRE', N'771', N'SUCRE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'70', N'SUCRE', N'820', N'SANTIAGO DE TOLU')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'70', N'SUCRE', N'823', N'TOLU VIEJO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'001', N'IBAGUE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'024', N'ALPUJARRA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'026', N'ALVARADO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'030', N'AMBALEMA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'043', N'ANZOATEGUI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'055', N'ARMERO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'067', N'ATACO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'124', N'CAJAMARCA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'148', N'CARMEN DE APICALA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'152', N'CASABIANCA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'168', N'CHAPARRAL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'200', N'COELLO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'217', N'COYAIMA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'226', N'CUNDAY')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'236', N'DOLORES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'268', N'ESPINAL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'270', N'FALAN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'275', N'FLANDES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'283', N'FRESNO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'319', N'GUAMO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'347', N'HERVEO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'349', N'HONDA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'352', N'ICONONZO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'408', N'LERIDA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'411', N'LIBANO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'443', N'MARIQUITA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'449', N'MELGAR')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'461', N'MURILLO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'483', N'NATAGAIMA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'504', N'ORTEGA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'520', N'PALOCABILDO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'547', N'PIEDRAS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'555', N'PLANADAS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'563', N'PRADO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'585', N'PURIFICACION')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'616', N'RIOBLANCO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'622', N'RONCESVALLES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'624', N'ROVIRA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'671', N'SALDAÑA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'675', N'SAN ANTONIO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'678', N'SAN LUIS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'686', N'SANTA ISABEL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'770', N'SUAREZ')
GO
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'854', N'VALLE DE SAN JUAN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'861', N'VENADILLO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'870', N'VILLAHERMOSA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'73', N'TOLIMA', N'873', N'VILLARRICA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'001', N'CALI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'020', N'ALCALA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'036', N'ANDALUCIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'041', N'ANSERMANUEVO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'054', N'ARGELIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'100', N'BOLIVAR')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'109', N'BUENAVENTURA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'111', N'GUADALAJARA DE BUGA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'113', N'BUGALAGRANDE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'122', N'CAICEDONIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'126', N'CALIMA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'130', N'CANDELARIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'147', N'CARTAGO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'233', N'DAGUA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'243', N'EL AGUILA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'246', N'EL CAIRO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'248', N'EL CERRITO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'250', N'EL DOVIO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'275', N'FLORIDA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'306', N'GINEBRA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'318', N'GUACARI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'364', N'JAMUNDI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'377', N'LA CUMBRE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'400', N'LA UNION')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'403', N'LA VICTORIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'497', N'OBANDO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'520', N'PALMIRA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'563', N'PRADERA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'606', N'RESTREPO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'616', N'RIOFRIO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'622', N'ROLDANILLO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'670', N'SAN PEDRO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'736', N'SEVILLA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'823', N'TORO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'828', N'TRUJILLO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'834', N'TULUA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'845', N'ULLOA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'863', N'VERSALLES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'869', N'VIJES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'890', N'YOTOCO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'892', N'YUMBO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'76', N'VALLE DEL CAUCA', N'895', N'ZARZAL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'81', N'ARAUCA', N'001', N'ARAUCA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'81', N'ARAUCA', N'065', N'ARAUQUITA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'81', N'ARAUCA', N'220', N'CRAVO NORTE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'81', N'ARAUCA', N'300', N'FORTUL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'81', N'ARAUCA', N'591', N'PUERTO RONDON')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'81', N'ARAUCA', N'736', N'SARAVENA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'81', N'ARAUCA', N'794', N'TAME')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'85', N'CASANARE', N'001', N'YOPAL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'85', N'CASANARE', N'010', N'AGUAZUL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'85', N'CASANARE', N'015', N'CHAMEZA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'85', N'CASANARE', N'125', N'HATO COROZAL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'85', N'CASANARE', N'136', N'LA SALINA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'85', N'CASANARE', N'139', N'MANI')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'85', N'CASANARE', N'162', N'MONTERREY')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'85', N'CASANARE', N'225', N'NUNCHIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'85', N'CASANARE', N'230', N'OROCUE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'85', N'CASANARE', N'250', N'PAZ DE ARIPORO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'85', N'CASANARE', N'263', N'PORE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'85', N'CASANARE', N'279', N'RECETOR')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'85', N'CASANARE', N'300', N'SABANALARGA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'85', N'CASANARE', N'315', N'SACAMA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'85', N'CASANARE', N'325', N'SAN LUIS DE PALENQUE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'85', N'CASANARE', N'400', N'TAMARA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'85', N'CASANARE', N'410', N'TAURAMENA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'85', N'CASANARE', N'430', N'TRINIDAD')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'85', N'CASANARE', N'440', N'VILLANUEVA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'86', N'PUTUMAYO', N'001', N'MOCOA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'86', N'PUTUMAYO', N'219', N'COLON')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'86', N'PUTUMAYO', N'320', N'ORITO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'86', N'PUTUMAYO', N'568', N'PUERTO ASIS')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'86', N'PUTUMAYO', N'569', N'PUERTO CAICEDO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'86', N'PUTUMAYO', N'571', N'PUERTO GUZMAN')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'86', N'PUTUMAYO', N'573', N'LEGUIZAMO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'86', N'PUTUMAYO', N'749', N'SIBUNDOY')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'86', N'PUTUMAYO', N'755', N'SAN FRANCISCO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'86', N'PUTUMAYO', N'757', N'SAN MIGUEL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'86', N'PUTUMAYO', N'760', N'SANTIAGO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'86', N'PUTUMAYO', N'865', N'VALLE DEL GUAMUEZ')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'86', N'PUTUMAYO', N'885', N'VILLAGARZON')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'88', N'SAN ANDRES', N'001', N'SAN ANDRES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'88', N'SAN ANDRES', N'564', N'PROVIDENCIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'91', N'AMAZONAS', N'001', N'LETICIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'91', N'AMAZONAS', N'263', N'EL ENCANTO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'91', N'AMAZONAS', N'405', N'LA CHORRERA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'91', N'AMAZONAS', N'407', N'LA PEDRERA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'91', N'AMAZONAS', N'430', N'LA VICTORIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'91', N'AMAZONAS', N'460', N'MIRITI - PARANA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'91', N'AMAZONAS', N'530', N'PUERTO ALEGRIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'91', N'AMAZONAS', N'536', N'PUERTO ARICA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'91', N'AMAZONAS', N'540', N'PUERTO NARIÑO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'91', N'AMAZONAS', N'669', N'PUERTO SANTANDER')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'91', N'AMAZONAS', N'798', N'TARAPACA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'94', N'GUAINIA', N'001', N'INIRIDA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'94', N'GUAINIA', N'343', N'BARRANCO MINAS')
GO
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'94', N'GUAINIA', N'663', N'MAPIRIPANA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'94', N'GUAINIA', N'883', N'SAN FELIPE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'94', N'GUAINIA', N'884', N'PUERTO COLOMBIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'94', N'GUAINIA', N'885', N'LA GUADALUPE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'94', N'GUAINIA', N'886', N'CACAHUAL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'94', N'GUAINIA', N'887', N'PANA PANA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'94', N'GUAINIA', N'888', N'MORICHAL')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'95', N'GUAVIARE', N'001', N'SAN JOSE DEL GUAVIARE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'95', N'GUAVIARE', N'015', N'CALAMAR')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'95', N'GUAVIARE', N'025', N'EL RETORNO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'95', N'GUAVIARE', N'200', N'MIRAFLORES')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'97', N'VAUPES', N'001', N'MITU')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'97', N'VAUPES', N'161', N'CARURU')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'97', N'VAUPES', N'511', N'PACOA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'97', N'VAUPES', N'666', N'TARAIRA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'97', N'VAUPES', N'777', N'PAPUNAUA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'97', N'VAUPES', N'889', N'YAVARATE')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'99', N'VICHADA', N'001', N'PUERTO CARREÑO')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'99', N'VICHADA', N'524', N'LA PRIMAVERA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'99', N'VICHADA', N'624', N'SANTA ROSALIA')
INSERT [catalogo].[Municipios] ([CodigoDept], [NombreDept], [CodigoMuni], [NombreMuni]) VALUES (N'99', N'VICHADA', N'773', N'CUMARIBO')
GO
INSERT [catalogo].[Paises] ([Codigo1], [Codigo2], [Codigo3], [Nombre]) VALUES (N'CO', N'COL', N'170', N'COLOMBIA')
GO

-- ============================================================================
-- SEED DATA DE FABRICA — ejecutar siempre en una BD nueva
-- Estos datos son requeridos para que el sistema arranque correctamente.
-- ============================================================================
USE [NEXO_ERP]
GO

-- ── Seguridad.Roles ─────────────────────────────────────────────────────────
SET IDENTITY_INSERT [Seguridad].[Roles] ON
GO
INSERT [Seguridad].[Roles] ([RolID],[Nombre],[Descripcion],[Estado],[FechaCreacion]) VALUES
    (1, N'Administracion',  N'Acceso total al sistema',                                   1, GETUTCDATE()),
    (2, N'Produccion',      N'Gestion de ordenes de produccion y recetas',                1, GETUTCDATE()),
    (3, N'Inventario',      N'Control de stock, bodegas, traspasos y perdidas',           1, GETUTCDATE()),
    (4, N'Ventas',          N'Facturacion, CRM y cotizaciones',                           1, GETUTCDATE()),
    (5, N'Compras',         N'Ordenes de compra y recepcion de mercancia',                1, GETUTCDATE()),
    (6, N'RRHH',            N'Gestion de empleados, horarios y asistencia',               1, GETUTCDATE()),
    (7, N'Logistica',       N'Despachos y seguimiento de entregas',                       1, GETUTCDATE()),
    (8, N'Reportes',        N'Acceso de solo lectura a informes y dashboard',             1, GETUTCDATE())
GO
SET IDENTITY_INSERT [Seguridad].[Roles] OFF
GO

-- ── Kardex.TiposMovimientoKardex ─────────────────────────────────────────────
SET IDENTITY_INSERT [Kardex].[TiposMovimientoKardex] ON
GO
INSERT [Kardex].[TiposMovimientoKardex] ([TipoMovID],[Codigo],[Nombre],[Signo]) VALUES
    ( 1, N'ENTRADA_COMPRA',               N'Entrada por Orden de Compra',              1),
    ( 2, N'ENTRADA_PT',                   N'Entrada de Producto Terminado',             1),
    ( 3, N'ENTRADA_DEVOLUCION_CLIENTE',   N'Devolucion de cliente',                    1),
    ( 4, N'ENTRADA_DEVOLUCION_VISIONS',   N'Devolucion desde Visions',                 1),
    ( 5, N'TRASPASO_ENTRADA',             N'Entrada por Traspaso entre Bodegas',        1),
    ( 6, N'AJU_INV',                      N'Ajuste de Inventario',                     1),
    ( 7, N'SALIDA_VENTA_FACTURA',         N'Salida por Factura NEXO',                 -1),
    ( 8, N'SALIDA_VENTA_VISIONS',         N'Salida por Venta Visions',                -1),
    ( 9, N'SALIDA_WIP',                   N'Salida a Proceso Productivo (WIP)',        -1),
    (10, N'SALIDA_DEVOLUCION_PROVEEDOR',  N'Devolucion a Proveedor',                  -1),
    (11, N'TRASPASO_SALIDA',              N'Salida por Traspaso entre Bodegas',        -1),
    (12, N'BAJA_INVENTARIO',              N'Baja / Perdida de Inventario',             -1)
GO
SET IDENTITY_INSERT [Kardex].[TiposMovimientoKardex] OFF
GO

-- ── Produccion.EstadosOP ─────────────────────────────────────────────────────
SET IDENTITY_INSERT [Produccion].[EstadosOP] ON
GO
INSERT [Produccion].[EstadosOP] ([EstadoOPID],[Nombre],[Orden]) VALUES
    (1, N'Planificada', 1),
    (2, N'Liberada',    2),
    (3, N'En Proceso',  3),
    (4, N'Finalizada',  4),
    (5, N'Cancelada',   5)
GO
SET IDENTITY_INSERT [Produccion].[EstadosOP] OFF
GO

-- ── catalogo.TiposArticulo ───────────────────────────────────────────────────
SET IDENTITY_INSERT [catalogo].[TiposArticulo] ON
GO
INSERT [catalogo].[TiposArticulo] ([TipoArticuloID],[Codigo],[Nombre]) VALUES
    (1, N'MP',  N'Materia Prima'),
    (2, N'PT',  N'Producto Terminado'),
    (3, N'SV',  N'Servicio'),
    (4, N'ME',  N'Material de Empaque'),
    (5, N'RE',  N'Repuesto'),
    (6, N'OT',  N'Otro')
GO
SET IDENTITY_INSERT [catalogo].[TiposArticulo] OFF
GO

-- ── Kardex.TiposMotivoLoss ───────────────────────────────────────────────────
SET IDENTITY_INSERT [Kardex].[TiposMotivoLoss] ON
GO
INSERT [Kardex].[TiposMotivoLoss] ([MotivoID],[Nombre]) VALUES
    (1, N'Vencimiento'),
    (2, N'Deterioro o dano fisico'),
    (3, N'Error de conteo'),
    (4, N'Robo o hurto'),
    (5, N'Merma del proceso'),
    (6, N'Devolucion sin valor'),
    (7, N'Otro')
GO
SET IDENTITY_INSERT [Kardex].[TiposMotivoLoss] OFF
GO

-- ── catalogo.TiposIdentificacion ────────────────────────────────────────────
INSERT [catalogo].[TiposIdentificacion] ([Codigo],[Detalle]) VALUES
    (N'NIT', N'Numero de Identificacion Tributaria'),
    (N'CC',  N'Cedula de Ciudadania'),
    (N'CE',  N'Cedula de Extranjeria'),
    (N'PA',  N'Pasaporte'),
    (N'TI',  N'Tarjeta de Identidad'),
    (N'RUT', N'Registro Unico Tributario')
GO
