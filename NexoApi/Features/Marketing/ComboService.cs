using Dapper;
using NexoApi.Common.Data;
using NexoApi.Features.Marketing.Dtos;

namespace NexoApi.Features.Marketing;

public interface IComboService
{
    Task<IEnumerable<ComboItem>> ListarAsync(string? estado);
    Task<IEnumerable<ComboItem>> ListarActivosAsync();
    Task<ComboDetalle?> ObtenerAsync(int id);
    Task<int> CrearAsync(CrearComboRequest r, int usuarioId);
    Task ActualizarAsync(int id, ActualizarComboRequest r);
    Task<decimal?> CalcularPrecioAsync(int id);
}

public class ComboService : IComboService
{
    private readonly IDbConnectionFactory _db;
    public ComboService(IDbConnectionFactory db) => _db = db;

    private record ItemCrudo(
        int ComboItemID, int ComboID, int ArticuloID, string SKU, string NombreArticulo,
        decimal Cantidad, string? Unidad, decimal? PrecioUnitarioSnapshot, decimal? PrecioVenta
    );

    private record DetalleRow(
        int ComboID, string Nombre, string? Descripcion,
        string? ImagenBase64, string? ImagenContentType,
        string Estado, string ModoPrecio,
        DateTime? FechaInicio, DateTime? FechaFin,
        decimal? PrecioManual, decimal PorcentajeDescuento,
        DateTime FechaCreacion
    );

    private record ListaRow(
        int ComboID, string Nombre, string? Descripcion, string Estado, string ModoPrecio,
        DateTime? FechaInicio, DateTime? FechaFin, decimal? PrecioManual, decimal PorcentajeDescuento,
        string? ImagenBase64, string? ImagenContentType,
        DateTime FechaCreacion, decimal? PrecioCalculado
    );

    private static ComboItem RowToItem(ListaRow r, IEnumerable<ItemCrudo> items) => new(
        r.ComboID, r.Nombre, r.Descripcion, r.Estado, r.ModoPrecio,
        r.FechaInicio.HasValue ? DateOnly.FromDateTime(r.FechaInicio.Value) : null,
        r.FechaFin.HasValue    ? DateOnly.FromDateTime(r.FechaFin.Value)    : null,
        r.PrecioManual, r.PorcentajeDescuento, r.PrecioCalculado,
        r.ImagenBase64, r.ImagenContentType, r.FechaCreacion,
        items.Select(i => new ComboItemLine(i.ComboItemID, i.ArticuloID, i.SKU, i.NombreArticulo, i.Cantidad, i.Unidad, i.PrecioUnitarioSnapshot)).ToList()
    );

    private const string SqlItems = @"
        SELECT ci.ComboItemID, ci.ComboID, ci.ArticuloID, a.SKU, a.Nombre AS NombreArticulo,
               ci.Cantidad, um.Abreviatura AS Unidad, ci.PrecioUnitarioSnapshot, a.PrecioVenta
        FROM Marketing.ComboItems ci
        JOIN Catalogo.Articulos a ON a.ArticuloID = ci.ArticuloID
        LEFT JOIN Catalogo.UnidadesMedida um ON um.UnidadID = a.UnidadID
        WHERE ci.ComboID IN @Ids";

    private static async Task<List<ItemCrudo>> CargarItemsAsync(
        System.Data.IDbConnection con, IEnumerable<int> ids)
    {
        var arr = ids.ToArray();
        if (arr.Length == 0) return [];
        return (await con.QueryAsync<ItemCrudo>(SqlItems, new { Ids = arr })).ToList();
    }

    public async Task<IEnumerable<ComboItem>> ListarAsync(string? estado)
    {
        using var con = _db.CreateConnection();
        const string sql = @"
            SELECT c.ComboID, c.Nombre, c.Descripcion, c.Estado, c.ModoPrecio,
                   c.FechaInicio, c.FechaFin, c.PrecioManual, c.PorcentajeDescuento,
                   c.ImagenBase64, c.ImagenContentType,
                   c.FechaCreacion,
                   (SELECT SUM(a.PrecioVenta * ci.Cantidad) * (1 - c.PorcentajeDescuento / 100.0)
                    FROM Marketing.ComboItems ci
                    JOIN Catalogo.Articulos a ON a.ArticuloID = ci.ArticuloID
                    WHERE ci.ComboID = c.ComboID) AS PrecioCalculado
            FROM Marketing.Combos c
            WHERE (@Estado IS NULL OR c.Estado = @Estado)
            ORDER BY c.FechaCreacion DESC";

        var rows = (await con.QueryAsync<ListaRow>(sql, new { Estado = estado })).ToList();
        var items = await CargarItemsAsync(con, rows.Select(r => r.ComboID));
        return rows.Select(r => RowToItem(r, items.Where(i => i.ComboID == r.ComboID)));
    }

