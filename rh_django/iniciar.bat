@echo off
TITLE Sistema de Recursos Humanos - Inicio Rapido
echo ==================================================
echo   🚀 INICIANDO CONFIGURACION Y EJECUCION PORTABLE
echo ==================================================
echo.

:: Detectar ruta del script
set SCRIPT_DIR=%~dp0

:: Ejecutar PowerShell saltándose las políticas de restricción
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%iniciar.ps1"

if %errorlevel% neq 0 (
    echo.
    echo ❌ Ocurrio un error al ejecutar el script de inicio.
    pause
)
