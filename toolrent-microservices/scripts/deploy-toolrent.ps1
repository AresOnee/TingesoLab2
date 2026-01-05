# ============================================================================
# TOOLRENT - SCRIPT COMPLETO DE DESPLIEGUE EN MINIKUBE (Windows PowerShell)
# ============================================================================
# Autor: ToolRent Team
# Descripcion: Despliega toda la aplicacion ToolRent en un cluster Minikube
# Uso: .\deploy-toolrent.ps1 [-SkipMinikubeStart] [-CleanDeploy]
# ============================================================================

param(
    [switch]$SkipMinikubeStart,    # Saltar inicio de Minikube si ya esta corriendo
    [switch]$CleanDeploy,          # Eliminar namespace existente antes de desplegar
    [switch]$SkipWait,             # No esperar a que los pods esten listos
    [int]$MinikubeMemory = 12288,  # Memoria para Minikube en MB (12GB)
    [int]$MinikubeCPUs = 6         # CPUs para Minikube
)

# ============================================================================
# CONFIGURACION
# ============================================================================
$NAMESPACE = "toolrent"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$K8S_DIR = Join-Path (Split-Path -Parent $SCRIPT_DIR) "k8s"

# Colores para output
function Write-Color {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "=" * 70 -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host "=" * 70 -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Step, [string]$Text)
    Write-Host "[$Step] $Text" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Text)
    Write-Host "  [OK] $Text" -ForegroundColor Green
}

function Write-Error {
    param([string]$Text)
    Write-Host "  [ERROR] $Text" -ForegroundColor Red
}

function Write-Info {
    param([string]$Text)
    Write-Host "  [INFO] $Text" -ForegroundColor Gray
}

# ============================================================================
# VERIFICACION DE PREREQUISITOS
# ============================================================================
Write-Header "TOOLRENT - DESPLIEGUE EN MINIKUBE"
Write-Host "Directorio K8s: $K8S_DIR" -ForegroundColor Gray
Write-Host "Namespace: $NAMESPACE" -ForegroundColor Gray
Write-Host ""

Write-Step "1/10" "Verificando prerequisitos..."

# Verificar kubectl
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Error "kubectl no esta instalado. Instalalo desde: https://kubernetes.io/docs/tasks/tools/"
    exit 1
}
Write-Success "kubectl encontrado"

# Verificar minikube
if (-not (Get-Command minikube -ErrorAction SilentlyContinue)) {
    Write-Error "minikube no esta instalado. Instalalo desde: https://minikube.sigs.k8s.io/docs/start/"
    exit 1
}
Write-Success "minikube encontrado"

# Verificar directorio K8s
if (-not (Test-Path $K8S_DIR)) {
    Write-Error "Directorio K8s no encontrado: $K8S_DIR"
    exit 1
}
Write-Success "Directorio K8s encontrado"

# ============================================================================
# INICIAR MINIKUBE
# ============================================================================
Write-Step "2/10" "Configurando Minikube..."

$minikubeStatus = minikube status --format='{{.Host}}' 2>$null
if ($minikubeStatus -ne "Running" -and -not $SkipMinikubeStart) {
    Write-Info "Iniciando Minikube con $MinikubeMemory MB RAM y $MinikubeCPUs CPUs..."
    Write-Info "Driver: hyperv (asegurate de ejecutar como Administrador)"

    minikube start --driver=hyperv --memory=$MinikubeMemory --cpus=$MinikubeCPUs

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Error al iniciar Minikube"
        Write-Info "Intenta: minikube start --driver=hyperv"
        exit 1
    }
    Write-Success "Minikube iniciado correctamente"
} else {
    Write-Success "Minikube ya esta corriendo"
}

# Obtener IP de Minikube
$MINIKUBE_IP = (minikube ip).Trim()
if ([string]::IsNullOrEmpty($MINIKUBE_IP)) {
    Write-Error "No se pudo obtener la IP de Minikube"
    exit 1
}
Write-Success "Minikube IP: $MINIKUBE_IP"

