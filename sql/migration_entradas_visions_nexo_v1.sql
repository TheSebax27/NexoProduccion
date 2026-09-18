-- migration_entradas_visions_nexo_v1.sql
-- NEXO ERP: sync de entradas de inventario VISIONS → NEXO.
-- EJECUTAR en nexoVisions (45.171.180.182\VISIONS, BD nexoVisions).
--
-- Crea sp_ProcesarEntradaCompraVisions: procesa un EventoEntrante de tipo ENTRADA_COMPRA
-- (enviado por TareaExportarEntradasVisions cuando el usuario recibe mercancia en FRMENTRADAS
-- de Visions sin OC previa en NEXO).
-- Logica: igual que sp_ProcesarDevolucionVisions pero usa tipo ENTRADA_COMPRA en Kardex.

GO
CREATE OR ALTER PROCEDURE Integracion.sp_ProcesarEntradaCompraVisions
    @EventoEntranteID BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @CentroCostoID INT, @CodigoArticuloVisions NVARCHAR(30), @Cantidad DECIMAL(18,4),
            @Procesado BIT, @CostoVisions DECIMAL(18,4), @NombreVisions NVARCHAR(255),
            @PrecioVisions DECIMAL(18,4), @TipDoc NVARCHAR(20), @NroDoc NVARCHAR(50);

    SELECT
        @CentroCostoID          = CentroCostoID,
        @CodigoArticuloVisions  = CodigoArticuloVisions,
        @Cantidad               = Cantidad,
        @Procesado              = Procesado,
        @CostoVisions           = CostoArticuloVisions,
        @NombreVisions          = NombreArticuloVisions,
        @PrecioVisions          = PrecioArticuloVisions,
        @TipDoc                 = TipDoc,
        @NroDoc                 = NroDoc
    FROM Integracion.EventosEntrantes
    WHERE EventoEntranteID = @EventoEntranteID;

    IF @Procesado = 1 RETURN;

    -- 1. Mapeo explicito.
    DECLARE @ArticuloID INT;
    SELECT @ArticuloID = ArticuloID
    FROM Integracion.MapeoArticulos
    WHERE CodigoArticuloVisions = @CodigoArticuloVisions
      AND CentroCostoID = @CentroCostoID
      AND Estado = 1;

    -- 2. Auto-resolver por Referencia si no hay mapeo manual.
    IF @ArticuloID IS NULL
    BEGIN
        SELECT @ArticuloID = ArticuloID
        FROM Catalogo.Tarjetas
        WHERE Referencia = @CodigoArticuloVisions AND Estado = 1;

        IF @ArticuloID IS NOT NULL
            MERGE Integracion.MapeoArticulos AS d
            USING (SELECT @ArticuloID    AS ArticuloID,
                          @CentroCostoID AS CentroCostoID,
                          @CodigoArticuloVisions AS CodigoArticuloVisions) AS s
            ON d.ArticuloID = s.ArticuloID AND d.CentroCostoID = s.CentroCostoID
            WHEN NOT MATCHED THEN
                INSERT (ArticuloID, CentroCostoID, CodigoArticuloVisions, Estado)
                VALUES (@ArticuloID, @CentroCostoID, @CodigoArticuloVisions, 1);
    END

    -- 3. Sin mapeo: dejar pendiente para revision del admin.
    IF @ArticuloID IS NULL
    BEGIN
        MERGE Integracion.ArticulosPendientesMapeo AS destino
        USING (SELECT @CentroCostoID          AS CentroCostoID,
                      @CodigoArticuloVisions   AS CodigoArticuloVisions) AS origen
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
        SELECT BodegaVentaVisionsID FROM Organizacion.CentrosCosto
        WHERE CentroCostoID = @CentroCostoID);
    IF @BodegaVentaID IS NULL
        THROW 54001, 'El Centro de Costo no tiene configurada una Bodega de Venta Visions.', 1;

    DECLARE @TipoEntrada INT = (
        SELECT TipoMovID FROM Kardex.TiposMovimientoKardex WHERE Codigo = 'ENTRADA_COMPRA');
    DECLARE @UsuarioSistemaID INT = (
        SELECT UsuarioID FROM Seguridad.Usuarios WHERE Username = 'sistema.sync');
    DECLARE @Costo DECIMAL(18,4) = COALESCE(@CostoVisions, 0);

    BEGIN TRANSACTION;

    -- Sumar stock sin FEFO: entradas directas van a fila sin lote.
    MERGE Inventario.InventarioStock AS dest
    USING (SELECT @ArticuloID AS ArticuloID, @BodegaVentaID AS BodegaID) AS src
    ON dest.ArticuloID = src.ArticuloID AND dest.BodegaID = src.BodegaID AND dest.LoteID IS NULL
    WHEN MATCHED THEN
        UPDATE SET CantidadActual = CantidadActual + @Cantidad,
                   FechaUltimaActualizacion = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN
        INSERT (ArticuloID, BodegaID, LoteID, CantidadActual, CostoUnitarioLote, FechaUltimaActualizacion)
        VALUES (@ArticuloID, @BodegaVentaID, NULL, @Cantidad, @Costo, SYSUTCDATETIME());

    DECLARE @NuevoSaldo DECIMAL(18,4) = (
        SELECT SUM(CantidadActual) FROM Inventario.InventarioStock
        WHERE ArticuloID = @ArticuloID AND BodegaID = @BodegaVentaID);

    INSERT INTO Kardex.KardexMovimientos
        (ArticuloID, BodegaID, LoteID, TipoMovID, CentroCostoID,
         Cantidad, CostoUnitario, CantidadSaldo, CostoPromedioSaldo,
         ObservacionDetallada, UsuarioID)
    VALUES
        (@ArticuloID, @BodegaVentaID, NULL, @TipoEntrada, @CentroCostoID,
         @Cantidad, @Costo, @NuevoSaldo, @Costo,
         CONCAT('Entrada compra Visions - ', ISNULL(@TipDoc,''), ' ',
                ISNULL(@NroDoc,''), ' - Evento #', @EventoEntranteID),
         @UsuarioSistemaID);

    UPDATE Integracion.EventosEntrantes
    SET Procesado = 1, FechaProcesado = SYSUTCDATETIME()
    WHERE EventoEntranteID = @EventoEntranteID;

    COMMIT TRANSACTION;
END
GO
