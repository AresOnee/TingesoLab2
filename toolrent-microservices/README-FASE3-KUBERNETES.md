# 🚀 FASE 3: Despliegue en Kubernetes (Minikube)

## 📋 Requisitos Previos

1. **Hyper-V** habilitado en Windows
2. **Minikube** instalado
3. **kubectl** instalado
4. **Docker Desktop** corriendo
5. **Cuenta en Docker Hub**

### Habilitar Hyper-V (si no está habilitado)
```powershell
# Ejecutar PowerShell como Administrador
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
# Reiniciar el PC después
```

## 🏗️ Arquitectura en Kubernetes

```
                         INTERNET
                            │
                     ┌──────▼──────┐
                     │   NodePort  │ :30080
                     │ API-GATEWAY │
                     └──────┬──────┘
                            │
        ┌───────────────────┼───────────────────┐
        │              CLUSTER K8S              │
        │                   │                   │
        │  ┌────────────────┼────────────────┐  │
        │  │           ClusterIP             │  │
        │  │                                 │  │
        │  │  ┌─────────┐  ┌─────────┐      │  │
        │  │  │ EUREKA  │  │ CONFIG  │      │  │
        │  │  │ SERVER  │  │ SERVER  │      │  │
        │  │  └─────────┘  └─────────┘      │  │
        │  │                                 │  │
        │  │  ┌─────────┬─────────┬───────┐ │  │
        │  │  │ms-tools │ms-client│ms-conf│ │  │
        │  │  │ms-kardex│ms-loans │ms-repo│ │  │
        │  │  │ms-users │         │       │ │  │
        │  │  └────┬────┴────┬────┴───┬───┘ │  │
        │  │       │         │        │     │  │
        │  │  ┌────▼────┬────▼────┬───▼───┐ │  │
        │  │  │ MySQL   │ MySQL   │ MySQL │ │  │
        │  │  │(6 inst.)│         │       │ │  │
        │  │  └─────────┴─────────┴───────┘ │  │
        │  └─────────────────────────────────┘  │
        └───────────────────────────────────────┘
```

## 📦 Estructura de Archivos K8s

```
k8s/
├── 00-namespace.yaml      # Namespace: toolrent
├── 01-configmap.yaml      # Configuraciones comunes
├── 02-secrets.yaml        # Credenciales MySQL (base64)
├── databases/
│   ├── mysql-tools.yaml   # PVC + Deployment + Service
│   ├── mysql-clients.yaml
│   ├── mysql-config.yaml
│   ├── mysql-loans.yaml
│   ├── mysql-kardex.yaml
│   └── mysql-users.yaml
├── infrastructure/
│   ├── config-server.yaml # ClusterIP :8888
│   ├── eureka-server.yaml # ClusterIP :8761
│   └── api-gateway.yaml   # NodePort :30080 ⬅️ ÚNICO EXPUESTO
└── microservices/
    ├── ms-tools.yaml      # ClusterIP
    ├── ms-clients.yaml    # ClusterIP
    ├── ms-config.yaml     # ClusterIP
    ├── ms-kardex.yaml     # ClusterIP
    ├── ms-loans.yaml      # ClusterIP
    ├── ms-reports.yaml    # ClusterIP
    └── ms-users.yaml      # ClusterIP
```

## 🔧 Paso 1: Iniciar Minikube con Hyper-V

```cmd
REM IMPORTANTE: Ejecutar CMD como Administrador

REM Iniciar Minikube con Hyper-V
minikube start --driver=hyperv --memory=8192 --cpus=4

REM Verificar que está corriendo
minikube status

REM Ver la IP asignada
minikube ip
```

### Si tienes problemas con el Virtual Switch de Hyper-V:
```cmd
REM Crear un Virtual Switch externo en Hyper-V Manager primero
REM Luego especificarlo:
minikube start --driver=hyperv --hyperv-virtual-switch="NombreDelSwitch" --memory=8192 --cpus=4
```

## 🐳 Paso 2: Subir imágenes a Docker Hub

