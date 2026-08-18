-- ==========================================================================
-- seed_empleados_pasteleria_v1.sql
-- Inserta empleados realistas para una pasteleria/panaderia artesanal
-- SIN borrar datos existentes. Usa IF NOT EXISTS para ser idempotente.
-- Requiere: migration_empleados_produccion_v1.sql ya ejecutado
--           seed_panaderia_v1.sql ya ejecutado (para RecetaBOM IDs)
-- ==========================================================================

USE NEXO_ERP;
GO

-- ── 1. Departamentos ──────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM Rrhh.Departamentos WHERE Nombre = 'Produccion Pasteleria')
    INSERT INTO Rrhh.Departamentos (Nombre) VALUES ('Produccion Pasteleria');

IF NOT EXISTS (SELECT 1 FROM Rrhh.Departamentos WHERE Nombre = 'Administracion')
    INSERT INTO Rrhh.Departamentos (Nombre) VALUES ('Administracion');

IF NOT EXISTS (SELECT 1 FROM Rrhh.Departamentos WHERE Nombre = 'Ventas y Despacho')
    INSERT INTO Rrhh.Departamentos (Nombre) VALUES ('Ventas y Despacho');
GO

DECLARE @DepProd  INT = (SELECT DepartamentoID FROM Rrhh.Departamentos WHERE Nombre = 'Produccion Pasteleria');
DECLARE @DepAdmin INT = (SELECT DepartamentoID FROM Rrhh.Departamentos WHERE Nombre = 'Administracion');
DECLARE @DepVenta INT = (SELECT DepartamentoID FROM Rrhh.Departamentos WHERE Nombre = 'Ventas y Despacho');

-- ── 2. Cargos ─────────────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM Rrhh.Cargos WHERE Nombre = 'Maestro Pastelero')
    INSERT INTO Rrhh.Cargos (Nombre, DepartamentoID) VALUES ('Maestro Pastelero', @DepProd);

IF NOT EXISTS (SELECT 1 FROM Rrhh.Cargos WHERE Nombre = 'Oficial Pastelero')
    INSERT INTO Rrhh.Cargos (Nombre, DepartamentoID) VALUES ('Oficial Pastelero', @DepProd);

IF NOT EXISTS (SELECT 1 FROM Rrhh.Cargos WHERE Nombre = 'Ayudante de Produccion')
    INSERT INTO Rrhh.Cargos (Nombre, DepartamentoID) VALUES ('Ayudante de Produccion', @DepProd);

IF NOT EXISTS (SELECT 1 FROM Rrhh.Cargos WHERE Nombre = 'Decorador de Tortas')
    INSERT INTO Rrhh.Cargos (Nombre, DepartamentoID) VALUES ('Decorador de Tortas', @DepProd);

IF NOT EXISTS (SELECT 1 FROM Rrhh.Cargos WHERE Nombre = 'Jefe de Produccion')
    INSERT INTO Rrhh.Cargos (Nombre, DepartamentoID) VALUES ('Jefe de Produccion', @DepProd);

IF NOT EXISTS (SELECT 1 FROM Rrhh.Cargos WHERE Nombre = 'Administrador General')
    INSERT INTO Rrhh.Cargos (Nombre, DepartamentoID) VALUES ('Administrador General', @DepAdmin);

IF NOT EXISTS (SELECT 1 FROM Rrhh.Cargos WHERE Nombre = 'Asesor de Ventas')
    INSERT INTO Rrhh.Cargos (Nombre, DepartamentoID) VALUES ('Asesor de Ventas', @DepVenta);

IF NOT EXISTS (SELECT 1 FROM Rrhh.Cargos WHERE Nombre = 'Repartidor')
    INSERT INTO Rrhh.Cargos (Nombre, DepartamentoID) VALUES ('Repartidor', @DepVenta);
GO

-- ── 3. Empleados ──────────────────────────────────────────────────────────
-- (se guarda primer centro de costo disponible como referencia)
DECLARE @CC INT = (SELECT TOP 1 CentroCostoID FROM Organizacion.CentrosCosto ORDER BY CentroCostoID);

