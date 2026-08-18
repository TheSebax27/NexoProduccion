-- ==========================================================================
-- fix3_sp_tarjetas_v1.sql
-- Corrige sp_LiberarOrdenProduccion: reemplaza Catalogo.Articulos por
-- Catalogo.Tarjetas (tabla fue renombrada en migration_tarjetas_v2.sql).
-- Solo hay que ejecutar este script si fix2_migration_recetas_sin_unidad_v1
-- ya fue ejecutado (ese script creo el SP con el nombre incorrecto).
-- ==========================================================================

USE NEXO_ERP;
GO

CREATE OR ALTER PROCEDURE Produccion.sp_LiberarOrdenProduccion
    @OrdenProduccionID INT,
    @UsuarioID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EstadoActual NVARCHAR(30), @RecetaID INT, @CantidadProgramada DECIMAL(18,4),
            @RendimientoBase DECIMAL(18,4), @BodegaOrigenMPID INT;

    SELECT
        @EstadoActual = e.Nombre, @RecetaID = op.RecetaID,
        @CantidadProgramada = op.CantidadProgramada, @BodegaOrigenMPID = op.BodegaOrigenMPID
    FROM Produccion.OrdenesProduccion op
    JOIN Produccion.EstadosOP e ON e.EstadoOPID = op.EstadoOPID
    WHERE op.OrdenProduccionID = @OrdenProduccionID;

    IF @EstadoActual IS NULL  THROW 51000, 'La orden de produccion no existe.', 1;
    IF @EstadoActual <> 'Planificada' THROW 51001, 'Solo se pueden liberar ordenes en estado Planificada.', 1;

    SELECT @RendimientoBase = CantidadRendimientoBase FROM Produccion.RecetaBOM WHERE RecetaID = @RecetaID;
    DECLARE @FactorEscala DECIMAL(18,8) = @CantidadProgramada / @RendimientoBase;

    IF OBJECT_ID('tempdb..#Requerido') IS NOT NULL DROP TABLE #Requerido;
    SELECT rd.InsumoID, a.Nombre AS NombreInsumo,
           (rd.CantidadRequerida * @FactorEscala) * (1 + rd.PorcentajeMermaEstandar / 100.0) AS CantidadNecesaria
    INTO #Requerido
    FROM Produccion.RecetaBOM_Detalle rd
    JOIN Catalogo.Tarjetas a ON a.ArticuloID = rd.InsumoID   -- corregido: era Catalogo.Articulos
    WHERE rd.RecetaID = @RecetaID;

    IF OBJECT_ID('tempdb..#Faltantes') IS NOT NULL DROP TABLE #Faltantes;
    SELECT r.InsumoID, r.NombreInsumo, r.CantidadNecesaria,
           ISNULL(s.Disponible,0) AS Disponible,
           (r.CantidadNecesaria - ISNULL(s.Disponible,0)) AS Faltante
    INTO #Faltantes
    FROM #Requerido r
    OUTER APPLY (
        SELECT SUM(CantidadActual) AS Disponible
        FROM Inventario.InventarioStock
        WHERE ArticuloID = r.InsumoID AND BodegaID = @BodegaOrigenMPID
    ) s
    WHERE r.CantidadNecesaria > ISNULL(s.Disponible,0);

    IF EXISTS (SELECT 1 FROM #Faltantes)
    BEGIN
        DECLARE @Detalle NVARCHAR(MAX) = (
            SELECT STRING_AGG(CONCAT(NombreInsumo, ': faltan ', CAST(ROUND(Faltante,4) AS NVARCHAR(30))), ' | ')
            FROM #Faltantes
        );
        THROW 51002, N'Stock insuficiente para liberar la OP.', 1;
    END

    UPDATE Produccion.OrdenesProduccion
    SET EstadoOPID = (SELECT EstadoOPID FROM Produccion.EstadosOP WHERE Nombre = 'Liberada'),
        UsuarioLiberaID = @UsuarioID
    WHERE OrdenProduccionID = @OrdenProduccionID;

    SELECT 'OK' AS Resultado, 'Orden liberada correctamente.' AS Mensaje;
END
GO

PRINT 'fix3_sp_tarjetas_v1.sql: sp_LiberarOrdenProduccion recreado con Catalogo.Tarjetas.';
GO

-- ==========================================================================
-- Corrige sp_CerrarOrdenProduccion: dos referencias a Catalogo.Articulos
-- ==========================================================================
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
    SELECT @CostoMateriales = SUM(c.CantidadReal * ISNULL(k.CostoUnitario, a.CostoPromedio))
    FROM Produccion.OrdenesProduccionConsumo c
    JOIN Catalogo.Tarjetas a ON a.ArticuloID = c.ArticuloID   -- corregido: era Catalogo.Articulos
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

    UPDATE Catalogo.Tarjetas SET CostoPromedio = @CostoUnitarioReal WHERE ArticuloID = @ProductoTerminadoID;   -- corregido: era Catalogo.Articulos

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

    IF EXISTS (SELECT 1 FROM Organizacion.CentrosCosto WHERE CentroCostoID = @CentroCostoID AND TieneVisions = 1)
    BEGIN
        INSERT INTO Integracion.EventosSalientes
            (TipoEvento, CentroCostoID, ArticuloID, Cantidad, CostoUnitario, KardexID)
        VALUES
            ('ENTRADA_PRODUCTO_TERMINADO', @CentroCostoID, @ProductoTerminadoID, @CantidadProducidaReal, @CostoUnitarioReal, @KardexIDGenerado);
    END

    COMMIT TRANSACTION;

    SELECT 'OK' AS Resultado, @CostoUnitarioReal AS CostoUnitarioReal, @LoteID AS LoteProductoTerminadoID;
END
GO

PRINT 'fix3_sp_tarjetas_v1.sql: sp_CerrarOrdenProduccion recreado con Catalogo.Tarjetas.';
GO
