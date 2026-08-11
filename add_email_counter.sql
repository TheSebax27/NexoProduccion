-- Agrega contador de emails del día a la tabla de configuración de email
ALTER TABLE Organizacion.ConfiguracionEmail
    ADD EmailsHoy  INT  NOT NULL DEFAULT 0,
        FechaContador DATE NULL;
GO
PRINT 'Contador diario de emails agregado OK';
