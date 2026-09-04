# Backend Options - Firebase vs Spring Boot + PostgreSQL

Status: Decided  
Created: 2026-09-04
Decision date: 2026-09-04

## Context

Auto Skola 365 needs a backend for a business SaaS platform with:

- Multiple user roles.
- School-scoped permissions.
- Candidates, instructors, lessons, progress, exams, documents and payments.
- Calendar conflict validation.
- Audit logs and reporting.
- Flutter Web admin app and Flutter mobile apps.

The evaluated shortlist was:

- Firebase.
- Java Spring Boot + PostgreSQL.

## Option A: Firebase

Firebase means using a managed backend stack, likely:

- Firebase Authentication.
- Cloud Firestore.
- Cloud Functions.
- Firebase Storage.
- Firebase Cloud Messaging.
- Firebase Hosting, optionally.

### Advantages

- Very fast MVP setup.
- Excellent Flutter integration.
- Built-in auth and push notifications.
- Real-time updates are simple.
- Less infrastructure work at the beginning.
- Good fit for chat, notifications and mobile-first features.
- Easy local prototype without designing a full backend from day one.

### Disadvantages

- Complex relational data becomes harder to model and query.
- Reporting across candidates, lessons, payments and instructors is weaker than
  SQL.
- School-scoped authorization rules can become difficult to reason about as the
  product grows.
- Calendar conflict validation needs careful transaction design.
- Business logic can spread between security rules, client code and functions.
- Vendor lock-in is higher.
- Migrations and data evolution are less explicit than PostgreSQL migrations.
- Advanced admin reporting may require exporting data to BigQuery or another
  analytics layer.

### Best Fit

Firebase is best if the priority is speed, prototype velocity and mobile
features, and if the first version is relatively simple:

- One or a few driving schools.
- Lightweight admin workflows.
- Real-time communication is important early.
- Reporting and billing are not central in the first releases.

## Option B: Java Spring Boot + PostgreSQL

This option means a custom backend API with:

- Spring Boot.
- PostgreSQL.
- JPA/Hibernate or jOOQ.
- Flyway or Liquibase migrations.
- Spring Security.
- Docker-based local development.

### Advantages

- Strong fit for relational business data.
- PostgreSQL is excellent for reporting, filtering and data integrity.
- Clear ownership of business rules in the backend.
- Better long-term fit for scheduling, audit logs, permissions and billing.
- Explicit migrations and predictable schema evolution.
- Easier to enforce school-scoped access consistently.
- Easier to integrate later with accounting, government/compliance systems or
  external APIs.
- Java/Spring ecosystem is mature and stable for business SaaS platforms.

### Disadvantages

- Slower initial setup than Firebase.
- More backend code to write before the app feels useful.
- Requires hosting, deployment, monitoring and database operations.
- Real-time features and push notifications need additional integration.
- Flutter integration is straightforward, but not as turnkey as Firebase.
- More engineering discipline is needed from day one.

### Best Fit

Spring Boot + PostgreSQL is best if the product is intended to become a serious
business platform:

- Multi-school SaaS is likely.
- Admin operations are central.
- Scheduling rules must be reliable.
- Reporting and billing matter.
- Data integrity and auditability are important.
- The system may need compliance-oriented features.

## Recommendation

For Auto Skola 365, the stronger long-term default is:

```text
Spring Boot + PostgreSQL
```

Reason:

The core of this product is not only mobile convenience. It is operational
business management: candidates, instructors, lessons, schedules, progress,
payments, documents, exams, permissions and reports. That shape fits a
relational backend better than a document-first backend.

Firebase is still useful later for:

- Push notifications through Firebase Cloud Messaging.
- Mobile analytics.
- Crash reporting.
- Possibly chat or real-time presence if needed.

## Proposed Architecture If Using Spring Boot

```text
Flutter Web Admin
Flutter Instructor App
Flutter Candidate App
        |
        v
Spring Boot REST API
        |
        v
PostgreSQL
```

Supporting services:

- Firebase Cloud Messaging for push notifications.
- S3-compatible storage for documents.
- Redis later for queues/cache if needed.
- Docker Compose for local development.

## Initial Backend Modules

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

## Decision

Confirmed decision:

- Use Spring Boot + PostgreSQL for the core backend.
- Use Firebase selectively for mobile-support services, especially push
  notifications.

This keeps the business core explicit and relational while still benefiting from
Firebase where it is strongest.
