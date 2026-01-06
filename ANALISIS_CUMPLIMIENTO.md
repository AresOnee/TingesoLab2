# Análisis Detallado de Cumplimiento - Evaluación 2 ToolRent

## 1. Resumen Ejecutivo

Este documento presenta un análisis exhaustivo del estado actual del proyecto `toolrent` contrastado con los documentos `Evaluacion2_v1.pdf` (Requisitos) y `Rubrica de Evaluación 2 _v2.pdf` (Criterios de evaluación).

**Estado General:** El proyecto cumple con la mayoría de los requisitos arquitectónicos y de infraestructura (Kubernetes, Docker, Patrones de Microservicios).
Respecto a **M7 (Gestión de Usuarios)**, el profesor ha confirmado que **Keycloak reemplaza completamente** la implementación manual de un microservicio Spring Boot para esta finalidad.

## 2. Análisis Comparativo con la Rúbrica de Evaluación

### Criterio 1: La aplicación web debe estar funcionando completamente en Kubernetes (20%)
*   **Requisito:** Aplicación funcional (frontend + backend) en K8s. Sin `port-forward`. Uso de `ClusterIP` interno y `NodePort` para Gateway.
*   **Estado:** **CUMPLE**.
*   **Evidencia:**
    *   **Frontend:** `toolrent-microservices/k8s/infrastructure/frontend-deployment.yaml` expone el frontend mediante `NodePort` en el puerto `30000`.
    *   **Backend:** `toolrent-microservices/k8s/infrastructure/api-gateway.yaml` expone el gateway mediante `NodePort` en el puerto `30080`.
    *   **Comunicación:** Los microservicios usan `ClusterIP` (por defecto al no especificar `type` en sus servicios).
*   **Observación:** La configuración del frontend (`.env`) tiene una IP hardcodeada (`192.168.1.89`), pero el despliegue de Kubernetes inyecta variables de entorno para Keycloak. Se debe asegurar que el frontend apunte correctamente al `NodePort` del API Gateway para que funcione en cualquier entorno.

### Criterio 2: Correcta implementación de microservicios y comunicación (20%)
*   **Requisito:** M1 a M7 implementados con capas, base de datos propia, `RestTemplate`, `server.port=0`.
*   **Estado:** **CUMPLE**.
*   **Cumplimiento:**
    *   **M1, M2, M3, M4, M5:** Implementados correctamente con Spring Boot y bases de datos independientes (`mysql-tools`, `mysql-loans`, `mysql-clients`, `mysql-config`, `mysql-kardex`).
    *   **M7 (Usuarios):** Implementado mediante **Keycloak** (reemplazo válido confirmado por el profesor).
    *   **Puertos Dinámicos:** `ms-loans` y `ms-reports` tienen `server.port=0` en `application.yml`.
    *   **Comunicación:** Se verificó uso de `RestTemplate` en `ms-loans` y `ms-reports`.
*   **Notas:**
    *   **M6 (Reportes):** El microservicio `ms-reports` existe pero **NO TIENE BASE DE DATOS** propia en `k8s/databases`. Realiza consultas HTTP a otros servicios. Esto es técnicamente válido para reportes en tiempo real, ya que la rúbrica indica "según corresponda".

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
| **M4** | Montos y Tarifas | **Existe** (`ms-config`) | ✅ `mysql-config` | Cumple. |
| **M5** | Kardex | **Existe** (`ms-kardex`) | ✅ `mysql-kardex` | Cumple. |
| **M6** | Reportes | **Existe** (`ms-reports`) | ⚠️ **Sin DB** | Cumple lógica de negocio mediante agregación HTTP. Falta DB si se exige persistencia de reportes históricos. |
| **M7** | Usuarios y Roles | ✅ **Keycloak** | ✅ `postgres` (o H2 interna) | **CUMPLE.** Reemplazo autorizado por el profesor. Se gestiona la identidad y roles en Keycloak. |

### Frontend
*   **Requisito:** ReactJS, único frontend.
*   **Estado:** **CUMPLE**.
*   **Evidencia:** Carpeta `toolrent-frontend` con estructura React/Vite.

### Tecnologías y Herramientas
*   **Spring Boot:** Usado en todos los servicios backend (M1-M6).
*   **Java:** Versión 17 (según POM).
*   **Docker:** Dockerfiles presentes en cada servicio.
*   **Kubernetes:** Manifiestos completos.

## 4. Conclusiones y Recomendaciones

1.  **M7 (Usuarios):** La solución está **alineada con las instrucciones del profesor** al utilizar Keycloak para reemplazar el desarrollo manual de un microservicio de usuarios.
2.  **Base de Datos M6 (Reportes):**
    *   *Recomendación:* Se justifica que M6 es un agregador en tiempo real y por ende no requiere persistencia propia ("según corresponda").
3.  **Configuración Frontend:**
    *   *Recomendación:* Verificar que el `ConfigMap` del frontend en K8s apunte al API Gateway correctamente y no dependa de las IPs en el `.env` local.

## 5. Ubicación de Evidencias en el Repositorio

*   **M1-M6:** `toolrent-microservices/ms-*`
*   **Infraestructura:** `toolrent-microservices/k8s/infrastructure/`
*   **Bases de Datos:** `toolrent-microservices/k8s/databases/`
*   **Configuración Dinámica:** `toolrent-microservices/ms-loans/src/main/resources/application.yml` (server.port=0)
