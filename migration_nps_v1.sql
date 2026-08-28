-- ============================================================
-- NPS automático: encuesta de satisfacción post-resolución
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID('Soporte.EncuestasNPS'))
BEGIN
    CREATE TABLE Soporte.EncuestasNPS (
        EncuestaNPSID   INT           IDENTITY(1,1) PRIMARY KEY,
        TicketID        INT           NOT NULL REFERENCES Soporte.Tickets(TicketID),
        Puntuacion      TINYINT       NOT NULL CHECK (Puntuacion BETWEEN 0 AND 10),
        Comentario      NVARCHAR(500) NULL,
        FechaRespuesta  DATETIME      NOT NULL DEFAULT GETDATE()
    );
    CREATE UNIQUE INDEX UX_EncuestasNPS_Ticket ON Soporte.EncuestasNPS(TicketID);
    PRINT 'Tabla Soporte.EncuestasNPS creada.';
END
ELSE
    PRINT 'Tabla Soporte.EncuestasNPS ya existe — sin cambios.';
GO
