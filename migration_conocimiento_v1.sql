-- ============================================================
-- Base de conocimiento interna (FAQs y artículos de soporte)
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Conocimiento')
BEGIN
    EXEC('CREATE SCHEMA Conocimiento');
    PRINT 'Schema Conocimiento creado.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID('Conocimiento.Articulos'))
BEGIN
    CREATE TABLE Conocimiento.Articulos (
        ArticuloID          INT             IDENTITY(1,1) PRIMARY KEY,
        Titulo              NVARCHAR(300)   NOT NULL,
        Contenido           NVARCHAR(MAX)   NOT NULL,
        Categoria           NVARCHAR(100)   NOT NULL DEFAULT 'General',
        Tags                NVARCHAR(500)   NULL,
        AutorID             INT             NOT NULL REFERENCES Seguridad.Usuarios(UsuarioID),
        FechaCreacion       DATETIME        NOT NULL DEFAULT GETDATE(),
        FechaActualizacion  DATETIME        NOT NULL DEFAULT GETDATE(),
        Activo              BIT             NOT NULL DEFAULT 1,
        Vistas              INT             NOT NULL DEFAULT 0
    );
    CREATE INDEX IX_Articulos_Categoria ON Conocimiento.Articulos(Categoria);
    PRINT 'Tabla Conocimiento.Articulos creada.';
END
ELSE
    PRINT 'Tabla Conocimiento.Articulos ya existe — sin cambios.';
GO
