FROM eclipse-temurin:17-jdk-alpine

WORKDIR /app

# Copiar el JAR
COPY target/config-server-1.0.0.jar app.jar

# Exponer puerto
EXPOSE 8888

# Variables de entorno
ENV JAVA_OPTS=""

# Comando de inicio
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
