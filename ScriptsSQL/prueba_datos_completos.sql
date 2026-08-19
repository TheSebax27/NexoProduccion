-- =============================================================
-- NEXO ERP — DATOS DE PRUEBA COMPLETOS
-- Escenario: Panadería El Trigo Dorado
-- Cubre: Clientes, Catálogo, Inventario, Kardex, Producción,
--        Facturación, CRM, Integración con Visions
--
-- INSTRUCCIONES:
--   Ejecutar sección por sección con F5 en SSMS contra NEXODB.
--   Secciones 7-9 tienen TRY/CATCH: si fallan revisar columnas y re-ejecutar.
--   Este script NO modifica VISIONSDBL1 directamente.
-- =============================================================
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;

PRINT '========================================';
PRINT '  NEXO ERP — INSERCION DE DATOS PRUEBA  ';
PRINT '========================================';

-- =============================================================
-- SECCIÓN 1: CLIENTES (2 Natural + 2 Jurídica)
-- Columnas verificadas en código de CrmService
-- =============================================================
PRINT '';
PRINT '--- 1. Clientes ---';

IF NOT EXISTS (SELECT 1 FROM Crm.Clientes WHERE NIT='52445789')
    INSERT INTO Crm.Clientes
        (Nombre, NIT, Telefono, Email, Direccion, Estado, TipoCliente, TipoPersona,
         PrimerNombre, SegundoNombre, PrimerApellido, SegundoApellido,
         Departamento, Ciudad, FechaCreacion, FechaModificacion)
    VALUES ('Ana Lucia Bermudez Garcia','52445789','3108765432','analucia@gmail.com',
            'Calle 45 #12-30',1,'Persona Natural','Natural',
            'Ana Lucia',NULL,'Bermudez','Garcia','Boyaca','Tunja',GETDATE(),GETDATE());

IF NOT EXISTS (SELECT 1 FROM Crm.Clientes WHERE NIT='12356789')
    INSERT INTO Crm.Clientes
        (Nombre, NIT, Telefono, Email, Direccion, Estado, TipoCliente, TipoPersona,
         PrimerNombre, SegundoNombre, PrimerApellido, SegundoApellido,
         Departamento, Ciudad, FechaCreacion, FechaModificacion)
    VALUES ('Carlos Eduardo Ruiz Perez','12356789','3187654321','carlosruiz@hotmail.com',
            'Carrera 8 #22-15',1,'Persona Natural','Natural',
            'Carlos','Eduardo','Ruiz','Perez','Cundinamarca','Bogota',GETDATE(),GETDATE());

IF NOT EXISTS (SELECT 1 FROM Crm.Clientes WHERE NIT='900234567-1')
    INSERT INTO Crm.Clientes
        (Nombre, NIT, Telefono, Email, Direccion, Estado, TipoCliente, TipoPersona,
         Departamento, Ciudad, FechaCreacion, FechaModificacion)
    VALUES ('Supermercado La Economia SAS','900234567-1','6074512345','compras@laeconomia.co',
            'Avenida 6 #15-80',1,'Empresa','Juridica','Santander','Bucaramanga',GETDATE(),GETDATE());

IF NOT EXISTS (SELECT 1 FROM Crm.Clientes WHERE NIT='860567890-2')
    INSERT INTO Crm.Clientes
        (Nombre, NIT, Telefono, Email, Direccion, Estado, TipoCliente, TipoPersona,
         Departamento, Ciudad, FechaCreacion, FechaModificacion)
    VALUES ('Restaurante El Sabor Casero Ltda','860567890-2','6014567890','pedidos@saborcasero.co',
            'Calle 72 #45-20',1,'Empresa','Juridica','Cundinamarca','Bogota',GETDATE(),GETDATE());

PRINT '  OK: 4 clientes listos';

-- =============================================================
-- SECCIÓN 2: CATÁLOGO — Marcas, Grupos, Artículos
-- Columnas verificadas en sesión anterior
-- =============================================================
PRINT '';
PRINT '--- 2. Catalogo ---';

