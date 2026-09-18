-- migration_fanout_articulos_visions.sql
-- Fan-out masivo: propaga todos los articulos ya mapeados en cualquier CentroCosto Visions
-- a todos los demas CentroCostos Visions que aun no los tienen.
-- EJECUTAR en nexoVisions (45.171.180.182\VISIONS, BD nexoVisions).
-- Seguro relanzar: NOT EXISTS en ambos INSERT evita duplicados.
-- El agente de cada punto procesa los eventos en su proximo ciclo.

BEGIN TRANSACTION;

-- Paso 1: Crear mapeos para CentroCostos Visions que no tienen el articulo mapeado aun.
-- Usa el mismo CodigoArticuloVisions (REFERENCIA) que el CC origen.
INSERT INTO Integracion.MapeoArticulos
    (ArticuloID, CentroCostoID, CodigoArticuloVisions, Estado, FechaCreacion)
SELECT
    ma_origen.ArticuloID,
    cc_destino.CentroCostoID,
    ma_origen.CodigoArticuloVisions,
    1,
    GETDATE()
FROM Integracion.MapeoArticulos ma_origen
JOIN Catalogo.Tarjetas t ON t.ArticuloID = ma_origen.ArticuloID
JOIN Organizacion.CentrosCosto cc_origen  ON cc_origen.CentroCostoID  = ma_origen.CentroCostoID
JOIN Organizacion.CentrosCosto cc_destino ON cc_destino.TieneVisions   = 1
WHERE cc_origen.TieneVisions = 1
  AND ma_origen.Estado = 1
  AND cc_destino.CentroCostoID <> ma_origen.CentroCostoID
  AND NOT EXISTS (
      SELECT 1 FROM Integracion.MapeoArticulos ma2
      WHERE ma2.ArticuloID    = ma_origen.ArticuloID
        AND ma2.CentroCostoID = cc_destino.CentroCostoID);

DECLARE @MapeoInsertados INT = @@ROWCOUNT;

-- Paso 2: Generar eventos SINCRONIZAR_ARTICULO para cada CC destino
-- que no tenga ya un evento pendiente/confirmado para ese articulo.
INSERT INTO Integracion.EventosSalientes
    (TipoEvento, CentroCostoID, ArticuloID, Cantidad, CostoUnitario)
SELECT
    'SINCRONIZAR_ARTICULO',
    ma.CentroCostoID,
    ma.ArticuloID,
    0,
    ISNULL(t.CostoPromedio, 0)
FROM Integracion.MapeoArticulos ma
JOIN Catalogo.Tarjetas t          ON t.ArticuloID     = ma.ArticuloID
JOIN Organizacion.CentrosCosto cc ON cc.CentroCostoID = ma.CentroCostoID
WHERE cc.TieneVisions = 1
  AND ma.Estado = 1
  AND NOT EXISTS (
      SELECT 1 FROM Integracion.EventosSalientes e
      WHERE e.ArticuloID    = ma.ArticuloID
        AND e.CentroCostoID = ma.CentroCostoID
        AND e.TipoEvento    = 'SINCRONIZAR_ARTICULO'
        AND e.Estado IN ('PENDIENTE', 'CONFIRMADO'))
  -- Solo generar para CentroCostos que recibieron mapeo recien o que nunca tuvieron evento
  AND EXISTS (
      SELECT 1 FROM Integracion.MapeoArticulos ma_check
      WHERE ma_check.ArticuloID    = ma.ArticuloID
        AND ma_check.CentroCostoID = ma.CentroCostoID
        AND ma_check.Estado = 1);

DECLARE @EventosInsertados INT = @@ROWCOUNT;

COMMIT TRANSACTION;

SELECT
    @MapeoInsertados  AS MapeoArticulosCreados,
    @EventosInsertados AS EventosSalientesCreados;
