-- Agrega CentroCostoID a Crm.Cotizaciones para que al convertir a Factura
-- el centro de costo se transfiera automaticamente.
-- Ejecutar UNA sola vez en NEXO_ERP.

ALTER TABLE Crm.Cotizaciones
    ADD CentroCostoID INT NULL
        CONSTRAINT FK_Cotizaciones_CentroCosto
            FOREIGN KEY REFERENCES Organizacion.CentrosCosto(CentroCostoID);
