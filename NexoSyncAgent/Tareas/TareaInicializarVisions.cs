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

    public async Task EjecutarAsync()
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
                    FechaCambio DATETIME      NOT NULL DEFAULT GETDATE(),
                    Procesado   BIT           NOT NULL DEFAULT 0
                );");

            // Trigger: captura cambios de precio/nombre en TARJETA y los encola en NEXO_TarjetasCambios.
            // MERGE upserta para que si hay un cambio sin procesar no acumule filas duplicadas.
            await connection.ExecuteAsync(@"
                CREATE OR ALTER TRIGGER dbo.TR_TARJETA_NexoCambios ON dbo.TARJETA AFTER UPDATE
                AS
                BEGIN
                    SET NOCOUNT ON;
                    MERGE dbo.NEXO_TarjetasCambios AS destino
                    USING (
                        SELECT i.CENTROCOSTO, i.REFERENCIA, i.DETALLE, i.COSTO, i.PPUBLICO, GETDATE() AS FechaCambio
                        FROM inserted i
                    ) AS origen
                    ON destino.CENTROCOSTO = origen.CENTROCOSTO
                       AND destino.REFERENCIA = origen.REFERENCIA
                       AND destino.Procesado = 0
                    WHEN MATCHED THEN UPDATE SET
                        DETALLE = origen.DETALLE, COSTO = origen.COSTO,
                        PPUBLICO = origen.PPUBLICO, FechaCambio = origen.FechaCambio
                    WHEN NOT MATCHED THEN
                        INSERT (CENTROCOSTO, REFERENCIA, DETALLE, COSTO, PPUBLICO, FechaCambio, Procesado)
                        VALUES (origen.CENTROCOSTO, origen.REFERENCIA, origen.DETALLE, origen.COSTO,
                                origen.PPUBLICO, origen.FechaCambio, 0);
                END");

            // Clientes de NEXO para que Visions los tenga disponibles como referencia de clientes.
            await connection.ExecuteAsync(@"
                IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'NEXO_Clientes')
                CREATE TABLE dbo.NEXO_Clientes (
                    NIT       NVARCHAR(30)  NOT NULL PRIMARY KEY,
                    Nombre    NVARCHAR(200) NOT NULL,
                    Telefono  NVARCHAR(50)  NULL,
                    Email     NVARCHAR(200) NULL,
                    Direccion NVARCHAR(300) NULL,
                    FechaSync DATETIME      NOT NULL DEFAULT GETDATE()
                );");

            // Rastreo de facturas NEXO exportadas a Visions.
            // El trigger detecta cuando Visions asigna el número real y lo copia aquí
            // para que el agente pueda actualizarlo de vuelta en NEXO vía API.
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

            // Trigger: cuando Visions actualiza NRODOC de 'NEXO-{ID}' al número real,
            // copia el nuevo número a NEXO_FacturasSalientes para que el agente lo
            // sincronice de vuelta a NEXO en la próxima ronda.
            await connection.ExecuteAsync(@"
                CREATE OR ALTER TRIGGER dbo.trg_NEXO_ActualizarFacturaSaliente
                ON dbo.MOVDETALLES AFTER UPDATE
                AS
                BEGIN
                    SET NOCOUNT ON;
                    IF UPDATE(NRODOC)
                    BEGIN
                        UPDATE nfs
                        SET NroDocVisions = src.NewNroDoc,
                            TipDocVisions = src.NewTipDoc
                        FROM dbo.NEXO_FacturasSalientes nfs
                        INNER JOIN (
                            SELECT DISTINCT d.NRODOC AS OldNroDoc, i.NRODOC AS NewNroDoc, i.TIPDOC AS NewTipDoc
                            FROM inserted i
                            INNER JOIN deleted d ON i.NRODOC <> d.NRODOC
                            WHERE d.NRODOC LIKE 'NEXO-%'
                        ) AS src ON src.OldNroDoc = nfs.NexoNroDoc
                        WHERE nfs.NroDocVisions IS NULL;
                    END
                END");

            _logger.LogInformation("Tablas NEXO_* verificadas/creadas en Visions correctamente");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error al inicializar tablas NEXO_* en Visions. El agente continuara de todas formas");
        }
    }
}