# ============================================================================
# LIMPIAR DESPLIEGUE ANTERIOR (OPCIONAL)
# ============================================================================
if ($CleanDeploy) {
    Write-Step "2.5/10" "Eliminando despliegue anterior..."
    kubectl delete namespace $NAMESPACE --ignore-not-found=true 2>$null
    Start-Sleep -Seconds 5
    Write-Success "Namespace eliminado"
}

# ============================================================================
# CREAR NAMESPACE
# ============================================================================
Write-Step "3/10" "Creando namespace..."

$namespaceYaml = @"
apiVersion: v1
kind: Namespace
metadata:
  name: $NAMESPACE
  labels:
    app: toolrent
"@

$namespaceYaml | kubectl apply -f - 2>$null
if ($LASTEXITCODE -ne 0) {
    kubectl create namespace $NAMESPACE 2>$null
}
Write-Success "Namespace '$NAMESPACE' creado/verificado"

# ============================================================================
# ACTUALIZAR CONFIGMAPS CON IP DE MINIKUBE
# ============================================================================
Write-Step "4/10" "Actualizando ConfigMaps con IP de Minikube..."

# Actualizar frontend-configmap.yaml
$frontendConfigPath = Join-Path $K8S_DIR "configmaps\frontend-configmap.yaml"
if (Test-Path $frontendConfigPath) {
    $content = Get-Content $frontendConfigPath -Raw
    $content = $content -replace 'MINIKUBE_IP_HERE', $MINIKUBE_IP
    $content = $content -replace 'http://\d+\.\d+\.\d+\.\d+:30090', "http://${MINIKUBE_IP}:30090"
    $content | Set-Content $frontendConfigPath -NoNewline
    Write-Success "frontend-configmap.yaml actualizado con IP: $MINIKUBE_IP"
}

# ============================================================================
# APLICAR SECRETS Y CONFIGMAPS
# ============================================================================
Write-Step "5/10" "Aplicando Secrets y ConfigMaps..."

# Secrets
$secretsPath = Join-Path $K8S_DIR "secrets"
if (Test-Path $secretsPath) {
    Get-ChildItem -Path $secretsPath -Filter "*.yaml" | ForEach-Object {
        kubectl apply -f $_.FullName -n $NAMESPACE 2>$null
        Write-Info "Aplicado: $($_.Name)"
    }
}

# ConfigMaps
$configmapsPath = Join-Path $K8S_DIR "configmaps"
if (Test-Path $configmapsPath) {
    Get-ChildItem -Path $configmapsPath -Filter "*.yaml" | ForEach-Object {
        kubectl apply -f $_.FullName -n $NAMESPACE 2>$null
        Write-Info "Aplicado: $($_.Name)"
    }
}

Write-Success "Secrets y ConfigMaps aplicados"

# ============================================================================
# DESPLEGAR BASES DE DATOS
# ============================================================================
Write-Step "6/10" "Desplegando bases de datos MySQL..."

$databasesPath = Join-Path $K8S_DIR "databases"
if (Test-Path $databasesPath) {
    Get-ChildItem -Path $databasesPath -Filter "*.yaml" | ForEach-Object {
        kubectl apply -f $_.FullName -n $NAMESPACE
        Write-Info "Desplegado: $($_.Name)"
    }
}

# Esperar a que las bases de datos esten listas
if (-not $SkipWait) {
    Write-Info "Esperando a que las bases de datos esten listas (60s)..."
    Start-Sleep -Seconds 30

    $databases = @("mysql-clients", "mysql-tools", "mysql-loans", "mysql-kardex", "mysql-config", "mysql-users")
    foreach ($db in $databases) {
        $ready = $false
        $attempts = 0
        while (-not $ready -and $attempts -lt 10) {
            $pod = kubectl get pods -n $NAMESPACE -l app=$db -o jsonpath='{.items[0].status.phase}' 2>$null
            if ($pod -eq "Running") {
                $ready = $true
                Write-Success "$db esta listo"
            } else {
                $attempts++
                Start-Sleep -Seconds 5
            }
        }
        if (-not $ready) {
            Write-Info "$db aun iniciando..."
        }
    }
}

