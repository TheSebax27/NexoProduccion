-- Agrega IntervalSeconds a AgentesSync para soportar intervalos menores a 1 minuto.
-- Cuando IntervalSeconds > 0, el agente usa segundos en vez de minutos.
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('Integracion.AgentesSync')
      AND name = 'IntervalSeconds'
)
BEGIN
    ALTER TABLE Integracion.AgentesSync
        ADD IntervalSeconds INT NOT NULL DEFAULT 0;
END
