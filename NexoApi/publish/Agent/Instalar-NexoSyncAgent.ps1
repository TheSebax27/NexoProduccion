#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Instala NexoSyncAgent como Servicio de Windows.
.DESCRIPTION
    Copia el agente a C:\NexoSyncAgent\, instala y arranca el servicio de Windows.
    El appsettings.json que viene en la misma carpeta ya tiene la configuracion
    completa (clave, URL de NEXO y conexion a Visions) generada desde la web.
    Solo hay que ejecutar este script como Administrador.
#>

$serviceName = "NexoSyncAgent"
$serviceDesc = "Agente de sincronizacion NEXO ERP - Visions"
$destino     = "C:\NexoSyncAgent"
$exeDest     = Join-Path $destino "NexoSyncAgent.exe"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   Instalador NEXO Sync Agent" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# 1. Verificar que el ejecutable existe en la carpeta del script
$exeOrigen = Join-Path $PSScriptRoot "NexoSyncAgent.exe"
if (-not (Test-Path $exeOrigen)) {
    Write-Host "[ERROR] No se encontro NexoSyncAgent.exe en:" -ForegroundColor Red
    Write-Host "        $PSScriptRoot" -ForegroundColor Red
    Read-Host "Presiona Enter para salir"
    exit 1
}

# 2. Detener el servicio si estaba corriendo (libera el .exe para poder reemplazarlo)
$svc = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($svc) {
    Write-Host "Deteniendo servicio existente..." -ForegroundColor Yellow
    if ($svc.Status -eq "Running") {
        Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
    }
    Write-Host "Eliminando registro del servicio..." -ForegroundColor Yellow
    & sc.exe delete $serviceName | Out-Null
    Start-Sleep -Seconds 2
}

# 3. Copiar (o actualizar) todos los archivos a C:\NexoSyncAgent\
Write-Host "Copiando archivos a $destino ..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $destino -Force | Out-Null

Get-ChildItem -Path $PSScriptRoot -File | ForEach-Object {
    try {
        Copy-Item -Path $_.FullName -Destination $destino -Force
        Write-Host "  -> $($_.Name)" -ForegroundColor Gray
    } catch {
        Write-Host "  [!] No se pudo copiar $($_.Name): $_" -ForegroundColor Yellow
    }
}

# 4. Instalar el servicio apuntando a la ruta fija
Write-Host ""
Write-Host "Instalando servicio de Windows..." -ForegroundColor Cyan
& sc.exe create $serviceName binPath= "`"$exeDest`"" start= auto DisplayName= $serviceName | Out-Null
& sc.exe description $serviceName $serviceDesc | Out-Null
& sc.exe failure $serviceName reset= 86400 actions= restart/60000/restart/60000/restart/60000 | Out-Null

# 5. Arrancar el servicio
Write-Host "Iniciando servicio..." -ForegroundColor Cyan
& sc.exe start $serviceName | Out-Null
Start-Sleep -Seconds 4

# 6. Verificar resultado
$svc = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($svc -and $svc.Status -eq "Running") {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "   [OK] Instalacion completada" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "El agente esta corriendo en C:\NexoSyncAgent\" -ForegroundColor Green
    Write-Host "Se sincronizara automaticamente con NEXO en los proximos segundos." -ForegroundColor Green
    Write-Host "Inicia automaticamente con Windows — no hay que hacer nada mas." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Red
    Write-Host "   [ERROR] El servicio no pudo iniciarse" -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Posibles causas:" -ForegroundColor Yellow
    Write-Host "  - URL de NexoApi incorrecta o sin conexion a internet" -ForegroundColor Yellow
    Write-Host "  - Cadena de conexion a Visions incorrecta" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Revisa: Visor de Eventos -> Registros de Windows -> Aplicacion" -ForegroundColor Yellow
}

Write-Host ""
Read-Host "Presiona Enter para cerrar"
