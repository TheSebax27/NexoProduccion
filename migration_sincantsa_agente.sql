-- Agrega flag SincAntsaActivo a AgentesSync para que NEXO Web controle
-- el parametro SINCANTSA (1518) en la Visions DB de cada cliente.
-- El agente lee este valor en cada ciclo y lo aplica localmente en Visions.
-- Idempotente: no falla si la columna ya existe.
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('Integracion.AgentesSync')
      AND name = 'SincAntsaActivo'
)
    ALTER TABLE Integracion.AgentesSync
    ADD SincAntsaActivo bit NOT NULL DEFAULT 0;
