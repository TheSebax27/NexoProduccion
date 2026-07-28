/* ============================================================================
   SISTEMA NEXO - Script 05: Esquema de Integracion con Visions (u otros POS)
   Ejecutar en NEXO_ERP despues de 01, 02, 03 y 04.

   Diseñado a partir de la revision real del esquema de Visions
   (VisionsInicial.sql). Puntos clave que dictan este diseño:
     - Visions identifica sucursal con CENTROCOSTO (smallint) -> mapeamos
       contra nuestro CentroCostoID (INT) en Organizacion.CentrosCosto.
     - Visions identifica producto con REFERENCIA (nvarchar(30)) -> mapeamos
       contra nuestro ArticuloID en Integracion.MapeoArticulos.
     - Visions NO tiene bodegas reales: TARJETA.EXISTENCIAS es una sola
       cifra por (CENTROCOSTO, REFERENCIA). Por eso cuando salga un evento
       hacia Visions, se debe enviar la suma de todas nuestras bodegas de
       ese centro de costo, nunca el detalle por bodega.
   ============================================================================ */
USE NEXO_ERP;
GO

CREATE SCHEMA Integracion AUTHORIZATION dbo;
GO

-- ----------------------------------------------------------------------------
-- Interruptor por centro de costo: si esa sucursal tiene Visions o no.
-- ----------------------------------------------------------------------------
ALTER TABLE Organizacion.CentrosCosto ADD
    TieneVisions                BIT NOT NULL DEFAULT 0,
    IdentificadorClienteVisions NVARCHAR(50) NULL; -- guarda aqui el CENTROCOSTO (smallint) de Visions, como texto para no atarnos a un solo sistema externo
GO

-- ----------------------------------------------------------------------------
-- Mapeo de productos: nuestro ArticuloID <-> TARJETA.REFERENCIA de Visions
-- ----------------------------------------------------------------------------
CREATE TABLE Integracion.MapeoArticulos (
    MapeoID                 INT IDENTITY(1,1) PRIMARY KEY,
    ArticuloID              INT NOT NULL REFERENCES Catalogo.Articulos(ArticuloID),
    CentroCostoID           INT NOT NULL REFERENCES Organizacion.CentrosCosto(CentroCostoID),
    CodigoArticuloVisions   NVARCHAR(30) NOT NULL, -- debe existir como REFERENCIA en TARJETA para ese CENTROCOSTO
    Estado                  BIT NOT NULL DEFAULT 1,
    FechaCreacion           DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT UQ_Mapeo_Articulo UNIQUE (ArticuloID, CentroCostoID),
    CONSTRAINT UQ_Mapeo_Referencia UNIQUE (CentroCostoID, CodigoArticuloVisions)
);
GO

-- ----------------------------------------------------------------------------
-- Cola de salida: Produccion -> Visions (entradas de stock que Produccion
-- ya decidio y cerro: cierre de OP, traspaso recibido en un punto de venta).
-- ----------------------------------------------------------------------------
CREATE TABLE Integracion.EventosSalientes (
    EventoID            BIGINT IDENTITY(1,1) PRIMARY KEY,
    TipoEvento          NVARCHAR(50) NOT NULL
                        CHECK (TipoEvento IN ('ENTRADA_PRODUCTO_TERMINADO','TRASPASO_RECIBIDO')),
    CentroCostoID       INT NOT NULL REFERENCES Organizacion.CentrosCosto(CentroCostoID),
    ArticuloID          INT NOT NULL REFERENCES Catalogo.Articulos(ArticuloID),
    Cantidad            DECIMAL(18,4) NOT NULL,
    CostoUnitario       DECIMAL(18,4) NOT NULL,
    KardexID            BIGINT NULL REFERENCES Kardex.KardexMovimientos(KardexID),
    Estado              NVARCHAR(20) NOT NULL DEFAULT 'PENDIENTE'
                        CHECK (Estado IN ('PENDIENTE','ENVIADO','CONFIRMADO','ERROR')),
    IntentosEnvio       INT NOT NULL DEFAULT 0,
    UltimoError         NVARCHAR(500) NULL,
    FechaCreacion       DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    FechaEnvio          DATETIME2 NULL
);
GO
CREATE INDEX IX_EventosSalientes_Pendientes ON Integracion.EventosSalientes(Estado, CentroCostoID);
GO

-- Vista que el agente de sincronizacion consulta directamente: ya trae
-- el codigo de centro de costo y de referencia en el formato que Visions
-- necesita, sin que el agente tenga que hacer los JOIN.
CREATE OR ALTER VIEW Integracion.vw_EventosPendientesParaVisions AS
SELECT
    e.EventoID, e.TipoEvento, e.Cantidad, e.CostoUnitario, e.FechaCreacion,
    cc.IdentificadorClienteVisions AS CentroCostoVisions,
    m.CodigoArticuloVisions AS ReferenciaVisions
