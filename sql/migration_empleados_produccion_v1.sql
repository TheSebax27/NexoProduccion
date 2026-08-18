-- ==========================================================================
-- migration_empleados_produccion_v1.sql
-- Asignacion de empleados a Recetas y Ordenes de Produccion
-- Patron gemelo al de maquinaria (RecetaMaquinaria / OrdenMaquinaria)
-- ==========================================================================

USE NEXO_ERP;
GO

-- ── 1. TarifaHora en Empleados ────────────────────────────────────────────
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('Rrhh.Empleados') AND name = 'TarifaHora'
)
BEGIN
    ALTER TABLE Rrhh.Empleados ADD TarifaHora DECIMAL(18,4) NULL;
    PRINT 'Columna TarifaHora agregada a Rrhh.Empleados.';
END
ELSE
    PRINT 'TarifaHora ya existe en Rrhh.Empleados.';
GO

-- ── 2. RecetaEmpleado ─────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'RecetaEmpleado' AND schema_id = SCHEMA_ID('Produccion'))
BEGIN
    CREATE TABLE Produccion.RecetaEmpleado (
        RecetaEmpleadoID  INT            NOT NULL IDENTITY(1,1) PRIMARY KEY,
        RecetaID          INT            NOT NULL
            CONSTRAINT FK_RecetaEmpleado_Receta
                REFERENCES Produccion.RecetaBOM(RecetaID) ON DELETE CASCADE,
        EmpleadoID        INT            NOT NULL
            CONSTRAINT FK_RecetaEmpleado_Empleado
                REFERENCES Rrhh.Empleados(EmpleadoID),
        HorasEstimadasPorLote DECIMAL(18,4) NULL,
        Notas             NVARCHAR(500)  NULL,
        CONSTRAINT UQ_RecetaEmpleado UNIQUE (RecetaID, EmpleadoID)
    );
    PRINT 'Tabla Produccion.RecetaEmpleado creada.';
END
ELSE
    PRINT 'RecetaEmpleado ya existe.';
GO

-- ── 3. OrdenEmpleado ──────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'OrdenEmpleado' AND schema_id = SCHEMA_ID('Produccion'))
BEGIN
    CREATE TABLE Produccion.OrdenEmpleado (
        OrdenEmpleadoID   INT            NOT NULL IDENTITY(1,1) PRIMARY KEY,
        OrdenProduccionID INT            NOT NULL
            CONSTRAINT FK_OrdenEmpleado_Orden
                REFERENCES Produccion.OrdenesProduccion(OrdenProduccionID) ON DELETE CASCADE,
        EmpleadoID        INT            NOT NULL
            CONSTRAINT FK_OrdenEmpleado_Empleado
                REFERENCES Rrhh.Empleados(EmpleadoID),
        HorasReales       DECIMAL(18,4)  NULL,
        Notas             NVARCHAR(500)  NULL,
        CONSTRAINT UQ_OrdenEmpleado UNIQUE (OrdenProduccionID, EmpleadoID)
    );
    PRINT 'Tabla Produccion.OrdenEmpleado creada.';
END
ELSE
    PRINT 'OrdenEmpleado ya existe.';
GO

PRINT 'migration_empleados_produccion_v1.sql completada.';
GO
