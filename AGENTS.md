# Auto Skola 365 Coding Instructions

These instructions apply to the entire repository.

Flutter/Dart sections apply to every existing and future Flutter application under
`apps/`, including `admin_app`, `instructor_app` and `candidate_app`, and to shared
Dart/Flutter code under `packages/` where relevant. Flutter widget rules apply only
to Flutter code; backend-specific rules apply to `backend/`.

Keep shared instructions in this root file so work started from the repository
root or an application directory uses the same guidance. App-local `AGENTS.md`
files, if needed, should contain only app-specific additions. Keep architectural
rules aligned with [the Flutter architecture decision](docs/architecture/flutter-architecture.md).

## Product Context

Auto Skola 365 is a SaaS platform for driving schools. The current applications are:

- `apps/admin_app`: Flutter Web admin app.
- `apps/instructor_app`: Flutter instructor app.
- `apps/candidate_app`: Flutter candidate app.
- `backend`: Java Spring Boot + PostgreSQL backend.

## Working Agreements

- Explain decisions, changes and verification results in Croatian.
- Write identifiers and code comments in English; follow the project's localization conventions for user-facing text.
- Keep changes focused on the requested task and preserve established project conventions.
- Before Flutter/Dart implementation, inspect the affected package's `pubspec.yaml`, the workspace `pubspec.lock`, applicable `analysis_options.yaml`, SDK configuration, relevant CI scripts and a representative existing feature and test when available.
- Use the SDK and dependency versions configured in the repository. Check documentation against those versions when an API is uncertain.
- Prefer an existing, well-maintained implementation in this repository as the reference for new features.
- Proceed with routine, reversible implementation decisions. Ask for clarification when missing product requirements materially affect behavior.

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

- Organize new code by feature, following the repository's actual directory structure.
- Separate presentation, business logic and data access. Widgets render state and forward user interactions; blocs and cubits coordinate behavior through domain use cases.
- Access network, database and storage operations through the data layer. Keep SDK-specific details out of widgets and state management classes.
- Inject dependencies through constructors. Compose dependencies with the existing `get_it` setup and expose Cubits/BLoCs to widgets with `BlocProvider`; providers do not replace the app dependency container.
- Keep domain entities, repository interfaces and use cases as required Clean Architecture boundaries. Avoid additional abstraction layers without a concrete purpose.
- Keep dependencies between layers explicit. Do not pass `BuildContext` into blocs, cubits, repositories or domain services.
- Avoid direct dependencies between blocs. Coordinate shared data through use cases backed by reactive repositories, or use presentation-layer listeners to forward relevant events.
- Reuse existing shared widgets and utilities; promote feature code to `core/` only after at least two features use it.

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

- Use `flutter_bloc` for application state management. Keep Bloc and Cubit implementation files independent of Flutter, using `package:bloc/bloc.dart` with an appropriate declared dependency.
- Use Bloc when explicit events, transition traceability or event transformations are valuable. Use Cubit when direct methods adequately express the state changes.
- Preserve the established Bloc/Cubit convention within an existing feature.
- Do not introduce Riverpod packages, providers or generators. Migrate existing state management only when the task includes that migration.
- Preserve the required stack above and the Spring Boot/PostgreSQL backend. New applications use the same stack; do not substitute another router, HTTP client, dependency container or backend.
- Preserve the project's model and equality approach, such as Freezed or ordinary Dart classes with Equatable. Do not add code generation solely to follow a template.
- Flutter Hooks is optional and independent of the Bloc choice. Follow existing usage; do not introduce `hooks_riverpod`.
- Add dependencies when the implementation needs them, following repository policy. Avoid unrelated upgrades and duplicate libraries for the same responsibility.

## Bloc and Cubit API conventions

