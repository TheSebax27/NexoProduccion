-- =============================================================================
-- SCRIPT: pruebas_verificacion_nexo_a_visions.sql
-- Base   : NEXO_ERP en .\JONATHAN
-- Objeto : Verificacion integral del sistema NEXO:
--          articulos, clientes, proveedores, stock, receta BOM, orden de
--          produccion completa (Planificada->Liberada->En Proceso->Finalizada),
--          ajuste y baja directos, y generacion de eventos para Visions.
-- Uso    : Ejecutar en SSMS contra NEXO_ERP. Cada bloque imprime su resultado.
-- Nota   : Los SPs de produccion manejan sus propias transacciones.
--          El resto de los INSERTs van en una transaccion unica que se confirma
--          ANTES de llamar los SPs para evitar conflictos de XACT_ABORT.
-- =============================================================================
USE NEXO_ERP;
GO

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT '======================================================================';
PRINT 'NEXO ERP - VERIFICACION INTEGRAL';
PRINT 'Fecha: ' + CONVERT(NVARCHAR(30), GETDATE(), 120);
PRINT '======================================================================';
GO

-- =============================================================================
-- VARIABLES: se declaran aqui para persistir durante todo el batch
-- =============================================================================
DECLARE
    -- IDs articulos
    @IdHarina      INT,
    @IdAzucar      INT,
    @IdMargarina   INT,
    @IdPanTajado   INT,

    -- IDs clientes
    @IdCliente1    INT,
    @IdCliente2    INT,

    -- IDs proveedores
    @IdProv1       INT,
    @IdProv2       INT,

    -- IDs lotes
    @LoteHarina    INT,
    @LoteAzucar    INT,
    @LoteMargarina INT,

    -- IDs produccion
    @RecetaID      INT,
    @OpID          INT,

    -- tipos movimiento kardex
    @TipoCompra    INT,
    @TipoBaja      INT;

-- Tipos de movimiento (referenciar desde la tabla, no hardcodear)
SET @TipoCompra = (SELECT TipoMovID FROM Kardex.TiposMovimientoKardex WHERE Codigo = 'ENTRADA_COMPRA');
SET @TipoBaja   = (SELECT TipoMovID FROM Kardex.TiposMovimientoKardex WHERE Codigo = 'BAJA_MERMA');

-- =============================================================================
-- BLOQUE 1 - ARTICULOS NUEVOS
-- 3 materias primas (Harina, Azucar, Margarina) + 1 producto terminado (Pan)
-- TipoArticuloID: 1=MP, 2=PT, 3=INS, 4=SER
-- PresentacionCodigo: KG=Kilogramo, UND=Unidad, GR=Gramo
-- MarcaCodigo: HVALL=Harinera del Valle, INCAU=Incauca, DANLE=Dan Leb
-- GrupoMenorCodigo: TRIG, AZUC, MARG, PAND
-- =============================================================================
PRINT '';
PRINT '--- BLOQUE 1: Articulos nuevos ---';

