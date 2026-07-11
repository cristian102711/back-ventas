# back-ventas

Microservicio REST de **gestión de ventas y órdenes de compra** para la plataforma logística ITPCargo. Desarrollado con Spring Boot 3.4 + Java 17, conectado a Amazon RDS MySQL 8.0 mediante Spring Data JPA.

## Tecnologías

| Tecnología | Versión | Uso |
|---|---|---|
| Spring Boot | 3.4.4 | Framework REST |
| Java | 17 (Temurin) | Lenguaje |
| Spring Data JPA / Hibernate | — | ORM y acceso a BD |
| MySQL Connector/J | 9.1.0 | Driver JDBC |
| Lombok | 1.18.36 | Reducción de boilerplate |
| SpringDoc OpenAPI | 2.7.0 | Documentación Swagger |
| Maven | 3.9 | Build tool |

## Endpoints principales

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/api/v1/ventas` | Listar todas las órdenes de compra |
| POST | `/api/v1/ventas` | Crear nueva orden |
| GET | `/api/v1/ventas/{id}` | Obtener orden por ID |
| PUT | `/api/v1/ventas/{id}` | Actualizar orden |
| DELETE | `/api/v1/ventas/{id}` | Eliminar orden |
| GET | `/swagger-ui.html` | Documentación interactiva |

## Estructura del proyecto

```
Springboot-API-REST/
├── src/main/java/com/citt/
│   ├── controller/      # Controladores REST
│   ├── model/           # Entidades JPA
│   ├── repository/      # Interfaces Spring Data
│   └── service/         # Lógica de negocio
├── src/main/resources/
│   └── application.properties   # Configuración (variables de entorno)
├── Dockerfile           # Multi-stage: Maven → JRE Alpine
├── .dockerignore
└── pom.xml
```

## Ejecutar en desarrollo local

### Con Maven

```bash
# Requiere MySQL local o la variable DB_ENDPOINT apuntando a RDS
export DB_ENDPOINT=localhost
export DB_PORT=3306
export DB_NAME=innovatech
export DB_USERNAME=appuser
export DB_PASSWORD=Innovatech2025!

./mvnw spring-boot:run
# API disponible en http://localhost:8080
```

### Con Docker Compose (todos los servicios)

Desde la raíz del proyecto semestral:

```bash
docker compose up --build
# API disponible en http://localhost:8080
```

## Variables de entorno requeridas

| Variable | Descripción | Ejemplo |
|---|---|---|
| `DB_ENDPOINT` | Host de la base de datos | `innovatech-db.cmi1jz685kmy.us-east-1.rds.amazonaws.com` |
| `DB_PORT` | Puerto MySQL | `3306` |
| `DB_NAME` | Nombre de la base de datos | `innovatech` |
| `DB_USERNAME` | Usuario MySQL | `appuser` |
| `DB_PASSWORD` | Contraseña MySQL | — |
| `SPRING_DATASOURCE_URL` | URL JDBC completa (overrides application.properties) | Ver nota abajo |

> ⚠️ **Nota importante:** MySQL 8.0 en Amazon RDS usa el plugin `caching_sha2_password` por defecto. El conector MySQL 9.x requiere `allowPublicKeyRetrieval=true` en la URL JDBC. Configurar esta variable de entorno en la Task Definition:
> ```
> SPRING_DATASOURCE_URL=jdbc:mysql://[DB_ENDPOINT]:3306/innovatech?allowPublicKeyRetrieval=true&useSSL=false&serverTimezone=UTC
> ```

## Dockerfile — explicación multi-stage

```dockerfile
# Stage 1: Compilación con Maven
FROM maven:3.9-eclipse-temurin-17 AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -B   # cachea dependencias
COPY src ./src
RUN mvn package -DskipTests        # genera el JAR ejecutable

# Stage 2: Solo JRE Alpine (imagen mínima ~150 MB vs ~500 MB con JDK)
FROM eclipse-temurin:17-jre-alpine AS production
WORKDIR /app
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser   # usuario no root — principio de mínimo privilegio
COPY --from=builder /app/target/Springboot-API-REST-0.0.1-SNAPSHOT.jar app.jar
EXPOSE 8080
CMD ["java", "-jar", "app.jar"]
```

## CI/CD con GitHub Actions

El pipeline se activa con cada push a la rama `deploy`:

```
Push a deploy
  → Checkout código
  → Configurar credenciales AWS (GitHub Secrets)
  → Login en Amazon ECR
  → docker build + docker push → ECR :latest
  → aws ecs update-service --force-new-deployment
```

**Secrets requeridos:**

| Secret | Descripción |
|---|---|
| `AWS_ACCESS_KEY_ID` | Clave de acceso AWS Academy |
| `AWS_SECRET_ACCESS_KEY` | Clave secreta AWS Academy |
| `AWS_SESSION_TOKEN` | Token de sesión (obligatorio en Academy) |

## Despliegue en AWS (ECS Fargate)

| Recurso | Valor |
|---|---|
| Clúster ECS | `innovatech-cluster` |
| Servicio | `back-ventas-service` |
| Task Definition | `back-ventas-task:2` |
| Repositorio ECR | `326709309665.dkr.ecr.us-east-1.amazonaws.com/back-ventas` |
| CPU / Memoria | 256 vCPU / 512 MiB |
| Puerto expuesto | 8080 |
| Ruta ALB | `/api/v1/ventas*` → `back-ventas-tg` |

## Commits convencionales

```
feat: initial commit - Spring Boot Ventas con Dockerfile multi-stage
fix: force remove conflicting back-ventas container before compose up
docs: agregar README profesional del back-ventas
ci: agregar pipeline GitHub Actions para build y push automático
```

## Autores

- **Cristian Velásquez** — ISY1101 Introducción a Herramientas DevOps · DuocUC Las Condes · 2026
