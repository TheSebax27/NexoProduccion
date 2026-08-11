-- ============================================================
-- Módulo Maquinaria v1
-- sqlcmd -S DESKTOP-V83PQ7M\JONATHAN -d NEXO_ERP -i C:\Produccion\sql\migration_maquinaria_v1.sql
-- ============================================================
SET NOCOUNT ON;

-- ── 1. Tipos de maquinaria ────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='TiposMaquinaria' AND schema_id=SCHEMA_ID('Produccion'))
BEGIN
    CREATE TABLE Produccion.TiposMaquinaria (
        TipoMaquinariaID INT IDENTITY(1,1) PRIMARY KEY,
        Nombre           NVARCHAR(100) NOT NULL,
        Descripcion      NVARCHAR(300) NULL,
        Activo           BIT NOT NULL DEFAULT 1,
        CONSTRAINT UQ_TiposMaquinaria_Nombre UNIQUE (Nombre)
    );
    PRINT '✓ Tabla Produccion.TiposMaquinaria creada.';
END

-- Datos semilla de tipos
INSERT INTO Produccion.TiposMaquinaria (Nombre, Descripcion)
SELECT * FROM (VALUES
    ('Horno Industrial',          'Hornos de cocción, secado o tratamiento térmico'),
    ('Mezcladora / Amasadora',    'Mezcladoras industriales y amasadoras'),
    ('Empacadora / Selladora',    'Equipos de empaque, sellado y embalaje'),
    ('Cortadora / Sierra',        'Cortadoras, sierras y troqueladoras'),
    ('Compresor',                 'Compresores de aire o gas'),
    ('Bomba / Sistema hidráulico','Bombas de fluidos y sistemas hidráulicos'),
    ('Banda / Conveyor',          'Cintas transportadoras y conveyors'),
    ('Torno / Fresadora',         'Maquinaria de mecanizado CNC o manual'),
    ('Caldera / Generador',       'Calderas de vapor, generadores eléctricos'),
    ('Equipo de frío',            'Cámaras frías, refrigeradores industriales'),
    ('Báscula / Balanza',         'Básculas industriales y de precisión'),
    ('Otro',                      'Tipo de maquinaria no categorizado')
) AS T(Nombre, Descripcion)
WHERE NOT EXISTS (SELECT 1 FROM Produccion.TiposMaquinaria WHERE Nombre = T.Nombre);
PRINT '✓ Tipos de maquinaria sembrados.';

-- ── 2. Maquinaria ─────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='Maquinaria' AND schema_id=SCHEMA_ID('Produccion'))
BEGIN
    CREATE TABLE Produccion.Maquinaria (
        MaquinariaID       INT IDENTITY(1,1) PRIMARY KEY,
        Codigo             NVARCHAR(50)    NOT NULL,
        Nombre             NVARCHAR(150)   NOT NULL,
        TipoMaquinariaID   INT             NOT NULL REFERENCES Produccion.TiposMaquinaria(TipoMaquinariaID),
        CentroTrabajoID    INT             NULL     REFERENCES Organizacion.CentrosTrabajo(CentroTrabajoID),
        Estado             NVARCHAR(30)    NOT NULL DEFAULT 'Activa',
        Marca              NVARCHAR(100)   NULL,
        Modelo             NVARCHAR(100)   NULL,
        NumeroSerie        NVARCHAR(100)   NULL,
        FechaAdquisicion   DATE            NULL,
        VidaUtilAnios      INT             NULL,
        CostoAdquisicion   DECIMAL(18,2)   NULL,
        CostoHoraOperacion DECIMAL(18,4)   NULL,
        CapacidadMaxima    DECIMAL(18,4)   NULL,
        UnidadCapacidad    NVARCHAR(50)    NULL,
        UbicacionFisica    NVARCHAR(200)   NULL,
        Notas              NVARCHAR(MAX)   NULL,
        FechaCreacion      DATETIME        NOT NULL DEFAULT GETDATE(),
        CONSTRAINT UQ_Maquinaria_Codigo UNIQUE (Codigo),
        CONSTRAINT CK_Maquinaria_Estado CHECK (Estado IN ('Activa','EnMantenimiento','Inactiva','BajaDefinitiva'))
    );
    PRINT '✓ Tabla Produccion.Maquinaria creada.';
END

-- ── 3. Mantenimientos ─────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='MantenimientoMaquinaria' AND schema_id=SCHEMA_ID('Produccion'))
BEGIN
    CREATE TABLE Produccion.MantenimientoMaquinaria (
        MantenimientoID       INT IDENTITY(1,1) PRIMARY KEY,
        MaquinariaID          INT             NOT NULL REFERENCES Produccion.Maquinaria(MaquinariaID) ON DELETE CASCADE,
        TipoMantenimiento     NVARCHAR(30)    NOT NULL,
        FechaRealizado        DATE            NOT NULL,
        Descripcion           NVARCHAR(500)   NOT NULL,
        Costo                 DECIMAL(18,2)   NULL,
        HorasFueraServicio    DECIMAL(10,2)   NULL,
        Tecnico               NVARCHAR(200)   NULL,
        ProximoMantenimiento  DATE            NULL,
        Observaciones         NVARCHAR(500)   NULL,
        UsuarioID             INT             NULL REFERENCES Seguridad.Usuarios(UsuarioID),
        FechaRegistro         DATETIME        NOT NULL DEFAULT GETDATE(),
        CONSTRAINT CK_Mant_Tipo CHECK (TipoMantenimiento IN ('Preventivo','Correctivo','Predictivo'))
    );
    CREATE INDEX IX_Mant_Maquinaria ON Produccion.MantenimientoMaquinaria(MaquinariaID, FechaRealizado DESC);
    PRINT '✓ Tabla Produccion.MantenimientoMaquinaria creada.';
END
GO
