-- migration_soporte_v1.sql
-- Módulo de Soporte: tickets, comentarios, adjuntos de referencia.
-- Ejecutar una sola vez.

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Soporte')
    EXEC('CREATE SCHEMA Soporte');
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('Soporte.Tickets'))
BEGIN
    CREATE TABLE Soporte.Tickets (
        TicketID        int             IDENTITY(1,1) PRIMARY KEY,
        Titulo          nvarchar(300)   NOT NULL,
        Descripcion     nvarchar(max)   NOT NULL,
        Categoria       nvarchar(100)   NOT NULL,  -- Bug, Consulta, Mejora, Acceso, Otro
        Prioridad       nvarchar(20)    NOT NULL DEFAULT 'MEDIA', -- BAJA / MEDIA / ALTA / CRITICA
        Estado          nvarchar(30)    NOT NULL DEFAULT 'ABIERTO', -- ABIERTO / EN_PROGRESO / RESUELTO / CERRADO
        ReportadoPor    int             NOT NULL,  -- UsuarioID
        AsignadoA       int             NULL,      -- UsuarioID
        ClienteID       int             NULL REFERENCES Crm.Clientes(ClienteID),
        FechaCreacion   datetime2       NOT NULL DEFAULT GETUTCDATE(),
        FechaActualizacion datetime2    NOT NULL DEFAULT GETUTCDATE(),
        FechaResolucion datetime2       NULL,
        Notas           nvarchar(1000)  NULL
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('Soporte.TicketComentarios'))
BEGIN
    CREATE TABLE Soporte.TicketComentarios (
        ComentarioID    int             IDENTITY(1,1) PRIMARY KEY,
        TicketID        int             NOT NULL REFERENCES Soporte.Tickets(TicketID) ON DELETE CASCADE,
        AutorID         int             NOT NULL,
        Texto           nvarchar(max)   NOT NULL,
        EsInterno       bit             NOT NULL DEFAULT 0,  -- 1 = nota interna, no visible al cliente
        Fecha           datetime2       NOT NULL DEFAULT GETUTCDATE()
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Tickets_Estado' AND object_id = OBJECT_ID('Soporte.Tickets'))
    CREATE INDEX IX_Tickets_Estado ON Soporte.Tickets (Estado, FechaCreacion DESC);
GO

PRINT 'migration_soporte_v1 OK';