- Send external Bloc events through `add()`. Keep event handlers and implementation helpers private; avoid custom public action methods on blocs.
- Expose Cubit methods for state-changing actions, normally returning `void` or `Future<void>`. Expose results through state rather than a separate return-value workflow.
- Keep repositories, subscriptions and other implementation details private.
- Name events after occurrences, using the feature subject and an appropriate past-tense verb: `LoginSubmitted`, `SearchQueryChanged`, `ProfileStarted`.
- Use `<Feature>Event` and `<Feature>State` for roots and descriptive names for variants. Preserve established naming in existing features.
- Repository updates may trigger private internal events when event transformations are needed. Do not create chains of internal events when a private helper expresses the same operation clearly.

## State modeling and equality

- Model state according to the screen's behavior rather than imposing one representation everywhere.
- Use a single immutable state with status fields when operations share data or can overlap, such as displaying existing results while refreshing or reporting a refresh failure.
- Use a sealed hierarchy when states are mutually exclusive and contain distinct required data.
- Represent initial, loading, success, empty and failure conditions where relevant. An empty successful result does not necessarily require a separate state class.
- Preserve existing data during refresh or recoverable errors when required by the UX. Avoid replacing every operation with a full-screen loading state.
- Keep emitted states and their nested data immutable. Create new collections when updating data, and prevent callers from mutating collections exposed by state.
- Follow the project's value-equality convention. With Equatable, include all state properties that participate in observable behavior in `props`.
- Remember that equal consecutive states are generally suppressed. Model repeated user-visible effects explicitly when each occurrence must be observed.
- Class modifiers do not provide value equality, `copyWith`, serialization or deep immutability. Implement or generate these separately when needed.

## Class modifiers

- Use `sealed` roots and `final` leaf variants for closed event/state hierarchies. A sealed class is already abstract; do not combine `abstract` and `sealed`.
- Keep a sealed root and its direct subtypes in the same Dart library: one file or files connected through `part` and `part of`. An ordinary import or a shared folder does not make them one library.
- Prefer exhaustive switches when every variant needs explicit handling. Avoid a catch-all branch that would hide a newly added variant unless that fallback behavior is intentional.
- Sealed events do not automatically verify that all required `on<E>` handlers have been registered. Verify event behavior through implementation and tests.
- Use `abstract interface class` for replaceable repository/service contracts when an interface is useful.
- Use `final class` for concrete models, implementations and widgets that should not be extended or implemented outside their defining library.
- Preserve the ability to implement Bloc/Cubit classes in tests when the project uses `MockBloc` or `MockCubit`. Do not mark these classes `final` or `base` automatically.
- Use `abstract class` for an intentionally extensible abstraction with optional shared implementation.
- Use `base` only when inheriting the implementation is an explicit requirement. Its restrictions propagate to subtypes, which must use compatible modifiers.
- Use `mixin` for behavior reused through `with`; use `mixin class` only when both class and mixin usage are intended.
- Treat `final class`, final fields and const values as separate decisions. In particular, a final collection reference does not make its contents immutable.
- Before tightening a public class's modifiers, check existing subtypes, generated code and test doubles. Follow the installed generator's supported syntax and the project's Dart language version.

## Asynchronous work and event concurrency

- Bloc event handlers are concurrent by default. Choose concurrency deliberately whenever overlapping work can affect correctness.
- Apply transformers per `on<E>` registration. Separate registrations remain independent; `sequential()` on multiple event types does not create one global queue.
- Use `restartable()` when only the latest event's result should be applied, such as an asynchronous search.
- Use `sequential()` when every event must finish in order within the relevant handler registration.
- Use `droppable()` when additional triggers should be ignored while an operation is running.
- Use `concurrent()` when operations can safely overlap. Use `bloc_concurrency` when its transformers are needed; it is not a mandatory dependency for every feature.
- Treat debounce/throttle, handler cancellation and network cancellation separately. `restartable()` is not debounce and does not automatically cancel the underlying HTTP request.
- Ensure stale results cannot overwrite newer state. Cubits need their own overlap policy because they do not use Bloc event transformers.
- Await or return asynchronous work that uses `emit`, including `emit.forEach` and `emit.onEach`. Do not leave callbacks that emit after their handler has completed.
- Check `emit.isDone` after asynchronous boundaries where cancellation can invalidate continued work. For Cubits, account for closure and superseded requests as appropriate; `isClosed` alone does not prevent stale results.
- Cancel manually owned stream subscriptions and release owned resources in `close()`. Do not dispose dependencies owned by another scope.
- Translate expected failures into appropriate state and user-facing messages. Follow existing error reporting for diagnostics, preserving useful exception and stack-trace information.

