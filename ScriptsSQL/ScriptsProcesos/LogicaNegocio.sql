/* ============================================================================
   SISTEMA NEXO - Script 03: Logica de Negocio (Stored Procedures)
   Ejecutar despues de 01_estructura_base.sql y 02_datos_maestros.sql

   Todas las operaciones que tocan stock pasan por procedimientos, nunca por
   INSERT/UPDATE directo desde el backend, para garantizar que KARDEX,
   InventarioStock y CostoPromedio siempre queden consistentes (fuente unica
   de verdad transaccional).
   ============================================================================ */
USE NEXO_ERP;
GO

-- ============================================================================
-- FUNCION AUXILIAR: costo promedio ponderado total del articulo
-- ============================================================================
CREATE OR ALTER FUNCTION Catalogo.fn_StockTotalArticulo (@ArticuloID INT)
RETURNS DECIMAL(18,4)
AS
BEGIN
    DECLARE @Total DECIMAL(18,4);
    SELECT @Total = ISNULL(SUM(CantidadActual),0)
    FROM Inventario.InventarioStock WHERE ArticuloID = @ArticuloID;
    RETURN @Total;
END
GO

-- ============================================================================
-- SP: sp_LiberarOrdenProduccion
-- Valida stock suficiente de TODOS los insumos de la receta (escalado a la
-- cantidad programada) antes de permitir pasar de Planificada -> Liberada.
-- Si falta stock en cualquier insumo, BLOQUEA y devuelve el detalle faltante.
-- ============================================================================
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

    -- Requerimiento total por insumo (incluyendo merma estandar), convertido a
    -- la Unidad BASE del articulo (la que usa InventarioStock). La receta puede
    -- pedir una Unidad distinta a la del articulo (ej. receta en "und" pero el
    -- articulo se stockea por "Caja") -- se convierte usando
    -- Catalogo.Articulos.UnidadesPorEmbalaje cuando el par es Caja<->Unidad;
    -- cualquier otra combinacion de unidades distintas sin factor conocido
    -- (ej. kg vs caja) se deja sin convertir (responsabilidad de quien arma
    -- la receta usar la misma unidad que el articulo en ese caso).
    -- Ademas, si la Unidad resultante es 'UNIDAD' (discreta, ej. piezas), se
    -- redondea hacia arriba: no se puede tomar una fraccion de un articulo
    -- indivisible. Para PESO/VOLUMEN/LONGITUD se deja fraccionario.
    IF OBJECT_ID('tempdb..#Requerido') IS NOT NULL DROP TABLE #Requerido;
    SELECT
        rd.InsumoID,
        a.Nombre AS NombreInsumo,
        CASE
            WHEN rd.UnidadID = a.UnidadID THEN
                CASE WHEN um.Tipo = 'UNIDAD'
                     THEN CEILING((rd.CantidadRequerida * @FactorEscala) * (1 + rd.PorcentajeMermaEstandar/100.0))
                     ELSE (rd.CantidadRequerida * @FactorEscala) * (1 + rd.PorcentajeMermaEstandar/100.0)
                END
            WHEN um.Abreviatura = 'und' AND umArt.Abreviatura = 'cja' AND a.UnidadesPorEmbalaje > 0 THEN
                ((rd.CantidadRequerida * @FactorEscala) * (1 + rd.PorcentajeMermaEstandar/100.0)) / a.UnidadesPorEmbalaje
            WHEN um.Abreviatura = 'cja' AND umArt.Abreviatura = 'und' AND a.UnidadesPorEmbalaje > 0 THEN
                CEILING(((rd.CantidadRequerida * @FactorEscala) * (1 + rd.PorcentajeMermaEstandar/100.0)) * a.UnidadesPorEmbalaje)
            ELSE
                (rd.CantidadRequerida * @FactorEscala) * (1 + rd.PorcentajeMermaEstandar/100.0)
        END AS CantidadNecesaria
    INTO #Requerido
    FROM Produccion.RecetaBOM_Detalle rd
    JOIN Catalogo.Articulos a ON a.ArticuloID = rd.InsumoID
    JOIN Catalogo.UnidadesMedida um ON um.UnidadID = rd.UnidadID
    LEFT JOIN Catalogo.UnidadesMedida umArt ON umArt.UnidadID = a.UnidadID
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

