# Auto Skola 365 - SuperAdmin App

Status: Draft  
Created: 2026-09-04

## Purpose

The SuperAdmin app is the internal platform administration surface for the SaaS
operator. It is not used by a driving school office. It is used to manage the
whole Auto Skola 365 platform across all tenant schools.

## Difference Between Admin And SuperAdmin

### Admin App

Used by a driving school owner or office staff.

Scope:

- One driving school.
- That school's candidates, instructors, lessons, documents and payments.
- Daily business operations.

### SuperAdmin App

Used by the platform owner/operator.

Scope:

- All driving schools on the platform.
- Tenant lifecycle.
- Subscription and billing status.
- Support tooling.
- System health.
- Global configuration.
- Compliance and audit visibility.

## Recommended MVP Timing

Do not build a full SuperAdmin app first.

For the first MVP, build only the minimum SuperAdmin capability needed to operate
the platform safely:

- Create a school tenant.
- Create the first owner/admin user for that school.
- Activate/deactivate a school.
- View basic school metadata.

Everything else can come after the school admin workflows are validated.

## SuperAdmin MVP Features

### Tenant Management

- List schools.
- Create school.
- Edit school metadata.
- Activate, suspend or archive school.
- Configure supported categories per school.
- Configure branch records.

### Initial User Provisioning

- Create first owner/admin user for a school.
- Reset invite or password flow.
- See school memberships.
- Disable a user in urgent support cases.

### Basic Support View

- Search school by name, OIB or owner email.
- Open a read-only operational summary.
- See active instructors and candidate counts.
- See recent lesson activity.
- See recent audit log events.

### Platform Configuration

- Manage global driving categories.
- Manage default progress templates.
- Manage default role templates.
- Manage feature flags later.

### Audit And Compliance

- View global audit logs.
- Filter by school, user, entity and action.
- Support incident investigation.

## Features To Defer

- Subscription billing automation.
- Usage-based billing.
- Advanced analytics.
- Impersonation.
- Global reports.
- Support ticketing.
- Tenant data export.
- Tenant deletion automation.

## Impersonation Warning

Impersonation is useful for support, but it is sensitive.

If implemented later, it should require:

- Explicit SuperAdmin permission.
- Reason field.
- Time-limited session.
- Audit log entry.
- Clear UI banner showing impersonation mode.
- No access to secrets or payment methods.

## Suggested Screens

### MVP

- SuperAdmin login.
- Schools list.
- School detail.
- Create school.
- Create first school admin.

### Later

- Platform dashboard.
- Support search.
- Audit logs.
- Feature flags.
- Subscription management.
- System health.

## Data Access Rules

- SuperAdmin permissions must be separate from school admin permissions.
- A school admin must never get SuperAdmin access by normal school membership.
- SuperAdmin actions must be audited.
- Destructive actions should be soft-delete or status-based where possible.

## Implementation Recommendation

The first implementation can be part of the same Flutter Web admin codebase if
the routing and permissions are clean:

```text
apps/admin_app
  /school-admin
  /super-admin
```

However, the backend permission model must treat SuperAdmin as a platform-level
role, not as a school membership role.

Recommended backend model:

- `platform_roles`
- `platform_memberships`
- `school_memberships`

Alternative:

- One `memberships` table with nullable `school_id`.

Prefer explicit separation if the product is multi-school SaaS from the start.

## First SuperAdmin Task

Build tenant provisioning:

1. Create school.
2. Create branch.
3. Create owner user.
4. Assign owner role in that school.
5. Seed default categories and progress templates.
