using Dapper;
using NexoApi.Common.Data;
using NexoApi.Features.Crm.Dtos;
using NexoApi.Features.Email;
using NexoApi.Features.Facturacion;
using NexoApi.Features.Facturacion.Dtos;

namespace NexoApi.Features.Crm;

public interface ICrmService
{
    Task<IEnumerable<ClienteItem>> ListarClientesAsync(int? responsableId, string? tipoCliente, string? fuenteContacto, bool? soloActivos);
    Task<ClientesPaginadosResponse> ListarClientesPaginadosAsync(string? texto, int? responsableId, string? tipoCliente, string? fuenteContacto, int pagina, int tamano);
    Task<ClienteItem?> ObtenerClienteAsync(string externalId);
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
    Task CambiarEtapaLeadAsync(int leadId, string etapa);

    // ---------- Oportunidades (embudo de ventas, agosto 2026) ----------
    Task<IEnumerable<OportunidadItem>> ListarOportunidadesAsync(string? etapa, int? responsableId);
    Task<int> CrearOportunidadAsync(CrearOportunidadRequest request);
    Task ActualizarOportunidadAsync(int oportunidadId, ActualizarOportunidadRequest request);

    // ---------- Actividades CRM (agosto 2026) ----------
    Task<IEnumerable<ActividadItem>> ListarActividadesAsync(bool soloActivas, int? oportunidadId, int? clienteId);
    Task<int> CrearActividadAsync(CrearActividadRequest request);
    Task CompletarActividadAsync(int actividadId, bool completada);
    Task EliminarActividadAsync(int actividadId);

    // ---------- Cotizaciones (agosto 2026) ----------
    Task<IEnumerable<CotizacionItem>> ListarCotizacionesAsync(int? clienteId, string? estado);
    Task<int> CrearCotizacionAsync(CrearCotizacionRequest request, int usuarioId);
    Task<IEnumerable<CotizacionLineaItem>> ListarLineasCotizacionAsync(int cotizacionId);
    Task ActualizarEstadoCotizacionAsync(int cotizacionId, ActualizarEstadoCotizacionRequest request);
    Task<int> ConvertirCotizacionAFacturaAsync(int cotizacionId, int usuarioId);
    Task<bool> EnviarEmailCotizacionAsync(int cotizacionId);

    // Catálogo de referencia geográfica/tributaria
    Task<IEnumerable<PaisItem>> ListarPaisesAsync();
    Task<IEnumerable<MunicipioItem>> ListarMunicipiosAsync();
    Task<IEnumerable<TipoIdentificacionItem>> ListarTiposIdentificacionAsync();
}

public class CrmService : ICrmService
{
    private readonly IDbConnectionFactory _db;
    private readonly IFacturacionService _facturacion;
    private readonly IAutomacionService _automacion;
    private readonly IEmailService _email;

    public CrmService(IDbConnectionFactory db, IFacturacionService facturacion, IAutomacionService automacion, IEmailService email)
    {
        _db = db;
        _facturacion = facturacion;
        _automacion = automacion;
        _email = email;
    }

    public async Task<IEnumerable<ClienteItem>> ListarClientesAsync(int? responsableId, string? tipoCliente, string? fuenteContacto, bool? soloActivos)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT c.ClienteID, c.ExternalId, c.Nombre, c.NIT, c.Contacto, c.Telefono, c.Email, c.Direccion, c.Estado,
                   c.FuenteContacto, c.TipoCliente, c.ResponsableID,
                   e.Nombres + ' ' + e.Apellidos AS Responsable, c.ProximoContacto,
                   (SELECT COUNT(*) FROM Crm.Contactos ct WHERE ct.ClienteID = c.ClienteID AND ct.Estado = 1) AS TotalContactos,
                   (SELECT MAX(i.Fecha) FROM Crm.Interacciones i WHERE i.ClienteID = c.ClienteID) AS UltimaInteraccion,
                   c.TipoPersona, c.PrimerNombre, c.SegundoNombre, c.PrimerApellido, c.SegundoApellido,
                   c.Departamento, c.Ciudad, c.TipoIdentificacion, c.CodigoDept, c.CodigoMuni, c.DigitoVerificacion
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

