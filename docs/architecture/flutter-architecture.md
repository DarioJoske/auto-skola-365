# Auto Skola 365 - Flutter Architecture

Status: Decision  
Created: 2026-09-04

## Decision

All Flutter apps in Auto Skola 365 will use:

- Clean Architecture per feature.
- `go_router` for navigation.
- `flutter_bloc` with Cubit/BLoC for state management.
- `get_it` for dependency injection.
- `dio` for HTTP/API calls.
- `dartz` `Either` for fallible repository and use case results.
- A small `core` layer for shared app infrastructure.

This applies to:

- Admin Flutter Web app.
- Future instructor app.
- Future candidate app.

Detailed Flutter/Dart implementation and verification rules live in the repository
root [AGENTS.md](../../AGENTS.md) and apply to all existing and future apps.
Keep those rules and this architecture decision aligned; domain repository
interfaces, use cases and the selected stack remain required boundaries.

## Goals

- Keep every feature shaped the same way.
- Make backend API usage testable and replaceable.
- Prevent UI code from depending directly on HTTP, storage or DTO details.
- Keep future mobile apps aligned with the admin app.

## Target App Structure

```text
lib/src/
  app/
    router/
      app_router.dart
    theme/
      app_theme.dart
    app.dart
  core/
    api/
      api_client.dart
      api_exception.dart
      failure.dart
      result.dart
      result_extensions.dart
    errors/
    storage/
      token_storage.dart
    utils/
  features/
    auth/
      data/
        datasources/
          auth_remote_data_source.dart
        models/
          login_response_model.dart
          current_user_model.dart
        repositories/
          auth_repository_impl.dart
      domain/
        entities/
          current_user.dart
          membership.dart
        repositories/
          auth_repository.dart
        usecases/
          get_current_user.dart
          login.dart
          logout.dart
      presentation/
        bloc/
          auth_cubit.dart
          auth_state.dart
        pages/
          login_page.dart
        widgets/
    candidates/
      data/
      domain/
      presentation/
```

## Dependency Direction

Dependencies flow inward:

```text
presentation -> domain
data -> domain
app/core -> features through composition
```

Rules:

- `presentation` depends on Cubits/BLoCs and domain entities.
- `presentation` does not import API clients, DTOs or repositories from `data`.
- `domain` has no Flutter, HTTP or storage dependencies.
- `data` implements domain repository interfaces.
- `app` wires routing, themes and dependency composition.

## Feature Anatomy

Each feature should have these layers.

### Domain

Contains business-facing contracts:

- Entities.
- Repository interfaces.
- Use cases.

Domain objects should be stable and not mirror backend JSON unless that shape is
actually meaningful to the app.

### Data

Contains integration details:

- Remote data sources.
- Local data sources.
- API request/response models.
- Repository implementations.

Data models can have `fromJson` and `toJson`. Mapping from data models to domain
entities happens inside the data layer.

### Presentation

Contains UI and state:

- Pages.
- Widgets.
- Cubits/BLoCs.
- States.

Pages dispatch actions to Cubits/BLoCs. Cubits/BLoCs call use cases and expose
loading/success/error states.

Cubits/BLoCs consume use case results through named `Either` helpers from
`core/api/result_extensions.dart`.

## Routing

Use `go_router`.

Expected route groups:

```text
/login
/
/candidates
/candidates/:candidateId
/instructors
/lessons
/settings
```

Routing rules:

- Auth guard redirects unauthenticated users to `/login`.
- Authenticated users should not stay on `/login`.
- Current school context should be resolved after `/api/me`.
- Feature pages should not manually decide global auth redirects.

## State Management

Use `flutter_bloc`.

Default choices:

- Use `Cubit` for simple state transitions.
- Use full `Bloc` only when event history or richer event modeling helps.
- Keep state immutable.
- Use explicit states rather than boolean-heavy UI logic when flows grow.

Example state shape:

```dart
sealed class CandidatesState {}

class CandidatesInitial extends CandidatesState {}
class CandidatesLoading extends CandidatesState {}
class CandidatesLoaded extends CandidatesState {
  CandidatesLoaded(this.candidates);
  final List<Candidate> candidates;
}
class CandidatesFailure extends CandidatesState {
  CandidatesFailure(this.message);
  final String message;
}
```

## API And Auth

The backend uses JWT Bearer auth.

Frontend rules:

- Store the access token through a storage abstraction.
- Add `Authorization: Bearer <token>` in authenticated API calls.
- If API returns `401`, clear token and send user to login.
- `403` means authenticated but insufficient permission.
- UI should use permissions from `/api/me` to hide or disable unavailable
  actions.
- All HTTP calls use `dio` through the shared `ApiClient`.

## Dependency Injection

Use `get_it` as the app dependency container.

Rules:

- Register shared infrastructure first: `Dio`, `ApiClient`, `TokenStorage`.
- Register remote/local data sources.
- Register repository implementations as their domain interfaces.
- Register use cases.
- Register Cubits either as factories or explicit app-level instances when the
  router needs to observe them.
- Widgets should not construct repositories, data sources or API clients.

## Error Handling

Use shared failure/result helpers in `core/api`.

Minimum shape:

```dart
class Failure {
  const Failure(this.message, {this.statusCode});

  final String message;
  final int? statusCode;
}
```

Repository and use case contracts should return:

```dart
typedef Result<T> = Either<Failure, T>;
typedef FutureResult<T> = Future<Result<T>>;
typedef FutureEither<T> = Future<Result<T>>;
```

Prefer named helpers over ambiguous raw `Left` / `Right` construction:

```dart
Result<T> success<T>(T value) => Right(value);
Result<T> failure<T>(Failure failure) => Left(failure);
```

User-facing errors should be Croatian and action-oriented.

## Testing Expectations

For every new feature:

- Unit test use cases when they include branching business logic.
- Unit test Cubits/BLoCs for loading, success and failure states.
- Add widget tests for complex forms or permission-dependent UI.

For small scaffolding changes, `flutter analyze` is acceptable until the feature
has meaningful behavior.

## Current Implementation Status

The Admin app auth and candidates code has been refactored into:

```text
features/auth/{data,domain,presentation}
features/candidates/{data,domain,presentation}
core/{api,storage}
app/{router,theme}
```

The app now uses `go_router`, `flutter_bloc`, `get_it`, `dio` and `dartz` as
app-level dependencies.
