namespace NexoApi.Features.Configuracion.Dtos;

public record ConfiguracionEmpresaResponse(string NombreEmpresa, string? NombrePropietario, string? LogoBase64, string? LogoContentType, bool UsaVisions);
public record ActualizarNombreEmpresaRequest(string NombreEmpresa, string? NombrePropietario);
public record ActualizarLogoEmpresaRequest(string Base64, string ContentType);
public record ActualizarUsaVisionsRequest(bool UsaVisions);