BEGIN TRANSACTION;
BEGIN TRY

    -- MP-01: Harina de Trigo (materia prima)
    IF NOT EXISTS (SELECT 1 FROM Catalogo.Tarjetas WHERE Referencia = 'MP-HARINA-T01')
    BEGIN
        INSERT INTO Catalogo.Tarjetas
            (Referencia, Nombre, Descripcion, TipoArticuloID,
             CostoPromedio, StockMinimo, PuntoReorden, Fracciona,
             PPublico, PBodega, PCredito,
             MarcaCodigo, GrupoMenorCodigo, PresentacionCodigo,
             IvaSiNo, IvaValor, IvaDescripcion, Estado)
        VALUES
            ('MP-HARINA-T01', 'Harina de Trigo Enriquecida - TEST', 'Harina de trigo tipo 0000 para panaderia industrial', 1,
             1850.0000, 50, 25, 'NO',
             0, 0, 0,
             'HVALL', 'TRIG', 'KG',
             'NO', 0, 'EXCLUIDO', 1);
        SET @IdHarina = SCOPE_IDENTITY();
        PRINT '  Articulo MP-HARINA-T01 creado. ID=' + CAST(@IdHarina AS NVARCHAR);
    END
    ELSE
    BEGIN
        SET @IdHarina = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'MP-HARINA-T01');
        PRINT '  MP-HARINA-T01 ya existe. ID=' + CAST(@IdHarina AS NVARCHAR);
    END

    -- MP-02: Azucar Blanca (materia prima)
    IF NOT EXISTS (SELECT 1 FROM Catalogo.Tarjetas WHERE Referencia = 'MP-AZUCAR-T01')
    BEGIN
        INSERT INTO Catalogo.Tarjetas
            (Referencia, Nombre, Descripcion, TipoArticuloID,
             CostoPromedio, StockMinimo, PuntoReorden, Fracciona,
             PPublico, PBodega, PCredito,
             MarcaCodigo, GrupoMenorCodigo, PresentacionCodigo,
             IvaSiNo, IvaValor, IvaDescripcion, Estado)
        VALUES
            ('MP-AZUCAR-T01', 'Azucar Blanca Refinada - TEST', 'Azucar de cana refinada grado alimenticio', 1,
             1600.0000, 30, 15, 'NO',
             0, 0, 0,
             'INCAU', 'AZUC', 'KG',
             'NO', 0, 'EXCLUIDO', 1);
        SET @IdAzucar = SCOPE_IDENTITY();
        PRINT '  Articulo MP-AZUCAR-T01 creado. ID=' + CAST(@IdAzucar AS NVARCHAR);
    END
    ELSE
    BEGIN
        SET @IdAzucar = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'MP-AZUCAR-T01');
        PRINT '  MP-AZUCAR-T01 ya existe. ID=' + CAST(@IdAzucar AS NVARCHAR);
    END

    -- MP-03: Margarina Industrial (materia prima)
    IF NOT EXISTS (SELECT 1 FROM Catalogo.Tarjetas WHERE Referencia = 'MP-MARG-T01')
    BEGIN
        INSERT INTO Catalogo.Tarjetas
            (Referencia, Nombre, Descripcion, TipoArticuloID,
             CostoPromedio, StockMinimo, PuntoReorden, Fracciona,
             PPublico, PBodega, PCredito,
             MarcaCodigo, GrupoMenorCodigo, PresentacionCodigo,
             IvaSiNo, IvaValor, IvaDescripcion, Estado)
        VALUES
            ('MP-MARG-T01', 'Margarina Industrial Bloque - TEST', 'Margarina vegetal hidrogenada en bloque x15kg', 1,
             4200.0000, 10, 5, 'NO',
             0, 0, 0,
             'DANLE', 'MARG', 'KG',
             'NO', 0, 'EXCLUIDO', 1);
        SET @IdMargarina = SCOPE_IDENTITY();
        PRINT '  Articulo MP-MARG-T01 creado. ID=' + CAST(@IdMargarina AS NVARCHAR);
    END
    ELSE
    BEGIN
        SET @IdMargarina = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'MP-MARG-T01');
        PRINT '  MP-MARG-T01 ya existe. ID=' + CAST(@IdMargarina AS NVARCHAR);
    END

    -- PT-01: Pan Tajado de Molde (producto terminado)
    IF NOT EXISTS (SELECT 1 FROM Catalogo.Tarjetas WHERE Referencia = 'PT-PAN-T01')
    BEGIN
        INSERT INTO Catalogo.Tarjetas
            (Referencia, Nombre, Descripcion, TipoArticuloID,
             CostoPromedio, StockMinimo, PuntoReorden, Fracciona,
             PPublico, PBodega, PCredito,
             MarcaCodigo, GrupoMenorCodigo, PresentacionCodigo,
             IvaSiNo, IvaValor, IvaDescripcion, Estado)
        VALUES
            ('PT-PAN-T01', 'Pan Tajado Molde 500g - TEST', 'Pan tajado en bolsa de 500g, 22 tajadas', 2,
             0.0000, 20, 10, 'NO',
             4500, 4000, 4200,
             'HVALL', 'PAND', 'UND',
             'NO', 0, 'EXCLUIDO', 1);
        SET @IdPanTajado = SCOPE_IDENTITY();
        PRINT '  Articulo PT-PAN-T01 creado. ID=' + CAST(@IdPanTajado AS NVARCHAR);
    END
    ELSE
    BEGIN
        SET @IdPanTajado = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia = 'PT-PAN-T01');
        PRINT '  PT-PAN-T01 ya existe. ID=' + CAST(@IdPanTajado AS NVARCHAR);
    END

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'ERROR BLOQUE 1: ' + ERROR_MESSAGE();
    RETURN;
END CATCH;

-- =============================================================================
-- BLOQUE 2 - CLIENTES NUEVOS
-- Un cliente persona natural y uno juridico, con todos los campos de sync
-- =============================================================================
PRINT '';
PRINT '--- BLOQUE 2: Clientes nuevos ---';

BEGIN TRANSACTION;
BEGIN TRY

    -- Cliente 1: Persona Natural
    IF NOT EXISTS (SELECT 1 FROM Crm.Clientes WHERE NIT = '52847392')
    BEGIN
        INSERT INTO Crm.Clientes
            (Nombre, NIT, Telefono, Email, Direccion, Estado, TipoCliente, FuenteContacto,
             TipoPersona, PrimerNombre, SegundoNombre, PrimerApellido, SegundoApellido,
             TipoIdentificacion, DigitoVerificacion, Departamento, Ciudad,
             CodigoDept, CodigoMuni, Pais, CodigoPais, FechaModificacion)
        VALUES
            ('Maria Elena Torres Rojas', '52847392', '3178456231', 'matorres@outlook.com',
             'Calle 45 # 12-67 Apt 301, Bogota', 1, 'DIRECTO', 'REFERIDO',
             'Natural', 'Maria Elena', NULL, 'Torres', 'Rojas',
             'CC', NULL, 'CUNDINAMARCA', 'BOGOTA D.C.',
             '25', '001', 'COLOMBIA', 'CO', GETDATE());
        SET @IdCliente1 = SCOPE_IDENTITY();
        PRINT '  Cliente Maria Elena Torres creado. ID=' + CAST(@IdCliente1 AS NVARCHAR);
    END
    ELSE
    BEGIN
        SET @IdCliente1 = (SELECT ClienteID FROM Crm.Clientes WHERE NIT = '52847392');
        PRINT '  Cliente NIT 52847392 ya existe. ID=' + CAST(@IdCliente1 AS NVARCHAR);
    END

    -- Cliente 2: Persona Juridica (empresa)
    IF NOT EXISTS (SELECT 1 FROM Crm.Clientes WHERE NIT = '900847321')
    BEGIN
        INSERT INTO Crm.Clientes
            (Nombre, NIT, Telefono, Email, Direccion, Estado, TipoCliente, FuenteContacto,
             TipoPersona, PrimerNombre, SegundoNombre, PrimerApellido, SegundoApellido,
             TipoIdentificacion, DigitoVerificacion, Departamento, Ciudad,
             CodigoDept, CodigoMuni, Pais, CodigoPais, FechaModificacion)
        VALUES
            ('Distribuidora Central del Oriente SAS', '900847321', '6086421234', 'compras@distcentral.com',
             'Carrera 18 # 24-15, Tunja', 1, 'MAYORISTA', 'COMERCIAL',
             'Juridica', NULL, NULL, NULL, NULL,
             'NIT', 8, 'BOYACA', 'TUNJA',
             '15', '001', 'COLOMBIA', 'CO', GETDATE());
        SET @IdCliente2 = SCOPE_IDENTITY();
        PRINT '  Cliente Distribuidora Central creado. ID=' + CAST(@IdCliente2 AS NVARCHAR);
    END
    ELSE
    BEGIN
        SET @IdCliente2 = (SELECT ClienteID FROM Crm.Clientes WHERE NIT = '900847321');
        PRINT '  Cliente NIT 900847321 ya existe. ID=' + CAST(@IdCliente2 AS NVARCHAR);
    END

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'ERROR BLOQUE 2: ' + ERROR_MESSAGE();
    RETURN;
