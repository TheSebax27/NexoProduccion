-- migration_formularios_v1.sql
-- Módulo de Formularios: creador de formularios, campos, respuestas.
-- Ejecutar una sola vez.

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Formularios')
    EXEC('CREATE SCHEMA Formularios');
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('Formularios.Formularios'))
BEGIN
    CREATE TABLE Formularios.Formularios (
        FormularioID    int             IDENTITY(1,1) PRIMARY KEY,
        Titulo          nvarchar(300)   NOT NULL,
        Descripcion     nvarchar(1000)  NULL,
        Token           nvarchar(64)    NOT NULL UNIQUE,  -- URL pública /f/{Token}
        Activo          bit             NOT NULL DEFAULT 1,
        AceptaRespuestas bit           NOT NULL DEFAULT 1,
        MensajeExito    nvarchar(500)   NULL,
        CreadoPor       int             NOT NULL,
        FechaCreacion   datetime2       NOT NULL DEFAULT GETUTCDATE(),
        FechaActualizacion datetime2    NOT NULL DEFAULT GETUTCDATE()
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('Formularios.Campos'))
BEGIN
    CREATE TABLE Formularios.Campos (
        CampoID         int             IDENTITY(1,1) PRIMARY KEY,
        FormularioID    int             NOT NULL REFERENCES Formularios.Formularios(FormularioID) ON DELETE CASCADE,
        Tipo            nvarchar(30)    NOT NULL,  -- TEXTO, PARRAFO, EMAIL, TELEFONO, NUMERO, FECHA, SELECCION, MULTIPLE, CHECKBOX
        Etiqueta        nvarchar(300)   NOT NULL,
        Placeholder     nvarchar(300)   NULL,
        Requerido       bit             NOT NULL DEFAULT 0,
        Orden           int             NOT NULL DEFAULT 0,
        Opciones        nvarchar(max)   NULL  -- JSON array para SELECCION/MULTIPLE
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID('Formularios.Respuestas'))
BEGIN
    CREATE TABLE Formularios.Respuestas (
        RespuestaID     int             IDENTITY(1,1) PRIMARY KEY,
        FormularioID    int             NOT NULL REFERENCES Formularios.Formularios(FormularioID) ON DELETE CASCADE,
        Datos           nvarchar(max)   NOT NULL,  -- JSON con campo→valor
        IPOrigen        nvarchar(45)    NULL,
        FechaRespuesta  datetime2       NOT NULL DEFAULT GETUTCDATE()
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Respuestas_FormularioID' AND object_id = OBJECT_ID('Formularios.Respuestas'))
    CREATE INDEX IX_Respuestas_FormularioID ON Formularios.Respuestas (FormularioID, FechaRespuesta DESC);
GO

PRINT 'migration_formularios_v1 OK';
