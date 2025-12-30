#!/bin/bash
# ============================================
# TOOLRENT KUBERNETES DEPLOYMENT SCRIPT
# ============================================
# Despliega todos los componentes en el orden correcto

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KEYCLOAK_REALM_FILE="$SCRIPT_DIR/../../keycloak-config/realm-export.json"

echo "============================================"
echo "     TOOLRENT K8s DEPLOYMENT"
echo "============================================"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

wait_for_pod() {
    local label=$1
    local timeout=${2:-120}
    log_info "Esperando pod con label app=$label..."
    kubectl wait --for=condition=ready pod -l app=$label -n toolrent --timeout=${timeout}s 2>/dev/null || {
        log_warn "Timeout esperando $label, continuando..."
    }
}

# 1. Namespace
log_info "1/7 Creando namespace..."
kubectl apply -f "$SCRIPT_DIR/00-namespace.yaml" 2>/dev/null || kubectl apply -f "$SCRIPT_DIR/namespace.yaml"

# 2. Secrets
log_info "2/7 Aplicando secrets..."
kubectl apply -f "$SCRIPT_DIR/secrets/"

# 3. ConfigMaps
log_info "3/7 Aplicando ConfigMaps..."
kubectl apply -f "$SCRIPT_DIR/configmaps/app-config.yaml" 2>/dev/null || true
kubectl apply -f "$SCRIPT_DIR/configmaps/api-gateway-config.yaml"
kubectl apply -f "$SCRIPT_DIR/configmaps/frontend-configmap.yaml"

# 3.1 Generar ConfigMap de Keycloak Realm desde el archivo JSON
log_info "3.1/7 Generando ConfigMap de Keycloak Realm..."
if [ -f "$KEYCLOAK_REALM_FILE" ]; then
    kubectl create configmap keycloak-realm \
        --from-file=sisgr-realm.json="$KEYCLOAK_REALM_FILE" \
        --namespace=toolrent \
        --dry-run=client -o yaml | kubectl apply -f -
    log_info "ConfigMap keycloak-realm creado correctamente"
else
    log_error "Archivo realm no encontrado: $KEYCLOAK_REALM_FILE"
    exit 1
fi

# 4. Databases
log_info "4/7 Desplegando bases de datos..."
kubectl apply -f "$SCRIPT_DIR/databases/"
log_info "Esperando que las bases de datos esten listas..."
sleep 10

# 5. Keycloak
log_info "5/7 Desplegando Keycloak..."
kubectl apply -f "$SCRIPT_DIR/infrastructure/keycloak.yaml"
wait_for_pod "keycloak" 180

# 6. Infrastructure (API Gateway - sin Eureka en K8s)
log_info "6/7 Desplegando API Gateway..."
kubectl apply -f "$SCRIPT_DIR/infrastructure/api-gateway.yaml"
wait_for_pod "api-gateway" 120

# 7. Microservices
log_info "7/7 Desplegando microservicios..."
kubectl apply -f "$SCRIPT_DIR/microservices/"

# 8. Frontend
log_info "8/7 Desplegando Frontend..."
kubectl apply -f "$SCRIPT_DIR/infrastructure/frontend-deployment.yaml"

echo ""
echo "============================================"
echo "     DEPLOYMENT COMPLETADO"
echo "============================================"
echo ""

# Obtener Minikube IP para mostrar URLs
MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "localhost")

echo "URLs de acceso:"
echo "  - Frontend:     http://$MINIKUBE_IP:30000"
echo "  - API Gateway:  http://$MINIKUBE_IP:30080"
echo "  - Keycloak:     http://$MINIKUBE_IP:30090"
echo ""
echo "Para ver el estado de los pods:"
echo "  kubectl get pods -n toolrent"
echo ""
echo "IMPORTANTE: Actualiza el ConfigMap frontend-config con la IP de Minikube:"
echo "  kubectl edit configmap frontend-config -n toolrent"
echo "  Cambiar MINIKUBE_IP_HERE por: $MINIKUBE_IP"
