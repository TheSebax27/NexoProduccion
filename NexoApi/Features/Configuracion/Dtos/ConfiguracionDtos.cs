namespace NexoApi.Features.Configuracion.Dtos;

public record ConfiguracionEmpresaResponse(string NombreEmpresa, string? LogoBase64, string? LogoContentType);
public record ActualizarNombreEmpresaRequest(string NombreEmpresa);
public record ActualizarLogoEmpresaRequest(string Base64, string ContentType);