END CATCH;

-- =============================================================================
-- BLOQUE 3 - PROVEEDORES NUEVOS
-- Un proveedor juridico (molino) y uno natural (distribuidor independiente)
-- =============================================================================
PRINT '';
PRINT '--- BLOQUE 3: Proveedores nuevos ---';

BEGIN TRANSACTION;
BEGIN TRY

    -- Proveedor 1: Persona Juridica
    IF NOT EXISTS (SELECT 1 FROM Catalogo.Proveedores WHERE NIT = '860012547')
    BEGIN
        INSERT INTO Catalogo.Proveedores
            (RazonSocial, NIT, Contacto, Telefono, Email, Direccion, Estado,
             TipoPersona, TipoIdentificacion, DigitoVerificacion,
             Departamento, Ciudad, CodigoDept, CodigoMuni, Pais, CodigoPais)
        VALUES
            ('Molinos del Pacifico SAS', '860012547', 'Dpto. Ventas', '6014251400', 'ventas@molinospacifico.com',
             'Zona Industrial Montevideo Bodega 12, Bogota', 1,
             'Juridica', '31', 7,
             'CUNDINAMARCA', 'BOGOTA D.C.', '25', '001', 'COLOMBIA', 'CO');
        SET @IdProv1 = SCOPE_IDENTITY();
        PRINT '  Proveedor Molinos del Pacifico creado. ID=' + CAST(@IdProv1 AS NVARCHAR);
    END
    ELSE
    BEGIN
        SET @IdProv1 = (SELECT ProveedorID FROM Catalogo.Proveedores WHERE NIT = '860012547');
        PRINT '  Proveedor NIT 860012547 ya existe. ID=' + CAST(@IdProv1 AS NVARCHAR);
    END

    -- Proveedor 2: Persona Natural
    IF NOT EXISTS (SELECT 1 FROM Catalogo.Proveedores WHERE NIT = '79345682')
    BEGIN
        INSERT INTO Catalogo.Proveedores
            (RazonSocial, NIT, Contacto, Telefono, Email, Direccion, Estado,
             TipoPersona, TipoIdentificacion, DigitoVerificacion,
             Departamento, Ciudad, CodigoDept, CodigoMuni, Pais, CodigoPais)
        VALUES
            ('Luis Ernesto Parra Molina', '79345682', 'Luis Parra', '3125478923', 'leparra@hotmail.com',
             'Cra 7 # 80-25 Apto 502, Bogota', 1,
             'Natural', '13', 3,
             'CUNDINAMARCA', 'BOGOTA D.C.', '25', '001', 'COLOMBIA', 'CO');
        SET @IdProv2 = SCOPE_IDENTITY();
        PRINT '  Proveedor Luis Parra creado. ID=' + CAST(@IdProv2 AS NVARCHAR);
    END
    ELSE
    BEGIN
        SET @IdProv2 = (SELECT ProveedorID FROM Catalogo.Proveedores WHERE NIT = '79345682');
        PRINT '  Proveedor NIT 79345682 ya existe. ID=' + CAST(@IdProv2 AS NVARCHAR);
    END

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'ERROR BLOQUE 3: ' + ERROR_MESSAGE();
    RETURN;
END CATCH;

-- =============================================================================
-- BLOQUE 4 - STOCK INICIAL DE MATERIAS PRIMAS
-- Crea lotes y agrega existencias en bodega 5 (Harinas y Secos, CC7)
-- y bodega 4 (Lacteos y Frios, CC7) para Margarina.
-- Tambien registra el Kardex de entrada por compra (trazabilidad completa).
-- BodegaID referencia:
--   3 = Bodega Materias Primas (CC7)
--   4 = Bodega Lacteos y Frios (CC7)
--   5 = Bodega Harinas y Secos (CC7)
--   9 = Bodega Producto Terminado (CC7)
-- CentroCostoID 7 = CC-BODEGA (Bodega y Logistica)
-- =============================================================================
PRINT '';
PRINT '--- BLOQUE 4: Stock inicial de materias primas ---';

