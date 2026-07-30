using Microsoft.Data.SqlClient;
using System.Data.SqlClient;
using System.Net;
using System.Text.Json;
using SqlException = Microsoft.Data.SqlClient.SqlException;

namespace NexoApi.Common.Middleware;

public class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;

    public ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (SqlException ex) when (ex.Number is >= 50000 and < 60000)
        {
            _logger.LogWarning(ex, "Regla de negocio rechazada por la base de datos");
            await WriteResponse(context, HttpStatusCode.BadRequest, ex.Message);
        }
        catch (SqlException ex)
        {
            _logger.LogError(ex, "Error de base de datos no controlado");
            await WriteResponse(context, HttpStatusCode.InternalServerError, "Ocurrio un error interno al procesar la operacion.");
        }
        catch (KeyNotFoundException ex)
        {
            await WriteResponse(context, HttpStatusCode.NotFound, ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error no controlado");
            await WriteResponse(context, HttpStatusCode.InternalServerError, "Ocurrio un error interno inesperado.");
        }
    }

    private static async Task WriteResponse(HttpContext context, HttpStatusCode statusCode, string message)
    {
        context.Response.ContentType = "application/json";
        context.Response.StatusCode = (int)statusCode;
        await context.Response.WriteAsync(JsonSerializer.Serialize(new { error = message }));
    }
}