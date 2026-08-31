-- migration_pendientes_limpieza_visions.sql
-- Tabla para encolar facturas/pedidos eliminados en NEXO que el agente debe
-- limpiar del staging de Visions (NEXO_FacturasPendientes / NEXO_PedidosLineas).

IF NOT EXISTS (
    SELECT 1 FROM sys.tables t
    JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE s.name = 'Integracion' AND t.name = 'PendientesLimpiezaVisions'
)
BEGIN
    CREATE TABLE Integracion.PendientesLimpiezaVisions (
        LimpiezaID  INT           IDENTITY(1,1) NOT NULL PRIMARY KEY,
        Tipo        NVARCHAR(20)  NOT NULL,   -- 'FACTURA' | 'PEDIDO'
        EntidadID   INT           NOT NULL,   -- FacturaID o PedidoID
        FechaRegistro DATETIME    NOT NULL DEFAULT GETDATE()
    );
    PRINT 'Tabla Integracion.PendientesLimpiezaVisions creada.';
END
ELSE
    PRINT 'Tabla ya existe, sin cambios.';