-- ============================================================================
-- SP: sp_IniciarOrdenProduccion
-- Descuenta materia prima (FEFO: primero vence, primero sale) de la bodega
-- de origen, genera KARDEX de salida a WIP y dispara estado En Proceso.
-- ============================================================================
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
    -- Mismo criterio de conversion Caja<->Unidad y redondeo que
    -- sp_LiberarOrdenProduccion (ver comentario alli).
    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT rd.InsumoID,
               CASE
                   WHEN rd.UnidadID = a.UnidadID THEN
                       CASE WHEN um.Tipo = 'UNIDAD'
                            THEN CEILING((rd.CantidadRequerida * @FactorEscala) * (1 + rd.PorcentajeMermaEstandar/100.0))
                            ELSE (rd.CantidadRequerida * @FactorEscala) * (1 + rd.PorcentajeMermaEstandar/100.0)
                       END
                   WHEN um.Abreviatura = 'und' AND umArt.Abreviatura = 'cja' AND a.UnidadesPorEmbalaje > 0 THEN
                       ((rd.CantidadRequerida * @FactorEscala) * (1 + rd.PorcentajeMermaEstandar/100.0)) / a.UnidadesPorEmbalaje
                   WHEN um.Abreviatura = 'cja' AND umArt.Abreviatura = 'und' AND a.UnidadesPorEmbalaje > 0 THEN
                       CEILING(((rd.CantidadRequerida * @FactorEscala) * (1 + rd.PorcentajeMermaEstandar/100.0)) * a.UnidadesPorEmbalaje)
                   ELSE
                       (rd.CantidadRequerida * @FactorEscala) * (1 + rd.PorcentajeMermaEstandar/100.0)
               END
        FROM Produccion.RecetaBOM_Detalle rd
        JOIN Catalogo.Articulos a ON a.ArticuloID = rd.InsumoID
        JOIN Catalogo.UnidadesMedida um ON um.UnidadID = rd.UnidadID
        LEFT JOIN Catalogo.UnidadesMedida umArt ON umArt.UnidadID = a.UnidadID
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

-- ============================================================================
-- SP: sp_AjustarConsumoReal
-- Permite corregir la cantidad real consumida de un insumo dentro de una OP
-- En Proceso. Si CantidadReal > CantidadTeorica exige justificacion.
--
-- IMPORTANTE: no basta con actualizar el numero guardado -- el ajuste debe
-- reflejarse en InventarioStock y en Kardex, porque sp_IniciarOrdenProduccion
-- ya desconto la cantidad TEORICA del stock. Si el consumo real es mayor,
-- falta descontar la diferencia (exceso); si es menor, hay que devolverla.
-- ============================================================================
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

-- ============================================================================
-- SP: sp_CerrarOrdenProduccion
-- Calcula costo real (materiales + MOD + CIF), ingresa el Producto Terminado
-- a la bodega destino, genera KARDEX de entrada y finaliza la OP.
-- ============================================================================
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

    -- Crear lote del producto terminado
    DECLARE @LoteID INT;
    INSERT INTO Inventario.Lotes (ArticuloID, NumeroLote, FechaFabricacion, FechaVencimiento, Estado)
    VALUES (@ProductoTerminadoID, @NumeroLotePT, CAST(SYSUTCDATETIME() AS DATE), @FechaVencimientoPT, 'APROBADO');
    SET @LoteID = SCOPE_IDENTITY();

    -- Entrada a inventario de producto terminado
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

    -- Actualizar costo promedio ponderado global del articulo terminado
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

    COMMIT TRANSACTION;

    SELECT 'OK' AS Resultado, @CostoUnitarioReal AS CostoUnitarioReal, @LoteID AS LoteProductoTerminadoID;
END
GO

