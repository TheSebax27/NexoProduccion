using Dapper;
using NexoSyncAgent.NexoApiClient;
using NexoSyncAgent.VisionsData;

namespace NexoSyncAgent.Tareas;

// Descarga imagenes actualizadas en NEXO y las escribe directamente en dbo.TARJETA.Imagen (varbinary).
// TARJETA.Imagen es varbinary(MAX) NOT NULL DEFAULT(0x); el trigger ignora updates del agente.
// Persiste el ultimo timestamp en imagen_sync_estado.txt junto al ejecutable.
public class TareaExportarImagenesAVisions
{
    private readonly INexoApiClient _apiClient;
    private readonly IVisionsConnectionFactory _visionsDb;
    private readonly ILogger<TareaExportarImagenesAVisions> _logger;
    private readonly string _estadoFile;

    public TareaExportarImagenesAVisions(
        INexoApiClient apiClient, IVisionsConnectionFactory visionsDb,
        ILogger<TareaExportarImagenesAVisions> logger)
    {
        _apiClient  = apiClient;
        _visionsDb  = visionsDb;
        _logger     = logger;
        _estadoFile = Path.Combine(AppContext.BaseDirectory, "imagen_sync_estado.txt");
    }

    public async Task EjecutarAsync(int centroCostoVisions, CancellationToken ct)
    {
        using var connection = _visionsDb.CreateConnection();

        // Verificar que la columna Imagen existe — instalaciones antiguas no la tienen.
        var tieneImagen = await connection.ExecuteScalarAsync<int>(
            "SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='TARJETA' AND COLUMN_NAME='Imagen'") > 0;
        if (!tieneImagen)
        {
            _logger.LogDebug("Columna Imagen no existe en TARJETA de Visions — sync de imagenes omitido");
            return;
        }

        DateTime? desde  = LeerUltimoTimestamp();
        var articulos    = (await _apiClient.ListarArticulosConImagenActualizadaAsync(desde, ct)).ToList();

        if (articulos.Count == 0)
            return;

        _logger.LogInformation("Imagenes NEXO→Visions: {N} articulos con imagen actualizada", articulos.Count);

        foreach (var art in articulos)
        {
            try
            {
                var bytes = Convert.FromBase64String(art.ImagenBase64);
                await connection.ExecuteAsync(
                    "UPDATE dbo.TARJETA SET Imagen = @Imagen WHERE CENTROCOSTO = @CC AND REFERENCIA = @Referencia",
                    new { Imagen = bytes, CC = centroCostoVisions, Referencia = art.Referencia });
                _logger.LogDebug("Imagen aplicada en Visions para {Ref} ({Bytes} bytes)", art.Referencia, bytes.Length);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "No se pudo aplicar imagen para {Ref} en Visions (no critico)", art.Referencia);
            }
        }

        GuardarTimestamp(DateTime.UtcNow);
    }

    private DateTime? LeerUltimoTimestamp()
    {
        if (!File.Exists(_estadoFile)) return null;
        var txt = File.ReadAllText(_estadoFile).Trim();
        return DateTime.TryParse(txt, out var dt) ? dt : null;
    }

    private void GuardarTimestamp(DateTime dt)
    {
        try { File.WriteAllText(_estadoFile, dt.ToString("O")); }
        catch { /* no critico */ }
    }
}
