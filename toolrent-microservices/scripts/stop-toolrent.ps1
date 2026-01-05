# ============================================================================
# TOOLRENT - SCRIPT PARA DETENER/LIMPIAR DESPLIEGUE (Windows PowerShell)
# ============================================================================
# Uso: .\stop-toolrent.ps1 [-DeleteNamespace] [-StopMinikube]
# ============================================================================

param(
    [switch]$DeleteNamespace,    # Eliminar namespace completo
    [switch]$StopMinikube,       # Detener Minikube tambien
    [switch]$DeleteAll           # Eliminar todo (namespace + detener minikube)
)

$NAMESPACE = "toolrent"

function Write-Color {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host "=" * 60 -ForegroundColor Cyan
}

Write-Header "TOOLRENT - DETENIENDO SERVICIOS"

# Verificar que Minikube esta corriendo
$minikubeStatus = minikube status --format='{{.Host}}' 2>$null
if ($minikubeStatus -ne "Running") {
    Write-Color "Minikube no esta corriendo" "Yellow"
    exit 0
}

if ($DeleteAll) {
    $DeleteNamespace = $true
    $StopMinikube = $true
}

if ($DeleteNamespace) {
    Write-Color "Eliminando namespace '$NAMESPACE' y todos sus recursos..." "Yellow"
    kubectl delete namespace $NAMESPACE --ignore-not-found=true
    Write-Color "Namespace eliminado" "Green"
} else {
    # Solo escalar a 0 replicas
    Write-Color "Escalando deployments a 0 replicas..." "Yellow"

    $deployments = kubectl get deployments -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}' 2>$null
    if ($deployments) {
        foreach ($deployment in $deployments.Split(" ")) {
            if ($deployment) {
                kubectl scale deployment/$deployment --replicas=0 -n $NAMESPACE 2>$null
                Write-Host "  Detenido: $deployment" -ForegroundColor Gray
            }
        }
    }
    Write-Color "Deployments detenidos (replicas=0)" "Green"
    Write-Host ""
    Write-Color "Para reiniciar, escala los deployments a 1:" "Gray"
    Write-Host "  kubectl scale deployment --all --replicas=1 -n $NAMESPACE" -ForegroundColor Cyan
}

if ($StopMinikube) {
    Write-Host ""
    Write-Color "Deteniendo Minikube..." "Yellow"
    minikube stop
    Write-Color "Minikube detenido" "Green"
}

Write-Host ""
Write-Color "Operacion completada" "Green"
Write-Host ""

# Mostrar estado final
if (-not $StopMinikube) {
    Write-Color "Estado actual de pods:" "White"
    kubectl get pods -n $NAMESPACE 2>$null
}