Write-Success "Bases de datos desplegadas"

# ============================================================================
# DESPLEGAR INFRAESTRUCTURA
# ============================================================================
Write-Step "7/10" "Desplegando infraestructura (Config Server, Eureka, Keycloak)..."

$infraPath = Join-Path $K8S_DIR "infrastructure"

# Orden de despliegue de infraestructura
# IMPORTANTE: Config Server PRIMERO para que los microservicios puedan obtener su configuración
$infraOrder = @(
    "config-server.yaml",     # 1. Config Server - provee configuración centralizada
    "eureka-server.yaml",     # 2. Eureka - service discovery
    "keycloak.yaml",          # 3. Keycloak - autenticación
    "api-gateway.yaml",       # 4. API Gateway - punto de entrada
    "frontend-deployment.yaml" # 5. Frontend
)

foreach ($file in $infraOrder) {
    $filePath = Join-Path $infraPath $file
    if (Test-Path $filePath) {
        kubectl apply -f $filePath -n $NAMESPACE
        Write-Info "Desplegado: $file"
    }
}

# Esperar a que la infraestructura esté lista (en orden)
if (-not $SkipWait) {
    # 1. Esperar a Config Server PRIMERO (crítico para microservicios)
    Write-Info "Esperando a Config Server (puede tomar 1-2 minutos)..."
    $ready = $false
    $attempts = 0
    while (-not $ready -and $attempts -lt 24) {
        $status = kubectl get pods -n $NAMESPACE -l app=config-server -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>$null
        if ($status -eq "True") {
            $ready = $true
            Write-Success "Config Server esta listo"
        } else {
            $attempts++
            Write-Host "." -NoNewline
            Start-Sleep -Seconds 5
        }
    }
    Write-Host ""
    if (-not $ready) {
        Write-Error "Config Server no esta listo despues de 2 minutos"
        Write-Info "Los microservicios pueden fallar al iniciar sin Config Server"
    }

    # 2. Esperar a Eureka Server
    Write-Info "Esperando a Eureka Server (puede tomar 2-3 minutos)..."
    $ready = $false
    $attempts = 0
    while (-not $ready -and $attempts -lt 30) {
        $status = kubectl get pods -n $NAMESPACE -l app=eureka-server -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>$null
        if ($status -eq "True") {
            $ready = $true
            Write-Success "Eureka Server esta listo"
        } else {
            $attempts++
            Write-Host "." -NoNewline
            Start-Sleep -Seconds 10
        }
    }
    Write-Host ""

    # 3. Esperar a Keycloak
    Write-Info "Esperando a Keycloak..."
    $ready = $false
    $attempts = 0
    while (-not $ready -and $attempts -lt 30) {
        $status = kubectl get pods -n $NAMESPACE -l app=keycloak -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>$null
        if ($status -eq "True") {
            $ready = $true
            Write-Success "Keycloak esta listo"
        } else {
            $attempts++
            Write-Host "." -NoNewline
            Start-Sleep -Seconds 10
        }
    }
    Write-Host ""
}

Write-Success "Infraestructura desplegada"

# ============================================================================
# DESPLEGAR MICROSERVICIOS
# ============================================================================
Write-Step "8/10" "Desplegando microservicios..."

$microservicesPath = Join-Path $K8S_DIR "microservices"
if (Test-Path $microservicesPath) {
    Get-ChildItem -Path $microservicesPath -Filter "*.yaml" | ForEach-Object {
        kubectl apply -f $_.FullName -n $NAMESPACE
        Write-Info "Desplegado: $($_.Name)"
    }
}

