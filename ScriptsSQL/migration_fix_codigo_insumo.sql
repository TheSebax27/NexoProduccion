-- Corrige el codigo de Insumo en Catalogo.TiposArticulo para que coincida con
-- el codigo que usa Visions (TIPOPRODUCTO_TIPOS.Codigo = 'IN').
-- Sin este fix, los articulos tipo Insumo llegan a Visions como "Producto Terminado"
-- porque la busqueda WHERE Codigo = 'INS' no encuentra nada en Visions.
-- Ejecutar UNA sola vez en NEXO_ERP.

UPDATE Catalogo.TiposArticulo
SET    Codigo = 'IN'
WHERE  Codigo = 'INS';
