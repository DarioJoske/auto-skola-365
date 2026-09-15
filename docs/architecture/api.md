# Auto Skola 365 - API Draft

Status: Draft  
Created: 2026-09-04

## Health

Swagger UI:

```text
http://localhost:8080/swagger-ui.html
```

OpenAPI JSON:

```text
http://localhost:8080/v3/api-docs
```

For authenticated endpoints in Swagger:

1. Call `POST /api/auth/login`.
2. Copy `accessToken` from the response.
3. Click `Authorize` in Swagger UI.
4. Paste only the JWT token value, not the `Bearer ` prefix.
5. Call `GET /api/me`.

```http
GET /api/health
```

Response:

```json
{
  "status": "ok",
  "service": "auto-skola-365-backend",
  "timestamp": "2026-09-04T20:55:52.151201Z"
}
```

## Platform Tenant Provisioning

Temporary MVP endpoint for creating the first school tenant and owner account.

```http
POST /api/platform/tenants
Content-Type: application/json
```

Request:

```json
{
  "schoolName": "Auto Skola Demo",
  "schoolOib": "12345678901",
  "schoolEmail": "ured@example.com",
  "schoolPhone": "+385 1 123 4567",
  "branch": {
    "name": "Glavna poslovnica",
    "address": "Ilica 1",
    "city": "Zagreb",
    "phone": "+385 1 123 4567"
  },
  "owner": {
    "firstName": "Dario",
    "lastName": "Josipovic",
    "email": "owner@example.com",
    "phone": "+385 91 123 4567",
    "password": "change-me-123"
  }
}
```

Response:

```json
{
  "schoolId": "uuid",
  "branchId": "uuid",
  "ownerUserId": "uuid",
  "membershipId": "uuid"
}
```

## Authentication

The backend uses backend-owned authentication with BCrypt password hashes and a
stateless JWT access token.

```http
POST /api/auth/login
Content-Type: application/json
```

Request:

```json
{
  "email": "owner@example.com",
  "password": "change-me-123"
}
```

Response:

```json
{
  "accessToken": "jwt",
  "tokenType": "Bearer",
  "expiresInMinutes": 480,
  "user": {
    "id": "uuid",
    "email": "owner@example.com",
    "firstName": "Dario",
    "lastName": "Josipovic",
    "phone": "+385 91 123 4567",
    "status": "ACTIVE",
    "memberships": [
      {
        "id": "uuid",
        "schoolId": "uuid",
        "schoolName": "Auto Skola Demo",
        "membershipStatus": "ACTIVE",
        "roleKey": "school_owner",
        "roleName": "School Owner",
        "roleScope": "SCHOOL",
        "permissions": [
          "candidates.manage",
          "instructors.manage",
          "lessons.manage",
          "school.settings.manage",
          "users.manage"
        ]
      }
    ]
  }
}
```

```http
GET /api/me
Authorization: Bearer <accessToken>
```

Response:

```json
{
  "id": "uuid",
  "email": "owner@example.com",
  "firstName": "Dario",
  "lastName": "Josipovic",
  "phone": "+385 91 123 4567",
  "status": "ACTIVE",
  "memberships": [
    {
      "id": "uuid",
      "schoolId": "uuid",
      "schoolName": "Auto Skola Demo",
      "membershipStatus": "ACTIVE",
      "roleKey": "school_owner",
      "roleName": "School Owner",
      "roleScope": "SCHOOL",
      "permissions": [
        "candidates.manage",
        "instructors.manage",
        "lessons.manage",
        "school.settings.manage",
        "users.manage"
      ]
    }
  ]
}
```

Security configuration:

- `/api/auth/login`, `/api/health`, `/actuator/health`, Swagger and temporary
  tenant provisioning are public.
- All other endpoints require `Authorization: Bearer <accessToken>`.
- `JWT_SECRET` must be set outside local development.

## Security Note

`POST /api/platform/tenants` is currently open so the initial tenant can be
created during early development. Before production, this endpoint must require
platform-level SuperAdmin authorization or be replaced by a one-time setup
command.

## Candidates

Candidates are school-scoped. The authenticated user must have an active
membership in the requested school and the `candidates.manage` permission.
School authorization is enforced through active memberships, roles and role
permissions from the identity schema.

