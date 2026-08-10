using System.Net;
using System.Net.Mail;
using Dapper;
using NexoApi.Common.Data;

namespace NexoApi.Features.Email;

public class GmailEmailService(IDbConnectionFactory db) : IEmailService
{
    private readonly IDbConnectionFactory _db = db;

    public async Task<EmailConfigItem> ObtenerConfigAsync()
    {
        using var conn = _db.CreateConnection();
        var row = await conn.QueryFirstOrDefaultAsync<ConfigRow>(
            "SELECT Proveedor, ApiKey, EmailFrom, NombreFrom, Activo FROM Organizacion.ConfiguracionEmail WHERE ConfiguracionID = 1");
        return row is null
            ? new EmailConfigItem("Gmail", null, null, null, false)
            : new EmailConfigItem(row.Proveedor, row.ApiKey, row.EmailFrom, row.NombreFrom, row.Activo);
    }

    public async Task GuardarConfigAsync(EmailConfigItem config)
    {
        using var conn = _db.CreateConnection();
        await conn.ExecuteAsync("""
            UPDATE Organizacion.ConfiguracionEmail
            SET Proveedor = @Proveedor, ApiKey = @ApiKey, EmailFrom = @EmailFrom,
                NombreFrom = @NombreFrom, Activo = @Activo, FechaModificacion = SYSUTCDATETIME()
            WHERE ConfiguracionID = 1
            """, config);
    }

    public async Task<bool> SendAsync(EmailMessage message)
    {
        var config = await ObtenerConfigAsync();
        if (!config.Activo || string.IsNullOrWhiteSpace(config.ApiKey) || string.IsNullOrWhiteSpace(config.EmailFrom))
            return false;

        using var smtp = new SmtpClient("smtp.gmail.com", 587)
        {
            EnableSsl   = true,
            Credentials = new NetworkCredential(config.EmailFrom, config.ApiKey)
        };

        var desde = string.IsNullOrWhiteSpace(config.NombreFrom)
            ? new MailAddress(config.EmailFrom)
            : new MailAddress(config.EmailFrom, config.NombreFrom);

        var hacia = string.IsNullOrWhiteSpace(message.ToName)
            ? new MailAddress(message.To)
            : new MailAddress(message.To, message.ToName);

        using var mail = new MailMessage(desde, hacia)
        {
            Subject    = message.Subject,
            Body       = message.Html,
            IsBodyHtml = true
        };

        await smtp.SendMailAsync(mail);
        return true;
    }

    private record ConfigRow(string Proveedor, string? ApiKey, string? EmailFrom, string? NombreFrom, bool Activo);
}