MERGE catalogo.Marca AS d USING (SELECT 'ELD' AS C) AS s ON d.Codigo=s.C
WHEN NOT MATCHED THEN INSERT (Codigo,Marca) VALUES ('ELD','EL DORADO');
MERGE catalogo.Marca AS d USING (SELECT 'TRG' AS C) AS s ON d.Codigo=s.C
WHEN NOT MATCHED THEN INSERT (Codigo,Marca) VALUES ('TRG','TRIGO DE ORO');

MERGE catalogo.GrupoMayor AS d USING (SELECT 'PT' AS C) AS s ON d.Codigo=s.C
WHEN NOT MATCHED THEN INSERT (Codigo,Nombre) VALUES ('PT','PRODUCTOS TERMINADOS');
MERGE catalogo.GrupoMayor AS d USING (SELECT 'INS' AS C) AS s ON d.Codigo=s.C
WHEN NOT MATCHED THEN INSERT (Codigo,Nombre) VALUES ('INS','INSUMOS');

MERGE catalogo.GrupoMenor AS d USING (SELECT 'PT-PAN' AS C) AS s ON d.Codigo=s.C
WHEN NOT MATCHED THEN INSERT (Codigo,Nombre,GrupoMayor) VALUES ('PT-PAN','PANES','PT');
MERGE catalogo.GrupoMenor AS d USING (SELECT 'PT-PAS' AS C) AS s ON d.Codigo=s.C
WHEN NOT MATCHED THEN INSERT (Codigo,Nombre,GrupoMayor) VALUES ('PT-PAS','PASTELERIA','PT');
MERGE catalogo.GrupoMenor AS d USING (SELECT 'INS-EMP' AS C) AS s ON d.Codigo=s.C
WHEN NOT MATCHED THEN INSERT (Codigo,Nombre,GrupoMayor) VALUES ('INS-EMP','EMPAQUES','INS');

IF NOT EXISTS (SELECT 1 FROM catalogo.Tarjetas WHERE Referencia='PAH-PT-001')
    INSERT INTO catalogo.Tarjetas
        (Referencia,Nombre,TipoArticuloID,CostoPromedio,StockMinimo,PuntoReorden,Fracciona,Estado,
         Costo,PPublico,MarcaCodigo,GrupoMenorCodigo,PresentacionCodigo,IvaSiNo,IvaValor,IvaDescripcion,FechaCreacion)
    VALUES
        ('PAH-PT-001','Pan Tajado Integral 500g',2,1200,50,100,'NO',1,1200,3500,'TRG','PT-PAN','1','SI',0,'EXENTO',GETDATE()),
        ('PAH-PT-002','Croissant de Mantequilla UND',2,800,30,60,'NO',1,800,2200,'TRG','PT-PAS','1','SI',0,'EXENTO',GETDATE()),
        ('PAH-PT-003','Pandebono 50g UND',2,350,100,200,'NO',1,350,900,'TRG','PT-PAN','1','SI',0,'EXENTO',GETDATE()),
        ('PAH-PT-004','Torta Basica de Vainilla 500g',2,4500,10,20,'NO',1,4500,15000,'TRG','PT-PAS','1','SI',0,'EXENTO',GETDATE()),
        ('PAH-INS-005','Bolsa Kraft Pan Tajado UND',3,120,500,1000,'NO',1,120,280,'ELD','INS-EMP','1','NO',0,'EXENTO',GETDATE());