```http
GET /api/schools/{schoolId}/candidates
Authorization: Bearer <accessToken>
```

Supported query filters:

- `status`: candidate status, for example `LEAD` or `IN_DRIVING`.
- `categoryCode`: driving category code, for example `B`.
- `assignedInstructorId`: assigned instructor profile id.
- `withoutInstructor`: when `true`, returns only candidates without an assigned instructor.
- `q`: search across first name, last name, email, phone and OIB.

Response:

```json
[
  {
    "id": "uuid",
    "schoolId": "uuid",
    "firstName": "Ana",
    "lastName": "Anic",
    "email": "ana@example.com",
    "phone": "+385 91 000 111",
    "oib": "98765432109",
    "status": "LEAD",
    "categoryCode": "B",
    "categoryName": "Passenger car",
    "assignedInstructorId": "uuid",
    "assignedInstructorName": "Ivan Ivic",
    "notes": "Prvi kandidat"
  }
]
```

```http
POST /api/schools/{schoolId}/candidates
Authorization: Bearer <accessToken>
Content-Type: application/json
```

Request:

```json
{
  "firstName": "Ana",
  "lastName": "Anic",
  "email": "ana@example.com",
  "phone": "+385 91 000 111",
  "oib": "98765432109",
  "status": "LEAD",
  "categoryCode": "B",
  "assignedInstructorId": "uuid",
  "notes": "Prvi kandidat"
}
```

Response: `201 Created` with the created candidate object.

```http
GET /api/schools/{schoolId}/candidates/{candidateId}
Authorization: Bearer <accessToken>
```

Response: `200 OK` with the candidate object.

```http
PUT /api/schools/{schoolId}/candidates/{candidateId}
Authorization: Bearer <accessToken>
Content-Type: application/json
```

Request:

```json
{
  "firstName": "Ana",
  "lastName": "Anic Horvat",
  "email": "ana.horvat@example.com",
  "phone": "+385 91 000 222",
  "oib": "98765432109",
  "status": "IN_DRIVING",
  "categoryCode": "B",
  "assignedInstructorId": "uuid",
  "notes": "Prebacena u voznju"
}
```

Response: `200 OK` with the updated candidate object.

## Instructors

Instructors are school-scoped. The authenticated user must have an active
membership in the requested school and the `instructors.manage` permission.

```http
GET /api/schools/{schoolId}/instructors?active=true&categoryCode=B
Authorization: Bearer <accessToken>
```

Response:

```json
[
  {
    "id": "uuid",
    "schoolId": "uuid",
    "userId": "uuid",
    "membershipId": "uuid",
    "firstName": "Ivan",
    "lastName": "Ivic",
    "email": "ivan@example.com",
    "phone": "+385 91 111 222",
    "licenseNumber": "ZG-12345",
    "active": true,
    "categoryCodes": ["B"],
    "availabilityRules": [
      {
        "id": "uuid",
        "dayOfWeek": 1,
        "startTime": "08:00:00",
        "endTime": "16:00:00"
      }
    ]
  }
]
```

```http
POST /api/schools/{schoolId}/instructors
Authorization: Bearer <accessToken>
Content-Type: application/json
```

Request:

```json
{
  "firstName": "Ivan",
  "lastName": "Ivic",
  "email": "ivan@example.com",
  "password": "instruktor-123",
  "phone": "+385 91 111 222",
  "licenseNumber": "ZG-12345",
  "active": true,
  "categoryCodes": ["B"],
  "availabilityRules": [
    {
      "dayOfWeek": 1,
      "startTime": "08:00:00",
      "endTime": "16:00:00"
    }
  ]
}
```

`password` is required on create and must contain at least 8 characters. The
created instructor can use that password for their first login.

Response: `201 Created` with the created instructor object.

```http
GET /api/schools/{schoolId}/instructors/{instructorId}
Authorization: Bearer <accessToken>
```

Response: `200 OK` with the instructor object.

```http
PUT /api/schools/{schoolId}/instructors/{instructorId}
Authorization: Bearer <accessToken>
Content-Type: application/json
```

