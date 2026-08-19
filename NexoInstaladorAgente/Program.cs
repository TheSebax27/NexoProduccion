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
    Thread.Sleep(1500);
    Verde("[OK]");
}

// ── 4. Crear directorio e instalar archivos ──────────────────────────────────
Paso("Preparando directorio de instalacion...");
Directory.CreateDirectory(Carpeta);
Verde("[OK]");

Paso("Instalando ejecutable del agente...  ");
var exeDest = Path.Combine(Carpeta, "NexoSyncAgent.exe");
for (int intento = 1; intento <= 10; intento++)
{
    try { File.WriteAllBytes(exeDest, agentBin); break; }
    catch (IOException) when (intento < 10) { Thread.Sleep(1000); }
}
Verde("[OK]");

Paso("Escribiendo configuracion...         ");
File.WriteAllText(Path.Combine(Carpeta, "appsettings.json"), appsettingsJson, Encoding.UTF8);
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