DECLARE @PanTajadoID   INT = (SELECT ArticuloID FROM catalogo.Tarjetas WHERE Referencia='PAH-PT-001');
DECLARE @CroissantID   INT = (SELECT ArticuloID FROM catalogo.Tarjetas WHERE Referencia='PAH-PT-002');
DECLARE @PandebonoID   INT = (SELECT ArticuloID FROM catalogo.Tarjetas WHERE Referencia='PAH-PT-003');
DECLARE @TortaID       INT = (SELECT ArticuloID FROM catalogo.Tarjetas WHERE Referencia='PAH-PT-004');
DECLARE @BolsaID       INT = (SELECT ArticuloID FROM catalogo.Tarjetas WHERE Referencia='PAH-INS-005');
DECLARE @HarinaID      INT = (SELECT ArticuloID FROM catalogo.Tarjetas WHERE Referencia='PAH-MP-001');
DECLARE @AzucarID      INT = (SELECT ArticuloID FROM catalogo.Tarjetas WHERE Referencia='PAH-MP-002');
DECLARE @SalID         INT = (SELECT ArticuloID FROM catalogo.Tarjetas WHERE Referencia='PAH-MP-003');
DECLARE @LevaduraID    INT = (SELECT ArticuloID FROM catalogo.Tarjetas WHERE Referencia='PAH-MP-004');
DECLARE @MargarinaID   INT = (SELECT ArticuloID FROM catalogo.Tarjetas WHERE Referencia='PAH-MP-005');

PRINT '  OK: articulos catalogo listos';
PRINT '  PanTajado=' + CAST(@PanTajadoID AS VARCHAR) + ' Croissant=' + CAST(@CroissantID AS VARCHAR);

-- =============================================================
-- SECCIÓN 3: INVENTARIO — Bodegas, Lotes, Stock
-- =============================================================
PRINT '';
PRINT '--- 3. Inventario ---';

IF NOT EXISTS (SELECT 1 FROM Inventario.Bodegas WHERE CentroCostoID=7 AND TipoBodega='PRODUCTO_TERMINADO')
    INSERT INTO Inventario.Bodegas (Nombre,CentroCostoID,TipoBodega,EsVirtual,Estado)
    VALUES ('Bodega PT Panificacion',7,'PRODUCTO_TERMINADO',0,1);

DECLARE @BodegaPT   INT = (SELECT TOP 1 BodegaID FROM Inventario.Bodegas WHERE CentroCostoID=7 AND TipoBodega='PRODUCTO_TERMINADO');
DECLARE @BodegaMP   INT = 3; -- Bodega MP CC=7 (verificada sesion anterior)

IF NOT EXISTS (SELECT 1 FROM Inventario.Lotes WHERE NumeroLote='LOT-PT-2026001')
    INSERT INTO Inventario.Lotes (ArticuloID,NumeroLote,FechaFabricacion,FechaVencimiento,Estado,FechaCreacion)
    VALUES
        (@PanTajadoID,'LOT-PT-2026001', CAST(GETDATE() AS DATE),DATEADD(DAY, 5,GETDATE()),'APROBADO',GETDATE()),
        (@CroissantID,'LOT-CRO-2026001',CAST(GETDATE() AS DATE),DATEADD(DAY, 3,GETDATE()),'APROBADO',GETDATE()),
        (@PandebonoID,'LOT-PAN-2026001',CAST(GETDATE() AS DATE),DATEADD(DAY, 2,GETDATE()),'APROBADO',GETDATE()),
        (@TortaID,    'LOT-TOR-2026001',CAST(GETDATE() AS DATE),DATEADD(DAY, 4,GETDATE()),'APROBADO',GETDATE()),
        (@BolsaID,    'LOT-BOL-2026001',CAST(GETDATE() AS DATE),DATEADD(YEAR,2,GETDATE()),'APROBADO',GETDATE());

DECLARE @LotePan       INT = (SELECT LoteID FROM Inventario.Lotes WHERE NumeroLote='LOT-PT-2026001');
DECLARE @LoteCroissant INT = (SELECT LoteID FROM Inventario.Lotes WHERE NumeroLote='LOT-CRO-2026001');
DECLARE @LotePandebono INT = (SELECT LoteID FROM Inventario.Lotes WHERE NumeroLote='LOT-PAN-2026001');
DECLARE @LoteTorta     INT = (SELECT LoteID FROM Inventario.Lotes WHERE NumeroLote='LOT-TOR-2026001');
DECLARE @LoteBolsa     INT = (SELECT LoteID FROM Inventario.Lotes WHERE NumeroLote='LOT-BOL-2026001');
-- Lotes de MP ya existentes (si difieren: SELECT LoteID,NumeroLote FROM Inventario.Lotes WHERE ArticuloID=@HarinaID)
DECLARE @LoteHarina    INT = 60;
DECLARE @LoteAzucar    INT = 61;

