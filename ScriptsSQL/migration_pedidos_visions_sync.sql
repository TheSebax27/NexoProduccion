-- Agrega columnas necesarias para sync Pedidos NEXO → Visions Entradas.
-- Ejecutar UNA sola vez en NEXO_ERP.

ALTER TABLE Compras.OrdenesCompra
    ADD ExportadoVisions  BIT           NOT NULL DEFAULT 0,
        NroDocVisions     NVARCHAR(50)  NULL,
        TipDocVisions     NVARCHAR(20)  NULL,
        TipoMovimiento    NVARCHAR(20)  NOT NULL DEFAULT 'COMPRA';
-- TipoMovimiento: 'COMPRA' (entrada normal) | 'DEVOLUCION' (devolución al proveedor → salida de inventario)
