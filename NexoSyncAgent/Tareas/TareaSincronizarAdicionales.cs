using Dapper;
using NexoSyncAgent.NexoApiClient;
using NexoSyncAgent.NexoApiClient.Dtos;
using NexoSyncAgent.VisionsData;

namespace NexoSyncAgent.Tareas;

// Sincronizacion adicionales bidireccional.
// Paso 1 Visions→NEXO: upsert (inserta los que NEXO no tiene; no borra).
// Paso 2 NEXO→Visions: reconciliacion completa (inserta + borra segun NEXO).
public class TareaSincronizarAdicionales
{
    private readonly INexoApiClient _apiClient;
    private readonly IVisionsConnectionFactory _visionsDb;
    private readonly ILogger<TareaSincronizarAdicionales> _logger;

    public TareaSincronizarAdicionales(
        INexoApiClient apiClient, IVisionsConnectionFactory visionsDb,
        ILogger<TareaSincronizarAdicionales> logger)
    {
        _apiClient = apiClient;
        _visionsDb = visionsDb;
        _logger    = logger;
    }

    public async Task EjecutarAsync(CancellationToken ct)
    {
        using var conn = _visionsDb.CreateConnection();

        // ── PASO 1: Visions → NEXO (upsert; NEXO es quien elimina) ──────────────
        await SincronizarVisionsANexoAsync(conn, ct);

        // ── PASO 2: NEXO → Visions (reconciliación completa) ────────────────────
        var datos = await _apiClient.ListarAdicionalesSyncAsync(ct);

        // ── TARJETA_ES_ADICIONAL ──────────────────────────────────────────────

        var refEsAdicionalEnNexo = datos.EsAdicional
            .Select(e => e.Referencia)
            .ToHashSet(StringComparer.OrdinalIgnoreCase);

        // Insertar las que no existen en Visions
        foreach (var item in datos.EsAdicional)
        {
            try
            {
                await conn.ExecuteAsync(
                    """
                    IF NOT EXISTS (SELECT 1 FROM dbo.TARJETA_ES_ADICIONAL WHERE REFERENCIA = @Referencia)
                        INSERT INTO dbo.TARJETA_ES_ADICIONAL (REFERENCIA) VALUES (@Referencia)
                    """,
                    new { item.Referencia });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error al insertar TARJETA_ES_ADICIONAL {Ref}", item.Referencia);
            }
        }

        // Eliminar las que ya no están en NEXO
        var enVisionsEsAd = (await conn.QueryAsync<string>(
            "SELECT REFERENCIA FROM dbo.TARJETA_ES_ADICIONAL")).ToList();

        foreach (var ref_ in enVisionsEsAd.Where(r => !refEsAdicionalEnNexo.Contains(r)))
        {
            try
            {
                await conn.ExecuteAsync(
                    "DELETE FROM dbo.TARJETA_ES_ADICIONAL WHERE REFERENCIA = @R",
                    new { R = ref_ });
                _logger.LogInformation("TARJETA_ES_ADICIONAL: quitada {Ref} (ya no es adicional en NEXO)", ref_);
            }
            catch (Exception ex) { _logger.LogError(ex, "Error al quitar TARJETA_ES_ADICIONAL {Ref}", ref_); }
        }

        _logger.LogInformation("TARJETA_ES_ADICIONAL: {N} activas", refEsAdicionalEnNexo.Count);

        // ── TARJETA_ADICIONALES ───────────────────────────────────────────────

        var paresEnNexo = datos.Adicionales
            .ToDictionary(
                a => a.Referencia + "|" + a.RefAdicional,
                a => a,
                StringComparer.OrdinalIgnoreCase);

        // Upsert relaciones desde NEXO
        foreach (var item in datos.Adicionales)
        {
            try
            {
                await conn.ExecuteAsync(
                    """
                    MERGE dbo.TARJETA_ADICIONALES AS d
                    USING (SELECT @Referencia AS REFERENCIA, @RefAdicional AS REFADICIONAL) AS s
                       ON d.REFERENCIA = s.REFERENCIA AND d.REFADICIONAL = s.REFADICIONAL
                    WHEN MATCHED THEN
                        UPDATE SET ORDEN = @Orden
                    WHEN NOT MATCHED THEN
                        INSERT (REFERENCIA, REFADICIONAL, OBLIGATORIO, MINSELECCION, MAXSELECCION, ORDEN)
                        VALUES (@Referencia, @RefAdicional, 0, 0, 0, @Orden);
                    """,
                    new { item.Referencia, item.RefAdicional, item.Orden });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex,
                    "Error al sincronizar TARJETA_ADICIONALES {Ref}→{RefAd}", item.Referencia, item.RefAdicional);
            }
        }

        // Eliminar relaciones que ya no están en NEXO
        var enVisionsAd = (await conn.QueryAsync<(string Referencia, string RefAdicional)>(
            "SELECT REFERENCIA, REFADICIONAL FROM dbo.TARJETA_ADICIONALES")).ToList();

        foreach (var fila in enVisionsAd)
        {
            var key = fila.Referencia + "|" + fila.RefAdicional;
            if (!paresEnNexo.ContainsKey(key))
            {
                try
                {
                    await conn.ExecuteAsync(
                        "DELETE FROM dbo.TARJETA_ADICIONALES WHERE REFERENCIA = @R AND REFADICIONAL = @RA",
                        new { R = fila.Referencia, RA = fila.RefAdicional });
                    _logger.LogInformation(
                        "TARJETA_ADICIONALES: eliminada relacion {Ref}→{RefAd}", fila.Referencia, fila.RefAdicional);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex,
                        "Error al eliminar TARJETA_ADICIONALES {Ref}→{RefAd}", fila.Referencia, fila.RefAdicional);
                }
            }
        }

        _logger.LogInformation("TARJETA_ADICIONALES: {N} relaciones activas", paresEnNexo.Count);
    }

    private async Task SincronizarVisionsANexoAsync(System.Data.IDbConnection conn, CancellationToken ct)
    {
        try
        {
            var esAdicional = (await conn.QueryAsync<string>(
                "SELECT REFERENCIA FROM dbo.TARJETA_ES_ADICIONAL")).ToList();

            var relaciones = (await conn.QueryAsync<(string Referencia, string RefAdicional)>(
                "SELECT REFERENCIA, REFADICIONAL FROM dbo.TARJETA_ADICIONALES")).ToList();

            var request = new AdicionalesSyncDesdeVisionsRequest(
                esAdicional.Select(r => new EsAdicionalSyncItem(r)).ToList(),
                relaciones.Select(r => new AdicionalRelacionSyncItem(r.Referencia, r.RefAdicional, 0)).ToList()
            );

            await _apiClient.SincronizarAdicionalesDesdeVisionsAsync(request, ct);
            _logger.LogInformation(
                "Visions→NEXO adicionales: {NEsAd} marcados, {NRel} relaciones enviadas",
                esAdicional.Count, relaciones.Count);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error en sync Visions→NEXO adicionales");
        }
    }
}
