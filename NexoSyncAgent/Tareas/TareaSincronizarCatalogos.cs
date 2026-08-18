using Dapper;
using NexoSyncAgent.NexoApiClient;
using NexoSyncAgent.NexoApiClient.Dtos;
using NexoSyncAgent.VisionsData;

namespace NexoSyncAgent.Tareas;

// Sincronizacion bidireccional de entidades de catalogo.
// MARCA, GRUPOMAYOR, GRUPOMENOR, IVA, PRESENTACION son globales en Visions
// (sin columna CENTROCOSTO) -- aplican a toda la base de datos de Visions.
public class TareaSincronizarCatalogos
{
    private readonly INexoApiClient _apiClient;
    private readonly IVisionsConnectionFactory _visionsDb;
    private readonly ILogger<TareaSincronizarCatalogos> _logger;

    public TareaSincronizarCatalogos(
        INexoApiClient apiClient, IVisionsConnectionFactory visionsDb, ILogger<TareaSincronizarCatalogos> logger)
    {
        _apiClient = apiClient;
        _visionsDb = visionsDb;
        _logger = logger;
    }

    public async Task EjecutarAsync(CancellationToken ct)
    {
        await SincronizarMarcasAsync(ct);
        await SincronizarGruposMayorAsync(ct);
        await SincronizarGruposMenorAsync(ct);
        await SincronizarIvaAsync(ct);
        await SincronizarPresentacionesAsync(ct);
    }

    // ──────── MARCAS ────────

    private async Task SincronizarMarcasAsync(CancellationToken ct)
    {
        var enNexo = await _apiClient.ListarMarcasSyncAsync(ct);
        var codigosNexo = enNexo.Select(m => m.Codigo).ToHashSet(StringComparer.OrdinalIgnoreCase);

        using var connection = _visionsDb.CreateConnection();
        var enVisions = (await connection.QueryAsync<MarcaSyncDto>(
            "SELECT CODIGO AS Codigo, MARCA AS Nombre FROM dbo.MARCA")).ToList();

        var codigosVisions = enVisions.Select(m => m.Codigo).ToHashSet(StringComparer.OrdinalIgnoreCase);

        foreach (var item in enVisions.Where(m => !codigosNexo.Contains(m.Codigo)))
        {
            try
            {
                await _apiClient.UpsertMarcaEnNexoAsync(item, ct);
                _logger.LogInformation("Marca {Codigo} creada en NEXO desde Visions", item.Codigo);
            }
            catch (Exception ex) { _logger.LogError(ex, "Error al exportar marca {Codigo} a NEXO", item.Codigo); }
        }

        foreach (var item in enNexo.Where(m => !codigosVisions.Contains(m.Codigo)))
        {
            try
            {
                await connection.ExecuteAsync(
                    @"MERGE dbo.MARCA AS d
                      USING (SELECT @Codigo AS CODIGO) AS s ON d.CODIGO = s.CODIGO
                      WHEN MATCHED THEN UPDATE SET MARCA = @Nombre
                      WHEN NOT MATCHED THEN INSERT (CODIGO, MARCA) VALUES (@Codigo, @Nombre);",
                    new { item.Codigo, Nombre = item.Nombre ?? item.Codigo });
                _logger.LogInformation("Marca {Codigo} creada en Visions desde NEXO", item.Codigo);
            }
            catch (Exception ex) { _logger.LogError(ex, "Error al crear marca {Codigo} en Visions", item.Codigo); }
        }
    }

    // ──────── GRUPOS MAYOR ────────

