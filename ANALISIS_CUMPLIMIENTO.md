# Análisis Detallado de Cumplimiento - Evaluación 2 ToolRent

## 1. Resumen Ejecutivo

Este documento presenta un análisis exhaustivo del estado actual del proyecto `toolrent` contrastado con los documentos `Evaluacion2_v1.pdf` (Requisitos) y `Rubrica de Evaluación 2 _v2.pdf` (Criterios de evaluación).

**Estado General:** El proyecto cumple con la mayoría de los requisitos arquitectónicos y de infraestructura (Kubernetes, Docker, Patrones de Microservicios). Sin embargo, existe una **desviación crítica** respecto a la implementación del Microservicio M7 (Gestión de Usuarios), el cual no está implementado como un servicio Spring Boot independiente, sino que se delega completamente en Keycloak.

## 2. Análisis Comparativo con la Rúbrica de Evaluación

### Criterio 1: La aplicación web debe estar funcionando completamente en Kubernetes (20%)
*   **Requisito:** Aplicación funcional (frontend + backend) en K8s. Sin `port-forward`. Uso de `ClusterIP` interno y `NodePort` para Gateway.
*   **Estado:** **CUMPLE**.
*   **Evidencia:**
    *   **Frontend:** `toolrent-microservices/k8s/infrastructure/frontend-deployment.yaml` expone el frontend mediante `NodePort` en el puerto `30000`.
    *   **Backend:** `toolrent-microservices/k8s/infrastructure/api-gateway.yaml` expone el gateway mediante `NodePort` en el puerto `30080`.
    *   **Comunicación:** Los microservicios usan `ClusterIP` (por defecto al no especificar `type` en sus servicios, aunque no se visualizaron los Services específicos de M1-M6, se asume estándar).
*   **Observación:** La configuración del frontend (`.env`) tiene una IP hardcodeada (`192.168.1.89`), pero el despliegue de Kubernetes inyecta variables de entorno para Keycloak. Se debe asegurar que el frontend apunte correctamente al `NodePort` del API Gateway (ej. `http://<NODE_IP>:30080`) para que funcione en cualquier entorno.

### Criterio 2: Correcta implementación de microservicios y comunicación (20%)
*   **Requisito:** M1 a M7 implementados con capas, base de datos propia, `RestTemplate`, `server.port=0`.
*   **Estado:** **CUMPLE PARCIALMENTE (Riesgo en M7 y M6)**.
*   **Cumplimiento:**
    *   **M1, M2, M3, M4, M5:** Implementados correctamente con Spring Boot y bases de datos independientes (`mysql-tools`, `mysql-loans`, `mysql-clients`, `mysql-config`, `mysql-kardex`).
    *   **Puertos Dinámicos:** `ms-loans` y `ms-reports` tienen `server.port=0` en `application.yml`.
    *   **Comunicación:** Se verificó uso de `RestTemplate` en `ms-loans` y `ms-reports`.
*   **Faltantes/Desviaciones:**
    *   **M7 (Usuarios y Roles):** **NO EXISTE** como proyecto Spring Boot (`ms-users`). Se utiliza **Keycloak** como solución de identidad (`k8s/infrastructure/keycloak.yaml`). Aunque es una mejor práctica industrial, la rúbrica pide explícitamente "Cada uno de los microservicios (M1 a M7) implementa correctamente... usando Spring Boot".
    *   **M6 (Reportes):** El microservicio `ms-reports` existe pero **NO TIENE BASE DE DATOS** propia en `k8s/databases`. Realiza consultas HTTP a otros servicios. Esto es técnicamente válido para reportes en tiempo real, pero la rúbrica dice "conectado exclusivamente a su propia base de datos... según corresponda".

### Criterio 3: Implementación de patrones de microservicios (30%)
*   **Requisito:** ConfigServer, Eureka Server, API Gateway.
*   **Estado:** **CUMPLE**.
*   **Evidencia:**
    *   Carpetas `config-server`, `eureka-server`, `api-gateway` existen.
    *   Manifiestos K8s en `toolrent-microservices/k8s/infrastructure/`.
    *   Los microservicios (ej. `ms-loans`) están configurados para usar ConfigServer y Eureka (`eureka.client.service-url`).

