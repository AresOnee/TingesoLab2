#!/bin/bash
# ============================================
# TOOLRENT KUBERNETES CLEANUP SCRIPT
# ============================================
# Elimina todos los recursos de ToolRent

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "============================================"
echo "     TOOLRENT K8s CLEANUP"
echo "============================================"
echo ""
read -p "Esto eliminara todos los recursos de ToolRent. Continuar? (y/N): " confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Operacion cancelada."
    exit 0
fi

echo ""
echo "Eliminando recursos..."

# Eliminar en orden inverso
kubectl delete -f "$SCRIPT_DIR/infrastructure/frontend-deployment.yaml" --ignore-not-found
kubectl delete -f "$SCRIPT_DIR/microservices/" --ignore-not-found
kubectl delete -f "$SCRIPT_DIR/infrastructure/api-gateway.yaml" --ignore-not-found
kubectl delete -f "$SCRIPT_DIR/infrastructure/keycloak.yaml" --ignore-not-found
kubectl delete -f "$SCRIPT_DIR/databases/" --ignore-not-found
kubectl delete configmap keycloak-realm -n toolrent --ignore-not-found
kubectl delete -f "$SCRIPT_DIR/configmaps/" --ignore-not-found
kubectl delete -f "$SCRIPT_DIR/secrets/" --ignore-not-found

echo ""
read -p "Eliminar el namespace toolrent completamente? (y/N): " confirm_ns

if [[ "$confirm_ns" == "y" || "$confirm_ns" == "Y" ]]; then
    kubectl delete namespace toolrent --ignore-not-found
    echo "Namespace eliminado."
else
    echo "Namespace conservado."
fi

echo ""
echo "Cleanup completado."
