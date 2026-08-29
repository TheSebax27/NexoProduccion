-- Agrega CentroCostoID a Compras.OrdenesCompra para identificar a que area
-- va destinada la compra.
-- Ejecutar UNA sola vez en NEXO_ERP.

ALTER TABLE Compras.OrdenesCompra
    ADD CentroCostoID INT NULL
        CONSTRAINT FK_OrdenesCompra_CentroCosto
            FOREIGN KEY REFERENCES Organizacion.CentrosCosto(CentroCostoID);