BEGIN TRANSACTION;
BEGIN TRY

    -- Lote Harina
    IF NOT EXISTS (SELECT 1 FROM Inventario.Lotes WHERE NumeroLote = 'LOTE-HAR-2026-08-TEST' AND ArticuloID = @IdHarina)
    BEGIN
        INSERT INTO Inventario.Lotes (ArticuloID, NumeroLote, FechaFabricacion, FechaVencimiento, ProveedorID, Estado)
        VALUES (@IdHarina, 'LOTE-HAR-2026-08-TEST', '2026-08-10', '2027-02-10', @IdProv1, 'APROBADO');
        SET @LoteHarina = SCOPE_IDENTITY();

        INSERT INTO Inventario.InventarioStock (ArticuloID, BodegaID, LoteID, CantidadActual, CostoUnitarioLote)
        VALUES (@IdHarina, 5, @LoteHarina, 200.0000, 1850.0000);

        INSERT INTO Kardex.KardexMovimientos
            (ArticuloID, BodegaID, LoteID, TipoMovID, CentroCostoID,
             Cantidad, CostoUnitario, CantidadSaldo, CostoPromedioSaldo, ObservacionDetallada, UsuarioID)
        VALUES (@IdHarina, 5, @LoteHarina, @TipoCompra, 7,
                200.0000, 1850.0000, 200.0000, 1850.0000,
                'Compra inicial TEST - Molinos del Pacifico SAS, Factura F-001', 1);

        UPDATE Catalogo.Tarjetas SET CostoPromedio = 1850.0000 WHERE ArticuloID = @IdHarina;
        PRINT '  Stock Harina: 200 KG a $1.850 c/u en Bodega Harinas y Secos.';
    END
    ELSE
        PRINT '  Lote Harina ya existe.';

    -- Lote Azucar
    IF NOT EXISTS (SELECT 1 FROM Inventario.Lotes WHERE NumeroLote = 'LOTE-AZU-2026-08-TEST' AND ArticuloID = @IdAzucar)
    BEGIN
        INSERT INTO Inventario.Lotes (ArticuloID, NumeroLote, FechaFabricacion, FechaVencimiento, ProveedorID, Estado)
        VALUES (@IdAzucar, 'LOTE-AZU-2026-08-TEST', '2026-08-01', '2028-08-01', @IdProv1, 'APROBADO');
        SET @LoteAzucar = SCOPE_IDENTITY();

        INSERT INTO Inventario.InventarioStock (ArticuloID, BodegaID, LoteID, CantidadActual, CostoUnitarioLote)
        VALUES (@IdAzucar, 5, @LoteAzucar, 100.0000, 1600.0000);

        INSERT INTO Kardex.KardexMovimientos
            (ArticuloID, BodegaID, LoteID, TipoMovID, CentroCostoID,
             Cantidad, CostoUnitario, CantidadSaldo, CostoPromedioSaldo, ObservacionDetallada, UsuarioID)
        VALUES (@IdAzucar, 5, @LoteAzucar, @TipoCompra, 7,
                100.0000, 1600.0000, 100.0000, 1600.0000,
                'Compra inicial TEST - Incauca, Factura F-002', 1);

        UPDATE Catalogo.Tarjetas SET CostoPromedio = 1600.0000 WHERE ArticuloID = @IdAzucar;
        PRINT '  Stock Azucar: 100 KG a $1.600 c/u en Bodega Harinas y Secos.';
    END
    ELSE
        PRINT '  Lote Azucar ya existe.';

    -- Lote Margarina (bodega 4 = Lacteos y Frios)
    IF NOT EXISTS (SELECT 1 FROM Inventario.Lotes WHERE NumeroLote = 'LOTE-MAR-2026-08-TEST' AND ArticuloID = @IdMargarina)
    BEGIN
        INSERT INTO Inventario.Lotes (ArticuloID, NumeroLote, FechaFabricacion, FechaVencimiento, ProveedorID, Estado)
        VALUES (@IdMargarina, 'LOTE-MAR-2026-08-TEST', '2026-07-20', '2027-01-20', @IdProv1, 'APROBADO');
        SET @LoteMargarina = SCOPE_IDENTITY();

        INSERT INTO Inventario.InventarioStock (ArticuloID, BodegaID, LoteID, CantidadActual, CostoUnitarioLote)
        VALUES (@IdMargarina, 5, @LoteMargarina, 30.0000, 4200.0000);

        INSERT INTO Kardex.KardexMovimientos
            (ArticuloID, BodegaID, LoteID, TipoMovID, CentroCostoID,
             Cantidad, CostoUnitario, CantidadSaldo, CostoPromedioSaldo, ObservacionDetallada, UsuarioID)
        VALUES (@IdMargarina, 5, @LoteMargarina, @TipoCompra, 7,
                30.0000, 4200.0000, 30.0000, 4200.0000,
                'Compra inicial TEST - Dan Leb, Factura F-003', 1);

        UPDATE Catalogo.Tarjetas SET CostoPromedio = 4200.0000 WHERE ArticuloID = @IdMargarina;
        PRINT '  Stock Margarina: 30 KG a $4.200 c/u en Bodega Harinas y Secos.';
    END
    ELSE
        PRINT '  Lote Margarina ya existe.';

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'ERROR BLOQUE 4: ' + ERROR_MESSAGE();
    RETURN;
END CATCH;

-- =============================================================================
-- BLOQUE 5 - RECETA BOM
-- Receta para producir 10 unidades de Pan Tajado con 3 insumos.
-- Rendimiento base = 10 und. El SP escala segun CantidadProgramada.
-- Merma: 3% Harina, 2% Azucar, 1% Margarina (tipico panaderia industrial).
-- =============================================================================
PRINT '';
PRINT '--- BLOQUE 5: Receta BOM ---';

BEGIN TRANSACTION;
BEGIN TRY

    IF NOT EXISTS (SELECT 1 FROM Produccion.RecetaBOM WHERE ProductoTerminadoID = @IdPanTajado AND Version = 1)
    BEGIN
        INSERT INTO Produccion.RecetaBOM (ProductoTerminadoID, NombreReceta, Version, CantidadRendimientoBase)
        OUTPUT INSERTED.RecetaID INTO @tmpReceta(RecetaID)
        VALUES (@IdPanTajado, 'Pan Tajado Molde 500g - Receta v1 TEST', 1, 10.0000);

        -- Leer el RecetaID recien insertado (OUTPUT no puede asignarse directo a variable)
        SET @RecetaID = SCOPE_IDENTITY();

        -- Detalle: Harina de Trigo - 2 KG por 10 panes (3% merma)
        INSERT INTO Produccion.RecetaBOM_Detalle (RecetaID, InsumoID, CantidadRequerida, PorcentajeMermaEstandar, Orden)
        VALUES (@RecetaID, @IdHarina, 2.0000, 3.00, 1);

        -- Detalle: Azucar Blanca - 300 g por 10 panes (2% merma)
        INSERT INTO Produccion.RecetaBOM_Detalle (RecetaID, InsumoID, CantidadRequerida, PorcentajeMermaEstandar, Orden)
        VALUES (@RecetaID, @IdAzucar, 0.3000, 2.00, 2);

        -- Detalle: Margarina - 150 g por 10 panes (1% merma)
        INSERT INTO Produccion.RecetaBOM_Detalle (RecetaID, InsumoID, CantidadRequerida, PorcentajeMermaEstandar, Orden)
        VALUES (@RecetaID, @IdMargarina, 0.1500, 1.00, 3);

        PRINT '  Receta BOM creada. ID=' + CAST(@RecetaID AS NVARCHAR);
        PRINT '  Insumos: Harina 2KG/10und (3% merma), Azucar 300g/10und (2%), Margarina 150g/10und (1%)';
    END
    ELSE
    BEGIN
        SET @RecetaID = (SELECT TOP 1 RecetaID FROM Produccion.RecetaBOM WHERE ProductoTerminadoID = @IdPanTajado AND Version = 1);
        PRINT '  Receta ya existe. ID=' + CAST(@RecetaID AS NVARCHAR);
    END

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'ERROR BLOQUE 5: ' + ERROR_MESSAGE();
    RETURN;
