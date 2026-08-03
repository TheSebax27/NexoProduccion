/* ============================================================================
   NEXO ERP - FIX: sp_AjustarConsumoReal solo actualizaba el numero guardado en
   Produccion.OrdenesProduccionConsumo.CantidadReal, pero NUNCA tocaba
   Inventario.InventarioStock ni generaba movimiento en Kardex. Resultado: si
   ajustabas el consumo real hacia arriba (se uso mas material del previsto),
   el sistema seguia creyendo que habia mas stock del que realmente queda
   fisicamente -- y si lo ajustabas hacia abajo (se uso menos), el material no
   usado nunca se devolvia al inventario.

   Ahora: calcula el delta entre la cantidad real anterior (ya reflejada en el
   stock) y la nueva, y:
   - Delta > 0 (exceso adicional): descuenta la diferencia del mismo lote de
     donde se tomo originalmente (Kardex tipo SALIDA_WIP).
   - Delta < 0 (se uso menos): devuelve la diferencia al mismo lote (Kardex
     tipo AJU_INV, que ya existe y encaja semanticamente con "devolucion").
   ============================================================================ */

USE NEXO_ERP;
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE Produccion.sp_AjustarConsumoReal
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

PRINT 'sp_AjustarConsumoReal corregido: ahora si mueve InventarioStock y genera Kardex.';
GO
