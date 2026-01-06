# 🔧 FASE 1: Infraestructura Base para ToolRent Microservices

Este directorio contiene los tres componentes de infraestructura necesarios para la arquitectura de microservicios:

## 📁 Estructura

```
toolrent-microservices/
├── config-server/          # Puerto 8888 - Servidor de configuración centralizada
├── eureka-server/          # Puerto 8761 - Service Discovery
├── api-gateway/            # Puerto 8080 - Gateway único de entrada
├── k8s/                    # Manifiestos de Kubernetes
│   ├── namespace.yaml
│   ├── configmaps/
│   ├── secrets/
│   └── infrastructure/
├── docker-compose-infra.yml
├── build-infra.sh
└── README.md
```

## 🚀 Inicio Rápido

### Prerequisitos
- Java 17
- Maven 3.8+
- Docker Desktop
- (Opcional) Minikube + VirtualBox para Kubernetes

### 1. Compilar los proyectos

```bash
# Dar permisos al script
chmod +x build-infra.sh

# Compilar todo
./build-infra.sh
```

O manualmente:
```bash
cd config-server && ./mvnw clean package -DskipTests && cd ..
cd eureka-server && ./mvnw clean package -DskipTests && cd ..
cd api-gateway && ./mvnw clean package -DskipTests && cd ..
```

### 2. Probar con Docker Compose

```bash
docker-compose -f docker-compose-infra.yml up --build
```

**URLs de acceso:**
- Config Server: http://localhost:8888
- Eureka Dashboard: http://localhost:8761
- API Gateway: http://localhost:8080

### 3. Subir imágenes a Docker Hub

```bash
# Login a Docker Hub
docker login

# Construir y taggear
docker build -t TU_USUARIO/config-server:latest ./config-server
docker build -t TU_USUARIO/eureka-server:latest ./eureka-server
docker build -t TU_USUARIO/api-gateway:latest ./api-gateway

# Push
docker push TU_USUARIO/config-server:latest
docker push TU_USUARIO/eureka-server:latest
docker push TU_USUARIO/api-gateway:latest
```

### 4. Desplegar en Kubernetes (Minikube)

```bash
# Iniciar Minikube con VirtualBox (REQUERIDO según enunciado)
minikube start --driver=virtualbox

# Crear namespace y configuración
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmaps/
kubectl apply -f k8s/secrets/

# Desplegar infraestructura (en orden)
kubectl apply -f k8s/infrastructure/config-server.yaml
kubectl wait --for=condition=ready pod -l app=config-server -n toolrent --timeout=120s

kubectl apply -f k8s/infrastructure/eureka-server.yaml
kubectl wait --for=condition=ready pod -l app=eureka-server -n toolrent --timeout=120s

kubectl apply -f k8s/infrastructure/api-gateway.yaml

# Verificar
kubectl get pods -n toolrent
kubectl get services -n toolrent
```

## 📋 Componentes

### Config Server (Puerto 8888)
- Centraliza la configuración de todos los microservicios
- Usa perfil `native` para servir configs desde `classpath:/configurations`
- Contiene configuraciones para: ms-tools, ms-loans, ms-clients, ms-config, ms-kardex, ms-reports
- NOTA: La gestión de usuarios (Épica 7) se maneja con Keycloak

### Eureka Server (Puerto 8761)
- Service Discovery para registro automático de microservicios
- Dashboard disponible en http://localhost:8761
- Los microservicios se registran automáticamente usando su nombre

### API Gateway (Puerto 8080 → NodePort 30080)
- Punto único de entrada para el frontend
- Rutea peticiones a los microservicios usando Eureka
- Configuración CORS para React frontend
- **IMPORTANTE:** Es el ÚNICO servicio expuesto externamente via NodePort

## 🔗 Rutas del API Gateway

| Ruta | Microservicio | Épica |
|------|---------------|-------|
| `/api/v1/tools/**` | MS-TOOLS | Épica 1: Herramientas |
| `/api/v1/loans/**` | MS-LOANS | Épica 2: Préstamos |
| `/api/v1/clients/**` | MS-CLIENTS | Épica 3: Clientes |
| `/api/v1/config/**` | MS-CONFIG | Épica 4: Tarifas |
| `/api/v1/kardex/**` | MS-KARDEX | Épica 5: Kardex |
| `/api/v1/reports/**` | MS-REPORTS | Épica 6: Reportes |

> **Nota:** La Épica 7 (Gestión de Usuarios y Roles) se implementa con Keycloak

## ⚠️ Notas Importantes

1. **NodePort vs ClusterIP:**
   - Config Server: ClusterIP (solo interno)
   - Eureka Server: ClusterIP (solo interno)
   - API Gateway: **NodePort** (acceso externo)

2. **No usar port-forward:** El enunciado prohibe explícitamente el uso de port-forward.

3. **Minikube con VM:** Debe levantarse con `--driver=virtualbox` o `--driver=hyperv`

4. **Comunicación interna:** Los microservicios NO deben comunicarse entre sí a través del Gateway. Deben usar los nombres de servicio de Eureka directamente.

## 🐛 Troubleshooting

### Ver logs de un pod
```bash
kubectl logs -f deployment/config-server -n toolrent
kubectl logs -f deployment/eureka-server -n toolrent
kubectl logs -f deployment/api-gateway -n toolrent
```

### Verificar endpoints de Config Server
```bash
curl http://localhost:8888/ms-tools/default
```

### Verificar servicios registrados en Eureka
```bash
curl http://localhost:8761/eureka/apps
```

### Reiniciar un deployment
```bash
kubectl rollout restart deployment/api-gateway -n toolrent
```

---

## ➡️ Siguiente Paso: FASE 2

Una vez que la infraestructura base esté funcionando, continuar con la **FASE 2: Migración de Microservicios**, donde separaremos el monolito en 7 microservicios independientes.
