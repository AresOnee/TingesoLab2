// ============================================
// RUNTIME ENVIRONMENT CONFIGURATION
// Este archivo es reemplazado en runtime por K8s ConfigMap
// ============================================
window.ENV = {
  KEYCLOAK_URL: "__KEYCLOAK_URL__",
  KEYCLOAK_REALM: "__KEYCLOAK_REALM__",
  KEYCLOAK_CLIENT_ID: "__KEYCLOAK_CLIENT_ID__"
};
