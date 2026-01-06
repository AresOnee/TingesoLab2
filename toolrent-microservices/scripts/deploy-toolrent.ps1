# ============================================================================
# TOOLRENT - SCRIPT COMPLETO DE DESPLIEGUE EN MINIKUBE (Windows PowerShell)
# ============================================================================
# Autor: ToolRent Team
# Descripcion: Compila, construye imagenes Docker y despliega en Minikube
# Uso: .\deploy-toolrent.ps1 [-SkipBuild] [-SkipMinikubeStart] [-CleanDeploy]
# ============================================================================

param(
    [switch]$SkipBuild,            # Saltar compilacion y construccion de imagenes
    [switch]$SkipMinikubeStart,    # Saltar inicio de Minikube si ya esta corriendo
    [switch]$CleanDeploy,          # Eliminar namespace existente antes de desplegar
    [switch]$SkipWait,             # No esperar a que los pods esten listos
    [switch]$SkipSeed,             # Saltar carga de datos de prueba (seed)
    [int]$MinikubeMemory = 12288,  # Memoria para Minikube en MB (12GB)
    [int]$MinikubeCPUs = 6,        # CPUs para Minikube
    [string]$DockerUser = "fergusone"  # Usuario de Docker Hub
)

# ============================================================================
# CONFIGURACION
# ============================================================================
$NAMESPACE = "toolrent"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_DIR = Split-Path -Parent $SCRIPT_DIR
$K8S_DIR = Join-Path $PROJECT_DIR "k8s"
$SEED_DIR = Join-Path $PROJECT_DIR "seed-data"

# Lista de proyectos a compilar y construir
$INFRA_PROJECTS = @("config-server", "eureka-server", "api-gateway")
$MS_PROJECTS = @("ms-tools", "ms-clients", "ms-config", "ms-loans", "ms-kardex", "ms-reports")

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
Write-Host "Directorio proyecto: $PROJECT_DIR" -ForegroundColor Gray
Write-Host "Directorio K8s: $K8S_DIR" -ForegroundColor Gray
Write-Host "Namespace: $NAMESPACE" -ForegroundColor Gray
Write-Host "Docker User: $DockerUser" -ForegroundColor Gray
Write-Host "Skip Build: $SkipBuild" -ForegroundColor Gray
Write-Host "Skip Seed: $SkipSeed" -ForegroundColor Gray
Write-Host ""

Write-Step "1/13" "Verificando prerequisitos..."

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

# Verificar Maven (solo si no se salta el build)
if (-not $SkipBuild) {
    if (-not (Get-Command mvn -ErrorAction SilentlyContinue)) {
        Write-Error "Maven no esta instalado. Instalalo desde: https://maven.apache.org/download.cgi"
        exit 1
    }
    Write-Success "Maven encontrado"

    # Verificar Docker
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Error "Docker no esta instalado. Instalalo desde: https://www.docker.com/products/docker-desktop"
        exit 1
    }
    Write-Success "Docker encontrado"
}

# Verificar directorio K8s
if (-not (Test-Path $K8S_DIR)) {
    Write-Error "Directorio K8s no encontrado: $K8S_DIR"
    exit 1
}
Write-Success "Directorio K8s encontrado"

# Verificar directorio del proyecto
if (-not (Test-Path $PROJECT_DIR)) {
    Write-Error "Directorio del proyecto no encontrado: $PROJECT_DIR"
    exit 1
}
Write-Success "Directorio del proyecto encontrado"

# ============================================================================
# COMPILAR PROYECTOS CON MAVEN
# ============================================================================
if (-not $SkipBuild) {
    Write-Step "2/13" "Compilando proyectos con Maven..."

    $allProjects = $INFRA_PROJECTS + $MS_PROJECTS
    $totalProjects = $allProjects.Count
    $currentProject = 0

    foreach ($project in $allProjects) {
        $currentProject++
        $projectPath = Join-Path $PROJECT_DIR $project

        if (Test-Path $projectPath) {
            Write-Info "[$currentProject/$totalProjects] Compilando $project..."

            Push-Location $projectPath
            $result = mvn clean package -DskipTests -q 2>&1
            $exitCode = $LASTEXITCODE
            Pop-Location

            if ($exitCode -ne 0) {
                Write-Error "Error compilando $project"
                Write-Host $result -ForegroundColor Red
                exit 1
            }
            Write-Success "$project compilado"
        } else {
            Write-Error "Proyecto no encontrado: $projectPath"
            exit 1
        }
    }

    Write-Success "Todos los proyectos compilados exitosamente"

    # ============================================================================
    # CONSTRUIR IMAGENES DOCKER
    # ============================================================================
    Write-Step "3/13" "Construyendo imagenes Docker..."

    $currentProject = 0
    foreach ($project in $allProjects) {
        $currentProject++
        $projectPath = Join-Path $PROJECT_DIR $project
        $imageName = "$DockerUser/${project}:1.0.0"

        Write-Info "[$currentProject/$totalProjects] Construyendo imagen $imageName..."

        Push-Location $projectPath
        docker build -t $imageName -q . 2>&1 | Out-Null
        $exitCode = $LASTEXITCODE
        Pop-Location

        if ($exitCode -ne 0) {
            Write-Error "Error construyendo imagen para $project"
            exit 1
        }
        Write-Success "Imagen $imageName construida"
    }

    Write-Success "Todas las imagenes Docker construidas"

    # ============================================================================
    # SUBIR IMAGENES A DOCKER HUB
    # ============================================================================
    Write-Step "4/13" "Subiendo imagenes a Docker Hub..."
    Write-Info "Asegurate de haber ejecutado 'docker login' previamente"

    $currentProject = 0
    foreach ($project in $allProjects) {
        $currentProject++
        $imageName = "$DockerUser/${project}:1.0.0"

        Write-Info "[$currentProject/$totalProjects] Subiendo $imageName..."

        docker push $imageName 2>&1 | Out-Null
        $exitCode = $LASTEXITCODE

        if ($exitCode -ne 0) {
            Write-Error "Error subiendo imagen $imageName"
            Write-Info "Ejecuta 'docker login' e intenta de nuevo"
            exit 1
        }
        Write-Success "$imageName subida"
    }

    Write-Success "Todas las imagenes subidas a Docker Hub"
} else {
    Write-Step "2-4/13" "Saltando compilacion y construccion de imagenes (SkipBuild activado)"
}

