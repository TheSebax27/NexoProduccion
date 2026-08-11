using System.Security.Cryptography;
using System.Text;
using Dapper;
using NexoApi.Common.Data;
using NexoApi.Features.Rrhh.Dtos;

namespace NexoApi.Features.Rrhh;

public interface IAsistenciaService
{
    Task<TokenQrResponse> ObtenerTokenActualAsync();
    Task<bool> ValidarTokenAsync(string token);

    Task<IEnumerable<HorarioItem>> ListarHorariosAsync();
    Task<int> CrearHorarioAsync(CrearHorarioRequest request);
    Task AsignarHorarioEmpleadoAsync(int empleadoId, AsignarHorarioRequest request);

    Task<EstadoAsistenciaHoy> ObtenerEstadoHoyAsync(int usuarioId);
    Task MarcarQrAsync(int usuarioId, MarcarQrRequest request);
    Task MarcarManualAsync(int registradorUsuarioId, MarcarManualRequest request);

    Task<IEnumerable<RegistroAsistenciaItem>> ListarAsync(int? empleadoId, DateOnly? desde, DateOnly? hasta);
}

public class AsistenciaService(IDbConnectionFactory db) : IAsistenciaService
{
    // ---- Token TOTP-style (ventana de 5 minutos) ----

    private async Task<string> ObtenerSecretoAsync()
    {
        using var conn = db.CreateConnection();
        return await conn.QueryFirstOrDefaultAsync<string>(
            "SELECT TOP 1 Secreto FROM Rrhh.QrAsistenciaConfig") ?? "nexo-fallback";
    }

    private static string Computar(string secreto, long ventana)
    {
        var input = Encoding.UTF8.GetBytes($"{secreto}:{ventana}");
        return Convert.ToHexString(SHA256.HashData(input))[..16].ToLower();
    }

    public async Task<TokenQrResponse> ObtenerTokenActualAsync()
    {
        var secreto = await ObtenerSecretoAsync();
        var ahora = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
        var token = Computar(secreto, ahora / 300);
        return new TokenQrResponse(token, (int)(300 - ahora % 300));
    }

    public async Task<bool> ValidarTokenAsync(string token)
    {
        var secreto = await ObtenerSecretoAsync();
        var ventana = DateTimeOffset.UtcNow.ToUnixTimeSeconds() / 300;
        // Acepta ventana actual y anterior (periodo de gracia al rotar)
        return Computar(secreto, ventana) == token || Computar(secreto, ventana - 1) == token;
    }

    // ---- Horarios ----

    private record HorarioRow(int HorarioID, string Nombre, int ToleranciaTardanzaMin, string TipoCiclo, bool Activo, bool RegistraSalida);
    private record HorarioDiaRow(int HorarioID, byte DiaSemana, string? Semana, TimeSpan HoraEntrada, TimeSpan HoraSalida, bool TieneAlmuerzo, TimeSpan? HoraInicioAlmuerzo, TimeSpan? HoraFinAlmuerzo);

    public async Task<IEnumerable<HorarioItem>> ListarHorariosAsync()
    {
        using var conn = db.CreateConnection();
        var horarios = (await conn.QueryAsync<HorarioRow>(
            "SELECT HorarioID, Nombre, ToleranciaTardanzaMin, TipoCiclo, Activo, RegistraSalida FROM Rrhh.Horarios ORDER BY Nombre"
        )).ToList();

        if (horarios.Count == 0) return [];

        var ids = horarios.Select(h => h.HorarioID).ToList();
        var diasRaw = await conn.QueryAsync<HorarioDiaRow>("""
            SELECT HorarioID, DiaSemana, Semana, HoraEntrada, HoraSalida,
                   TieneAlmuerzo, HoraInicioAlmuerzo, HoraFinAlmuerzo
            FROM Rrhh.HorarioDias
            WHERE HorarioID IN @ids
            ORDER BY HorarioID, Semana, DiaSemana
            """, new { ids });

        var diasPorHorario = diasRaw.GroupBy(d => d.HorarioID)
            .ToDictionary(g => g.Key, g => g.Select(d => new HorarioDiaItem(
                d.DiaSemana, d.Semana,
                TimeOnly.FromTimeSpan(d.HoraEntrada), TimeOnly.FromTimeSpan(d.HoraSalida),
                d.TieneAlmuerzo,
                d.HoraInicioAlmuerzo.HasValue ? TimeOnly.FromTimeSpan(d.HoraInicioAlmuerzo.Value) : null,
                d.HoraFinAlmuerzo.HasValue    ? TimeOnly.FromTimeSpan(d.HoraFinAlmuerzo.Value)    : null
            )).ToList());

        return horarios.Select(h => new HorarioItem(
            h.HorarioID, h.Nombre, h.ToleranciaTardanzaMin, h.TipoCiclo, h.Activo, h.RegistraSalida,
            diasPorHorario.TryGetValue(h.HorarioID, out var ds) ? ds : []
        ));
    }