DECLARE @JefeProdCargo  INT = (SELECT CargoID FROM Rrhh.Cargos WHERE Nombre = 'Jefe de Produccion');
DECLARE @MaestroCargo   INT = (SELECT CargoID FROM Rrhh.Cargos WHERE Nombre = 'Maestro Pastelero');
DECLARE @OficialCargo   INT = (SELECT CargoID FROM Rrhh.Cargos WHERE Nombre = 'Oficial Pastelero');
DECLARE @AyudanteCargo  INT = (SELECT CargoID FROM Rrhh.Cargos WHERE Nombre = 'Ayudante de Produccion');
DECLARE @DecorCargo     INT = (SELECT CargoID FROM Rrhh.Cargos WHERE Nombre = 'Decorador de Tortas');
DECLARE @AdminCargo     INT = (SELECT CargoID FROM Rrhh.Cargos WHERE Nombre = 'Administrador General');
DECLARE @VentaCargo     INT = (SELECT CargoID FROM Rrhh.Cargos WHERE Nombre = 'Asesor de Ventas');
DECLARE @RepartCargo    INT = (SELECT CargoID FROM Rrhh.Cargos WHERE Nombre = 'Repartidor');

-- Jefe de produccion
IF NOT EXISTS (SELECT 1 FROM Rrhh.Empleados WHERE Nombres='Carmen' AND Apellidos='Valbuena')
    INSERT INTO Rrhh.Empleados (Nombres, Apellidos, CargoID, CentroCostoID, FechaIngreso, Telefono, Email, TarifaHora, Estado)
    VALUES ('Carmen','Valbuena', @JefeProdCargo, @CC, '2021-03-01', '300-111-2222', 'c.valbuena@panaderia.com', 35000, 1);

-- Maestros pasteleros
IF NOT EXISTS (SELECT 1 FROM Rrhh.Empleados WHERE Nombres='Luis Eduardo' AND Apellidos='Herrera')
    INSERT INTO Rrhh.Empleados (Nombres, Apellidos, CargoID, CentroCostoID, FechaIngreso, Telefono, Email, TarifaHora, Estado)
    VALUES ('Luis Eduardo','Herrera', @MaestroCargo, @CC, '2022-01-10', '301-222-3333', 'l.herrera@panaderia.com', 28000, 1);

IF NOT EXISTS (SELECT 1 FROM Rrhh.Empleados WHERE Nombres='Maria Fernanda' AND Apellidos='Ospina')
    INSERT INTO Rrhh.Empleados (Nombres, Apellidos, CargoID, CentroCostoID, FechaIngreso, Telefono, Email, TarifaHora, Estado)
    VALUES ('Maria Fernanda','Ospina', @MaestroCargo, @CC, '2021-07-15', '302-333-4444', 'm.ospina@panaderia.com', 27500, 1);

-- Oficiales
IF NOT EXISTS (SELECT 1 FROM Rrhh.Empleados WHERE Nombres='Jorge Andres' AND Apellidos='Cano')
    INSERT INTO Rrhh.Empleados (Nombres, Apellidos, CargoID, CentroCostoID, FechaIngreso, Telefono, Email, TarifaHora, Estado)
    VALUES ('Jorge Andres','Cano', @OficialCargo, @CC, '2023-02-20', '303-444-5555', 'j.cano@panaderia.com', 20000, 1);

IF NOT EXISTS (SELECT 1 FROM Rrhh.Empleados WHERE Nombres='Valentina' AND Apellidos='Rios Gutierrez')
    INSERT INTO Rrhh.Empleados (Nombres, Apellidos, CargoID, CentroCostoID, FechaIngreso, Telefono, Email, TarifaHora, Estado)
    VALUES ('Valentina','Rios Gutierrez', @OficialCargo, @CC, '2023-05-01', '304-555-6666', 'v.rios@panaderia.com', 19500, 1);

-- Ayudantes
IF NOT EXISTS (SELECT 1 FROM Rrhh.Empleados WHERE Nombres='Andres Felipe' AND Apellidos='Moreno')
    INSERT INTO Rrhh.Empleados (Nombres, Apellidos, CargoID, CentroCostoID, FechaIngreso, Telefono, Email, TarifaHora, Estado)
    VALUES ('Andres Felipe','Moreno', @AyudanteCargo, @CC, '2024-01-08', '305-666-7777', 'a.moreno@panaderia.com', 14000, 1);

IF NOT EXISTS (SELECT 1 FROM Rrhh.Empleados WHERE Nombres='Daniela' AND Apellidos='Suarez Peña')
    INSERT INTO Rrhh.Empleados (Nombres, Apellidos, CargoID, CentroCostoID, FechaIngreso, Telefono, Email, TarifaHora, Estado)
    VALUES ('Daniela','Suarez Peña', @AyudanteCargo, @CC, '2024-03-15', '306-777-8888', 'd.suarez@panaderia.com', 13500, 1);

