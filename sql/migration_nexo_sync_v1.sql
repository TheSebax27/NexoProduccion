-- migration_nexo_sync_v1.sql
-- NEXO_ERP: sincronizacion automatica bidireccional.
-- EJECUTAR UNA VEZ en NEXO_ERP (en SSMS).

-- 1. Columna de control: si la factura de NEXO ya fue escrita en MOVDETALLES de Visions.
IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA='Facturacion' AND TABLE_NAME='Facturas' AND COLUMN_NAME='ExportadaVisions')
BEGIN
    ALTER TABLE Facturacion.Facturas
        ADD ExportadaVisions BIT NOT NULL CONSTRAINT DF_Facturas_ExportadaVisions DEFAULT 0;
END
GO

-- 2. Actualizar sp_ProcesarEventoEntrante para que resuelva el articulo
--    automaticamente por Tarjetas.Referencia cuando no hay entrada en MapeoArticulos.
--    Antes: sin mapeo manual => evento queda pendiente para siempre.
--    Ahora: si Tarjetas.Referencia coincide con el codigo de Visions, se autocrea
--           el mapeo y se procesa la venta sin intervencion del administrador.
ALTER PROCEDURE [Integracion].[sp_ProcesarEventoEntrante]
    @EventoEntranteID BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CentroCostoID INT, @CodigoArticuloVisions NVARCHAR(30), @Cantidad DECIMAL(18,4), @Procesado BIT,
            @NombreVisions NVARCHAR(255), @CostoVisions DECIMAL(18,4), @PrecioVisions DECIMAL(18,4);

    SELECT
        @CentroCostoID           = CentroCostoID,
        @CodigoArticuloVisions   = CodigoArticuloVisions,
        @Cantidad                = Cantidad,
        @Procesado               = Procesado,
        @NombreVisions           = NombreArticuloVisions,
        @CostoVisions            = CostoArticuloVisions,
        @PrecioVisions           = PrecioArticuloVisions
    FROM Integracion.EventosEntrantes
    WHERE EventoEntranteID = @EventoEntranteID;

    IF @Procesado = 1
        RETURN;

    -- 1. Buscar mapeo explicito (tabla MapeoArticulos, sigue funcionando como override).
    DECLARE @ArticuloID INT;
    SELECT @ArticuloID = ArticuloID
    FROM Integracion.MapeoArticulos
    WHERE CodigoArticuloVisions = @CodigoArticuloVisions
      AND CentroCostoID = @CentroCostoID
      AND Estado = 1;

    -- 2. Si no hay mapeo explicito, resolver por Tarjetas.Referencia automaticamente.
    IF @ArticuloID IS NULL
    BEGIN
        SELECT @ArticuloID = ArticuloID
        FROM Catalogo.Tarjetas
        WHERE Referencia = @CodigoArticuloVisions AND Estado = 1;

        -- Auto-registrar el mapeo para que quede visible en la pantalla de mapeos.
        IF @ArticuloID IS NOT NULL
        BEGIN
            MERGE Integracion.MapeoArticulos AS d
            USING (SELECT @ArticuloID AS ArticuloID, @CentroCostoID AS CentroCostoID,
                          @CodigoArticuloVisions AS CodigoArticuloVisions) AS s
            ON d.ArticuloID = s.ArticuloID AND d.CentroCostoID = s.CentroCostoID
            WHEN NOT MATCHED THEN
                INSERT (ArticuloID, CentroCostoID, CodigoArticuloVisions, Estado)
                VALUES (@ArticuloID, @CentroCostoID, @CodigoArticuloVisions, 1);
        END
    END

    -- 3. Si aun no se resuelve: dejar como pendiente de revision del admin.
    IF @ArticuloID IS NULL
    BEGIN
        MERGE Integracion.ArticulosPendientesMapeo AS destino
        USING (SELECT @CentroCostoID AS CentroCostoID,
                      @CodigoArticuloVisions AS CodigoArticuloVisions) AS origen
        ON destino.CentroCostoID = origen.CentroCostoID
           AND destino.CodigoArticuloVisions = origen.CodigoArticuloVisions
        WHEN MATCHED THEN UPDATE SET
            NombreVisions     = @NombreVisions,
            CostoVisions      = @CostoVisions,
            PrecioVisions     = @PrecioVisions,
            CantidadDetectada = @Cantidad,
            FechaDetectado    = SYSUTCDATETIME(),
            Resuelto          = 0,
            FechaResuelto     = NULL
        WHEN NOT MATCHED THEN
            INSERT (CentroCostoID, CodigoArticuloVisions, NombreVisions,
                    CostoVisions, PrecioVisions, CantidadDetectada)
            VALUES (@CentroCostoID, @CodigoArticuloVisions, @NombreVisions,
                    @CostoVisions, @PrecioVisions, @Cantidad);
        RETURN;
    END

    DECLARE @BodegaVentaID INT = (
        SELECT BodegaVentaVisionsID FROM Organizacion.CentrosCosto WHERE CentroCostoID = @CentroCostoID);

    IF @BodegaVentaID IS NULL
        THROW 54001, 'El Centro de Costo no tiene configurada una Bodega de Venta Visions; revisar Catalogo > Centros de Costo.', 1;

    BEGIN TRANSACTION;

    MERGE Integracion.InventarioReportadoVisions AS destino
    USING (SELECT @ArticuloID AS ArticuloID, @CentroCostoID AS CentroCostoID) AS origen
    ON destino.ArticuloID = origen.ArticuloID AND destino.CentroCostoID = origen.CentroCostoID
    WHEN MATCHED THEN UPDATE SET
        CantidadVendidaAcumulada = destino.CantidadVendidaAcumulada + @Cantidad,
        UltimaActualizacion      = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN
        INSERT (ArticuloID, CentroCostoID, CantidadVendidaAcumulada)
        VALUES (@ArticuloID, @CentroCostoID, @Cantidad);

    DECLARE @TipoSalida INT = (
        SELECT TipoMovID FROM Kardex.TiposMovimientoKardex WHERE Codigo = 'SALIDA_VENTA_VISIONS');
    DECLARE @UsuarioSistemaID INT = (
        SELECT UsuarioID FROM Seguridad.Usuarios WHERE Username = 'sistema.sync');
    DECLARE @Pendiente DECIMAL(18,4) = @Cantidad;
    DECLARE @InvID BIGINT, @LoteID INT, @CantidadLote DECIMAL(18,4), @CostoLote DECIMAL(18,4);

    DECLARE curLotes CURSOR LOCAL FAST_FORWARD FOR
        SELECT s.InventarioID, s.LoteID, s.CantidadActual, s.CostoUnitarioLote
        FROM Inventario.InventarioStock s
        LEFT JOIN Inventario.Lotes l ON l.LoteID = s.LoteID
        WHERE s.ArticuloID = @ArticuloID AND s.BodegaID = @BodegaVentaID AND s.CantidadActual > 0
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
            WHERE ArticuloID = @ArticuloID AND BodegaID = @BodegaVentaID);

        INSERT INTO Kardex.KardexMovimientos
            (ArticuloID, BodegaID, LoteID, TipoMovID, CentroCostoID,
             Cantidad, CostoUnitario, CantidadSaldo, CostoPromedioSaldo, ObservacionDetallada, UsuarioID)
        VALUES
            (@ArticuloID, @BodegaVentaID, @LoteID, @TipoSalida, @CentroCostoID,
             @Tomar, @CostoLote, @NuevoSaldo, @CostoLote,
             CONCAT('Venta Visions - Evento entrante #', @EventoEntranteID), @UsuarioSistemaID);

        SET @Pendiente -= @Tomar;
        FETCH NEXT FROM curLotes INTO @InvID, @LoteID, @CantidadLote, @CostoLote;
    END
    CLOSE curLotes; DEALLOCATE curLotes;

    IF @Pendiente > 0
    BEGIN
        IF EXISTS (SELECT 1 FROM Inventario.InventarioStock
                   WHERE ArticuloID = @ArticuloID AND BodegaID = @BodegaVentaID AND LoteID IS NULL)
            UPDATE Inventario.InventarioStock
            SET CantidadActual = CantidadActual - @Pendiente, FechaUltimaActualizacion = SYSUTCDATETIME()
            WHERE ArticuloID = @ArticuloID AND BodegaID = @BodegaVentaID AND LoteID IS NULL;
        ELSE
            INSERT INTO Inventario.InventarioStock (ArticuloID, BodegaID, LoteID, CantidadActual, CostoUnitarioLote)
            VALUES (@ArticuloID, @BodegaVentaID, NULL, -@Pendiente, 0);

        DECLARE @NuevoSaldoFinal DECIMAL(18,4) = (
            SELECT SUM(CantidadActual) FROM Inventario.InventarioStock
            WHERE ArticuloID = @ArticuloID AND BodegaID = @BodegaVentaID);

        INSERT INTO Kardex.KardexMovimientos
            (ArticuloID, BodegaID, LoteID, TipoMovID, CentroCostoID,
             Cantidad, CostoUnitario, CantidadSaldo, CostoPromedioSaldo, ObservacionDetallada, UsuarioID)
        VALUES
            (@ArticuloID, @BodegaVentaID, NULL, @TipoSalida, @CentroCostoID,
             @Pendiente, 0, @NuevoSaldoFinal, 0,
             CONCAT('Venta Visions - Evento entrante #', @EventoEntranteID, ' (stock insuficiente, queda en negativo)'),
             @UsuarioSistemaID);
    END

    UPDATE Integracion.EventosEntrantes
    SET Procesado = 1, FechaProcesado = SYSUTCDATETIME()
    WHERE EventoEntranteID = @EventoEntranteID;

    COMMIT TRANSACTION;
END
GO
