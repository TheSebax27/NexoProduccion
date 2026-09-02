using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;
using Microsoft.OpenApi.Models;
using NexoApi.Common.Data;
using NexoApi.Common.Middleware;
using NexoApi.Common.Security;
using NexoApi.Features.Auth;
using NexoApi.Features.Busqueda;
using NexoApi.Features.Calendario;
using NexoApi.Features.Catalogo;
using NexoApi.Features.Compras;
using NexoApi.Features.Configuracion;
using NexoApi.Features.Crm;
using NexoApi.Features.Dashboard;
using NexoApi.Features.Facturacion;
using NexoApi.Features.Integracion;
using NexoApi.Features.Inventario;
using NexoApi.Features.Logistica;
using NexoApi.Features.Notificaciones;
using NexoApi.Features.Marketing;
using NexoApi.Features.Planificacion;
using NexoApi.Features.Preferencias;
using NexoApi.Features.Produccion;
using NexoApi.Features.Proyectos;
using NexoApi.Features.Recetas;
using NexoApi.Features.Rrhh;
using NexoApi.Features.Seguridad;
using NexoApi.Features.Traspasos;
using System.Text;
using Dapper;

// QuestPDF exige declarar el tipo de licencia antes de generar cualquier PDF.
// Community es gratuita para empresas con ingresos anuales menores a 1M USD
// (ver https://www.questpdf.com/license/) -- si el negocio crece mas alla de
// ese umbral, hay que comprar la licencia comercial de QuestPDF.
QuestPDF.Settings.License = QuestPDF.Infrastructure.LicenseType.Community;

SqlMapper.AddTypeHandler(new TimeOnlyTypeHandler());

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();

// ----------------------------------------------------------------------------
// CONFIGURACIÓN DE SWAGGER (JWT + X-Api-Key)
// ----------------------------------------------------------------------------
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo { Title = "NEXO API", Version = "v1" });

    // Evita colisión de SchemaId cuando dos namespaces distintos usan el mismo nombre de clase
    options.CustomSchemaIds(t => t.FullName?.Replace('+', '.') ?? t.Name);

    // Security definition para JWT (Usuarios)
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Escribe: Bearer {tu token}"
    });

    // Security definition para API Key (Agente Sync)
    options.AddSecurityDefinition("ApiKey", new OpenApiSecurityScheme
    {
        Name = ApiKeyAuthenticationHandler.HeaderName, // X-Api-Key
        Type = SecuritySchemeType.ApiKey,
        In = ParameterLocation.Header,
        Description = "Escribe tu API Key del Agente directamente"
    });

    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        { new OpenApiSecurityScheme { Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" } }, Array.Empty<string>() },
        { new OpenApiSecurityScheme { Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "ApiKey" } }, Array.Empty<string>() }
    });
});

// ----------------------------------------------------------------------------
// INFRAESTRUCTURA Y MÓDULOS DE NEGOCIO
// ----------------------------------------------------------------------------
builder.Services.AddSingleton<IDbConnectionFactory, SqlConnectionFactory>();
builder.Services.AddScoped<IJwtService, JwtService>();

builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IOrdenesProduccionService, OrdenesProduccionService>();
builder.Services.AddScoped<IInventarioService, InventarioService>();
builder.Services.AddScoped<IOrdenesCompraService, OrdenesCompraService>();
builder.Services.AddScoped<ITraspasosService, TraspasosService>();
builder.Services.AddScoped<ICatalogoService, CatalogoService>();
builder.Services.AddScoped<IRecetasService, RecetasService>();
builder.Services.AddScoped<IIntegracionService, IntegracionService>();
builder.Services.AddScoped<IDashboardService, DashboardService>();
builder.Services.AddScoped<IDashboardExportService, DashboardExportService>();
builder.Services.AddScoped<IRrhhService, RrhhService>();
builder.Services.AddScoped<IAsistenciaService, AsistenciaService>();
builder.Services.AddScoped<IAutomacionService, AutomacionService>();
builder.Services.AddScoped<ICrmService, CrmService>();
builder.Services.AddScoped<NexoApi.Features.Email.IEmailService, NexoApi.Features.Email.GmailEmailService>();
builder.Services.AddHttpClient();
builder.Services.AddHostedService<NexoApi.Infrastructure.AutomationBackgroundService>();
builder.Services.AddScoped<IPlanificacionService, PlanificacionService>();
builder.Services.AddScoped<ICalendarioService, CalendarioService>();
builder.Services.AddScoped<ILogisticaService, LogisticaService>();
builder.Services.AddScoped<IProyectosService, ProyectosService>();
builder.Services.AddScoped<IFacturacionService, FacturacionService>();
builder.Services.AddScoped<IDevolucionService, DevolucionService>();
builder.Services.AddScoped<INotificacionesService, NotificacionesService>();
builder.Services.AddScoped<IBusquedaService, BusquedaService>();
builder.Services.AddScoped<IPreferenciasService, PreferenciasService>();
builder.Services.AddScoped<IConfiguracionService, ConfiguracionService>();
builder.Services.AddScoped<IMarketingService, MarketingService>();
builder.Services.AddScoped<IMaquinariaService, MaquinariaService>();
builder.Services.AddScoped<IEmpleadoProduccionService, EmpleadoProduccionService>();
builder.Services.AddScoped<IComboService, ComboService>();
builder.Services.AddScoped<ISeguridadService, SeguridadService>();
builder.Services.AddScoped<NexoApi.Features.Finanzas.IFinanzasService, NexoApi.Features.Finanzas.FinanzasService>();
builder.Services.AddScoped<NexoApi.Features.Soporte.ISoporteService, NexoApi.Features.Soporte.SoporteService>();
builder.Services.AddScoped<NexoApi.Features.Formularios.IFormulariosService, NexoApi.Features.Formularios.FormulariosService>();
builder.Services.AddScoped<NexoApi.Features.Conocimiento.IConocimientoService, NexoApi.Features.Conocimiento.ConocimientoService>();
builder.Services.AddScoped<NexoApi.Features.Reportes.IReportesService, NexoApi.Features.Reportes.ReportesService>();
builder.Services.AddHttpClient<NexoApi.Features.WhatsApp.IWhatsAppService, NexoApi.Features.WhatsApp.WhatsAppService>();

// ----------------------------------------------------------------------------
// AUTENTICACIÓN Y AUTORIZACIÓN (AQUÍ ESTÁ EL CAMBIO)
// ----------------------------------------------------------------------------
var jwtSection = builder.Configuration.GetSection("Jwt");

// Bloqueo de arranque: la clave JWT de desarrollo no debe usarse en producción.
// Si el sistema de clientes no sobreescribió la clave, la API no arranca.
if (builder.Environment.IsProduction())
{
    const string claveDesarrollo = "NexoERP_ClaveSecretaSuperSegura2026_SistemaIntegrado#99";
    var jwtKey = jwtSection["Key"] ?? "";
    if (string.IsNullOrWhiteSpace(jwtKey) || jwtKey == claveDesarrollo || jwtKey.Length < 32)
        throw new InvalidOperationException(
            "La clave JWT no está configurada para producción. " +
            "Establece Jwt:Key en appsettings.Production.json (mínimo 32 caracteres, distinta a la clave de desarrollo).");
}

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtSection["Issuer"],
        ValidAudience = jwtSection["Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSection["Key"]!))
    };
})
// <-- AQUÍ SE ENCADENA EL NUEVO ESQUEMA DE API KEY PARA EL AGENTE -->
.AddScheme<ApiKeyAuthenticationOptions, ApiKeyAuthenticationHandler>(
    ApiKeyAuthenticationHandler.SchemeName,
    _ => { }
);

builder.Services.AddAuthorization();
builder.Services.AddMemoryCache();

// ----------------------------------------------------------------------------
// PIPELINE DE LA APLICACIÓN
// ----------------------------------------------------------------------------
var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseMiddleware<ExceptionHandlingMiddleware>();
app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();
// Despues de Authorization: para este punto ya se conoce el usuario (JWT
// validado) y la request ya paso el chequeo de rol -- ver AuditoriaMiddleware.cs.
app.UseMiddleware<AuditoriaMiddleware>();
app.MapControllers();

app.Run();