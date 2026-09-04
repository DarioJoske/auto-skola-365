# Auto Skola 365 Coding Instructions

These instructions apply to the entire repository.

## Product Context

Auto Skola 365 is a SaaS platform for driving schools. The current applications are:

- `apps/admin_app`: Flutter Web admin app.
- `apps/instructor_app`: future Flutter instructor app.
- `apps/candidate_app`: future Flutter candidate app.
- `backend`: Java Spring Boot + PostgreSQL backend.

## Flutter Architecture

All Flutter apps must use:

- `go_router` for navigation.
- `flutter_bloc` with Cubit/BLoC for state management.
- `get_it` for dependency injection.
- `dio` for all HTTP/API calls.
- `dartz` `Either` for repository and use case success/failure results.
- Clean Architecture per feature.
- Repository interfaces in `domain`, implementations in `data`.
- API DTOs/models in `data`; domain entities in `domain`.
- UI widgets/pages in `presentation`.

Target feature structure:

```text
lib/src/
  app/
    router/
    theme/
  core/
    api/
    errors/
    storage/
    utils/
  features/
    <feature_name>/
      data/
        datasources/
        models/
        repositories/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        bloc/
        pages/
        widgets/
```

## Flutter Rules

- UI must not call HTTP clients directly.
- Widgets/pages may talk to Cubits/BLoCs only.
- Cubits/BLoCs call use cases.
- Use cases depend on domain repository interfaces.
- Use cases return `FutureEither<T>` or `Either<Failure, T>` for fallible work.
- Data repository implementations call remote/local data sources.
- Repositories catch data-source/API exceptions and return `Left(Failure)`.
- Cubits/BLoCs consume `Either` with helper methods; avoid raw unclear `fold`
  blocks when a named helper makes the intent clearer.
- API response/request models must not leak into presentation.
- Shared code goes into `core/` only after it is used by at least two features.
- Prefer immutable models with explicit `fromJson` and `toJson` methods unless code generation is introduced.
- Keep app-specific feature code inside that app until there is a clear need to extract it into `packages/`.
- Use Croatian labels for user-facing admin UI text unless a backend/domain identifier is intentionally English.

## Flutter Dependencies

Preferred dependencies:

- Routing: `go_router`
- State management: `flutter_bloc`, `bloc`
- Dependency injection: `get_it`
- Functional result type: `dartz`
- HTTP: `dio`
- Local simple storage: `shared_preferences`

Before adding a new dependency:

- Check whether an existing dependency already solves the problem.
- Keep dependency scope local to the app/package that uses it.
- Avoid adding global framework choices without updating `docs/architecture/flutter-architecture.md`.

## Backend Rules

- Use Spring Boot with PostgreSQL and Flyway migrations.
- Do not modify applied Flyway migrations; add a new `V<number>__description.sql` migration.
- Keep tenant/school scoping explicit in APIs.
- Protected endpoints must derive authorization from the authenticated user and active memberships/permissions.
- Keep DTOs separate from JPA entities at API boundaries.

## Verification

For Flutter changes:

```bash
dart format apps/admin_app/lib
flutter analyze apps/admin_app
```

For backend changes:

```bash
cd backend
mvn test
```

For schema/API changes, also run:

```bash
cd backend
mvn -DskipTests package
```