    public async Task<ClientesPaginadosResponse> ListarClientesPaginadosAsync(
        string? texto, int? responsableId, string? tipoCliente, string? fuenteContacto, int pagina, int tamano)
    {
        using var connection = _db.CreateConnection();

        var offset = (pagina - 1) * tamano;

        const string sqlBase = @"
            FROM Crm.Clientes c
            LEFT JOIN Rrhh.Empleados e ON e.EmpleadoID = c.ResponsableID
            WHERE c.Estado = 1
              AND (@Texto IS NULL OR c.Nombre LIKE '%' + @Texto + '%' OR c.NIT LIKE '%' + @Texto + '%')
              AND (@ResponsableId IS NULL OR c.ResponsableID = @ResponsableId)
              AND (@TipoCliente IS NULL OR c.TipoCliente = @TipoCliente)
              AND (@FuenteContacto IS NULL OR c.FuenteContacto = @FuenteContacto)";

        var total = await connection.ExecuteScalarAsync<int>(
            "SELECT COUNT(*) " + sqlBase,
            new { Texto = string.IsNullOrWhiteSpace(texto) ? null : texto, ResponsableId = responsableId, TipoCliente = tipoCliente, FuenteContacto = fuenteContacto });

        var items = await connection.QueryAsync<ClienteItem>(@"
            SELECT c.ClienteID, c.ExternalId, c.Nombre, c.NIT, c.Contacto, c.Telefono, c.Email, c.Direccion, c.Estado,
                   c.FuenteContacto, c.TipoCliente, c.ResponsableID,
                   e.Nombres + ' ' + e.Apellidos AS Responsable, c.ProximoContacto,
                   (SELECT COUNT(*) FROM Crm.Contactos ct WHERE ct.ClienteID = c.ClienteID AND ct.Estado = 1) AS TotalContactos,
                   (SELECT MAX(i.Fecha) FROM Crm.Interacciones i WHERE i.ClienteID = c.ClienteID) AS UltimaInteraccion,
                   c.TipoPersona, c.PrimerNombre, c.SegundoNombre, c.PrimerApellido, c.SegundoApellido,
                   c.Departamento, c.Ciudad, c.TipoIdentificacion, c.CodigoDept, c.CodigoMuni, c.DigitoVerificacion " + sqlBase + @"
            ORDER BY c.Nombre
            OFFSET @Offset ROWS FETCH NEXT @Tamano ROWS ONLY",
            new { Texto = string.IsNullOrWhiteSpace(texto) ? null : texto, ResponsableId = responsableId, TipoCliente = tipoCliente, FuenteContacto = fuenteContacto, Offset = offset, Tamano = tamano });

        return new ClientesPaginadosResponse(items.ToList(), total);
    }

    // Usado por el workspace (/crm/clientes/{externalId}) -- busca por ExternalId
    // (string opaco, no expone el int primario) y devuelve el ClienteID interno
    // para que el workspace lo use en operaciones posteriores.
    public async Task<ClienteItem?> ObtenerClienteAsync(string externalId)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT c.ClienteID, c.ExternalId, c.Nombre, c.NIT, c.Contacto, c.Telefono, c.Email, c.Direccion, c.Estado,
                   c.FuenteContacto, c.TipoCliente, c.ResponsableID,
                   e.Nombres + ' ' + e.Apellidos AS Responsable, c.ProximoContacto,
                   (SELECT COUNT(*) FROM Crm.Contactos ct WHERE ct.ClienteID = c.ClienteID AND ct.Estado = 1) AS TotalContactos,
                   (SELECT MAX(i.Fecha) FROM Crm.Interacciones i WHERE i.ClienteID = c.ClienteID) AS UltimaInteraccion,
                   c.TipoPersona, c.PrimerNombre, c.SegundoNombre, c.PrimerApellido, c.SegundoApellido,
                   c.Departamento, c.Ciudad, c.TipoIdentificacion, c.CodigoDept, c.CodigoMuni, c.DigitoVerificacion
            FROM Crm.Clientes c
            LEFT JOIN Rrhh.Empleados e ON e.EmpleadoID = c.ResponsableID
            WHERE c.ExternalId = @ExternalId";

