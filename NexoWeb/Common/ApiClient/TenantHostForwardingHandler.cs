namespace NexoWeb.Common.ApiClient;

/// <summary>
/// DelegatingHandler que reenvía el Host del request entrante al API.
/// Así la web llama al API por localhost internamente pero el API
/// puede resolver el tenant correcto desde el Host header.
/// </summary>
public class TenantHostForwardingHandler : DelegatingHandler
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    public TenantHostForwardingHandler(IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    protected override Task<HttpResponseMessage> SendAsync(
        HttpRequestMessage request, CancellationToken cancellationToken)
    {
        var host = _httpContextAccessor.HttpContext?.Request.Host.Host;

        if (!string.IsNullOrEmpty(host)
            && host != "localhost"
            && host != "127.0.0.1"
            && !System.Net.IPAddress.TryParse(host, out _))
        {
            request.Headers.Host = host;
        }

        return base.SendAsync(request, cancellationToken);
    }
}