    public async Task<IEnumerable<ComboItem>> ListarActivosAsync()
    {
        using var con = _db.CreateConnection();
        const string sql = @"
            SELECT c.ComboID, c.Nombre, c.Descripcion, c.Estado, c.ModoPrecio,
                   c.FechaInicio, c.FechaFin, c.PrecioManual, c.PorcentajeDescuento,
                   c.ImagenBase64, c.ImagenContentType,
                   c.FechaCreacion,
                   (SELECT SUM(a.PrecioVenta * ci.Cantidad) * (1 - c.PorcentajeDescuento / 100.0)
                    FROM Marketing.ComboItems ci
                    JOIN Catalogo.Articulos a ON a.ArticuloID = ci.ArticuloID
                    WHERE ci.ComboID = c.ComboID) AS PrecioCalculado
            FROM Marketing.Combos c
            WHERE c.Estado = 'Activo'
              AND (c.FechaInicio IS NULL OR c.FechaInicio <= CAST(GETDATE() AS DATE))
              AND (c.FechaFin IS NULL OR c.FechaFin >= CAST(GETDATE() AS DATE))
            ORDER BY c.Nombre";

        var rows = (await con.QueryAsync<ListaRow>(sql)).ToList();
        var items = await CargarItemsAsync(con, rows.Select(r => r.ComboID));
        return rows.Select(r => RowToItem(r, items.Where(i => i.ComboID == r.ComboID)));
    }