    public async Task<int> CrearHorarioAsync(CrearHorarioRequest r)
    {
        using var conn = db.CreateConnection();
        var horarioId = await conn.ExecuteScalarAsync<int>("""
            INSERT INTO Rrhh.Horarios (Nombre, ToleranciaTardanzaMin, TipoCiclo, RegistraSalida, Activo)
            OUTPUT INSERTED.HorarioID
            VALUES (@Nombre, @ToleranciaTardanzaMin, @TipoCiclo, @RegistraSalida, 1)
            """, new { r.Nombre, r.ToleranciaTardanzaMin, r.TipoCiclo, r.RegistraSalida });

        foreach (var dia in r.Dias)
        {
            await conn.ExecuteAsync("""
                INSERT INTO Rrhh.HorarioDias
                    (HorarioID, DiaSemana, Semana, HoraEntrada, HoraSalida,
                     TieneAlmuerzo, HoraInicioAlmuerzo, HoraFinAlmuerzo)
                VALUES (@horarioId, @DiaSemana, @Semana, @HoraEntrada, @HoraSalida,
                        @TieneAlmuerzo, @HoraInicioAlmuerzo, @HoraFinAlmuerzo)
                """, new { horarioId, dia.DiaSemana, dia.Semana,
                    dia.HoraEntrada, dia.HoraSalida, dia.TieneAlmuerzo,
                    dia.HoraInicioAlmuerzo, dia.HoraFinAlmuerzo });
        }

        return horarioId;
    }

    public async Task AsignarHorarioEmpleadoAsync(int empleadoId, AsignarHorarioRequest r)
    {
        using var conn = db.CreateConnection();
        var desdeDate = r.Desde.Date;
        // Cierra asignación vigente
        await conn.ExecuteAsync("""
            UPDATE Rrhh.EmpleadoHorario SET Hasta = DATEADD(DAY,-1,@Desde)
            WHERE EmpleadoID=@EmpleadoID AND Hasta IS NULL
            """, new { EmpleadoID = empleadoId, Desde = desdeDate });

        await conn.ExecuteAsync("""
            INSERT INTO Rrhh.EmpleadoHorario (EmpleadoID,HorarioID,Desde)
            VALUES (@EmpleadoID,@HorarioID,@Desde)
            """, new { EmpleadoID = empleadoId, r.HorarioID, Desde = desdeDate });
    }

    // ---- Estado y marcado ----

    private async Task<int?> EmpleadoDeUsuarioAsync(int usuarioId)
    {
        using var conn = db.CreateConnection();
        return await conn.QueryFirstOrDefaultAsync<int?>(
            "SELECT EmpleadoID FROM Seguridad.Usuarios WHERE UsuarioID=@usuarioId", new { usuarioId });
    }

    public async Task<EstadoAsistenciaHoy> ObtenerEstadoHoyAsync(int usuarioId)
    {
        var empleadoId = await EmpleadoDeUsuarioAsync(usuarioId)
            ?? throw new InvalidOperationException("Tu usuario no está vinculado a ningún empleado. Contacta al administrador.");

        using var conn = db.CreateConnection();
        var fila = await conn.QueryFirstOrDefaultAsync<FilaEstado>("""
            SELECT e.EmpleadoID, e.Nombres+' '+e.Apellidos AS Empleado,
                   r.HoraEntrada, r.MetodoEntrada, r.HoraSalida, r.MetodoSalida,
                   ISNULL(h.RegistraSalida, 1) AS RegistraSalida
            FROM Rrhh.Empleados e
            LEFT JOIN Rrhh.RegistroAsistencia r
                ON r.EmpleadoID=e.EmpleadoID AND r.Fecha=CAST(GETDATE() AS DATE)
            LEFT JOIN Rrhh.EmpleadoHorario eh
                ON eh.EmpleadoID=e.EmpleadoID
                AND eh.Desde <= CAST(GETDATE() AS DATE)
                AND (eh.Hasta IS NULL OR eh.Hasta >= CAST(GETDATE() AS DATE))
            LEFT JOIN Rrhh.Horarios h ON h.HorarioID=eh.HorarioID AND h.Activo=1
            WHERE e.EmpleadoID=@empleadoId
            """, new { empleadoId }) ?? throw new InvalidOperationException("Empleado no encontrado.");

        return new EstadoAsistenciaHoy(
            fila.EmpleadoID, fila.Empleado,
            fila.HoraEntrada is not null, fila.HoraEntrada, fila.MetodoEntrada,
            fila.HoraSalida is not null, fila.HoraSalida, fila.MetodoSalida,
            fila.RegistraSalida);
    }