        return await connection.QuerySingleOrDefaultAsync<ClienteItem>(sql, new { ExternalId = externalId });
    }

    public async Task<int> CrearClienteAsync(CrearClienteRequest r)
    {
        using var connection = _db.CreateConnection();

        var tipoCliente = r.TipoCliente ?? (r.TipoPersona == "Natural" ? "Persona Natural" : r.TipoPersona == "Juridica" ? "Empresa" : null);

        const string sql = @"
            INSERT INTO Crm.Clientes (Nombre, NIT, Telefono, Email, Direccion, FuenteContacto, TipoCliente, ResponsableID,
                TipoPersona, PrimerNombre, SegundoNombre, PrimerApellido, SegundoApellido, Departamento, Ciudad,
                TipoIdentificacion, CodigoDept, CodigoMuni, DigitoVerificacion, FechaModificacion)
            OUTPUT INSERTED.ClienteID
            VALUES (@Nombre, @NIT, @Telefono, @Email, @Direccion, @FuenteContacto, @TipoCliente, @ResponsableID,
                @TipoPersona, @PrimerNombre, @SegundoNombre, @PrimerApellido, @SegundoApellido, @Departamento, @Ciudad,
                @TipoIdentificacion, @CodigoDept, @CodigoMuni, @DigitoVerificacion, GETDATE())";

        var id = await connection.ExecuteScalarAsync<int>(sql, new
        {
            r.Nombre, r.NIT, r.Telefono, r.Email, r.Direccion, r.FuenteContacto, TipoCliente = tipoCliente, r.ResponsableID,
            r.TipoPersona, r.PrimerNombre, r.SegundoNombre, r.PrimerApellido, r.SegundoApellido, r.Departamento, r.Ciudad,
            r.TipoIdentificacion, r.CodigoDept, r.CodigoMuni, r.DigitoVerificacion
        });

        if (!string.IsNullOrWhiteSpace(r.Email))
        {
            var empresa = await connection.ExecuteScalarAsync<string>(
                "SELECT TOP 1 NombreEmpresa FROM Organizacion.ConfiguracionEmpresa") ?? "NEXO ERP";
            var html = EmailTemplates.Bienvenida(empresa, r.Nombre);
            _ = _email.SendAsync(new EmailMessage(r.Email, $"Bienvenido/a a {empresa}", html, r.Nombre));
        }

        return id;
    }

    public async Task ActualizarClienteAsync(int clienteId, ActualizarClienteRequest r)
    {
        using var connection = _db.CreateConnection();

        var tipoClienteAct = r.TipoCliente ?? (r.TipoPersona == "Natural" ? "Persona Natural" : r.TipoPersona == "Juridica" ? "Empresa" : null);

        const string sql = @"
            UPDATE Crm.Clientes
            SET Nombre = @Nombre, NIT = @NIT, Telefono = @Telefono,
                Email = @Email, Direccion = @Direccion, Estado = @Estado,
                FuenteContacto = @FuenteContacto, TipoCliente = @TipoCliente,
                ResponsableID = @ResponsableID, ProximoContacto = @ProximoContacto,
                TipoPersona = @TipoPersona, PrimerNombre = @PrimerNombre, SegundoNombre = @SegundoNombre,
                PrimerApellido = @PrimerApellido, SegundoApellido = @SegundoApellido,
                Departamento = @Departamento, Ciudad = @Ciudad,
                TipoIdentificacion = @TipoIdentificacion, CodigoDept = @CodigoDept, CodigoMuni = @CodigoMuni,
                DigitoVerificacion = @DigitoVerificacion,
                FechaModificacion = GETDATE()
            WHERE ClienteID = @ClienteId";

        var filas = await connection.ExecuteAsync(sql, new
        {
            ClienteId = clienteId,
            r.Nombre, r.NIT, r.Telefono, r.Email, r.Direccion, r.Estado,
            r.FuenteContacto, TipoCliente = tipoClienteAct, r.ResponsableID, r.ProximoContacto,
            r.TipoPersona, r.PrimerNombre, r.SegundoNombre, r.PrimerApellido, r.SegundoApellido,
            r.Departamento, r.Ciudad, r.TipoIdentificacion, r.CodigoDept, r.CodigoMuni, r.DigitoVerificacion
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
                   a.Nombre + ' - ' + CAST(op.CantidadProgramada AS VARCHAR) + ' ' + ISNULL(a.PresentacionCodigo, '') AS Detalle
            FROM Produccion.OrdenesProduccion op
            JOIN Catalogo.Tarjetas a ON a.ArticuloID = op.ProductoTerminadoID
            WHERE op.ClienteID = @ClienteId

            UNION ALL

            SELECT 'DESPACHO' AS TipoEvento, d.FechaDespacho AS Fecha,
                   'GUIA-' + RIGHT('000000' + CAST(d.DespachoID AS VARCHAR(6)), 6) AS Titulo,
                   d.Estado + ISNULL(' - ' + d.Observaciones, '') AS Detalle
            FROM Logistica.Despachos d
            WHERE d.ClienteID = @ClienteId

            UNION ALL

            SELECT 'FACTURA' AS TipoEvento, f.Fecha,
                   'Factura #' + CAST(f.FacturaID AS VARCHAR) AS Titulo,
                   'Total: $' + FORMAT(ISNULL((SELECT SUM(l.Cantidad * l.PrecioUnitario) FROM Facturacion.FacturaLineas l WHERE l.FacturaID = f.FacturaID), 0), 'N0') AS Detalle
            FROM Facturacion.Facturas f
            WHERE f.ClienteID = @ClienteId

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

            // Si el lead tenía empresa: Nombre = persona, Contacto = empresa.
            // Si no tenía empresa: Nombre = persona, Contacto = null.
            var nombreCliente  = lead.Nombre;
            var contactoCliente = lead.Empresa; // null cuando no hay empresa

            const string sqlCrearCliente = @"
                INSERT INTO Crm.Clientes (Nombre, Contacto, Telefono, Email, FuenteContacto, ResponsableID)
                OUTPUT INSERTED.ClienteID
                VALUES (@Nombre, @Contacto, @Telefono, @Email, @FuenteContacto, @ResponsableID)";

            var clienteId = await connection.ExecuteScalarAsync<int>(sqlCrearCliente, new
            {
                Nombre   = nombreCliente,
                Contacto = contactoCliente,
                lead.Telefono, lead.Email, lead.FuenteContacto, lead.ResponsableID
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

    // Cambio rapido de etapa desde el listado (sin abrir el dialogo de edicion).
    // CONVERTIDO no se puede cambiar -- ya tiene un cliente asociado.
    public async Task CambiarEtapaLeadAsync(int leadId, string etapa)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            UPDATE Crm.Leads SET Etapa = @Etapa
            WHERE LeadID = @LeadId AND Etapa <> 'CONVERTIDO'";

        var filas = await connection.ExecuteAsync(sql, new { LeadId = leadId, Etapa = etapa });
        if (filas == 0)
            throw new InvalidOperationException("No se puede cambiar la etapa de este lead (ya fue convertido o no existe).");
    }

    private record LeadParaConvertir(string Nombre, string? Empresa, string? Telefono, string? Email, string? FuenteContacto, int? ResponsableID, string Etapa);

    // D) Clientes activos sin interaccion reciente (o con proximo contacto
    // vencido) -- no envia nada, solo los detecta para que alguien actue.
    public async Task<IEnumerable<ClienteFrioItem>> ListarClientesFriosAsync(int diasSinContacto)
    {
        using var connection = _db.CreateConnection();

        const string sql = @"
            SELECT c.ClienteID, c.ExternalId, c.Nombre, e.Nombres + ' ' + e.Apellidos AS Responsable,
                   (SELECT MAX(i.Fecha) FROM Crm.Interacciones i WHERE i.ClienteID = c.ClienteID) AS UltimaInteraccion,
                   c.ProximoContacto
            FROM Crm.Clientes c
            LEFT JOIN Rrhh.Empleados e ON e.EmpleadoID = c.ResponsableID
            WHERE c.Estado = 1
              AND c.NIT <> 'CF-SYS'
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
                   o.Nombre, o.ValorEstimado, o.ConfianzaCierre, o.Etapa, o.FechaCierreEsperada,
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
            INSERT INTO Crm.Oportunidades (LeadID, ClienteID, Nombre, ValorEstimado, ConfianzaCierre, FechaCierreEsperada, ResponsableID, Notas)
            OUTPUT INSERTED.OportunidadID
            VALUES (@LeadID, @ClienteID, @Nombre, @ValorEstimado, @ConfianzaCierre, @FechaCierreEsperada, @ResponsableID, @Notas)";

        return await connection.ExecuteScalarAsync<int>(sql, r);
    }

    // Al pasar a GANADA o PERDIDA se registra la fecha de cierre (solo la
    // primera vez -- no se pisa si ya tenia valor, mismo patron que
    // FechaCompletado en Hitos de Proyectos).
    public async Task ActualizarOportunidadAsync(int oportunidadId, ActualizarOportunidadRequest r)
    {
        using var connection = _db.CreateConnection();

        // Capturar estado anterior para detectar cambio de etapa (hook de automatización).
        var anterior = await connection.QueryFirstOrDefaultAsync<(string Etapa, int? ClienteID)>(
            "SELECT Etapa, ClienteID FROM Crm.Oportunidades WHERE OportunidadID = @Id",
            new { Id = oportunidadId });

        var cerrada = r.Etapa is "GANADA" or "PERDIDA";

        const string sql = @"
            UPDATE Crm.Oportunidades
            SET Nombre = @Nombre, ValorEstimado = @ValorEstimado, ConfianzaCierre = @ConfianzaCierre, Etapa = @Etapa,
                FechaCierreEsperada = @FechaCierreEsperada, ResponsableID = @ResponsableID, Notas = @Notas,
                FechaCierre = CASE WHEN @Cerrada = 1 THEN ISNULL(FechaCierre, SYSDATETIME()) ELSE NULL END
            WHERE OportunidadID = @OportunidadId";

        var filas = await connection.ExecuteAsync(sql, new
        {
            OportunidadId = oportunidadId, r.Nombre, r.ValorEstimado, r.ConfianzaCierre, r.Etapa,
            r.FechaCierreEsperada, r.ResponsableID, r.Notas, Cerrada = cerrada
        });

        if (filas == 0)
            throw new KeyNotFoundException($"No existe la oportunidad {oportunidadId}.");

        // Disparar automatización si cambió la etapa a una etapa activa.
        if (!string.IsNullOrEmpty(anterior.Etapa) && anterior.Etapa != r.Etapa && !cerrada)
            await _automacion.EvaluarEtapaCambiadaAsync(oportunidadId, anterior.ClienteID, r.ResponsableID, r.Etapa);
    }

    // ---------- Actividades CRM ----------

    public async Task<IEnumerable<ActividadItem>> ListarActividadesAsync(bool soloActivas, int? oportunidadId, int? clienteId)
    {
        using var connection = _db.CreateConnection();
        var sql = @"
            SELECT a.ActividadID, a.Tipo, a.Titulo, a.Notas,
                   a.FechaVencimiento, a.Completada, a.FechaCompletada,
                   a.OportunidadID, op.Nombre AS Oportunidad,
                   a.ClienteID, c.Nombre AS Cliente,
                   a.ResponsableID, CONCAT(u.Nombres, ' ', u.Apellidos) AS Responsable,
                   a.FechaCreacion
            FROM Crm.Actividades a
            LEFT JOIN Crm.Oportunidades op ON op.OportunidadID = a.OportunidadID
            LEFT JOIN Crm.Clientes c       ON c.ClienteID = a.ClienteID
            LEFT JOIN Seguridad.Usuarios u ON u.UsuarioID  = a.ResponsableID
            WHERE (@SoloActivas = 0 OR a.Completada = 0)
              AND (@OportunidadID IS NULL OR a.OportunidadID = @OportunidadID)
              AND (@ClienteID    IS NULL OR a.ClienteID    = @ClienteID)
            ORDER BY CASE WHEN a.FechaVencimiento IS NULL THEN 1 ELSE 0 END,
                     a.FechaVencimiento, a.FechaCreacion DESC";
        return await connection.QueryAsync<ActividadItem>(sql,
            new { SoloActivas = soloActivas ? 1 : 0, OportunidadID = oportunidadId, ClienteID = clienteId });
    }

    public async Task<int> CrearActividadAsync(CrearActividadRequest r)
    {
        if (r.OportunidadID is null && r.ClienteID is null)
            throw new InvalidOperationException("La actividad debe estar vinculada a una oportunidad o a un cliente.");
        using var connection = _db.CreateConnection();
        return await connection.ExecuteScalarAsync<int>(@"
            INSERT INTO Crm.Actividades (Tipo, Titulo, Notas, FechaVencimiento, OportunidadID, ClienteID, ResponsableID)
            OUTPUT INSERTED.ActividadID
            VALUES (@Tipo, @Titulo, @Notas, @FechaVencimiento, @OportunidadID, @ClienteID, @ResponsableID)",
            new { r.Tipo, r.Titulo, r.Notas, r.FechaVencimiento, r.OportunidadID, r.ClienteID, r.ResponsableID });
    }

    public async Task CompletarActividadAsync(int actividadId, bool completada)
    {
        using var connection = _db.CreateConnection();
        await connection.ExecuteAsync(@"
            UPDATE Crm.Actividades
            SET Completada = @Completada,
                FechaCompletada = CASE WHEN @Completada = 1 THEN SYSUTCDATETIME() ELSE NULL END
            WHERE ActividadID = @ActividadID",
            new { Completada = completada, ActividadID = actividadId });
    }

    public async Task EliminarActividadAsync(int actividadId)
    {
        using var connection = _db.CreateConnection();
        await connection.ExecuteAsync("DELETE FROM Crm.Actividades WHERE ActividadID = @ActividadID",
            new { ActividadID = actividadId });
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
            SELECT l.LineaID, l.CotizacionID, l.ArticuloID, a.Referencia AS SkuArticulo, a.Nombre AS NombreArticulo,
                   l.Cantidad, l.PrecioUnitario, (l.Cantidad * l.PrecioUnitario) AS Subtotal
            FROM Crm.CotizacionLineas l
            JOIN Catalogo.Tarjetas a ON a.ArticuloID = l.ArticuloID
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

        var lineasFactura = lineas.Select(l => new LineaFacturaInput(l.ArticuloID, null, null, l.Cantidad, l.PrecioUnitario)).ToList();
        var facturaRequest = new CrearFacturaRequest(
            cotizacion.ClienteID, DateTime.Today,
            $"Generada desde Cotización #{cotizacionId}",
            TipDoc: "FACTURA", NroDoc: null,
            Lineas: lineasFactura);

        var facturaId = await _facturacion.CrearFacturaAsync(facturaRequest, usuarioId);

        await connection.ExecuteAsync(
            "UPDATE Crm.Cotizaciones SET Estado = 'ACEPTADA', FacturaID = @FacturaId WHERE CotizacionID = @CotizacionId",
            new { FacturaId = facturaId, CotizacionId = cotizacionId });

        return facturaId;
    }

    public async Task<bool> EnviarEmailCotizacionAsync(int cotizacionId)
    {
        using var connection = _db.CreateConnection();

        var data = await connection.QueryFirstOrDefaultAsync<(int ClienteID, string Cliente, string? Email,
            DateTime Fecha, DateTime? ValidoHasta, decimal Total, string? Notas)>(@"
            SELECT c.ClienteID, cl.Nombre AS Cliente, cl.Email,
                   c.Fecha, c.ValidoHasta, c.Total, c.Notas
            FROM Crm.Cotizaciones c
            JOIN Crm.Clientes cl ON cl.ClienteID = c.ClienteID
            WHERE c.CotizacionID = @CotizacionId", new { CotizacionId = cotizacionId });

        if (data.Email is null)
            return false;

        var empresa = await connection.ExecuteScalarAsync<string>(
            "SELECT TOP 1 NombreEmpresa FROM Organizacion.ConfiguracionEmpresa") ?? "NEXO ERP";

        var html = EmailTemplates.Cotizacion(empresa, data.Cliente, cotizacionId,
            data.Fecha, data.ValidoHasta ?? data.Fecha.AddDays(30), data.Total, data.Notas);

        var enviado = await _email.SendAsync(new EmailMessage(
            data.Email, $"Cotización #{cotizacionId} de {empresa}", html, data.Cliente));

        if (enviado)
            await connection.ExecuteAsync(
                "UPDATE Crm.Cotizaciones SET Estado = 'ENVIADA' WHERE CotizacionID = @CotizacionId AND Estado = 'BORRADOR'",
                new { CotizacionId = cotizacionId });

        return enviado;
    }

    public async Task<IEnumerable<PaisItem>> ListarPaisesAsync()
    {
        using var connection = _db.CreateConnection();
        return await connection.QueryAsync<PaisItem>(
            "SELECT Codigo1, Codigo2, Codigo3, Nombre FROM Catalogo.Paises ORDER BY Nombre");
    }

    public async Task<IEnumerable<MunicipioItem>> ListarMunicipiosAsync()
    {
        using var connection = _db.CreateConnection();
        return await connection.QueryAsync<MunicipioItem>(
            "SELECT CodigoDept, NombreDept, CodigoMuni, NombreMuni FROM Catalogo.Municipios ORDER BY NombreDept, NombreMuni");
    }

    public async Task<IEnumerable<TipoIdentificacionItem>> ListarTiposIdentificacionAsync()
    {
        using var connection = _db.CreateConnection();
        return await connection.QueryAsync<TipoIdentificacionItem>(
            "SELECT Codigo, Detalle FROM Catalogo.TiposIdentificacion ORDER BY CAST(Codigo AS int)");
    }
}
