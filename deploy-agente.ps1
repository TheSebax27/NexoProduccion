# deploy-agente.ps1
# Publica NexoSyncAgent, detiene el servicio, reemplaza el exe y lo vuelve a arrancar.
# Uso: PowerShell -ExecutionPolicy Bypass -File "C:\Produccion\deploy-agente.ps1"
# Requiere: PowerShell como Administrador (para sc stop/start)

$ErrorActionPreference = "Stop"

$origen         = "C:\Produccion\NexoSyncAgent\publish\NexoSyncAgent.exe"
$destino        = "C:\NexoSyncAgent\NexoSyncAgent.exe"
$origenSettings = "C:\Produccion\NexoSyncAgent\appsettings.json"
$destinoSettings= "C:\NexoSyncAgent\appsettings.json"
$svc            = "NexoSyncAgent"

Write-Host ""
Write-Host "=== DEPLOY NEXO SYNC AGENT ===" -ForegroundColor Cyan

# 1. Publicar (single-file exe)
Write-Host ""
Write-Host "[1/5] Publicando NexoSyncAgent..." -ForegroundColor Yellow
Push-Location "C:\Produccion\NexoSyncAgent"
dotnet publish -c Release -r win-x64 --self-contained true -o publish `
    /p:PublishSingleFile=true `
    /p:EnableCompressionInSingleFile=true `
    /p:IncludeNativeLibrariesForSelfExtract=true | Select-Object -Last 3
Pop-Location

if (-not (Test-Path $origen)) {
    Write-Host "ERROR: No se encontro el exe publicado en $origen" -ForegroundColor Red
    exit 1
}

# 2. Detener el servicio
Write-Host ""
Write-Host "[2/5] Deteniendo servicio $svc..." -ForegroundColor Yellow
$svcObj = Get-Service -Name $svc -ErrorAction SilentlyContinue
$estado = if ($svcObj) { $svcObj.Status } else { "NotFound" }
if ($estado -eq "Running") {
    Stop-Service -Name $svc -Force
    # Esperar hasta que el proceso libere el exe (max 30s)
    $exePath = $destino
    $intentos = 0
    while ($intentos -lt 15) {
        Start-Sleep -Seconds 2
        $proc = Get-Process | Where-Object { $_.Path -eq $exePath } -ErrorAction SilentlyContinue
        if (-not $proc) { break }
        $intentos++
    }
    # Si sigue colgado, matar el proceso directamente
    $proc = Get-Process | Where-Object { try { $_.Path -eq $exePath } catch { $false } }
    if ($proc) { $proc | Stop-Process -Force; Start-Sleep -Seconds 2 }
    Write-Host "     Servicio detenido." -ForegroundColor Gray
} else {
    Write-Host "     Servicio no estaba corriendo ($estado)." -ForegroundColor Gray
}

# 3. Reemplazar exe y appsettings
Write-Host ""
Write-Host "[3/5] Copiando nuevo exe y configuracion..." -ForegroundColor Yellow
Copy-Item -Path $origen -Destination $destino -Force
$tamano = [math]::Round((Get-Item $destino).Length / 1MB, 1)
Write-Host "     Exe copiado: $destino ($tamano MB)" -ForegroundColor Gray

if (Test-Path $origenSettings) {
    Copy-Item -Path $origenSettings -Destination $destinoSettings -Force
    Write-Host "     appsettings.json copiado desde $origenSettings" -ForegroundColor Gray
} else {
    Write-Host "     ADVERTENCIA: No se encontro $origenSettings" -ForegroundColor Yellow
}

# 4. Arrancar servicio
Write-Host ""
Write-Host "[4/5] Arrancando servicio $svc..." -ForegroundColor Yellow
Start-Service -Name $svc
Start-Sleep -Seconds 4
$nuevoEstado = (Get-Service -Name $svc).Status
if ($nuevoEstado -eq "Running") {
    Write-Host "     Servicio corriendo." -ForegroundColor Green
} else {
    Write-Host "     ADVERTENCIA: estado = $nuevoEstado. Revisar Event Viewer." -ForegroundColor Red
    exit 1
}

# 5. Validar API Key contra NEXO
Write-Host ""
Write-Host "[5/5] Validando API Key contra NEXO..." -ForegroundColor Yellow
try {
    $settings = Get-Content $destinoSettings -Raw | ConvertFrom-Json
    $apiKey   = $settings.NexoApi.ApiKey
    $baseUrl  = $settings.NexoApi.BaseUrl

    if (-not $apiKey -or -not $baseUrl) {
        Write-Host "     ADVERTENCIA: No se pudo leer ApiKey o BaseUrl de appsettings.json." -ForegroundColor Yellow
    } else {
        # PS 5.1 rechaza el certificado de desarrollo de ASP.NET Core (self-signed).
        # Para validacion local lo ignoramos — el agente usa HttpClient de .NET que
        # confía en el certificado normalmente.
        try {
            Add-Type -TypeDefinition @'
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class _TrustAll : ICertificatePolicy {
    public bool CheckValidationResult(ServicePoint sp, X509Certificate cert,
        WebRequest req, int problem) { return true; }
}
'@ -ErrorAction SilentlyContinue
            [System.Net.ServicePointManager]::CertificatePolicy = New-Object _TrustAll
        } catch { }

        $headers    = @{ "X-Api-Key" = $apiKey; "Content-Type" = "application/json" }
        $body       = '{"Version":"deploy-check"}'
        $baseUrl    = $baseUrl.TrimEnd('/')
        $statusCode = 0
        try {
            $resp       = Invoke-WebRequest -Uri "$baseUrl/api/integracion/latido" `
                              -Method POST -Headers $headers -Body $body -UseBasicParsing -TimeoutSec 10
            $statusCode = [int]$resp.StatusCode
        } catch {
            $webResp = $_.Exception.Response
            if ($webResp -ne $null) { $statusCode = [int]$webResp.StatusCode } else { throw }
        }

        if ($statusCode -eq 200) {
            Write-Host "     API Key valida - latido respondio OK." -ForegroundColor Green
        } elseif ($statusCode -eq 401) {
            Write-Host ""
            Write-Host "     [ERROR 401] API KEY INVALIDA." -ForegroundColor Red
            Write-Host "     La clave en appsettings.json no esta en NEXO o esta inactiva." -ForegroundColor Red
            Write-Host "     Para corregir:" -ForegroundColor Yellow
            Write-Host "       1. Abre NEXO Web, ve a Integracion Visions, Configurar agente" -ForegroundColor Yellow
            Write-Host "       2. Selecciona el Centro de Costo correcto y haz clic en Regenerar clave" -ForegroundColor Yellow
            Write-Host "       3. Copia la clave en appsettings.json campo NexoApi.ApiKey" -ForegroundColor Yellow
            Write-Host "       4. Vuelve a ejecutar este script." -ForegroundColor Yellow
            Write-Host ""
        } else {
            Write-Host "     NEXO respondio HTTP $statusCode - puede que NexoApi no este corriendo." -ForegroundColor Yellow
            Write-Host "     Arranca NexoApi en Visual Studio con F5 y verifica el latido en NEXO Web." -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "     No se pudo conectar a NEXO para validar la key: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "     Asegurate de que NexoApi este corriendo (F5 en VS)." -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== LISTO ===" -ForegroundColor Cyan
Write-Host "Revisa NEXO Web, seccion Integracion, para ver el latido." -ForegroundColor White
Write-Host ""