END CATCH;

-- =============================================================================
-- BLOQUE 6A - CREAR ORDEN DE PRODUCCION (estado Planificada)
-- Produce 20 panes (2x el rendimiento base de la receta).
-- BodegaOrigenMP=5 (Harinas y Secos), BodegaDestinoPT=9 (Producto Terminado)
-- CentroCostoDestino=4 (Panaderia)
-- =============================================================================
PRINT '';
PRINT '--- BLOQUE 6A: Crear Orden de Produccion ---';

BEGIN TRANSACTION;
BEGIN TRY

    IF NOT EXISTS (SELECT 1 FROM Produccion.OrdenesProduccion WHERE CodigoOP = 'OP-TEST-20260821')
    BEGIN
        INSERT INTO Produccion.OrdenesProduccion
            (CodigoOP, TipoProduccionID, EstadoOPID, ProductoTerminadoID, RecetaID,
             CantidadProgramada, CentroCostoDestinoID, BodegaOrigenMPID, BodegaDestinoPTID,
             FechaPlanificada, UsuarioCreaID, CostoMateriales, CostoMOD, CostoCIF,
             Observaciones)
        VALUES
            ('OP-TEST-20260821', 1,
             (SELECT EstadoOPID FROM Produccion.EstadosOP WHERE Nombre = 'Planificada'),
             @IdPanTajado, @RecetaID,
             20.0000,  -- 20 panes = 2 lotes de rendimiento base
             4,        -- CentroCosto: Panaderia y Pasteleria
             5,        -- BodegaOrigenMP: Harinas y Secos
             9,        -- BodegaDestinoPT: Bodega Producto Terminado
             DATEADD(DAY, 1, GETDATE()), 1, 0, 0, 0,
             'Orden de produccion de prueba - verificacion integral NEXO');
        SET @OpID = SCOPE_IDENTITY();
        PRINT '  Orden OP-TEST-20260821 creada en estado Planificada. ID=' + CAST(@OpID AS NVARCHAR);
    END
    ELSE
    BEGIN
        SET @OpID = (SELECT OrdenProduccionID FROM Produccion.OrdenesProduccion WHERE CodigoOP = 'OP-TEST-20260821');
        PRINT '  OP-TEST-20260821 ya existe. ID=' + CAST(@OpID AS NVARCHAR);
    END

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'ERROR BLOQUE 6A: ' + ERROR_MESSAGE();
    RETURN;
END CATCH;

-- =============================================================================
-- BLOQUE 6B - LIBERAR ORDEN (valida stock de insumos)
-- El SP verifica que haya suficiente stock en bodega 5 para los 3 insumos.
-- Con 20 panes: necesita ~4.12 KG harina, 0.612 KG azucar, 0.303 KG margarina.
-- Si falla, significa que el stock del bloque 4 no fue suficiente.
-- =============================================================================
PRINT '';
PRINT '--- BLOQUE 6B: Liberar Orden (validacion de stock) ---';

DECLARE @EstadoOP NVARCHAR(30);
SET @EstadoOP = (SELECT e.Nombre FROM Produccion.OrdenesProduccion op
                 JOIN Produccion.EstadosOP e ON e.EstadoOPID = op.EstadoOPID
                 WHERE op.OrdenProduccionID = @OpID);

IF @EstadoOP = 'Planificada'
BEGIN
    EXEC Produccion.sp_LiberarOrdenProduccion @OrdenProduccionID = @OpID, @UsuarioID = 1;
    PRINT '  Orden liberada. Stock suficiente confirmado por el SP.';
END
ELSE
    PRINT '  OP ya en estado ' + @EstadoOP + ', salto liberacion.';

-- =============================================================================
-- BLOQUE 6C - INICIAR ORDEN (descuenta insumos con FEFO)
-- El SP descuenta automaticamente harina, azucar y margarina de la bodega 5.
-- Genera movimientos SALIDA_WIP en el Kardex por cada lote consumido.
-- Crea registros en Produccion.OrdenesProduccionConsumo.
-- =============================================================================
PRINT '';
PRINT '--- BLOQUE 6C: Iniciar Orden (descuento de insumos FEFO) ---';

SET @EstadoOP = (SELECT e.Nombre FROM Produccion.OrdenesProduccion op
                 JOIN Produccion.EstadosOP e ON e.EstadoOPID = op.EstadoOPID
                 WHERE op.OrdenProduccionID = @OpID);

IF @EstadoOP = 'Liberada'
BEGIN
    EXEC Produccion.sp_IniciarOrdenProduccion @OrdenProduccionID = @OpID, @UsuarioID = 1;
    PRINT '  Orden iniciada. Insumos descontados de inventario. Kardex SALIDA_WIP generado.';
