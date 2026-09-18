-- ============================================================
-- migration_performance_indexes.sql
-- Índices de rendimiento para escalabilidad a millones de filas
-- Ejecutar en NEXO_ERP. Todos usan IF NOT EXISTS (seguros de re-ejecutar).
-- ============================================================

-- -------- Facturacion.FacturaLineas --------
-- El más crítico: casi todo el dashboard hace GROUP BY FacturaID sobre esta tabla.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FacturaLineas_FacturaID' AND object_id = OBJECT_ID('Facturacion.FacturaLineas'))
    CREATE NONCLUSTERED INDEX IX_FacturaLineas_FacturaID
        ON Facturacion.FacturaLineas (FacturaID)
        INCLUDE (ArticuloID, Cantidad, PrecioUnitario);

-- Reportes de ventas por artículo (top productos, historial precios).
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FacturaLineas_ArticuloID' AND object_id = OBJECT_ID('Facturacion.FacturaLineas'))
    CREATE NONCLUSTERED INDEX IX_FacturaLineas_ArticuloID
        ON Facturacion.FacturaLineas (ArticuloID)
        INCLUDE (FacturaID, Cantidad, PrecioUnitario);

-- -------- Facturacion.Facturas --------
-- Consultas CRM y dashboard filtradas por cliente.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Facturas_ClienteID_Fecha' AND object_id = OBJECT_ID('Facturacion.Facturas'))
    CREATE NONCLUSTERED INDEX IX_Facturas_ClienteID_Fecha
        ON Facturacion.Facturas (ClienteID, Fecha DESC)
        INCLUDE (CentroCostoID, TipDoc, NroDoc, StockDescontado);

-- Dashboard ventas por periodo y centro de costo.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Facturas_CentroCosto_Fecha' AND object_id = OBJECT_ID('Facturacion.Facturas'))
    CREATE NONCLUSTERED INDEX IX_Facturas_CentroCosto_Fecha
        ON Facturacion.Facturas (CentroCostoID, Fecha DESC)
        INCLUDE (ClienteID, TipDoc, StockDescontado);

-- -------- Facturacion.Pagos --------
-- Dashboard: subquery GROUP BY FacturaID en Pagos.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Pagos_FacturaID' AND object_id = OBJECT_ID('Facturacion.Pagos'))
    CREATE NONCLUSTERED INDEX IX_Pagos_FacturaID
        ON Facturacion.Pagos (FacturaID)
        INCLUDE (Monto);

-- -------- Crm.Cotizaciones --------
-- CRM: cotizaciones por cliente, estado, vencimiento.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Cotizaciones_ClienteID_Fecha' AND object_id = OBJECT_ID('Crm.Cotizaciones'))
    CREATE NONCLUSTERED INDEX IX_Cotizaciones_ClienteID_Fecha
        ON Crm.Cotizaciones (ClienteID, Fecha DESC)
        INCLUDE (Estado, ValidoHasta, CentroCostoID);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Cotizaciones_Estado_ValidoHasta' AND object_id = OBJECT_ID('Crm.Cotizaciones'))
    CREATE NONCLUSTERED INDEX IX_Cotizaciones_Estado_ValidoHasta
        ON Crm.Cotizaciones (Estado, ValidoHasta)
        INCLUDE (ClienteID, CentroCostoID);

-- -------- Crm.CotizacionLineas --------
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_CotizacionLineas_CotizacionID' AND object_id = OBJECT_ID('Crm.CotizacionLineas'))
    CREATE NONCLUSTERED INDEX IX_CotizacionLineas_CotizacionID
        ON Crm.CotizacionLineas (CotizacionID)
        INCLUDE (ArticuloID, Cantidad, PrecioUnitario);

-- -------- Crm.Clientes --------
-- Dashboard: ClientesNuevos por rango de fechas.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Clientes_FechaCreacion' AND object_id = OBJECT_ID('Crm.Clientes'))
    CREATE NONCLUSTERED INDEX IX_Clientes_FechaCreacion
        ON Crm.Clientes (FechaCreacion DESC);

-- Segmentación automática y reportes por departamento/ciudad.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Clientes_Departamento' AND object_id = OBJECT_ID('Crm.Clientes'))
    CREATE NONCLUSTERED INDEX IX_Clientes_Departamento
        ON Crm.Clientes (Departamento)
        INCLUDE (ClienteID, Nombre, NIT);

