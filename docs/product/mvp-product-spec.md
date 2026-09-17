# Auto Skola 365 - MVP Product Specification

Status: Draft  
Created: 2026-09-04  
Last aligned with implementation: 2026-09-17 (task #2)
Owner: Product / Engineering

The [design handoff](../architecture/design-handoff.md) records the current
lesson, hour-counting, note-visibility and account-access rules and their
differences from the Figma blueprint. These rules take precedence over sample
values and proposed interactions in the mockups.

## 1. Overview

Auto Skola 365 is a SaaS platform for managing driving schools. The product
will support three operational surfaces:

- Admin application for owners and office staff.
- Instructor application for lesson scheduling, communication and candidate
  progress tracking.
- Candidate application for booking lessons, communication, progress visibility
  and exam status.

The MVP focuses on the operational core: the admin workflow, users and roles,
candidates, instructors, scheduling, lessons and basic progress tracking.

## 2. Product Goals

- Replace spreadsheet/manual tracking for core driving school operations.
- Give office staff one place to manage candidates, instructors and lessons.
- Give instructors a simple daily workflow for lessons and candidate progress.
- Establish a shared backend and data model that can later support candidate
  self-service, billing, documents, messaging and multi-school SaaS operations.

## 3. Non-Goals For MVP

- Full accounting and fiscalization.
- Full candidate mobile app with payments and document management.
- Advanced chat system.
- Advanced reporting and analytics.
- Marketplace or public website for driving schools.
- Multi-language support beyond initial Croatian product terminology.
- Complex fleet maintenance management.

## 4. Primary Users

### 4.1 Owner / Admin

Owns the driving school and needs visibility into operations, candidate status,
instructor workload and business activity.

Core needs:

- See current operational status.
- Manage instructors and candidates.
- Assign candidates to instructors.
- Manage and review lesson calendar.
- Track candidate readiness and status.

### 4.2 Office Staff

Handles day-to-day administration.

Core needs:

- Create and update candidate records.
- Manage statuses and categories.
- Schedule, reschedule and cancel lessons.
- Track exam readiness and basic notes.

### 4.3 Instructor

Conducts lessons and tracks candidate progress.

Core needs:

- See today's and upcoming lessons.
- Access assigned candidate information.
- Mark lessons completed.
- See completed instructional driving hours against the candidate target.
- See where each candidate stands.

### 4.4 Candidate

Learns to drive and needs visibility into their progress and schedule.

MVP involvement:

- Candidate data exists in the system.
- Candidate portal supports login, own schedule, completed hours and profile.
- Candidate can request a lesson with the assigned instructor; the request
  requires confirmation and is not a confirmed booking.

## 5. MVP Scope

### 5.1 Authentication And Roles

Functional requirements:

- Users can log in.
- System supports admin, office staff, instructor and candidate roles.
- User access is scoped to a driving school.
- The backend returns current user, active school membership and permissions.

Acceptance criteria:

- Admin cannot access data outside their school.
- Instructor can access only assigned candidates and own schedule.
- Role checks are enforced in the backend, not only in the UI.
- Admin activates candidate access by saving `loginPassword` (8–72 characters)
  with an unused contact email. An existing account cannot be claimed by email.
- Omitting `loginPassword` keeps the login unchanged; the admin UI sends `null`
  for an empty field. Contact email changes do not change `loginEmail`.
- Password changes are limited to a linked account with active candidate access
  to this school and no membership in another school or another role.
- Invitations, self-service password recovery and forced first-login password
  changes are not implemented. Do not promise these flows in the current UI.

### 5.2 School And Membership Model

Functional requirements:

- System supports a driving school entity.
- System supports users belonging to a school through memberships.
- Memberships define role and permissions.
- Model should allow multiple schools later.

Acceptance criteria:

- Database can represent one user in one or more schools.
- School-scoped data always has a clear school ownership path.

### 5.3 Candidate Management

Functional requirements:

- Admin can create a candidate.
- Admin can edit candidate profile data.
- Admin can list, search and filter candidates.
- Candidate has category, status and assigned instructor.
- Candidate profile stores basic contact and operational data.

Initial candidate statuses:

- Lead
- Enrolled
- In Theory
- Passed Theory
- In Driving
- Ready For Exam
- Exam Scheduled
- Passed
- Dropped
- Archived

Initial candidate fields:

- First name
- Last name
- Email
- Phone
- OIB
- Date of birth
- Address
- Driving category
- Status
- Assigned instructor
- Internal notes

Acceptance criteria:

- Office staff can create and find candidates quickly.
- Candidate list shows status, category and assigned instructor.
- Candidate record changes are ready for audit logging.

### 5.4 Instructor Management

Functional requirements:

- Admin can create and edit instructors.
- Instructor has supported driving categories.
- Instructor has active/inactive status.
- Instructor can be assigned to candidates.
- Instructor can have availability rules in the model.

Acceptance criteria:

- Admin can see each instructor's assigned candidates.
- Scheduling can validate against instructor availability.

### 5.5 Lessons And Calendar

Functional requirements:

- Admin can create a lesson for candidate + instructor.
- Admin can reschedule, confirm and cancel a mutable lesson.
- Only the active instructor recorded on the lesson can complete it; admin
  permission alone does not grant completion access.
- Lessons have start time, end time, status and optional notes.
- Calendar can be filtered by instructor.
- Backend prevents schedule conflicts.

Current lesson statuses:

| API status | Croatian label | Contribution to hours |
| --- | --- | --- |
| `REQUESTED` | Čeka potvrdu | 0 |
| `CONFIRMED` | Potvrđeno | 0 |
| `COMPLETED` | Odrađeno | 1 for an eligible current-category `DRIVING` lesson |
| `CANCELLED` | Otkazano | 0 |
| `NO_SHOW` | Nedolazak | 0; represented in the model, no current write action |

Candidate requests create `REQUESTED`; instructor reservations create
`CONFIRMED`. Admin creation defaults to `REQUESTED` and supports `CONFIRMED`
and `CANCELLED`. Confirm/cancel actions belong to authorized school staff or
the instructor recorded on the lesson. Completion requires `CONFIRMED` and
`endAt <= server time`; it records `completedAt` and locks out later changes.
Passing the end time alone never completes a lesson.

The [transition table](../architecture/design-handoff.md#statusi-i-prijelazi)
also documents API support for reopening cancelled lessons and repeated
confirm/cancel actions. Candidate withdrawal/rescheduling, separate cancellation
reasons and a `MOVED` status are not implemented.

Scheduling rules:

- One instructor cannot have overlapping lessons.
- One candidate cannot have overlapping lessons.
- One vehicle cannot have overlapping lessons once vehicles are enabled.
- Lessons must belong to one school.
- Only allowed roles can change lesson status.
- A calendar slot is fixed at 60 minutes. The backend supplies `endAt` when
  omitted and rejects any other duration. Figma examples of 45-minute slots
  or 90 minutes / 2 hours do not change this rule.
- Create/update must use the candidate's current assigned active instructor,
  who must support the candidate's category. Candidate/instructor identities
  for self-service reservations are derived by the backend.
- `REQUESTED` also blocks overlaps; only `CANCELLED` frees the slot.

Acceptance criteria:

- Admin can manage a weekly lesson schedule.
- Backend rejects conflicting lesson creation or rescheduling.
- Completed eligible lessons feed the current hours counter; billing remains
  outside this scope.

### 5.6 Candidate Driving Hours

Scope simplified on 2026-09-16: MVP progress tracks completed instructional
hours only. Skill lists, skill ratings and assessment history are outside MVP.

Functional requirements:

- Instructor marks an eligible own confirmed lesson completed after its end.
- Backend counts completed DRIVING lessons for the candidate's current category.
- Each existing 60-minute calendar slot contributes one instructional hour
  (45 minutes of teaching within the scheduled hour).
- The backend is the only source of `completedDrivingHours`; no manual hours
  field, client-side duration conversion or optimistic `+1`/`+2` is allowed.
  After completion, reload the total from the backend.
- Requested, confirmed, cancelled and no-show lessons contribute no hours.
- Show `25/35 sati odrađeno`; retain the actual count above the target, e.g. 37/35.
- Standard B-category target defaults to 35. Store the target per candidate and
  allow school admins to set a positive value through the candidate API.
- Other categories have no inferred target until one is configured.
- Keep candidate `notes`, lesson `notes` and `completionNote` internal to
  authorized school staff/instructors. The candidate portal omits all three.
  A candidate's reservation note is input to the school, not a public feedback
  field. Public feedback to candidates requires a separate future API field
  and explicit visibility rules; existing notes must never be republished.

Acceptance criteria:

- Candidate progress and lesson detail show the same backend-calculated hours.
- Completing a lesson refreshes the displayed counter automatically.
- Repeated/concurrent completion cannot double count a lesson.
- Access remains scoped to the school and assigned candidate/instructor.
- Reaching the target does not automatically change candidate status or exam readiness.
- Admin candidate details show completed/target hours and allow editing a positive target.
- Instructor can reserve a confirmed 60-minute driving lesson for a currently assigned candidate.
- Instructor identity comes from the signed-in account, not a selectable form field.
- Admin selects an instructor first; the candidate picker shows only that instructor's current candidates and resets when the instructor changes.
- Backend rechecks the current assignment and rejects conflicting reservations.

## 6. Out Of MVP, But Model-Aware

The MVP data model should leave room for:

- Exams and attempts.
- Documents and expiration dates.
- Payments, packages and debt tracking.
- Messaging and notifications.
- Vehicles and fleet scheduling.
- Audit log and reports.

These modules do not need full UI in the first MVP, but the architecture should
not block them.

## 7. Application Surfaces

### 7.1 Admin Application

MVP screens:

- Login.
- Dashboard placeholder.
- Candidates list.
- Candidate detail.
- Instructors list.
- Instructor detail.
- Lessons calendar.
- Lesson create/edit form.

### 7.2 Instructor Application

MVP screens:

- Login.
- Today schedule.
- Upcoming lessons.
- Candidate detail.
- Complete lesson action with an optional internal note (not visible to candidate).
- Completed driving hours, for example `25/35 sati odrađeno`.

### 7.3 Candidate Application

First candidate slice implemented on 2026-09-17:

- Admin activates a new candidate login by setting an initial password.
- Candidate login and school-scoped access to their own data.
- Home overview with next lesson and completed driving hours.
- Upcoming lessons, lesson history and statuses.
- Requests for a 60-minute lesson with the assigned instructor.
- Profile and logout.
- Shared light/blue design system with responsive mobile and desktop layouts.

Exams, messages, invitations and password recovery remain follow-up work.

## 8. Recommended Technical Direction

- Frontend: Flutter for all three applications, with the required stack in the
  [Flutter architecture decision](../architecture/flutter-architecture.md).
- Backend: Java Spring Boot API service.
- Database: PostgreSQL.
- Auth: backend-owned auth with role-based access control.
- Notifications: Firebase Cloud Messaging later.
- Storage: S3-compatible object storage later.
- Deployment: Docker-based local and production setup.

## 9. Key Domain Entities

- School
- Branch
- User
- SchoolMembership
- Role
- Permission
- Candidate
- InstructorProfile
- DrivingCategory
- Vehicle
- Lesson
- LessonStatusHistory
- Exam
- Document
- Payment
- AuditLog

## 10. Open Questions

- Should a future release support other durations or multiple instructional
  hours per lesson? Until explicitly decided and documented, keep 60 minutes / 1 hour.
- What separate public-feedback, invitation and password-recovery contracts
  should a future release introduce? Current internal notes and access rules remain.
- Is the first target one driving school or multi-school SaaS from day one?
- Which driving categories must be supported in the first production version?
- Are payments and invoices only internal tracking or legally/fiscally relevant?
- Which data is mandatory for Croatian driving school compliance?

## 11. MVP Success Criteria

The MVP is successful when:

- Admin can manage candidates and instructors.
- Admin can schedule and change lessons without conflicts.
- Instructor can view daily schedule, complete lessons and see completed/target hours.
- Candidate status and progress are visible from the admin side.
- Backend enforces roles, school scope and scheduling rules.
- The domain model is ready for exams, documents, billing and candidate app.

## 12. Next Deliverables

1. Confirm open product questions.
2. Create ERD for the MVP domain.
3. Define API resources and endpoint skeleton.
4. Choose backend stack.
5. Restructure Flutter project or monorepo layout if needed.
