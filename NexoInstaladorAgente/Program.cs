using System.Diagnostics;
using System.Security.Principal;
using System.Text;

// ── Formato del ejecutable generado por NexoApi ──────────────────────────────
// [NexoInstaladorAgente.exe base]
// [appsettings.json en UTF-8]
// [4 bytes int32: longitud del appsettings]
// [NexoSyncAgent.exe binario]
// [8 bytes int64: longitud del exe del agente]
// ["NEXO_SETUP_V1" 13 bytes ASCII]  ← últimos bytes del archivo
// ─────────────────────────────────────────────────────────────────────────────

const string MagicStr       = "NEXO_SETUP_V1";
const string Carpeta        = @"C:\NexoSyncAgent";
const string NombreServicio = "NexoSyncAgent";
const string DescServicio   = "Agente de sincronizacion NEXO ERP - Visions";

Console.OutputEncoding = Encoding.UTF8;

// ── 1. Auto-elevar a Administrador si no lo somos ────────────────────────────
if (!EsAdministrador())
{
    try
    {
        Process.Start(new ProcessStartInfo
        {
            FileName        = Environment.ProcessPath!,
            UseShellExecute = true,
            Verb            = "runas"
        });
    }
    catch
    {
        Rojo("\n[ERROR] Se requieren permisos de Administrador.");
        Console.ReadKey();
    }
    return;
}

Cian("\n============================================");
Cian("   NEXO ERP - Instalador del Agente Sync   ");
Cian("============================================\n");

// ── 2. Leer datos embebidos al final del ejecutable ──────────────────────────
byte[] exeBytes;
try   { exeBytes = File.ReadAllBytes(Environment.ProcessPath!); }
catch { Fallo("No se pudo leer el instalador."); return; }

var magicBytes = Encoding.ASCII.GetBytes(MagicStr);
int fileLen    = exeBytes.Length;
int magicStart = fileLen - magicBytes.Length;

// Verificar magic
bool magicOk = true;
for (int i = 0; i < magicBytes.Length; i++)
    if (exeBytes[magicStart + i] != magicBytes[i]) { magicOk = false; break; }

if (!magicOk)
{
    Fallo("Instalador incompleto o corrupto. Descarga uno nuevo desde NEXO ERP.");
    return;
}

// Leer longitud del exe del agente (8 bytes antes del magic)
int agentLenPos = magicStart - 8;
long agentLen   = BitConverter.ToInt64(exeBytes, agentLenPos);

// Leer longitud del appsettings (4 bytes antes del bloque del agente)
int agentStart      = agentLenPos - (int)agentLen;
int settingsLenPos  = agentStart - 4;
int settingsLen     = BitConverter.ToInt32(exeBytes, settingsLenPos);
int settingsStart   = settingsLenPos - settingsLen;

if (settingsLen <= 0 || agentLen <= 0 || settingsStart < 0 || agentStart < 0)
{
    Fallo("Datos del instalador invalidos. Descarga uno nuevo desde NEXO ERP.");
    return;
}

var appsettingsJson = Encoding.UTF8.GetString(exeBytes, settingsStart, settingsLen);
var agentBin        = new byte[(int)agentLen];
Array.Copy(exeBytes, agentStart, agentBin, 0, (int)agentLen);

// ── 3. Detener el servicio si ya estaba corriendo ────────────────────────────
var svcActual = ObtenerEstadoServicio(NombreServicio);
if (svcActual is not null)
{
    Paso("Deteniendo servicio existente...");
    Sc("stop",   NombreServicio);
    Thread.Sleep(3000);
    Sc("delete", NombreServicio);
    // Esperar hasta que el SCM elimine el servicio (puede tardar si el proceso aún tiene handles abiertos)
    for (int i = 0; i < 20; i++)
    {
        if (ObtenerEstadoServicio(NombreServicio) is null) break;
        Thread.Sleep(500);
    }
    Verde("[OK]");
}

// ── 4. Crear directorio e instalar archivos ──────────────────────────────────
Paso("Preparando directorio de instalacion...");
Directory.CreateDirectory(Carpeta);
Verde("[OK]");

Paso("Instalando ejecutable del agente...  ");
var exeDest = Path.Combine(Carpeta, "NexoSyncAgent.exe");
try
{
    for (int intento = 1; intento <= 10; intento++)
    {
        try { File.WriteAllBytes(exeDest, agentBin); break; }
        catch (IOException) when (intento < 10) { Thread.Sleep(1000); }
    }
}
catch (Exception ex) { Fallo($"No se pudo instalar el ejecutable: {ex.Message}"); return; }
Verde("[OK]");

Paso("Escribiendo configuracion...         ");
try
{
    var settingsPath = Path.Combine(Carpeta, "appsettings.json");
    if (File.Exists(settingsPath))
    {
        var backup = settingsPath + $".bak_{DateTime.Now:yyyyMMddHHmmss}";
        File.Copy(settingsPath, backup, overwrite: true);
    }
    File.WriteAllText(settingsPath, appsettingsJson, Encoding.UTF8);
}
catch (Exception ex) { Fallo($"No se pudo escribir la configuracion: {ex.Message}"); return; }
Verde("[OK]");