-- Decorador
IF NOT EXISTS (SELECT 1 FROM Rrhh.Empleados WHERE Nombres='Sofia' AND Apellidos='Cardenas Leal')
    INSERT INTO Rrhh.Empleados (Nombres, Apellidos, CargoID, CentroCostoID, FechaIngreso, Telefono, Email, TarifaHora, Estado)
    VALUES ('Sofia','Cardenas Leal', @DecorCargo, @CC, '2022-09-01', '307-888-9999', 's.cardenas@panaderia.com', 22000, 1);

-- Admin y ventas
IF NOT EXISTS (SELECT 1 FROM Rrhh.Empleados WHERE Nombres='Roberto' AND Apellidos='Mendez Arenas')
    INSERT INTO Rrhh.Empleados (Nombres, Apellidos, CargoID, CentroCostoID, FechaIngreso, Telefono, Email, TarifaHora, Estado)
    VALUES ('Roberto','Mendez Arenas', @AdminCargo, @CC, '2020-11-01', '308-999-0000', 'r.mendez@panaderia.com', 40000, 1);

IF NOT EXISTS (SELECT 1 FROM Rrhh.Empleados WHERE Nombres='Paola Andrea' AND Apellidos='Castillo')
    INSERT INTO Rrhh.Empleados (Nombres, Apellidos, CargoID, CentroCostoID, FechaIngreso, Telefono, Email, TarifaHora, Estado)
    VALUES ('Paola Andrea','Castillo', @VentaCargo, @CC, '2023-08-10', '309-000-1111', 'p.castillo@panaderia.com', 16000, 1);

IF NOT EXISTS (SELECT 1 FROM Rrhh.Empleados WHERE Nombres='Miguel Angel' AND Apellidos='Torres')
    INSERT INTO Rrhh.Empleados (Nombres, Apellidos, CargoID, CentroCostoID, FechaIngreso, Telefono, Email, TarifaHora, Estado)
    VALUES ('Miguel Angel','Torres', @RepartCargo, @CC, '2024-02-01', '310-111-2222', 'm.torres@panaderia.com', 12000, 1);
GO

-- ── 4. Jerarquia: Carmen es jefa de los de produccion ─────────────────────
DECLARE @CarmenID       INT = (SELECT EmpleadoID FROM Rrhh.Empleados WHERE Nombres='Carmen'         AND Apellidos='Valbuena');
DECLARE @LuisID         INT = (SELECT EmpleadoID FROM Rrhh.Empleados WHERE Nombres='Luis Eduardo'   AND Apellidos='Herrera');
DECLARE @MariaID        INT = (SELECT EmpleadoID FROM Rrhh.Empleados WHERE Nombres='Maria Fernanda' AND Apellidos='Ospina');
DECLARE @JorgeID        INT = (SELECT EmpleadoID FROM Rrhh.Empleados WHERE Nombres='Jorge Andres'   AND Apellidos='Cano');
DECLARE @ValentinaID    INT = (SELECT EmpleadoID FROM Rrhh.Empleados WHERE Nombres='Valentina'      AND Apellidos='Rios Gutierrez');
DECLARE @AndresFID      INT = (SELECT EmpleadoID FROM Rrhh.Empleados WHERE Nombres='Andres Felipe'  AND Apellidos='Moreno');
DECLARE @DanielaID      INT = (SELECT EmpleadoID FROM Rrhh.Empleados WHERE Nombres='Daniela'        AND Apellidos='Suarez Peña');
DECLARE @SofiaID        INT = (SELECT EmpleadoID FROM Rrhh.Empleados WHERE Nombres='Sofia'          AND Apellidos='Cardenas Leal');

UPDATE Rrhh.Empleados SET JefeDirectoID = @CarmenID
WHERE Nombres IN ('Luis Eduardo','Maria Fernanda','Jorge Andres','Valentina','Andres Felipe','Daniela','Sofia')
  AND JefeDirectoID IS NULL;

-- Luis y Maria son jefes de los ayudantes y oficiales a su cargo
UPDATE Rrhh.Empleados SET JefeDirectoID = @LuisID
WHERE EmpleadoID IN (@JorgeID, @AndresFID) AND JefeDirectoID = @CarmenID;

UPDATE Rrhh.Empleados SET JefeDirectoID = @MariaID
WHERE EmpleadoID IN (@ValentinaID, @DanielaID) AND JefeDirectoID = @CarmenID;
GO

