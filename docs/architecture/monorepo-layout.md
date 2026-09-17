# Auto Skola 365 — struktura monorepa

Ažurirano: 2026-09-17.

```text
apps/
  admin_app/        Flutter administracijska aplikacija
  instructor_app/   Flutter Android/iOS instruktorska aplikacija
  candidate_app/    Flutter Android/iOS kandidatska aplikacija
packages/
  design_system/    Zajednička tema i UI komponente
backend/            Spring Boot + PostgreSQL + Flyway, Maven (pom.xml)
docs/               Produktna, arhitekturna i razvojna dokumentacija
pubspec.yaml        Dart workspace i Melos skripte
pubspec.lock        Zajedničko razrješavanje Dart/Flutter ovisnosti
```

## Aplikacije i zajednički kod

Sve tri aplikacije su implementirani Flutter paketi, s arhitekturom opisanom u
[Flutter odluci](flutter-architecture.md). Sve koriste
[design system](design-system.md). API, autentikacija i poslovne značajke ostaju
unutar aplikacija dok ne postoji stvarna potreba za stabilnim zajedničkim paketom.

## Razvojni alati

Root Dart workspace uključuje sve tri aplikacije i `packages/design_system`.
Svaki član deklarira `resolution: workspace`. Melos 8.6.0 konfiguriran je u
root pubspecu za provjere, testove i buildove. Naredbe i buduća poboljšanja
nalaze se u [Melos vodiču](../development/melos.md).

Backend nije član Dart workspacea. Melosova skripta `test:backend` samo poziva
postojeći `mvn test` iz njegovog direktorija.