// ── 5. Registrar e iniciar el servicio de Windows ───────────────────────────
var exePath = exeDest;
Paso("Registrando servicio de Windows...  ");
Sc("create",      $"{NombreServicio} binPath= \"{exePath}\" start= auto DisplayName= {NombreServicio}");
Sc("description", $"{NombreServicio} \"{DescServicio}\"");
Sc("failure",     $"{NombreServicio} reset= 86400 actions= restart/60000/restart/60000/restart/60000");
Verde("[OK]");

Paso("Iniciando servicio...               ");
Sc("start", NombreServicio);
Thread.Sleep(4000);
Verde("[OK]");

// ── 5.5. Insertar parametro NEXO en Visions PARAMETROS si no existe ──────────
Paso("Configurando parametro NEXO en Visions...  ");
try
{
    var connVisions = ExtraerConnectionStringVisions(appsettingsJson);
    if (connVisions is not null)
    {
        var sqlArgs = ConstruirArgsSqlcmd(connVisions);
        if (sqlArgs is not null)
        {
            const string sql =
                "IF NOT EXISTS (SELECT 1 FROM PARAMETROS WHERE PARAMETRO = 'NEXO') " +
                "INSERT INTO PARAMETROS (CONSECUTIVO, PARAMETRO, VALOR, DESCRIPCION, TIPOGRUPO) " +
                "VALUES (1905, 'NEXO', '1', 'MANEJAN NEXO', 'HABILITAR')";
            EjecutarSqlcmd(sqlArgs.Value.Args, sql, sqlArgs.Value.Password);
            Verde("[OK]");
        }
        else
            Console.WriteLine("[OMITIDO] No se pudo parsear la conexion de Visions");

    }
    else
        Console.WriteLine("[OMITIDO] No hay cadena VisionsDb en el appsettings.");
}
catch (Exception exSql)
{
    Console.WriteLine($"[ADVERTENCIA] No se inserto el parametro NEXO: {exSql.Message}");
}

// ── 5.6. Parametro SINCANTSA: bloquear ventas sin inventario ─────────────────
Paso("Configurando SINCANTSA...             ");
try
{
    var connSoloInv = ExtraerConnectionStringVisions(appsettingsJson);
    if (connSoloInv is not null)
    {
        var sqlArgsSoloInv = ConstruirArgsSqlcmd(connSoloInv);
        if (sqlArgsSoloInv is not null)
        {
            const string sqlSoloInv =
                "IF NOT EXISTS (SELECT 1 FROM PARAMETROS WHERE PARAMETRO = 'SINCANTSA') " +
                "INSERT INTO PARAMETROS (CONSECUTIVO, PARAMETRO, VALOR, DESCRIPCION, TIPOGRUPO) " +
                "VALUES (1518, 'SINCANTSA', '0', 'BUSCAR CANTIDADES EN INVENTARIO', 'HABILITAR')";

            EjecutarSqlcmd(sqlArgsSoloInv.Value.Args, sqlSoloInv, sqlArgsSoloInv.Value.Password);
            Verde("[OK]");
        }
        else
            Console.WriteLine("[OMITIDO] No se pudo parsear la conexion de Visions");
    }
    else
        Console.WriteLine("[OMITIDO] No hay cadena VisionsDb en el appsettings.");
}
catch (Exception exSoloInv)
{
    Console.WriteLine($"[ADVERTENCIA] No se configuro SINCANTSA: {exSoloInv.Message}");
}

// ── 6. Verificar resultado ───────────────────────────────────────────────────
var estadoFinal = ObtenerEstadoServicio(NombreServicio);
Console.WriteLine();
if (estadoFinal == "RUNNING")
{
    Console.ForegroundColor = ConsoleColor.Green;
    Console.WriteLine("============================================");
    Console.WriteLine("   [OK] Instalacion completada con exito    ");
    Console.WriteLine("============================================");
    Console.ResetColor();
    Console.WriteLine();
    Console.WriteLine($"  El agente esta corriendo en {Carpeta}");
    Console.WriteLine("  Se sincronizara con NEXO ERP automaticamente.");
    Console.WriteLine("  Arranca solo con Windows — no hay que hacer nada mas.");
}
else
{
    Console.ForegroundColor = ConsoleColor.Red;
    Console.WriteLine("============================================");
    Console.WriteLine("   [!] El servicio no pudo iniciarse        ");
    Console.WriteLine("============================================");
    Console.ResetColor();
    Console.WriteLine();
    Console.WriteLine("  Posibles causas:");
    Console.WriteLine("  - La URL de NEXO no es accesible desde este equipo");
    Console.WriteLine("  - La cadena de conexion a Visions es incorrecta");
    Console.WriteLine();
    Console.WriteLine("  Revisa: Visor de Eventos -> Registros de Windows -> Aplicacion");
}

Console.WriteLine();
Console.WriteLine("  Esta ventana se cerrara en 6 segundos...");
Thread.Sleep(6000);

