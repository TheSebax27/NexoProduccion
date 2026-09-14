-- VentaDesdeReceta: cuando activo, DescontarStock descuenta insumos de receta
-- en vez de stock del PT. Compatible con facturas NEXO directo y Visions.

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('Organizacion.ConfiguracionEmpresa') AND name = 'VentaDesdeReceta'
)
    ALTER TABLE Organizacion.ConfiguracionEmpresa
        ADD VentaDesdeReceta BIT NOT NULL DEFAULT 0;
GO

CREATE PROCEDURE Facturacion.sp_DescontarStockFactura_Receta
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

    -- Falla si alguna linea PT no tiene receta activa
    DECLARE @SinReceta NVARCHAR(2000);
    SELECT @SinReceta = STUFF((
        SELECT '; ' + (a.Referencia + ' - ' + a.Nombre)
        FROM Facturacion.FacturaLineas fl
        JOIN Catalogo.Tarjetas a ON a.ArticuloID = fl.ArticuloID
        WHERE fl.FacturaID = @FacturaID
          AND fl.ArticuloID IS NOT NULL
          AND NOT EXISTS (
              SELECT 1 FROM Produccion.RecetaBOM r
              WHERE r.ProductoTerminadoID = fl.ArticuloID AND r.Estado = 1
          )
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), 1, 2, '');

    IF @SinReceta IS NOT NULL
    BEGIN
        DECLARE @MsgReceta NVARCHAR(2200) =
            'Modo Venta desde Receta activo: los siguientes articulos no tienen receta activa: ' + @SinReceta;
        THROW 57010, @MsgReceta, 1;
    END

    -- Calcular insumos a descontar: consumo = qty_insumo * (qty_vendida / rendimiento_base)
    DECLARE @InsumosADescontar TABLE (
        ArticuloID    INT,
        CantidadTotal DECIMAL(18,4)
    );

    INSERT INTO @InsumosADescontar (ArticuloID, CantidadTotal)
    SELECT
        bd.InsumoID,
        SUM(bd.CantidadRequerida * (fl.Cantidad / r.CantidadRendimientoBase)) AS CantidadTotal
    FROM Facturacion.FacturaLineas fl
    JOIN Produccion.RecetaBOM r ON r.ProductoTerminadoID = fl.ArticuloID AND r.Estado = 1
    JOIN Produccion.RecetaBOM_Detalle bd ON bd.RecetaID = r.RecetaID
    WHERE fl.FacturaID = @FacturaID
      AND fl.ArticuloID IS NOT NULL
    GROUP BY bd.InsumoID;

    -- Validar stock de insumos
    DECLARE @InsumosInsuficientes NVARCHAR(2000);
    SELECT @InsumosInsuficientes = STUFF((
        SELECT '; ' + (a.Referencia + ' - ' + a.Nombre
            + ' (necesario: ' + CAST(CAST(i.CantidadTotal AS DECIMAL(18,4)) AS NVARCHAR(20))
            + ', disponible: ' + CAST(ISNULL(s.Total, 0) AS NVARCHAR(20)) + ')')
        FROM @InsumosADescontar i
        JOIN Catalogo.Tarjetas a ON a.ArticuloID = i.ArticuloID
        LEFT JOIN (
            SELECT ArticuloID, SUM(CantidadActual) AS Total
            FROM Inventario.InventarioStock
            GROUP BY ArticuloID
        ) s ON s.ArticuloID = i.ArticuloID
        WHERE i.CantidadTotal > ISNULL(s.Total, 0)
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), 1, 2, '');

    IF @InsumosInsuficientes IS NOT NULL
    BEGIN
        DECLARE @MsgStock NVARCHAR(2200) = 'Stock insuficiente en insumos: ' + @InsumosInsuficientes;
        THROW 57004, @MsgStock, 1;
    END

    DECLARE @TipoSalida INT = (SELECT TipoMovID FROM Kardex.TiposMovimientoKardex WHERE Codigo = 'SALIDA_VENTA_FACTURA');

    BEGIN TRANSACTION;

    DECLARE @ArticuloID INT, @CantidadLinea DECIMAL(18,4);

    DECLARE curInsumos CURSOR LOCAL FAST_FORWARD FOR
        SELECT ArticuloID, CantidadTotal FROM @InsumosADescontar;

    OPEN curInsumos;
    FETCH NEXT FROM curInsumos INTO @ArticuloID, @CantidadLinea;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @Pendiente DECIMAL(18,4) = @CantidadLinea;
        DECLARE @InvID INT, @LoteID INT, @BodegaID INT, @CentroCostoID INT,
                @CantidadLote DECIMAL(18,4), @CostoLote DECIMAL(18,4);

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
                SELECT SUM(CantidadActual) FROM Inventario.InventarioStock
                WHERE ArticuloID = @ArticuloID AND BodegaID = @BodegaID
            );

            INSERT INTO Kardex.KardexMovimientos
                (ArticuloID, BodegaID, LoteID, TipoMovID, CentroCostoID, Cantidad, CostoUnitario,
                 CantidadSaldo, CostoPromedioSaldo, ObservacionDetallada, UsuarioID)
            VALUES
                (@ArticuloID, @BodegaID, @LoteID, @TipoSalida, @CentroCostoID, @Tomar, @CostoLote,
                 @NuevoSaldo, @CostoLote,
                 CONCAT('Factura #', @FacturaID, ' (insumo receta)'), @UsuarioID);

            SET @Pendiente -= @Tomar;
            FETCH NEXT FROM curLotes INTO @InvID, @LoteID, @BodegaID, @CentroCostoID, @CantidadLote, @CostoLote;
        END
        CLOSE curLotes; DEALLOCATE curLotes;

        FETCH NEXT FROM curInsumos INTO @ArticuloID, @CantidadLinea;
    END
    CLOSE curInsumos; DEALLOCATE curInsumos;

    UPDATE Facturacion.Facturas SET StockDescontado = 1 WHERE FacturaID = @FacturaID;

    COMMIT TRANSACTION;

    SELECT @FacturaID AS FacturaID;
END;
GO
