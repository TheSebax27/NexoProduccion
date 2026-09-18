-- Parche aislamiento CC en stock: sp_DescontarStockFactura + sp_DescontarStockFactura_Receta
-- Ejecutar sobre NEXO_ERP en produccion (45.171.180.182\VISIONS)
-- Es seguro re-ejecutar: CREATE OR ALTER no afecta datos.

-- ============================================================
-- 1. sp_DescontarStockFactura
-- ============================================================
CREATE OR ALTER PROCEDURE [Facturacion].[sp_DescontarStockFactura]
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

    DECLARE @FacCC INT = (SELECT CentroCostoID FROM Facturacion.Facturas WHERE FacturaID = @FacturaID);

    -- Valida stock solo de lineas con articulo (combos no mueven stock)
    DECLARE @ArticulosSinStock NVARCHAR(2000);
    SELECT @ArticulosSinStock = STUFF((
        SELECT '; ' + (a.Referencia + ' - ' + a.Nombre
            + ' (necesario: ' + CAST(fl.Cantidad AS NVARCHAR(20))
            + ', disponible: ' + CAST(ISNULL(s.Total, 0) AS NVARCHAR(20)) + ')')
        FROM Facturacion.FacturaLineas fl
        JOIN Catalogo.Tarjetas a ON a.ArticuloID = fl.ArticuloID
        LEFT JOIN (
            SELECT s2.ArticuloID, SUM(s2.CantidadActual) AS Total
            FROM Inventario.InventarioStock s2
            JOIN Inventario.Bodegas b2 ON b2.BodegaID = s2.BodegaID
            WHERE b2.CentroCostoID = @FacCC
            GROUP BY s2.ArticuloID
        ) s ON s.ArticuloID = fl.ArticuloID
        WHERE fl.FacturaID = @FacturaID
          AND fl.ArticuloID IS NOT NULL
          AND fl.Cantidad > ISNULL(s.Total, 0)
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), 1, 2, '');

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
              AND b.CentroCostoID = @FacCC
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

