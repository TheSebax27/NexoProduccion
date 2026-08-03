/* ============================================================================
   NEXO ERP - Ajuste de Inventario (entrada positiva sin orden de compra)
   Permite cargar stock inicial o corregir por conteo fisico, sin inventar
   una Orden de Compra falsa. Sigue el mismo patron que Kardex.sp_RegistrarBajaInventario
   pero en sentido contrario (usa el tipo de movimiento AJU_INV, ya sembrado en
   DatosSemilla.sql).

   Ya aplicado en la base de datos NEXO_ERP local (DESKTOP-V83PQ7M\JONATHAN).
   Este script queda aqui para que quede versionado junto al resto de scripts
   de procesos, y para poder recrear el objeto en otro ambiente.
   ============================================================================ */

USE NEXO_ERP;
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID('Kardex.AjustesInventario') IS NULL
BEGIN
    CREATE TABLE Kardex.AjustesInventario(
        AjusteID INT IDENTITY(1,1) NOT NULL,
        CodigoAjuste NVARCHAR(30) NOT NULL,
        Fecha DATETIME2(7) NOT NULL,
        ArticuloID INT NOT NULL,
        BodegaID INT NOT NULL,
        LoteID INT NULL,
        CantidadAjustada DECIMAL(18,4) NOT NULL,
        CostoUnitario DECIMAL(18,4) NOT NULL,
        CostoTotal AS (CantidadAjustada * CostoUnitario) PERSISTED,
        Motivo NVARCHAR(300) NOT NULL,
        UsuarioRegistraID INT NOT NULL,
        PRIMARY KEY CLUSTERED (AjusteID ASC)
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
        CONSTRAINT UQ_AjusteInventario_Codigo UNIQUE NONCLUSTERED (CodigoAjuste ASC)
            WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
    ) ON [PRIMARY];

    PRINT 'Tabla Kardex.AjustesInventario creada.';
END
ELSE
    PRINT 'Tabla Kardex.AjustesInventario ya existia, se omite.';
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('Kardex.KardexMovimientos') AND name = 'AjusteID'
)
BEGIN
    ALTER TABLE Kardex.KardexMovimientos ADD AjusteID INT NULL;
    PRINT 'Columna Kardex.KardexMovimientos.AjusteID agregada.';
END
ELSE
    PRINT 'Columna Kardex.KardexMovimientos.AjusteID ya existia, se omite.';
GO

CREATE OR ALTER PROCEDURE Kardex.sp_AjustePositivoInventario
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

    IF NOT EXISTS (SELECT 1 FROM Catalogo.Articulos WHERE ArticuloID = @ArticuloID)
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
    DECLARE @CostoPromedioPrevio DECIMAL(18,4) = (SELECT CostoPromedio FROM Catalogo.Articulos WHERE ArticuloID = @ArticuloID);
    DECLARE @NuevoCostoPromedio DECIMAL(18,4) =
        CASE WHEN @StockPrevio IS NULL OR @StockPrevio <= 0 OR @CostoPromedioPrevio IS NULL THEN @CostoUnitario
             ELSE ((@StockPrevio * @CostoPromedioPrevio) + (@Cantidad * @CostoUnitario)) / (@StockPrevio + @Cantidad)
        END;

    UPDATE Catalogo.Articulos SET CostoPromedio = @NuevoCostoPromedio WHERE ArticuloID = @ArticuloID;

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

PRINT 'Kardex.sp_AjustePositivoInventario creado/actualizado correctamente.';
GO
