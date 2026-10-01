using Dapper;
using NexoSyncAgent.VisionsData;

namespace NexoSyncAgent.Tareas;

// Corre UNA SOLA VEZ al arrancar el agente (ver Worker.cs).
// Crea las tablas NEXO_* y triggers en la base de Visions si no existen.
// No toca ninguna tabla existente de Visions -- solo CREATE IF NOT EXISTS.
public class TareaInicializarVisions
{
    private readonly IVisionsConnectionFactory _visionsDb;
    private readonly ILogger<TareaInicializarVisions> _logger;

    public TareaInicializarVisions(IVisionsConnectionFactory visionsDb, ILogger<TareaInicializarVisions> logger)
    {
        _visionsDb = visionsDb;
        _logger = logger;
    }

    public async Task EjecutarAsync(CancellationToken ct = default)
    {
        try
        {
            using var connection = _visionsDb.CreateConnection();

            await connection.ExecuteAsync(@"
                IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NEXO_ConfiguracionSync')
                CREATE TABLE dbo.NEXO_ConfiguracionSync (
                    CENTROCOSTO          INT           NOT NULL PRIMARY KEY,
                    Activo               BIT           NOT NULL DEFAULT 1,
                    TiposDocumentoVenta  NVARCHAR(500) NULL
                );");

            await connection.ExecuteAsync(@"
                IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NEXO_VentasExportadas')
                CREATE TABLE dbo.NEXO_VentasExportadas (
                    CENTROCOSTO  INT           NOT NULL,
                    TIPDOC       NVARCHAR(20)  NOT NULL,
                    NRODOC       NVARCHAR(50)  NOT NULL,
                    ORDEN        INT           NOT NULL,
                    REFERENCIA   NVARCHAR(30)  NOT NULL,
                    CANTIDAD     DECIMAL(18,4) NOT NULL,
                    CONSTRAINT PK_NEXO_VentasExportadas PRIMARY KEY (CENTROCOSTO, TIPDOC, NRODOC, ORDEN, REFERENCIA)
                );");

            await connection.ExecuteAsync(@"
                IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NEXO_EntradasExportadas')
                CREATE TABLE dbo.NEXO_EntradasExportadas (
                    CENTROCOSTO  INT           NOT NULL,
                    TIPDOC       NVARCHAR(20)  NOT NULL,
                    NRODOC       NVARCHAR(50)  NOT NULL,
                    ORDEN        INT           NOT NULL,
                    REFERENCIA   NVARCHAR(30)  NOT NULL,
                    CANTIDAD     DECIMAL(18,4) NOT NULL,
                    CONSTRAINT PK_NEXO_EntradasExportadas PRIMARY KEY (CENTROCOSTO, TIPDOC, NRODOC, ORDEN, REFERENCIA)
                );");

            await connection.ExecuteAsync(@"
                IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NEXO_EntradasInventario')
                CREATE TABLE dbo.NEXO_EntradasInventario (
                    Id              BIGINT        NOT NULL IDENTITY PRIMARY KEY,
                    IdEventoOrigen  BIGINT        NOT NULL,
                    CENTROCOSTO     INT           NOT NULL,
                    REFERENCIA      NVARCHAR(30)  NOT NULL,
                    CANTIDAD        DECIMAL(18,4) NOT NULL,
                    COSTO           DECIMAL(18,4) NOT NULL DEFAULT 0,
                    Aplicado        BIT           NOT NULL DEFAULT 1,
                    FechaAplicado   DATETIME      NOT NULL DEFAULT GETDATE()
                );");

            // Cambios en TARJETA de Visions para sincronizar de vuelta a NEXO.
            await connection.ExecuteAsync(@"
                IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NEXO_TarjetasCambios')
                CREATE TABLE dbo.NEXO_TarjetasCambios (
                    Id          BIGINT        NOT NULL IDENTITY PRIMARY KEY,
                    CENTROCOSTO INT           NOT NULL,
                    REFERENCIA  NVARCHAR(30)  NOT NULL,
                    DETALLE     NVARCHAR(200) NULL,
                    COSTO       DECIMAL(18,4) NULL,
                    PPUBLICO    DECIMAL(18,4) NULL,
                    VV3         SMALLINT      NULL,
                    FechaCambio DATETIME      NOT NULL DEFAULT GETDATE(),
                    Procesado   BIT           NOT NULL DEFAULT 0
                );");

            // Agregar columna VV3 si la tabla ya existia sin ella (migracion).
            await connection.ExecuteAsync(@"
                IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
                               WHERE TABLE_NAME = 'NEXO_TarjetasCambios' AND COLUMN_NAME = 'VV3')
                    ALTER TABLE dbo.NEXO_TarjetasCambios ADD VV3 SMALLINT NULL;");

            // Trigger: captura cambios de precio/nombre en TARJETA originados en Visions POS.
            // APP_NAME()='NexoSyncAgent' identifica conexiones del agente (VisionsConnectionFactory
            // fuerza este nombre). Compatible con SQL Server 2008+.
            // MERGE upserta para que si hay un cambio sin procesar no acumule filas duplicadas.
            // CREATE OR ALTER requiere SQL 2016+; usamos stub+ALTER para compatibilidad.
            await connection.ExecuteAsync(@"
                IF OBJECT_ID('dbo.TR_TARJETA_NexoCambios', 'TR') IS NULL
                    EXEC('CREATE TRIGGER dbo.TR_TARJETA_NexoCambios ON dbo.TARJETA AFTER UPDATE AS SELECT 1')");
            try
            {
            await connection.ExecuteAsync(@"
                ALTER TRIGGER dbo.TR_TARJETA_NexoCambios ON dbo.TARJETA AFTER UPDATE
                AS
                BEGIN
                    SET NOCOUNT ON;
                    IF APP_NAME() = 'NexoSyncAgent' RETURN;
                    MERGE dbo.NEXO_TarjetasCambios AS destino
                    USING (
                        SELECT i.CENTROCOSTO, i.REFERENCIA, i.DETALLE, i.COSTO, i.PPUBLICO,
                               CAST(i.VV3 AS SMALLINT) AS VV3, GETDATE() AS FechaCambio
                        FROM inserted i
                    ) AS origen
                    ON destino.CENTROCOSTO = origen.CENTROCOSTO
                       AND destino.REFERENCIA = origen.REFERENCIA
                       AND destino.Procesado = 0
                    WHEN MATCHED THEN UPDATE SET
                        DETALLE = origen.DETALLE, COSTO = origen.COSTO,
                        PPUBLICO = origen.PPUBLICO, VV3 = origen.VV3, FechaCambio = origen.FechaCambio
                    WHEN NOT MATCHED THEN
                        INSERT (CENTROCOSTO, REFERENCIA, DETALLE, COSTO, PPUBLICO, VV3, FechaCambio, Procesado)
                        VALUES (origen.CENTROCOSTO, origen.REFERENCIA, origen.DETALLE, origen.COSTO,
                                origen.PPUBLICO, origen.VV3, origen.FechaCambio, 0);
                END");
            }
            catch (Exception exTrigger)
            {
                // El trigger queda como stub "SELECT 1" — el flujo Visions→NEXO no funcionara
                // hasta que el permiso DDL sea otorgado. El resto de la inicializacion continua.
                _logger.LogError(exTrigger,
                    "No se pudo crear/actualizar TR_TARJETA_NexoCambios. " +
                    "Los cambios de precio/nombre en Visions NO se sincronizaran a NEXO. " +
                    "Verificar que el usuario de BD tiene permisos ALTER TRIGGER.");
            }

            // Rastreo de facturas confirmadas por Visions que ya se sincronizaron de vuelta a NEXO.
            // Se usa como dedup: si FechaSyncBack no es NULL, ya fue procesada y no se repite.
            await connection.ExecuteAsync(@"
                IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NEXO_FacturasSalientes')
                CREATE TABLE dbo.NEXO_FacturasSalientes (
                    FacturaID     INT          NOT NULL,
                    NexoNroDoc    VARCHAR(50)  NOT NULL,
                    TipDocVisions VARCHAR(20)  NULL,
                    NroDocVisions VARCHAR(50)  NULL,
                    FechaEnvio    DATETIME     NOT NULL DEFAULT GETDATE(),
                    FechaSyncBack DATETIME     NULL,
                    CONSTRAINT PK_NEXO_FacturasSalientes PRIMARY KEY (FacturaID)
                );");

            // Eliminar el trigger obsoleto del flujo viejo (escribia en NEXO_FacturasSalientes
            // cuando Visions cambiaba NRODOC de 'NEXO-{ID}' al número real). Ya no se usa:
            // el nuevo flujo usa NEXO_SP_ConfirmarFactura que Visions llama explicitamente.
            await connection.ExecuteAsync(@"
                IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'trg_NEXO_ActualizarFacturaSaliente')
                    DROP TRIGGER dbo.trg_NEXO_ActualizarFacturaSaliente;");

            // SP ACTUALIZARTARJETA: asegura que el WHERE use parámetros (@CENTROCOSTO, @REFERENCIA)
            // y no columnas sin prefijo (bug original que sobreescribía TODA la tabla en cada sync).
            await connection.ExecuteAsync(@"
                IF OBJECT_ID('dbo.ACTUALIZARTARJETA', 'P') IS NULL
                    EXEC('CREATE PROCEDURE dbo.ACTUALIZARTARJETA AS SELECT 1')");
            await connection.ExecuteAsync(@"
                ALTER PROCEDURE [dbo].ACTUALIZARTARJETA
                (
                    @CENTROCOSTO smallint, @REFERENCIA nchar(30), @DETALLE nchar(255), @MARCA nchar(10),
                    @COSTO numeric(18,0), @GRUPOMENOR nchar(10), @BARRAS nchar(30),
                    @IVASINO nchar(2), @IVAVALOR smallint,
                    @EXISTENCIAS numeric(18,0), @EXISTENCIASMINIMAS numeric(18,0),
                    @FRACCIONES numeric(18,0), @CANTIDAD numeric(18,0),
                    @PRESENTACION nchar(10), @VALORIZADO numeric(18,0),
                    @PPUBLICO numeric(18,0), @PBODEGA numeric(18,0), @PCREDITO numeric(18,0),
                    @UPUBLICO numeric(18,2), @UBODEGA numeric(18,2), @UCREDITO numeric(18,2),
                    @FRACCIONA nchar(1),
                    @VF1 numeric(18,0), @VV1 numeric(18,0), @VF2 numeric(18,0), @VV2 numeric(18,0),
                    @VF3 numeric(18,0), @VV3 numeric(18,0), @VF4 numeric(18,0), @VV4 numeric(18,0),
                    @TIPOTARJETA nchar(12),
                    @ROTA1 numeric(18,0), @ROTA2 numeric(18,0), @SUGERIDO numeric(18,0),
                    @FISICOE numeric(18,0), @FISICOF numeric(18,0), @COMBO numeric(18,0),
                    @FULTV date, @FULTC date, @REVISAR nchar(10), @NOTA ntext,
                    @PESO numeric(18,2), @DFI date, @DFF date,
                    @DPO smallint, @DVA numeric(18,0), @PESAR nchar(2)
                )
                AS
                SET NOCOUNT OFF;
                UPDATE [dbo].[TARJETA] SET
                    [CENTROCOSTO]=@CENTROCOSTO,
                    [DETALLE]=ISNULL(@DETALLE,''),
                    [MARCA]=ISNULL(@MARCA,''),
                    [COSTO]=ISNULL(@COSTO,0),
                    [GRUPOMENOR]=ISNULL(@GRUPOMENOR,''),
                    [BARRAS]=ISNULL(@BARRAS,''),
                    [IVASINO]=ISNULL(@IVASINO,'SI'),
                    [IVAVALOR]=ISNULL(@IVAVALOR,19),
                    [EXISTENCIAS]=ISNULL(@EXISTENCIAS,0),
                    [EXISTENCIASMINIMAS]=ISNULL(@EXISTENCIASMINIMAS,0),
                    [FRACCIONES]=ISNULL(@FRACCIONES,0),
                    [CANTIDAD]=ISNULL(@CANTIDAD,0),
                    [PRESENTACION]=ISNULL(@PRESENTACION,''),
                    [VALORIZADO]=ISNULL(@VALORIZADO,0),
                    [PPUBLICO]=ISNULL(@PPUBLICO,0),
                    [PBODEGA]=ISNULL(@PBODEGA,0),
                    [PCREDITO]=ISNULL(@PCREDITO,0),
                    [UPUBLICO]=ISNULL(@UPUBLICO,0),
                    [UBODEGA]=ISNULL(@UBODEGA,0),
                    [UCREDITO]=ISNULL(@UCREDITO,0),
                    [FRACCIONA]=ISNULL(@FRACCIONA,''),
                    [VF1]=ISNULL(@VF1,0), [VV1]=ISNULL(@VV1,0),
                    [VF2]=ISNULL(@VF2,0), [VV2]=ISNULL(@VV2,0),
                    [VF3]=ISNULL(@VF3,0), [VV3]=ISNULL(@VV3,0),
                    [VF4]=ISNULL(@VF4,0), [VV4]=ISNULL(@VV4,0),
                    [TIPOTARJETA]=ISNULL(@TIPOTARJETA,''),
                    [ROTA1]=ISNULL(@ROTA1,0), [ROTA2]=ISNULL(@ROTA2,0),
                    [SUGERIDO]=ISNULL(@SUGERIDO,0),
                    [FISICOE]=ISNULL(@FISICOE,0), [FISICOF]=ISNULL(@FISICOF,0),
                    [COMBO]=ISNULL(@COMBO,0),
                    [FULTV]=ISNULL(@FULTV,'2000-01-01'),
                    [FULTC]=ISNULL(@FULTC,'2000-01-01'),
                    [REVISAR]=ISNULL(@REVISAR,''),
                    [NOTA]=ISNULL(@NOTA,N''),
                    [PESO]=ISNULL(@PESO,0),
                    [DFI]=ISNULL(@DFI,'2000-01-01'),
                    [DFF]=ISNULL(@DFF,'2099-12-31'),
                    [DPO]=ISNULL(@DPO,0),
                    [DVA]=ISNULL(@DVA,0),
                    [PESAR]=ISNULL(@PESAR,'')
                WHERE [CENTROCOSTO] = @CENTROCOSTO AND [REFERENCIA] = @REFERENCIA");

            // Tabla de tipos de producto (igual que en NEXO). Se guarda TipoID en TARJETA.VV3.
            await connection.ExecuteAsync(@"
                IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'TIPOPRODUCTO_TIPOS')
                BEGIN
                    CREATE TABLE dbo.TIPOPRODUCTO_TIPOS (
                        TipoID smallint      NOT NULL CONSTRAINT PK_TIPOPRODUCTO_TIPOS PRIMARY KEY,
                        Codigo nvarchar(10)  NOT NULL,
                        Nombre nvarchar(100) NOT NULL
                    );
                    INSERT INTO dbo.TIPOPRODUCTO_TIPOS VALUES (1, 'PT', 'Producto Terminado');
                    INSERT INTO dbo.TIPOPRODUCTO_TIPOS VALUES (2, 'MP', 'Materia Prima');
                    INSERT INTO dbo.TIPOPRODUCTO_TIPOS VALUES (3, 'IN', 'Insumo');
                    INSERT INTO dbo.TIPOPRODUCTO_TIPOS VALUES (4, 'SER', 'Servicio');
                END");

            // Migracion: corregir codigo SV->SER en bases ya existentes.
            await connection.ExecuteAsync(@"
                IF EXISTS (SELECT 1 FROM dbo.TIPOPRODUCTO_TIPOS WHERE Codigo = 'SV')
                    UPDATE dbo.TIPOPRODUCTO_TIPOS SET Codigo = 'SER' WHERE Codigo = 'SV'");

            // Staging de facturas NEXO pendientes de ser procesadas en Visions.
            await connection.ExecuteAsync(@"
                IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NEXO_FacturasPendientes')
                CREATE TABLE dbo.NEXO_FacturasPendientes (
                    FacturaID       INT           NOT NULL CONSTRAINT PK_NEXO_FacturasPendientes PRIMARY KEY,
                    NIT             NVARCHAR(30)  NOT NULL,
                    NombreCliente   NVARCHAR(200) NOT NULL,
                    Fecha           DATE          NOT NULL,
                    TipDoc          NVARCHAR(20)  NOT NULL,
                    TotalNexo       DECIMAL(18,4) NOT NULL DEFAULT 0,
                    Estado          NVARCHAR(20)  NOT NULL DEFAULT 'PENDIENTE',
                    FechaEnvio      DATETIME      NOT NULL DEFAULT GETDATE(),
                    NroDocVisions   NVARCHAR(50)  NULL,
                    TipDocVisions   NVARCHAR(20)  NULL,
                    FechaConfirmada DATETIME      NULL
                );");

            await connection.ExecuteAsync(@"
                IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NEXO_FacturasPendientesLineas')
                CREATE TABLE dbo.NEXO_FacturasPendientesLineas (
                    FacturaID      INT           NOT NULL,
                    Orden          INT           NOT NULL,
                    Referencia     NVARCHAR(30)  NOT NULL,
                    Detalle        NVARCHAR(255) NULL,
                    Cantidad       DECIMAL(18,4) NOT NULL DEFAULT 0,
                    PrecioUnitario DECIMAL(18,4) NOT NULL DEFAULT 0,
                    Total          DECIMAL(18,4) NOT NULL DEFAULT 0,
                    CONSTRAINT PK_NEXO_FacturasPendientesLineas PRIMARY KEY (FacturaID, Orden)
                );");

            // SP: lista facturas PENDIENTE con dos resultsets (cabeceras + líneas).
            await connection.ExecuteAsync(@"
                IF OBJECT_ID('dbo.NEXO_SP_FacturasPendientes', 'P') IS NULL
                    EXEC('CREATE PROCEDURE dbo.NEXO_SP_FacturasPendientes AS SELECT 1')");
            await connection.ExecuteAsync(@"
                ALTER PROCEDURE dbo.NEXO_SP_FacturasPendientes
                AS
                BEGIN
                    SET NOCOUNT ON;
                    SELECT FacturaID, NIT, NombreCliente, Fecha, TipDoc, TotalNexo, FechaEnvio
                    FROM dbo.NEXO_FacturasPendientes
                    WHERE Estado = 'PENDIENTE'
                    ORDER BY Fecha, FacturaID;

                    SELECT l.FacturaID, l.Orden, l.Referencia, l.Detalle, l.Cantidad, l.PrecioUnitario, l.Total
                    FROM dbo.NEXO_FacturasPendientesLineas l
                    INNER JOIN dbo.NEXO_FacturasPendientes f ON f.FacturaID = l.FacturaID
                    WHERE f.Estado = 'PENDIENTE'
                    ORDER BY l.FacturaID, l.Orden;
                END");

            // SP: Visions llama este SP al confirmar una factura con su número real.
            await connection.ExecuteAsync(@"
                IF OBJECT_ID('dbo.NEXO_SP_ConfirmarFactura', 'P') IS NULL
                    EXEC('CREATE PROCEDURE dbo.NEXO_SP_ConfirmarFactura @FacturaID INT, @NroDocVisions NVARCHAR(50), @TipDocVisions NVARCHAR(20) AS SELECT 1')");
            await connection.ExecuteAsync(@"
                ALTER PROCEDURE dbo.NEXO_SP_ConfirmarFactura
                    @FacturaID     INT,
                    @NroDocVisions NVARCHAR(50),
                    @TipDocVisions NVARCHAR(20)
                AS
                BEGIN
                    SET NOCOUNT ON;
                    UPDATE dbo.NEXO_FacturasPendientes
                    SET Estado          = 'PROCESADA',
                        NroDocVisions   = @NroDocVisions,
                        TipDocVisions   = @TipDocVisions,
                        FechaConfirmada = GETDATE()
                    WHERE FacturaID = @FacturaID;
                END");

            // Staging de pedidos (órdenes de compra) NEXO → Visions Entradas.
            await connection.ExecuteAsync(@"
                IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NEXO_Pedidos')
                CREATE TABLE dbo.NEXO_Pedidos (
                    PedidoID        INT           NOT NULL CONSTRAINT PK_NEXO_Pedidos PRIMARY KEY,
                    Codigo          NVARCHAR(50)  NOT NULL DEFAULT '',
                    NombreProveedor NVARCHAR(200) NOT NULL DEFAULT '',
                    NITProveedor    NVARCHAR(30)  NOT NULL DEFAULT '',
                    Fecha           DATE          NOT NULL,
                    TotalNexo       DECIMAL(18,4) NOT NULL DEFAULT 0,
                    TipoMovimiento  NVARCHAR(20)  NOT NULL DEFAULT 'COMPRA',
                    Estado          NVARCHAR(20)  NOT NULL DEFAULT 'PENDIENTE',
                    FechaEnvio      DATETIME      NOT NULL DEFAULT GETDATE(),
                    NroDocVisions   NVARCHAR(50)  NULL,
                    TipDocVisions   NVARCHAR(20)  NULL,
                    FechaConfirmada DATETIME      NULL
                );");

            await connection.ExecuteAsync(@"
                IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NEXO_PedidosLineas')
                CREATE TABLE dbo.NEXO_PedidosLineas (
                    PedidoID       INT           NOT NULL,
                    Orden          INT           NOT NULL,
                    Referencia     NVARCHAR(30)  NOT NULL,
                    Detalle        NVARCHAR(255) NULL,
                    Cantidad       DECIMAL(18,4) NOT NULL DEFAULT 0,
                    PrecioUnitario DECIMAL(18,4) NOT NULL DEFAULT 0,
                    Total          DECIMAL(18,4) NOT NULL DEFAULT 0,
                    CONSTRAINT PK_NEXO_PedidosLineas PRIMARY KEY (PedidoID, Orden)
                );");

            // SP: lista pedidos PENDIENTE con dos resultsets (cabeceras + líneas).
            await connection.ExecuteAsync(@"
                IF OBJECT_ID('dbo.NEXO_SP_PedidosPendientes', 'P') IS NULL
                    EXEC('CREATE PROCEDURE dbo.NEXO_SP_PedidosPendientes AS SELECT 1')");
            await connection.ExecuteAsync(@"
                ALTER PROCEDURE dbo.NEXO_SP_PedidosPendientes
                AS
                BEGIN
                    SET NOCOUNT ON;
                    SELECT PedidoID, Codigo, NombreProveedor, NITProveedor, Fecha, TotalNexo, TipoMovimiento, FechaEnvio
                    FROM dbo.NEXO_Pedidos
                    WHERE Estado = 'PENDIENTE'
                    ORDER BY Fecha, PedidoID;

                    SELECT l.PedidoID, l.Orden, l.Referencia, l.Detalle, l.Cantidad, l.PrecioUnitario, l.Total
                    FROM dbo.NEXO_PedidosLineas l
                    INNER JOIN dbo.NEXO_Pedidos p ON p.PedidoID = l.PedidoID
                    WHERE p.Estado = 'PENDIENTE'
                    ORDER BY l.PedidoID, l.Orden;
                END");

            // SP: Visions llama este SP al confirmar un pedido con su número de Entrada asignado.
            await connection.ExecuteAsync(@"
                IF OBJECT_ID('dbo.NEXO_SP_ConfirmarPedido', 'P') IS NULL
                    EXEC('CREATE PROCEDURE dbo.NEXO_SP_ConfirmarPedido @PedidoID INT, @NroDocVisions NVARCHAR(50), @TipDocVisions NVARCHAR(20) AS SELECT 1')");
            await connection.ExecuteAsync(@"
                ALTER PROCEDURE dbo.NEXO_SP_ConfirmarPedido
                    @PedidoID      INT,
                    @NroDocVisions NVARCHAR(50),
                    @TipDocVisions NVARCHAR(20)
                AS
                BEGIN
                    SET NOCOUNT ON;
                    UPDATE dbo.NEXO_Pedidos
                    SET Estado          = 'PROCESADA',
                        NroDocVisions   = @NroDocVisions,
                        TipDocVisions   = @TipDocVisions,
                        FechaConfirmada = GETDATE()
                    WHERE PedidoID = @PedidoID;
                END");

            // Parámetros requeridos en Visions para la integración NEXO.
            // 1518 (SINCANTSA): habilita búsqueda de cantidades al grabar salidas.
            // 1905 (NEXO): activa el combo TipoProducto en FRMTARJETA y btn_nexo en FRMVENTAS.
            await connection.ExecuteAsync(@"
                IF NOT EXISTS (SELECT 1 FROM dbo.PARAMETROS WHERE CONSECUTIVO = 1518)
                    INSERT INTO dbo.PARAMETROS (CONSECUTIVO, PARAMETRO, VALOR, DESCRIPCION, TIPOGRUPO)
                    VALUES (1518, 'SINCANTSA', '0', 'BUSCAR CANTIDADES AL GRABAR SALIDAS', 'HABILITAR');

                IF NOT EXISTS (SELECT 1 FROM dbo.PARAMETROS WHERE CONSECUTIVO = 1905)
                    INSERT INTO dbo.PARAMETROS (CONSECUTIVO, PARAMETRO, VALOR, DESCRIPCION, TIPOGRUPO)
                    VALUES (1905, 'NEXO', '1', 'MANEJAN NEXO', 'HABILITAR')
                ELSE IF EXISTS (SELECT 1 FROM dbo.PARAMETROS WHERE CONSECUTIVO = 1905 AND VALOR = '0')
                    UPDATE dbo.PARAMETROS SET VALOR = '1' WHERE CONSECUTIVO = 1905;");

            // Sanear NULLs heredados de versiones anteriores del agente.
            // FechaCambio NULL en NEXO_TarjetasCambios impide que Dapper mapee DateTime y el batch falla.
            var cambiosReparados = await connection.ExecuteAsync(@"
                UPDATE dbo.NEXO_TarjetasCambios
                SET FechaCambio = GETDATE()
                WHERE Procesado = 0 AND FechaCambio IS NULL;");
            if (cambiosReparados > 0)
                _logger.LogWarning("SaneamientoNulls: {N} registros en NEXO_TarjetasCambios tenian FechaCambio NULL — corregidos. Se procesaran en el proximo ciclo.", cambiosReparados);

            // Fechas NULL en TARJETA hacen que Visions no muestre el articulo en ventas/inventario.
            var tarjetasReparadas = await connection.ExecuteAsync(@"
                UPDATE dbo.TARJETA
                SET FULTV = ISNULL(FULTV, '2000-01-01'),
                    FULTC = ISNULL(FULTC, '2000-01-01'),
                    DFI   = ISNULL(DFI,   '2000-01-01'),
                    DFF   = ISNULL(DFF,   '2099-12-31')
                WHERE FULTV IS NULL OR FULTC IS NULL OR DFI IS NULL OR DFF IS NULL;");
            if (tarjetasReparadas > 0)
                _logger.LogWarning("SaneamientoNulls: {N} articulos en TARJETA tenian fechas NULL — corregidos.", tarjetasReparadas);

            _logger.LogInformation("Tablas NEXO_* verificadas/creadas en Visions correctamente");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error al inicializar tablas NEXO_* en Visions. El agente continuara de todas formas");
        }
    }
}
