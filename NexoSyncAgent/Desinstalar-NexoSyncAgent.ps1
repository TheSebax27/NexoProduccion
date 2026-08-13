#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Detiene, desinstala y elimina el NexoSyncAgent de esta maquina.
#>

$serviceName = "NexoSyncAgent"
$carpeta     = "C:\NexoSyncAgent"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   Desinstalador NEXO Sync Agent" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$svc = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($svc) {
    if ($svc.Status -eq "Running") {
        Write-Host "Deteniendo servicio..." -ForegroundColor Yellow
        Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
    }
    Write-Host "Eliminando servicio de Windows..." -ForegroundColor Yellow
    & sc.exe delete $serviceName | Out-Null
    Start-Sleep -Seconds 2
    Write-Host "[OK] Servicio eliminado." -ForegroundColor Green
} else {
    Write-Host "El servicio no estaba instalado en esta maquina." -ForegroundColor Yellow
}

# Preguntar si eliminar la carpeta
if (Test-Path $carpeta) {
    Write-Host ""
    $resp = Read-Host "Deseas eliminar la carpeta $carpeta ? (S/N)"
    if ($resp -match '^[Ss]') {
        try {
            Remove-Item -Path $carpeta -Recurse -Force
            Write-Host "[OK] Carpeta eliminada." -ForegroundColor Green
        } catch {
            Write-Host "[!] No se pudo eliminar la carpeta: $_" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "[OK] Desinstalacion completada." -ForegroundColor Green
Write-Host ""
Read-Host "Presiona Enter para cerrar"
