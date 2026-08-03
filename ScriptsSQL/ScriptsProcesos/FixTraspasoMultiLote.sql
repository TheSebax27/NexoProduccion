/* ============================================================================
   NEXO ERP - FIX: sp_CrearYEnviarTraspaso solo buscaba stock SIN lote
   (LoteID IS NULL) cuando el detalle no especificaba un lote exacto -- pero
   la pantalla "Nuevo Traspaso" nunca pide elegir lote, y CASI TODO el stock
   real tiene lote asignado (todo lo que entra por Compra o Produccion crea
   un Lote). Resultado: cualquier traspaso de un articulo con stock real
   fallaba con "Stock insuficiente" aunque sobrara inventario.

   Se corrige igual que sp_IniciarOrdenProduccion: cuando no se pide un lote
   especifico (LoteID NULL en el detalle), se toma de TODOS los lotes
   disponibles por FEFO (primero vence, primero sale) hasta cubrir la
   cantidad, generando una linea de TraspasosDetalle/Kardex POR CADA LOTE
   consumido. Si el detalle SI trae un LoteID especifico, se respeta la
   busqueda exacta (comportamiento anterior, sin cambios en ese caso).
   ============================================================================ */

USE NEXO_ERP;
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE Inventario.sp_CrearYEnviarTraspaso
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
            -- No se pidio un lote especifico: se toma de TODOS los lotes
            -- disponibles por FEFO (igual criterio que sp_IniciarOrdenProduccion),
            -- generando una linea de detalle/kardex por cada lote consumido.
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

PRINT 'sp_CrearYEnviarTraspaso corregido: ahora consume de todos los lotes disponibles (FEFO) cuando no se pide un lote especifico.';
GO
