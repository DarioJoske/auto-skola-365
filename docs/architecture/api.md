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

Request body matches the create request. Response: `200 OK` with the updated
instructor object.