# ============================================================================
# INICIAR MINIKUBE
# ============================================================================
Write-Step "5/13" "Configurando Minikube..."

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
    Write-Step "5.5/13" "Eliminando despliegue anterior..."
    kubectl delete namespace $NAMESPACE --ignore-not-found=true 2>$null
    Start-Sleep -Seconds 5
    Write-Success "Namespace eliminado"
}

# ============================================================================
# CREAR NAMESPACE
# ============================================================================
Write-Step "6/13" "Creando namespace..."

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
Write-Step "7/13" "Actualizando ConfigMaps con IP de Minikube..."

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
Write-Step "8/13" "Aplicando Secrets y ConfigMaps..."

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
Write-Step "9/13" "Desplegando bases de datos MySQL..."

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

    $databases = @("mysql-clients", "mysql-tools", "mysql-loans", "mysql-kardex", "mysql-config")
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
# CARGAR DATOS DE PRUEBA (SEED)
# ============================================================================
if (-not $SkipSeed) {
    Write-Step "10/13" "Cargando datos de prueba (seed) en las bases de datos..."

    # Verificar que existe el directorio de seeds
    if (Test-Path $SEED_DIR) {
        # Esperar un poco mas para asegurar que MySQL esta completamente listo
        Write-Info "Esperando 15 segundos adicionales para que MySQL este completamente listo..."
        Start-Sleep -Seconds 15

        # Definir los seeds a cargar (archivo, deployment, base de datos)
        $seeds = @(
            @{file="01-tools-seed.sql"; deployment="mysql-tools"; database="tools_db"},
            @{file="02-clients-seed.sql"; deployment="mysql-clients"; database="clients_db"},
            @{file="03-config-seed.sql"; deployment="mysql-config"; database="config_db"},
            @{file="04-loans-seed.sql"; deployment="mysql-loans"; database="loans_db"},
            @{file="05-kardex-seed.sql"; deployment="mysql-kardex"; database="kardex_db"}
        )

        foreach ($seed in $seeds) {
            $seedFile = Join-Path $SEED_DIR $seed.file
            if (Test-Path $seedFile) {
                Write-Info "Cargando $($seed.file) en $($seed.database)..."

                # Obtener el nombre del pod
                $podName = kubectl get pods -n $NAMESPACE -l app=$($seed.deployment) -o jsonpath='{.items[0].metadata.name}' 2>$null

                if ($podName) {
                    # Copiar archivo al pod (preserva encoding UTF-8)
                    kubectl cp $seedFile "${NAMESPACE}/${podName}:/tmp/seed.sql" 2>$null

                    # Ejecutar el seed con charset utf8mb4
                    $result = kubectl exec -i "deployment/$($seed.deployment)" -n $NAMESPACE -- mysql -u toolrent -ptoolrent123 --default-character-set=utf8mb4 $($seed.database) -e "source /tmp/seed.sql" 2>&1

                    if ($LASTEXITCODE -eq 0) {
                        Write-Success "$($seed.file) cargado correctamente"
                    } else {
                        Write-Info "Advertencia al cargar $($seed.file): puede que ya existan datos"
                    }
                } else {
                    Write-Info "Pod $($seed.deployment) no encontrado, saltando seed"
                }
            } else {
                Write-Info "Archivo $($seed.file) no encontrado, saltando"
            }
        }

        Write-Success "Datos de prueba cargados"
    } else {
        Write-Info "Directorio de seeds no encontrado: $SEED_DIR"
        Write-Info "Saltando carga de datos de prueba"
    }
} else {
    Write-Step "10/13" "Saltando carga de datos de prueba (SkipSeed activado)"
}

# ============================================================================
# DESPLEGAR INFRAESTRUCTURA
# ============================================================================
Write-Step "11/13" "Desplegando infraestructura (Config Server, Eureka, Keycloak)..."

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
Write-Step "12/13" "Desplegando microservicios..."

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

    $microservices = @("ms-clients", "ms-tools", "ms-loans", "ms-kardex", "ms-config", "ms-reports")
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
Write-Step "13/13" "Verificando despliegue y mostrando informacion..."

Write-Host ""
Write-Host "PODS:" -ForegroundColor White
kubectl get pods -n $NAMESPACE -o wide

Write-Host ""
Write-Host "SERVICES:" -ForegroundColor White
kubectl get services -n $NAMESPACE

# ============================================================================
# MOSTRAR URLs DE ACCESO
# ============================================================================
# Informacion de acceso (parte del paso 12)

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