Request body matches the create request, but `password` is optional on update.
Omit it or send it blank to keep the current password; send a new value with at
least 8 characters to reset the instructor password. Response: `200 OK` with the
updated instructor object.

## Lessons

Lessons are school-scoped. Admin users need `lessons.manage`. Assigned
instructors need `lessons.view_assigned` for instructor-facing lesson access.
Candidate users need `lessons.reserve_own` and a linked `candidates.user_id`
profile to reserve their own lessons. MVP scheduling focuses on `DRIVING`
lessons.

Lesson statuses:

- `REQUESTED`: candidate/admin/instructor requested a slot.
- `CONFIRMED`: instructor/admin confirmed the slot.
- `COMPLETED`: lesson was completed.
- `CANCELLED`: lesson was cancelled and no longer blocks overlaps.
- `NO_SHOW`: candidate did not attend.

Lesson types:

- `DRIVING`
- `THEORY`
- `EXAM`

MVP rule: only `DRIVING` can be created through the API for now. Duration is
fixed to 60 minutes. `endAt` is optional; if omitted, the backend sets it to
`startAt + 60 minutes`. If provided, it must match that 60-minute duration.

Overlap rule: all lessons except `CANCELLED` block overlapping lessons for both
the instructor and the candidate. Overlap returns `409 Conflict`.

```http
GET /api/schools/{schoolId}/lessons?from=2026-09-08T00:00:00Z&to=2026-09-09T00:00:00Z
Authorization: Bearer <accessToken>
```

Supported query filters:

- `from`: inclusive range start.
- `to`: exclusive range end.
- `instructorId`: optional instructor filter.
- `candidateId`: optional candidate filter.
- `status`: optional status filter.

Response:

```json
[
  {
    "id": "uuid",
    "schoolId": "uuid",
    "candidateId": "uuid",
    "candidateName": "Ana Anic",
    "instructorId": "uuid",
    "instructorName": "Ivan Ivic",
    "categoryCode": "B",
    "categoryName": "Passenger car",
    "branchId": "uuid",
    "branchName": "Glavna poslovnica",
    "lessonType": "DRIVING",
    "status": "REQUESTED",
    "startAt": "2026-09-08T08:00:00Z",
    "endAt": "2026-09-08T09:00:00Z",
    "confirmedAt": null,
    "cancelledAt": null,
    "notes": "Prvi sat voznje",
    "createdByRole": "ADMIN"
  }
]
```

```http
POST /api/schools/{schoolId}/lessons
Authorization: Bearer <accessToken>
Content-Type: application/json
```

Request:

```json
{
  "candidateId": "uuid",
  "instructorId": "uuid",
  "branchId": "uuid",
  "lessonType": "DRIVING",
  "status": "REQUESTED",
  "startAt": "2026-09-08T08:00:00Z",
  "endAt": "2026-09-08T09:00:00Z",
  "notes": "Prvi sat voznje"
}
```

Response: `201 Created` with the created lesson object.

```http
GET /api/schools/{schoolId}/lessons/instructor?from=2026-09-08T00:00:00Z&to=2026-09-09T00:00:00Z
Authorization: Bearer <accessToken>
```

Instructor-facing list. Returns only lessons assigned to the authenticated
instructor profile for the requested school. Supports `from`, `to` and `status`
filters.

```http
GET /api/schools/{schoolId}/lessons/instructor/{lessonId}
Authorization: Bearer <accessToken>
```

Instructor-facing detail. Returns `403 Forbidden` when the lesson belongs to a
different instructor.

```http
POST /api/schools/{schoolId}/lessons/candidate/reservations
Authorization: Bearer <accessToken>
Content-Type: application/json
```

Candidate-facing reservation. The request does not accept `candidateId`,
`instructorId`, `lessonType` or `status`; backend resolves the candidate from
the authenticated user, uses the candidate's assigned instructor, and creates a
`REQUESTED` `DRIVING` lesson.

Request:

```json
{
  "branchId": "uuid",
  "startAt": "2026-09-08T08:00:00Z",
  "endAt": "2026-09-08T09:00:00Z",
  "notes": "Zelim termin voznje"
}
```