### Criterio 4: Uso correcto de objetos Kubernetes (30%)
*   **Requisito:** Pods, Deployments, Services, ConfigMaps, Secrets.
*   **Estado:** **CUMPLE**.
*   **Evidencia:**
    *   Directorio `toolrent-microservices/k8s/` bien estructurado.
    *   Uso de `ConfigMap` (`01-configmap.yaml`) y `Secret` (`02-secrets.yaml`).
    *   Bases de datos desplegadas como Deployments independientes.

## 3. Análisis Detallado de Requisitos Funcionales (Evaluacion2_v1.pdf)

### Microservicios Requeridos

| Microservicio | Épica | Estado en Código | Base de Datos | Observación |
| :--- | :--- | :--- | :--- | :--- |
| **M1** | Inventario Herramientas | **Existe** (`ms-tools`) | ✅ `mysql-tools` | Cumple. |
| **M2** | Préstamos | **Existe** (`ms-loans`) | ✅ `mysql-loans` | Cumple. Usa RestTemplate. |
| **M3** | Clientes | **Existe** (`ms-clients`) | ✅ `mysql-clients` | Cumple. |
| **M4** | Montos y Tarifas | **Existe** (`ms-config`) | ✅ `mysql-config` | Cumple. Nota: Nombre de carpeta `ms-config` puede confundirse con ConfigServer, pero el POM confirma que es "Microservicio de Configuración y Tarifas". |
| **M5** | Kardex | **Existe** (`ms-kardex`) | ✅ `mysql-kardex` | Cumple. |
| **M6** | Reportes | **Existe** (`ms-reports`) | ⚠️ **Sin DB** | Cumple lógica de negocio mediante agregación HTTP. Falta DB si se exige persistencia de reportes históricos. |
| **M7** | Usuarios y Roles | ❌ **FALTA CÓDIGO** | ⚠️ `Keycloak` | **CRÍTICO.** No hay proyecto Spring Boot para M7. Se delega en Keycloak. Faltan endpoints RF7.1, RF7.2 implementados en Java si se exige estricto apego al enunciado. |

### Frontend
*   **Requisito:** ReactJS, único frontend.
*   **Estado:** **CUMPLE**.
*   **Evidencia:** Carpeta `toolrent-frontend` con estructura React/Vite.

### Tecnologías y Herramientas
*   **Spring Boot:** Usado en todos los servicios backend encontrados.
*   **Java:** Versión 17 (según POM).
*   **Docker:** Dockerfiles presentes en cada servicio.
*   **Kubernetes:** Manifiestos completos.

## 4. Conclusiones y Recomendaciones

1.  **Aclarar M7 (Usuarios):** El punto más débil es la ausencia de un microservicio Spring Boot para usuarios.
    *   *Recomendación:* Si aún hay tiempo, crear un microservicio `ms-users` que actúe como "wrapper" o fachada de Keycloak (o que implemente una tabla de usuarios simple si Keycloak no es obligatorio como única fuente), o bien, preparar una justificación sólida de por qué Keycloak reemplaza a M7 (cumple RF7.3 y RF7.4 mejor que una impl. propia).
2.  **Base de Datos M6 (Reportes):**
    *   *Recomendación:* Justificar que M6 es un agregador en tiempo real y por ende no requiere persistencia propia ("según corresponda").
3.  **Configuración Frontend:**
    *   *Recomendación:* Verificar que el `ConfigMap` del frontend en K8s apunte al API Gateway correctamente y no dependa de las IPs en el `.env` local.

## 5. Ubicación de Evidencias en el Repositorio

*   **M1-M6:** `toolrent-microservices/ms-*`
*   **Infraestructura:** `toolrent-microservices/k8s/infrastructure/`
*   **Bases de Datos:** `toolrent-microservices/k8s/databases/`
*   **Configuración Dinámica:** `toolrent-microservices/ms-loans/src/main/resources/application.yml` (server.port=0)
