using System.Data;
using System.Data.SqlClient;

namespace NexoApi.Common.Data;

public class SqlConnectionFactory : IDbConnectionFactory
{

    private readonly string _connectionString;

    public SqlConnectionFactory(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString("NexoDb")
                ?? throw new InvalidOperationException("Connection string 'NexoDb' not found.");
    }


    public IDbConnection CreateConnection() => new SqlConnection(_connectionString);


}
