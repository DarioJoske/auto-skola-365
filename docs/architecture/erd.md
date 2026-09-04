# Auto Skola 365 - Initial ERD

Status: Draft  
Created: 2026-09-04

## Implementation Status

Implemented in Flyway `V2__identity_foundation.sql`:

- schools
- branches
- users
- roles
- permissions
- role_permissions
- school_memberships
- driving_categories

## Scope

This ERD covers the MVP domain model for:

- Schools, branches and memberships.
- Users, roles and permissions.
- Candidates and instructors.
- Lessons, scheduling and progress tracking.
- Model-aware placeholders for exams, documents, payments and audit logs.

## Mermaid ERD

```mermaid
erDiagram
    schools ||--o{ branches : has
    schools ||--o{ school_memberships : has
    schools ||--o{ candidates : owns
    schools ||--o{ vehicles : owns
    schools ||--o{ lessons : owns
    schools ||--o{ audit_logs : owns

    users ||--o{ school_memberships : has
    roles ||--o{ school_memberships : assigned_to
    roles ||--o{ role_permissions : has
    permissions ||--o{ role_permissions : grants

    users ||--o| instructor_profiles : may_have
    school_memberships ||--o| instructor_profiles : instructor_membership

    instructors_categories }o--|| instructor_profiles : belongs_to
    instructors_categories }o--|| driving_categories : supports

    candidates }o--|| schools : belongs_to
    candidates }o--o| instructor_profiles : assigned_to
    candidates }o--|| driving_categories : trains_for

    vehicles }o--|| schools : belongs_to
    vehicles }o--|| driving_categories : supports

    lessons }o--|| schools : belongs_to
    lessons }o--|| candidates : for_candidate
    lessons }o--|| instructor_profiles : with_instructor
    lessons }o--o| vehicles : uses_vehicle
    lessons ||--o{ lesson_status_history : changes
    lessons ||--o{ lesson_progress_notes : produces

    candidate_progress_templates ||--o{ candidate_progress_items : contains
    driving_categories ||--o{ candidate_progress_templates : has
    candidates ||--o{ candidate_progress_items : tracks
    candidate_progress_items ||--o{ lesson_progress_notes : referenced_by

    candidates ||--o{ exams : has
    candidates ||--o{ documents : has
    candidates ||--o{ payments : has
    users ||--o{ audit_logs : performs

    schools {
        uuid id PK
        text name
        text oib
        text email
        text phone
        text status
        timestamptz created_at
        timestamptz updated_at
    }

    branches {
        uuid id PK
        uuid school_id FK
        text name
        text address
        text city
        text phone
        timestamptz created_at
        timestamptz updated_at
    }

    users {
        uuid id PK
        text email
        text password_hash
        text first_name
        text last_name
        text phone
        text status
        timestamptz created_at
        timestamptz updated_at
    }

    school_memberships {
        uuid id PK
        uuid school_id FK
        uuid user_id FK
        uuid role_id FK
        text status
        timestamptz created_at
        timestamptz updated_at
    }

    roles {
        uuid id PK
        text key
        text name
        text scope
    }

    permissions {
        uuid id PK
        text key
        text description
    }

    role_permissions {
        uuid role_id FK
        uuid permission_id FK
    }

    driving_categories {
        uuid id PK
        text code
        text name
        boolean active
    }

    instructor_profiles {
        uuid id PK
        uuid school_membership_id FK
        text license_number
        boolean active
        timestamptz created_at
        timestamptz updated_at
    }

    instructors_categories {
        uuid instructor_profile_id FK
        uuid driving_category_id FK
    }

    candidates {
        uuid id PK
        uuid school_id FK
        uuid driving_category_id FK
        uuid assigned_instructor_id FK
        text first_name
        text last_name
        text email
        text phone
        text oib
        date date_of_birth
        text address
        text status
        text internal_notes
        timestamptz created_at
        timestamptz updated_at
    }

    vehicles {
        uuid id PK
        uuid school_id FK
        uuid driving_category_id FK
        text registration_number
        text make
        text model
        boolean active
        timestamptz created_at
        timestamptz updated_at
    }

    lessons {
        uuid id PK
        uuid school_id FK
        uuid candidate_id FK
        uuid instructor_profile_id FK
        uuid vehicle_id FK
        timestamptz starts_at
        timestamptz ends_at
        text status
        text pickup_location
        text notes
        timestamptz created_at
        timestamptz updated_at
    }

    lesson_status_history {
        uuid id PK
        uuid lesson_id FK
        text old_status
        text new_status
        uuid changed_by_user_id FK
        text reason
        timestamptz created_at
    }

    candidate_progress_templates {
        uuid id PK
        uuid driving_category_id FK
        text name
        boolean active
    }

    candidate_progress_items {
        uuid id PK
        uuid candidate_id FK
        uuid template_id FK
        text area_key
        text area_name
        text status
        timestamptz updated_at
    }

    lesson_progress_notes {
        uuid id PK
        uuid lesson_id FK
        uuid candidate_progress_item_id FK
        uuid instructor_profile_id FK
        text note
        text status_after_lesson
        timestamptz created_at
    }

    exams {
        uuid id PK
        uuid candidate_id FK
        text type
        text status
        date scheduled_date
        text result
        int attempt_number
        timestamptz created_at
        timestamptz updated_at
    }

    documents {
        uuid id PK
        uuid candidate_id FK
        text type
        text status
        text file_url
        date expires_at
        uuid uploaded_by_user_id FK
        timestamptz created_at
    }

    payments {
        uuid id PK
        uuid candidate_id FK
        numeric amount
        text currency
        text type
        text status
        date paid_on
        timestamptz created_at
    }

    audit_logs {
        uuid id PK
        uuid school_id FK
        uuid actor_user_id FK
        text entity_type
        uuid entity_id
        text action
        jsonb changes
        timestamptz created_at
    }
```

## Important Modeling Notes

- Every operational record must be school-scoped directly or through an owned
  parent entity.
- Scheduling conflict checks belong in the backend service layer and should be
  backed by database indexes where possible.
- Candidate progress templates should be configurable per driving category.
- Exams, documents and payments are included as model-aware entities, but full
  UI implementation is outside the first admin-core MVP.
- Audit logs should be append-only and should not depend on UI behavior.

## First Implementation Order

1. `schools`, `branches`, `users`, `roles`, `permissions`,
   `school_memberships`.
2. `driving_categories`, `instructor_profiles`, `candidates`.
3. `vehicles`, `lessons`, `lesson_status_history`.
4. `candidate_progress_templates`, `candidate_progress_items`,
   `lesson_progress_notes`.
5. Model-aware placeholders for `exams`, `documents`, `payments`, `audit_logs`.