-- Stock PT en bodega panificacion
MERGE Inventario.InventarioStock AS d
USING (VALUES
    (@PanTajadoID,@BodegaPT,@LotePan,    50,1600),
    (@CroissantID,@BodegaPT,@LoteCroissant,40,1150),
    (@PandebonoID,@BodegaPT,@LotePandebono,80, 350),
    (@TortaID,    @BodegaPT,@LoteTorta,    5,4500)
) AS s(A,B,L,Qty,Costo)
ON d.ArticuloID=s.A AND d.BodegaID=s.B AND d.LoteID=s.L
WHEN NOT MATCHED THEN INSERT (ArticuloID,BodegaID,LoteID,CantidadActual,CostoUnitarioLote,FechaUltimaActualizacion)
VALUES (s.A,s.B,s.L,s.Qty,s.Costo,GETDATE());

-- Stock MP adicional
MERGE Inventario.InventarioStock AS d USING (SELECT @HarinaID A,@BodegaMP B,@LoteHarina L) AS s ON d.ArticuloID=s.A AND d.BodegaID=s.B AND d.LoteID=s.L
WHEN MATCHED THEN UPDATE SET CantidadActual=CantidadActual+150, FechaUltimaActualizacion=GETDATE()
WHEN NOT MATCHED THEN INSERT (ArticuloID,BodegaID,LoteID,CantidadActual,CostoUnitarioLote,FechaUltimaActualizacion) VALUES (@HarinaID,@BodegaMP,@LoteHarina,150,1850,GETDATE());

MERGE Inventario.InventarioStock AS d USING (SELECT @AzucarID A,@BodegaMP B,@LoteAzucar L) AS s ON d.ArticuloID=s.A AND d.BodegaID=s.B AND d.LoteID=s.L
WHEN MATCHED THEN UPDATE SET CantidadActual=CantidadActual+80, FechaUltimaActualizacion=GETDATE()
WHEN NOT MATCHED THEN INSERT (ArticuloID,BodegaID,LoteID,CantidadActual,CostoUnitarioLote,FechaUltimaActualizacion) VALUES (@AzucarID,@BodegaMP,@LoteAzucar,80,2100,GETDATE());

MERGE Inventario.InventarioStock AS d USING (SELECT @BolsaID A,@BodegaMP B,@LoteBolsa L) AS s ON d.ArticuloID=s.A AND d.BodegaID=s.B AND d.LoteID=s.L
WHEN MATCHED THEN UPDATE SET CantidadActual=CantidadActual+1000, FechaUltimaActualizacion=GETDATE()
WHEN NOT MATCHED THEN INSERT (ArticuloID,BodegaID,LoteID,CantidadActual,CostoUnitarioLote,FechaUltimaActualizacion) VALUES (@BolsaID,@BodegaMP,@LoteBolsa,1000,120,GETDATE());

PRINT '  OK: stock PT (50+40+80+5) y MP (+150 harina +80 azucar +1000 bolsas)';

-- =============================================================
-- SECCIÓN 4: FACTURACIÓN — 3 Facturas con líneas
-- Columnas verificadas en sesión anterior
-- =============================================================
PRINT '';
PRINT '--- 4. Facturas ---';

DECLARE @ClienteAna    INT = (SELECT ClienteID FROM Crm.Clientes WHERE NIT='52445789');
DECLARE @ClienteCarlos INT = (SELECT ClienteID FROM Crm.Clientes WHERE NIT='12356789');
DECLARE @ClienteSuper  INT = (SELECT ClienteID FROM Crm.Clientes WHERE NIT='900234567-1');
DECLARE @ClienteRest   INT = (SELECT ClienteID FROM Crm.Clientes WHERE NIT='860567890-2');