    public async Task MarcarQrAsync(int usuarioId, MarcarQrRequest request)
    {
        if (!await ValidarTokenAsync(request.Token))
            throw new InvalidOperationException("El código QR no es válido o ya expiró. Escanea el código nuevamente.");

        var empleadoId = await EmpleadoDeUsuarioAsync(usuarioId)
            ?? throw new InvalidOperationException("Tu usuario no está vinculado a ningún empleado.");

        await MarcarInternoAsync(empleadoId, request.Tipo, DateTime.Now, "QR", adminId: null, nota: null);
    }

    public async Task MarcarManualAsync(int registradorId, MarcarManualRequest request)
        => await MarcarInternoAsync(request.EmpleadoID, request.Tipo, request.Hora, "MANUAL", registradorId, request.Nota);

    private async Task MarcarInternoAsync(int empleadoId, string tipo, DateTime hora, string metodo, int? adminId, string? nota)
    {
        using var conn = db.CreateConnection();
        var fecha = hora.Date;

        if (tipo == "ENTRADA")
        {
            var yaEntrada = await conn.QueryFirstOrDefaultAsync<int?>("""
                SELECT RegistroID FROM Rrhh.RegistroAsistencia
                WHERE EmpleadoID=@empleadoId AND Fecha=@fecha AND HoraEntrada IS NOT NULL
                """, new { empleadoId, fecha });
            if (yaEntrada.HasValue)
                throw new InvalidOperationException("Ya existe una entrada registrada para ese empleado en esa fecha.");

            var tardanza = await CalcularTardanzaAsync(conn, empleadoId, DateOnly.FromDateTime(hora), TimeOnly.FromDateTime(hora));

            await conn.ExecuteAsync("""
                MERGE Rrhh.RegistroAsistencia AS t
                USING (SELECT @empleadoId AS EmpleadoID, @fecha AS Fecha) AS s
                ON t.EmpleadoID=s.EmpleadoID AND t.Fecha=s.Fecha
                WHEN MATCHED THEN
                    UPDATE SET HoraEntrada=@hora, MetodoEntrada=@metodo,
                               EntradaRegistradaPor=@adminId, EntradaNota=@nota, MinutosTardanza=@tardanza
                WHEN NOT MATCHED THEN
                    INSERT (EmpleadoID,Fecha,HoraEntrada,MetodoEntrada,EntradaRegistradaPor,EntradaNota,MinutosTardanza)
                    VALUES (@empleadoId,@fecha,@hora,@metodo,@adminId,@nota,@tardanza);
                """, new { empleadoId, fecha, hora, metodo, adminId, nota, tardanza });
        }
        else // SALIDA
        {
            var registro = await conn.QueryFirstOrDefaultAsync<int?>("""
                SELECT RegistroID FROM Rrhh.RegistroAsistencia
                WHERE EmpleadoID=@empleadoId AND Fecha=@fecha
                  AND HoraEntrada IS NOT NULL AND HoraSalida IS NULL
                """, new { empleadoId, fecha });
            if (!registro.HasValue)
                throw new InvalidOperationException("No hay entrada registrada para esa fecha o ya existe una salida.");

            await conn.ExecuteAsync("""
                UPDATE Rrhh.RegistroAsistencia
                SET HoraSalida=@hora, MetodoSalida=@metodo,
                    SalidaRegistradaPor=@adminId, SalidaNota=@nota
                WHERE EmpleadoID=@empleadoId AND Fecha=@fecha
                """, new { empleadoId, fecha, hora, metodo, adminId, nota });
        }
    }

