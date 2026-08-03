using Dapper;
using NexoApi.Common.Data;
using NexoApi.Common.Security;
using NexoApi.Features.Auth.Dtos;

namespace NexoApi.Features.Auth;

public interface IAuthService
{
    Task<LoginResponse?> LoginAsync(LoginRequest request);
    Task<int> RegistrarPrimerAdminAsync(RegistrarUsuarioRequest request);

    // Gestion de usuarios (Administrador)
    Task<IEnumerable<UsuarioItem>> ListarUsuariosAsync();
    Task<int> CrearUsuarioAsync(CrearUsuarioRequest request);
    Task ActualizarUsuarioAsync(int usuarioId, ActualizarUsuarioRequest request);
    Task ResetearPasswordAsync(int usuarioId, ResetearPasswordRequest request);
    Task<IEnumerable<RolItem>> ListarRolesAsync();
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

        // Se acepta Username O Email como credencial -- es comun que el usuario
        // intente ingresar con su correo (asi lo ve en "Mi perfil"/tarjetas de
        // usuario) sin recordar que el Username puede ser distinto.
        const string sql = @"
            SELECT u.UsuarioID, u.Nombres, u.Apellidos, u.Username,
                   u.PasswordHash, u.Salt, r.Nombre AS Rol, u.CentroCostoID, u.Estado
            FROM Seguridad.Usuarios u
            JOIN Seguridad.Roles r ON r.RolID = u.RolID
            WHERE u.Username = @Username OR u.Email = @Username";

        var usuario = await connection.QuerySingleOrDefaultAsync<UsuarioAuthData>(sql, new { request.Username });

        if (usuario is null || !usuario.Estado)
            return null;

        if (!PasswordHasher.VerifyPassword(request.Password, usuario.PasswordHash, usuario.Salt))
            return null;

        var accessToken = _jwt.GenerateAccessToken(usuario.UsuarioID, usuario.Username, usuario.Rol, usuario.CentroCostoID);
        var refreshToken = _jwt.GenerateRefreshToken();
        var expiraEn = DateTime.UtcNow.AddMinutes(double.Parse(_config["Jwt:ExpirationMinutes"]!));
        var refreshExpira = DateTime.UtcNow.AddDays(double.Parse(_config["Jwt:RefreshTokenExpirationDays"]!));

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
    public async Task<int> RegistrarPrimerAdminAsync(RegistrarUsuarioRequest r)
    {
        using var connection = _db.CreateConnection();

        var totalUsuarios = await connection.ExecuteScalarAsync<int>("SELECT COUNT(1) FROM Seguridad.Usuarios");

        if (totalUsuarios > 0)
            throw new InvalidOperationException(
                "Ya existe al menos un usuario. Este endpoint de arranque queda deshabilitado; los usuarios nuevos se crean autenticado como Administrador.");

        var (hash, salt) = PasswordHasher.HashPassword(r.Password);

        const string sql = @"
        INSERT INTO Seguridad.Usuarios (Nombres, Apellidos, Email, Username, PasswordHash, Salt, RolID, CentroCostoID)
        OUTPUT INSERTED.UsuarioID
        VALUES (@Nombres, @Apellidos, @Email, @Username, @Hash, @Salt, @RolID, @CentroCostoID)";

        return await connection.ExecuteScalarAsync<int>(sql, new
        {
            r.Nombres,
            r.Apellidos,
            r.Email,
            r.Username,
            Hash = hash,
            Salt = salt,
            r.RolID,
            r.CentroCostoID
        });
    }

    // ================= Gestion de usuarios (Administrador) =================

    public async Task<IEnumerable<UsuarioItem>> ListarUsuariosAsync()
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT u.UsuarioID, u.Nombres, u.Apellidos, u.Email, u.Username,
                   u.RolID, r.Nombre AS Rol, u.CentroCostoID, cc.Nombre AS CentroCosto,
                   u.Estado, u.UltimoAcceso
            FROM Seguridad.Usuarios u
            JOIN Seguridad.Roles r ON r.RolID = u.RolID
            LEFT JOIN Organizacion.CentrosCosto cc ON cc.CentroCostoID = u.CentroCostoID
            ORDER BY u.Nombres, u.Apellidos";

        return await connection.QueryAsync<UsuarioItem>(sql);
    }

    public async Task<int> CrearUsuarioAsync(CrearUsuarioRequest r)
    {
        using var connection = _db.CreateConnection();

        var existe = await connection.ExecuteScalarAsync<int>(
            "SELECT COUNT(1) FROM Seguridad.Usuarios WHERE Username = @Username OR Email = @Email",
            new { r.Username, r.Email });

        if (existe > 0)
            throw new InvalidOperationException("Ya existe un usuario con ese nombre de usuario o correo.");

        var (hash, salt) = PasswordHasher.HashPassword(r.Password);

        const string sql = @"
            INSERT INTO Seguridad.Usuarios
                (Nombres, Apellidos, Email, Username, PasswordHash, Salt, RolID, CentroCostoID, Estado, FechaCreacion)
            OUTPUT INSERTED.UsuarioID
            VALUES
                (@Nombres, @Apellidos, @Email, @Username, @Hash, @Salt, @RolID, @CentroCostoID, 1, SYSUTCDATETIME())";

        return await connection.ExecuteScalarAsync<int>(sql, new
        {
            r.Nombres,
            r.Apellidos,
            r.Email,
            r.Username,
            Hash = hash,
            Salt = salt,
            r.RolID,
            r.CentroCostoID
        });
    }

    public async Task ActualizarUsuarioAsync(int usuarioId, ActualizarUsuarioRequest r)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            UPDATE Seguridad.Usuarios
            SET Nombres = @Nombres, Apellidos = @Apellidos, Email = @Email,
                RolID = @RolID, CentroCostoID = @CentroCostoID, Estado = @Estado
            WHERE UsuarioID = @UsuarioId";

        var filas = await connection.ExecuteAsync(sql, new
        {
            UsuarioId = usuarioId,
            r.Nombres,
            r.Apellidos,
            r.Email,
            r.RolID,
            r.CentroCostoID,
            r.Estado
        });

        if (filas == 0)
            throw new KeyNotFoundException($"No existe el usuario {usuarioId}.");
    }

    public async Task ResetearPasswordAsync(int usuarioId, ResetearPasswordRequest r)
    {
        using var connection = _db.CreateConnection();

        var (hash, salt) = PasswordHasher.HashPassword(r.NuevaPassword);

        var filas = await connection.ExecuteAsync(
            "UPDATE Seguridad.Usuarios SET PasswordHash = @Hash, Salt = @Salt WHERE UsuarioID = @UsuarioId",
            new { Hash = hash, Salt = salt, UsuarioId = usuarioId });

        if (filas == 0)
            throw new KeyNotFoundException($"No existe el usuario {usuarioId}.");

        // Invalida las sesiones activas del usuario para que el cambio de clave surta efecto de inmediato.
        await connection.ExecuteAsync(
            "UPDATE Seguridad.SesionesUsuario SET Activa = 0 WHERE UsuarioID = @UsuarioId AND Activa = 1",
            new { UsuarioId = usuarioId });
    }

    public async Task<IEnumerable<RolItem>> ListarRolesAsync()
    {
        using var connection = _db.CreateConnection();
        return await connection.QueryAsync<RolItem>(
            "SELECT RolID, Nombre FROM Seguridad.Roles WHERE Estado = 1 ORDER BY Nombre");
    }
}