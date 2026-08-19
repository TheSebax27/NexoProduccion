@echo off
:: Verificar si ya corre como Administrador
net session >nul 2>&1
if %errorLevel% == 0 goto :ejecutar

:: Si no, solicitar elevacion via UAC
echo Solicitando permisos de administrador...
powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
exit /b

:ejecutar
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Instalar-NexoSyncAgent.ps1"
