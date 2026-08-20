# deploy-agente.ps1
# Publica NexoSyncAgent, detiene el servicio, reemplaza el exe y lo vuelve a arrancar.
# Uso: .\deploy-agente.ps1
# Requiere: PowerShell como Administrador (para sc stop/start)

$ErrorActionPreference = "Stop"

$origen  = "C:\Produccion\NexoSyncAgent\publish\NexoSyncAgent.exe"
$destino = "C:\NexoSyncAgent\NexoSyncAgent.exe"
$svc     = "NexoSyncAgent"

Write-Host ""
Write-Host "=== DEPLOY NEXO SYNC AGENT ===" -ForegroundColor Cyan

# 1. Publicar (single-file exe)
Write-Host ""
Write-Host "[1/4] Publicando NexoSyncAgent..." -ForegroundColor Yellow
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
Write-Host "[2/4] Deteniendo servicio $svc..." -ForegroundColor Yellow
$svcObj = Get-Service -Name $svc -ErrorAction SilentlyContinue
$estado = if ($svcObj) { $svcObj.Status } else { "NotFound" }
if ($estado -eq "Running") {
    Stop-Service -Name $svc -Force
    Start-Sleep -Seconds 2
    Write-Host "     Servicio detenido." -ForegroundColor Gray
} else {
    Write-Host "     Servicio no estaba corriendo ($estado)." -ForegroundColor Gray
}

# 3. Reemplazar exe
Write-Host ""
Write-Host "[3/4] Copiando nuevo exe..." -ForegroundColor Yellow
Copy-Item -Path $origen -Destination $destino -Force
$tamano = [math]::Round((Get-Item $destino).Length / 1MB, 1)
Write-Host "     Copiado: $destino ($tamano MB)" -ForegroundColor Gray

# 4. Arrancar servicio
Write-Host ""
Write-Host "[4/4] Arrancando servicio $svc..." -ForegroundColor Yellow
Start-Service -Name $svc
Start-Sleep -Seconds 3
$nuevoEstado = (Get-Service -Name $svc).Status
if ($nuevoEstado -eq "Running") {
    Write-Host "     Servicio corriendo." -ForegroundColor Green
} else {
    Write-Host "     ADVERTENCIA: estado = $nuevoEstado. Revisar Event Viewer." -ForegroundColor Red
}

Write-Host ""
Write-Host "=== LISTO ===" -ForegroundColor Cyan
Write-Host "Revisa NEXO Web > Integracion > Estado para ver el latido." -ForegroundColor White
Write-Host ""