IF NOT EXISTS (SELECT 1 FROM Facturacion.Facturas WHERE NroDoc='FAC-2026-001')
BEGIN
    INSERT INTO Facturacion.Facturas
        (ClienteID,Fecha,CentroCostoID,UsuarioID,StockDescontado,ProduccionAutoEjecutada,TipDoc,NroDoc)
    VALUES (@ClienteAna,CAST(GETDATE() AS DATE),7,2,1,0,'FACTURA','FAC-2026-001');
    DECLARE @F1 INT = SCOPE_IDENTITY();
    INSERT INTO Facturacion.FacturaLineas (FacturaID,ArticuloID,Cantidad,PrecioUnitario,DescripcionLinea)
    VALUES
        (@F1,@PanTajadoID, 5,3500,'Pan Tajado Integral 500g'),
        (@F1,@CroissantID, 6,2200,'Croissant de Mantequilla'),
        (@F1,@PandebonoID,10, 900,'Pandebono 50g');
    PRINT '  FAC-2026-001 (Ana Lucia) -> ID=' + CAST(@F1 AS VARCHAR);
END

IF NOT EXISTS (SELECT 1 FROM Facturacion.Facturas WHERE NroDoc='FAC-2026-002')
BEGIN
    INSERT INTO Facturacion.Facturas
        (ClienteID,Fecha,CentroCostoID,UsuarioID,StockDescontado,ProduccionAutoEjecutada,TipDoc,NroDoc)
    VALUES (@ClienteSuper,CAST(GETDATE() AS DATE),7,2,1,0,'FACTURA','FAC-2026-002');
    DECLARE @F2 INT = SCOPE_IDENTITY();
    INSERT INTO Facturacion.FacturaLineas (FacturaID,ArticuloID,Cantidad,PrecioUnitario,DescripcionLinea)
    VALUES
        (@F2,@PanTajadoID,20,3200,'Pan Tajado Integral x mayor'),
        (@F2,@CroissantID,16,2000,'Croissant Mantequilla x mayor'),
        (@F2,@PandebonoID,30, 850,'Pandebono 50g x mayor'),
        (@F2,@TortaID,     3,14000,'Torta Basica Vainilla 500g');
    PRINT '  FAC-2026-002 (Supermercado La Economia) -> ID=' + CAST(@F2 AS VARCHAR);
END

IF NOT EXISTS (SELECT 1 FROM Facturacion.Facturas WHERE NroDoc='FAC-2026-003')
BEGIN
    INSERT INTO Facturacion.Facturas
        (ClienteID,Fecha,CentroCostoID,UsuarioID,StockDescontado,ProduccionAutoEjecutada,TipDoc,NroDoc)
    VALUES (@ClienteRest,CAST(GETDATE() AS DATE),7,2,1,0,'FACTURA','FAC-2026-003');
    DECLARE @F3 INT = SCOPE_IDENTITY();
    INSERT INTO Facturacion.FacturaLineas (FacturaID,ArticuloID,Cantidad,PrecioUnitario,DescripcionLinea)
    VALUES
        (@F3,@PanTajadoID,10,3300,'Pan Tajado Integral 500g'),
        (@F3,@TortaID,     2,14500,'Torta Basica de Vainilla 500g');
    PRINT '  FAC-2026-003 (Restaurante El Sabor) -> ID=' + CAST(@F3 AS VARCHAR);
END

-- =============================================================
-- SECCIÓN 5: INTEGRACIÓN — Eventos para Visions (CC=7)
-- El agente los procesa en la próxima ronda de sincronización
-- =============================================================
PRINT '';
PRINT '--- 5. Eventos Visions (CC=7) ---';

-- Sincronizar artículos nuevos a dbo.TARJETA en Visions
INSERT INTO Integracion.EventosSalientes
    (TipoEvento,CentroCostoID,ArticuloID,Cantidad,CostoUnitario,Estado,IntentosEnvio,FechaCreacion)