    private async Task SincronizarGruposMayorAsync(CancellationToken ct)
    {
        var enNexo = await _apiClient.ListarGruposMayorSyncAsync(ct);
        var codigosNexo = enNexo.Select(g => g.Codigo).ToHashSet(StringComparer.OrdinalIgnoreCase);

        using var connection = _visionsDb.CreateConnection();
        var enVisions = (await connection.QueryAsync<GrupoMayorSyncDto>(
            "SELECT CODIGO AS Codigo, NOMBRE AS Nombre FROM dbo.GRUPOMAYOR")).ToList();

        var codigosVisions = enVisions.Select(g => g.Codigo).ToHashSet(StringComparer.OrdinalIgnoreCase);

        foreach (var item in enVisions.Where(g => !codigosNexo.Contains(g.Codigo)))
        {
            try
            {
                await _apiClient.UpsertGrupoMayorEnNexoAsync(item, ct);
                _logger.LogInformation("GrupoMayor {Codigo} creado en NEXO", item.Codigo);
            }
            catch (Exception ex) { _logger.LogError(ex, "Error al exportar GrupoMayor {Codigo} a NEXO", item.Codigo); }
        }

        foreach (var item in enNexo.Where(g => !codigosVisions.Contains(g.Codigo)))
        {
            try
            {
                await connection.ExecuteAsync(
                    @"MERGE dbo.GRUPOMAYOR AS d
                      USING (SELECT @Codigo AS CODIGO) AS s ON d.CODIGO = s.CODIGO
                      WHEN MATCHED THEN UPDATE SET NOMBRE = @Nombre
                      WHEN NOT MATCHED THEN INSERT (CODIGO, NOMBRE) VALUES (@Codigo, @Nombre);",
                    new { item.Codigo, Nombre = item.Nombre ?? item.Codigo });
                _logger.LogInformation("GrupoMayor {Codigo} creado en Visions", item.Codigo);
            }
            catch (Exception ex) { _logger.LogError(ex, "Error al crear GrupoMayor {Codigo} en Visions", item.Codigo); }
        }
    }

    // ──────── GRUPOS MENOR ────────

    private async Task SincronizarGruposMenorAsync(CancellationToken ct)
    {
        var enNexo = await _apiClient.ListarGruposMenorSyncAsync(ct);
        var codigosNexo = enNexo.Select(g => g.Codigo).ToHashSet(StringComparer.OrdinalIgnoreCase);

        using var connection = _visionsDb.CreateConnection();
        var enVisions = (await connection.QueryAsync<GrupoMenorSyncDto>(
            "SELECT CODIGO AS Codigo, NOMBRE AS Nombre, GRUPOMAYOR AS GrupoMayor FROM dbo.GRUPOMENOR")).ToList();

        var codigosVisions = enVisions.Select(g => g.Codigo).ToHashSet(StringComparer.OrdinalIgnoreCase);

        foreach (var item in enVisions.Where(g => !codigosNexo.Contains(g.Codigo)))
        {
            try
            {
                await _apiClient.UpsertGrupoMenorEnNexoAsync(item, ct);
                _logger.LogInformation("GrupoMenor {Codigo} creado en NEXO", item.Codigo);
            }
            catch (Exception ex) { _logger.LogError(ex, "Error al exportar GrupoMenor {Codigo} a NEXO", item.Codigo); }
        }

        foreach (var item in enNexo.Where(g => !codigosVisions.Contains(g.Codigo)))
        {
            try
            {
                var existeMayor = await connection.ExecuteScalarAsync<int>(
                    "SELECT COUNT(1) FROM dbo.GRUPOMAYOR WHERE CODIGO = @GM",
                    new { GM = item.GrupoMayor });
                if (existeMayor == 0)
                {
                    _logger.LogWarning("GrupoMenor {Codigo}: GrupoMayor {GM} no existe en Visions, se reintentara en la proxima ronda", item.Codigo, item.GrupoMayor);
                    continue;
                }

                await connection.ExecuteAsync(
                    @"MERGE dbo.GRUPOMENOR AS d
                      USING (SELECT @Codigo AS CODIGO) AS s ON d.CODIGO = s.CODIGO
                      WHEN MATCHED THEN UPDATE SET NOMBRE = @Nombre, GRUPOMAYOR = @GrupoMayor
                      WHEN NOT MATCHED THEN INSERT (CODIGO, NOMBRE, GRUPOMAYOR) VALUES (@Codigo, @Nombre, @GrupoMayor);",
                    new { item.Codigo, Nombre = item.Nombre ?? item.Codigo, item.GrupoMayor });
                _logger.LogInformation("GrupoMenor {Codigo} creado en Visions", item.Codigo);
            }
            catch (Exception ex) { _logger.LogError(ex, "Error al crear GrupoMenor {Codigo} en Visions", item.Codigo); }
        }
    }

