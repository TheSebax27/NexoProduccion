##############################################################################
#  NEXO ERP — Script de deploy local
#  Genera los publicados de NexoApi (+ agentes bundled) y NexoWeb.
#  Ejecucion: .\deploy.ps1
#  Opcional:  .\deploy.ps1 -Solo Api   |  -Solo Web   |  -Solo Agentes
##############################################################################

param(
    [ValidateSet("Todo", "Api", "Web", "Agentes")]
    [string]$Solo = "Todo"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Raiz       = $PSScriptRoot
$PublishApi = Join-Path $Raiz "Publish\Api"
$PublishWeb = Join-Path $Raiz "Publish\Web"

$ProyApi        = Join-Path $Raiz "NexoApi\NexoApi.csproj"
$ProyWeb        = Join-Path $Raiz "NexoWeb\NexoWeb.csproj"
$ProyAgente     = Join-Path $Raiz "NexoSyncAgent\NexoSyncAgent.csproj"
$ProyInstalador = Join-Path $Raiz "NexoInstaladorAgente\NexoInstaladorAgente.csproj"
$AgentPublish   = Join-Path $Raiz "NexoSyncAgent\publish"

function Titulo($msg) {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  $msg" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
}

function Ok($msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Info($msg) { Write-Host "  -->  $msg" -ForegroundColor Gray }
function Warn($msg) { Write-Host "  [!]  $msg" -ForegroundColor Yellow }

##############################################################################
# AGENTES (NexoInstaladorAgente + NexoSyncAgent)
# Normalmente esto lo hace el MSBuild target de NexoApi automaticamente.
# Solo ejecutar manualmente si publicas los agentes por separado.
##############################################################################
function Publicar-Agentes {
    Titulo "Publicando NexoInstaladorAgente"
    Info "Destino: $AgentPublish"
    dotnet publish $ProyInstalador -c Release -r win-x64 --self-contained `
        -p:PublishSingleFile=true -p:PublishTrimmed=true `
        -o $AgentPublish --nologo
    Ok "NexoInstaladorAgente.exe generado"

    Titulo "Publicando NexoSyncAgent"
    Info "Destino: $AgentPublish"
    dotnet publish $ProyAgente -c Release -r win-x64 --self-contained `
        -p:PublishSingleFile=true `
        -o $AgentPublish --nologo
    Ok "NexoSyncAgent.exe generado"

    $instalador = Join-Path $AgentPublish "NexoInstaladorAgente.exe"
    $agente     = Join-Path $AgentPublish "NexoSyncAgent.exe"
    if (Test-Path $instalador) { Info "NexoInstaladorAgente.exe  $('{0:N0}' -f (Get-Item $instalador).Length) bytes" }
    if (Test-Path $agente)     { Info "NexoSyncAgent.exe         $('{0:N0}' -f (Get-Item $agente).Length) bytes" }
}

##############################################################################
# API  (incluye agentes automaticamente via MSBuild target PublicarAgentes)
##############################################################################
function Publicar-Api {
    Titulo "Publicando NexoApi (+ agentes bundled)"
    Info "Destino: $PublishApi"

    if (Test-Path $PublishApi) {
        Remove-Item $PublishApi -Recurse -Force
        Info "Carpeta anterior limpiada"
    }

    dotnet publish $ProyApi -c Release -o $PublishApi --nologo

    # Verificar que los agentes quedaron dentro
    $agentDir   = Join-Path $PublishApi "Agent"
    $hayAgente  = Test-Path (Join-Path $agentDir "NexoSyncAgent.exe")
    $hayInstall = Test-Path (Join-Path $agentDir "NexoInstaladorAgente.exe")
    if ($hayAgente -and $hayInstall) {
        Ok "NexoApi.exe publicado"
        Ok "Agent\NexoSyncAgent.exe       bundled"
        Ok "Agent\NexoInstaladorAgente.exe bundled"
    } else {
        Warn "Los agentes NO quedaron en Agent\. Revisa el target PublicarAgentes en NexoApi.csproj"
    }
}

##############################################################################
# WEB
##############################################################################
function Publicar-Web {
    Titulo "Publicando NexoWeb"
    Info "Destino: $PublishWeb"

    if (Test-Path $PublishWeb) {
        Remove-Item $PublishWeb -Recurse -Force
        Info "Carpeta anterior limpiada"
    }

    dotnet publish $ProyWeb -c Release -o $PublishWeb --nologo
    Ok "NexoWeb.exe publicado"
}

##############################################################################
# RESUMEN FINAL
##############################################################################
function Resumen {
    Titulo "Deploy completado"

    if ($Solo -eq "Todo" -or $Solo -eq "Api") {
        Write-Host ""
        Write-Host "  NEXO API" -ForegroundColor White
        Write-Host "  Carpeta : $PublishApi" -ForegroundColor Gray
        Write-Host "  Editar  : $PublishApi\appsettings.Production.json" -ForegroundColor Yellow
        Write-Host "            -> ApiBaseUrl  (URL publica de la API, ej: https://apinexo.colombiasis.com)" -ForegroundColor Yellow
        Write-Host "  NOTA    : La BD de cada cliente se resuelve automaticamente desde admin_services" -ForegroundColor DarkCyan
        Write-Host "            segun el subdominio del Host header. No es necesario configurar NexoDb." -ForegroundColor DarkCyan
    }

    if ($Solo -eq "Todo" -or $Solo -eq "Web") {
        Write-Host ""
        Write-Host "  NEXO WEB" -ForegroundColor White
        Write-Host "  Carpeta : $PublishWeb" -ForegroundColor Gray
        Write-Host "  Editar  : $PublishWeb\appsettings.Production.json" -ForegroundColor Yellow
        Write-Host "            -> NexoApi.BaseUrl           (URL publica de la API + /)" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "  SQL (solo instalacion nueva):" -ForegroundColor White
    Write-Host "  1. SQL_Finales\nexosqlcompleto.sql          (BD completa + seed data)" -ForegroundColor Gray
    Write-Host "  2. sql\migration_bidireccional_v1.sql       (si la BD ya existia)" -ForegroundColor Gray
    Write-Host "  3. sql\migration_interval_seconds.sql       (si la BD ya existia)" -ForegroundColor Gray
    Write-Host ""
}

##############################################################################
# MAIN
##############################################################################
switch ($Solo) {
    "Agentes" { Publicar-Agentes }
    "Api"     { Publicar-Api }
    "Web"     { Publicar-Web }
    "Todo"    { Publicar-Api; Publicar-Web }
}

Resumen
