FROM openjdk:17-jdk-slim

WORKDIR /app

# Copiar el JAR
COPY target/eureka-server-1.0.0.jar app.jar

# Exponer puerto
EXPOSE 8761

# Variables de entorno
ENV JAVA_OPTS=""

# Comando de inicio
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