-- ============================================================
-- 2. sp_DescontarStockFactura_Receta (v2 hibrido + CC isolation)
-- ============================================================
CREATE OR ALTER PROCEDURE Facturacion.sp_DescontarStockFactura_Receta
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

    DECLARE @FacCC      INT = (SELECT CentroCostoID FROM Facturacion.Facturas WHERE FacturaID = @FacturaID);
    DECLARE @TipoSalida INT = (SELECT TipoMovID FROM Kardex.TiposMovimientoKardex WHERE Codigo = 'SALIDA_VENTA_FACTURA');

    -- Variables del cursor principal
    DECLARE @ArticuloID    INT;
    DECLARE @CantidadLinea DECIMAL(18,4);
    DECLARE @StockPT       DECIMAL(18,4);

    -- Variables rama A (PT en stock)
    DECLARE @Pendiente1 DECIMAL(18,4);
    DECLARE @InvID1     INT;
    DECLARE @LoteID1    INT;
    DECLARE @BodegaID1  INT;
    DECLARE @CC1        INT;
    DECLARE @CantLote1  DECIMAL(18,4);
    DECLARE @Costo1     DECIMAL(18,4);
    DECLARE @Tomar1     DECIMAL(18,4);
    DECLARE @Saldo1     DECIMAL(18,4);

    -- Variables rama B (insumos de receta)
    DECLARE @NombreArt  NVARCHAR(200);
    DECLARE @MsgSR      NVARCHAR(2200);
    DECLARE @InsumoID   INT;
    DECLARE @CantInsumo DECIMAL(18,4);
    DECLARE @PendIns    DECIMAL(18,4);
    DECLARE @InvID2     INT;
    DECLARE @LoteID2    INT;
    DECLARE @BodegaID2  INT;
    DECLARE @CC2        INT;
    DECLARE @CantLote2  DECIMAL(18,4);
    DECLARE @Costo2     DECIMAL(18,4);
    DECLARE @Tomar2     DECIMAL(18,4);
    DECLARE @Saldo2     DECIMAL(18,4);
    DECLARE @InsInsuf   NVARCHAR(2000);
    DECLARE @MsgI       NVARCHAR(2200);

    -- Tabla de insumos por articulo; se limpia con DELETE antes de cada uso
    DECLARE @InsumosArt TABLE (ArticuloID INT, CantidadTotal DECIMAL(18,4));

    BEGIN TRANSACTION;

    DECLARE curLineas CURSOR LOCAL FAST_FORWARD FOR
        SELECT ArticuloID, Cantidad
        FROM Facturacion.FacturaLineas
        WHERE FacturaID = @FacturaID AND ArticuloID IS NOT NULL;

    OPEN curLineas;
    FETCH NEXT FROM curLineas INTO @ArticuloID, @CantidadLinea;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @StockPT = ISNULL(SUM(s.CantidadActual), 0)
        FROM Inventario.InventarioStock s
        JOIN Inventario.Bodegas b ON b.BodegaID = s.BodegaID
        WHERE s.ArticuloID = @ArticuloID AND b.CentroCostoID = @FacCC;

        IF @StockPT >= @CantidadLinea
        BEGIN
            -- Rama A: PT en stock (OP ya manejo insumos)
            SET @Pendiente1 = @CantidadLinea;

            DECLARE curLotesPT CURSOR LOCAL FAST_FORWARD FOR
                SELECT s.InventarioID, s.LoteID, s.BodegaID, b.CentroCostoID, s.CantidadActual, s.CostoUnitarioLote
                FROM Inventario.InventarioStock s
                JOIN Inventario.Bodegas b ON b.BodegaID = s.BodegaID
                LEFT JOIN Inventario.Lotes l ON l.LoteID = s.LoteID
                WHERE s.ArticuloID = @ArticuloID AND s.CantidadActual > 0
                  AND b.CentroCostoID = @FacCC
                  AND (l.Estado IS NULL OR l.Estado = 'APROBADO')
                ORDER BY ISNULL(l.FechaVencimiento, '9999-12-31') ASC, s.InventarioID ASC;

            OPEN curLotesPT;
            FETCH NEXT FROM curLotesPT INTO @InvID1, @LoteID1, @BodegaID1, @CC1, @CantLote1, @Costo1;

            WHILE @@FETCH_STATUS = 0 AND @Pendiente1 > 0
            BEGIN
                SET @Tomar1 = CASE WHEN @CantLote1 >= @Pendiente1 THEN @Pendiente1 ELSE @CantLote1 END;

                UPDATE Inventario.InventarioStock
                SET CantidadActual = CantidadActual - @Tomar1, FechaUltimaActualizacion = SYSUTCDATETIME()
                WHERE InventarioID = @InvID1;

                SET @Saldo1 = (
                    SELECT SUM(CantidadActual) FROM Inventario.InventarioStock
                    WHERE ArticuloID = @ArticuloID AND BodegaID = @BodegaID1
                );

                INSERT INTO Kardex.KardexMovimientos
                    (ArticuloID, BodegaID, LoteID, TipoMovID, CentroCostoID,
                     Cantidad, CostoUnitario, CantidadSaldo, CostoPromedioSaldo, ObservacionDetallada, UsuarioID)
                VALUES
                    (@ArticuloID, @BodegaID1, @LoteID1, @TipoSalida, @CC1,
                     @Tomar1, @Costo1, @Saldo1, @Costo1,
                     CONCAT('Factura #', @FacturaID, ' (PT stock)'), @UsuarioID);

                SET @Pendiente1 -= @Tomar1;
                FETCH NEXT FROM curLotesPT INTO @InvID1, @LoteID1, @BodegaID1, @CC1, @CantLote1, @Costo1;
            END
            CLOSE curLotesPT; DEALLOCATE curLotesPT;

            IF @Pendiente1 > 0
                THROW 57011, 'Stock insuficiente al descontar PT: posible modificacion concurrente.', 1;
        END
        ELSE
        BEGIN
            -- Rama B: sin stock de PT — descuenta insumos de la receta
            IF NOT EXISTS (
                SELECT 1 FROM Produccion.RecetaBOM
                WHERE ProductoTerminadoID = @ArticuloID AND Estado = 1
            )
            BEGIN
                SET @NombreArt = (SELECT Referencia + ' - ' + Nombre FROM Catalogo.Tarjetas WHERE ArticuloID = @ArticuloID);
                SET @MsgSR = 'No tiene receta activa para: ' + ISNULL(@NombreArt, CAST(@ArticuloID AS NVARCHAR(10)));
                THROW 57010, @MsgSR, 1;
            END

            DELETE FROM @InsumosArt;

            INSERT INTO @InsumosArt (ArticuloID, CantidadTotal)
            SELECT
                bd.InsumoID,
                SUM(bd.CantidadRequerida * (@CantidadLinea / r.CantidadRendimientoBase))
            FROM Produccion.RecetaBOM r
            JOIN Produccion.RecetaBOM_Detalle bd ON bd.RecetaID = r.RecetaID
            WHERE r.RecetaID = (
                SELECT TOP 1 RecetaID
                FROM Produccion.RecetaBOM
                WHERE ProductoTerminadoID = @ArticuloID AND Estado = 1
                ORDER BY RecetaID
            )
            GROUP BY bd.InsumoID;

            SET @InsInsuf = NULL;
            SELECT @InsInsuf = STUFF((
                SELECT '; ' + (a.Referencia + ' - ' + a.Nombre
                    + ' (nec: ' + CAST(CAST(i.CantidadTotal AS DECIMAL(18,2)) AS NVARCHAR(20))
                    + ', disp: ' + CAST(ISNULL(s.Total,0) AS NVARCHAR(20)) + ')')
                FROM @InsumosArt i
                JOIN Catalogo.Tarjetas a ON a.ArticuloID = i.ArticuloID
                LEFT JOIN (
                    SELECT s2.ArticuloID, SUM(s2.CantidadActual) AS Total
                    FROM Inventario.InventarioStock s2
                    JOIN Inventario.Bodegas b2 ON b2.BodegaID = s2.BodegaID
                    WHERE b2.CentroCostoID = @FacCC
                    GROUP BY s2.ArticuloID
                ) s ON s.ArticuloID = i.ArticuloID
                WHERE i.CantidadTotal > ISNULL(s.Total, 0)
                FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)'), 1, 2, '');

            IF @InsInsuf IS NOT NULL
            BEGIN
                SET @MsgI = 'Stock insuficiente en insumos: ' + @InsInsuf;
                THROW 57004, @MsgI, 1;
            END

            DECLARE curIns CURSOR LOCAL FAST_FORWARD FOR
                SELECT ArticuloID, CantidadTotal FROM @InsumosArt;

            OPEN curIns;
            FETCH NEXT FROM curIns INTO @InsumoID, @CantInsumo;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @PendIns = @CantInsumo;

                DECLARE curLotesIns CURSOR LOCAL FAST_FORWARD FOR
                    SELECT s.InventarioID, s.LoteID, s.BodegaID, b.CentroCostoID, s.CantidadActual, s.CostoUnitarioLote
                    FROM Inventario.InventarioStock s
                    JOIN Inventario.Bodegas b ON b.BodegaID = s.BodegaID
                    LEFT JOIN Inventario.Lotes l ON l.LoteID = s.LoteID
                    WHERE s.ArticuloID = @InsumoID AND s.CantidadActual > 0
                      AND b.CentroCostoID = @FacCC
                      AND (l.Estado IS NULL OR l.Estado = 'APROBADO')
                    ORDER BY ISNULL(l.FechaVencimiento, '9999-12-31') ASC, s.InventarioID ASC;

                OPEN curLotesIns;
                FETCH NEXT FROM curLotesIns INTO @InvID2, @LoteID2, @BodegaID2, @CC2, @CantLote2, @Costo2;

                WHILE @@FETCH_STATUS = 0 AND @PendIns > 0
                BEGIN
                    SET @Tomar2 = CASE WHEN @CantLote2 >= @PendIns THEN @PendIns ELSE @CantLote2 END;

                    UPDATE Inventario.InventarioStock
                    SET CantidadActual = CantidadActual - @Tomar2, FechaUltimaActualizacion = SYSUTCDATETIME()
                    WHERE InventarioID = @InvID2;

                    SET @Saldo2 = (
                        SELECT SUM(CantidadActual) FROM Inventario.InventarioStock
                        WHERE ArticuloID = @InsumoID AND BodegaID = @BodegaID2
                    );

                    INSERT INTO Kardex.KardexMovimientos
                        (ArticuloID, BodegaID, LoteID, TipoMovID, CentroCostoID,
                         Cantidad, CostoUnitario, CantidadSaldo, CostoPromedioSaldo, ObservacionDetallada, UsuarioID)
                    VALUES
                        (@InsumoID, @BodegaID2, @LoteID2, @TipoSalida, @CC2,
                         @Tomar2, @Costo2, @Saldo2, @Costo2,
                         CONCAT('Factura #', @FacturaID, ' (insumo receta)'), @UsuarioID);

                    SET @PendIns -= @Tomar2;
                    FETCH NEXT FROM curLotesIns INTO @InvID2, @LoteID2, @BodegaID2, @CC2, @CantLote2, @Costo2;
                END
                CLOSE curLotesIns; DEALLOCATE curLotesIns;

                FETCH NEXT FROM curIns INTO @InsumoID, @CantInsumo;
            END
            CLOSE curIns; DEALLOCATE curIns;
        END

        FETCH NEXT FROM curLineas INTO @ArticuloID, @CantidadLinea;
    END
    CLOSE curLineas; DEALLOCATE curLineas;

    UPDATE Facturacion.Facturas SET StockDescontado = 1 WHERE FacturaID = @FacturaID;
    COMMIT TRANSACTION;
    SELECT @FacturaID AS FacturaID;
END;
GO
