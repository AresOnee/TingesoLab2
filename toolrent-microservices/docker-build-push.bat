@echo off
REM ============================================
REM Script para construir y subir imágenes a Docker Hub
REM ============================================

REM IMPORTANTE: Cambia fergusone por tu usuario de Docker Hub
set DOCKER_USER=fergusone

echo ============================================
echo   CONSTRUYENDO Y SUBIENDO IMAGENES DOCKER
echo   Usuario Docker Hub: %DOCKER_USER%
echo ============================================

REM Login a Docker Hub
echo.
echo Iniciando sesion en Docker Hub...
docker login

REM Infraestructura
echo.
echo [1/10] Construyendo config-server...
cd config-server
docker build -t %DOCKER_USER%/config-server:1.0.0 .
docker push %DOCKER_USER%/config-server:1.0.0
cd ..

echo.
echo [2/10] Construyendo eureka-server...
cd eureka-server
docker build -t %DOCKER_USER%/eureka-server:1.0.0 .
docker push %DOCKER_USER%/eureka-server:1.0.0
cd ..

echo.
echo [3/10] Construyendo api-gateway...
cd api-gateway
docker build -t %DOCKER_USER%/api-gateway:1.0.0 .
docker push %DOCKER_USER%/api-gateway:1.0.0
cd ..

REM Microservicios
echo.
echo [4/10] Construyendo ms-tools...
cd ms-tools
docker build -t %DOCKER_USER%/ms-tools:1.0.0 .
docker push %DOCKER_USER%/ms-tools:1.0.0
cd ..

echo.
echo [5/10] Construyendo ms-clients...
cd ms-clients
docker build -t %DOCKER_USER%/ms-clients:1.0.0 .
docker push %DOCKER_USER%/ms-clients:1.0.0
cd ..

echo.
echo [6/10] Construyendo ms-config...
cd ms-config
docker build -t %DOCKER_USER%/ms-config:1.0.0 .
docker push %DOCKER_USER%/ms-config:1.0.0
cd ..

echo.
echo [7/10] Construyendo ms-kardex...
cd ms-kardex
docker build -t %DOCKER_USER%/ms-kardex:1.0.0 .
docker push %DOCKER_USER%/ms-kardex:1.0.0
cd ..

echo.
echo [8/10] Construyendo ms-loans...
cd ms-loans
docker build -t %DOCKER_USER%/ms-loans:1.0.0 .
docker push %DOCKER_USER%/ms-loans:1.0.0
cd ..

echo.
echo [9/9] Construyendo ms-reports...
cd ms-reports
docker build -t %DOCKER_USER%/ms-reports:1.0.0 .
docker push %DOCKER_USER%/ms-reports:1.0.0
cd ..

REM NOTA: ms-users fue reemplazado por Keycloak para gestion de usuarios (Epica 7)

echo.
echo ============================================
echo   IMAGENES SUBIDAS EXITOSAMENTE
echo ============================================
echo.
echo Imagenes disponibles en Docker Hub:
echo   - %DOCKER_USER%/config-server:1.0.0
echo   - %DOCKER_USER%/eureka-server:1.0.0
echo   - %DOCKER_USER%/api-gateway:1.0.0
echo   - %DOCKER_USER%/ms-tools:1.0.0
echo   - %DOCKER_USER%/ms-clients:1.0.0
echo   - %DOCKER_USER%/ms-config:1.0.0
echo   - %DOCKER_USER%/ms-kardex:1.0.0
echo   - %DOCKER_USER%/ms-loans:1.0.0
echo   - %DOCKER_USER%/ms-reports:1.0.0
echo.
echo Siguiente paso: Actualiza los archivos YAML en k8s/ con tu usuario
echo y luego ejecuta deploy-k8s.bat

pause
