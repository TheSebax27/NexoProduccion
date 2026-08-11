-- RRHH Asistencia: tablas para control de asistencia con QR rotativo
-- Ejecutar con: sqlcmd -S "DESKTOP-V83PQ7M\JONATHAN" -d NEXO_ERP -i create_rrhh_asistencia.sql

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='QrAsistenciaConfig' AND schema_id=SCHEMA_ID('Rrhh'))
BEGIN
    CREATE TABLE Rrhh.QrAsistenciaConfig (
        ConfigID  INT IDENTITY(1,1) PRIMARY KEY,
        Secreto   NVARCHAR(64) NOT NULL DEFAULT CONVERT(NVARCHAR(64), NEWID())
    );
    INSERT INTO Rrhh.QrAsistenciaConfig DEFAULT VALUES;
    PRINT 'Rrhh.QrAsistenciaConfig creada.';
END;

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='Horarios' AND schema_id=SCHEMA_ID('Rrhh'))
BEGIN
    CREATE TABLE Rrhh.Horarios (
        HorarioID            INT IDENTITY(1,1) PRIMARY KEY,
        Nombre               NVARCHAR(100) NOT NULL,
        HoraEntrada          TIME NOT NULL,
        HoraSalida           TIME NOT NULL,
        ToleranciaTardanzaMin INT NOT NULL DEFAULT 5,
        LunesActivo          BIT NOT NULL DEFAULT 1,
        MartesActivo         BIT NOT NULL DEFAULT 1,
        MiercolesActivo      BIT NOT NULL DEFAULT 1,
        JuevesActivo         BIT NOT NULL DEFAULT 1,
        ViernesActivo        BIT NOT NULL DEFAULT 1,
        SabadoActivo         BIT NOT NULL DEFAULT 0,
        DomingoActivo        BIT NOT NULL DEFAULT 0,
        Activo               BIT NOT NULL DEFAULT 1
    );
    PRINT 'Rrhh.Horarios creada.';
END;

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='EmpleadoHorario' AND schema_id=SCHEMA_ID('Rrhh'))
BEGIN
    CREATE TABLE Rrhh.EmpleadoHorario (
        EmpleadoID INT NOT NULL,
        HorarioID  INT NOT NULL,
        Desde      DATE NOT NULL,
        Hasta      DATE NULL,
        CONSTRAINT PK_EmpleadoHorario PRIMARY KEY (EmpleadoID, Desde),
        CONSTRAINT FK_EmpHorario_Emp FOREIGN KEY (EmpleadoID) REFERENCES Rrhh.Empleados(EmpleadoID),
        CONSTRAINT FK_EmpHorario_Hor FOREIGN KEY (HorarioID)  REFERENCES Rrhh.Horarios(HorarioID)
    );
    PRINT 'Rrhh.EmpleadoHorario creada.';
END;

-- Inmutable: HoraEntrada/HoraSalida nunca se actualizan una vez SET.
-- La inmutabilidad se refuerza en la capa de aplicacion (no existe endpoint PUT).
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name='RegistroAsistencia' AND schema_id=SCHEMA_ID('Rrhh'))
BEGIN
    CREATE TABLE Rrhh.RegistroAsistencia (
        RegistroID           INT IDENTITY(1,1) PRIMARY KEY,
        EmpleadoID           INT NOT NULL,
        Fecha                DATE NOT NULL,
        HoraEntrada          DATETIME2 NULL,
        MetodoEntrada        NVARCHAR(10) NULL,
        EntradaRegistradaPor INT NULL,          -- UsuarioID si MANUAL, NULL si QR
        EntradaNota          NVARCHAR(500) NULL,
        HoraSalida           DATETIME2 NULL,
        MetodoSalida         NVARCHAR(10) NULL,
        SalidaRegistradaPor  INT NULL,
        SalidaNota           NVARCHAR(500) NULL,
        MinutosTardanza      INT NULL,
        CONSTRAINT UQ_Asistencia    UNIQUE (EmpleadoID, Fecha),
        CONSTRAINT FK_Asist_Emp     FOREIGN KEY (EmpleadoID) REFERENCES Rrhh.Empleados(EmpleadoID),
        CONSTRAINT CK_MetodoEntrada CHECK (MetodoEntrada IN ('QR','MANUAL') OR MetodoEntrada IS NULL),
        CONSTRAINT CK_MetodoSalida  CHECK (MetodoSalida  IN ('QR','MANUAL') OR MetodoSalida  IS NULL)
    );
    PRINT 'Rrhh.RegistroAsistencia creada.';
END;
