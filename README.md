# Auto Skola 365

SaaS platform for driving schools.

## Repository Layout

```text
apps/
  admin_app/        Flutter Web/Desktop admin app
  instructor_app/   Future Flutter instructor app
  candidate_app/    Future Flutter candidate app

backend/            Spring Boot backend service
packages/           Shared Flutter/Dart packages
docs/
  product/          Product specs and scope
  architecture/     Architecture decisions, ERD and API design
```

## Current App

The existing Flutter project has been moved to:

```text
apps/admin_app
```

Run the admin app for web:

```bash
cd apps/admin_app
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080
```

Or as a browser-independent web server:

```bash
cd apps/admin_app
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5173 --dart-define=API_BASE_URL=http://localhost:8080
```

## Local Backend

Start PostgreSQL:

```bash
docker compose up -d postgres
```

Run the backend:

```bash
cd backend
mvn spring-boot:run
```

Useful URLs:

```text
http://localhost:8080/api/health
http://localhost:8080/swagger-ui.html
```

After backend schema changes, restart Spring Boot so Flyway can apply new
migrations.

## Documentation

- `docs/product/mvp-product-spec.md`
- `docs/architecture/erd.md`
- `docs/architecture/flutter-architecture.md`

## Coding Instructions

Repository-wide implementation rules live in `AGENTS.md`. Flutter work should
follow Clean Architecture with `go_router` and `flutter_bloc`.

## Backend Direction

The selected backend direction is Java Spring Boot + PostgreSQL. Firebase can be
introduced later for push notifications, analytics or crash reporting if needed.
