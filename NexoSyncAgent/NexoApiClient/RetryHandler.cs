namespace NexoSyncAgent.NexoApiClient;

public class RetryHandler : DelegatingHandler
{
    private static readonly TimeSpan[] _delays = [
        TimeSpan.FromSeconds(2),
        TimeSpan.FromSeconds(5),
        TimeSpan.FromSeconds(15)
    ];

    protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken ct)
    {
        for (int intento = 0; ; intento++)
        {
            HttpResponseMessage? respuesta = null;
            try
            {
                respuesta = await base.SendAsync(request, ct);

                if (!EsTransiente(respuesta.StatusCode) || intento >= _delays.Length)
                    return respuesta;
            }
            catch (Exception ex) when (!ct.IsCancellationRequested && EsTransiente(ex) && intento < _delays.Length)
            {
                // caida de red: esperar y reintentar
            }

            await Task.Delay(_delays[intento], ct);
        }
    }

    private static bool EsTransiente(System.Net.HttpStatusCode code) =>
        code is System.Net.HttpStatusCode.ServiceUnavailable   // 503
             or System.Net.HttpStatusCode.TooManyRequests      // 429
             or System.Net.HttpStatusCode.GatewayTimeout       // 504
             or System.Net.HttpStatusCode.BadGateway;          // 502

    private static bool EsTransiente(Exception ex) =>
        ex is HttpRequestException or TaskCanceledException
        || ex.Message.Contains("refused", StringComparison.OrdinalIgnoreCase)
        || ex.Message.Contains("reset", StringComparison.OrdinalIgnoreCase);
}
