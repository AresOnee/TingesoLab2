// src/main.jsx
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App.jsx";
import { ReactKeycloakProvider } from "@react-keycloak/web";
import keycloak from "./services/keycloak";

// Debug: mostrar configuración de Keycloak
console.log("🔐 Keycloak Config:", {
  url: keycloak.authServerUrl,
  realm: keycloak.realm,
  clientId: keycloak.clientId,
  windowENV: window.ENV
});

// Componente de carga mientras Keycloak inicializa
const LoadingComponent = () => (
  <div style={{
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    height: '100vh',
    fontSize: '20px'
  }}>
    🔐 Conectando con Keycloak...
  </div>
);

ReactDOM.createRoot(document.getElementById("root")).render(
  <ReactKeycloakProvider
    authClient={keycloak}
    initOptions={{
      onLoad: "login-required",
      pkceMethod: "S256",
      checkLoginIframe: false,
    }}
    LoadingComponent={<LoadingComponent />}
    onEvent={(event, error) => {
      console.log("🔐 Keycloak Event:", event, error);
      if (error) {
        console.error("🔐 Keycloak Error:", error);
      }
    }}
    onTokens={({ token }) => {
      console.log("🔐 Token recibido!");
      localStorage.setItem("kc_token", token);
      window.keycloak = keycloak;
    }}
  >
    <React.StrictMode>
      <App />
    </React.StrictMode>
  </ReactKeycloakProvider>
);
