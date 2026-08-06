using Dapper;
using NexoApi.Common.Data;
using NexoApi.Features.Crm.Dtos;
using NexoApi.Features.Facturacion;
using NexoApi.Features.Facturacion.Dtos;

namespace NexoApi.Features.Crm;

public interface ICrmService
{
    Task<IEnumerable<ClienteItem>> ListarClientesAsync(int? responsableId, string? tipoCliente, string? fuenteContacto, bool? soloActivos);
    Task<int> CrearClienteAsync(CrearClienteRequest request);
    Task ActualizarClienteAsync(int clienteId, ActualizarClienteRequest request);

    Task<IEnumerable<InteraccionItem>> ListarInteraccionesAsync(int clienteId);
    Task<long> CrearInteraccionAsync(CrearInteraccionRequest request, int usuarioId);

    Task<IEnumerable<ContactoItem>> ListarContactosAsync(int clienteId);
    Task<int> CrearContactoAsync(CrearContactoRequest request);
    Task ActualizarContactoAsync(int contactoId, ActualizarContactoRequest request);

    Task<IEnumerable<EventoHistorialItem>> ObtenerHistorialAsync(int clienteId);

    Task<IEnumerable<ClienteDocumentoItem>> ListarDocumentosAsync(int clienteId);
    Task<int> SubirDocumentoAsync(int clienteId, SubirDocumentoRequest request, int usuarioId);
    Task<(byte[] Datos, string ContentType, string NombreArchivo)?> ObtenerDocumentoAsync(int documentoId);
    Task EliminarDocumentoAsync(int documentoId);

    Task<IEnumerable<LeadItem>> ListarLeadsAsync(string? etapa);
    Task<int> CrearLeadAsync(CrearLeadRequest request);
    Task ActualizarLeadAsync(int leadId, ActualizarLeadRequest request);
    Task<int> ConvertirLeadAsync(int leadId);

    Task<IEnumerable<ClienteFrioItem>> ListarClientesFriosAsync(int diasSinContacto);

    // ---------- Oportunidades (embudo de ventas, agosto 2026) ----------
    Task<IEnumerable<OportunidadItem>> ListarOportunidadesAsync(string? etapa, int? responsableId);
    Task<int> CrearOportunidadAsync(CrearOportunidadRequest request);
    Task ActualizarOportunidadAsync(int oportunidadId, ActualizarOportunidadRequest request);

    // ---------- Cotizaciones (agosto 2026) ----------
    Task<IEnumerable<CotizacionItem>> ListarCotizacionesAsync(int? clienteId, string? estado);
    Task<int> CrearCotizacionAsync(CrearCotizacionRequest request, int usuarioId);
    Task<IEnumerable<CotizacionLineaItem>> ListarLineasCotizacionAsync(int cotizacionId);
    Task ActualizarEstadoCotizacionAsync(int cotizacionId, ActualizarEstadoCotizacionRequest request);
    Task<int> ConvertirCotizacionAFacturaAsync(int cotizacionId, int usuarioId);
}

public class CrmService : ICrmService
{
    private readonly IDbConnectionFactory _db;
    private readonly IFacturacionService _facturacion;

    public CrmService(IDbConnectionFactory db, IFacturacionService facturacion)
    {
        _db = db;
        _facturacion = facturacion;
    }

    public async Task<IEnumerable<ClienteItem>> ListarClientesAsync(int? responsableId, string? tipoCliente, string? fuenteContacto, bool? soloActivos)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT c.ClienteID, c.Nombre, c.NIT, c.Contacto, c.Telefono, c.Email, c.Direccion, c.Estado,
                   c.FuenteContacto, c.TipoCliente, c.ResponsableID,
                   e.Nombres + ' ' + e.Apellidos AS Responsable, c.ProximoContacto,
                   (SELECT COUNT(*) FROM Crm.Contactos ct WHERE ct.ClienteID = c.ClienteID AND ct.Estado = 1) AS TotalContactos,
                   (SELECT MAX(i.Fecha) FROM Crm.Interacciones i WHERE i.ClienteID = c.ClienteID) AS UltimaInteraccion
            FROM Crm.Clientes c
            LEFT JOIN Rrhh.Empleados e ON e.EmpleadoID = c.ResponsableID
            WHERE (@ResponsableId IS NULL OR c.ResponsableID = @ResponsableId)
              AND (@TipoCliente IS NULL OR c.TipoCliente = @TipoCliente)
              AND (@FuenteContacto IS NULL OR c.FuenteContacto = @FuenteContacto)
              AND (@SoloActivos IS NULL OR c.Estado = @SoloActivos)
            ORDER BY c.Nombre";

