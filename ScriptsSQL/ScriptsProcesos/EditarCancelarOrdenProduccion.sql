/* ============================================================================
   NEXO ERP - Editar y Cancelar Orden de Produccion (solo en estado Planificada)
   Antes de Liberar no se ha descontado stock ni generado ningun Kardex, asi
   que editar o cancelar en ese punto es seguro. El estado 'Cancelada' ya
   existia sembrado en Produccion.EstadosOP pero ningun codigo lo usaba.
   ============================================================================ */

USE NEXO_ERP;
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE Produccion.sp_ActualizarOrdenProduccion
    @OrdenProduccionID INT,
    @TipoProduccionID INT,
    @ProductoTerminadoID INT,
    @RecetaID INT,
    @CantidadProgramada DECIMAL(18,4),
    @ClienteID INT = NULL,
    @CentroCostoDestinoID INT,
    @BodegaOrigenMPID INT,
    @BodegaDestinoPTID INT,
    @CentroTrabajoID INT = NULL,
    @FechaPlanificada DATETIME2 = NULL,
    @Observaciones NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EstadoActual NVARCHAR(30);
    SELECT @EstadoActual = e.Nombre
    FROM Produccion.OrdenesProduccion op
    JOIN Produccion.EstadosOP e ON e.EstadoOPID = op.EstadoOPID
    WHERE op.OrdenProduccionID = @OrdenProduccionID;

    IF @EstadoActual IS NULL
        THROW 51040, 'La orden de produccion no existe.', 1;

    IF @EstadoActual <> 'Planificada'
        THROW 51041, 'Solo se pueden editar ordenes en estado Planificada (antes de liberarlas).', 1;

    UPDATE Produccion.OrdenesProduccion
    SET TipoProduccionID = @TipoProduccionID,
        ProductoTerminadoID = @ProductoTerminadoID,
        RecetaID = @RecetaID,
        CantidadProgramada = @CantidadProgramada,
        ClienteID = @ClienteID,
        CentroCostoDestinoID = @CentroCostoDestinoID,
        BodegaOrigenMPID = @BodegaOrigenMPID,
        BodegaDestinoPTID = @BodegaDestinoPTID,
        CentroTrabajoID = @CentroTrabajoID,
        FechaPlanificada = @FechaPlanificada,
        Observaciones = @Observaciones
    WHERE OrdenProduccionID = @OrdenProduccionID;

    SELECT 'OK' AS Resultado;
END
GO

CREATE OR ALTER PROCEDURE Produccion.sp_CancelarOrdenProduccion
    @OrdenProduccionID INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EstadoActual NVARCHAR(30);
    SELECT @EstadoActual = e.Nombre
    FROM Produccion.OrdenesProduccion op
    JOIN Produccion.EstadosOP e ON e.EstadoOPID = op.EstadoOPID
    WHERE op.OrdenProduccionID = @OrdenProduccionID;

    IF @EstadoActual IS NULL
        THROW 51050, 'La orden de produccion no existe.', 1;

    IF @EstadoActual <> 'Planificada'
        THROW 51051, 'Solo se pueden cancelar ordenes en estado Planificada (aun no liberadas).', 1;

    UPDATE Produccion.OrdenesProduccion
    SET EstadoOPID = (SELECT EstadoOPID FROM Produccion.EstadosOP WHERE Nombre = 'Cancelada')
    WHERE OrdenProduccionID = @OrdenProduccionID;

    SELECT 'OK' AS Resultado;
END
GO

PRINT 'sp_ActualizarOrdenProduccion y sp_CancelarOrdenProduccion creados/actualizados correctamente.';
GO
