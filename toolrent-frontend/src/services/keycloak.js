// src/keycloak.js
import Keycloak from "keycloak-js";

// Configuración de Keycloak
// En desarrollo usa variables de entorno de Vite
// En producción (K8s) usa window.ENV inyectado por ConfigMap
const getKeycloakConfig = () => {
  // Primero intenta usar window.ENV (configuración runtime para K8s)
  if (typeof window !== 'undefined' && window.ENV) {
    return {
      url: window.ENV.KEYCLOAK_URL || "http://localhost:9090",
      realm: window.ENV.KEYCLOAK_REALM || "sisgr-realm",
      clientId: window.ENV.KEYCLOAK_CLIENT_ID || "sisgr-frontend",
    };
  }

  // Fallback a variables de entorno de Vite (desarrollo)
  return {
    url: import.meta.env.VITE_KEYCLOAK_URL || "http://localhost:9090",
    realm: import.meta.env.VITE_KEYCLOAK_REALM || "sisgr-realm",
    clientId: import.meta.env.VITE_KEYCLOAK_CLIENT_ID || "sisgr-frontend",
  };
};

const keycloak = new Keycloak(getKeycloakConfig());

export async function initKeycloak() {
  const authenticated = await keycloak.init({
    onLoad: "login-required",
    checkLoginIframe: false,
    pkceMethod: "S256",
  });

  if (!authenticated) {
    await keycloak.login();
  }

  // Guarda referencia global y token para que cualquier módulo lo pueda leer
  window.keycloak = keycloak;
  localStorage.setItem("kc_token", keycloak.token);

  // Mantén el token fresco
  setInterval(async () => {
    try {
      const refreshed = await keycloak.updateToken(30);
      if (refreshed) {
        localStorage.setItem("kc_token", keycloak.token);
      }
    } catch (e) {
      console.error("Fallo refrescando token:", e);
      keycloak.login();
    }
  }, 25_000);
}

export default keycloak;