        return await connection.QueryAsync<ClienteItem>(sql, new
        {
            ResponsableId = responsableId,
            TipoCliente = tipoCliente,
            FuenteContacto = fuenteContacto,
            SoloActivos = soloActivos
        });
    }

    public async Task<int> CrearClienteAsync(CrearClienteRequest r)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            INSERT INTO Crm.Clientes (Nombre, NIT, Telefono, Email, Direccion, FuenteContacto, TipoCliente, ResponsableID)
            OUTPUT INSERTED.ClienteID
            VALUES (@Nombre, @NIT, @Telefono, @Email, @Direccion, @FuenteContacto, @TipoCliente, @ResponsableID)";

        return await connection.ExecuteScalarAsync<int>(sql, r);
    }

    public async Task ActualizarClienteAsync(int clienteId, ActualizarClienteRequest r)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            UPDATE Crm.Clientes
            SET Nombre = @Nombre, NIT = @NIT, Telefono = @Telefono,
                Email = @Email, Direccion = @Direccion, Estado = @Estado,
                FuenteContacto = @FuenteContacto, TipoCliente = @TipoCliente,
                ResponsableID = @ResponsableID, ProximoContacto = @ProximoContacto
            WHERE ClienteID = @ClienteId";

        var filas = await connection.ExecuteAsync(sql, new
        {
            ClienteId = clienteId,
            r.Nombre, r.NIT, r.Telefono, r.Email, r.Direccion, r.Estado,
            r.FuenteContacto, r.TipoCliente, r.ResponsableID, r.ProximoContacto
        });

        if (filas == 0)
            throw new KeyNotFoundException($"No existe el cliente {clienteId}.");
    }

    public async Task<IEnumerable<InteraccionItem>> ListarInteraccionesAsync(int clienteId)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT i.InteraccionID, i.ClienteID, i.Tipo, i.Notas, i.Fecha,
                   u.Nombres + ' ' + u.Apellidos AS Usuario
            FROM Crm.Interacciones i
            LEFT JOIN Seguridad.Usuarios u ON u.UsuarioID = i.UsuarioID
            WHERE i.ClienteID = @ClienteId
            ORDER BY i.Fecha DESC";

        return await connection.QueryAsync<InteraccionItem>(sql, new { ClienteId = clienteId });
    }

    public async Task<long> CrearInteraccionAsync(CrearInteraccionRequest r, int usuarioId)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            INSERT INTO Crm.Interacciones (ClienteID, Tipo, Notas, UsuarioID)
            OUTPUT INSERTED.InteraccionID
            VALUES (@ClienteID, @Tipo, @Notas, @UsuarioID)";

        var id = await connection.ExecuteScalarAsync<long>(sql, new { r.ClienteID, r.Tipo, r.Notas, UsuarioID = usuarioId });

        // Registrar una interaccion es tambien el momento natural de agendar
        // cuando volver a contactar -- si el usuario lo indico, se actualiza aqui.
        if (r.ProximoContacto is not null)
        {
            await connection.ExecuteAsync(
                "UPDATE Crm.Clientes SET ProximoContacto = @ProximoContacto WHERE ClienteID = @ClienteID",
                new { r.ProximoContacto, r.ClienteID });
        }

        return id;
    }

    public async Task<IEnumerable<ContactoItem>> ListarContactosAsync(int clienteId)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT ContactoID, ClienteID, Nombres, Cargo, Telefono, Email, EsPrincipal, Estado
            FROM Crm.Contactos
            WHERE ClienteID = @ClienteId
            ORDER BY EsPrincipal DESC, Nombres";

        return await connection.QueryAsync<ContactoItem>(sql, new { ClienteId = clienteId });
    }

    public async Task<int> CrearContactoAsync(CrearContactoRequest r)
    {
        using var connection = _db.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();

        try
        {
            // Solo puede haber un contacto principal por cliente -- si este
            // nuevo se marca como principal, se le quita la marca al resto.
            if (r.EsPrincipal)
            {
                await connection.ExecuteAsync(
                    "UPDATE Crm.Contactos SET EsPrincipal = 0 WHERE ClienteID = @ClienteID",
                    new { r.ClienteID }, transaction);
            }

            const string sql = @"
                INSERT INTO Crm.Contactos (ClienteID, Nombres, Cargo, Telefono, Email, EsPrincipal)
                OUTPUT INSERTED.ContactoID
                VALUES (@ClienteID, @Nombres, @Cargo, @Telefono, @Email, @EsPrincipal)";

            var id = await connection.ExecuteScalarAsync<int>(sql, r, transaction);
            transaction.Commit();
            return id;
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public async Task ActualizarContactoAsync(int contactoId, ActualizarContactoRequest r)
    {
        using var connection = _db.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();

        try
        {
            var clienteId = await connection.ExecuteScalarAsync<int?>(
                "SELECT ClienteID FROM Crm.Contactos WHERE ContactoID = @ContactoId", new { ContactoId = contactoId }, transaction);

            if (clienteId is null)
                throw new KeyNotFoundException($"No existe el contacto {contactoId}.");

            if (r.EsPrincipal)
            {
                await connection.ExecuteAsync(
                    "UPDATE Crm.Contactos SET EsPrincipal = 0 WHERE ClienteID = @ClienteID AND ContactoID <> @ContactoId",
                    new { ClienteID = clienteId, ContactoId = contactoId }, transaction);
            }

            const string sql = @"
                UPDATE Crm.Contactos
                SET Nombres = @Nombres, Cargo = @Cargo, Telefono = @Telefono, Email = @Email,
                    EsPrincipal = @EsPrincipal, Estado = @Estado
                WHERE ContactoID = @ContactoId";

            await connection.ExecuteAsync(sql, new
            {
                ContactoId = contactoId, r.Nombres, r.Cargo, r.Telefono, r.Email, r.EsPrincipal, r.Estado
            }, transaction);

            transaction.Commit();
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    // C) Historial unificado: interacciones + pedidos (Ordenes de Produccion
    // MTO) + despachos, todo en una sola linea de tiempo.
    public async Task<IEnumerable<EventoHistorialItem>> ObtenerHistorialAsync(int clienteId)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT 'INTERACCION' AS TipoEvento, i.Fecha, i.Tipo AS Titulo, i.Notas AS Detalle
            FROM Crm.Interacciones i
            WHERE i.ClienteID = @ClienteId

            UNION ALL

            SELECT 'PEDIDO' AS TipoEvento, op.FechaCreacion AS Fecha,
                   'Orden de Produccion #' + CAST(op.OrdenProduccionID AS VARCHAR) AS Titulo,
                   a.Nombre + ' - ' + CAST(op.CantidadProgramada AS VARCHAR) + ' ' + ISNULL(u.Abreviatura, '') AS Detalle
            FROM Produccion.OrdenesProduccion op
            JOIN Catalogo.Articulos a ON a.ArticuloID = op.ProductoTerminadoID
            LEFT JOIN Catalogo.UnidadesMedida u ON u.UnidadID = a.UnidadID
            WHERE op.ClienteID = @ClienteId

            UNION ALL

            SELECT 'DESPACHO' AS TipoEvento, d.FechaDespacho AS Fecha,
                   'GUIA-' + RIGHT('000000' + CAST(d.DespachoID AS VARCHAR(6)), 6) AS Titulo,
                   d.Estado + ISNULL(' - ' + d.Observaciones, '') AS Detalle
            FROM Logistica.Despachos d
            WHERE d.ClienteID = @ClienteId

            ORDER BY Fecha DESC";

        return await connection.QueryAsync<EventoHistorialItem>(sql, new { ClienteId = clienteId });
    }

    public async Task<IEnumerable<ClienteDocumentoItem>> ListarDocumentosAsync(int clienteId)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT DocumentoID, ClienteID, TipoDocumento, NombreArchivo, ContentType, FechaSubida
            FROM Crm.ClienteDocumentos
            WHERE ClienteID = @ClienteId
            ORDER BY FechaSubida DESC";

        return await connection.QueryAsync<ClienteDocumentoItem>(sql, new { ClienteId = clienteId });
    }

    public async Task<int> SubirDocumentoAsync(int clienteId, SubirDocumentoRequest r, int usuarioId)
    {
        using var connection = _db.CreateConnection();
        var datos = Convert.FromBase64String(r.Base64);

        const string sql = @"
            INSERT INTO Crm.ClienteDocumentos (ClienteID, TipoDocumento, NombreArchivo, ContentType, Archivo, UsuarioID)
            OUTPUT INSERTED.DocumentoID
            VALUES (@ClienteID, @TipoDocumento, @NombreArchivo, @ContentType, @Archivo, @UsuarioID)";

        return await connection.ExecuteScalarAsync<int>(sql, new
        {
            ClienteID = clienteId, r.TipoDocumento, r.NombreArchivo, r.ContentType, Archivo = datos, UsuarioID = usuarioId
        });
    }

    private record DocumentoArchivo(byte[] Archivo, string ContentType, string NombreArchivo);

    public async Task<(byte[] Datos, string ContentType, string NombreArchivo)?> ObtenerDocumentoAsync(int documentoId)
    {
        using var connection = _db.CreateConnection();

        var resultado = await connection.QuerySingleOrDefaultAsync<DocumentoArchivo>(
            "SELECT Archivo, ContentType, NombreArchivo FROM Crm.ClienteDocumentos WHERE DocumentoID = @DocumentoId",
            new { DocumentoId = documentoId });

        return resultado is null ? null : (resultado.Archivo, resultado.ContentType, resultado.NombreArchivo);
    }

    public async Task EliminarDocumentoAsync(int documentoId)
    {
        using var connection = _db.CreateConnection();

        var filas = await connection.ExecuteAsync(
            "DELETE FROM Crm.ClienteDocumentos WHERE DocumentoID = @DocumentoId", new { DocumentoId = documentoId });

        if (filas == 0)
            throw new KeyNotFoundException($"No existe el documento {documentoId}.");
    }

    public async Task<IEnumerable<LeadItem>> ListarLeadsAsync(string? etapa)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT l.LeadID, l.Nombre, l.Empresa, l.Telefono, l.Email, l.FuenteContacto, l.Etapa, l.Notas,
                   l.ResponsableID, e.Nombres + ' ' + e.Apellidos AS Responsable,
                   l.ClienteIDConvertido, l.FechaCreacion, l.FechaConversion
            FROM Crm.Leads l
            LEFT JOIN Rrhh.Empleados e ON e.EmpleadoID = l.ResponsableID
            WHERE (@Etapa IS NULL OR l.Etapa = @Etapa)
            ORDER BY l.FechaCreacion DESC";

        return await connection.QueryAsync<LeadItem>(sql, new { Etapa = etapa });
    }

    public async Task<int> CrearLeadAsync(CrearLeadRequest r)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            INSERT INTO Crm.Leads (Nombre, Empresa, Telefono, Email, FuenteContacto, Notas, ResponsableID)
            OUTPUT INSERTED.LeadID
            VALUES (@Nombre, @Empresa, @Telefono, @Email, @FuenteContacto, @Notas, @ResponsableID)";

        return await connection.ExecuteScalarAsync<int>(sql, r);
    }

    public async Task ActualizarLeadAsync(int leadId, ActualizarLeadRequest r)
    {
        using var connection = _db.CreateConnection();

        var etapaActual = await connection.ExecuteScalarAsync<string?>(
            "SELECT Etapa FROM Crm.Leads WHERE LeadID = @LeadId", new { LeadId = leadId });

        if (etapaActual is null)
            throw new KeyNotFoundException($"No existe el lead {leadId}.");

        if (etapaActual == "CONVERTIDO")
            throw new InvalidOperationException("Este lead ya fue convertido a cliente, no se puede editar -- edita el cliente directamente.");

        const string sql = @"
            UPDATE Crm.Leads
            SET Nombre = @Nombre, Empresa = @Empresa, Telefono = @Telefono, Email = @Email,
                FuenteContacto = @FuenteContacto, Etapa = @Etapa, Notas = @Notas, ResponsableID = @ResponsableID
            WHERE LeadID = @LeadId";

        await connection.ExecuteAsync(sql, new
        {
            LeadId = leadId, r.Nombre, r.Empresa, r.Telefono, r.Email, r.FuenteContacto, r.Etapa, r.Notas, r.ResponsableID
        });
    }

    // Convertir un lead crea el Cliente con los mismos datos y marca el lead
    // como CONVERTIDO -- de ahi en adelante el lead queda solo como registro
    // historico de por donde entro este cliente, ya no se vuelve a tocar.
    public async Task<int> ConvertirLeadAsync(int leadId)
    {
        using var connection = _db.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();

        try
        {
            var lead = await connection.QuerySingleOrDefaultAsync<LeadParaConvertir>(
                "SELECT Nombre, Empresa, Telefono, Email, FuenteContacto, ResponsableID, Etapa FROM Crm.Leads WHERE LeadID = @LeadId",
                new { LeadId = leadId }, transaction);

            if (lead is null)
                throw new KeyNotFoundException($"No existe el lead {leadId}.");

            if (lead.Etapa == "CONVERTIDO")
                throw new InvalidOperationException("Este lead ya fue convertido a cliente antes.");

            const string sqlCrearCliente = @"
                INSERT INTO Crm.Clientes (Nombre, Telefono, Email, FuenteContacto, ResponsableID)
                OUTPUT INSERTED.ClienteID
                VALUES (@Nombre, @Telefono, @Email, @FuenteContacto, @ResponsableID)";

            var clienteId = await connection.ExecuteScalarAsync<int>(sqlCrearCliente, new
            {
                Nombre = lead.Empresa ?? lead.Nombre, lead.Telefono, lead.Email, lead.FuenteContacto, lead.ResponsableID
            }, transaction);

            await connection.ExecuteAsync(
                @"UPDATE Crm.Leads SET Etapa = 'CONVERTIDO', ClienteIDConvertido = @ClienteId, FechaConversion = SYSUTCDATETIME()
                  WHERE LeadID = @LeadId",
                new { ClienteId = clienteId, LeadId = leadId }, transaction);

            transaction.Commit();
            return clienteId;
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    private record LeadParaConvertir(string Nombre, string? Empresa, string? Telefono, string? Email, string? FuenteContacto, int? ResponsableID, string Etapa);

    // D) Clientes activos sin interaccion reciente (o con proximo contacto
    // vencido) -- no envia nada, solo los detecta para que alguien actue.
    public async Task<IEnumerable<ClienteFrioItem>> ListarClientesFriosAsync(int diasSinContacto)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT c.ClienteID, c.Nombre, e.Nombres + ' ' + e.Apellidos AS Responsable,
                   (SELECT MAX(i.Fecha) FROM Crm.Interacciones i WHERE i.ClienteID = c.ClienteID) AS UltimaInteraccion,
                   c.ProximoContacto
            FROM Crm.Clientes c
            LEFT JOIN Rrhh.Empleados e ON e.EmpleadoID = c.ResponsableID
            WHERE c.Estado = 1
              AND (
                  (SELECT MAX(i.Fecha) FROM Crm.Interacciones i WHERE i.ClienteID = c.ClienteID) IS NULL
                  OR (SELECT MAX(i.Fecha) FROM Crm.Interacciones i WHERE i.ClienteID = c.ClienteID) < DATEADD(DAY, -@DiasSinContacto, SYSUTCDATETIME())
                  OR (c.ProximoContacto IS NOT NULL AND c.ProximoContacto < CAST(GETDATE() AS DATE))
              )
            ORDER BY c.Nombre";

        return await connection.QueryAsync<ClienteFrioItem>(sql, new { DiasSinContacto = diasSinContacto });
    }

    // ---------- Oportunidades (embudo de ventas) ----------

    public async Task<IEnumerable<OportunidadItem>> ListarOportunidadesAsync(string? etapa, int? responsableId)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT o.OportunidadID, o.LeadID, l.Nombre AS Lead, o.ClienteID, c.Nombre AS Cliente,
                   o.Nombre, o.ValorEstimado, o.Probabilidad, o.Etapa, o.FechaCierreEsperada,
                   o.ResponsableID, e.Nombres + ' ' + e.Apellidos AS Responsable, o.Notas, o.FechaCreacion, o.FechaCierre
            FROM Crm.Oportunidades o
            LEFT JOIN Crm.Leads l ON l.LeadID = o.LeadID
            LEFT JOIN Crm.Clientes c ON c.ClienteID = o.ClienteID
            LEFT JOIN Rrhh.Empleados e ON e.EmpleadoID = o.ResponsableID
            WHERE (@Etapa IS NULL OR o.Etapa = @Etapa)
              AND (@ResponsableId IS NULL OR o.ResponsableID = @ResponsableId)
            ORDER BY o.FechaCreacion DESC";

        return await connection.QueryAsync<OportunidadItem>(sql, new { Etapa = etapa, ResponsableId = responsableId });
    }

    public async Task<int> CrearOportunidadAsync(CrearOportunidadRequest r)
    {
        if (r.LeadID is null && r.ClienteID is null)
            throw new InvalidOperationException("La oportunidad debe originarse de un Lead o de un Cliente.");

        using var connection = _db.CreateConnection();

        const string sql = @"
            INSERT INTO Crm.Oportunidades (LeadID, ClienteID, Nombre, ValorEstimado, Probabilidad, FechaCierreEsperada, ResponsableID, Notas)
            OUTPUT INSERTED.OportunidadID
            VALUES (@LeadID, @ClienteID, @Nombre, @ValorEstimado, @Probabilidad, @FechaCierreEsperada, @ResponsableID, @Notas)";

        return await connection.ExecuteScalarAsync<int>(sql, r);
    }

    // Al pasar a GANADA o PERDIDA se registra la fecha de cierre (solo la
    // primera vez -- no se pisa si ya tenia valor, mismo patron que
    // FechaCompletado en Hitos de Proyectos).
    public async Task ActualizarOportunidadAsync(int oportunidadId, ActualizarOportunidadRequest r)
    {
        using var connection = _db.CreateConnection();

        var cerrada = r.Etapa is "GANADA" or "PERDIDA";

        const string sql = @"
            UPDATE Crm.Oportunidades
            SET Nombre = @Nombre, ValorEstimado = @ValorEstimado, Probabilidad = @Probabilidad, Etapa = @Etapa,
                FechaCierreEsperada = @FechaCierreEsperada, ResponsableID = @ResponsableID, Notas = @Notas,
                FechaCierre = CASE WHEN @Cerrada = 1 THEN ISNULL(FechaCierre, SYSDATETIME()) ELSE NULL END
            WHERE OportunidadID = @OportunidadId";

        var filas = await connection.ExecuteAsync(sql, new
        {
            OportunidadId = oportunidadId, r.Nombre, r.ValorEstimado, r.Probabilidad, r.Etapa,
            r.FechaCierreEsperada, r.ResponsableID, r.Notas, Cerrada = cerrada
        });

        if (filas == 0)
            throw new KeyNotFoundException($"No existe la oportunidad {oportunidadId}.");
    }

    // ---------- Cotizaciones ----------

    public async Task<IEnumerable<CotizacionItem>> ListarCotizacionesAsync(int? clienteId, string? estado)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT c.CotizacionID, c.ClienteID, cl.Nombre AS Cliente, c.OportunidadID, c.Fecha, c.ValidoHasta,
                   c.Estado, c.Notas, c.FacturaID,
                   ISNULL((SELECT SUM(l.Cantidad * l.PrecioUnitario) FROM Crm.CotizacionLineas l WHERE l.CotizacionID = c.CotizacionID), 0) AS Total
            FROM Crm.Cotizaciones c
            JOIN Crm.Clientes cl ON cl.ClienteID = c.ClienteID
            WHERE (@ClienteId IS NULL OR c.ClienteID = @ClienteId)
              AND (@Estado IS NULL OR c.Estado = @Estado)
            ORDER BY c.Fecha DESC, c.CotizacionID DESC";

        return await connection.QueryAsync<CotizacionItem>(sql, new { ClienteId = clienteId, Estado = estado });
    }

    public async Task<int> CrearCotizacionAsync(CrearCotizacionRequest r, int usuarioId)
    {
        if (r.Lineas.Count == 0)
            throw new InvalidOperationException("La cotización debe tener al menos un artículo.");

        if (r.Lineas.Any(l => l.Cantidad <= 0))
            throw new InvalidOperationException("Todas las cantidades deben ser mayores a cero.");

        using var connection = _db.CreateConnection();
        connection.Open();
        using var transaction = connection.BeginTransaction();

        try
        {
            const string sqlCotizacion = @"
                INSERT INTO Crm.Cotizaciones (ClienteID, OportunidadID, Fecha, ValidoHasta, Notas, UsuarioID)
                OUTPUT INSERTED.CotizacionID
                VALUES (@ClienteID, @OportunidadID, @Fecha, @ValidoHasta, @Notas, @UsuarioID)";

            var cotizacionId = await connection.ExecuteScalarAsync<int>(sqlCotizacion,
                new { r.ClienteID, r.OportunidadID, r.Fecha, r.ValidoHasta, r.Notas, UsuarioID = usuarioId }, transaction);

            const string sqlLinea = @"
                INSERT INTO Crm.CotizacionLineas (CotizacionID, ArticuloID, Cantidad, PrecioUnitario)
                VALUES (@CotizacionId, @ArticuloID, @Cantidad, @PrecioUnitario)";

            foreach (var linea in r.Lineas)
            {
                await connection.ExecuteAsync(sqlLinea,
                    new { CotizacionId = cotizacionId, linea.ArticuloID, linea.Cantidad, linea.PrecioUnitario }, transaction);
            }

            transaction.Commit();
            return cotizacionId;
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    public async Task<IEnumerable<CotizacionLineaItem>> ListarLineasCotizacionAsync(int cotizacionId)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT l.LineaID, l.CotizacionID, l.ArticuloID, a.SKU AS SkuArticulo, a.Nombre AS NombreArticulo,
                   l.Cantidad, l.PrecioUnitario, (l.Cantidad * l.PrecioUnitario) AS Subtotal
            FROM Crm.CotizacionLineas l
            JOIN Catalogo.Articulos a ON a.ArticuloID = l.ArticuloID
            WHERE l.CotizacionID = @CotizacionId
            ORDER BY l.LineaID";

        return await connection.QueryAsync<CotizacionLineaItem>(sql, new { CotizacionId = cotizacionId });
    }

    public async Task ActualizarEstadoCotizacionAsync(int cotizacionId, ActualizarEstadoCotizacionRequest r)
    {
        using var connection = _db.CreateConnection();

        var filas = await connection.ExecuteAsync(
            "UPDATE Crm.Cotizaciones SET Estado = @Estado WHERE CotizacionID = @CotizacionId",
            new { CotizacionId = cotizacionId, r.Estado });

        if (filas == 0)
            throw new KeyNotFoundException($"No existe la cotización {cotizacionId}.");
    }

    private record CotizacionParaConvertir(int ClienteID, string Estado, int? FacturaID);

    // Integracion CRM -> Facturacion (recomendada en la auditoria de agosto
    // 2026, seccion 4.1): una Cotizacion Aceptada genera la Factura sin
    // volver a teclear cliente ni lineas. Mismo espiritu que ConvertirLeadAsync.
    public async Task<int> ConvertirCotizacionAFacturaAsync(int cotizacionId, int usuarioId)
    {
        using var connection = _db.CreateConnection();

        var cotizacion = await connection.QuerySingleOrDefaultAsync<CotizacionParaConvertir>(
            "SELECT ClienteID, Estado, FacturaID FROM Crm.Cotizaciones WHERE CotizacionID = @CotizacionId",
            new { CotizacionId = cotizacionId });

        if (cotizacion is null)
            throw new KeyNotFoundException($"No existe la cotización {cotizacionId}.");

        if (cotizacion.FacturaID is not null)
            throw new InvalidOperationException("Esta cotización ya fue convertida a factura antes.");

        var lineas = (await ListarLineasCotizacionAsync(cotizacionId)).ToList();
        if (lineas.Count == 0)
            throw new InvalidOperationException("La cotización no tiene artículos para facturar.");

        var lineasFactura = lineas.Select(l => new LineaFacturaInput(l.ArticuloID, l.Cantidad, l.PrecioUnitario)).ToList();
        var facturaRequest = new CrearFacturaRequest(cotizacion.ClienteID, DateTime.Today,
            $"Generada desde Cotización #{cotizacionId}", lineasFactura);

        var facturaId = await _facturacion.CrearFacturaAsync(facturaRequest, usuarioId);

        await connection.ExecuteAsync(
            "UPDATE Crm.Cotizaciones SET Estado = 'ACEPTADA', FacturaID = @FacturaId WHERE CotizacionID = @CotizacionId",
            new { FacturaId = facturaId, CotizacionId = cotizacionId });

        return facturaId;
    }
}
