/* ============================================================================
   NEXO ERP - FIX: la receta puede pedir un insumo en una Unidad distinta a la
   Unidad base en la que ese articulo se registra en stock (ej. receta pide
   "2 und" de Fuente, pero Fuente se compra/almacena por "Caja" con 5 unidades
   cada una). El sistema nunca convertia -- comparaba "2" contra el stock en
   cajas como si fueran la misma unidad, generando faltantes falsos (o
   sobre-consumo si fuera al reves).

   Se agrega conversion especifica para el par Caja<->Unidad usando
   Catalogo.Articulos.UnidadesPorEmbalaje (el factor que ya se captura en el
   formulario de Articulo). Cualquier otra combinacion de unidades distintas
   sin factor conocido (ej. kg vs caja) se deja exactamente igual que antes
   -- no se inventa conversion para casos no soportados, es responsabilidad
   de quien arma la receta usar la misma unidad que el articulo en ese caso.

   Se corrige en LOS DOS lugares que calculan la cantidad necesaria, para que
   sigan dando el mismo resultado entre si (ver CLAUDE.md seccion 20.5):
   - sp_LiberarOrdenProduccion (valida stock disponible)
   - sp_IniciarOrdenProduccion (descuenta el stock real)
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

    -- Requerimiento total por insumo (incluyendo merma estandar), convertido a
    -- la Unidad BASE del articulo (la que ya usa InventarioStock). Ver
    -- comentario de cabecera para el criterio de conversion Caja<->Unidad.
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
    -- Mismo criterio de conversion Caja<->Unidad que sp_LiberarOrdenProduccion
    -- (ver comentario de cabecera del script).
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

PRINT 'sp_LiberarOrdenProduccion y sp_IniciarOrdenProduccion corregidos: conversion Caja<->Unidad aplicada.';
GO
