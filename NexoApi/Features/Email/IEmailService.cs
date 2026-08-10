namespace NexoApi.Features.Email;

public record EmailMessage(string To, string Subject, string Html, string? ToName = null);

public interface IEmailService
{
    /// <summary>Envía un email. Devuelve false si el email no está configurado o activo.</summary>
    Task<bool> SendAsync(EmailMessage message);
    Task<EmailConfigItem> ObtenerConfigAsync();
    Task GuardarConfigAsync(EmailConfigItem config);
}

public record EmailConfigItem(
    string Proveedor, string? ApiKey, string? EmailFrom, string? NombreFrom, bool Activo
);
