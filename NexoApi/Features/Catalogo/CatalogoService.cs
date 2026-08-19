using Dapper;
using NexoApi.Common.Data;
using NexoApi.Features.Catalogo.Dtos;


namespace NexoApi.Features.Catalogo;

public interface ICatalogoService
{
    // Centros de Costo
    Task<int> CrearCentroCostoAsync(CrearCentroCostoRequest request);
    Task<IEnumerable<CentroCostoItem>> ListarCentrosCostoAsync(bool soloActivos);
    Task ActualizarCentroCostoAsync(int centroCostoId, ActualizarCentroCostoRequest request);

    // Bodegas
    Task<int> CrearBodegaAsync(CrearBodegaRequest request);
    Task<IEnumerable<BodegaItem>> ListarBodegasAsync(int? centroCostoId);
    Task ActualizarBodegaAsync(int bodegaId, ActualizarBodegaRequest request);
    Task DesactivarBodegaAsync(int bodegaId);

    // Articulos / Tarjetas
    Task<int> CrearArticuloAsync(CrearArticuloRequest request);
    Task<IEnumerable<ArticuloItem>> ListarArticulosAsync(int? tipoArticuloId, string? texto);
    Task<ArticuloItem?> ObtenerArticuloAsync(int articuloId);
    Task ActualizarArticuloAsync(int articuloId, ActualizarArticuloRequest request);
    Task<(byte[] Datos, string ContentType)?> ObtenerImagenArticuloAsync(int articuloId);
    Task ActualizarImagenArticuloAsync(int articuloId, ActualizarImagenRequest request);
    Task EliminarImagenArticuloAsync(int articuloId);

    Task<IEnumerable<CentroTrabajoItem>> ListarCentrosTrabajoAsync(bool soloActivos);
    Task<int> CrearCentroTrabajoAsync(CrearCentroTrabajoRequest request);
    Task ActualizarCentroTrabajoAsync(int centroTrabajoId, ActualizarCentroTrabajoRequest request);

    Task<IEnumerable<ProveedorItem>> ListarProveedoresAsync();
    Task<int> CrearProveedorAsync(CrearProveedorRequest request);
    Task ActualizarProveedorAsync(int proveedorId, ActualizarProveedorRequest request);

    Task<IEnumerable<TipoArticuloItem>> ListarTiposArticuloAsync();
    Task<IEnumerable<UnidadMedidaItem>> ListarUnidadesMedidaAsync();

    // Catalogo: Iva (calca de dbo.IVA de Visions)
    Task<IEnumerable<IvaItem>> ListarIvasAsync();
    Task<int> CrearIvaAsync(CrearIvaRequest request);
    Task ActualizarIvaAsync(int ivaId, ActualizarIvaRequest request);
    Task EliminarIvaAsync(int ivaId);

    // Catalogos Visions: GruposMayores, GruposMenores, Marcas, Presentaciones
    Task<IEnumerable<GrupoMayorItem>> ListarGruposMayoresAsync();
    Task CrearGrupoMayorAsync(CrearGrupoMayorRequest request);
    Task ActualizarGrupoMayorAsync(string codigo, ActualizarGrupoMayorRequest request);
    Task EliminarGrupoMayorAsync(string codigo);

    Task<IEnumerable<GrupoMenorItem>> ListarGruposMenoresAsync(string? grupoMayor);
    Task CrearGrupoMenorAsync(CrearGrupoMenorRequest request);
    Task ActualizarGrupoMenorAsync(string codigo, string grupoMayor, ActualizarGrupoMenorRequest request);
    Task EliminarGrupoMenorAsync(string codigo, string grupoMayor);

    Task<IEnumerable<MarcaItem>> ListarMarcasAsync();
    Task CrearMarcaAsync(CrearMarcaRequest request);
    Task ActualizarMarcaAsync(string codigo, ActualizarMarcaRequest request);
    Task EliminarMarcaAsync(string codigo);

    Task<IEnumerable<PresentacionItem>> ListarPresentacionesAsync();
    Task CrearPresentacionAsync(CrearPresentacionRequest request);
    Task ActualizarPresentacionAsync(string codigo, ActualizarPresentacionRequest request);
    Task EliminarPresentacionAsync(string codigo);
}

