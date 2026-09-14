-- Migración: reemplazar códigos de texto por códigos DIAN numéricos en TiposIdentificacion
-- Ejecutar en las 3 BDs de producción (45.171.180.182\VISIONS, login sas)
-- Idempotente: si ya existen los códigos numéricos solo actualiza Detalle

-- 1. Actualizar Clientes.TipoIdentificacion si tiene códigos de texto
UPDATE Crm.Clientes SET TipoIdentificacion = '13' WHERE TipoIdentificacion = 'CC';
UPDATE Crm.Clientes SET TipoIdentificacion = '31' WHERE TipoIdentificacion = 'NIT' OR TipoIdentificacion = 'RUT';
UPDATE Crm.Clientes SET TipoIdentificacion = '22' WHERE TipoIdentificacion = 'CE';
UPDATE Crm.Clientes SET TipoIdentificacion = '41' WHERE TipoIdentificacion = 'PA';
UPDATE Crm.Clientes SET TipoIdentificacion = '12' WHERE TipoIdentificacion = 'TI';
GO

-- 2. Actualizar Proveedores si existe y tiene códigos de texto
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Catalogo.Proveedores') AND name = 'TipoIdentificacion')
BEGIN
    UPDATE Catalogo.Proveedores SET TipoIdentificacion = '13' WHERE TipoIdentificacion = 'CC';
    UPDATE Catalogo.Proveedores SET TipoIdentificacion = '31' WHERE TipoIdentificacion = 'NIT' OR TipoIdentificacion = 'RUT';
    UPDATE Catalogo.Proveedores SET TipoIdentificacion = '22' WHERE TipoIdentificacion = 'CE';
    UPDATE Catalogo.Proveedores SET TipoIdentificacion = '41' WHERE TipoIdentificacion = 'PA';
    UPDATE Catalogo.Proveedores SET TipoIdentificacion = '12' WHERE TipoIdentificacion = 'TI';
END
GO

-- 3. Actualizar Crm.Leads si tiene columna TipoIdentificacion con códigos de texto
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Crm.Leads') AND name = 'TipoIdentificacion')
BEGIN
    UPDATE Crm.Leads SET TipoIdentificacion = '13' WHERE TipoIdentificacion = 'CC';
    UPDATE Crm.Leads SET TipoIdentificacion = '31' WHERE TipoIdentificacion = 'NIT' OR TipoIdentificacion = 'RUT';
    UPDATE Crm.Leads SET TipoIdentificacion = '22' WHERE TipoIdentificacion = 'CE';
    UPDATE Crm.Leads SET TipoIdentificacion = '41' WHERE TipoIdentificacion = 'PA';
    UPDATE Crm.Leads SET TipoIdentificacion = '12' WHERE TipoIdentificacion = 'TI';
END
GO

-- 4. Limpiar tabla TiposIdentificacion y cargar DIAN numéricos
DELETE FROM Catalogo.TiposIdentificacion;
GO

INSERT INTO Catalogo.TiposIdentificacion (Codigo, Detalle) VALUES
    ('11', 'Registro Civil'),
    ('12', 'Tarjeta de Identidad'),
    ('13', 'Cedula de Ciudadania'),
    ('21', 'Tarjeta de Extranjeria'),
    ('22', 'Cedula de Extranjeria'),
    ('31', 'NIT'),
    ('41', 'Pasaporte'),
    ('42', 'Documento de Identificacion Extranjero'),
    ('43', 'Sin identificacion del exterior'),
    ('44', 'PEP - Permiso Especial de Permanencia'),
    ('91', 'NUIP');
GO

-- 5. Si Detalle ya era NULL para los numéricos que ya existían, actualizar solo Detalle
-- (no duplica si el DELETE del paso 4 ya los limpió)
-- Este bloque es redundante pero inocuo si se ejecuta todo junto.

SELECT Codigo, Detalle FROM Catalogo.TiposIdentificacion ORDER BY COALESCE(Detalle, Codigo);
GO
