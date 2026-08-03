/* ============================================================================
   NEXO ERP - FIX: los insumos medidos "por Unidad" (discretos: cpu, Ram,
   Fuente, etc.) se estaban descontando en cantidades fraccionarias (ej. 0.93
   unidades), lo cual no tiene sentido fisico -- no se puede tomar 0.93 de una
   CPU de la bodega. Para insumos en PESO/VOLUMEN/LONGITUD si tiene sentido
   tener fracciones (0.93 kg es real), asi que el redondeo hacia arriba solo
   se aplica cuando la Unidad de la linea de receta es de tipo 'UNIDAD'.

   Se corrige en LOS DOS lugares donde se calcula la cantidad necesaria:
   - sp_LiberarOrdenProduccion (valida que haya stock suficiente)
   - sp_IniciarOrdenProduccion (descuenta el stock real)
   Si solo se corrige uno, quedarian inconsistentes entre si (una orden podria
   "liberarse" con una cantidad y luego fallar al iniciar con otra distinta).
   ============================================================================ */

USE NEXO_ERP;
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
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
        @EstadoActual = e.Nombre,
        @RecetaID = op.RecetaID,
        @CantidadProgramada = op.CantidadProgramada,
        @BodegaOrigenMPID = op.BodegaOrigenMPID
    FROM Produccion.OrdenesProduccion op
    JOIN Produccion.EstadosOP e ON e.EstadoOPID = op.EstadoOPID
    WHERE op.OrdenProduccionID = @OrdenProduccionID;

    IF @EstadoActual IS NULL
        THROW 51000, 'La orden de produccion no existe.', 1;
    IF @EstadoActual <> 'Planificada'
        THROW 51001, 'Solo se pueden liberar ordenes en estado Planificada.', 1;

    SELECT @RendimientoBase = CantidadRendimientoBase FROM Produccion.RecetaBOM WHERE RecetaID = @RecetaID;

    DECLARE @FactorEscala DECIMAL(18,8) = @CantidadProgramada / @RendimientoBase;

    -- Requerimiento total por insumo (incluyendo merma estandar). Si la Unidad
    -- de la linea es 'UNIDAD' (discreta), se redondea hacia arriba -- igual
    -- criterio que sp_IniciarOrdenProduccion, para que ambos calculen lo mismo.
    IF OBJECT_ID('tempdb..#Requerido') IS NOT NULL DROP TABLE #Requerido;
    SELECT
        rd.InsumoID,
        a.Nombre AS NombreInsumo,
        CASE WHEN um.Tipo = 'UNIDAD'
             THEN CEILING((rd.CantidadRequerida * @FactorEscala) * (1 + rd.PorcentajeMermaEstandar/100.0))
             ELSE (rd.CantidadRequerida * @FactorEscala) * (1 + rd.PorcentajeMermaEstandar/100.0)
        END AS CantidadNecesaria
    INTO #Requerido
    FROM Produccion.RecetaBOM_Detalle rd
    JOIN Catalogo.Articulos a ON a.ArticuloID = rd.InsumoID
    JOIN Catalogo.UnidadesMedida um ON um.UnidadID = rd.UnidadID
    WHERE rd.RecetaID = @RecetaID;

    -- Disponible en la bodega de origen de materia prima
    IF OBJECT_ID('tempdb..#Faltantes') IS NOT NULL DROP TABLE #Faltantes;
    SELECT
        r.InsumoID,
        r.NombreInsumo,
        r.CantidadNecesaria,
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
        DECLARE @Msg NVARCHAR(MAX) = CONCAT('Stock insuficiente para liberar la OP. Detalle: ', @Detalle);
        THROW 51002, @Msg, 1;
    END

    UPDATE Produccion.OrdenesProduccion
    SET EstadoOPID = (SELECT EstadoOPID FROM Produccion.EstadosOP WHERE Nombre = 'Liberada'),
        UsuarioLiberaID = @UsuarioID
    WHERE OrdenProduccionID = @OrdenProduccionID;

    SELECT 'OK' AS Resultado, 'Orden liberada correctamente.' AS Mensaje;
END
GO

