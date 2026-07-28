/* ============================================================================
   SISTEMA NEXO - Script 02: Datos Maestros / Parametrizacion Inicial
   Ejecutar despues de 01_estructura_base.sql
   ============================================================================ */
USE NEXO_ERP;
GO

-- ----------------------------------------------------------------------------
-- ROLES BASE
-- ----------------------------------------------------------------------------
INSERT INTO Seguridad.Roles (Nombre, Descripcion) VALUES
('Administrador',       'Acceso total al sistema'),
('SupervisorPlanta',     'Gestiona ordenes de produccion, recetas y libera OP'),
('Bodeguero',            'Gestiona inventario, kardex, bajas y traspasos'),
('Operario',             'Ejecuta y reporta consumo real en ordenes de produccion');
GO

-- ----------------------------------------------------------------------------
-- PERMISOS (catalogo inicial - ampliable sin tocar codigo)
-- ----------------------------------------------------------------------------
INSERT INTO Seguridad.Permisos (Codigo, Modulo, Descripcion) VALUES
('PRODUCCION.CREAR_OP',        'PRODUCCION', 'Crear ordenes de produccion'),
('PRODUCCION.LIBERAR_OP',      'PRODUCCION', 'Liberar ordenes de produccion'),
('PRODUCCION.CERRAR_OP',       'PRODUCCION', 'Cerrar / finalizar ordenes de produccion'),
('PRODUCCION.EDITAR_RECETA',   'PRODUCCION', 'Crear y modificar recetas BOM'),
('INVENTARIO.VER_STOCK',       'INVENTARIO', 'Consultar stock e inventario'),
('INVENTARIO.REGISTRAR_BAJA',  'INVENTARIO', 'Registrar bajas por merma/dano'),
('INVENTARIO.TRASPASO_ENVIAR', 'INVENTARIO', 'Enviar traspasos entre bodegas/sucursales'),
('INVENTARIO.TRASPASO_RECIBIR','INVENTARIO', 'Recibir traspasos'),
('COMPRAS.CREAR_OC',           'COMPRAS',    'Crear ordenes de compra'),
('COMPRAS.RECIBIR_OC',         'COMPRAS',    'Recibir mercancia de compras'),
('SEGURIDAD.GESTIONAR_USUARIOS','SEGURIDAD', 'Alta, baja y edicion de usuarios y roles'),
('DASHBOARD.VER',              'DASHBOARD',  'Visualizar dashboard e indicadores');
GO

-- Asignacion tipica de permisos por rol
INSERT INTO Seguridad.RolPermisos (RolID, PermisoID)
SELECT r.RolID, p.PermisoID
FROM Seguridad.Roles r CROSS JOIN Seguridad.Permisos p
WHERE r.Nombre = 'Administrador';

INSERT INTO Seguridad.RolPermisos (RolID, PermisoID)
SELECT r.RolID, p.PermisoID FROM Seguridad.Roles r, Seguridad.Permisos p
WHERE r.Nombre = 'SupervisorPlanta' AND p.Codigo IN
('PRODUCCION.CREAR_OP','PRODUCCION.LIBERAR_OP','PRODUCCION.CERRAR_OP','PRODUCCION.EDITAR_RECETA','INVENTARIO.VER_STOCK','DASHBOARD.VER');

INSERT INTO Seguridad.RolPermisos (RolID, PermisoID)
SELECT r.RolID, p.PermisoID FROM Seguridad.Roles r, Seguridad.Permisos p
WHERE r.Nombre = 'Bodeguero' AND p.Codigo IN
('INVENTARIO.VER_STOCK','INVENTARIO.REGISTRAR_BAJA','INVENTARIO.TRASPASO_ENVIAR','INVENTARIO.TRASPASO_RECIBIR','COMPRAS.RECIBIR_OC','DASHBOARD.VER');

INSERT INTO Seguridad.RolPermisos (RolID, PermisoID)
SELECT r.RolID, p.PermisoID FROM Seguridad.Roles r, Seguridad.Permisos p
WHERE r.Nombre = 'Operario' AND p.Codigo IN ('INVENTARIO.VER_STOCK');
GO

-- ----------------------------------------------------------------------------
-- TIPOS DE ARTICULO
-- ----------------------------------------------------------------------------
INSERT INTO Catalogo.TiposArticulo (Codigo, Nombre) VALUES
('MP',      'Materia Prima'),
('INSUMO',  'Insumo'),
('PT',      'Producto Terminado'),
('SUBPROD', 'Subproducto'),
('EMPAQUE', 'Material de Empaque');
GO