SELECT 'SINCRONIZAR_ARTICULO',7,ArticuloID,0,CostoPromedio,'PENDIENTE',0,GETDATE()
FROM catalogo.Tarjetas
WHERE Referencia IN ('PAH-PT-001','PAH-PT-002','PAH-PT-003','PAH-PT-004','PAH-INS-005')
  AND NOT EXISTS (
    SELECT 1 FROM Integracion.EventosSalientes e
    WHERE e.ArticuloID=Tarjetas.ArticuloID
      AND e.TipoEvento='SINCRONIZAR_ARTICULO'
      AND e.Estado='PENDIENTE');

-- Traspaso de stock PT → Visions (simula produccion enviada a bodega Visions)
INSERT INTO Integracion.EventosSalientes
    (TipoEvento,CentroCostoID,ArticuloID,Cantidad,CostoUnitario,Estado,IntentosEnvio,FechaCreacion)
VALUES
    ('TRASPASO_RECIBIDO',7,@PanTajadoID,50,1600,'PENDIENTE',0,GETDATE()),
    ('TRASPASO_RECIBIDO',7,@CroissantID,40,1150,'PENDIENTE',0,GETDATE()),
    ('TRASPASO_RECIBIDO',7,@PandebonoID,80, 350,'PENDIENTE',0,GETDATE()),
    ('TRASPASO_RECIBIDO',7,@TortaID,     5,4500,'PENDIENTE',0,GETDATE());

PRINT '  OK: 5 SINCRONIZAR_ARTICULO + 4 TRASPASO_RECIBIDO pendientes';

-- =============================================================
-- SECCIÓN 6: PROVEEDOR (módulo Compras)
-- =============================================================
PRINT '';
PRINT '--- 6. Proveedor ---';

IF NOT EXISTS (SELECT 1 FROM catalogo.Proveedores WHERE NIT='890123456-7')
    INSERT INTO catalogo.Proveedores (RazonSocial,NIT,Contacto,Telefono,Email,Direccion,Estado)
    VALUES ('Molinos El Dorado SAS','890123456-7','Juan Molina','6074509876',
            'pedidos@molinoeldorado.co','Zona Industrial Km 3',1);

PRINT '  OK: proveedor Molinos El Dorado';

-- =============================================================
-- SECCIÓN 7: PRODUCCIÓN — RecetaBOM + OP
-- TRY/CATCH — si falla verificar columnas exactas de estas tablas
-- =============================================================
PRINT '';
PRINT '--- 7. Produccion (TRY/CATCH) ---';

BEGIN TRY
    DECLARE @RecetaID INT;

    IF NOT EXISTS (SELECT 1 FROM Produccion.RecetaBOM WHERE NombreReceta='Receta Pan Tajado Integral Std')
    BEGIN
        INSERT INTO Produccion.RecetaBOM
            (ProductoTerminadoID,NombreReceta,Version,CantidadRendimientoBase,Estado,FechaCreacion)
        VALUES (@PanTajadoID,'Receta Pan Tajado Integral Std',1,10,1,GETDATE());
        SET @RecetaID = SCOPE_IDENTITY();

        -- Columna CantidadRequerida y Orden — ajustar si se llaman distinto
        INSERT INTO Produccion.RecetaBOM_Detalle (RecetaID,InsumoID,CantidadRequerida,Orden)
        VALUES
            (@RecetaID,@HarinaID,   1.000,1),
            (@RecetaID,@AzucarID,   0.080,2),
            (@RecetaID,@SalID,      0.015,3),
            (@RecetaID,@LevaduraID, 0.020,4),
            (@RecetaID,@MargarinaID,0.050,5),
            (@RecetaID,@BolsaID,    1.000,6);

        PRINT '  OK: RecetaBOM Pan Tajado insertada ID=' + CAST(@RecetaID AS VARCHAR);
    END
    ELSE
        SET @RecetaID = (SELECT RecetaID FROM Produccion.RecetaBOM WHERE NombreReceta='Receta Pan Tajado Integral Std');

    IF NOT EXISTS (SELECT 1 FROM Produccion.OrdenesProduccion WHERE CodigoOP='OP-2026-001')
    BEGIN
        -- Columnas probables — ajustar si EstadoOPID/TipoProduccionID se llaman distinto
        INSERT INTO Produccion.OrdenesProduccion
            (CodigoOP,TipoProduccionID,EstadoOPID,ProductoTerminadoID,RecetaID,
             CantidadProgramada,CantidadProducidaReal,
             CentroCostoDestinoID,FechaPlanificada,FechaInicio,FechaFin,
             CostoMateriales,CostoMOD,CostoCIF,CostoUnitarioReal,
             UsuarioCreaID,UsuarioLiberaID,UsuarioCierraID,FechaCreacion)
        VALUES
            ('OP-2026-001',1,4,@PanTajadoID,@RecetaID,
             50,50,
             7,DATEADD(DAY,-2,GETDATE()),DATEADD(DAY,-2,GETDATE()),DATEADD(DAY,-1,GETDATE()),
             60000,15000,5000,1600,
             2,2,2,GETDATE());

        DECLARE @OP1 INT = SCOPE_IDENTITY();

        -- Evento entrada PT desde producción
        INSERT INTO Integracion.EventosSalientes
            (TipoEvento,CentroCostoID,ArticuloID,Cantidad,CostoUnitario,Estado,IntentosEnvio,FechaCreacion)
        VALUES ('ENTRADA_PRODUCTO_TERMINADO',7,@PanTajadoID,50,1600,'PENDIENTE',0,GETDATE());

        PRINT '  OK: OP-2026-001 finalizada (50 Pan Tajado) ID=' + CAST(@OP1 AS VARCHAR);
    END