-- ============================================================================
-- SP: sp_RegistrarBajaInventario
-- Registro de perdida/dano accidental. Descuenta stock, crea KARDEX y deja
-- la observacion detallada auditable, sin afectar costeo de OP activas.
-- ============================================================================
CREATE OR ALTER PROCEDURE Kardex.sp_RegistrarBajaInventario
    @ArticuloID INT,
    @BodegaID INT,
    @LoteID INT = NULL,
    @CantidadPerdida DECIMAL(18,4),
    @MotivoID INT,
    @ObservacionDetallada NVARCHAR(500),
    @UsuarioRegistraID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @ObservacionDetallada IS NULL OR LEN(TRIM(@ObservacionDetallada)) < 5
        THROW 52000, 'Debe indicar una observacion detallada de al menos 5 caracteres.', 1;

    DECLARE @Disponible DECIMAL(18,4), @CostoUnitario DECIMAL(18,4), @CentroCostoID INT, @InventarioID BIGINT;

    SELECT TOP 1 @Disponible = s.CantidadActual, @CostoUnitario = s.CostoUnitarioLote,
                 @InventarioID = s.InventarioID, @CentroCostoID = b.CentroCostoID
    FROM Inventario.InventarioStock s
    JOIN Inventario.Bodegas b ON b.BodegaID = s.BodegaID
    WHERE s.ArticuloID = @ArticuloID AND s.BodegaID = @BodegaID
          AND ((@LoteID IS NULL AND s.LoteID IS NULL) OR s.LoteID = @LoteID);

    IF @Disponible IS NULL OR @Disponible < @CantidadPerdida
        THROW 52001, 'No hay stock suficiente en esa bodega/lote para registrar la baja.', 1;

    BEGIN TRANSACTION;

    DECLARE @CodigoBaja NVARCHAR(30) = CONCAT('BAJA-', FORMAT(SYSUTCDATETIME(),'yyyyMMddHHmmss'));
    DECLARE @BajaID INT;

    INSERT INTO Kardex.BajasInventarioPerdidas
        (CodigoBaja, ArticuloID, BodegaID, LoteID, CantidadPerdida, CostoUnitario, MotivoID, ObservacionDetallada, UsuarioRegistraID)
    VALUES
        (@CodigoBaja, @ArticuloID, @BodegaID, @LoteID, @CantidadPerdida, @CostoUnitario, @MotivoID, @ObservacionDetallada, @UsuarioRegistraID);
    SET @BajaID = SCOPE_IDENTITY();

    UPDATE Inventario.InventarioStock
    SET CantidadActual = CantidadActual - @CantidadPerdida, FechaUltimaActualizacion = SYSUTCDATETIME()
    WHERE InventarioID = @InventarioID;

    DECLARE @NuevoSaldo DECIMAL(18,4) = (SELECT SUM(CantidadActual) FROM Inventario.InventarioStock WHERE ArticuloID=@ArticuloID AND BodegaID=@BodegaID);
    DECLARE @TipoBaja INT = (SELECT TipoMovID FROM Kardex.TiposMovimientoKardex WHERE Codigo='BAJA_MERMA');

    INSERT INTO Kardex.KardexMovimientos
        (ArticuloID, BodegaID, LoteID, TipoMovID, BajaID, CentroCostoID,
         Cantidad, CostoUnitario, CantidadSaldo, CostoPromedioSaldo, ObservacionDetallada, UsuarioID)
    VALUES
        (@ArticuloID, @BodegaID, @LoteID, @TipoBaja, @BajaID, @CentroCostoID,
         @CantidadPerdida, @CostoUnitario, @NuevoSaldo, @CostoUnitario, @ObservacionDetallada, @UsuarioRegistraID);

    COMMIT TRANSACTION;
    SELECT 'OK' AS Resultado, @CodigoBaja AS CodigoBaja, @BajaID AS BajaID;
END
GO

-- ============================================================================
-- SP: sp_EnviarTraspaso / sp_RecibirTraspaso
-- Traspasos entre bodegas/centros de costo (planta central -> sucursales)
-- ============================================================================
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
            -- No se pidio un lote especifico (caso normal desde la UI, que no
            -- deja elegir lote): se toma de TODOS los lotes disponibles por
            -- FEFO -- igual criterio que sp_IniciarOrdenProduccion -- porque
            -- casi todo el stock real tiene lote (Compras y Produccion
            -- siempre asignan uno). Antes esto SIEMPRE fallaba con "stock
            -- insuficiente" para cualquier articulo con lote.
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

