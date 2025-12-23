@echo off
REM ============================================
REM Script para desplegar en Kubernetes (Minikube)
REM ============================================

echo ============================================
echo   DESPLEGANDO TOOLRENT EN KUBERNETES
echo ============================================

REM Verificar que minikube está corriendo
echo.
echo Verificando Minikube...
minikube status
if %ERRORLEVEL% neq 0 (
    echo ERROR: Minikube no esta corriendo!
    echo Ejecuta: minikube start --driver=hyperv --memory=8192 --cpus=4
    echo.
    echo NOTA: Debes ejecutar CMD como Administrador para usar Hyper-V
    pause
    exit /b 1
)

REM Paso 1: Crear Namespace, ConfigMap y Secrets
echo.
echo [Paso 1/4] Creando Namespace, ConfigMap y Secrets...
kubectl apply -f k8s/00-namespace.yaml
kubectl apply -f k8s/01-configmap.yaml
kubectl apply -f k8s/02-secrets.yaml

REM Paso 2: Desplegar bases de datos
echo.
echo [Paso 2/4] Desplegando bases de datos MySQL...
kubectl apply -f k8s/databases/

echo.
echo Esperando a que las bases de datos esten listas (60 segundos)...
timeout /t 60 /nobreak

REM Paso 3: Desplegar infraestructura
echo.
echo [Paso 3/4] Desplegando infraestructura (Config Server, Eureka, Gateway)...
kubectl apply -f k8s/infrastructure/

echo.
echo Esperando a que la infraestructura este lista (90 segundos)...
timeout /t 90 /nobreak

REM Paso 4: Desplegar microservicios
echo.
echo [Paso 4/4] Desplegando microservicios...
kubectl apply -f k8s/microservices/

echo.
echo ============================================
echo   DESPLIEGUE COMPLETADO
echo ============================================

REM Verificar estado
echo.
echo Estado de los pods:
kubectl get pods -n toolrent

echo.
echo Estado de los servicios:
kubectl get services -n toolrent

echo.
echo ============================================
echo   ACCESO A LA APLICACION
echo ============================================
echo.
echo Para obtener la URL del API Gateway, ejecuta:
echo   minikube service api-gateway -n toolrent --url
echo.
echo O accede directamente via NodePort:
echo   minikube ip
echo   (Luego usa http://[MINIKUBE_IP]:30080)
echo.

pause
