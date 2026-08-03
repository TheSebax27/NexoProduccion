using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;
using Microsoft.OpenApi.Models;
using NexoApi.Common.Data;
using NexoApi.Common.Middleware;
using NexoApi.Common.Security;
using NexoApi.Features.Auth;
using NexoApi.Features.Busqueda;
using NexoApi.Features.Catalogo;
using NexoApi.Features.Compras;
using NexoApi.Features.Dashboard;
using NexoApi.Features.Integracion;
using NexoApi.Features.Inventario;
using NexoApi.Features.Notificaciones;
using NexoApi.Features.Preferencias;
using NexoApi.Features.Produccion;
using NexoApi.Features.Recetas;
using NexoApi.Features.Traspasos;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();

// ----------------------------------------------------------------------------
// CONFIGURACIÓN DE SWAGGER (JWT + X-Api-Key)
// ----------------------------------------------------------------------------
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo { Title = "NEXO API", Version = "v1" });

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
builder.Services.AddScoped<INotificacionesService, NotificacionesService>();
builder.Services.AddScoped<IBusquedaService, BusquedaService>();
builder.Services.AddScoped<IPreferenciasService, PreferenciasService>();

// ----------------------------------------------------------------------------
// AUTENTICACIÓN Y AUTORIZACIÓN (AQUÍ ESTÁ EL CAMBIO)
// ----------------------------------------------------------------------------
var jwtSection = builder.Configuration.GetSection("Jwt");

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
app.MapControllers();

app.Run();