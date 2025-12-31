#!/bin/bash
# =====================================================
# SCRIPT: Export Keycloak Realm Configuration
# =====================================================
# Exporta la configuración completa del realm sisgr-realm
# incluyendo usuarios, roles, clients y configuraciones
# =====================================================

set -e

NAMESPACE="toolrent"
REALM_NAME="sisgr-realm"
OUTPUT_DIR="./keycloak-export"
CONFIGMAP_OUTPUT="../k8s/configmaps/keycloak-realm-configmap.yaml"

echo "=========================================="
echo "  Keycloak Realm Export Tool"
echo "=========================================="

# Verificar kubectl
if ! command -v kubectl &> /dev/null; then
    echo "ERROR: kubectl no está instalado"
    exit 1
fi

# Crear directorio de salida
mkdir -p "$OUTPUT_DIR"

# Obtener pod de Keycloak
echo "[1/5] Buscando pod de Keycloak..."
KEYCLOAK_POD=$(kubectl get pods -n $NAMESPACE -l app=keycloak -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$KEYCLOAK_POD" ]; then
    echo "ERROR: No se encontró el pod de Keycloak en namespace $NAMESPACE"
    exit 1
fi
echo "      Pod encontrado: $KEYCLOAK_POD"

# Exportar realm usando kc.sh export
echo "[2/5] Ejecutando export en el pod..."
kubectl exec -n $NAMESPACE $KEYCLOAK_POD -- /opt/keycloak/bin/kc.sh export \
    --dir /tmp/keycloak-export \
    --realm $REALM_NAME \
    --users realm_file 2>/dev/null || {
    echo "      Usando método alternativo (API REST)..."

    # Método alternativo: usar API REST
    MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "localhost")
    KEYCLOAK_PORT="30090"

    # Obtener token
    TOKEN=$(curl -s -X POST "http://$MINIKUBE_IP:$KEYCLOAK_PORT/realms/master/protocol/openid-connect/token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "username=admin" \
        -d "password=admin" \
        -d "grant_type=password" \
        -d "client_id=admin-cli" | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

    if [ -z "$TOKEN" ]; then
        echo "ERROR: No se pudo obtener token de admin"
        exit 1
    fi

    # Exportar realm
    curl -s -X GET "http://$MINIKUBE_IP:$KEYCLOAK_PORT/admin/realms/$REALM_NAME" \
        -H "Authorization: Bearer $TOKEN" > "$OUTPUT_DIR/$REALM_NAME-realm.json"

    # Exportar usuarios
    curl -s -X GET "http://$MINIKUBE_IP:$KEYCLOAK_PORT/admin/realms/$REALM_NAME/users?max=1000" \
        -H "Authorization: Bearer $TOKEN" > "$OUTPUT_DIR/$REALM_NAME-users.json"

    echo "      Exportado via API REST"
}

# Copiar archivo del pod
echo "[3/5] Copiando archivo exportado..."
kubectl cp $NAMESPACE/$KEYCLOAK_POD:/tmp/keycloak-export/$REALM_NAME-realm.json \
    $OUTPUT_DIR/$REALM_NAME-complete.json 2>/dev/null || true

# Verificar qué archivo tenemos
EXPORT_FILE=""
if [ -f "$OUTPUT_DIR/$REALM_NAME-complete.json" ]; then
    EXPORT_FILE="$OUTPUT_DIR/$REALM_NAME-complete.json"
elif [ -f "$OUTPUT_DIR/$REALM_NAME-realm.json" ]; then
    EXPORT_FILE="$OUTPUT_DIR/$REALM_NAME-realm.json"
fi

if [ -z "$EXPORT_FILE" ] || [ ! -s "$EXPORT_FILE" ]; then
    echo "ERROR: No se pudo exportar el realm"
    exit 1
fi

echo "      Archivo exportado: $EXPORT_FILE"

# Crear ConfigMap
echo "[4/5] Generando ConfigMap..."
cat > "$CONFIGMAP_OUTPUT" << 'HEADER'
# =====================================================
# KEYCLOAK REALM CONFIGMAP - AUTO-GENERATED
# =====================================================
# Generado automáticamente por export-keycloak-realm.sh
# Fecha: EXPORT_DATE
# =====================================================
apiVersion: v1
kind: ConfigMap
metadata:
  name: keycloak-realm
  namespace: toolrent
  labels:
    app: keycloak
data:
  sisgr-realm.json: |
HEADER

# Reemplazar fecha
sed -i "s/EXPORT_DATE/$(date '+%Y-%m-%d %H:%M:%S')/g" "$CONFIGMAP_OUTPUT"

# Agregar contenido del realm con indentación
sed 's/^/    /' "$EXPORT_FILE" >> "$CONFIGMAP_OUTPUT"

echo "      ConfigMap generado: $CONFIGMAP_OUTPUT"

# Mostrar resumen
echo "[5/5] Resumen de la exportación:"
echo "=========================================="
if command -v jq &> /dev/null; then
    echo "  Realm: $(jq -r '.realm // .id' $EXPORT_FILE)"
    echo "  Usuarios: $(jq '.users | length // 0' $EXPORT_FILE 2>/dev/null || echo 'N/A')"
    echo "  Clients: $(jq '.clients | length // 0' $EXPORT_FILE 2>/dev/null || echo 'N/A')"
    echo "  Roles: $(jq '.roles.realm | length // 0' $EXPORT_FILE 2>/dev/null || echo 'N/A')"
else
    echo "  (Instala jq para ver detalles)"
fi
echo "=========================================="
echo ""
echo "Archivos generados:"
echo "  - $EXPORT_FILE (realm completo)"
echo "  - $CONFIGMAP_OUTPUT (ConfigMap K8s)"
echo ""
echo "Para aplicar los cambios:"
echo "  kubectl apply -f $CONFIGMAP_OUTPUT"
echo "  kubectl rollout restart deployment/keycloak -n toolrent"
echo ""
echo "IMPORTANTE: Verifica que los usuarios tengan las"
echo "contraseñas correctas antes de aplicar."