END TRY
BEGIN CATCH
    PRINT '  ERROR Produccion: ' + ERROR_MESSAGE();
    PRINT '  >> Verificar: SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS';
    PRINT '     WHERE TABLE_SCHEMA IN (''Produccion'') AND TABLE_NAME IN (''RecetaBOM'',''RecetaBOM_Detalle'',''OrdenesProduccion'')';
    PRINT '     ORDER BY TABLE_NAME, ORDINAL_POSITION';
END CATCH;

-- =============================================================
-- SECCIÓN 8: KARDEX — Movimientos
-- TRY/CATCH — columnas de KardexMovimientos no verificadas al 100%
-- =============================================================
PRINT '';
PRINT '--- 8. Kardex (TRY/CATCH) ---';

BEGIN TRY
    -- TipoMovID 7 = Ajuste (para stock inicial)
    INSERT INTO Kardex.KardexMovimientos
        (Fecha,ArticuloID,BodegaID,LoteID,TipoMovID,CentroCostoID,
         Cantidad,CostoUnitario,CantidadSaldo,CostoPromedioSaldo,UsuarioID,FechaRegistro)
    VALUES
        (GETDATE(),@HarinaID,   @BodegaMP,@LoteHarina,   7,7, 150,1850, 150,1850,2,GETDATE()),
        (GETDATE(),@AzucarID,   @BodegaMP,@LoteAzucar,   7,7,  80,2100,  80,2100,2,GETDATE()),
        (GETDATE(),@BolsaID,    @BodegaMP,@LoteBolsa,    7,7,1000, 120,1000, 120,2,GETDATE()),
        (GETDATE(),@PanTajadoID,@BodegaPT,@LotePan,      7,7,  50,1600,  50,1600,2,GETDATE()),
        (GETDATE(),@CroissantID,@BodegaPT,@LoteCroissant,7,7,  40,1150,  40,1150,2,GETDATE()),
        (GETDATE(),@PandebonoID,@BodegaPT,@LotePandebono,7,7,  80, 350,  80, 350,2,GETDATE()),
        (GETDATE(),@TortaID,    @BodegaPT,@LoteTorta,    7,7,   5,4500,   5,4500,2,GETDATE());

    -- TipoMovID 14 = Venta Factura (salidas acumuladas por las 3 facturas)
    INSERT INTO Kardex.KardexMovimientos
        (Fecha,ArticuloID,BodegaID,LoteID,TipoMovID,CentroCostoID,
         Cantidad,CostoUnitario,CantidadSaldo,CostoPromedioSaldo,UsuarioID,FechaRegistro)
    VALUES
        (GETDATE(),@PanTajadoID,@BodegaPT,@LotePan,      14,7,-35,1600,15,1600,2,GETDATE()),
        (GETDATE(),@CroissantID,@BodegaPT,@LoteCroissant,14,7,-22,1150,18,1150,2,GETDATE()),
        (GETDATE(),@PandebonoID,@BodegaPT,@LotePandebono,14,7,-40, 350,40, 350,2,GETDATE()),
        (GETDATE(),@TortaID,    @BodegaPT,@LoteTorta,    14,7, -5,4500, 0,4500,2,GETDATE());

    PRINT '  OK: kardex 7 entradas + 4 salidas por venta';
