using System.Data;
using Microsoft.Data.SqlClient;

namespace NexoSyncAgent.VisionsData;

public class VisionsConnectionFactory : IVisionsConnectionFactory
{
    private readonly string _connectionString;

    public VisionsConnectionFactory(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("VisionsDb")
            ?? throw new InvalidOperationException("No se encontro la cadena de conexion 'VisionsDb'.");
    }

    public IDbConnection CreateConnection() => new SqlConnection(_connectionString);
}