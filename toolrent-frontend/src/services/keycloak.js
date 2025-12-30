// src/keycloak.js
import Keycloak from "keycloak-js";

// Configuración de Keycloak
// En desarrollo usa variables de entorno de Vite
// En producción (K8s) usa window.ENV inyectado por ConfigMap
const getKeycloakConfig = () => {
  // Primero intenta usar window.ENV (configuración runtime para K8s)
  if (typeof window !== 'undefined' && window.ENV) {
    console.log("🔐 Usando window.ENV para config:", window.ENV);
    return {
      url: window.ENV.KEYCLOAK_URL || "http://localhost:9090",
      realm: window.ENV.KEYCLOAK_REALM || "sisgr-realm",
      clientId: window.ENV.KEYCLOAK_CLIENT_ID || "sisgr-frontend",
    };
  }

  // Fallback a variables de entorno de Vite (desarrollo)
  console.log("🔐 Usando fallback config (Vite env)");
  return {
    url: import.meta.env.VITE_KEYCLOAK_URL || "http://localhost:9090",
    realm: import.meta.env.VITE_KEYCLOAK_REALM || "sisgr-realm",
    clientId: import.meta.env.VITE_KEYCLOAK_CLIENT_ID || "sisgr-frontend",
  };
};

const config = getKeycloakConfig();
console.log("🔐 Keycloak config final:", config);

const keycloak = new Keycloak(config);

export default keycloak;
