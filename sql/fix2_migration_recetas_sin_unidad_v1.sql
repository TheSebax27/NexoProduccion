/* ============================================================================
   FIX 2: borrado completo en cascada para migration_recetas_sin_unidad_v1
   Cadena de FKs confirmada:
     Integracion.EventosSalientes.KardexID
       → Kardex.KardexMovimientos.KardexID
         → Produccion.OrdenesProduccion (via OrdenProduccionID)
           → Produccion.OrdenMaquinaria (ON DELETE CASCADE)
     Produccion.RecetaMaquinaria (ON DELETE CASCADE desde RecetaBOM)
   Ejecutar sobre NEXO_ERP.
   ============================================================================ */
USE NEXO_ERP;
GO

-- ── 1. Recetas que quedan por borrar ────────────────────────────────────
IF OBJECT_ID('tempdb..#Recetas') IS NOT NULL DROP TABLE #Recetas;
SELECT RecetaID INTO #Recetas FROM Produccion.RecetaBOM;
GO

-- ── 2. OPs que referencian esas recetas ─────────────────────────────────
IF OBJECT_ID('tempdb..#OPs') IS NOT NULL DROP TABLE #OPs;
SELECT OrdenProduccionID INTO #OPs
FROM Produccion.OrdenesProduccion
WHERE RecetaID IN (SELECT RecetaID FROM #Recetas);
GO

-- ── 3. KardexIDs de esas OPs ────────────────────────────────────────────
IF OBJECT_ID('tempdb..#Kardex') IS NOT NULL DROP TABLE #Kardex;
SELECT KardexID INTO #Kardex
FROM Kardex.KardexMovimientos
WHERE OrdenProduccionID IN (SELECT OrdenProduccionID FROM #OPs);
GO

-- ── 4. Borrar EventosSalientes que apuntan a esos Kardex ────────────────
DELETE FROM Integracion.EventosSalientes
WHERE KardexID IN (SELECT KardexID FROM #Kardex);
GO

-- ── 5. Borrar KardexMovimientos de esas OPs ─────────────────────────────
DELETE FROM Kardex.KardexMovimientos
WHERE OrdenProduccionID IN (SELECT OrdenProduccionID FROM #OPs);
GO

-- ── 6. Borrar OrdenesProduccionConsumo (si quedó algo) ──────────────────
DELETE FROM Produccion.OrdenesProduccionConsumo
WHERE OrdenProduccionID IN (SELECT OrdenProduccionID FROM #OPs);
GO

-- ── 7. Borrar OPs — CASCADE borra OrdenMaquinaria automáticamente ────────
DELETE FROM Produccion.OrdenesProduccion
WHERE OrdenProduccionID IN (SELECT OrdenProduccionID FROM #OPs);
GO

-- ── 8. Borrar RecetaBOM_Detalle (si quedó algo) ──────────────────────────
DELETE FROM Produccion.RecetaBOM_Detalle
WHERE RecetaID IN (SELECT RecetaID FROM #Recetas);
GO

-- ── 9. Borrar RecetaBOM — CASCADE borra RecetaMaquinaria automáticamente ─
DELETE FROM Produccion.RecetaBOM;
GO

-- Limpieza de temporales
DROP TABLE IF EXISTS #Kardex;
DROP TABLE IF EXISTS #OPs;
DROP TABLE IF EXISTS #Recetas;
GO

-- ── 10. Eliminar FK de RecetaBOM_Detalle.UnidadID (si aún existe) ─────────
DECLARE @sql NVARCHAR(500);
SELECT @sql = 'ALTER TABLE Produccion.RecetaBOM_Detalle DROP CONSTRAINT ' + fk.name
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
JOIN sys.columns c ON c.object_id = fk.parent_object_id AND c.column_id = fkc.parent_column_id
WHERE fk.parent_object_id = OBJECT_ID('Produccion.RecetaBOM_Detalle') AND c.name = 'UnidadID';
IF @sql IS NOT NULL EXEC(@sql);
GO

-- ── 11. Eliminar FK de RecetaBOM.UnidadRendimientoID (si aún existe) ──────
DECLARE @sql2 NVARCHAR(500);
SELECT @sql2 = 'ALTER TABLE Produccion.RecetaBOM DROP CONSTRAINT ' + fk.name
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
JOIN sys.columns c ON c.object_id = fk.parent_object_id AND c.column_id = fkc.parent_column_id
WHERE fk.parent_object_id = OBJECT_ID('Produccion.RecetaBOM') AND c.name = 'UnidadRendimientoID';
IF @sql2 IS NOT NULL EXEC(@sql2);
GO

-- ── 12. DROP columnas (solo si aún existen) ───────────────────────────────
IF EXISTS (SELECT 1 FROM sys.columns
           WHERE object_id = OBJECT_ID('Produccion.RecetaBOM_Detalle') AND name = 'UnidadID')
    ALTER TABLE Produccion.RecetaBOM_Detalle DROP COLUMN UnidadID;
GO

IF EXISTS (SELECT 1 FROM sys.columns
           WHERE object_id = OBJECT_ID('Produccion.RecetaBOM') AND name = 'UnidadRendimientoID')
    ALTER TABLE Produccion.RecetaBOM DROP COLUMN UnidadRendimientoID;
GO

-- ── 13. Recrear sp_LiberarOrdenProduccion ─────────────────────────────────
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
    JOIN Catalogo.Articulos a ON a.ArticuloID = rd.InsumoID
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

-- ── 14. Recrear sp_IniciarOrdenProduccion ─────────────────────────────────
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
        @EstadoActual = e.Nombre, @RecetaID = op.RecetaID,
        @CantidadProgramada = op.CantidadProgramada,
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
    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT rd.InsumoID,
               (rd.CantidadRequerida * @FactorEscala) * (1 + rd.PorcentajeMermaEstandar / 100.0)
        FROM Produccion.RecetaBOM_Detalle rd
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
            ORDER BY ISNULL(l.FechaVencimiento,'9999-12-31') ASC;

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

PRINT 'Fix 2 completado: recetas, OPs y Kardex borrados. Columnas UnidadID eliminadas. SPs recreados.';
GO
