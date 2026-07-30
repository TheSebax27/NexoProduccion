/* ============================================================================
   SISTEMA NEXO - Script 05b: Enganche de Produccion -> Integracion
   Ejecutar despues de 05_integracion_nexo.sql

   Redefine (CREATE OR ALTER, no se pierde nada) dos procedimientos que ya
   existian en 03_logica_negocio.sql, agregando SOLO la emision del evento
   de salida cuando el centro de costo destino tiene Visions activo. Toda
   la logica original de negocio queda identica.
   ============================================================================ */
USE NEXO_ERP;
GO

CREATE OR ALTER PROCEDURE Produccion.sp_CerrarOrdenProduccion
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

CREATE OR ALTER PROCEDURE Inventario.sp_RecibirTraspaso
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

PRINT 'Procedimientos de Produccion e Inventario actualizados con enganche de integracion.';