-- ============================================================================
-- SP: sp_RecibirOrdenCompra
-- Entrada de materia prima por compra: crea lote, actualiza stock, kardex
-- y recalcula costo promedio ponderado del articulo.
-- ============================================================================
CREATE OR ALTER PROCEDURE Compras.sp_RecibirOrdenCompra
    @OrdenCompraDetalleID INT,
    @CantidadRecibida DECIMAL(18,4),
    @NumeroLote NVARCHAR(50),
    @FechaVencimiento DATE = NULL,
    @UsuarioID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @OrdenCompraID INT, @ArticuloID INT, @CostoUnitario DECIMAL(18,4), @BodegaDestinoID INT, @CentroCostoID INT, @ProveedorID INT;

    SELECT @OrdenCompraID = ocd.OrdenCompraID, @ArticuloID = ocd.ArticuloID, @CostoUnitario = ocd.CostoUnitario
    FROM Compras.OrdenesCompraDetalle ocd WHERE ocd.OrdenCompraDetalleID = @OrdenCompraDetalleID;

    SELECT @BodegaDestinoID = BodegaDestinoID, @ProveedorID = ProveedorID FROM Compras.OrdenesCompra WHERE OrdenCompraID = @OrdenCompraID;
    SELECT @CentroCostoID = CentroCostoID FROM Inventario.Bodegas WHERE BodegaID = @BodegaDestinoID;

    BEGIN TRANSACTION;

    -- Costo promedio ponderado ANTES de sumar la nueva entrada
    DECLARE @StockPrevio DECIMAL(18,4) = Catalogo.fn_StockTotalArticulo(@ArticuloID);
    DECLARE @CostoPromedioPrevio DECIMAL(18,4) = (SELECT CostoPromedio FROM Catalogo.Articulos WHERE ArticuloID = @ArticuloID);
    DECLARE @NuevoCostoPromedio DECIMAL(18,4) =
        CASE WHEN (@StockPrevio + @CantidadRecibida) = 0 THEN @CostoUnitario
             ELSE ((@StockPrevio * @CostoPromedioPrevio) + (@CantidadRecibida * @CostoUnitario)) / (@StockPrevio + @CantidadRecibida)
        END;

    DECLARE @LoteID INT;
    INSERT INTO Inventario.Lotes (ArticuloID, NumeroLote, FechaFabricacion, FechaVencimiento, ProveedorID, Estado)
    VALUES (@ArticuloID, @NumeroLote, CAST(SYSUTCDATETIME() AS DATE), @FechaVencimiento, @ProveedorID, 'APROBADO');
    SET @LoteID = SCOPE_IDENTITY();

    INSERT INTO Inventario.InventarioStock (ArticuloID, BodegaID, LoteID, CantidadActual, CostoUnitarioLote)
    VALUES (@ArticuloID, @BodegaDestinoID, @LoteID, @CantidadRecibida, @CostoUnitario);

    UPDATE Compras.OrdenesCompraDetalle SET CantidadRecibida = CantidadRecibida + @CantidadRecibida, LoteID = @LoteID
    WHERE OrdenCompraDetalleID = @OrdenCompraDetalleID;

    DECLARE @NuevoSaldo DECIMAL(18,4) = (SELECT SUM(CantidadActual) FROM Inventario.InventarioStock WHERE ArticuloID=@ArticuloID AND BodegaID=@BodegaDestinoID);
    DECLARE @TipoEntradaCompra INT = (SELECT TipoMovID FROM Kardex.TiposMovimientoKardex WHERE Codigo='ENTRADA_COMPRA');

    INSERT INTO Kardex.KardexMovimientos
        (ArticuloID, BodegaID, LoteID, TipoMovID, OrdenCompraID, CentroCostoID, Cantidad, CostoUnitario, CantidadSaldo, CostoPromedioSaldo, ObservacionDetallada, UsuarioID)
    VALUES
        (@ArticuloID, @BodegaDestinoID, @LoteID, @TipoEntradaCompra, @OrdenCompraID, @CentroCostoID, @CantidadRecibida, @CostoUnitario, @NuevoSaldo, @NuevoCostoPromedio,
         CONCAT('Recepcion de compra OC #', @OrdenCompraID), @UsuarioID);

    UPDATE Catalogo.Articulos SET CostoPromedio = @NuevoCostoPromedio WHERE ArticuloID = @ArticuloID;

    -- Actualiza estado de la OC si ya se recibio todo
    IF NOT EXISTS (
        SELECT 1 FROM Compras.OrdenesCompraDetalle
        WHERE OrdenCompraID = @OrdenCompraID AND CantidadRecibida < CantidadSolicitada
    )
        UPDATE Compras.OrdenesCompra SET EstadoOC = 'RECIBIDA', FechaRecepcion = SYSUTCDATETIME() WHERE OrdenCompraID = @OrdenCompraID;
    ELSE
        UPDATE Compras.OrdenesCompra SET EstadoOC = 'PARCIAL' WHERE OrdenCompraID = @OrdenCompraID;

    COMMIT TRANSACTION;
    SELECT 'OK' AS Resultado, @LoteID AS LoteID, @NuevoCostoPromedio AS NuevoCostoPromedio;
END
GO

PRINT 'Procedimientos almacenados creados correctamente.';