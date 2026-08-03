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

    // Articulos
    Task<int> CrearArticuloAsync(CrearArticuloRequest request);
    Task<IEnumerable<ArticuloItem>> ListarArticulosAsync(int? tipoArticuloId, string? texto);
    Task ActualizarArticuloAsync(int articuloId, ActualizarArticuloRequest request);

    Task<IEnumerable<ClienteItem>> ListarClientesAsync();
    Task<int> CrearClienteAsync(CrearClienteRequest request);
    Task ActualizarClienteAsync(int clienteId, ActualizarClienteRequest request);
    Task<IEnumerable<CentroTrabajoItem>> ListarCentrosTrabajoAsync(bool soloActivos);
    Task<int> CrearCentroTrabajoAsync(CrearCentroTrabajoRequest request);
    Task ActualizarCentroTrabajoAsync(int centroTrabajoId, ActualizarCentroTrabajoRequest request);

    Task<IEnumerable<ProveedorItem>> ListarProveedoresAsync();
    Task<int> CrearProveedorAsync(CrearProveedorRequest request);
    Task ActualizarProveedorAsync(int proveedorId, ActualizarProveedorRequest request);

    // Interfaz ICatalogoService, agregado:
    Task<IEnumerable<TipoArticuloItem>> ListarTiposArticuloAsync();
    Task<IEnumerable<UnidadMedidaItem>> ListarUnidadesMedidaAsync();

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
            SELECT CentroCostoID, Codigo, Nombre, TipoCentro, Direccion, Estado, TieneVisions
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
            SET Nombre = @Nombre, Direccion = @Direccion, Telefono = @Telefono, Estado = @Estado
            WHERE CentroCostoID = @CentroCostoId";

        var filas = await connection.ExecuteAsync(sql, new
        {
            CentroCostoId = centroCostoId,
            r.Nombre,
            r.Direccion,
            r.Telefono,
            r.Estado
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

    // ================= Articulos =================

    public async Task<int> CrearArticuloAsync(CrearArticuloRequest r)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            INSERT INTO Catalogo.Articulos
                (SKU, Nombre, Descripcion, TipoArticuloID, UnidadID, PrecioVenta, StockMinimo, PuntoReorden, DiasVidaUtil, UnidadesPorEmbalaje)
            OUTPUT INSERTED.ArticuloID
            VALUES
                (@SKU, @Nombre, @Descripcion, @TipoArticuloID, @UnidadID, @PrecioVenta, @StockMinimo, @PuntoReorden, @DiasVidaUtil, @UnidadesPorEmbalaje)";

        return await connection.ExecuteScalarAsync<int>(sql, r);
    }

    public async Task<IEnumerable<ArticuloItem>> ListarArticulosAsync(int? tipoArticuloId, string? texto)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT a.ArticuloID, a.SKU, a.Nombre, a.Descripcion, ta.Nombre AS TipoArticulo, u.Abreviatura AS Unidad,
                   a.CostoPromedio, a.PrecioVenta, a.StockMinimo, a.PuntoReorden, a.Estado, a.DiasVidaUtil,
                   a.UnidadesPorEmbalaje
            FROM Catalogo.Articulos a
            JOIN Catalogo.TiposArticulo ta ON ta.TipoArticuloID = a.TipoArticuloID
            LEFT JOIN Catalogo.UnidadesMedida u ON u.UnidadID = a.UnidadID
            WHERE (@TipoArticuloId IS NULL OR a.TipoArticuloID = @TipoArticuloId)
              AND (@Texto IS NULL OR a.Nombre LIKE '%' + @Texto + '%' OR a.SKU LIKE '%' + @Texto + '%')
            ORDER BY a.Nombre";

        return await connection.QueryAsync<ArticuloItem>(sql, new { TipoArticuloId = tipoArticuloId, Texto = texto });
    }

    public async Task ActualizarArticuloAsync(int articuloId, ActualizarArticuloRequest r)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            UPDATE Catalogo.Articulos
            SET Nombre = @Nombre, Descripcion = @Descripcion, PrecioVenta = @PrecioVenta,
                StockMinimo = @StockMinimo, PuntoReorden = @PuntoReorden, DiasVidaUtil = @DiasVidaUtil, Estado = @Estado,
                UnidadesPorEmbalaje = @UnidadesPorEmbalaje
            WHERE ArticuloID = @ArticuloId";

        var filas = await connection.ExecuteAsync(sql, new
        {
            ArticuloId = articuloId,
            r.Nombre,
            r.Descripcion,
            r.PrecioVenta,
            r.StockMinimo,
            r.PuntoReorden,
            r.DiasVidaUtil,
            r.Estado,
            r.UnidadesPorEmbalaje
        });

        if (filas == 0)
            throw new KeyNotFoundException($"No existe el articulo {articuloId}.");
    }

    

    public async Task<IEnumerable<ClienteItem>> ListarClientesAsync()
    {
        using var connection = _db.CreateConnection();
        return await connection.QueryAsync<ClienteItem>(
            "SELECT ClienteID, Nombre, NIT, Contacto, Telefono, Email, Direccion, Estado FROM Catalogo.Clientes ORDER BY Nombre");
    }

    public async Task<int> CrearClienteAsync(CrearClienteRequest r)
    {
        using var connection = _db.CreateConnection();
        const string sql = @"
            INSERT INTO Catalogo.Clientes (Nombre, NIT, Contacto, Telefono, Email, Direccion)
            OUTPUT INSERTED.ClienteID
            VALUES (@Nombre, @NIT, @Contacto, @Telefono, @Email, @Direccion)";
        return await connection.ExecuteScalarAsync<int>(sql, r);
    }

    public async Task ActualizarClienteAsync(int clienteId, ActualizarClienteRequest r)
    {
        using var connection = _db.CreateConnection();
        const string sql = @"
            UPDATE Catalogo.Clientes
            SET Nombre = @Nombre, NIT = @NIT, Contacto = @Contacto, Telefono = @Telefono,
                Email = @Email, Direccion = @Direccion, Estado = @Estado
            WHERE ClienteID = @ClienteId";
        var filas = await connection.ExecuteAsync(sql, new { ClienteId = clienteId, r.Nombre, r.NIT, r.Contacto, r.Telefono, r.Email, r.Direccion, r.Estado });
        if (filas == 0) throw new KeyNotFoundException($"No existe el cliente {clienteId}.");
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