# ============================================================================
# TOOLRENT - SCRIPT PARA CARGAR DATOS DE PRUEBA (SEEDS)
# ============================================================================
# Uso: .\load-seeds.ps1
# Este script carga los datos de prueba en las bases de datos MySQL
# Usa kubectl cp para preservar la codificacion UTF-8 (tildes, etc.)
# ============================================================================

$NAMESPACE = "toolrent"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_DIR = Split-Path -Parent $SCRIPT_DIR
$SEED_DIR = Join-Path $PROJECT_DIR "seed-data"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  CARGA DE DATOS DE PRUEBA (SEEDS)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Directorio de seeds: $SEED_DIR" -ForegroundColor Gray
Write-Host ""

# Verificar que existe el directorio
if (-not (Test-Path $SEED_DIR)) {
    Write-Host "[ERROR] Directorio de seeds no encontrado: $SEED_DIR" -ForegroundColor Red
    exit 1
}

# Definir los seeds a cargar
$seeds = @(
    @{file="01-tools-seed.sql"; label="mysql-tools"; database="tools_db"; name="Herramientas"},
    @{file="02-clients-seed.sql"; label="mysql-clients"; database="clients_db"; name="Clientes"},
    @{file="03-config-seed.sql"; label="mysql-config"; database="config_db"; name="Configuracion"},
    @{file="04-loans-seed.sql"; label="mysql-loans"; database="loans_db"; name="Prestamos"},
    @{file="05-kardex-seed.sql"; label="mysql-kardex"; database="kardex_db"; name="Kardex"}
)

$successCount = 0
$errorCount = 0

foreach ($seed in $seeds) {
    $seedFile = Join-Path $SEED_DIR $seed.file

    Write-Host "----------------------------------------" -ForegroundColor Gray
    Write-Host "Procesando: $($seed.name)" -ForegroundColor Yellow
    Write-Host "  Archivo: $($seed.file)" -ForegroundColor Gray
    Write-Host "  Base de datos: $($seed.database)" -ForegroundColor Gray

    # Verificar que existe el archivo
    if (-not (Test-Path $seedFile)) {
        Write-Host "  [ERROR] Archivo no encontrado: $seedFile" -ForegroundColor Red
        $errorCount++
        continue
    }
    Write-Host "  [OK] Archivo encontrado" -ForegroundColor Green

    # Obtener el nombre del pod
    Write-Host "  Buscando pod..." -ForegroundColor Gray
    $podName = kubectl get pods -n $NAMESPACE -l app=$($seed.label) -o jsonpath='{.items[0].metadata.name}' 2>$null

    if ([string]::IsNullOrEmpty($podName)) {
        Write-Host "  [ERROR] Pod no encontrado para: $($seed.label)" -ForegroundColor Red
        $errorCount++
        continue
    }
    Write-Host "  [OK] Pod encontrado: $podName" -ForegroundColor Green

    # Verificar que el pod esta Running
    $podStatus = kubectl get pod $podName -n $NAMESPACE -o jsonpath='{.status.phase}' 2>$null
    if ($podStatus -ne "Running") {
        Write-Host "  [ERROR] Pod no esta Running (estado: $podStatus)" -ForegroundColor Red
        $errorCount++
        continue
    }
    Write-Host "  [OK] Pod esta Running" -ForegroundColor Green

    # Copiar archivo al pod (preserva UTF-8)
    Write-Host "  Copiando archivo al pod..." -ForegroundColor Gray
    kubectl cp $seedFile "${NAMESPACE}/${podName}:/tmp/seed.sql" 2>$null

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [ERROR] Error al copiar archivo al pod" -ForegroundColor Red
        $errorCount++
        continue
    }
    Write-Host "  [OK] Archivo copiado a /tmp/seed.sql" -ForegroundColor Green

    # Ejecutar el seed
    Write-Host "  Ejecutando seed en MySQL..." -ForegroundColor Gray
    $result = kubectl exec $podName -n $NAMESPACE -- mysql -u toolrent -ptoolrent123 --default-character-set=utf8mb4 $($seed.database) -e "source /tmp/seed.sql" 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] Seed cargado correctamente!" -ForegroundColor Green
        $successCount++
    } else {
        # Verificar si es solo un warning o un error real
        if ($result -match "ERROR") {
            Write-Host "  [ERROR] Error al ejecutar seed: $result" -ForegroundColor Red
            $errorCount++
        } else {
            Write-Host "  [OK] Seed cargado (con warnings)" -ForegroundColor Yellow
            $successCount++
        }
    }

    # Limpiar archivo temporal
    kubectl exec $podName -n $NAMESPACE -- rm -f /tmp/seed.sql 2>$null
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  RESUMEN" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Seeds exitosos: $successCount" -ForegroundColor Green
Write-Host "  Seeds fallidos: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($errorCount -eq 0) {
    Write-Host "Todos los seeds se cargaron correctamente!" -ForegroundColor Green
} else {
    Write-Host "Algunos seeds fallaron. Revisa los errores arriba." -ForegroundColor Yellow
}

Write-Host ""
