-- Agrega soporte de foto a Produccion.Maquinaria
-- Ejecutar UNA sola vez en NEXO_ERP.

ALTER TABLE Produccion.Maquinaria
    ADD Foto             VARBINARY(MAX) NULL,
        FotoContentType  NVARCHAR(100)  NULL;
