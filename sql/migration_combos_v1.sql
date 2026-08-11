-- =============================================================
-- NEXO ERP  |  Módulo Combos / Ofertas  |  v1
-- =============================================================

-- ── 1. Marketing.Combos ──────────────────────────────────────
CREATE TABLE Marketing.Combos (
    ComboID          INT IDENTITY(1,1) PRIMARY KEY,
    Nombre           NVARCHAR(150) NOT NULL,
    Descripcion      NVARCHAR(500) NULL,
    ImagenBase64     NVARCHAR(MAX) NULL,
    ImagenContentType NVARCHAR(100) NULL,
    Estado           NVARCHAR(20)  NOT NULL DEFAULT 'Borrador'
                     CONSTRAINT CK_Combos_Estado CHECK (Estado IN ('Activo','Inactivo','Borrador')),
    FechaInicio      DATE NULL,
    FechaFin         DATE NULL,
    ModoPrecio       NVARCHAR(10)  NOT NULL DEFAULT 'MANUAL'
                     CONSTRAINT CK_Combos_ModoPrecio CHECK (ModoPrecio IN ('MANUAL','CALCULADO')),
    PrecioManual     DECIMAL(18,2) NULL,
    PorcentajeDescuento DECIMAL(5,2) NOT NULL DEFAULT 0
                     CONSTRAINT CK_Combos_Descuento CHECK (PorcentajeDescuento BETWEEN 0 AND 100),
    FechaCreacion    DATETIME NOT NULL DEFAULT GETDATE(),
    UsuarioCreaID    INT NULL
                     CONSTRAINT FK_Combos_Usuario FOREIGN KEY REFERENCES Seguridad.Usuarios(UsuarioID)
);

-- ── 2. Marketing.ComboItems ──────────────────────────────────
CREATE TABLE Marketing.ComboItems (
    ComboItemID             INT IDENTITY(1,1) PRIMARY KEY,
    ComboID                 INT NOT NULL
                            CONSTRAINT FK_ComboItems_Combo FOREIGN KEY REFERENCES Marketing.Combos(ComboID) ON DELETE CASCADE,
    ArticuloID              INT NOT NULL
                            CONSTRAINT FK_ComboItems_Articulo FOREIGN KEY REFERENCES Catalogo.Articulos(ArticuloID),
    Cantidad                DECIMAL(18,4) NOT NULL,
    PrecioUnitarioSnapshot  DECIMAL(18,2) NULL
);

CREATE INDEX IX_ComboItems_Combo ON Marketing.ComboItems(ComboID);

-- ── 3. Facturacion.FacturaLineas — nuevas columnas ───────────
ALTER TABLE Facturacion.FacturaLineas
    ADD ComboID        INT NULL
                       CONSTRAINT FK_FacturaLineas_Combo FOREIGN KEY REFERENCES Marketing.Combos(ComboID),
        DescripcionLinea NVARCHAR(200) NULL;

-- Hacer ArticuloID nullable y agregar constraint
ALTER TABLE Facturacion.FacturaLineas ALTER COLUMN ArticuloID INT NULL;

ALTER TABLE Facturacion.FacturaLineas
    ADD CONSTRAINT CK_FacturaLineas_ArticuloOCombo
        CHECK (ArticuloID IS NOT NULL OR ComboID IS NOT NULL);

-- ── 4. SP — cursor solo sobre líneas con artículo ────────────
GO
ALTER PROCEDURE Facturacion.sp_DescontarStockFactura
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

    -- Valida stock de líneas con artículo (combos se omiten)
    DECLARE @ArticulosSinStock NVARCHAR(2000);
    SELECT @ArticulosSinStock = STRING_AGG(a.SKU + ' - ' + a.Nombre
        + ' (necesario: ' + CAST(fl.Cantidad AS NVARCHAR(20))
        + ', disponible: ' + CAST(ISNULL(s.Total, 0) AS NVARCHAR(20)) + ')', '; ')
    FROM Facturacion.FacturaLineas fl
    JOIN Catalogo.Articulos a ON a.ArticuloID = fl.ArticuloID
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

    -- Solo líneas con artículo; combos no mueven stock
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
PRINT 'migration_combos_v1.sql ejecutado OK';
