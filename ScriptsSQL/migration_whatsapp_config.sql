-- Migración: tabla ConfiguracionWhatsApp (singleton, igual que ConfiguracionEmail)
-- Ejecutar UNA sola vez en NEXO_ERP

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'Organizacion' AND TABLE_NAME = 'ConfiguracionWhatsApp'
)
BEGIN
    CREATE TABLE Organizacion.ConfiguracionWhatsApp (
        ConfiguracionID  INT            NOT NULL DEFAULT 1,
        AccountSid       NVARCHAR(100)  NULL,
        AuthToken        NVARCHAR(200)  NULL,
        FromNumber       NVARCHAR(50)   NOT NULL DEFAULT N'whatsapp:+14155238886',
        Activo           BIT            NOT NULL DEFAULT 0,
        FechaModificacion DATETIME2(7)  NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_ConfiguracionWhatsApp PRIMARY KEY (ConfiguracionID),
        CONSTRAINT CK_ConfigWhatsApp_Singleton CHECK (ConfiguracionID = 1)
    );

    INSERT INTO Organizacion.ConfiguracionWhatsApp
        (ConfiguracionID, AccountSid, AuthToken, FromNumber, Activo)
    VALUES
        (1, NULL, NULL, N'whatsapp:+14155238886', 0);

    PRINT 'Tabla Organizacion.ConfiguracionWhatsApp creada e inicializada.';
END
ELSE
    PRINT 'Tabla ya existe, sin cambios.';
