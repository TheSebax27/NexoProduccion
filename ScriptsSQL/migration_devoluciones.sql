-- ══════════════════════════════════════════════════════════════════════
-- Módulo Devoluciones — ejecutar UNA vez en NEXO_ERP
-- ══════════════════════════════════════════════════════════════════════

-- 1) Nuevos tipos de movimiento Kardex
IF NOT EXISTS (SELECT 1 FROM Kardex.TiposMovimientoKardex WHERE Codigo = 'ENTRADA_DEVOLUCION_VISIONS')
    INSERT INTO Kardex.TiposMovimientoKardex (Codigo, Nombre, Signo)
    VALUES ('ENTRADA_DEVOLUCION_VISIONS', 'Entrada por Devolucion de Cliente (Visions)', 1);

IF NOT EXISTS (SELECT 1 FROM Kardex.TiposMovimientoKardex WHERE Codigo = 'ENTRADA_DEVOLUCION_CLIENTE')
    INSERT INTO Kardex.TiposMovimientoKardex (Codigo, Nombre, Signo)
    VALUES ('ENTRADA_DEVOLUCION_CLIENTE', 'Entrada por Devolucion de Cliente', 1);

IF NOT EXISTS (SELECT 1 FROM Kardex.TiposMovimientoKardex WHERE Codigo = 'SALIDA_DEVOLUCION_PROVEEDOR')
    INSERT INTO Kardex.TiposMovimientoKardex (Codigo, Nombre, Signo)
    VALUES ('SALIDA_DEVOLUCION_PROVEEDOR', 'Salida por Devolucion a Proveedor', -1);

-- 2) Tabla de devoluciones
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='Facturacion' AND TABLE_NAME='Devoluciones')
BEGIN
    CREATE TABLE Facturacion.Devoluciones (
        DevolucionID      INT           NOT NULL IDENTITY(1,1) CONSTRAINT PK_Devoluciones PRIMARY KEY,
        TipoDevolucion    NVARCHAR(20)  NOT NULL,  -- 'CLIENTE' o 'PROVEEDOR'
        FacturaOrigenID   INT           NULL CONSTRAINT FK_Dev_Factura REFERENCES Facturacion.Facturas(FacturaID),
        ClienteID         INT           NULL CONSTRAINT FK_Dev_Cliente REFERENCES Crm.Clientes(ClienteID),
        ProveedorID       INT           NULL CONSTRAINT FK_Dev_Proveedor REFERENCES Catalogo.Proveedores(ProveedorID),
        CentroCostoID     INT           NULL CONSTRAINT FK_Dev_CC REFERENCES Organizacion.CentrosCosto(CentroCostoID),
        Fecha             DATE          NOT NULL DEFAULT CAST(GETDATE() AS DATE),
        Motivo            NVARCHAR(500) NULL,
        NroDoc            NVARCHAR(50)  NULL,
        Total             DECIMAL(18,4) NOT NULL DEFAULT 0,
        StockRestituido   BIT           NOT NULL DEFAULT 0,
        OrigenVisions     BIT           NOT NULL DEFAULT 0,
        EventoEntranteID  BIGINT        NULL,
        UsuarioID         INT           NULL CONSTRAINT FK_Dev_Usuario REFERENCES Seguridad.Usuarios(UsuarioID),
        FechaRegistro     DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME()
    );
END

-- 3) Líneas de devolución
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='Facturacion' AND TABLE_NAME='DevolucionLineas')
BEGIN
    CREATE TABLE Facturacion.DevolucionLineas (
        LineaID       INT           NOT NULL IDENTITY(1,1) CONSTRAINT PK_DevolucionLineas PRIMARY KEY,
        DevolucionID  INT           NOT NULL CONSTRAINT FK_DevLin_Dev REFERENCES Facturacion.Devoluciones(DevolucionID),
        ArticuloID    INT           NOT NULL CONSTRAINT FK_DevLin_Art REFERENCES Catalogo.Tarjetas(ArticuloID),
        Cantidad      DECIMAL(18,4) NOT NULL,
        CostoUnitario DECIMAL(18,4) NOT NULL DEFAULT 0,
        Subtotal      AS (Cantidad * CostoUnitario),
        Nota          NVARCHAR(255) NULL
    );
END

GO
-- 4) SP para procesar devoluciones de cliente desde Visions (NOTA DEVOLUCION)
--    Equivalente a sp_ProcesarEventoEntrante pero SUMA stock en vez de restarlo.
CREATE OR ALTER PROCEDURE Integracion.sp_ProcesarDevolucionVisions
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
