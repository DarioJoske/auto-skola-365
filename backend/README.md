# Auto Skola 365 Backend

Spring Boot backend API for Auto Skola 365.

## Stack

```text
Java Spring Boot + PostgreSQL
```

Supporting choices:

- Java 17
- Spring Boot 3
- PostgreSQL
- Flyway migrations
- Spring Security
- Docker Compose for local PostgreSQL

## Local Database

From the repository root:

```bash
docker compose up -d postgres
```

## Run

Install Maven or add a Maven/Gradle wrapper, then run from `backend/`:

```bash
mvn spring-boot:run
```

Health endpoint:

```text
GET /api/health
```

Swagger UI:

```text
http://localhost:8080/swagger-ui.html
```

OpenAPI JSON:

```text
http://localhost:8080/v3/api-docs
```

Create initial school tenant:

```text
POST /api/platform/tenants
```

See `../docs/architecture/api.md` for the request payload.

## Planned Modules

- auth
- schools
- users
- roles
- candidates
- instructors
- lessons
- progress
- exams
- documents
- billing
- notifications
- audit
