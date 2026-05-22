# =============================================
# STAGE 1: Build con Maven
# =============================================
FROM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /app

# Copiamos pom.xml para cachear dependencias
COPY pom.xml .

# Descargamos dependencias
RUN mvn dependency:go-offline -B

# Copiamos el código fuente
COPY src ./src

# Construimos el JAR
RUN mvn package -DskipTests

# =============================================
# STAGE 2: Run solo con JRE liviano
# =============================================
FROM eclipse-temurin:17-jre-alpine AS production

WORKDIR /app

# Usuario no root (seguridad - rúbrica IE1)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

COPY --from=builder /app/target/Springboot-API-REST-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8080

CMD ["java", "-jar", "app.jar"]