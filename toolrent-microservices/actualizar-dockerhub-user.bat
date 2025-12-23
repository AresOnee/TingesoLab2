@echo off
REM ============================================
REM Script para actualizar usuario Docker Hub en archivos YAML
REM ============================================

if "%1"=="" (
    echo USO: actualizar-dockerhub-user.bat TU_USUARIO_DOCKERHUB
    echo Ejemplo: actualizar-dockerhub-user.bat juanperez
    pause
    exit /b 1
)

set DOCKER_USER=%1

echo ============================================
echo   ACTUALIZANDO USUARIO DOCKER HUB
echo   Nuevo usuario: %DOCKER_USER%
echo ============================================

REM Actualizar archivos de infraestructura
echo.
echo Actualizando archivos de infraestructura...
powershell -Command "(Get-Content k8s/infrastructure/config-server.yaml) -replace 'TU_USUARIO_DOCKERHUB', '%DOCKER_USER%' | Set-Content k8s/infrastructure/config-server.yaml"
powershell -Command "(Get-Content k8s/infrastructure/eureka-server.yaml) -replace 'TU_USUARIO_DOCKERHUB', '%DOCKER_USER%' | Set-Content k8s/infrastructure/eureka-server.yaml"
powershell -Command "(Get-Content k8s/infrastructure/api-gateway.yaml) -replace 'TU_USUARIO_DOCKERHUB', '%DOCKER_USER%' | Set-Content k8s/infrastructure/api-gateway.yaml"

REM Actualizar archivos de microservicios
echo.
echo Actualizando archivos de microservicios...
powershell -Command "(Get-Content k8s/microservices/ms-tools.yaml) -replace 'TU_USUARIO_DOCKERHUB', '%DOCKER_USER%' | Set-Content k8s/microservices/ms-tools.yaml"
powershell -Command "(Get-Content k8s/microservices/ms-clients.yaml) -replace 'TU_USUARIO_DOCKERHUB', '%DOCKER_USER%' | Set-Content k8s/microservices/ms-clients.yaml"
powershell -Command "(Get-Content k8s/microservices/ms-config.yaml) -replace 'TU_USUARIO_DOCKERHUB', '%DOCKER_USER%' | Set-Content k8s/microservices/ms-config.yaml"
powershell -Command "(Get-Content k8s/microservices/ms-kardex.yaml) -replace 'TU_USUARIO_DOCKERHUB', '%DOCKER_USER%' | Set-Content k8s/microservices/ms-kardex.yaml"
powershell -Command "(Get-Content k8s/microservices/ms-loans.yaml) -replace 'TU_USUARIO_DOCKERHUB', '%DOCKER_USER%' | Set-Content k8s/microservices/ms-loans.yaml"
powershell -Command "(Get-Content k8s/microservices/ms-reports.yaml) -replace 'TU_USUARIO_DOCKERHUB', '%DOCKER_USER%' | Set-Content k8s/microservices/ms-reports.yaml"
powershell -Command "(Get-Content k8s/microservices/ms-users.yaml) -replace 'TU_USUARIO_DOCKERHUB', '%DOCKER_USER%' | Set-Content k8s/microservices/ms-users.yaml"

REM Actualizar script de docker build
echo.
echo Actualizando docker-build-push.bat...
powershell -Command "(Get-Content docker-build-push.bat) -replace 'TU_USUARIO', '%DOCKER_USER%' | Set-Content docker-build-push.bat"

echo.
echo ============================================
echo   ARCHIVOS ACTUALIZADOS
echo ============================================
echo.
echo Todos los archivos YAML ahora usan: %DOCKER_USER%
echo.
echo Siguiente paso: 
echo   1. docker-build-push.bat (construir y subir imagenes)
echo   2. deploy-k8s.bat (desplegar en Kubernetes)
echo.

pause