public class CatalogoService : ICatalogoService
{
    private readonly IDbConnectionFactory _db;

    public CatalogoService(IDbConnectionFactory db)
    {
        _db = db;
    }

    // ================= Centros de Costo =================

    public async Task<int> CrearCentroCostoAsync(CrearCentroCostoRequest r)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            INSERT INTO Organizacion.CentrosCosto (Codigo, Nombre, TipoCentro, Direccion, Telefono)
            OUTPUT INSERTED.CentroCostoID
            VALUES (@Codigo, @Nombre, @TipoCentro, @Direccion, @Telefono)";

        return await connection.ExecuteScalarAsync<int>(sql, r);
    }

    public async Task<IEnumerable<CentroCostoItem>> ListarCentrosCostoAsync(bool soloActivos)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT CentroCostoID, Codigo, Nombre, TipoCentro, Direccion, Estado,
                   TieneVisions, IdentificadorClienteVisions, BodegaVentaVisionsID,
                   PrefijosDocumentoVentaVisions
            FROM Organizacion.CentrosCosto
            WHERE (@SoloActivos = 0 OR Estado = 1)
            ORDER BY Nombre";

        return await connection.QueryAsync<CentroCostoItem>(sql, new { SoloActivos = soloActivos });
    }

    public async Task ActualizarCentroCostoAsync(int centroCostoId, ActualizarCentroCostoRequest r)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            UPDATE Organizacion.CentrosCosto
            SET Nombre = @Nombre, Direccion = @Direccion, Telefono = @Telefono, Estado = @Estado,
                TieneVisions = @TieneVisions, IdentificadorClienteVisions = @IdentificadorClienteVisions,
                BodegaVentaVisionsID = @BodegaVentaVisionsID,
                PrefijosDocumentoVentaVisions = @PrefijosDocumentoVentaVisions
            WHERE CentroCostoID = @CentroCostoId";

        var filas = await connection.ExecuteAsync(sql, new
        {
            CentroCostoId = centroCostoId,
            r.Nombre,
            r.Direccion,
            r.Telefono,
            r.Estado,
            r.TieneVisions,
            r.IdentificadorClienteVisions,
            r.BodegaVentaVisionsID,
            r.PrefijosDocumentoVentaVisions
        });

        if (filas == 0)
            throw new KeyNotFoundException($"No existe el centro de costo {centroCostoId}.");
    }

    // ================= Bodegas =================

    public async Task<int> CrearBodegaAsync(CrearBodegaRequest r)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            INSERT INTO Inventario.Bodegas (Nombre, CentroCostoID, TipoBodega, EsVirtual)
            OUTPUT INSERTED.BodegaID
            VALUES (@Nombre, @CentroCostoID, @TipoBodega, @EsVirtual)";

        return await connection.ExecuteScalarAsync<int>(sql, r);
    }

    public async Task<IEnumerable<BodegaItem>> ListarBodegasAsync(int? centroCostoId)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT b.BodegaID, b.Nombre, b.CentroCostoID, cc.Nombre AS CentroCosto,
                   b.TipoBodega, b.EsVirtual, b.Estado
            FROM Inventario.Bodegas b
            JOIN Organizacion.CentrosCosto cc ON cc.CentroCostoID = b.CentroCostoID
            WHERE (@CentroCostoId IS NULL OR b.CentroCostoID = @CentroCostoId)
            ORDER BY cc.Nombre, b.Nombre";

        return await connection.QueryAsync<BodegaItem>(sql, new { CentroCostoId = centroCostoId });
    }

    public async Task ActualizarBodegaAsync(int bodegaId, ActualizarBodegaRequest r)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            UPDATE Inventario.Bodegas
            SET Nombre = @Nombre, TipoBodega = @TipoBodega, EsVirtual = @EsVirtual, Estado = @Estado
            WHERE BodegaID = @BodegaId";

        var filas = await connection.ExecuteAsync(sql, new
        {
            BodegaId = bodegaId,
            r.Nombre,
            r.TipoBodega,
            r.EsVirtual,
            r.Estado
        });

        if (filas == 0)
            throw new KeyNotFoundException($"No existe la bodega {bodegaId}.");
    }

    public async Task DesactivarBodegaAsync(int bodegaId)
    {
        using var connection = _db.CreateConnection();

        var filas = await connection.ExecuteAsync(
            "UPDATE Inventario.Bodegas SET Estado = 0 WHERE BodegaID = @BodegaId",
            new { BodegaId = bodegaId });

        if (filas == 0)
            throw new KeyNotFoundException($"No existe la bodega {bodegaId}.");
    }

    // ================= Articulos / Tarjetas =================

    public async Task<int> CrearArticuloAsync(CrearArticuloRequest r)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            INSERT INTO Catalogo.Tarjetas
                (Referencia, Nombre, Descripcion, TipoArticuloID, StockMinimo, PuntoReorden,
                 DiasVidaUtil, Fracciona, PrecioVentaUnidad,
                 Costo, PPublico, PBodega, PCredito, UPublico, UBodega, UCredito,
                 MarcaCodigo, GrupoMenorCodigo, PresentacionCodigo,
                 Peso, IvaSiNo, IvaValor, IvaDescripcion, Iva2, IvaDescripcion2)
            OUTPUT INSERTED.ArticuloID
            VALUES
                (@Referencia, @Nombre, @Descripcion, @TipoArticuloID, @StockMinimo, @PuntoReorden,
                 @DiasVidaUtil, ISNULL(@Fracciona, 'SI'), @PrecioVentaUnidad,
                 @Costo, @PPublico, @PBodega, @PCredito, @UPublico, @UBodega, @UCredito,
                 @MarcaCodigo, @GrupoMenorCodigo, @PresentacionCodigo,
                 @Peso, @IvaSiNo, @IvaValor, @IvaDescripcion, @Iva2, @IvaDescripcion2)";

        return await connection.ExecuteScalarAsync<int>(sql, r);
    }

    public async Task<IEnumerable<ArticuloItem>> ListarArticulosAsync(int? tipoArticuloId, string? texto)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT a.ArticuloID, a.Referencia, a.Nombre, a.Descripcion, ta.Nombre AS TipoArticulo,
                   a.CostoPromedio, a.StockMinimo, a.PuntoReorden, a.Estado,
                   (SELECT ISNULL(SUM(ist.CantidadActual),0) FROM Inventario.InventarioStock ist WHERE ist.ArticuloID = a.ArticuloID) AS Existencias,
                   a.DiasVidaUtil,
                   p.Fracciones,
                   CAST(CASE WHEN a.Imagen IS NULL THEN 0 ELSE 1 END AS BIT) AS TieneImagen,
                   a.Fracciona, a.PrecioVentaUnidad,
                   a.Costo,
                   a.PPublico, a.PBodega, a.PCredito,
                   a.UPublico,  a.UBodega, a.UCredito,
                   a.MarcaCodigo, m.Marca AS MarcaNombre,
                   a.GrupoMenorCodigo, gm.Nombre AS GrupoMenorNombre,
                   gm.GrupoMayor AS GrupoMayorCodigo, gmay.Nombre AS GrupoMayorNombre,
                   a.PresentacionCodigo, p.Presentacion AS PresentacionNombre,
                   a.Peso, a.IvaSiNo, a.IvaValor, a.IvaDescripcion,
                   a.Iva2, a.IvaDescripcion2
            FROM Catalogo.Tarjetas a
            JOIN Catalogo.TiposArticulo ta ON ta.TipoArticuloID = a.TipoArticuloID
            LEFT JOIN Catalogo.Marca m ON m.Codigo = a.MarcaCodigo
            LEFT JOIN Catalogo.GrupoMenor gm ON gm.Codigo = a.GrupoMenorCodigo
            LEFT JOIN Catalogo.GrupoMayor gmay ON gmay.Codigo = gm.GrupoMayor
            LEFT JOIN Catalogo.Presentacion p ON p.Codigo = a.PresentacionCodigo
            WHERE (@TipoArticuloId IS NULL OR a.TipoArticuloID = @TipoArticuloId)
              AND (@Texto IS NULL OR a.Nombre LIKE '%' + @Texto + '%' OR a.Referencia LIKE '%' + @Texto + '%')
            ORDER BY a.Nombre";

        return await connection.QueryAsync<ArticuloItem>(sql, new { TipoArticuloId = tipoArticuloId, Texto = texto });
    }

    public async Task<ArticuloItem?> ObtenerArticuloAsync(int articuloId)
    {
        using var connection = _db.CreateConnection();
        const string sql = @"
            SELECT a.ArticuloID, a.Referencia, a.Nombre, a.Descripcion, ta.Nombre AS TipoArticulo,
                   a.CostoPromedio, a.StockMinimo, a.PuntoReorden, a.Estado,
                   (SELECT ISNULL(SUM(ist.CantidadActual),0) FROM Inventario.InventarioStock ist WHERE ist.ArticuloID = a.ArticuloID) AS Existencias,
                   a.DiasVidaUtil,
                   p.Fracciones,
                   CAST(CASE WHEN a.Imagen IS NULL THEN 0 ELSE 1 END AS BIT) AS TieneImagen,
                   a.Fracciona, a.PrecioVentaUnidad,
                   a.Costo,
                   a.PPublico, a.PBodega, a.PCredito,
                   a.UPublico,  a.UBodega, a.UCredito,
                   a.MarcaCodigo, m.Marca AS MarcaNombre,
                   a.GrupoMenorCodigo, gm.Nombre AS GrupoMenorNombre,
                   gm.GrupoMayor AS GrupoMayorCodigo, gmay.Nombre AS GrupoMayorNombre,
                   a.PresentacionCodigo, p.Presentacion AS PresentacionNombre,
                   a.Peso, a.IvaSiNo, a.IvaValor, a.IvaDescripcion,
                   a.Iva2, a.IvaDescripcion2
            FROM Catalogo.Tarjetas a
            JOIN Catalogo.TiposArticulo ta ON ta.TipoArticuloID = a.TipoArticuloID
            LEFT JOIN Catalogo.Marca m ON m.Codigo = a.MarcaCodigo
            LEFT JOIN Catalogo.GrupoMenor gm ON gm.Codigo = a.GrupoMenorCodigo
            LEFT JOIN Catalogo.GrupoMayor gmay ON gmay.Codigo = gm.GrupoMayor
            LEFT JOIN Catalogo.Presentacion p ON p.Codigo = a.PresentacionCodigo
            WHERE a.ArticuloID = @ArticuloId";

        return await connection.QueryFirstOrDefaultAsync<ArticuloItem>(sql, new { ArticuloId = articuloId });
    }

    public async Task ActualizarArticuloAsync(int articuloId, ActualizarArticuloRequest r)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            UPDATE Catalogo.Tarjetas
            SET Nombre = @Nombre, Descripcion = @Descripcion,
                StockMinimo = @StockMinimo, PuntoReorden = @PuntoReorden, DiasVidaUtil = @DiasVidaUtil,
                Estado = @Estado,
                Fracciona = ISNULL(@Fracciona, 'SI'), PrecioVentaUnidad = @PrecioVentaUnidad,
                Costo = @Costo,
                PPublico = @PPublico, PBodega = @PBodega, PCredito = @PCredito,
                UPublico = @UPublico, UBodega = @UBodega, UCredito = @UCredito,
                MarcaCodigo = @MarcaCodigo, GrupoMenorCodigo = @GrupoMenorCodigo,
                PresentacionCodigo = @PresentacionCodigo,
                Peso = @Peso, IvaSiNo = @IvaSiNo, IvaValor = @IvaValor, IvaDescripcion = @IvaDescripcion,
                Iva2 = @Iva2, IvaDescripcion2 = @IvaDescripcion2,
                FechaModificacion = GETDATE()
            WHERE ArticuloID = @ArticuloId";

        var filas = await connection.ExecuteAsync(sql, new
        {
            ArticuloId = articuloId,
            r.Nombre, r.Descripcion, r.StockMinimo, r.PuntoReorden,
            r.DiasVidaUtil, r.Estado, r.Fracciona, r.PrecioVentaUnidad,
            r.Costo,
            r.PPublico, r.PBodega, r.PCredito,
            r.UPublico,  r.UBodega, r.UCredito,
            r.MarcaCodigo, r.GrupoMenorCodigo, r.PresentacionCodigo,
            r.Peso, r.IvaSiNo, r.IvaValor, r.IvaDescripcion,
            r.Iva2, r.IvaDescripcion2
        });

        if (filas == 0)
            throw new KeyNotFoundException($"No existe el articulo {articuloId}.");

        await connection.ExecuteAsync(@"
            INSERT INTO Integracion.EventosSalientes (TipoEvento, CentroCostoID, ArticuloID, Cantidad, CostoUnitario)
            SELECT 'SINCRONIZAR_ARTICULO', ma.CentroCostoID, ma.ArticuloID, 0, ISNULL(a.CostoPromedio, 0)
            FROM Integracion.MapeoArticulos ma
            JOIN Catalogo.Tarjetas a          ON a.ArticuloID    = ma.ArticuloID
            JOIN Organizacion.CentrosCosto cc ON cc.CentroCostoID = ma.CentroCostoID
            WHERE ma.ArticuloID = @ArticuloId AND ma.Estado = 1 AND cc.TieneVisions = 1",
            new { ArticuloId = articuloId });
    }

    private record ImagenArticulo(byte[] Imagen, string ImagenContentType);

    public async Task<(byte[] Datos, string ContentType)?> ObtenerImagenArticuloAsync(int articuloId)
    {
        using var connection = _db.CreateConnection();

        var resultado = await connection.QuerySingleOrDefaultAsync<ImagenArticulo>(
            "SELECT Imagen, ImagenContentType FROM Catalogo.Tarjetas WHERE ArticuloID = @ArticuloId AND Imagen IS NOT NULL",
            new { ArticuloId = articuloId });

        return resultado is null ? null : (resultado.Imagen, resultado.ImagenContentType);
    }

    public async Task ActualizarImagenArticuloAsync(int articuloId, ActualizarImagenRequest r)
    {
        using var connection = _db.CreateConnection();
        var datos = Convert.FromBase64String(r.Base64);

        var filas = await connection.ExecuteAsync(
            "UPDATE Catalogo.Tarjetas SET Imagen = @Datos, ImagenContentType = @ContentType WHERE ArticuloID = @ArticuloId",
            new { ArticuloId = articuloId, Datos = datos, r.ContentType });

        if (filas == 0)
            throw new KeyNotFoundException($"No existe el articulo {articuloId}.");
    }

    public async Task EliminarImagenArticuloAsync(int articuloId)
    {
        using var connection = _db.CreateConnection();

        var filas = await connection.ExecuteAsync(
            "UPDATE Catalogo.Tarjetas SET Imagen = NULL, ImagenContentType = NULL WHERE ArticuloID = @ArticuloId",
            new { ArticuloId = articuloId });

        if (filas == 0)
            throw new KeyNotFoundException($"No existe el articulo {articuloId}.");
    }

    // ================= Iva =================

    public async Task<IEnumerable<IvaItem>> ListarIvasAsync()
    {
        using var connection = _db.CreateConnection();
        return await connection.QueryAsync<IvaItem>(
            "SELECT IvaID, Iva, Descripcion FROM Catalogo.Iva ORDER BY Iva, Descripcion");
    }

    public async Task<int> CrearIvaAsync(CrearIvaRequest r)
    {
        using var connection = _db.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(
            "INSERT INTO Catalogo.Iva (Iva, Descripcion) OUTPUT INSERTED.IvaID VALUES (@Iva, @Descripcion)", r);
    }

    public async Task ActualizarIvaAsync(int ivaId, ActualizarIvaRequest r)
    {
        using var connection = _db.CreateConnection();
        var filas = await connection.ExecuteAsync(
            "UPDATE Catalogo.Iva SET Iva = @Iva, Descripcion = @Descripcion WHERE IvaID = @IvaID",
            new { IvaID = ivaId, r.Iva, r.Descripcion });
        if (filas == 0) throw new KeyNotFoundException($"IVA {ivaId} no encontrado.");
    }

    public async Task EliminarIvaAsync(int ivaId)
    {
        using var connection = _db.CreateConnection();
        var filas = await connection.ExecuteAsync(
            "DELETE FROM Catalogo.Iva WHERE IvaID = @IvaID", new { IvaID = ivaId });
        if (filas == 0) throw new KeyNotFoundException($"IVA {ivaId} no encontrado.");
    }

    // ================= GruposMayores =================

    public async Task<IEnumerable<GrupoMayorItem>> ListarGruposMayoresAsync()
    {
        using var connection = _db.CreateConnection();
        return await connection.QueryAsync<GrupoMayorItem>(
            "SELECT Codigo, Nombre FROM Catalogo.GrupoMayor ORDER BY Nombre");
    }

    public async Task CrearGrupoMayorAsync(CrearGrupoMayorRequest r)
    {
        using var connection = _db.CreateConnection();
        await connection.ExecuteAsync(
            "INSERT INTO Catalogo.GrupoMayor (Codigo, Nombre) VALUES (@Codigo, @Nombre)", r);
    }

    public async Task ActualizarGrupoMayorAsync(string codigo, ActualizarGrupoMayorRequest r)
    {
        using var connection = _db.CreateConnection();
        var filas = await connection.ExecuteAsync(
            "UPDATE Catalogo.GrupoMayor SET Nombre = @Nombre WHERE Codigo = @Codigo",
            new { Codigo = codigo, r.Nombre });
        if (filas == 0) throw new KeyNotFoundException($"GrupoMayor '{codigo}' no encontrado.");
    }

    public async Task EliminarGrupoMayorAsync(string codigo)
    {
        using var connection = _db.CreateConnection();
        var filas = await connection.ExecuteAsync(
            "DELETE FROM Catalogo.GrupoMayor WHERE Codigo = @Codigo", new { Codigo = codigo });
        if (filas == 0) throw new KeyNotFoundException($"GrupoMayor '{codigo}' no encontrado.");
    }

    // ================= GruposMenores =================

    public async Task<IEnumerable<GrupoMenorItem>> ListarGruposMenoresAsync(string? grupoMayor)
    {
        using var connection = _db.CreateConnection();
        const string sql = @"
            SELECT gm.Codigo, gm.Nombre, gm.GrupoMayor, gmay.Nombre AS GrupoMayorNombre
            FROM Catalogo.GrupoMenor gm
            JOIN Catalogo.GrupoMayor gmay ON gmay.Codigo = gm.GrupoMayor
            WHERE (@GrupoMayor IS NULL OR gm.GrupoMayor = @GrupoMayor)
            ORDER BY gmay.Nombre, gm.Nombre";
        return await connection.QueryAsync<GrupoMenorItem>(sql, new { GrupoMayor = grupoMayor });
    }

    public async Task CrearGrupoMenorAsync(CrearGrupoMenorRequest r)
    {
        using var connection = _db.CreateConnection();
        await connection.ExecuteAsync(
            "INSERT INTO Catalogo.GrupoMenor (Codigo, Nombre, GrupoMayor) VALUES (@Codigo, @Nombre, @GrupoMayor)", r);
    }

    public async Task ActualizarGrupoMenorAsync(string codigo, string grupoMayor, ActualizarGrupoMenorRequest r)
    {
        using var connection = _db.CreateConnection();
        var filas = await connection.ExecuteAsync(
            "UPDATE Catalogo.GrupoMenor SET Nombre = @Nombre WHERE Codigo = @Codigo AND GrupoMayor = @GrupoMayor",
            new { Codigo = codigo, GrupoMayor = grupoMayor, r.Nombre });
        if (filas == 0) throw new KeyNotFoundException($"GrupoMenor '{codigo}' / '{grupoMayor}' no encontrado.");
    }

    public async Task EliminarGrupoMenorAsync(string codigo, string grupoMayor)
    {
        using var connection = _db.CreateConnection();
        var filas = await connection.ExecuteAsync(
            "DELETE FROM Catalogo.GrupoMenor WHERE Codigo = @Codigo AND GrupoMayor = @GrupoMayor",
            new { Codigo = codigo, GrupoMayor = grupoMayor });
        if (filas == 0) throw new KeyNotFoundException($"GrupoMenor '{codigo}' / '{grupoMayor}' no encontrado.");
    }

    // ================= Marcas =================

    public async Task<IEnumerable<MarcaItem>> ListarMarcasAsync()
    {
        using var connection = _db.CreateConnection();
        return await connection.QueryAsync<MarcaItem>(
            "SELECT Codigo, Marca AS Nombre FROM Catalogo.Marca ORDER BY Marca");
    }

    public async Task CrearMarcaAsync(CrearMarcaRequest r)
    {
        using var connection = _db.CreateConnection();
        await connection.ExecuteAsync(
            "INSERT INTO Catalogo.Marca (Codigo, Marca) VALUES (@Codigo, @Nombre)", r);
    }

    public async Task ActualizarMarcaAsync(string codigo, ActualizarMarcaRequest r)
    {
        using var connection = _db.CreateConnection();
        var filas = await connection.ExecuteAsync(
            "UPDATE Catalogo.Marca SET Marca = @Nombre WHERE Codigo = @Codigo",
            new { Codigo = codigo, r.Nombre });
        if (filas == 0) throw new KeyNotFoundException($"Marca '{codigo}' no encontrada.");
    }

    public async Task EliminarMarcaAsync(string codigo)
    {
        using var connection = _db.CreateConnection();
        var filas = await connection.ExecuteAsync(
            "DELETE FROM Catalogo.Marca WHERE Codigo = @Codigo", new { Codigo = codigo });
        if (filas == 0) throw new KeyNotFoundException($"Marca '{codigo}' no encontrada.");
    }

    // ================= Presentaciones =================

    public async Task<IEnumerable<PresentacionItem>> ListarPresentacionesAsync()
    {
        using var connection = _db.CreateConnection();
        return await connection.QueryAsync<PresentacionItem>(
            "SELECT Codigo, Presentacion, Fracciones, Tipo FROM Catalogo.Presentacion ORDER BY Presentacion");
    }

    public async Task CrearPresentacionAsync(CrearPresentacionRequest r)
    {
        using var connection = _db.CreateConnection();
        await connection.ExecuteAsync(
            "INSERT INTO Catalogo.Presentacion (Codigo, Presentacion, Fracciones, Tipo) VALUES (@Codigo, @Presentacion, @Fracciones, @Tipo)", r);
    }

    public async Task ActualizarPresentacionAsync(string codigo, ActualizarPresentacionRequest r)
    {
        using var connection = _db.CreateConnection();
        var filas = await connection.ExecuteAsync(
            "UPDATE Catalogo.Presentacion SET Presentacion = @Presentacion, Fracciones = @Fracciones, Tipo = @Tipo WHERE Codigo = @Codigo",
            new { Codigo = codigo, r.Presentacion, r.Fracciones, r.Tipo });
        if (filas == 0) throw new KeyNotFoundException($"Presentacion '{codigo}' no encontrada.");
    }

    public async Task EliminarPresentacionAsync(string codigo)
    {
        using var connection = _db.CreateConnection();
        var filas = await connection.ExecuteAsync(
            "DELETE FROM Catalogo.Presentacion WHERE Codigo = @Codigo", new { Codigo = codigo });
        if (filas == 0) throw new KeyNotFoundException($"Presentacion '{codigo}' no encontrada.");
    }

    public async Task<IEnumerable<CentroTrabajoItem>> ListarCentrosTrabajoAsync(bool soloActivos)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT ct.CentroTrabajoID, ct.Nombre, ct.CentroCostoID, cc.Nombre AS CentroCosto,
                   ct.CostoHoraManoObra, ct.CostoHoraCIF, ct.Estado
            FROM Organizacion.CentrosTrabajo ct
            JOIN Organizacion.CentrosCosto cc ON cc.CentroCostoID = ct.CentroCostoID
            WHERE (@SoloActivos = 0 OR ct.Estado = 1)
            ORDER BY cc.Nombre, ct.Nombre";

        return await connection.QueryAsync<CentroTrabajoItem>(sql, new { SoloActivos = soloActivos });
    }

    public async Task<int> CrearCentroTrabajoAsync(CrearCentroTrabajoRequest r)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            INSERT INTO Organizacion.CentrosTrabajo (Nombre, CentroCostoID, CostoHoraManoObra, CostoHoraCIF, Estado)
            OUTPUT INSERTED.CentroTrabajoID
            VALUES (@Nombre, @CentroCostoID, @CostoHoraManoObra, @CostoHoraCIF, 1)";

        return await connection.ExecuteScalarAsync<int>(sql, r);
    }

    public async Task ActualizarCentroTrabajoAsync(int centroTrabajoId, ActualizarCentroTrabajoRequest r)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            UPDATE Organizacion.CentrosTrabajo
            SET Nombre = @Nombre, CostoHoraManoObra = @CostoHoraManoObra, CostoHoraCIF = @CostoHoraCIF, Estado = @Estado
            WHERE CentroTrabajoID = @CentroTrabajoId";

        var filas = await connection.ExecuteAsync(sql, new
        {
            CentroTrabajoId = centroTrabajoId,
            r.Nombre,
            r.CostoHoraManoObra,
            r.CostoHoraCIF,
            r.Estado
        });

        if (filas == 0)
            throw new KeyNotFoundException($"No existe el centro de trabajo {centroTrabajoId}.");
    }

    // Agregar a ICatalogoService / CatalogoService
   

    public async Task<IEnumerable<ProveedorItem>> ListarProveedoresAsync()
    {
        using var connection = _db.CreateConnection();
        return await connection.QueryAsync<ProveedorItem>(
            "SELECT ProveedorID, RazonSocial, NIT, Contacto, Telefono, Email, Direccion, Estado FROM Catalogo.Proveedores ORDER BY RazonSocial");
    }

    public async Task<int> CrearProveedorAsync(CrearProveedorRequest r)
    {
        using var connection = _db.CreateConnection();
        const string sql = @"
            INSERT INTO Catalogo.Proveedores (RazonSocial, NIT, Contacto, Telefono, Email, Direccion)
            OUTPUT INSERTED.ProveedorID
            VALUES (@RazonSocial, @NIT, @Contacto, @Telefono, @Email, @Direccion)";
        return await connection.ExecuteScalarAsync<int>(sql, r);
    }

    public async Task ActualizarProveedorAsync(int proveedorId, ActualizarProveedorRequest r)
    {
        using var connection = _db.CreateConnection();
        const string sql = @"
            UPDATE Catalogo.Proveedores
            SET RazonSocial = @RazonSocial, NIT = @NIT, Contacto = @Contacto, Telefono = @Telefono,
                Email = @Email, Direccion = @Direccion, Estado = @Estado
            WHERE ProveedorID = @ProveedorId";
        var filas = await connection.ExecuteAsync(sql, new { ProveedorId = proveedorId, r.RazonSocial, r.NIT, r.Contacto, r.Telefono, r.Email, r.Direccion, r.Estado });
        if (filas == 0) throw new KeyNotFoundException($"No existe el proveedor {proveedorId}.");
    }

    public async Task<IEnumerable<TipoArticuloItem>> ListarTiposArticuloAsync()
    {
        using var connection = _db.CreateConnection();
        return await connection.QueryAsync<TipoArticuloItem>(
            "SELECT TipoArticuloID, Codigo, Nombre FROM Catalogo.TiposArticulo ORDER BY Nombre");
    }

    public async Task<IEnumerable<UnidadMedidaItem>> ListarUnidadesMedidaAsync()
    {
        using var connection = _db.CreateConnection();
        return await connection.QueryAsync<UnidadMedidaItem>(
            "SELECT UnidadID, Nombre, Abreviatura, Tipo FROM Catalogo.UnidadesMedida ORDER BY Nombre");
    }
}