#!/bin/sh
# ============================================
# DOCKER ENTRYPOINT - RUNTIME ENV INJECTION
# Reemplaza placeholders en env.js con valores reales
# ============================================

set -e

# Archivo de configuración
ENV_FILE=/usr/share/nginx/html/env.js

# Valores por defecto
KEYCLOAK_URL=${KEYCLOAK_URL:-http://localhost:9090}
KEYCLOAK_REALM=${KEYCLOAK_REALM:-sisgr-realm}
KEYCLOAK_CLIENT_ID=${KEYCLOAK_CLIENT_ID:-sisgr-frontend}

echo "Configurando frontend con:"
echo "  KEYCLOAK_URL: $KEYCLOAK_URL"
echo "  KEYCLOAK_REALM: $KEYCLOAK_REALM"
echo "  KEYCLOAK_CLIENT_ID: $KEYCLOAK_CLIENT_ID"

# Reemplazar placeholders
sed -i "s|__KEYCLOAK_URL__|${KEYCLOAK_URL}|g" $ENV_FILE
sed -i "s|__KEYCLOAK_REALM__|${KEYCLOAK_REALM}|g" $ENV_FILE
sed -i "s|__KEYCLOAK_CLIENT_ID__|${KEYCLOAK_CLIENT_ID}|g" $ENV_FILE

echo "Configuración completada. Contenido de env.js:"
cat $ENV_FILE

# Iniciar nginx
exec nginx -g 'daemon off;'