-- ── 5. Empleados en Recetas (RecetaEmpleado) ──────────────────────────────
-- Asigna empleados a las 3 recetas del seed_panaderia_v1
DECLARE @LuisID2   INT = (SELECT EmpleadoID FROM Rrhh.Empleados WHERE Nombres='Luis Eduardo'  AND Apellidos='Herrera');
DECLARE @MariaID2  INT = (SELECT EmpleadoID FROM Rrhh.Empleados WHERE Nombres='Maria Fernanda' AND Apellidos='Ospina');
DECLARE @JorgeID2  INT = (SELECT EmpleadoID FROM Rrhh.Empleados WHERE Nombres='Jorge Andres'  AND Apellidos='Cano');
DECLARE @ValID2    INT = (SELECT EmpleadoID FROM Rrhh.Empleados WHERE Nombres='Valentina'     AND Apellidos='Rios Gutierrez');
DECLARE @AndresID2 INT = (SELECT EmpleadoID FROM Rrhh.Empleados WHERE Nombres='Andres Felipe' AND Apellidos='Moreno');
DECLARE @DanID2    INT = (SELECT EmpleadoID FROM Rrhh.Empleados WHERE Nombres='Daniela'       AND Apellidos='Suarez Peña');

-- BOM Pan de Molde Blanco → Luis (maestro 2h/lote), Andres (ayudante 1.5h/lote)
DECLARE @RecetaBlanco INT = (SELECT RecetaID FROM Produccion.RecetaBOM WHERE NombreReceta LIKE '%Blanco%');
IF @RecetaBlanco IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Produccion.RecetaEmpleado WHERE RecetaID=@RecetaBlanco AND EmpleadoID=@LuisID2)
        INSERT INTO Produccion.RecetaEmpleado (RecetaID, EmpleadoID, HorasEstimadasPorLote, Notas)
        VALUES (@RecetaBlanco, @LuisID2, 2.0, 'Responsable del amasado y horneado');

    IF @AndresID2 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Produccion.RecetaEmpleado WHERE RecetaID=@RecetaBlanco AND EmpleadoID=@AndresID2)
        INSERT INTO Produccion.RecetaEmpleado (RecetaID, EmpleadoID, HorasEstimadasPorLote, Notas)
        VALUES (@RecetaBlanco, @AndresID2, 1.5, 'Apoyo en pesaje y empaque');
END

-- BOM Pan Integral → Maria (maestra 2.5h/lote), Valentina (oficial 1.5h/lote)
DECLARE @RecetaIntegral INT = (SELECT RecetaID FROM Produccion.RecetaBOM WHERE NombreReceta LIKE '%Integral%');
IF @RecetaIntegral IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Produccion.RecetaEmpleado WHERE RecetaID=@RecetaIntegral AND EmpleadoID=@MariaID2)
        INSERT INTO Produccion.RecetaEmpleado (RecetaID, EmpleadoID, HorasEstimadasPorLote, Notas)
        VALUES (@RecetaIntegral, @MariaID2, 2.5, 'Maestra de la linea de pan integral');

    IF @ValID2 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Produccion.RecetaEmpleado WHERE RecetaID=@RecetaIntegral AND EmpleadoID=@ValID2)
        INSERT INTO Produccion.RecetaEmpleado (RecetaID, EmpleadoID, HorasEstimadasPorLote, Notas)
        VALUES (@RecetaIntegral, @ValID2, 1.5, 'Apoyo en formado y corte');
END

-- BOM Galleta Vainilla → Jorge (oficial 1h/lote), Daniela (ayudante 1h/lote)
DECLARE @RecetaGalleta INT = (SELECT RecetaID FROM Produccion.RecetaBOM WHERE NombreReceta LIKE '%Galleta%');
IF @RecetaGalleta IS NOT NULL
BEGIN
    IF @JorgeID2 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Produccion.RecetaEmpleado WHERE RecetaID=@RecetaGalleta AND EmpleadoID=@JorgeID2)
        INSERT INTO Produccion.RecetaEmpleado (RecetaID, EmpleadoID, HorasEstimadasPorLote, Notas)
        VALUES (@RecetaGalleta, @JorgeID2, 1.0, 'Responsable del mezclado y cortado');

    IF @DanID2 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Produccion.RecetaEmpleado WHERE RecetaID=@RecetaGalleta AND EmpleadoID=@DanID2)
        INSERT INTO Produccion.RecetaEmpleado (RecetaID, EmpleadoID, HorasEstimadasPorLote, Notas)
        VALUES (@RecetaGalleta, @DanID2, 1.0, 'Empaque y control de calidad');
END
GO

