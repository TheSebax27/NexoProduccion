using System.Data;
using Microsoft.Data.SqlClient;

namespace NexoSyncAgent.VisionsData;

public class VisionsConnectionFactory : IVisionsConnectionFactory
{
    private readonly string _connectionString;

    public VisionsConnectionFactory(IConfiguration configuration)
    {
        var raw = configuration.GetConnectionString("VisionsDb")
            ?? throw new InvalidOperationException("No se encontro la cadena de conexion 'VisionsDb'.");
        // Forzar Application Name para que APP_NAME() en TR_TARJETA_NexoCambios identifique
        // conexiones del agente y suprima el eco hacia NEXO_TarjetasCambios.
        // Funciona desde SQL Server 2000 (a diferencia de SESSION_CONTEXT que requiere 2016+).
        var builder = new SqlConnectionStringBuilder(raw);
        if (string.IsNullOrEmpty(builder.ApplicationName) || builder.ApplicationName == ".Net SqlClient Data Provider")
            builder.ApplicationName = "NexoSyncAgent";
        _connectionString = builder.ConnectionString;
    }

    public IDbConnection CreateConnection() => new SqlConnection(_connectionString);
}