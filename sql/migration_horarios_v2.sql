-- ============================================================
-- Migración: Horarios v2 + Consumidor Final + ProduccionAutoEjecutada
-- sqlcmd -S DESKTOP-V83PQ7M\JONATHAN -d NEXO_ERP -i C:\Produccion\sql\migration_horarios_v2.sql
-- ============================================================
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;

-- ── 1. HorarioDias: tabla de horario por día ──────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='HorarioDias' AND schema_id=SCHEMA_ID('Rrhh'))
BEGIN
    CREATE TABLE Rrhh.HorarioDias (
        HorarioDiaID         INT IDENTITY(1,1) PRIMARY KEY,
        HorarioID            INT NOT NULL REFERENCES Rrhh.Horarios(HorarioID) ON DELETE CASCADE,
        Semana               CHAR(1) NULL,        -- NULL=siempre (FIJO), 'A'/'B' para SEMANA_AB
        DiaSemana            TINYINT NOT NULL,    -- 1=Lunes ... 7=Domingo
        HoraEntrada          TIME NOT NULL,
        HoraSalida           TIME NOT NULL,
        TieneAlmuerzo        BIT NOT NULL DEFAULT 0,
        HoraInicioAlmuerzo   TIME NULL,
        HoraFinAlmuerzo      TIME NULL,
        CONSTRAINT CK_HorarioDias_Semana    CHECK (Semana IN ('A','B')),
        CONSTRAINT CK_HorarioDias_DiaSemana CHECK (DiaSemana BETWEEN 1 AND 7),
        CONSTRAINT UQ_HorarioDias_Dia       UNIQUE (HorarioID, Semana, DiaSemana)
    );
    PRINT '✓ Tabla Rrhh.HorarioDias creada.';
END

-- ── 2. Columna TipoCiclo en Rrhh.Horarios ─────────────────
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='Rrhh' AND TABLE_NAME='Horarios' AND COLUMN_NAME='TipoCiclo')
BEGIN
    ALTER TABLE Rrhh.Horarios ADD TipoCiclo NVARCHAR(10) NOT NULL DEFAULT 'FIJO';
    PRINT '✓ Columna TipoCiclo agregada a Rrhh.Horarios.';
END

-- ── 3. Migrar horarios existentes a HorarioDias ───────────
INSERT INTO Rrhh.HorarioDias (HorarioID, Semana, DiaSemana, HoraEntrada, HoraSalida, TieneAlmuerzo)
SELECT h.HorarioID, NULL, d.DiaSemana, h.HoraEntrada, h.HoraSalida, 0
FROM Rrhh.Horarios h
CROSS JOIN (VALUES (1),(2),(3),(4),(5),(6),(7)) AS d(DiaSemana)
WHERE h.HoraEntrada IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM Rrhh.HorarioDias WHERE HorarioID=h.HorarioID AND DiaSemana=d.DiaSemana AND Semana IS NULL)
  AND (
    (d.DiaSemana=1 AND h.LunesActivo=1)    OR
    (d.DiaSemana=2 AND h.MartesActivo=1)   OR
    (d.DiaSemana=3 AND h.MiercolesActivo=1)OR
    (d.DiaSemana=4 AND h.JuevesActivo=1)   OR
    (d.DiaSemana=5 AND h.ViernesActivo=1)  OR
    (d.DiaSemana=6 AND h.SabadoActivo=1)   OR
    (d.DiaSemana=7 AND h.DomingoActivo=1)
  );
PRINT '✓ Horarios existentes migrados a HorarioDias.';

-- ── 4. ProduccionAutoEjecutada en Facturas ─────────────────
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA='Facturacion' AND TABLE_NAME='Facturas' AND COLUMN_NAME='ProduccionAutoEjecutada')
BEGIN
    ALTER TABLE Facturacion.Facturas ADD ProduccionAutoEjecutada BIT NOT NULL DEFAULT 0;
    PRINT '✓ Columna ProduccionAutoEjecutada agregada a Facturacion.Facturas.';
END

-- ── 5. Cliente "Consumidor Final" del sistema ──────────────
IF NOT EXISTS (SELECT 1 FROM Crm.Clientes WHERE NIT = 'CF-SYS')
BEGIN
    INSERT INTO Crm.Clientes (Nombre, NIT, Estado)
    VALUES ('Consumidor Final', 'CF-SYS', 1);
    PRINT '✓ Cliente Consumidor Final insertado (NIT=CF-SYS).';
END

DECLARE @CfId INT = (SELECT ClienteID FROM Crm.Clientes WHERE NIT='CF-SYS');
PRINT 'ClienteID Consumidor Final: ' + CAST(@CfId AS VARCHAR);
GO