END
ELSE
    PRINT '  OP ya en estado ' + @EstadoOP + ', salto inicio.';

-- =============================================================================
-- BLOQUE 6D - CERRAR ORDEN (entra PT + genera eventos Visions)
-- CantidadProducidaReal = 19 (1 unidad de merma de las 20 programadas).
-- HorasManoObra = 3, sin CIF para simplificar.
-- El SP calcula el costo real, crea lote PT, entra al stock, actualiza CostoPromedio.
-- NEXO luego crea EventosSalientes para ENTRADA_PRODUCCION y CONSUMO_INSUMO
-- (solo si los articulos tienen MapeoArticulos con cc.TieneVisions=1).
-- =============================================================================
PRINT '';
PRINT '--- BLOQUE 6D: Cerrar Orden (entrada PT + costo real) ---';

SET @EstadoOP = (SELECT e.Nombre FROM Produccion.OrdenesProduccion op
                 JOIN Produccion.EstadosOP e ON e.EstadoOPID = op.EstadoOPID
                 WHERE op.OrdenProduccionID = @OpID);

IF @EstadoOP = 'En Proceso'
BEGIN
    EXEC Produccion.sp_CerrarOrdenProduccion
        @OrdenProduccionID    = @OpID,
        @CantidadProducidaReal = 19.0000,
        @HorasManoObra        = 3.0000,
        @HorasCIF             = 0.0000,
        @NumeroLotePT         = 'PT-PAN-TEST-001',
        @FechaVencimientoPT   = '2026-08-28',
        @UsuarioID            = 1;
    PRINT '  Orden finalizada. 19 panes entrados al stock. Costo real calculado.';
    PRINT '  Lote PT-PAN-TEST-001 creado. Kardex ENTRADA_PT generado.';
END
ELSE
    PRINT '  OP en estado ' + @EstadoOP + ', salto cierre.';

-- =============================================================================
-- BLOQUE 7 - AJUSTE DE INVENTARIO DIRECTO
-- Prueba el SP de ajuste positivo sobre la harina (simula un conteo fisico
-- que encontro 5 KG adicionales no registrados).
-- Valida: cantidad > 0, costo >= 0, motivo >= 5 chars.
-- Genera: Kardex AJU_INV + EventosSalientes si el CC tiene Visions.
-- =============================================================================
PRINT '';
PRINT '--- BLOQUE 7: Ajuste directo de inventario ---';

EXEC Kardex.sp_AjustePositivoInventario
    @ArticuloID   = @IdHarina,
    @BodegaID     = 5,
    @Cantidad     = 5.0000,
    @CostoUnitario = 1850.0000,
    @Motivo       = 'Diferencia de inventario en conteo fisico agosto 2026 - TEST',
    @UsuarioID    = 1;

PRINT '  Ajuste aplicado: +5 KG de harina en Bodega Harinas y Secos. Kardex AJU_INV generado.';

-- =============================================================================
-- BLOQUE 8 - BAJA DE INVENTARIO DIRECTA
-- Prueba el SP de baja (merma) sobre el azucar.
-- Simula 2 KG danados por humedad (motivo tipico en panaderia).
-- Requiere ObservacionDetallada de minimo 5 chars.
-- Genera: Kardex BAJA_MERMA (cantidad negativa) + EventosSalientes si Visions.
-- =============================================================================
PRINT '';
PRINT '--- BLOQUE 8: Baja de inventario (merma) ---';

-- Obtener MotivoID de averia (si existe, si no usar el primero disponible)
DECLARE @MotivoMermaID INT;
SET @MotivoMermaID = ISNULL(
    (SELECT TOP 1 MotivoID FROM Kardex.TiposMotivoLoss WHERE Nombre LIKE '%humedad%' OR Nombre LIKE '%dano%' ORDER BY MotivoID),
    (SELECT TOP 1 MotivoID FROM Kardex.TiposMotivoLoss ORDER BY MotivoID)
);

IF @MotivoMermaID IS NOT NULL
BEGIN
    EXEC Kardex.sp_RegistrarBajaInventario
        @ArticuloID          = @IdAzucar,
        @BodegaID            = 5,
        @LoteID              = @LoteAzucar,
        @CantidadPerdida     = 2.0000,
        @MotivoID            = @MotivoMermaID,
        @ObservacionDetallada = 'Dano por humedad en bodega - saco perforado - TEST agosto 2026',
        @UsuarioRegistraID   = 1;
    PRINT '  Baja aplicada: -2 KG de azucar. Kardex BAJA_MERMA generado.';
END
ELSE
    PRINT '  No hay motivos de perdida configurados. Omitiendo baja.';

-- =============================================================================
-- BLOQUE 9 - [OPCIONAL] CONFIGURACION PARA SYNC CON VISIONS
-- Descomenta si tienes Visions conectado y quieres ver los EventosSalientes
-- llegar a dbo.TARJETA en VISIONSDBL1.
-- Paso 1: Habilitar TieneVisions en el CentroCosto de Bodega (ID=7)
-- Paso 2: Registrar los articulos en MapeoArticulos con su codigo en Visions
-- =============================================================================
PRINT '';
PRINT '--- BLOQUE 9: [OPCIONAL] Config Visions (descomenta para activar) ---';

/*
-- Activar integracion Visions para el CC-BODEGA (CC7)
UPDATE Organizacion.CentrosCosto
SET TieneVisions = 1, IdentificadorClienteVisions = 1  -- 1 = CENTROCOSTO en Visions
WHERE CentroCostoID = 7;

-- Mapear los 4 articulos test con sus referencias en Visions
-- CodigoArticuloVisions = REFERENCIA en dbo.TARJETA de Visions
INSERT INTO Integracion.MapeoArticulos (ArticuloID, CentroCostoID, CodigoArticuloVisions, Estado)
VALUES
    (@IdHarina,    7, 'MP-HARINA-T01', 1),
    (@IdAzucar,    7, 'MP-AZUCAR-T01', 1),
    (@IdMargarina, 7, 'MP-MARG-T01',   1),
    (@IdPanTajado, 7, 'PT-PAN-T01',    1);

PRINT '  Mapeos Visions configurados. Los proximos movimientos generaran EventosSalientes.';
*/

