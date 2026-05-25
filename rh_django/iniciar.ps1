# Powershell Script for Django Auto-Start and Self-Healing
$ErrorActionPreference = "Stop"

# Clear console for premium experience
Clear-Host

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "   >>> CONTROL DE PERSONAL & RECURSOS HUMANOS <<<   " -ForegroundColor Cyan -BackgroundColor DarkBlue
Write-Host "         SISTEMA DE EJECUCION AUTOMATICA         " -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Verificar si estamos en el directorio correcto y navegar
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ($null -eq $ScriptDir -or $ScriptDir -eq "") {
    $ScriptDir = Get-Location
}
$DjangoDir = Join-Path $ScriptDir "rh_django"

if (Test-Path $DjangoDir) {
    Set-Location $DjangoDir
    Write-Host "[DIR] Directorio del proyecto: $DjangoDir" -ForegroundColor Gray
} else {
    # Si ya estamos dentro de la carpeta rh_django
    $ParentDirName = Split-Path $ScriptDir -Leaf
    if ($ParentDirName -eq "rh_django" -and (Test-Path (Join-Path $ScriptDir "manage.py"))) {
        $DjangoDir = $ScriptDir
        Write-Host "[DIR] Directorio del proyecto: $DjangoDir" -ForegroundColor Gray
    } else {
        Write-Host "[ERROR] No se encontro la carpeta 'rh_django' en $ScriptDir" -ForegroundColor Red
        Read-Host "Presiona Enter para salir..."
        Exit 1
    }
}

# 2. Verificar Python en el sistema
Write-Host "[CHECK] Verificando Python en el sistema..." -ForegroundColor Green
$PythonInstalled = $false
try {
    # Intentar ejecutar python --version
    $SysPythonVer = & python --version 2>&1
    if ($SysPythonVer -match "Python") {
        Write-Host "[OK] Python de sistema detectado: $SysPythonVer" -ForegroundColor Green
        $PythonInstalled = $true
    }
} catch {
    # No hace nada
}

# Si no se detecto python directamente, buscar en las rutas por defecto de Windows
if (-not $PythonInstalled) {
    $CommonPaths = @(
        "$env:LocalAppData\Programs\Python\Python312\python.exe",
        "$env:LocalAppData\Programs\Python\Python311\python.exe",
        "$env:LocalAppData\Programs\Python\Python310\python.exe",
        "C:\Python312\python.exe",
        "C:\Python311\python.exe",
        "C:\Python310\python.exe"
    )
    foreach ($Path in $CommonPaths) {
        if (Test-Path $Path) {
            $SysPythonVer = & $Path --version 2>&1
            Write-Host "[OK] Python detectado en ruta especifica: $Path ($SysPythonVer)" -ForegroundColor Green
            # Anadir temporalmente al PATH para que venv use este ejecutable
            $env:Path = "$(Split-Path $Path);$env:Path"
            $PythonInstalled = $true
            break
        }
    }
}

if (-not $PythonInstalled) {
    Write-Host "[ALERTA] Python no esta en el PATH del sistema o no esta instalado." -ForegroundColor Yellow
    Write-Host "Intentando instalar Python automaticamente usando winget..." -ForegroundColor Yellow
    try {
        & winget install Python.Python.3.12 --accept-source-agreements --accept-package-agreements
        Write-Host "[INFO] Python 3.12 instalado con exito mediante winget." -ForegroundColor Green
        Write-Host "Por favor, cierra esta ventana y vuelve a ejecutar 'iniciar.bat' para actualizar las rutas." -ForegroundColor Green
        Read-Host "Presiona Enter para salir..."
        Exit 0
    } catch {
        Write-Host "[ERROR] No se pudo instalar Python automaticamente." -ForegroundColor Red
        Write-Host "Por favor instala Python 3.12 manualmente desde https://www.python.org/ e intentalo de nuevo." -ForegroundColor Red
        Read-Host "Presiona Enter para salir..."
        Exit 1
    }
}

# 3. Verificar Entorno Virtual (venv)
$VenvDir = Join-Path $DjangoDir "venv"
$RecreateVenv = $false

