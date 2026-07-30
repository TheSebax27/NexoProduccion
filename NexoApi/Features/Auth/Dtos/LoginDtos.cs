namespace NexoApi.Features.Auth.Dtos;

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