PRINT '  Seccion Visions comentada. Ver instrucciones dentro del bloque.';

-- =============================================================================
-- BLOQUE 10 - VERIFICACIONES FINALES
-- Consultas que demuestran que todo quedo correcto.
-- =============================================================================
PRINT '';
PRINT '======================================================================';
PRINT 'VERIFICACIONES FINALES';
PRINT '======================================================================';

-- 10A: Articulos creados con stock y costos actualizados
PRINT '';
PRINT '10A - ARTICULOS TEST (stock + costo):';
SELECT
    a.Referencia AS SKU,
    a.Nombre,
    ta.Nombre AS Tipo,
    ISNULL(a.CostoPromedio, 0) AS CostoPromedio,
    ISNULL(a.PPublico, 0) AS PrecioVenta,
    ISNULL(SUM(s.CantidadActual), 0) AS StockTotal
FROM Catalogo.Tarjetas a
JOIN Catalogo.TiposArticulo ta ON ta.TipoArticuloID = a.TipoArticuloID
LEFT JOIN Inventario.InventarioStock s ON s.ArticuloID = a.ArticuloID
WHERE a.Referencia IN ('MP-HARINA-T01','MP-AZUCAR-T01','MP-MARG-T01','PT-PAN-T01')
GROUP BY a.Referencia, a.Nombre, ta.Nombre, a.CostoPromedio, a.PPublico
ORDER BY ta.Nombre DESC, a.Referencia;

-- 10B: Stock consolidado por bodega y lote
PRINT '';
PRINT '10B - STOCK CONSOLIDADO (vw_StockConsolidado):';
SELECT
    SKU, Articulo, Bodega, NumeroLote, FechaVencimiento,
    CantidadActual, CostoUnitarioLote,
    CantidadActual * CostoUnitarioLote AS ValorTotal,
    CASE WHEN RequierePedido = 1 THEN 'SI - BAJO MINIMO' ELSE 'OK' END AS Alerta
FROM Inventario.vw_StockConsolidado
WHERE SKU IN ('MP-HARINA-T01','MP-AZUCAR-T01','MP-MARG-T01','PT-PAN-T01')
ORDER BY SKU, Bodega;

-- 10C: Kardex completo de los articulos test (todos los movimientos)
PRINT '';
PRINT '10C - KARDEX (ultimos 30 movimientos de articulos TEST):';
SELECT TOP 30
    k.Fecha,
    a.Referencia AS SKU,
    b.Nombre AS Bodega,
    tm.Nombre AS TipoMovimiento,
    k.Cantidad,
    k.CostoUnitario,
    k.CantidadSaldo AS SaldoTrasMovimiento,
    LEFT(k.ObservacionDetallada, 80) AS Observacion
FROM Kardex.KardexMovimientos k
JOIN Catalogo.Tarjetas a ON a.ArticuloID = k.ArticuloID
JOIN Inventario.Bodegas b ON b.BodegaID = k.BodegaID
JOIN Kardex.TiposMovimientoKardex tm ON tm.TipoMovID = k.TipoMovID
WHERE a.Referencia IN ('MP-HARINA-T01','MP-AZUCAR-T01','MP-MARG-T01','PT-PAN-T01')
ORDER BY k.KardexID DESC;

-- 10D: Orden de Produccion y su resultado
PRINT '';
PRINT '10D - ORDEN DE PRODUCCION:';
SELECT
    op.CodigoOP,
    e.Nombre AS Estado,
    a.Nombre AS Producto,
    op.CantidadProgramada,
    op.CantidadProducidaReal,
    op.CostoMateriales,
    op.CostoMOD,
    op.CostoCIF,
    op.CostoUnitarioReal,
    op.CantidadProducidaReal * op.CostoUnitarioReal AS CostoTotalReal,
    op.FechaPlanificada,
    op.FechaInicio,
    op.FechaFin
FROM Produccion.OrdenesProduccion op
JOIN Produccion.EstadosOP e ON e.EstadoOPID = op.EstadoOPID
JOIN Catalogo.Tarjetas a ON a.ArticuloID = op.ProductoTerminadoID
WHERE op.CodigoOP = 'OP-TEST-20260821';

-- 10D2: Consumo real vs teorico de la OP
PRINT '';
PRINT '10D2 - CONSUMOS DE LA OP (real vs teorico):';
SELECT
    art.Nombre AS Insumo,
    c.CantidadTeorica,
    c.CantidadReal,
    c.CantidadReal - c.CantidadTeorica AS Diferencia,
    CASE WHEN c.CantidadReal > c.CantidadTeorica THEN 'EXCESO' WHEN c.CantidadReal < c.CantidadTeorica THEN 'AHORRO' ELSE 'EXACTO' END AS Resultado
FROM Produccion.OrdenesProduccionConsumo c
JOIN Catalogo.Tarjetas art ON art.ArticuloID = c.ArticuloID
JOIN Produccion.OrdenesProduccion op ON op.OrdenProduccionID = c.OrdenProduccionID
WHERE op.CodigoOP = 'OP-TEST-20260821'
ORDER BY c.ConsumoID;

-- 10E: Clientes y Proveedores creados
PRINT '';
PRINT '10E - CLIENTES TEST:';
SELECT ClienteID, Nombre, NIT, TipoPersona, TipoIdentificacion, DigitoVerificacion,
       Ciudad, Departamento, Pais, CodigoPais, Email, Telefono, Estado
