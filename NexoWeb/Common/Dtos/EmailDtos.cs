namespace NexoWeb.Common.Dtos;

public record EmailConfigItem(
    string Proveedor, string? ApiKey, string? EmailFrom, string? NombreFrom, bool Activo
);