### 2.1 Actualizar usuario en archivos

```cmd
REM Reemplaza TU_USUARIO con tu usuario de Docker Hub
actualizar-dockerhub-user.bat TU_USUARIO
```

### 2.2 Construir y subir imágenes

```cmd
REM Asegúrate de haber compilado los JARs primero
docker-build-push.bat
```

Este script:
1. Hace login a Docker Hub
2. Construye las 10 imágenes
3. Las sube a tu repositorio

## ☸️ Paso 3: Desplegar en Kubernetes

```cmd
deploy-k8s.bat
```

Este script aplica los YAMLs en orden:
1. Namespace, ConfigMap, Secrets
2. Bases de datos MySQL (espera 60s)
3. Infraestructura (espera 90s)
4. Microservicios

## ✅ Paso 4: Verificar Despliegue

### Ver todos los pods
```cmd
kubectl get pods -n toolrent
```

Todos deben estar en estado `Running` con `1/1` READY.

### Ver servicios
```cmd
kubectl get services -n toolrent
```

Solo `api-gateway` debe ser `NodePort`, el resto `ClusterIP`.

### Ver logs de un pod
```cmd
kubectl logs -n toolrent deployment/ms-tools
```

## 🌐 Paso 5: Acceder a la Aplicación

### Obtener IP de Minikube
```cmd
minikube ip
```

### Acceder via NodePort
```
http://[MINIKUBE_IP]:30080/api/v1/tools/
http://[MINIKUBE_IP]:30080/api/v1/clients/
```

Ejemplo: Si `minikube ip` retorna `192.168.99.100`:
```
http://192.168.99.100:30080/api/v1/tools/
```

## 📊 Comandos Útiles

```cmd
REM Ver estado general
kubectl get all -n toolrent

REM Ver pods con más detalle
kubectl get pods -n toolrent -o wide

REM Describir un pod (para debugging)
kubectl describe pod [NOMBRE_POD] -n toolrent

REM Ver logs en tiempo real
kubectl logs -f deployment/ms-loans -n toolrent

REM Reiniciar un deployment
kubectl rollout restart deployment/ms-tools -n toolrent

REM Eliminar todo
kubectl delete namespace toolrent
```

## 🔄 Cargar Seed Data en Kubernetes

Una vez que los pods estén corriendo:

```cmd
REM Obtener nombre del pod MySQL
kubectl get pods -n toolrent | findstr mysql-tools

REM Copiar archivo SQL al pod
kubectl cp seed-data/01-tools-seed.sql toolrent/[NOMBRE_POD_MYSQL]:/tmp/

REM Ejecutar SQL
kubectl exec -n toolrent [NOMBRE_POD_MYSQL] -- mysql -uroot -prootpass tools_db -e "source /tmp/01-tools-seed.sql"
```

Repetir para cada base de datos.

## ⚠️ Requisitos de la Evaluación Cumplidos

| Requisito | Estado |
|-----------|--------|
| NO usar port-forward | ✅ Usamos NodePort |
| Minikube con Hyper-V | ✅ `--driver=hyperv` |
| ClusterIP para microservicios | ✅ Solo comunicación interna |
| NodePort solo para API Gateway | ✅ Puerto 30080 |
| Microservicios NO via Gateway | ✅ Comunicación directa por Eureka |
| Imágenes en Docker Hub | ✅ Script incluido |
| Deployment, Service, ConfigMap, Secrets | ✅ Todos los tipos usados |

## 🛠️ Troubleshooting

### Pod en estado CrashLoopBackOff
```cmd
kubectl logs -n toolrent [NOMBRE_POD] --previous
kubectl describe pod -n toolrent [NOMBRE_POD]
```

### MySQL no conecta
- Verificar que el pod MySQL esté Running
- Verificar que el Secret esté creado correctamente

### Eureka no tiene servicios registrados
- Esperar 2-3 minutos para que se registren
- Verificar logs de los microservicios

### ImagePullBackOff
- Verificar que las imágenes existan en Docker Hub
- Verificar nombre de usuario en los YAMLs