END TRY
BEGIN CATCH
    PRINT '  ERROR Kardex: ' + ERROR_MESSAGE();
    PRINT '  >> Verificar: SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS';
    PRINT '     WHERE TABLE_SCHEMA=''Kardex'' AND TABLE_NAME=''KardexMovimientos''';
    PRINT '     ORDER BY ORDINAL_POSITION';
END CATCH;

-- =============================================================
-- SECCIÓN 9: CRM — Interacciones con clientes
-- TRY/CATCH por posibles diferencias de columnas
-- =============================================================
PRINT '';
PRINT '--- 9. Interacciones CRM (TRY/CATCH) ---';

BEGIN TRY
    INSERT INTO Crm.Interacciones (ClienteID,Tipo,Notas,Fecha,UsuarioID)
    VALUES
        (@ClienteSuper,'REUNION',
         'Acuerdo suministro semanal: 50 Pan Tajado + 30 Croissant. Precio especial acordado para volumen.',
         DATEADD(DAY,-5,GETDATE()),2),
        (@ClienteRest,'LLAMADA',
         'Solicita ampliar pedido a 15 Pan Tajado y 4 Tortas desde proxima semana. Confirmar disponibilidad.',
         GETDATE(),2),
        (@ClienteAna,'EMAIL',
         'Consulta disponibilidad pan sin gluten. Posible nueva linea de producto a evaluar.',
         GETDATE(),5),
        (@ClienteCarlos,'VISITA',
         'Primera visita. Interesado en compra semanal de croissants para cafeteria de oficina.',
         DATEADD(DAY,-2,GETDATE()),5);

    PRINT '  OK: 4 interacciones CRM insertadas';
END TRY
BEGIN CATCH
    PRINT '  ERROR Interacciones: ' + ERROR_MESSAGE();
    PRINT '  >> Verificar: SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS';
    PRINT '     WHERE TABLE_SCHEMA=''Crm'' AND TABLE_NAME=''Interacciones''';
    PRINT '     ORDER BY ORDINAL_POSITION';
END CATCH;

-- =============================================================
-- RESUMEN FINAL
-- =============================================================
PRINT '';
PRINT '========================================';
PRINT '  RESUMEN FINAL';
PRINT '========================================';

SELECT 'Clientes activos'           AS Entidad, COUNT(*) AS Total FROM Crm.Clientes WHERE Estado=1
UNION ALL SELECT 'Articulos activos',       COUNT(*) FROM catalogo.Tarjetas WHERE Estado=1
UNION ALL SELECT 'Lineas stock activas',    COUNT(*) FROM Inventario.InventarioStock WHERE CantidadActual>0
UNION ALL SELECT 'Facturas totales',        COUNT(*) FROM Facturacion.Facturas
UNION ALL SELECT 'Lineas de factura',       COUNT(*) FROM Facturacion.FacturaLineas
UNION ALL SELECT 'Eventos pend. CC=7',      COUNT(*) FROM Integracion.EventosSalientes WHERE Estado='PENDIENTE' AND CentroCostoID=7
UNION ALL SELECT 'Proveedores activos',     COUNT(*) FROM catalogo.Proveedores WHERE Estado=1;