    // ──────── IVA ────────

    private async Task SincronizarIvaAsync(CancellationToken ct)
    {
        var enNexo = await _apiClient.ListarIvaSyncAsync(ct);
        var valoresNexo = enNexo.Select(i => i.IvaValor).ToHashSet();

        using var connection = _visionsDb.CreateConnection();
        var enVisions = (await connection.QueryAsync<IvaSyncDto>(
            "SELECT Id AS IvaID, IVA AS IvaValor, DESCRIPCION AS Descripcion FROM dbo.IVA")).ToList();

        var valoresVisions = enVisions.Select(i => i.IvaValor).ToHashSet();

        foreach (var item in enVisions.Where(i => !valoresNexo.Contains(i.IvaValor)))
        {
            try
            {
                await _apiClient.UpsertIvaEnNexoAsync(item, ct);
                _logger.LogInformation("IVA {Valor}% creado en NEXO", item.IvaValor);
            }
            catch (Exception ex) { _logger.LogError(ex, "Error al exportar IVA {Valor}% a NEXO", item.IvaValor); }
        }

        foreach (var item in enNexo.Where(i => !valoresVisions.Contains(i.IvaValor)))
        {
            try
            {
                await connection.ExecuteAsync(
                    @"MERGE dbo.IVA AS d
                      USING (SELECT @IvaValor AS IVA) AS s ON d.IVA = s.IVA
                      WHEN MATCHED THEN UPDATE SET DESCRIPCION = @Descripcion
                      WHEN NOT MATCHED THEN INSERT (IVA, DESCRIPCION) VALUES (@IvaValor, @Descripcion);",
                    new { item.IvaValor, Descripcion = item.Descripcion ?? $"IVA {item.IvaValor}%" });
                _logger.LogInformation("IVA {Valor}% creado en Visions", item.IvaValor);
            }
            catch (Exception ex) { _logger.LogError(ex, "Error al crear IVA {Valor}% en Visions", item.IvaValor); }
        }
    }

    // ──────── PRESENTACIONES ────────

    private async Task SincronizarPresentacionesAsync(CancellationToken ct)
    {
        var enNexo = await _apiClient.ListarPresentacionesSyncAsync(ct);
        var codigosNexo = enNexo.Select(p => p.Codigo).ToHashSet(StringComparer.OrdinalIgnoreCase);

        using var connection = _visionsDb.CreateConnection();
        var enVisions = (await connection.QueryAsync<PresentacionSyncDto>(
            "SELECT CODIGO AS Codigo, PRESENTACION AS Presentacion, FRACCIONES AS Fracciones FROM dbo.PRESENTACION")).ToList();

        var codigosVisions = enVisions.Select(p => p.Codigo).ToHashSet(StringComparer.OrdinalIgnoreCase);

        foreach (var item in enVisions.Where(p => !codigosNexo.Contains(p.Codigo)))
        {
            try
            {
                await _apiClient.UpsertPresentacionEnNexoAsync(item, ct);
                _logger.LogInformation("Presentacion {Codigo} creada en NEXO", item.Codigo);
            }
            catch (Exception ex) { _logger.LogError(ex, "Error al exportar Presentacion {Codigo} a NEXO", item.Codigo); }
        }

        foreach (var item in enNexo.Where(p => !codigosVisions.Contains(p.Codigo)))
        {
            try
            {
                await connection.ExecuteAsync(
                    @"MERGE dbo.PRESENTACION AS d
                      USING (SELECT @Codigo AS CODIGO) AS s ON d.CODIGO = s.CODIGO
                      WHEN MATCHED THEN UPDATE SET PRESENTACION = @Presentacion, FRACCIONES = @Fracciones
                      WHEN NOT MATCHED THEN INSERT (CODIGO, PRESENTACION, FRACCIONES) VALUES (@Codigo, @Presentacion, @Fracciones);",
                    new { item.Codigo, item.Presentacion, item.Fracciones });
                _logger.LogInformation("Presentacion {Codigo} creada en Visions", item.Codigo);
            }
            catch (Exception ex) { _logger.LogError(ex, "Error al crear Presentacion {Codigo} en Visions", item.Codigo); }
        }
    }
}