FROM Integracion.EventosSalientes e
JOIN Organizacion.CentrosCosto cc ON cc.CentroCostoID = e.CentroCostoID
JOIN Integracion.MapeoArticulos m ON m.ArticuloID = e.ArticuloID AND m.CentroCostoID = e.CentroCostoID
WHERE e.Estado = 'PENDIENTE' AND cc.TieneVisions = 1;
GO

-- ----------------------------------------------------------------------------
-- Cola de entrada: Visions -> Produccion (ventas/consumos reales en el punto
-- de venta). Idempotente por IdEventoExterno para que un reintento del
-- agente nunca cuente la misma venta dos veces.
-- ----------------------------------------------------------------------------
CREATE TABLE Integracion.EventosEntrantes (
    EventoEntranteID        BIGINT IDENTITY(1,1) PRIMARY KEY,
    IdEventoExterno         NVARCHAR(150) NOT NULL UNIQUE, -- ej: '3-FV-000123-1-REF001' (CentroCosto-TipDoc-NroDoc-Orden-Referencia)
    TipoEvento              NVARCHAR(50) NOT NULL CHECK (TipoEvento IN ('VENTA','AJUSTE_INVENTARIO')),
    CentroCostoID           INT NOT NULL REFERENCES Organizacion.CentrosCosto(CentroCostoID),
    CodigoArticuloVisions   NVARCHAR(30) NOT NULL,
    Cantidad                DECIMAL(18,4) NOT NULL,
    FechaEventoOrigen       DATETIME2 NOT NULL,
    Procesado               BIT NOT NULL DEFAULT 0,
    FechaRecepcion          DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    FechaProcesado          DATETIME2 NULL
);
GO
CREATE INDEX IX_EventosEntrantes_Pendientes ON Integracion.EventosEntrantes(Procesado);
GO

-- ----------------------------------------------------------------------------
-- Solo para reportes/dashboard: cuanto se ha vendido realmente en cada punto
-- de venta de lo que Produccion le entrego. NO es la fuente de verdad del
-- stock de Produccion (ese sigue siendo Inventario.InventarioStock).
-- ----------------------------------------------------------------------------
CREATE TABLE Integracion.InventarioReportadoVisions (
    ArticuloID                  INT NOT NULL REFERENCES Catalogo.Articulos(ArticuloID),
    CentroCostoID               INT NOT NULL REFERENCES Organizacion.CentrosCosto(CentroCostoID),
    CantidadVendidaAcumulada    DECIMAL(18,4) NOT NULL DEFAULT 0,
    UltimaActualizacion         DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    PRIMARY KEY (ArticuloID, CentroCostoID)
);
GO

-- ----------------------------------------------------------------------------
-- SP: procesa un evento entrante (venta reportada por Visions) y actualiza
-- el acumulado de reporte. Idempotente: si el IdEventoExterno ya existe,
-- no hace nada (lo detecta el INSERT con UNIQUE antes de llamar este SP).
-- ----------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Integracion.sp_ProcesarEventoEntrante
    @EventoEntranteID BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ArticuloID INT, @CentroCostoID INT, @Cantidad DECIMAL(18,4), @Procesado BIT;

    SELECT
        @ArticuloID = m.ArticuloID,
        @CentroCostoID = e.CentroCostoID,
        @Cantidad = e.Cantidad,
        @Procesado = e.Procesado
    FROM Integracion.EventosEntrantes e
    JOIN Integracion.MapeoArticulos m
        ON m.CodigoArticuloVisions = e.CodigoArticuloVisions AND m.CentroCostoID = e.CentroCostoID
    WHERE e.EventoEntranteID = @EventoEntranteID;

    IF @ArticuloID IS NULL
        THROW 54000, 'No existe mapeo de articulo para este evento entrante; revisar Integracion.MapeoArticulos.', 1;

    IF @Procesado = 1
        RETURN;

    BEGIN TRANSACTION;

    MERGE Integracion.InventarioReportadoVisions AS destino
    USING (SELECT @ArticuloID AS ArticuloID, @CentroCostoID AS CentroCostoID) AS origen
    ON destino.ArticuloID = origen.ArticuloID AND destino.CentroCostoID = origen.CentroCostoID
    WHEN MATCHED THEN UPDATE SET
        CantidadVendidaAcumulada = destino.CantidadVendidaAcumulada + @Cantidad,
        UltimaActualizacion = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN INSERT (ArticuloID, CentroCostoID, CantidadVendidaAcumulada)
        VALUES (@ArticuloID, @CentroCostoID, @Cantidad);

    UPDATE Integracion.EventosEntrantes
    SET Procesado = 1, FechaProcesado = SYSUTCDATETIME()
    WHERE EventoEntranteID = @EventoEntranteID;

    COMMIT TRANSACTION;
END
GO

PRINT 'Esquema de integracion con Visions creado correctamente.';