using Dapper;
using NexoApi.Common.Data;
using NexoApi.Features.Configuracion.Dtos;

namespace NexoApi.Features.Configuracion;

public interface IConfiguracionService
{
    Task<ConfiguracionEmpresaResponse> ObtenerEmpresaAsync();
    Task ActualizarNombreEmpresaAsync(string nombreEmpresa);
    Task ActualizarLogoEmpresaAsync(string base64, string contentType);
    Task EliminarLogoEmpresaAsync();
}

// Configuracion global de la empresa (nombre + logo del sidebar) -- a
// diferencia de Seguridad.PreferenciasUsuario, esto NO es por usuario: es
// una sola fila (ConfiguracionID = 1) que ve y usa todo el mundo, pero solo
// Administrador puede editarla (logica de rol en el controller).
public class ConfiguracionService : IConfiguracionService
{
    private readonly IDbConnectionFactory _db;

    public ConfiguracionService(IDbConnectionFactory db)
    {
        _db = db;
    }

    public async Task<ConfiguracionEmpresaResponse> ObtenerEmpresaAsync()
    {
        using var connection = _db.CreateConnection();

        var fila = await connection.QuerySingleAsync<(string NombreEmpresa, byte[]? Logo, string? LogoContentType)>(
            "SELECT NombreEmpresa, Logo, LogoContentType FROM Organizacion.ConfiguracionEmpresa WHERE ConfiguracionID = 1");

        return new ConfiguracionEmpresaResponse(
            fila.NombreEmpresa,
            fila.Logo is null ? null : Convert.ToBase64String(fila.Logo),
            fila.LogoContentType);
    }

    public async Task ActualizarNombreEmpresaAsync(string nombreEmpresa)
    {
        using var connection = _db.CreateConnection();
        await connection.ExecuteAsync(
            "UPDATE Organizacion.ConfiguracionEmpresa SET NombreEmpresa = @NombreEmpresa WHERE ConfiguracionID = 1",
            new { NombreEmpresa = nombreEmpresa });
    }

    // El UPDATE reemplaza el logo anterior -- no es un archivo en disco, es
    // una columna varbinary que simplemente se sobrescribe.
    public async Task ActualizarLogoEmpresaAsync(string base64, string contentType)
    {
        using var connection = _db.CreateConnection();
        var datos = Convert.FromBase64String(base64);

        await connection.ExecuteAsync(
            "UPDATE Organizacion.ConfiguracionEmpresa SET Logo = @Datos, LogoContentType = @ContentType WHERE ConfiguracionID = 1",
            new { Datos = datos, ContentType = contentType });
    }

    public async Task EliminarLogoEmpresaAsync()
    {
        using var connection = _db.CreateConnection();
        await connection.ExecuteAsync(
            "UPDATE Organizacion.ConfiguracionEmpresa SET Logo = NULL, LogoContentType = NULL WHERE ConfiguracionID = 1");
    }
}
