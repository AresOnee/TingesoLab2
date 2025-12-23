# ToolRent Microservicios - FASE 2

## 📋 Resumen de Microservicios

| Microservicio | Puerto | Base de Datos | Épica |
|---------------|--------|---------------|-------|
| ms-tools | dinámico | tools_db (3307) | Épica 1: Gestión de Herramientas |
| ms-clients | dinámico | clients_db (3308) | Épica 3: Gestión de Clientes |
| ms-config | dinámico | config_db (3309) | Épica 4: Tarifas y Configuración |
| ms-kardex | dinámico | kardex_db (3311) | Épica 5: Kardex y Movimientos |
| ms-loans | dinámico | loans_db (3310) | Épica 2: Préstamos y Devoluciones |
| ms-reports | dinámico | (sin BD) | Épica 6: Reportes |
| ms-users | dinámico | users_db (3312) | Épica 7: Usuarios |

## 🏗️ Arquitectura

```
                    ┌─────────────────┐
                    │  Config Server  │ :8888
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │  Eureka Server  │ :8761
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
     Frontend  ───► │   API Gateway   │ :8080
                    └────────┬────────┘
                             │
         ┌───────┬───────┬───┴───┬───────┬───────┬───────┐
         ▼       ▼       ▼       ▼       ▼       ▼       ▼
     ms-tools ms-clients ms-config ms-kardex ms-loans ms-reports ms-users
         │       │       │       │       │               │
         ▼       ▼       ▼       ▼       ▼               ▼
     MySQL    MySQL    MySQL   MySQL   MySQL          MySQL
     3307     3308     3309    3311    3310           3312
```

## 🚀 Instrucciones de Compilación

### Prerrequisitos
- Java 17+
- Maven 3.8+
- Docker Desktop

### Paso 1: Compilar todos los proyectos

```bash
cd toolrent-microservices
chmod +x build-all.sh
./build-all.sh
```

O manualmente:

```bash
# Infraestructura
cd config-server && mvn clean package -DskipTests && cd ..
cd eureka-server && mvn clean package -DskipTests && cd ..
cd api-gateway && mvn clean package -DskipTests && cd ..

# Microservicios
cd ms-tools && mvn clean package -DskipTests && cd ..
cd ms-clients && mvn clean package -DskipTests && cd ..
cd ms-config && mvn clean package -DskipTests && cd ..
cd ms-kardex && mvn clean package -DskipTests && cd ..
cd ms-loans && mvn clean package -DskipTests && cd ..
cd ms-reports && mvn clean package -DskipTests && cd ..
cd ms-users && mvn clean package -DskipTests && cd ..
```

### Paso 2: Ejecutar con Docker Compose

```bash
docker-compose up --build
```

Espera aproximadamente 3-5 minutos para que todos los servicios inicien.

### Paso 3: Verificar servicios

- **Eureka Dashboard:** http://localhost:8761
  - Debes ver todos los microservicios registrados

- **Config Server:** http://localhost:8888/actuator/health

- **API Gateway:** http://localhost:8080/actuator/health

## 📡 Endpoints del API Gateway

### Herramientas (ms-tools)
```
GET    /api/v1/tools/           # Listar todas
GET    /api/v1/tools/{id}       # Obtener por ID
POST   /api/v1/tools/           # Crear herramienta
PUT    /api/v1/tools/{id}       # Actualizar
PUT    /api/v1/tools/{id}/decommission  # Dar de baja
```

### Clientes (ms-clients)
```
GET    /api/v1/clients/         # Listar todos
GET    /api/v1/clients/{id}     # Obtener por ID
POST   /api/v1/clients/         # Crear cliente
PUT    /api/v1/clients/{id}     # Actualizar
PUT    /api/v1/clients/{id}/state  # Cambiar estado
```

### Configuración (ms-config)
```
GET    /api/v1/config/          # Listar configuraciones
GET    /api/v1/config/tarifa-arriendo  # Tarifa de arriendo
GET    /api/v1/config/tarifa-multa     # Tarifa de multa
PUT    /api/v1/config/tarifa-arriendo  # Actualizar tarifa arriendo
PUT    /api/v1/config/tarifa-multa     # Actualizar tarifa multa
```

### Préstamos (ms-loans)
```
GET    /api/v1/loans/           # Listar todos
GET    /api/v1/loans/active     # Préstamos activos
POST   /api/v1/loans/create     # Crear préstamo
POST   /api/v1/loans/return     # Registrar devolución
```

### Kardex (ms-kardex)
```
GET    /api/v1/kardex/          # Listar movimientos
GET    /api/v1/kardex/tool/{id} # Movimientos por herramienta
POST   /api/v1/kardex/          # Registrar movimiento
```

### Reportes (ms-reports)
```
GET    /api/v1/reports/active-loans        # Préstamos activos
GET    /api/v1/reports/clients-with-overdues  # Clientes con atrasos
GET    /api/v1/reports/most-loaned-tools   # Ranking herramientas
```

### Usuarios (ms-users)
```
GET    /api/v1/users/           # Listar usuarios
GET    /api/v1/users/{id}       # Obtener por ID
POST   /api/v1/users/           # Crear usuario
```

## 🗄️ Seed Data

Los datos de prueba se cargan automáticamente al iniciar las bases de datos.
Ver archivos en `/seed-data/`:

- `01-tools-seed.sql` - 19 herramientas
- `02-clients-seed.sql` - 9 clientes (7 activos, 2 restringidos)
- `03-config-seed.sql` - 3 configuraciones de tarifas
- `04-loans-seed.sql` - 18 préstamos históricos
- `05-kardex-seed.sql` - 24 movimientos de inventario
- `06-users-seed.sql` - 5 usuarios

## 🔄 Comunicación entre Microservicios

Los microservicios se comunican usando **RestTemplate con @LoadBalanced**:

```java
// En ms-loans para obtener datos de ms-tools
String url = "http://ms-tools/api/v1/tools/" + toolId;
ToolDTO tool = restTemplate.getForObject(url, ToolDTO.class);
```

La resolución de nombres se hace automáticamente a través de Eureka.

## 📊 Flujo de Préstamo (Ejemplo)

1. **Cliente solicita préstamo** → `POST /api/v1/loans/create`
2. **ms-loans** consulta **ms-clients** para validar estado del cliente
3. **ms-loans** consulta **ms-tools** para verificar disponibilidad
4. **ms-loans** consulta **ms-config** para obtener tarifa
5. **ms-loans** crea el préstamo
6. **ms-loans** actualiza stock en **ms-tools**
7. **ms-loans** registra movimiento en **ms-kardex**

## ⚠️ Notas Importantes

1. **Encoding UTF-8:** Todos los seed data usan `SET NAMES utf8mb4` para caracteres especiales
2. **Puertos dinámicos:** Los microservicios usan `port: 0` (asignación dinámica)
3. **Health Checks:** Usar `wget` en lugar de `curl` (imagen Alpine)
4. **Dependencias:** ms-loans depende de ms-tools, ms-clients, ms-config, ms-kardex

## 🛠️ Troubleshooting

### Error: "Connection refused"
- Verificar que todos los contenedores estén corriendo: `docker ps`
- Verificar logs: `docker-compose logs -f [servicio]`

### Error: "Service unavailable"
- Esperar a que los servicios se registren en Eureka (~2 min)
- Verificar Eureka Dashboard: http://localhost:8761

### Error de encoding (tildes)
- Verificar que MySQL use `utf8mb4_unicode_ci`
- Los seed data incluyen `SET NAMES utf8mb4`