// ── Helpers ──────────────────────────────────────────────────────────────────
static bool EsAdministrador()
{
    using var id = WindowsIdentity.GetCurrent();
    return new WindowsPrincipal(id).IsInRole(WindowsBuiltInRole.Administrator);
}

static string? ObtenerEstadoServicio(string nombre)
{
    var salida = Sc("query", nombre);
    if (salida.Contains("RUNNING")) return "RUNNING";
    if (salida.Contains("STATE"))   return "STOPPED";
    return null;
}

static string Sc(string accion, string args)
{
    try
    {
        var psi = new ProcessStartInfo("sc.exe", $"{accion} {args}")
        {
            UseShellExecute        = false,
            RedirectStandardOutput = true,
            CreateNoWindow         = true
        };
        using var p = Process.Start(psi)!;
        var out_ = p.StandardOutput.ReadToEnd();
        p.WaitForExit(10_000);
        return out_;
    }
    catch { return string.Empty; }
}

static void Paso(string msg)  { Console.Write($"  {msg} "); }
static void Verde(string msg) { Console.ForegroundColor = ConsoleColor.Green;  Console.WriteLine(msg); Console.ResetColor(); }
static void Cian(string msg)  { Console.ForegroundColor = ConsoleColor.Cyan;   Console.WriteLine(msg); Console.ResetColor(); }
static void Rojo(string msg)  { Console.ForegroundColor = ConsoleColor.Red;    Console.WriteLine(msg); Console.ResetColor(); }
static void Fallo(string msg) { Rojo($"\n[ERROR] {msg}\n"); Console.ReadKey(); }

// Extrae la connection string "VisionsDb" del JSON en memoria (appsettings).
static string? ExtraerConnectionStringVisions(string json)
{
    try
    {
        using var doc = System.Text.Json.JsonDocument.Parse(json);
        if (doc.RootElement.TryGetProperty("ConnectionStrings", out var cs) &&
            cs.TryGetProperty("VisionsDb", out var val))
            return val.GetString();
    }
    catch { }
    return null;
}

// Parsea la connection string y devuelve (args para sqlcmd, password opcional).
// Password nunca va en la linea de comandos; se pasa via SQLCMDPASSWORD env var.
static (string Args, string? Password)? ConstruirArgsSqlcmd(string connectionString)
{
    try
    {
        var partes = connectionString.Split(';', StringSplitOptions.RemoveEmptyEntries);
        var kv = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        foreach (var p in partes)
        {
            var idx = p.IndexOf('=');
            if (idx < 0) continue;
            kv[p[..idx].Trim()] = p[(idx + 1)..].Trim();
        }
        var server = kv.GetValueOrDefault("Server") ?? kv.GetValueOrDefault("Data Source");
        var db     = kv.GetValueOrDefault("Database") ?? kv.GetValueOrDefault("Initial Catalog");
        if (string.IsNullOrWhiteSpace(server) || string.IsNullOrWhiteSpace(db)) return null;

        var trusted = kv.TryGetValue("Trusted_Connection", out var tc) && tc.Equals("True", StringComparison.OrdinalIgnoreCase)
                   || kv.TryGetValue("Integrated Security", out var is_) && (is_.Equals("True", StringComparison.OrdinalIgnoreCase) || is_.Equals("SSPI", StringComparison.OrdinalIgnoreCase));

        if (trusted)
            return ($"-S \"{server}\" -d \"{db}\" -E", (string?)null);

        var user = kv.GetValueOrDefault("User ID") ?? kv.GetValueOrDefault("UID");
        var pwd  = kv.GetValueOrDefault("Password") ?? kv.GetValueOrDefault("PWD");
        if (string.IsNullOrWhiteSpace(user)) return null;
        // pwd via SQLCMDPASSWORD env var; nunca en command line
        return ($"-S \"{server}\" -d \"{db}\" -U \"{user}\"", pwd);
    }
    catch { return null; }
}

// Ejecuta sqlcmd con los args dados y el SQL en un archivo temporal.
// password se inyecta via SQLCMDPASSWORD env var para no exponerla en la linea de comandos.
static void EjecutarSqlcmd(string sqlcmdArgs, string sql, string? password = null)
{
    var tmp = Path.Combine(Path.GetTempPath(), $"nexo_setup_{Guid.NewGuid():N}.sql");
    try
    {
        File.WriteAllText(tmp, sql, System.Text.Encoding.UTF8);
        var psi = new ProcessStartInfo("sqlcmd.exe", $"{sqlcmdArgs} -i \"{tmp}\"")
        {
            UseShellExecute        = false,
            RedirectStandardOutput = true,
            RedirectStandardError  = true,
            CreateNoWindow         = true
        };
        if (!string.IsNullOrEmpty(password))
            psi.EnvironmentVariables["SQLCMDPASSWORD"] = password;
        using var p = Process.Start(psi) ?? throw new Exception("sqlcmd no encontrado en el PATH.");
        p.WaitForExit(15_000);
        if (p.ExitCode != 0)
        {
            var err = p.StandardError.ReadToEnd();
            if (!string.IsNullOrWhiteSpace(err)) throw new Exception(err.Trim());
        }
    }
    finally
    {
        try { File.Delete(tmp); } catch { }
    }
}