FROM Crm.Clientes
WHERE NIT IN ('52847392','900847321')
ORDER BY ClienteID;

PRINT '';
PRINT '10F - PROVEEDORES TEST:';
SELECT ProveedorID, RazonSocial, NIT, TipoPersona, TipoIdentificacion, DigitoVerificacion,
       Ciudad, Departamento, Pais, CodigoPais, Email, Telefono, Estado
FROM Catalogo.Proveedores
WHERE NIT IN ('860012547','79345682')
ORDER BY ProveedorID;

-- 10G: Eventos Salientes para Visions (solo si hay mapeo configurado)
PRINT '';
PRINT '10G - EVENTOS SALIENTES PARA VISIONS:';
SELECT
    e.EventoID,
    e.TipoEvento,
    cc.Nombre AS CentroCosto,
    a.Referencia AS SKU,
    a.Nombre AS Articulo,
    e.Cantidad,
    e.CostoUnitario,
    e.Estado,
    e.FechaCreacion
FROM Integracion.EventosSalientes e
JOIN Organizacion.CentrosCosto cc ON cc.CentroCostoID = e.CentroCostoID
JOIN Catalogo.Tarjetas a ON a.ArticuloID = e.ArticuloID
WHERE a.Referencia IN ('MP-HARINA-T01','MP-AZUCAR-T01','MP-MARG-T01','PT-PAN-T01')
   OR e.TipoEvento IN ('ENTRADA_PRODUCCION','CONSUMO_INSUMO','BAJA_INVENTARIO','AJUSTE_INVENTARIO')
ORDER BY e.EventoID DESC;

-- 10H: Resumen de lotes creados en esta prueba
PRINT '';
PRINT '10H - LOTES CREADOS:';
SELECT l.NumeroLote, a.Referencia AS SKU, l.FechaFabricacion, l.FechaVencimiento, l.Estado,
       p.RazonSocial AS Proveedor
FROM Inventario.Lotes l
JOIN Catalogo.Tarjetas a ON a.ArticuloID = l.ArticuloID
LEFT JOIN Catalogo.Proveedores p ON p.ProveedorID = l.ProveedorID
WHERE l.NumeroLote LIKE '%-TEST%'
ORDER BY l.LoteID;

PRINT '';
PRINT '======================================================================';
PRINT 'VERIFICACION COMPLETADA.';
PRINT 'Resultado esperado:';
PRINT '  10A: 4 articulos test con costos y stock actualizados.';
PRINT '  10B: Stock de MP reducido (insumos consumidos) + PT nuevo.';
PRINT '  10C: Kardex con ENTRADA_COMPRA > SALIDA_WIP > ENTRADA_PT > AJU_INV > BAJA_MERMA.';
PRINT '  10D: OP Finalizada con costo unitario real calculado.';
PRINT '  10D2: Consumos de la OP (real = teorico si no se ajusto).';
PRINT '  10E/10F: Clientes y proveedores con campos geograficos completos.';
PRINT '  10G: EventosSalientes presentes SOLO si se configuro MapeoArticulos (Bloque 9).';
PRINT '  10H: 3 lotes MP + 1 lote PT creados en esta prueba.';
PRINT '======================================================================';
GO

-- =============================================================================
-- LIMPIEZA (OPCIONAL)
-- Descomenta y ejecuta SOLO si quieres borrar todos los datos de prueba.
-- ADVERTENCIA: elimina permanentemente los registros insertados en este script.
-- =============================================================================
/*
DECLARE @IdHarina INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia='MP-HARINA-T01');
DECLARE @IdAzucar INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia='MP-AZUCAR-T01');
DECLARE @IdMargarina INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia='MP-MARG-T01');
DECLARE @IdPanTajado INT = (SELECT ArticuloID FROM Catalogo.Tarjetas WHERE Referencia='PT-PAN-T01');
DECLARE @OpID INT = (SELECT OrdenProduccionID FROM Produccion.OrdenesProduccion WHERE CodigoOP='OP-TEST-20260821');
DECLARE @RecetaID INT = (SELECT TOP 1 RecetaID FROM Produccion.RecetaBOM WHERE NombreReceta LIKE '%TEST%');

DELETE FROM Kardex.KardexMovimientos WHERE ArticuloID IN (@IdHarina,@IdAzucar,@IdMargarina,@IdPanTajado);
DELETE FROM Inventario.InventarioStock WHERE ArticuloID IN (@IdHarina,@IdAzucar,@IdMargarina,@IdPanTajado);
DELETE FROM Inventario.Lotes WHERE NumeroLote LIKE '%-TEST%';
DELETE FROM Produccion.OrdenesProduccionConsumo WHERE OrdenProduccionID = @OpID;
DELETE FROM Produccion.OrdenesProduccion WHERE OrdenProduccionID = @OpID;
DELETE FROM Produccion.RecetaBOM_Detalle WHERE RecetaID = @RecetaID;
DELETE FROM Produccion.RecetaBOM WHERE RecetaID = @RecetaID;
DELETE FROM Integracion.EventosSalientes WHERE ArticuloID IN (@IdHarina,@IdAzucar,@IdMargarina,@IdPanTajado);
DELETE FROM Integracion.MapeoArticulos WHERE ArticuloID IN (@IdHarina,@IdAzucar,@IdMargarina,@IdPanTajado);
DELETE FROM Crm.Clientes WHERE NIT IN ('52847392','900847321');
DELETE FROM Catalogo.Proveedores WHERE NIT IN ('860012547','79345682');
DELETE FROM Catalogo.Tarjetas WHERE Referencia IN ('MP-HARINA-T01','MP-AZUCAR-T01','MP-MARG-T01','PT-PAN-T01');
PRINT 'Datos de prueba eliminados.';
*/
