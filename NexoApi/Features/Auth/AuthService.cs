using Dapper;
using NexoApi.Common.Data;
using NexoApi.Common.Security;
using NexoApi.Features.Auth.Dtos;

namespace NexoApi.Features.Auth;

public interface IAuthService
{
    Task<LoginResponse?> LoginAsync(LoginRequest request);
}

public class AuthService : IAuthService
{
    private readonly IDbConnectionFactory _db;
    private readonly IJwtService _jwt;
    private readonly IConfiguration _config;

    public AuthService(IDbConnectionFactory db, IJwtService jwt, IConfiguration config)
    {
        _db = db;
        _jwt = jwt;
        _config = config;
    }

    private record UsuarioAuthData(
        int UsuarioID, string Nombres, string Apellidos, string Username,
        byte[] PasswordHash, byte[] Salt, string Rol, int? CentroCostoID, bool Estado);

    public async Task<LoginResponse?> LoginAsync(LoginRequest request)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT u.UsuarioID, u.Nombres, u.Apellidos, u.Username,
                   u.PasswordHash, u.Salt, r.Nombre AS Rol, u.CentroCostoID, u.Estado
            FROM Seguridad.Usuarios u
            JOIN Seguridad.Roles r ON r.RolID = u.RolID
            WHERE u.Username = @Username";

        var usuario = await connection.QuerySingleOrDefaultAsync<UsuarioAuthData>(sql, new { request.Username });

        if (usuario is null || !usuario.Estado)
            return null;

        if (!PasswordHasher.VerifyPassword(request.Password, usuario.PasswordHash, usuario.Salt))
            return null;

        var accessToken = _jwt.GenerateAccessToken(usuario.UsuarioID, usuario.Username, usuario.Rol, usuario.CentroCostoID);
        var refreshToken = _jwt.GenerateRefreshToken();
        var expiraEn = DateTime.UtcNow.AddMinutes(double.Parse(_config["Jwt:ExpirationMinutes"]!));
        var refreshExpira = DateTime.UtcNow.AddDays(double.Parse(_config["Jwt:RefreshExpirationDays"]!));

        const string insertSesion = @"
            INSERT INTO Seguridad.SesionesUsuario (UsuarioID, Token, RefreshToken, FechaExpiracion, Activa)
            VALUES (@UsuarioID, @Token, @RefreshToken, @FechaExpiracion, 1)";

        await connection.ExecuteAsync(insertSesion, new
        {
            usuario.UsuarioID,
            Token = accessToken,
            RefreshToken = refreshToken,
            FechaExpiracion = refreshExpira
        });

        await connection.ExecuteAsync(
            "UPDATE Seguridad.Usuarios SET UltimoAcceso = SYSUTCDATETIME() WHERE UsuarioID = @UsuarioID",
            new { usuario.UsuarioID });

        return new LoginResponse(
            accessToken, refreshToken, expiraEn, usuario.UsuarioID,
            $"{usuario.Nombres} {usuario.Apellidos}", usuario.Rol, usuario.CentroCostoID);
    }
}