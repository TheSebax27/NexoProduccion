namespace NexoWeb.Common.Dtos;

public record ConfiguracionEmpresaResponse(string NombreEmpresa, string? LogoBase64, string? LogoContentType, bool UsaVisions);
public record ActualizarNombreEmpresaRequest(string NombreEmpresa);
public record ActualizarLogoEmpresaRequest(string Base64, string ContentType);
public record ActualizarUsaVisionsRequest(bool UsaVisions);