    private static async Task<int?> CalcularTardanzaAsync(
        System.Data.IDbConnection conn, int empleadoId, DateOnly fecha, TimeOnly horaReal)
    {
        var dow = fecha.DayOfWeek;
        var diaSemana = dow == DayOfWeek.Sunday ? 7 : (int)dow;
        var isoWeek = System.Globalization.ISOWeek.GetWeekOfYear(fecha.ToDateTime(TimeOnly.MinValue));
        // FIJO usa Semana=NULL (match por IS NULL en la query). AB: par=A,impar=B. 4: mod4→A/B/C/D
        var semana = (isoWeek % 4) switch { 0 => "A", 1 => "B", 2 => "C", _ => "D" };

        var horario = await conn.QueryFirstOrDefaultAsync<HorarioSchedule>("""
            SELECT hd.HoraEntrada, h.ToleranciaTardanzaMin
            FROM Rrhh.EmpleadoHorario eh
            JOIN Rrhh.Horarios h ON h.HorarioID=eh.HorarioID
            JOIN Rrhh.HorarioDias hd ON hd.HorarioID=h.HorarioID
                AND hd.DiaSemana=@diaSemana
                AND (hd.Semana IS NULL OR hd.Semana=@semana)
            WHERE eh.EmpleadoID=@empleadoId
              AND eh.Desde <= @fecha AND (eh.Hasta IS NULL OR eh.Hasta >= @fecha)
              AND h.Activo=1
            """, new { empleadoId, fecha = fecha.ToDateTime(TimeOnly.MinValue), diaSemana, semana });

        if (horario is null) return null;

        var entradaHorario = TimeOnly.FromTimeSpan(horario.HoraEntrada);
        var limite = entradaHorario.AddMinutes(horario.ToleranciaTardanzaMin);
        if (horaReal <= limite) return 0;
        return (int)(horaReal - entradaHorario).TotalMinutes;
    }

    public async Task<IEnumerable<RegistroAsistenciaItem>> ListarAsync(int? empleadoId, DateOnly? desde, DateOnly? hasta)
    {
        using var conn = db.CreateConnection();
        DateTime? desdeDate = desde.HasValue ? desde.Value.ToDateTime(TimeOnly.MinValue) : null;
        DateTime? hastaDate = hasta.HasValue  ? hasta.Value.ToDateTime(new TimeOnly(23, 59, 59)) : null;

        return await conn.QueryAsync<RegistroAsistenciaItem>("""
            SELECT r.RegistroID, r.EmpleadoID,
                   e.Nombres+' '+e.Apellidos AS Empleado,
                   r.Fecha, r.HoraEntrada, r.MetodoEntrada,
                   COALESCE(ur.Nombres+' '+ur.Apellidos, NULL) AS EntradaRegistradaPor,
                   r.EntradaNota, r.HoraSalida, r.MetodoSalida,
                   COALESCE(us.Nombres+' '+us.Apellidos, NULL) AS SalidaRegistradaPor,
                   r.SalidaNota, r.MinutosTardanza,
                   CASE WHEN r.HoraEntrada IS NOT NULL AND r.HoraSalida IS NOT NULL
                        THEN CAST(DATEDIFF(MINUTE,r.HoraEntrada,r.HoraSalida) AS FLOAT)/60.0
                        ELSE NULL END AS HorasEfectivas
            FROM Rrhh.RegistroAsistencia r
            JOIN Rrhh.Empleados e ON e.EmpleadoID=r.EmpleadoID
            LEFT JOIN Seguridad.Usuarios ur ON ur.UsuarioID=r.EntradaRegistradaPor
            LEFT JOIN Seguridad.Usuarios us ON us.UsuarioID=r.SalidaRegistradaPor
            WHERE (@empleadoId IS NULL OR r.EmpleadoID=@empleadoId)
              AND (@desdeDate IS NULL OR r.Fecha>=@desdeDate)
              AND (@hastaDate IS NULL OR r.Fecha<=@hastaDate)
            ORDER BY r.Fecha DESC, e.Apellidos
            """, new { empleadoId, desdeDate, hastaDate });
    }

    private record FilaEstado(int EmpleadoID, string Empleado,
        DateTime? HoraEntrada, string? MetodoEntrada, DateTime? HoraSalida, string? MetodoSalida,
        bool RegistraSalida);

    private record HorarioSchedule(TimeSpan HoraEntrada, int ToleranciaTardanzaMin);
}
