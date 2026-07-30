using System.Data;

namespace NexoSyncAgent.VisionsData;

public interface IVisionsConnectionFactory
{
    IDbConnection CreateConnection();
}