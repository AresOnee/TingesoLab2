FROM eclipse-temurin:17-jdk-alpine

WORKDIR /app

# Copiar el JAR
COPY target/api-gateway-1.0.0.jar app.jar

# Exponer puerto
EXPOSE 8080

# Variables de entorno
ENV JAVA_OPTS=""

# Comando de inicio
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