## Flutter integration, lifecycle and navigation

- Keep `BlocBuilder` callbacks free of side effects. Do not initiate requests, dispatch events or navigate from builders.
- Use `BlocListener` for reactions to state changes, such as snackbars, dialogs and navigation. Use `listenWhen` when only a particular transition should trigger the effect.
- A listener does not run for the initial state. Handle startup/authentication routing explicitly through the existing router or application initialization flow.
- Use `BlocConsumer` only when the same component needs both UI rebuilding and state-change reactions.
- Use `BlocSelector` or `context.select` for focused subscriptions when useful. Selected values must be immutable; use `buildWhen` as a rebuild optimization, not as a substitute for valid state handling.
- Use `context.read` in callbacks to obtain a bloc and dispatch events or call Cubit methods. Use a reactive subscription when displayed values must update.
- Create blocs through `BlocProvider(create: ...)` at the narrowest appropriate scope. It closes instances it creates. Its creation is lazy by default; use `lazy: false` only when eager initialization is needed.
- Use `BlocProvider.value` for an existing instance. The original owner remains responsible for closing it.
- Dispose repository resources through their owning scope, using `RepositoryProvider.dispose` where appropriate.
- Keep controllers, focus, animations and other temporary widget state local unless the feature requires sharing or persistence. Dispose manually created resources.
- After asynchronous UI work, verify the relevant context/widget is still mounted before using it.
- Preserve the existing routing architecture. Connect authentication updates without unnecessarily recreating the router or losing navigation state.
- Check navigation code against the installed router API. For modern GoRouter path checks, use `state.uri.path` rather than obsolete `state.location` examples.

## Flutter UI and Dart style

- Prefer composition, small focused widgets and existing design-system components.
- Use descriptive names, such as `isLoading`, `canSubmit` and `hasReachedEnd`.
- Use const constructors and const expressions where applicable. Let the configured Dart formatter and analyzer enforce formatting and style.
- Follow the project's Freezed/JSON generation conventions; keep transport serialization concerns in the appropriate data layer.
- Use theme colors, typography and spacing conventions consistently, including loading, empty and error states.
- Follow localization conventions rather than introducing hard-coded user-facing strings into a localized application.
- Build responsive layouts with appropriate constraints, `LayoutBuilder` or `MediaQuery`. Account for text scaling and accessibility.
- Use lazy list builders for large collections and provide suitable image loading/error behavior. Follow the existing image caching approach.
- Configure text fields with appropriate keyboard types, capitalization and input actions.
- Use the existing logging or BlocObserver setup for diagnostics. Avoid adding ad hoc print statements or exposing raw internal errors in the UI.

## Backend Rules

- Use Spring Boot with PostgreSQL and Flyway migrations.
- Do not modify applied Flyway migrations; add a new `V<number>__description.sql` migration.
- Keep tenant/school scoping explicit in APIs.
- Protected endpoints must derive authorization from the authenticated user and active memberships/permissions.
- Keep DTOs separate from JPA entities at API boundaries.

## Error Handling

- Backend APIs must return structured JSON errors with `status`, `code`,
  `message`, and `path`.
- Backend domain, validation, authorization, and database constraint failures
  must be mapped to explicit HTTP statuses and user-safe messages.
