-- ============================================================
-- migration_qr_modo_v1.sql
-- Agrega modo de QR configurable a Rrhh.QrAsistenciaConfig
-- Modos: 'TTL' (TOTP 5 min, default) | 'SINGLE_USE' (rota al usarse)
-- Ejecutar en NEXO_ERP. Seguro de re-ejecutar (IF NOT EXISTS).
-- ============================================================

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('Rrhh.QrAsistenciaConfig') AND name = 'ModoQr'
)
    ALTER TABLE Rrhh.QrAsistenciaConfig
        ADD ModoQr NVARCHAR(20) NOT NULL DEFAULT 'TTL';

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('Rrhh.QrAsistenciaConfig') AND name = 'TokenActual'
)
    ALTER TABLE Rrhh.QrAsistenciaConfig
        ADD TokenActual NVARCHAR(64) NULL;

PRINT 'migration_qr_modo_v1.sql completada.';
