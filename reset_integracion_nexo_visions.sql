-- ================================================================
-- RESET INTEGRACIÓN NEXO_ERP
-- Borra todos los datos sincronizados desde Visions y deja NEXO
-- limpio para re-sincronizar desde cero.
--
-- EJECUTAR (solo contra NEXO_ERP con Windows Auth):
--   sqlcmd -S .\JONATHAN -d NEXO_ERP -E -i "C:\Produccion\reset_integracion_nexo_visions.sql"
--
-- Para resetear Visions: restaurar el backup de visionsdbl1 directamente.
-- ================================================================

IF DB_NAME() <> 'NEXO_ERP'
BEGIN
    RAISERROR('Este script solo debe ejecutarse contra NEXO_ERP. BD actual: %s', 16, 1, DB_NAME());
    RETURN;
END

PRINT 'Limpiando NEXO_ERP...';

BEGIN TRANSACTION;

-- 1. Eventos de integración (entrada y salida)
DELETE FROM Integracion.EventosEntrantes;
PRINT '  EventosEntrantes borrados.';

DELETE FROM Integracion.EventosSalientes;
PRINT '  EventosSalientes borrados.';

-- 2. Inventario reportado desde Visions (acumulado de ventas)
DELETE FROM Integracion.InventarioReportadoVisions;
PRINT '  InventarioReportadoVisions borrado.';

-- 3. Artículos pendientes de mapeo
DELETE FROM Integracion.ArticulosPendientesMapeo;
PRINT '  ArticulosPendientesMapeo borrado.';

-- 4. Stock en bodegas de artículos que vinieron de Visions
DELETE ist
FROM Inventario.InventarioStock ist
JOIN Integracion.MapeoArticulos ma ON ma.ArticuloID = ist.ArticuloID;
PRINT '  InventarioStock borrado.';

-- 5. Mapeos de artículos
DELETE FROM Integracion.MapeoArticulos;
PRINT '  MapeoArticulos borrado.';

-- 6. Artículos sincronizados desde Visions
DELETE FROM Catalogo.Tarjetas;
PRINT '  Catalogo.Tarjetas borrado.';

-- 7. Clientes sincronizados desde Visions
DELETE FROM Crm.Clientes;
PRINT '  Crm.Clientes borrado.';

-- 8. Catálogos creados por la integración (Marcas, Grupos, Presentaciones)
DELETE FROM Catalogo.Marca;
PRINT '  Catalogo.Marca borrado.';
DELETE FROM Catalogo.GrupoMenor;
PRINT '  Catalogo.GrupoMenor borrado.';
DELETE FROM Catalogo.GrupoMayor;
PRINT '  Catalogo.GrupoMayor borrado.';
DELETE FROM Catalogo.Presentacion;
PRINT '  Catalogo.Presentacion borrado.';

COMMIT;
PRINT 'NEXO_ERP limpio. ✓';
PRINT 'Para resetear Visions: restaurar el backup de visionsdbl1.';
