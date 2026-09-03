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
        // Forzar Application Name para que APP_NAME() en el trigger del agente sea predecible
        // en cualquier version de SQL Server (reemplaza SESSION_CONTEXT que requiere 2016+).
        var builder = new SqlConnectionStringBuilder(raw);
        if (string.IsNullOrEmpty(builder.ApplicationName) || builder.ApplicationName == ".Net SqlClient Data Provider")
            builder.ApplicationName = "NexoSyncAgent";
        _connectionString = builder.ConnectionString;
    }

    public IDbConnection CreateConnection() => new SqlConnection(_connectionString);
}