-- ----------------------------------------------------------------------------
-- UNIDADES DE MEDIDA
-- ----------------------------------------------------------------------------
INSERT INTO Catalogo.UnidadesMedida (Nombre, Abreviatura, Tipo) VALUES
('Kilogramo', 'KG', 'PESO'),
('Gramo',     'G',  'PESO'),
('Litro',     'L',  'VOLUMEN'),
('Mililitro', 'ML', 'VOLUMEN'),
('Unidad',    'UN', 'UNIDAD'),
('Bolsa',     'BOL','UNIDAD'),
('Metro',     'M',  'LONGITUD');
GO

-- Conversiones basicas (1 origen = Factor destino)
INSERT INTO Catalogo.UnidadesConversion (UnidadOrigenID, UnidadDestinoID, Factor)
SELECT u1.UnidadID, u2.UnidadID, 1000
FROM Catalogo.UnidadesMedida u1, Catalogo.UnidadesMedida u2
WHERE u1.Abreviatura='KG' AND u2.Abreviatura='G';

INSERT INTO Catalogo.UnidadesConversion (UnidadOrigenID, UnidadDestinoID, Factor)
SELECT u1.UnidadID, u2.UnidadID, 0.001
FROM Catalogo.UnidadesMedida u1, Catalogo.UnidadesMedida u2
WHERE u1.Abreviatura='G' AND u2.Abreviatura='KG';

INSERT INTO Catalogo.UnidadesConversion (UnidadOrigenID, UnidadDestinoID, Factor)
SELECT u1.UnidadID, u2.UnidadID, 1000
FROM Catalogo.UnidadesMedida u1, Catalogo.UnidadesMedida u2
WHERE u1.Abreviatura='L' AND u2.Abreviatura='ML';

INSERT INTO Catalogo.UnidadesConversion (UnidadOrigenID, UnidadDestinoID, Factor)
SELECT u1.UnidadID, u2.UnidadID, 0.001
FROM Catalogo.UnidadesMedida u1, Catalogo.UnidadesMedida u2
WHERE u1.Abreviatura='ML' AND u2.Abreviatura='L';
GO

-- ----------------------------------------------------------------------------
-- TIPOS DE PRODUCCION
-- ----------------------------------------------------------------------------
INSERT INTO Produccion.TiposProduccion (Codigo, Nombre, Descripcion) VALUES
('MTO',            'Produccion por Pedido (Cliente)',        'Orden vinculada a un cliente especifico'),
('MTS_MASA',       'Produccion General / Masa (Planta Central)', 'Lote grande para distribuir a varios puntos'),
('MTS_REPOSICION', 'Reposicion Especifica por Punto de Venta',  'Orden dedicada a un centro de costo puntual');
GO

-- ----------------------------------------------------------------------------
-- ESTADOS DE ORDEN DE PRODUCCION
-- ----------------------------------------------------------------------------
INSERT INTO Produccion.EstadosOP (Nombre, Orden) VALUES
('Planificada', 1),
('Liberada',    2),
('En Proceso',  3),
('Finalizada',  4),
('Cancelada',   5);
GO

-- ----------------------------------------------------------------------------
-- MOTIVOS DE EXCESO DE CONSUMO
-- ----------------------------------------------------------------------------
INSERT INTO Produccion.MotivosExcesoConsumo (Nombre) VALUES
('Ajuste por humedad de la materia prima'),
('Merma normal del proceso superior a lo estandar'),
('Error de pesaje / dosificacion'),
('Reproceso por falla de calidad');
GO

-- ----------------------------------------------------------------------------
-- TIPOS DE MOVIMIENTO KARDEX
-- ----------------------------------------------------------------------------
INSERT INTO Kardex.TiposMovimientoKardex (Codigo, Nombre, Signo) VALUES
('ENTRADA_COMPRA',    'Entrada por Compra',                 1),
('SALIDA_WIP',        'Salida a Produccion (WIP)',          -1),
('ENTRADA_PT',        'Entrada de Producto Terminado',       1),
('BAJA_MERMA',        'Baja por Merma / Dano Accidental',   -1),
('TRASPASO_SALIDA',   'Salida por Traspaso a otro Centro',  -1),
('TRASPASO_ENTRADA',  'Entrada por Traspaso de otro Centro', 1),
('AJUSTE_POSITIVO',   'Ajuste Manual Positivo',              1),
('AJUSTE_NEGATIVO',   'Ajuste Manual Negativo',             -1);
GO

-- ----------------------------------------------------------------------------
-- MOTIVOS DE PERDIDA (BAJAS)
-- ----------------------------------------------------------------------------
INSERT INTO Kardex.TiposMotivoLoss (Nombre) VALUES
('Dano Fisico / Empaque Roto'),
('Vencimiento'),
('Humedad / Contaminacion'),
('Error de Manipulacion');
GO

PRINT 'Datos maestros insertados correctamente.';