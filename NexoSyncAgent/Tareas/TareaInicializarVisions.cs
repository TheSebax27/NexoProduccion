using Dapper;
using NexoSyncAgent.VisionsData;

namespace NexoSyncAgent.Tareas;

// Corre UNA SOLA VEZ al arrancar el agente (ver Worker.cs).
// Crea las 3 tablas NEXO_* en la base de Visions si no existen.
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

            _logger.LogInformation("Tablas NEXO_* verificadas/creadas en Visions correctamente");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error al inicializar tablas NEXO_* en Visions. El agente continuara de todas formas");
        }
    }
}
