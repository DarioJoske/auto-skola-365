# Auto Skola 365

SaaS platform for driving schools.

## Repository Layout

```text
apps/
  admin_app/        Flutter Web/Desktop admin app
  instructor_app/   Flutter Android/iOS instructor app
  candidate_app/    Flutter Android/iOS candidate app

backend/            Spring Boot backend service
packages/           Shared Flutter/Dart packages
docs/
  product/          Product specs and scope
  architecture/     Architecture decisions, ERD and API design
```

## Admin App

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

## Monorepo Tooling

Use Dart from the project's Flutter SDK (Dart >=3.9.2, <4.0.0). From the repository root:

```bash
dart pub global activate melos
flutter pub get
melos --version
melos list
melos run check
```

The globally activated launcher uses the workspace's pinned Melos 8.6.0.
If `melos` is not found, add `$HOME/.pub-cache/bin` to `PATH` on macOS/Linux
(or `$PUB_CACHE/bin` when a custom cache is configured). Alternatively, run
`dart run melos` from the repository root.

Daily commands: `melos run format`, `melos run check:design-system`,
`melos run build:web`, `melos run dev:candidate`, and `melos run test:backend`.
`build:web` builds only the admin app. Candidate and instructor apps target
Android/iOS only. Set `CANDIDATE_DEVICE_ID` to a mobile device ID from
`flutter devices` before running `dev:candidate`; see the
[candidate guide](apps/candidate_app/README.md) for API configuration.
The `check` script checks formatting without changing files, then analyzes and
tests all four Flutter packages. Backend tests and builds are separate commands.

See the [Melos guide](docs/development/melos.md) for all commands, setup details,
and improvements to consider as the project grows.

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

Repository-wide implementation rules live in [AGENTS.md](AGENTS.md). Its shared
Flutter/Dart guidelines apply to every app under `apps/` (admin, instructor,
candidate and future apps) and to relevant shared code under `packages/`.
They cover Clean Architecture, Bloc/Cubit conventions, state and concurrency,
widget lifecycle, error handling and verification in each affected package.
Maintain these rules in the root file; app-local instructions are only needed
for app-specific additions.

## Backend Direction

The selected backend direction is Java Spring Boot + PostgreSQL. Firebase can be
introduced later for push notifications, analytics or crash reporting if needed.
