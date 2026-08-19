-- =============================================================
-- NEXO ERP — Soporte para numeración de facturas desde Visions
-- Ejecutar en VISIONSDBL1
-- =============================================================
USE VISIONSDBL1;
GO

-- Tabla de rastreo: una fila por cada factura NEXO exportada a Visions.
-- El agente escribe aquí cuando exporta. Cuando Visions asigna el número
-- real al MOVDETALLES (actualizando NRODOC), el trigger lo copia acá.
-- El agente luego lee la tabla y actualiza NEXO vía API.
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='NEXO_FacturasSalientes' AND schema_id=SCHEMA_ID('dbo'))
BEGIN
    CREATE TABLE dbo.NEXO_FacturasSalientes (
        FacturaID     INT          NOT NULL,
        NexoNroDoc    VARCHAR(50)  NOT NULL,   -- placeholder usado: 'NEXO-{FacturaID}'
        TipDocVisions VARCHAR(20)  NULL,        -- tipo asignado por Visions
        NroDocVisions VARCHAR(50)  NULL,        -- número asignado por Visions
        FechaEnvio    DATETIME     NOT NULL DEFAULT GETDATE(),
        FechaSyncBack DATETIME     NULL,        -- cuando el agente actualizó NEXO
        CONSTRAINT PK_NEXO_FacturasSalientes PRIMARY KEY (FacturaID)
    );
    PRINT 'Tabla NEXO_FacturasSalientes creada.';
END
ELSE
    PRINT 'Tabla NEXO_FacturasSalientes ya existe.';
GO

-- Trigger: detecta cuando Visions actualiza el NRODOC de una fila cuyo
-- NRODOC original era un placeholder NEXO-*, y copia el nuevo número a la tabla.
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name='trg_NEXO_ActualizarFacturaSaliente')
    DROP TRIGGER dbo.trg_NEXO_ActualizarFacturaSaliente;
GO

CREATE TRIGGER dbo.trg_NEXO_ActualizarFacturaSaliente
ON dbo.MOVDETALLES
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Solo actuar cuando la columna NRODOC cambió
    IF UPDATE(NRODOC)
    BEGIN
        -- Usar DISTINCT para que múltiples líneas de la misma factura no generen
        -- múltiples intentos de UPDATE (el WHERE nfs.NroDocVisions IS NULL lo
        -- hace idempotente de todas formas, pero esto es más limpio).
        UPDATE nfs
        SET
            NroDocVisions = src.NewNroDoc,
            TipDocVisions = src.NewTipDoc
        FROM dbo.NEXO_FacturasSalientes nfs
        INNER JOIN (
            SELECT DISTINCT
                d.NRODOC AS OldNroDoc,
                i.NRODOC AS NewNroDoc,
                i.TIPDOC AS NewTipDoc
            FROM inserted i
            INNER JOIN deleted  d ON i.NRODOC <> d.NRODOC   -- NRODOC efectivamente cambió
            WHERE d.NRODOC LIKE 'NEXO-%'                      -- era un placeholder NEXO
        ) AS src ON src.OldNroDoc = nfs.NexoNroDoc
        WHERE nfs.NroDocVisions IS NULL;                      -- aún no sincronizado
    END
END;
GO

PRINT 'Trigger trg_NEXO_ActualizarFacturaSaliente creado.';
GO
