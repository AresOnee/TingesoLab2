#!/bin/bash

# Script para compilar los proyectos de infraestructura de ToolRent
# Ejecutar desde la carpeta toolrent-microservices/

echo "=========================================="
echo "Compilando proyectos de infraestructura"
echo "=========================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para compilar un proyecto
compile_project() {
    local project=$1
    echo -e "\n${YELLOW}Compilando $project...${NC}"
    cd $project
    
    if ./mvnw clean package -DskipTests; then
        echo -e "${GREEN}✓ $project compilado exitosamente${NC}"
        cd ..
        return 0
    else
        echo -e "${RED}✗ Error compilando $project${NC}"
        cd ..
        return 1
    fi
}

# Verificar que estamos en el directorio correcto
if [ ! -d "config-server" ] || [ ! -d "eureka-server" ] || [ ! -d "api-gateway" ]; then
    echo -e "${RED}Error: Ejecuta este script desde la carpeta toolrent-microservices/${NC}"
    exit 1
fi

# Compilar cada proyecto
compile_project "config-server" || exit 1
compile_project "eureka-server" || exit 1
compile_project "api-gateway" || exit 1

echo -e "\n${GREEN}=========================================="
echo "¡Todos los proyectos compilados!"
echo "==========================================${NC}"

echo -e "\n${YELLOW}Siguiente paso: Ejecutar docker-compose${NC}"
echo "  docker-compose -f docker-compose-infra.yml up --build"