if (Test-Path $VenvDir) {
    Write-Host "[CHECK] Verificando estado del entorno virtual (venv)..." -ForegroundColor Green
    try {
        $VenvPython = Join-Path $VenvDir "Scripts\python.exe"
        if (-not (Test-Path $VenvPython)) {
            $RecreateVenv = $true
        } else {
            # Probar si el ejecutable de python funciona realmente
            $TestResult = & $VenvPython -c "print('ok')" 2>&1
            if ($TestResult -ne "ok") {
                $RecreateVenv = $true
            }
        }
    } catch {
        $RecreateVenv = $true
    }
} else {
    $RecreateVenv = $true
}

if ($RecreateVenv) {
    Write-Host "[ALERTA] El entorno virtual no existe, esta roto o pertenece a otra computadora/usuario." -ForegroundColor Yellow
    Write-Host "[🛠️] Recreando entorno virtual localmente (esto tomara unos segundos)..." -ForegroundColor Yellow
    
    # Intentar eliminar la carpeta de forma segura
    if (Test-Path $VenvDir) {
        try {
            Remove-Item -Recurse -Force $VenvDir -ErrorAction Stop
        } catch {
            Write-Host "[ALERTA] No se pudo eliminar la carpeta venv de forma automatica. Intentando renombrarla..." -ForegroundColor Yellow
            $RandomName = "venv_old_" + (Get-Random)
            Rename-Item -Path $VenvDir -NewName $RandomName -ErrorAction SilentlyContinue
        }
    }
    
    try {
        & python -m venv venv
        Write-Host "[OK] Nuevo entorno virtual creado exitosamente para este equipo." -ForegroundColor Green
    } catch {
        # Si fallo, intentar buscar el ejecutable exacto
        Write-Host "Intentando crear entorno usando ejecutable directo..." -ForegroundColor Yellow
        & python.exe -m venv venv
        Write-Host "[OK] Nuevo entorno virtual creado exitosamente para este equipo." -ForegroundColor Green
    }
} else {
    Write-Host "[OK] Entorno virtual local verificado y listo." -ForegroundColor Green
}

# 4. Activar Entorno Virtual e Instalar Dependencias
$VenvPython = Join-Path $VenvDir "Scripts\python.exe"
$VenvPip = Join-Path $VenvDir "Scripts\pip.exe"

Write-Host "[DEP] Verificando e instalando dependencias requeridas..." -ForegroundColor Green

# Instalar/actualizar todo
try {
    Write-Host "Ejecutando instalacion/actualizacion de paquetes necesarios..." -ForegroundColor Cyan
    & $VenvPython -m pip install --upgrade pip
    & $VenvPython -m pip install django pymysql djangorestframework django-cors-headers cryptography
    Write-Host "[OK] Todas las dependencias instaladas y actualizadas correctamente." -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Error instalando dependencias mediante pip." -ForegroundColor Red
    Read-Host "Presiona Enter para salir..."
    Exit 1
}

# 5. Ejecutar Migraciones de Base de Datos
Write-Host "[DB] Verificando e ingresando migraciones de la base de datos..." -ForegroundColor Green
try {
    & $VenvPython manage.py makemigrations
    & $VenvPython manage.py migrate
    Write-Host "[OK] Base de datos al dia." -ForegroundColor Green
} catch {
    Write-Host ""
    Write-Host "[ALERTA] Nota: No se pudo conectar a la base de datos MySQL (rh_db)." -ForegroundColor Yellow
    Write-Host "Si aun no tienes MySQL corriendo o no has creado la base de datos 'rh_db'," -ForegroundColor Yellow
    Write-Host "por favor crea la base de datos 'rh_db' en tu MySQL local con el usuario 'root' y contrasena 'Dante'." -ForegroundColor Yellow
    Write-Host "El servidor se iniciara de todos modos en modo de desarrollo..." -ForegroundColor Yellow
    Write-Host ""
}

# 6. Levantar Servidor Django
Write-Host "==================================================" -ForegroundColor Green
Write-Host "  [LISTO] ¡TODO LISTO! Iniciando servidor..." -ForegroundColor Green
Write-Host "  [PC] Accesible localmente en: http://localhost:8000/" -ForegroundColor Green
Write-Host "  [RED] Accesible desde otros dispositivos de tu red local." -ForegroundColor Green
Write-Host "  [TIP] Presiona CTRL + C para detener el servidor." -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Green
Write-Host ""

& $VenvPython manage.py runserver 0.0.0.0:8000
