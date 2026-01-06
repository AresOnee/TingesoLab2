#!/bin/bash

# ============================================
# Script de compilación para todos los microservicios
# ============================================

echo "============================================"
echo "  COMPILANDO MICROSERVICIOS TOOLRENT"
echo "============================================"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Función para compilar un proyecto
compile_project() {
    local project=$1
    echo ""
    echo "----------------------------------------"
    echo "Compilando: $project"
    echo "----------------------------------------"
    
    cd "$project" || exit 1
    
    if mvn clean package -DskipTests -q; then
        echo -e "${GREEN}✓ $project compilado exitosamente${NC}"
        cd ..
        return 0
    else
        echo -e "${RED}✗ Error compilando $project${NC}"
        cd ..
        return 1
    fi
}

# Proyectos de infraestructura (ya deberían estar compilados)
INFRA_PROJECTS=(
    "config-server"
    "eureka-server"
    "api-gateway"
)

# Microservicios
# NOTA: ms-users fue reemplazado por Keycloak para gestión de usuarios (Épica 7)
MICROSERVICES=(
    "ms-tools"
    "ms-clients"
    "ms-config"
    "ms-kardex"
    "ms-loans"
    "ms-reports"
)

# Compilar infraestructura
echo ""
echo "============================================"
echo "  FASE 1: INFRAESTRUCTURA"
echo "============================================"

for project in "${INFRA_PROJECTS[@]}"; do
    if [ -d "$project" ]; then
        compile_project "$project"
    else
        echo -e "${RED}Directorio $project no encontrado${NC}"
    fi
done

# Compilar microservicios
echo ""
echo "============================================"
echo "  FASE 2: MICROSERVICIOS"
echo "============================================"

for project in "${MICROSERVICES[@]}"; do
    if [ -d "$project" ]; then
        compile_project "$project"
    else
        echo -e "${RED}Directorio $project no encontrado${NC}"
    fi
done

# Verificar JARs generados
echo ""
echo "============================================"
echo "  VERIFICACIÓN DE JARS"
echo "============================================"

ALL_PROJECTS=("${INFRA_PROJECTS[@]}" "${MICROSERVICES[@]}")
SUCCESS=0
FAILED=0

for project in "${ALL_PROJECTS[@]}"; do
    JAR_FILE="$project/target/*.jar"
    if ls $JAR_FILE 1>/dev/null 2>&1; then
        SIZE=$(ls -lh $JAR_FILE 2>/dev/null | awk '{print $5}')
        echo -e "${GREEN}✓ $project/target/*.jar ($SIZE)${NC}"
        ((SUCCESS++))
    else
        echo -e "${RED}✗ $project/target/*.jar NO ENCONTRADO${NC}"
        ((FAILED++))
    fi
done

echo ""
echo "============================================"
echo "  RESUMEN"
echo "============================================"
echo -e "Exitosos: ${GREEN}$SUCCESS${NC}"
echo -e "Fallidos: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}¡Todos los proyectos compilados exitosamente!${NC}"
    echo ""
    echo "Siguiente paso: Ejecutar docker-compose"
    echo "  docker-compose up --build"
    exit 0
else
    echo -e "${RED}Algunos proyectos fallaron. Revisa los errores.${NC}"
    exit 1
fi