- Frontend API clients must preserve backend `status`, `code`, and `message`
  in `Failure`.
- UI must visibly surface every backend failure: mutation failures as snackbars,
  load failures as inline error states with retry, and auth failures with a clear
  session-expired message before redirect.
- Do not swallow backend errors silently. Empty `catch` blocks, ignored `Left`
  values, or generic fallback-only UI are not allowed unless the backend
  response is genuinely unavailable.

## Verification

### Flutter/Dart code and generated code

Run checks for every affected app or shared package, not only `admin_app`. Run the
following commands from that package's root (for example `apps/admin_app` or
`apps/instructor_app`), using the configured SDK wrapper when one exists:

```bash
dart format lib
flutter analyze
```

Also format changed Dart test files and run the relevant `flutter test` targets.
Run `flutter test` for the whole package when its complete suite is relevant and a
`test/` directory exists. Use `dart analyze` and `dart test` for pure Dart packages.
When changing shared code, also check the affected consuming applications.
These checks also apply to `candidate_app`. Documentation-only changes require review of
instruction consistency, local links and `git diff --check` rather than SDK checks.

- For changed Bloc/Cubit business behavior, use `bloc_test` to verify initial state separately and meaningful emitted-state sequences after actions. Add a compatible app-local dev dependency when needed; existing tests may retain their fake implementations and assertion style.
- Cover relevant success, failure, retry, overlapping-event and stale-response scenarios. Verify data preservation during refresh or failure when required.
- Use the project's existing mocking library and fake implementations. Do not switch between Mockito and Mocktail without a task-related reason.
- Add widget tests for meaningful rendering, interactions and listener effects. Use integration tests for flows that require multiple components or platform behavior.
- Avoid tests that only repeat implementation details and do not protect observable behavior.
- Format changed Dart files, run `flutter analyze` from the appropriate package root and run the relevant `flutter test` targets. Run any additional checks required by the repository or CI.
- Use the configured SDK wrapper, such as FVM, and monorepo scripts when the project requires them.
- Regenerate code after changing annotated sources when code generation is configured. Prefer the repository script; otherwise use its supported `build_runner` command, commonly `dart run build_runner build --delete-conflicting-outputs`.
- Do not manually edit generated files such as `*.freezed.dart`, `*.g.dart` or generated mock files. Follow the repository's policy for committing generated outputs.
- If Bloc linting is configured, run the project's lint command, commonly `bloc lint .`. Useful rules include `avoid_flutter_imports` and `avoid_public_bloc_methods`.
- Preserve existing analysis configuration when adding lint rules. `bloc_lint` and `bloc_tools` are optional, not prerequisites for ordinary changes.
- Report what changed, which checks actually ran, their results and any unresolved limitations. Do not claim verification that was not performed.

### Backend

For backend changes, run from the repository root:

```bash
cd backend
mvn test
```

For schema/API changes, also run from `backend/`:

```bash
mvn -DskipTests package
```

## Official Flutter/Dart References

Consult the relevant section when needed, matching examples to the repository's installed versions:

- [Bloc concepts and Bloc/Cubit tradeoffs](https://bloclibrary.dev/bloc-concepts/)
- [Architecture and communication between blocs](https://bloclibrary.dev/architecture/)
- [State modeling](https://bloclibrary.dev/modeling-state/)
- [Flutter widgets, providers and lifecycle](https://bloclibrary.dev/flutter-bloc-concepts/)
- [Naming conventions](https://bloclibrary.dev/naming-conventions/)
- [FAQs and public API conventions](https://bloclibrary.dev/faqs/)
- [Event concurrency](https://pub.dev/documentation/bloc_concurrency/latest/)
- [Testing](https://bloclibrary.dev/testing/)
- [Bloc lint configuration](https://bloclibrary.dev/lint/configuration/)
- [Dart class modifiers](https://dart.dev/language/class-modifiers)
- [Dart libraries](https://dart.dev/language/libraries)