-- -------- Crm.Interacciones --------
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Interacciones_ClienteID_Fecha' AND object_id = OBJECT_ID('Crm.Interacciones'))
    CREATE NONCLUSTERED INDEX IX_Interacciones_ClienteID_Fecha
        ON Crm.Interacciones (ClienteID, Fecha DESC);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Interacciones_Fecha' AND object_id = OBJECT_ID('Crm.Interacciones'))
    CREATE NONCLUSTERED INDEX IX_Interacciones_Fecha
        ON Crm.Interacciones (Fecha DESC);

-- -------- Catalogo.Tarjetas --------
-- Búsquedas por Estado (listados paginados filtran por Estado=1).
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Tarjetas_Estado_Nombre' AND object_id = OBJECT_ID('Catalogo.Tarjetas'))
    CREATE NONCLUSTERED INDEX IX_Tarjetas_Estado_Nombre
        ON Catalogo.Tarjetas (Estado, Nombre)
        INCLUDE (ArticuloID, Referencia, TipoArticuloID, PresentacionCodigo, MarcaCodigo, GrupoMenorCodigo);

-- -------- Compras.OrdenesCompra --------
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_OrdenesCompra_Estado_Fecha' AND object_id = OBJECT_ID('Compras.OrdenesCompra'))
    CREATE NONCLUSTERED INDEX IX_OrdenesCompra_Estado_Fecha
        ON Compras.OrdenesCompra (EstadoOC, FechaEmision DESC);

-- -------- Integracion.EventosEntrantes --------
-- La columna CodigoArticuloVisions+CentroCostoID se consulta en lookups de mapeo.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_EventosEntrantes_Articulo_CC' AND object_id = OBJECT_ID('Integracion.EventosEntrantes'))
    CREATE NONCLUSTERED INDEX IX_EventosEntrantes_Articulo_CC
        ON Integracion.EventosEntrantes (CodigoArticuloVisions, CentroCostoID)
        INCLUDE (Cantidad, TipoEvento, Procesado);

-- -------- Integracion.EventosSalientes --------
-- Agente de sync: filtra por (Estado, CentroCostoID) en cada ciclo.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_EventosSalientes_Estado_CC' AND object_id = OBJECT_ID('Integracion.EventosSalientes'))
    CREATE NONCLUSTERED INDEX IX_EventosSalientes_Estado_CC
        ON Integracion.EventosSalientes (Estado, CentroCostoID)
        INCLUDE (EventoID, ArticuloID, TipoEvento, FechaCreacion);

-- -------- Kardex.KardexMovimientos --------
-- Consulta de kardex y dashboard filtran por (Fecha, ArticuloID).
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_KardexMovimientos_Fecha_ArticuloID' AND object_id = OBJECT_ID('Kardex.KardexMovimientos'))
    CREATE NONCLUSTERED INDEX IX_KardexMovimientos_Fecha_ArticuloID
        ON Kardex.KardexMovimientos (Fecha DESC, ArticuloID)
        INCLUDE (BodegaID, TipoMovID, Cantidad, CantidadSaldo);

-- -------- Facturacion.Facturas (VisionsConfirmado) --------
-- IntegracionService filtra por (CentroCostoID, VisionsConfirmado).
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Facturas_CC_VisionsConfirmado' AND object_id = OBJECT_ID('Facturacion.Facturas'))
    CREATE NONCLUSTERED INDEX IX_Facturas_CC_VisionsConfirmado
        ON Facturacion.Facturas (CentroCostoID, VisionsConfirmado)
        INCLUDE (FacturaID, Fecha, NroDoc, TipDoc);

-- -------- Produccion.OrdenesProduccion --------
-- ListarAsync filtra por (EstadoOPID, CentroCostoDestinoID).
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_OrdenesProduccion_Estado_CC' AND object_id = OBJECT_ID('Produccion.OrdenesProduccion'))
    CREATE NONCLUSTERED INDEX IX_OrdenesProduccion_Estado_CC
        ON Produccion.OrdenesProduccion (EstadoOPID, CentroCostoDestinoID)
        INCLUDE (OrdenProduccionID, FechaCreacion, ProductoTerminadoID);

PRINT 'migration_performance_indexes.sql completada correctamente.';