-- ── 6. Empleados en Ordenes (OrdenEmpleado) ───────────────────────────────
-- Asigna empleados a las OPs del seed, con horas reales (simulando que ya trabajaron)
DECLARE @LuisOP   INT = (SELECT EmpleadoID FROM Rrhh.Empleados WHERE Nombres='Luis Eduardo'  AND Apellidos='Herrera');
DECLARE @MariaOP  INT = (SELECT EmpleadoID FROM Rrhh.Empleados WHERE Nombres='Maria Fernanda' AND Apellidos='Ospina');
DECLARE @JorgeOP  INT = (SELECT EmpleadoID FROM Rrhh.Empleados WHERE Nombres='Jorge Andres'  AND Apellidos='Cano');
DECLARE @AndresOP INT = (SELECT EmpleadoID FROM Rrhh.Empleados WHERE Nombres='Andres Felipe' AND Apellidos='Moreno');
DECLARE @DanOP    INT = (SELECT EmpleadoID FROM Rrhh.Empleados WHERE Nombres='Daniela'       AND Apellidos='Suarez Peña');
DECLARE @ValOP    INT = (SELECT EmpleadoID FROM Rrhh.Empleados WHERE Nombres='Valentina'     AND Apellidos='Rios Gutierrez');

-- OP-2026-001 (Pan Blanco, 100 unidades → ~5 lotes × 2h = 10h Luis, 7.5h Andres)
DECLARE @OP001 INT = (SELECT OrdenProduccionID FROM Produccion.OrdenesProduccion WHERE CodigoOP='OP-2026-001');
IF @OP001 IS NOT NULL
BEGIN
    IF @LuisOP IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Produccion.OrdenEmpleado WHERE OrdenProduccionID=@OP001 AND EmpleadoID=@LuisOP)
        INSERT INTO Produccion.OrdenEmpleado (OrdenProduccionID, EmpleadoID, HorasReales, Notas)
        VALUES (@OP001, @LuisOP, 10.0, 'Amasado y horneado completo');

    IF @AndresOP IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Produccion.OrdenEmpleado WHERE OrdenProduccionID=@OP001 AND EmpleadoID=@AndresOP)
        INSERT INTO Produccion.OrdenEmpleado (OrdenProduccionID, EmpleadoID, HorasReales, Notas)
        VALUES (@OP001, @AndresOP, 7.5, 'Pesaje insumos y empaque final');
END

-- OP-2026-002 (Pan Integral, 80 unidades → ~5h Maria, 3.5h Valentina)
DECLARE @OP002 INT = (SELECT OrdenProduccionID FROM Produccion.OrdenesProduccion WHERE CodigoOP='OP-2026-002');
IF @OP002 IS NOT NULL
BEGIN
    IF @MariaOP IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Produccion.OrdenEmpleado WHERE OrdenProduccionID=@OP002 AND EmpleadoID=@MariaOP)
        INSERT INTO Produccion.OrdenEmpleado (OrdenProduccionID, EmpleadoID, HorasReales, Notas)
        VALUES (@OP002, @MariaOP, 5.0, 'Produccion integral completa');

    IF @ValOP IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Produccion.OrdenEmpleado WHERE OrdenProduccionID=@OP002 AND EmpleadoID=@ValOP)
        INSERT INTO Produccion.OrdenEmpleado (OrdenProduccionID, EmpleadoID, HorasReales, Notas)
        VALUES (@OP002, @ValOP, 3.5, 'Formado y empaque');
END

-- OP-2026-003 (Galleta Vainilla, 360 unidades → ~3h Jorge, 3h Daniela)
DECLARE @OP003 INT = (SELECT OrdenProduccionID FROM Produccion.OrdenesProduccion WHERE CodigoOP='OP-2026-003');
IF @OP003 IS NOT NULL
BEGIN
    IF @JorgeOP IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Produccion.OrdenEmpleado WHERE OrdenProduccionID=@OP003 AND EmpleadoID=@JorgeOP)
        INSERT INTO Produccion.OrdenEmpleado (OrdenProduccionID, EmpleadoID, HorasReales, Notas)
        VALUES (@OP003, @JorgeOP, 3.0, 'Mezcla, corte y horneado galletas');

    IF @DanOP IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Produccion.OrdenEmpleado WHERE OrdenProduccionID=@OP003 AND EmpleadoID=@DanOP)
        INSERT INTO Produccion.OrdenEmpleado (OrdenProduccionID, EmpleadoID, HorasReales, Notas)
        VALUES (@OP003, @DanOP, 3.0, 'Empaque en cajas de 12 unidades');
END
GO

PRINT 'seed_empleados_pasteleria_v1.sql completado: 11 empleados, jerarquia, RecetaEmpleado y OrdenEmpleado insertados.';
GO
