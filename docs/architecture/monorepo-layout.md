# Auto Skola 365 - Monorepo Layout

Status: Draft  
Created: 2026-09-04

## Current Layout

```text
apps/
  admin_app/
  instructor_app/
  candidate_app/

backend/
packages/
docs/
```

## Apps

### apps/admin_app

Existing Flutter project moved here.

Target:

- Flutter Web for school admin.
- Later, SuperAdmin routes can live here if permission boundaries stay clean.

### apps/instructor_app

Placeholder for future Flutter mobile instructor app.

### apps/candidate_app

Placeholder for future Flutter mobile candidate app.

## Backend

### backend

Spring Boot backend service.

Chosen direction:

```text
Spring Boot + PostgreSQL
```

Possible structure:

```text
backend/
  src/main/java/...
  src/main/resources/
  src/test/java/...
  build.gradle.kts
  Dockerfile
```

## Shared Flutter Packages

### packages

Expected future packages:

- `api_client`
- `domain`
- `design_system`
- `auth`
- `calendar`

Create these only when real shared code exists. Avoid premature package
splitting before app boundaries are clearer.

## Workspace Tooling

The root `pubspec.yaml` defines a Dart workspace and currently includes:

```text
apps/admin_app
```

Additional Flutter/Dart packages should be added to the workspace when created.
The Java backend does not need to be part of the Dart workspace.