CREATE OR ALTER PROCEDURE Produccion.sp_IniciarOrdenProduccion
    @OrdenProduccionID INT,
    @UsuarioID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @EstadoActual NVARCHAR(30), @RecetaID INT, @CantidadProgramada DECIMAL(18,4),
            @RendimientoBase DECIMAL(18,4), @BodegaOrigenMPID INT, @CentroCostoID INT,
            @TipoSalidaWIP INT = (SELECT TipoMovID FROM Kardex.TiposMovimientoKardex WHERE Codigo='SALIDA_WIP');

    SELECT
        @EstadoActual = e.Nombre, @RecetaID = op.RecetaID, @CantidadProgramada = op.CantidadProgramada,
        @BodegaOrigenMPID = op.BodegaOrigenMPID, @CentroCostoID = op.CentroCostoDestinoID
    FROM Produccion.OrdenesProduccion op
    JOIN Produccion.EstadosOP e ON e.EstadoOPID = op.EstadoOPID
    WHERE op.OrdenProduccionID = @OrdenProduccionID;

    IF @EstadoActual <> 'Liberada'
        THROW 51010, 'Solo se pueden iniciar ordenes en estado Liberada.', 1;

    SELECT @RendimientoBase = CantidadRendimientoBase FROM Produccion.RecetaBOM WHERE RecetaID = @RecetaID;
    DECLARE @FactorEscala DECIMAL(18,8) = @CantidadProgramada / @RendimientoBase;

    BEGIN TRANSACTION;

    DECLARE @InsumoID INT, @CantidadNecesaria DECIMAL(18,4);
    -- Mismo criterio de redondeo que sp_LiberarOrdenProduccion: hacia arriba
    -- para Unidad de tipo 'UNIDAD' (discreta), fraccionario para el resto.
    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT rd.InsumoID,
               CASE WHEN um.Tipo = 'UNIDAD'
                    THEN CEILING((rd.CantidadRequerida * @FactorEscala) * (1 + rd.PorcentajeMermaEstandar/100.0))
                    ELSE (rd.CantidadRequerida * @FactorEscala) * (1 + rd.PorcentajeMermaEstandar/100.0)
               END
        FROM Produccion.RecetaBOM_Detalle rd
        JOIN Catalogo.UnidadesMedida um ON um.UnidadID = rd.UnidadID
        WHERE rd.RecetaID = @RecetaID;

    OPEN cur;
    FETCH NEXT FROM cur INTO @InsumoID, @CantidadNecesaria;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @Pendiente DECIMAL(18,4) = @CantidadNecesaria;

        DECLARE @LoteID INT, @CantidadLote DECIMAL(18,4), @CostoLote DECIMAL(18,4), @InventarioID BIGINT;

        DECLARE curLotes CURSOR LOCAL FAST_FORWARD FOR
            SELECT s.InventarioID, s.LoteID, s.CantidadActual, s.CostoUnitarioLote
            FROM Inventario.InventarioStock s
            LEFT JOIN Inventario.Lotes l ON l.LoteID = s.LoteID
            WHERE s.ArticuloID = @InsumoID AND s.BodegaID = @BodegaOrigenMPID AND s.CantidadActual > 0
                  AND (l.Estado IS NULL OR l.Estado = 'APROBADO')
            ORDER BY ISNULL(l.FechaVencimiento,'9999-12-31') ASC; -- FEFO

        OPEN curLotes;
        FETCH NEXT FROM curLotes INTO @InventarioID, @LoteID, @CantidadLote, @CostoLote;

        WHILE @@FETCH_STATUS = 0 AND @Pendiente > 0
        BEGIN
            DECLARE @Tomar DECIMAL(18,4) = CASE WHEN @CantidadLote >= @Pendiente THEN @Pendiente ELSE @CantidadLote END;

            UPDATE Inventario.InventarioStock
            SET CantidadActual = CantidadActual - @Tomar, FechaUltimaActualizacion = SYSUTCDATETIME()
            WHERE InventarioID = @InventarioID;

            DECLARE @NuevoSaldo DECIMAL(18,4) = (SELECT SUM(CantidadActual) FROM Inventario.InventarioStock WHERE ArticuloID=@InsumoID AND BodegaID=@BodegaOrigenMPID);

            INSERT INTO Kardex.KardexMovimientos
                (ArticuloID, BodegaID, LoteID, TipoMovID, OrdenProduccionID, CentroCostoID,
                 Cantidad, CostoUnitario, CantidadSaldo, CostoPromedioSaldo, ObservacionDetallada, UsuarioID)
            VALUES
                (@InsumoID, @BodegaOrigenMPID, @LoteID, @TipoSalidaWIP, @OrdenProduccionID, @CentroCostoID,
                 @Tomar, @CostoLote, @NuevoSaldo, @CostoLote, 'Consumo teorico a produccion (FEFO)', @UsuarioID);

            INSERT INTO Produccion.OrdenesProduccionConsumo (OrdenProduccionID, ArticuloID, LoteID, CantidadTeorica, CantidadReal)
            VALUES (@OrdenProduccionID, @InsumoID, @LoteID, @Tomar, @Tomar);

            SET @Pendiente -= @Tomar;
            FETCH NEXT FROM curLotes INTO @InventarioID, @LoteID, @CantidadLote, @CostoLote;
        END
        CLOSE curLotes; DEALLOCATE curLotes;

        IF @Pendiente > 0
        BEGIN
            ROLLBACK TRANSACTION;
            CLOSE cur; DEALLOCATE cur;
            THROW 51011, 'Stock insuficiente detectado al iniciar la OP (condicion de carrera). Reintente.', 1;
        END

        FETCH NEXT FROM cur INTO @InsumoID, @CantidadNecesaria;
    END
    CLOSE cur; DEALLOCATE cur;

    UPDATE Produccion.OrdenesProduccion
    SET EstadoOPID = (SELECT EstadoOPID FROM Produccion.EstadosOP WHERE Nombre = 'En Proceso'),
        FechaInicio = SYSUTCDATETIME()
    WHERE OrdenProduccionID = @OrdenProduccionID;

    COMMIT TRANSACTION;
    SELECT 'OK' AS Resultado, 'Orden iniciada, materia prima descontada.' AS Mensaje;
END
GO

PRINT 'sp_LiberarOrdenProduccion y sp_IniciarOrdenProduccion corregidos: redondeo hacia arriba para insumos por Unidad.';
GO