Response: `201 Created` with the created lesson object. If the candidate has no
assigned instructor, the API returns `409 Conflict`.

```http
GET /api/schools/{schoolId}/lessons/{lessonId}
Authorization: Bearer <accessToken>
```

Response: `200 OK` with the lesson object.

```http
PUT /api/schools/{schoolId}/lessons/{lessonId}
Authorization: Bearer <accessToken>
Content-Type: application/json
```

Request body matches create. Response: `200 OK` with the updated lesson object.

```http
POST /api/schools/{schoolId}/lessons/{lessonId}/confirm
Authorization: Bearer <accessToken>
```

Response: `200 OK` with status `CONFIRMED`.

```http
POST /api/schools/{schoolId}/lessons/{lessonId}/cancel
Authorization: Bearer <accessToken>
```

Response: `200 OK` with status `CANCELLED`.

### Complete an instructor lesson

```http
POST /api/schools/{schoolId}/lessons/{lessonId}/complete
Authorization: Bearer <accessToken>
Content-Type: application/json

{"note": "Vježbali smo parkiranje."}
```

Only the active instructor assigned to the lesson, with active school access,
can complete it. The lesson must be `CONFIRMED` and its scheduled end must have
passed (server time). `note` is optional, trimmed, and limited to 2000 characters.

Response: `200 OK` with the lesson object, status `COMPLETED`, server-generated
`completedAt`, and nullable `completionNote`. Existing `notes` are preserved.
These two additional fields are also returned by lesson list/detail endpoints.

Invalid status, early completion, or repeated completion returns `409 Conflict`;
unauthorized school/instructor access returns `403 Forbidden`; invalid note
length returns `400 Bad Request`. Errors use the standard structured JSON format.
Completed lessons cannot be edited, confirmed, or cancelled. Mutations lock the
lesson row for the transaction so concurrent actions cannot overwrite completion.

Database migration: `V10__lesson_completion.sql` adds the completion columns.

### Candidate skill progress (B category)

```http
GET /api/schools/{schoolId}/candidates/{candidateId}/progress
GET /api/schools/{schoolId}/lessons/{lessonId}/progress
Authorization: Bearer <accessToken>
```

Both return `candidateId`, `candidateName`, `categoryCode`, nullable `lessonId`,
`editable`, `skills`, `statuses`, and `entries`. Skills/statuses are `{code,label}`
options with Croatian labels. Each entry contains `lessonId`, `lessonEndAt`,
`skill`, `status`, and `recordedAt`.

Entries are ordered by lesson end descending, then recording time descending.
The latest entry for each skill is its current assessment: editing an older
lesson does not replace a newer lesson's assessment. No entry means unassessed,
which is distinct from an explicit `NOT_STARTED` assessment.

School users with `candidates.manage` may read their school's progress.
Instructors need `progress.manage_assigned` and an active instructor profile
assigned to the candidate. Lesson responses are editable only for that lesson's
instructor, after completion, for B category. Other categories return an empty
skill template and are read-only.

```http
POST /api/schools/{schoolId}/lessons/{lessonId}/progress
Authorization: Bearer <accessToken>
Content-Type: application/json

{"assessments":[{"skill":"PARKING","status":"NEEDS_PRACTICE"}]}
```

Accepts 1–10 distinct skills from the template. Statuses: `NOT_STARTED`,
`IN_PROGRESS`, `NEEDS_PRACTICE`, `SATISFACTORY`, `MASTERED`. Only the lesson's
active instructor with the progress permission and current candidate assignment
can write. The lesson must be `COMPLETED`.

Returns `200 OK` with refreshed progress. Saving inserts or corrects the selected
skills for that lesson; omitted skills are unchanged. There is one assessment
per lesson/skill, so repeated requests do not duplicate history. This is history
across lessons, not an audit trail of every correction. The lesson row is locked
while saving to serialize concurrent updates.

Invalid/duplicate skills, invalid statuses, empty requests, or unsupported
category return `400`; denied access returns `403`; an unfinished lesson returns
`409`. All errors use the standard structured JSON format.

Migration `V11__lesson_progress.sql` adds the assessment table, foreign key,
unique lesson/skill constraint, and allowed skill/status constraints.
