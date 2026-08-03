namespace NexoWeb.Common.Dtos;

public record LoginRequest(string Username, string Password);

public record LoginResponse(
    string AccessToken,
    string RefreshToken,
    DateTime ExpiraEn,
    int UsuarioId,
    string NombreCompleto,
    string Rol,
    int? CentroCostoId
);

// ---------- Gestion de usuarios (Administrador) ----------
public record UsuarioItem(
    int UsuarioID,
    string Nombres,
    string Apellidos,
    string Email,
    string Username,
    int RolID,
    string Rol,
    int? CentroCostoID,
    string? CentroCosto,
    bool Estado,
    DateTime? UltimoAcceso
);

public record RolItem(int RolID, string Nombre);

public record CrearUsuarioRequest(
    string Nombres,
    string Apellidos,
    string Email,
    string Username,
    string Password,
    int RolID,
    int? CentroCostoID
);

public record ActualizarUsuarioRequest(
    string Nombres,
    string Apellidos,
    string Email,
    int RolID,
    int? CentroCostoID,
    bool Estado
);

public record ResetearPasswordRequest(string NuevaPassword);