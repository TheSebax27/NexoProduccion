using NexoApi.Features.Catalogo;
using NexoApi.Features.Compras;
using NexoApi.Features.Inventario;
using NexoApi.Features.Traspasos;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();
builder.Services.AddScoped<IOrdenesProduccionService, OrdenesProduccionService>();
builder.Services.AddScoped<IInventarioService, InventarioService>();
builder.Services.AddScoped<IOrdenesCompraService, OrdenesCompraService>();
builder.Services.AddScoped<ITraspasosService, TraspasosService>();
builder.Services.AddScoped<ICatalogoService, CatalogoService>();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}



app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();
