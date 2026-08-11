-- ============================================================
-- Módulo Maquinaria v2 — enlace con Recetas y Órdenes
-- sqlcmd -S DESKTOP-V83PQ7M\JONATHAN -d NEXO_ERP -i C:\Produccion\sql\migration_maquinaria_v2.sql
-- ============================================================
SET NOCOUNT ON;

-- ── 1. Máquinas por receta (BOM) ─────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='RecetaMaquinaria' AND schema_id=SCHEMA_ID('Produccion'))
BEGIN
    CREATE TABLE Produccion.RecetaMaquinaria (
        RecetaID              INT           NOT NULL REFERENCES Produccion.RecetaBOM(RecetaID)    ON DELETE CASCADE,
        MaquinariaID          INT           NOT NULL REFERENCES Produccion.Maquinaria(MaquinariaID),
        HorasEstimadasPorLote DECIMAL(10,2) NULL,
        Notas                 NVARCHAR(300) NULL,
        CONSTRAINT PK_RecetaMaquinaria PRIMARY KEY (RecetaID, MaquinariaID)
    );
    PRINT '✓ Tabla Produccion.RecetaMaquinaria creada.';
END

-- ── 2. Máquinas por orden de producción ───────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='OrdenMaquinaria' AND schema_id=SCHEMA_ID('Produccion'))
BEGIN
    CREATE TABLE Produccion.OrdenMaquinaria (
        OrdenProduccionID INT           NOT NULL REFERENCES Produccion.OrdenesProduccion(OrdenProduccionID) ON DELETE CASCADE,
        MaquinariaID      INT           NOT NULL REFERENCES Produccion.Maquinaria(MaquinariaID),
        HorasReales       DECIMAL(10,2) NULL,
        Notas             NVARCHAR(300) NULL,
        CONSTRAINT PK_OrdenMaquinaria PRIMARY KEY (OrdenProduccionID, MaquinariaID)
    );
    CREATE INDEX IX_OrdenMaquinaria_Maquinaria ON Produccion.OrdenMaquinaria(MaquinariaID);
    PRINT '✓ Tabla Produccion.OrdenMaquinaria creada.';
END
GO