# Esperar a que los microservicios esten listos
if (-not $SkipWait) {
    Write-Info "Esperando a que los microservicios esten listos..."
    Start-Sleep -Seconds 30

    $microservices = @("ms-clients", "ms-tools", "ms-loans", "ms-kardex", "ms-config", "ms-users", "ms-reports")
    foreach ($ms in $microservices) {
        $attempts = 0
        while ($attempts -lt 12) {
            $status = kubectl get pods -n $NAMESPACE -l app=$ms -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' 2>$null
            if ($status -eq "True") {
                Write-Success "$ms esta listo"
                break
            }
            $attempts++
            Start-Sleep -Seconds 10
        }
    }
}

Write-Success "Microservicios desplegados"

# ============================================================================
# VERIFICAR DESPLIEGUE
# ============================================================================
Write-Step "9/10" "Verificando despliegue..."

Write-Host ""
Write-Host "PODS:" -ForegroundColor White
kubectl get pods -n $NAMESPACE -o wide

Write-Host ""
Write-Host "SERVICES:" -ForegroundColor White
kubectl get services -n $NAMESPACE

# ============================================================================
# MOSTRAR URLs DE ACCESO
# ============================================================================
Write-Step "10/10" "Informacion de acceso..."

Write-Header "DESPLIEGUE COMPLETADO"

Write-Host ""
Write-Host "URLs DE ACCESO:" -ForegroundColor White
Write-Host "===============" -ForegroundColor White
Write-Host ""
Write-Host "  Frontend (ToolRent):     " -NoNewline -ForegroundColor Gray
Write-Host "http://${MINIKUBE_IP}:30000" -ForegroundColor Green
Write-Host ""
Write-Host "  API Gateway:             " -NoNewline -ForegroundColor Gray
Write-Host "http://${MINIKUBE_IP}:30080" -ForegroundColor Green
Write-Host ""
Write-Host "  Keycloak Admin Console:  " -NoNewline -ForegroundColor Gray
Write-Host "http://${MINIKUBE_IP}:30090" -ForegroundColor Green
Write-Host "    Usuario: admin" -ForegroundColor Gray
Write-Host "    Password: admin" -ForegroundColor Gray
Write-Host ""
Write-Host "  Eureka Dashboard:        " -NoNewline -ForegroundColor Gray
Write-Host "http://${MINIKUBE_IP}:30761" -ForegroundColor Green
Write-Host ""

Write-Host "USUARIOS DE PRUEBA (Keycloak):" -ForegroundColor White
Write-Host "==============================" -ForegroundColor White
Write-Host ""
Write-Host "  Administrador:" -ForegroundColor Yellow
Write-Host "    Usuario:  admin" -ForegroundColor Gray
Write-Host "    Password: admin123" -ForegroundColor Gray
Write-Host "    Roles:    ADMIN, USER" -ForegroundColor Gray
Write-Host ""
Write-Host "  Empleado:" -ForegroundColor Yellow
Write-Host "    Usuario:  juan" -ForegroundColor Gray
Write-Host "    Password: juan123" -ForegroundColor Gray
Write-Host "    Roles:    USER" -ForegroundColor Gray
Write-Host ""

Write-Host "COMANDOS UTILES:" -ForegroundColor White
Write-Host "================" -ForegroundColor White
Write-Host ""
Write-Host "  Ver logs de un pod:" -ForegroundColor Gray
Write-Host "    kubectl logs -f deployment/<nombre> -n $NAMESPACE" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Ver estado de pods:" -ForegroundColor Gray
Write-Host "    kubectl get pods -n $NAMESPACE" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Reiniciar un deployment:" -ForegroundColor Gray
Write-Host "    kubectl rollout restart deployment/<nombre> -n $NAMESPACE" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Eliminar todo:" -ForegroundColor Gray
Write-Host "    kubectl delete namespace $NAMESPACE" -ForegroundColor Cyan
Write-Host ""

# Guardar IP en archivo para referencia
$MINIKUBE_IP | Out-File -FilePath (Join-Path $SCRIPT_DIR "minikube-ip.txt") -NoNewline
Write-Info "IP de Minikube guardada en: minikube-ip.txt"

Write-Host ""
Write-Color "Despliegue completado exitosamente!" "Green"
Write-Host ""