    public async Task<ComboDetalle?> ObtenerAsync(int id)
    {
        using var con = _db.CreateConnection();

        var combo = await con.QueryFirstOrDefaultAsync<DetalleRow>(
            "SELECT ComboID, Nombre, Descripcion, ImagenBase64, ImagenContentType, Estado, ModoPrecio, FechaInicio, FechaFin, PrecioManual, PorcentajeDescuento, FechaCreacion FROM Marketing.Combos WHERE ComboID = @id",
            new { id });
        if (combo is null) return null;

        var items = (await con.QueryAsync<ItemCrudo>(@"
            SELECT ci.ComboItemID, ci.ArticuloID, a.SKU, a.Nombre AS NombreArticulo,
                   ci.Cantidad, um.Abreviatura AS Unidad, ci.PrecioUnitarioSnapshot, a.PrecioVenta
            FROM Marketing.ComboItems ci
            JOIN Catalogo.Articulos a ON a.ArticuloID = ci.ArticuloID
            LEFT JOIN Catalogo.UnidadesMedida um ON um.UnidadID = a.UnidadID
            WHERE ci.ComboID = @id
            ORDER BY ci.ComboItemID", new { id })).ToList();

        decimal? precioCalculado = items.Count > 0
            ? items.Sum(i => (i.PrecioVenta ?? 0) * i.Cantidad) * (1m - combo.PorcentajeDescuento / 100m)
            : null;

        DateOnly? fi = combo.FechaInicio.HasValue ? DateOnly.FromDateTime(combo.FechaInicio.Value) : null;
        DateOnly? ff = combo.FechaFin.HasValue    ? DateOnly.FromDateTime(combo.FechaFin.Value)    : null;

        return new ComboDetalle(
            combo.ComboID, combo.Nombre, combo.Descripcion,
            combo.ImagenBase64, combo.ImagenContentType,
            combo.Estado, combo.ModoPrecio, fi, ff,
            combo.PrecioManual, combo.PorcentajeDescuento, precioCalculado,
            items.Select(i => new ComboItemLine(i.ComboItemID, i.ArticuloID, i.SKU, i.NombreArticulo, i.Cantidad, i.Unidad, i.PrecioUnitarioSnapshot)).ToList(),
            combo.FechaCreacion
        );
    }

    public async Task<int> CrearAsync(CrearComboRequest r, int usuarioId)
    {
        using var con = _db.CreateConnection();
        con.Open();
        using var tx = con.BeginTransaction();

        var id = await con.ExecuteScalarAsync<int>(@"
            INSERT INTO Marketing.Combos (Nombre,Descripcion,ImagenBase64,ImagenContentType,Estado,ModoPrecio,FechaInicio,FechaFin,PrecioManual,PorcentajeDescuento,UsuarioCreaID)
            OUTPUT INSERTED.ComboID
            VALUES (@Nombre,@Descripcion,@ImagenBase64,@ImagenContentType,@Estado,@ModoPrecio,@FechaInicio,@FechaFin,@PrecioManual,@PorcentajeDescuento,@UsuarioID)",
            new { r.Nombre, r.Descripcion, r.ImagenBase64, r.ImagenContentType, r.Estado, r.ModoPrecio,
                  FechaInicio = r.FechaInicio.HasValue ? (DateTime?)r.FechaInicio.Value.ToDateTime(TimeOnly.MinValue) : null,
                  FechaFin    = r.FechaFin.HasValue    ? (DateTime?)r.FechaFin.Value.ToDateTime(TimeOnly.MinValue)    : null,
                  r.PrecioManual, r.PorcentajeDescuento, UsuarioID = usuarioId }, tx);

        await InsertarItemsAsync(con, tx, id, r.Items);
        tx.Commit();
        return id;
    }

    public async Task ActualizarAsync(int id, ActualizarComboRequest r)
    {
        using var con = _db.CreateConnection();
        con.Open();
        using var tx = con.BeginTransaction();

        var rows = await con.ExecuteAsync(@"
            UPDATE Marketing.Combos
            SET Nombre=@Nombre, Descripcion=@Descripcion, ImagenBase64=@ImagenBase64, ImagenContentType=@ImagenContentType,
                Estado=@Estado, ModoPrecio=@ModoPrecio, FechaInicio=@FechaInicio, FechaFin=@FechaFin,
                PrecioManual=@PrecioManual, PorcentajeDescuento=@PorcentajeDescuento
            WHERE ComboID=@ID",
            new { r.Nombre, r.Descripcion, r.ImagenBase64, r.ImagenContentType, r.Estado, r.ModoPrecio,
                  FechaInicio = r.FechaInicio.HasValue ? (DateTime?)r.FechaInicio.Value.ToDateTime(TimeOnly.MinValue) : null,
                  FechaFin    = r.FechaFin.HasValue    ? (DateTime?)r.FechaFin.Value.ToDateTime(TimeOnly.MinValue)    : null,
                  r.PrecioManual, r.PorcentajeDescuento, ID = id }, tx);

        if (rows == 0) throw new KeyNotFoundException($"Combo {id} no encontrado.");

        await con.ExecuteAsync("DELETE FROM Marketing.ComboItems WHERE ComboID=@id", new { id }, tx);
        await InsertarItemsAsync(con, tx, id, r.Items);
        tx.Commit();
    }

    public async Task<decimal?> CalcularPrecioAsync(int id)
    {
        using var con = _db.CreateConnection();
        return await con.ExecuteScalarAsync<decimal?>(@"
            SELECT SUM(a.PrecioVenta * ci.Cantidad) * (1 - c.PorcentajeDescuento / 100.0)
            FROM Marketing.ComboItems ci
            JOIN Catalogo.Articulos a ON a.ArticuloID = ci.ArticuloID
            JOIN Marketing.Combos c ON c.ComboID = ci.ComboID
            WHERE ci.ComboID = @id", new { id });
    }

    private static async Task InsertarItemsAsync(
        System.Data.IDbConnection con, System.Data.IDbTransaction tx,
        int comboId, List<ComboItemInput> items)
    {
        if (items.Count == 0) return;
        const string sql = @"
            INSERT INTO Marketing.ComboItems (ComboID, ArticuloID, Cantidad, PrecioUnitarioSnapshot)
            SELECT @ComboID, @ArticuloID, @Cantidad,
                   (SELECT PrecioVenta FROM Catalogo.Articulos WHERE ArticuloID = @ArticuloID)";
        foreach (var item in items)
            await con.ExecuteAsync(sql, new { ComboID = comboId, item.ArticuloID, item.Cantidad }, tx);
    }
}
