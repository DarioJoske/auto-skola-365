package com.autoskola365.backend.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.jdbc.Sql;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

@SpringBootTest
@AutoConfigureMockMvc
@Sql("/tenancy-regression.sql")
class TenancyRegressionTest {
    private static final String SCHOOL = "10000000-0000-0000-0000-000000000001";
    private static final String OTHER_SCHOOL = "10000000-0000-0000-0000-000000000002";
    private static final String CANDIDATE = "50000000-0000-0000-0000-000000000001";
    private static final String OTHER_CANDIDATE = "50000000-0000-0000-0000-000000000002";
    private static final String INSTRUCTOR = "40000000-0000-0000-0000-000000000001";
    private static final String OTHER_INSTRUCTOR = "40000000-0000-0000-0000-000000000002";
    private static final String LESSON = "60000000-0000-0000-0000-000000000001";
    private static final String OTHER_LESSON = "60000000-0000-0000-0000-000000000002";
    private static final String BASE = "/api/schools/" + SCHOOL;
    @Autowired MockMvc mvc;
    @Autowired JdbcTemplate jdbc;
    @Autowired JwtService jwt;
    String instructorToken;
    String otherInstructorToken;
    String candidateToken;
    String adminToken;

    @BeforeEach
    void addPortalAndAdminMemberships() {
        jdbc.update("INSERT INTO schools (id,name,status,created_at,updated_at) VALUES (?, 'Other school','ACTIVE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)", id(OTHER_SCHOOL));
        jdbc.update("INSERT INTO roles (id,\"key\",name,scope) VALUES (?, 'candidate','Candidate','SCHOOL')", id("00000000-0000-0000-0000-000000000003"));
        jdbc.update("INSERT INTO roles (id,\"key\",name,scope) VALUES (?, 'school_owner','Owner','SCHOOL')", id("00000000-0000-0000-0000-000000000001"));
        for (String permission : List.of("lessons.reserve_own", "lessons.manage", "candidates.manage", "instructors.manage")) {
            UUID permissionId = UUID.randomUUID();
            jdbc.update("INSERT INTO permissions (id,\"key\",description) VALUES (?,?,?)", permissionId, permission, permission);
            jdbc.update("INSERT INTO role_permissions (role_id,permission_id) VALUES (?,?)",
                id(permission.equals("lessons.reserve_own") ? "00000000-0000-0000-0000-000000000003" : "00000000-0000-0000-0000-000000000001"), permissionId);
        }
        for (int n : List.of(3, 4)) {
            UUID user = id("20000000-0000-0000-0000-00000000000" + n);
            jdbc.update("INSERT INTO users (id,email,password_hash,first_name,last_name,status,created_at,updated_at) VALUES (?,?,'x','Test','User','ACTIVE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)", user, "user" + n + "@example.com");
            jdbc.update("INSERT INTO school_memberships (id,school_id,user_id,role_id,status,created_at,updated_at) VALUES (?,?,?,?,'ACTIVE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)",
                id("30000000-0000-0000-0000-00000000000" + n), id(SCHOOL), user,
                id(n == 3 ? "00000000-0000-0000-0000-000000000003" : "00000000-0000-0000-0000-000000000001"));
        }
        jdbc.update("UPDATE candidates SET user_id=? WHERE id=?", id("20000000-0000-0000-0000-000000000003"), id(CANDIDATE));
        instructorToken = token(1);
        otherInstructorToken = token(2);
        candidateToken = token(3);
        adminToken = token(4);
    }

    @Test
    void missingInvalidAndExpiredTokensHaveStructuredErrors() throws Exception {
        assertError(mvc.perform(get(BASE + "/lessons")), 401, "UNAUTHORIZED", BASE + "/lessons");
        assertError(mvc.perform(get(BASE + "/lessons").header("Authorization", "Bearer invalid")), 401, "UNAUTHORIZED", BASE + "/lessons");
        String expired = new JwtService(new JwtProperties("test-only-change-this-secret-test-only-change-this-secret", -1))
            .createAccessToken(id("20000000-0000-0000-0000-000000000001"), "ivan@example.com");
        assertError(read(BASE + "/lessons", expired), 401, "UNAUTHORIZED", BASE + "/lessons");
    }

    @Test
    void schoolAndResourceBoundariesApplyToReadAndWriteRoutes() throws Exception {
        String otherBase = "/api/schools/" + OTHER_SCHOOL;
        for (String resource : List.of("/candidates", "/instructors", "/lessons", "/candidates/" + CANDIDATE + "/progress")) {
            assertError(read(otherBase + resource, adminToken), 403, "FORBIDDEN", otherBase + resource);
        }
        assertError(read(otherBase + "/candidate-portal", candidateToken), 403, "FORBIDDEN", otherBase + "/candidate-portal");
        String route = otherBase + "/lessons/instructor/reservations";
        assertError(postJson(route, instructorToken, reservation(CANDIDATE, future())), 403, "FORBIDDEN", route);
        assertError(postJson(otherBase + "/lessons", adminToken, lessonBody(CANDIDATE, future())), 403, "FORBIDDEN", otherBase + "/lessons");
        for (String action : List.of("confirm", "cancel", "complete")) {
            route = otherBase + "/lessons/" + LESSON + "/" + action;
            assertError(postJson(route, instructorToken, "{}"), 403, "FORBIDDEN", route);
        }
        route = BASE + "/candidates/" + OTHER_CANDIDATE + "/progress";
        assertError(read(route, instructorToken), 403, "FORBIDDEN", route);
        route = BASE + "/lessons/instructor/" + OTHER_LESSON;
        assertError(read(route, instructorToken), 403, "FORBIDDEN", route);
        for (String action : List.of("confirm", "cancel", "complete")) {
            route = BASE + "/lessons/" + OTHER_LESSON + "/" + action;
            assertError(postJson(route, instructorToken, "{}"), 403, "FORBIDDEN", route);
        }
        // A valid school membership must not make foreign IDs visible under its URL.
        jdbc.update("UPDATE candidates SET school_id=? WHERE id=?", id(OTHER_SCHOOL), id(OTHER_CANDIDATE));
        route = BASE + "/candidates/" + OTHER_CANDIDATE;
        assertError(read(route, adminToken), 404, "NOT_FOUND", route);
        route = BASE + "/lessons";
        assertError(postJson(route, adminToken, lessonBody(OTHER_CANDIDATE, future())), 404, "NOT_FOUND", route);
        assertThat(jdbc.queryForObject("SELECT status FROM lessons WHERE id=?", String.class, id(OTHER_LESSON))).isEqualTo("REQUESTED");
    }

    @Test
    void revokedMembershipIsCheckedAgainForAlreadyIssuedTokens() throws Exception {
        read(BASE + "/candidate-portal", candidateToken).andExpect(status().isOk());
        read(BASE + "/lessons/instructor", instructorToken).andExpect(status().isOk());
        read(BASE + "/candidates", adminToken).andExpect(status().isOk());
        jdbc.update("UPDATE school_memberships SET status='INACTIVE'");
        for (String suffix : List.of("/lessons/instructor", "/candidates/" + CANDIDATE + "/progress")) {
            assertError(read(BASE + suffix, instructorToken), 403, "FORBIDDEN", BASE + suffix);
        }
        assertError(read(BASE + "/candidates", adminToken), 403, "FORBIDDEN", BASE + "/candidates");
        assertError(read(BASE + "/candidate-portal", candidateToken), 403, "FORBIDDEN", BASE + "/candidate-portal");
        String route = BASE + "/lessons/candidate/reservations";
        assertError(postJson(route, candidateToken, "{\"startAt\":\"" + future() + "\"}"), 403, "FORBIDDEN", route);
        route = BASE + "/lessons/" + LESSON + "/confirm";
        assertError(postJson(route, instructorToken, "{}"), 403, "FORBIDDEN", route);
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM lessons", Integer.class)).isEqualTo(2);
    }

    @Test
    void reassignmentRevokesProgressAndNewReservationsButKeepsHistoricalCompletionOwner() throws Exception {
        jdbc.update("UPDATE candidates SET assigned_instructor_profile_id=? WHERE id=?", id(OTHER_INSTRUCTOR), id(CANDIDATE));
        String progress = BASE + "/candidates/" + CANDIDATE + "/progress";
        assertError(read(progress, instructorToken), 403, "FORBIDDEN", progress);
        read(progress, otherInstructorToken).andExpect(status().isOk());
        String route = BASE + "/lessons/instructor/reservations";
        assertError(postJson(route, instructorToken, reservation(CANDIDATE, future())), 409, "CONFLICT", route);
        assertError(postJson(BASE + "/lessons", adminToken, lessonBody(CANDIDATE, future())), 409, "CONFLICT", BASE + "/lessons");
        postJson(BASE + "/lessons/candidate/reservations", candidateToken, "{\"startAt\":\"" + future() + "\"}")
            .andExpect(status().isCreated()).andExpect(jsonPath("$.instructorId").value(OTHER_INSTRUCTOR))
            .andExpect(jsonPath("$.candidateId").value(CANDIDATE));
        jdbc.update("UPDATE lessons SET status='CONFIRMED' WHERE id=?", id(LESSON));
        route = BASE + "/lessons/" + LESSON + "/complete";
        assertError(postJson(route, otherInstructorToken, "{}"), 403, "FORBIDDEN", route);
        postJson(route, instructorToken, "{}").andExpect(status().isOk());
        read(progress, otherInstructorToken).andExpect(jsonPath("$.completedDrivingHours").value(1));
        assertError(read(BASE + "/lessons/" + LESSON + "/progress", instructorToken), 403, "FORBIDDEN", BASE + "/lessons/" + LESSON + "/progress");
    }

    @Test
    void onlyOwnCompletedDrivingLessonsOfCurrentCategoryCountAndNotesRemainPrivate() throws Exception {
        String portal = BASE + "/candidate-portal";
        String progress = BASE + "/candidates/" + CANDIDATE + "/progress";
        jdbc.update("UPDATE lessons SET status='COMPLETED',notes='INTERNAL SECRET',completion_note='PRIVATE COMPLETION'");
        read(portal, candidateToken).andExpect(jsonPath("$.completedDrivingHours").value(1))
            .andExpect(jsonPath("$.lessons.length()").value(1))
            .andExpect(content().string(org.hamcrest.Matchers.not(org.hamcrest.Matchers.containsString("SECRET"))))
            .andExpect(content().string(org.hamcrest.Matchers.not(org.hamcrest.Matchers.containsString("PRIVATE COMPLETION"))));
        for (String lessonStatus : List.of("REQUESTED", "CONFIRMED", "CANCELLED", "NO_SHOW")) {
            jdbc.update("UPDATE lessons SET status=? WHERE id=?", lessonStatus, id(LESSON));
            read(portal, candidateToken).andExpect(jsonPath("$.completedDrivingHours").value(0));
            read(progress, adminToken).andExpect(jsonPath("$.completedDrivingHours").value(0));
        }
        jdbc.update("UPDATE lessons SET status='COMPLETED',lesson_type='THEORY' WHERE id=?", id(LESSON));
        read(progress, adminToken).andExpect(jsonPath("$.completedDrivingHours").value(0));
        read(portal, candidateToken).andExpect(jsonPath("$.completedDrivingHours").value(0));
        jdbc.update("UPDATE lessons SET lesson_type='DRIVING' WHERE id=?", id(LESSON));
        UUID category = UUID.randomUUID();
        jdbc.update("INSERT INTO driving_categories (id,code,name,active) VALUES (?,'A','Motorcycle',true)", category);
        jdbc.update("UPDATE candidates SET driving_category_id=? WHERE id=?", category, id(CANDIDATE));
        read(progress, adminToken).andExpect(jsonPath("$.completedDrivingHours").value(0));
        read(portal, candidateToken).andExpect(jsonPath("$.completedDrivingHours").value(0));
    }

    @Test
    void candidateTableAndProfileExposeScopedCurrentCategoryHoursWithoutCapping() throws Exception {
        String candidates = BASE + "/candidates";
        jdbc.update("UPDATE lessons SET status='COMPLETED'");
        jdbc.update("UPDATE candidates SET required_driving_hours=1 WHERE id=?", id(CANDIDATE));
        for (int i = 0; i < 2; i++) {
            jdbc.update("""
                INSERT INTO lessons (id, school_id, candidate_id, instructor_profile_id, driving_category_id,
                    lesson_type, status, start_at, end_at, created_by_role, created_at, updated_at)
                SELECT ?, school_id, candidate_id, instructor_profile_id, driving_category_id,
                    lesson_type, status, start_at, end_at, created_by_role, created_at, updated_at
                FROM lessons WHERE id=?
                """, UUID.randomUUID(), id(LESSON));
        }
        read(candidates + "/" + CANDIDATE, adminToken)
            .andExpect(status().isOk()).andExpect(jsonPath("$.completedDrivingHours").value(3))
            .andExpect(jsonPath("$.requiredDrivingHours").value(1));
        read(candidates + "?q=Ana", adminToken).andExpect(status().isOk())
            .andExpect(jsonPath("$[0].completedDrivingHours").value(3));
        for (String excludedStatus : List.of("REQUESTED", "CONFIRMED", "CANCELLED", "NO_SHOW")) {
            jdbc.update("UPDATE lessons SET status=? WHERE candidate_id=?", excludedStatus, id(CANDIDATE));
            read(candidates + "?q=Ana", adminToken).andExpect(jsonPath("$[0].completedDrivingHours").value(0));
        }
        jdbc.update("UPDATE lessons SET status='COMPLETED',lesson_type='THEORY' WHERE candidate_id=?", id(CANDIDATE));
        read(candidates + "?q=Ana", adminToken).andExpect(jsonPath("$[0].completedDrivingHours").value(0));
        jdbc.update("UPDATE lessons SET lesson_type='DRIVING',school_id=? WHERE candidate_id=?", id(OTHER_SCHOOL), id(CANDIDATE));
        read(candidates + "?q=Ana", adminToken).andExpect(jsonPath("$[0].completedDrivingHours").value(0));
        jdbc.update("UPDATE lessons SET school_id=? WHERE candidate_id=?", id(SCHOOL), id(CANDIDATE));
        UUID category = UUID.randomUUID();
        jdbc.update("INSERT INTO driving_categories (id,code,name,active) VALUES (?,'A','Motorcycle',true)", category);
        jdbc.update("UPDATE candidates SET driving_category_id=? WHERE id=?", category, id(CANDIDATE));
        read(candidates + "?q=Ana", adminToken).andExpect(jsonPath("$[0].completedDrivingHours").value(0));
        read(candidates + "/" + CANDIDATE, adminToken).andExpect(jsonPath("$.completedDrivingHours").value(0));
        read("/api/schools/" + OTHER_SCHOOL + "/candidates/" + CANDIDATE, adminToken).andExpect(status().isForbidden());
        read(candidates, candidateToken).andExpect(status().isForbidden());
    }

    @Test
    void simultaneousCandidateAndInstructorReservationsHaveOneWinner() throws Exception {
        Instant start = future();
        assertRace(
            () -> postJson(BASE + "/lessons/candidate/reservations", candidateToken, "{\"startAt\":\"" + start + "\"}"),
            () -> postJson(BASE + "/lessons/instructor/reservations", instructorToken, reservation(CANDIDATE, start)), 201);
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM lessons WHERE start_at=?", Integer.class, java.sql.Timestamp.from(start))).isEqualTo(1);
    }

    @Test
    void differentCandidatesCannotReserveSameInstructorConcurrently() throws Exception {
        jdbc.update("UPDATE candidates SET assigned_instructor_profile_id=? WHERE id=?", id(INSTRUCTOR), id(OTHER_CANDIDATE));
        Instant start = future();
        assertRace(
            () -> postJson(BASE + "/lessons", adminToken, lessonBody(CANDIDATE, start)),
            () -> postJson(BASE + "/lessons", adminToken, lessonBody(OTHER_CANDIDATE, start)), 201);
        // Touching intervals are allowed; a rejected reservation must not poison retry.
        postJson(BASE + "/lessons", adminToken, lessonBody(OTHER_CANDIDATE, start.plusSeconds(3600)))
            .andExpect(status().isCreated());
    }

    @Test
    void simultaneousReconfirmationAndReservationCannotReopenAnOccupiedSlot() throws Exception {
        Instant start = future();
        jdbc.update("UPDATE lessons SET status='CANCELLED',start_at=?,end_at=? WHERE id=?", java.sql.Timestamp.from(start), java.sql.Timestamp.from(start.plusSeconds(3600)), id(LESSON));
        assertRace(
            () -> postJson(BASE + "/lessons/" + LESSON + "/confirm", instructorToken, "{}"),
            () -> postJson(BASE + "/lessons/candidate/reservations", candidateToken, "{\"startAt\":\"" + start + "\"}"), -1);
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM lessons WHERE start_at=? AND status <> 'CANCELLED'", Integer.class, java.sql.Timestamp.from(start))).isEqualTo(1);
    }

    @Test
    void reassignedCandidateCannotOverlapOldAndNewInstructorsDuringRace() throws Exception {
        Instant start = future();
        jdbc.update("UPDATE candidates SET assigned_instructor_profile_id=? WHERE id=?", id(OTHER_INSTRUCTOR), id(CANDIDATE));
        jdbc.update("UPDATE lessons SET status='CANCELLED',start_at=?,end_at=? WHERE id=?", java.sql.Timestamp.from(start), java.sql.Timestamp.from(start.plusSeconds(3600)), id(LESSON));
        assertRace(
            () -> postJson(BASE + "/lessons/" + LESSON + "/confirm", instructorToken, "{}"),
            () -> postJson(BASE + "/lessons/instructor/reservations", otherInstructorToken, reservation(CANDIDATE, start)), -1);
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM lessons WHERE candidate_id=? AND start_at=? AND status <> 'CANCELLED'", Integer.class, id(CANDIDATE), java.sql.Timestamp.from(start))).isEqualTo(1);
    }

    @Test
    void movingLessonAndCreatingReservationShareTheSameOverlapProtection() throws Exception {
        jdbc.update("UPDATE candidates SET assigned_instructor_profile_id=? WHERE id=?", id(INSTRUCTOR), id(OTHER_CANDIDATE));
        Instant start = future();
        assertRace(
            () -> mvc.perform(put(BASE + "/lessons/" + LESSON).header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON).content(lessonBody(CANDIDATE, start))),
            () -> postJson(BASE + "/lessons", adminToken, lessonBody(OTHER_CANDIDATE, start)), -1);
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM lessons WHERE start_at=? AND status <> 'CANCELLED'", Integer.class, java.sql.Timestamp.from(start))).isEqualTo(1);
    }

    @Test
    void adminConflictNamesResourceAndActualIntervalWithoutLeakingOtherCandidate() throws Exception {
        String body = lessonBody(CANDIDATE, Instant.parse("2026-09-08T08:30:00Z"));
        postJson(BASE + "/lessons", adminToken, body)
            .andExpect(status().isConflict())
            .andExpect(jsonPath("$.code").value("CONFLICT"))
            .andExpect(jsonPath("$.message").value("Instruktor već ima termin 08.09.2026. 08:00 – 08.09.2026. 09:00 UTC. Odaberite drugo vrijeme."));
        // After reassignment the historical instructor differs, but the candidate remains occupied.
        jdbc.update("UPDATE candidates SET assigned_instructor_profile_id=? WHERE id=?", id(OTHER_INSTRUCTOR), id(CANDIDATE));
        postJson(BASE + "/lessons", adminToken, body.replace(INSTRUCTOR, OTHER_INSTRUCTOR))
            .andExpect(status().isConflict())
            .andExpect(jsonPath("$.message").value("Kandidat već ima termin 08.09.2026. 08:00 – 08.09.2026. 09:00 UTC. Odaberite drugo vrijeme."));
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM lessons", Integer.class)).isEqualTo(2);
    }

    @Test
    void adminStatusFiltersIncludeFinalStatusesAndCancelledSlotCanBeReused() throws Exception {
        for (String lessonStatus : List.of("REQUESTED", "CONFIRMED", "COMPLETED", "NO_SHOW", "CANCELLED")) {
            jdbc.update("UPDATE lessons SET status=? WHERE id=?", lessonStatus, id(LESSON));
            read(BASE + "/lessons?from=2026-09-08T00:00:00Z&to=2026-09-09T00:00:00Z&status=" + lessonStatus, adminToken)
                .andExpect(status().isOk()).andExpect(jsonPath("$[0].status").value(lessonStatus));
        }
        postJson(BASE + "/lessons", adminToken, lessonBody(CANDIDATE, Instant.parse("2026-09-08T08:00:00Z")))
            .andExpect(status().isCreated());
    }

    @Test
    void instructorProfileAndHistoryRespectAssignmentSchoolAndActiveAccess() throws Exception {
        String profile = BASE + "/candidates/instructor/" + CANDIDATE;
        String history = BASE + "/lessons/instructor/candidates/" + CANDIDATE;
        read(profile, instructorToken).andExpect(status().isOk()).andExpect(jsonPath("$.id").value(CANDIDATE));
        read(history, instructorToken).andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(1))
            .andExpect(jsonPath("$[0].id").value(LESSON));
        for (String route : List.of(profile, history)) {
            assertError(read(route, otherInstructorToken), 403, "FORBIDDEN", route);
            assertError(read(route, candidateToken), 403, "FORBIDDEN", route);
            assertError(read(route.replace(SCHOOL, OTHER_SCHOOL), instructorToken), 403, "FORBIDDEN", route.replace(SCHOOL, OTHER_SCHOOL));
            String absent = route.replace(CANDIDATE, "50000000-0000-0000-0000-000000000099");
            assertError(read(absent, instructorToken), 404, "NOT_FOUND", absent);
        }
        // A newly assigned instructor may read the profile, but not the old instructor's notes.
        jdbc.update("UPDATE candidates SET assigned_instructor_profile_id=? WHERE id=?", id(OTHER_INSTRUCTOR), id(CANDIDATE));
        read(profile, otherInstructorToken).andExpect(status().isOk());
        read(history, otherInstructorToken).andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(0));
        assertError(read(profile, instructorToken), 403, "FORBIDDEN", profile);
        assertError(read(history, instructorToken), 403, "FORBIDDEN", history);
        jdbc.update("UPDATE instructor_profiles SET active=false WHERE id=?", id(OTHER_INSTRUCTOR));
        assertError(read(profile, otherInstructorToken), 403, "FORBIDDEN", profile);
        assertError(read(history, otherInstructorToken), 403, "FORBIDDEN", history);
    }

    @Test
    void completionRefreshesProfileHistoryAndHoursWithoutDoubleCounting() throws Exception {
        jdbc.update("UPDATE lessons SET status='CONFIRMED', start_at=?, end_at=? WHERE id=?",
            java.sql.Timestamp.from(Instant.now().minusSeconds(7200)), java.sql.Timestamp.from(Instant.now().minusSeconds(3600)), id(LESSON));
        postJson(BASE + "/lessons/" + LESSON + "/complete", instructorToken, "{\"note\":\"Internal practice note\"}")
            .andExpect(status().isOk()).andExpect(jsonPath("$.status").value("COMPLETED"));
        read(BASE + "/candidates/instructor/" + CANDIDATE, instructorToken)
            .andExpect(status().isOk()).andExpect(jsonPath("$.completedDrivingHours").value(1));
        read(BASE + "/lessons/instructor/candidates/" + CANDIDATE, instructorToken)
            .andExpect(status().isOk()).andExpect(jsonPath("$[0].completionNote").value("Internal practice note"));
        postJson(BASE + "/lessons/" + LESSON + "/complete", instructorToken, "{}")
            .andExpect(status().isConflict());
        read(BASE + "/candidates/" + CANDIDATE + "/progress", instructorToken)
            .andExpect(status().isOk()).andExpect(jsonPath("$.completedDrivingHours").value(1));
    }

    @Test
    void proposalRequiresCandidateConsentAndNeverAddsHours() throws Exception {
        var proposed = future();
        postJson(BASE + "/lessons/" + LESSON + "/propose", instructorToken, proposal(proposed))
            .andExpect(status().isOk()).andExpect(jsonPath("$.status").value("REQUESTED"))
            .andExpect(jsonPath("$.proposedStartAt").value(proposed.toString()));
        postJson(BASE + "/lessons/" + LESSON + "/confirm", instructorToken, "{}").andExpect(status().isConflict());
        read(BASE + "/candidate-portal", candidateToken).andExpect(status().isOk())
            .andExpect(jsonPath("$.completedDrivingHours").value(0))
            .andExpect(jsonPath("$.lessons[0].proposedStartAt").value(proposed.toString()))
            .andExpect(jsonPath("$.lessons[0].notes").doesNotExist());
        postJson(BASE + "/lessons/candidate/" + LESSON + "/proposal-response", candidateToken, response(proposed, true))
            .andExpect(status().isNoContent());
        read(BASE + "/candidate-portal", candidateToken).andExpect(jsonPath("$.lessons[0].status").value("CONFIRMED"))
            .andExpect(jsonPath("$.lessons[0].startAt").value(proposed.toString()))
            .andExpect(jsonPath("$.completedDrivingHours").value(0));
        postJson(BASE + "/lessons/candidate/" + LESSON + "/proposal-response", candidateToken, response(proposed, true))
            .andExpect(status().isConflict());
        postJson(BASE + "/lessons/" + LESSON + "/reject", instructorToken, "{}").andExpect(status().isConflict());
    }

    @Test
    void proposalRejectAndStaleResponsePreserveDecisionBoundaries() throws Exception {
        var start = future();
        postJson(BASE + "/lessons/" + LESSON + "/propose", instructorToken, proposal(start)).andExpect(status().isOk());
        postJson(BASE + "/lessons/" + LESSON + "/propose", instructorToken, proposal(start.plusSeconds(7200))).andExpect(status().isOk());
        String route = BASE + "/lessons/candidate/" + LESSON + "/proposal-response";
        postJson(route, candidateToken, response(start, true)).andExpect(status().isConflict());
        postJson(route, candidateToken, response(start.plusSeconds(7200), false)).andExpect(status().isNoContent());
        postJson(BASE + "/lessons/" + LESSON + "/confirm", instructorToken, "{}").andExpect(status().isConflict());
        assertThat(jdbc.queryForObject("SELECT status FROM lessons WHERE id=?", String.class, id(LESSON))).isEqualTo("CANCELLED");
    }

    @Test
    void allRequestDecisionsRecheckAssignmentMembershipAndOwnership() throws Exception {
        var start = future();
        for (String action : List.of("confirm", "reject", "propose")) {
            postJson(BASE + "/lessons/" + LESSON + "/" + action, otherInstructorToken, proposal(start)).andExpect(status().isForbidden());
            postJson("/api/schools/" + OTHER_SCHOOL + "/lessons/" + LESSON + "/" + action, instructorToken, proposal(start)).andExpect(status().isForbidden());
        }
        postJson(BASE + "/lessons/" + LESSON + "/propose", instructorToken, proposal(start)).andExpect(status().isOk());
        String responseRoute = BASE + "/lessons/candidate/" + OTHER_LESSON + "/proposal-response";
        postJson(responseRoute, candidateToken, response(start, true)).andExpect(status().isForbidden());
        jdbc.update("UPDATE candidates SET assigned_instructor_profile_id=? WHERE id=?", id(OTHER_INSTRUCTOR), id(CANDIDATE));
        for (String action : List.of("confirm", "reject", "propose")) {
            postJson(BASE + "/lessons/" + LESSON + "/" + action, instructorToken, proposal(start)).andExpect(status().isConflict());
        }
        postJson(BASE + "/lessons/candidate/" + LESSON + "/proposal-response", candidateToken, response(start, true)).andExpect(status().isConflict());
        jdbc.update("UPDATE candidates SET assigned_instructor_profile_id=? WHERE id=?", id(INSTRUCTOR), id(CANDIDATE));
        jdbc.update("UPDATE school_memberships SET status='INACTIVE' WHERE id=?", id("30000000-0000-0000-0000-000000000001"));
        postJson(BASE + "/lessons/" + LESSON + "/reject", instructorToken, "{}").andExpect(status().isForbidden());
        postJson(BASE + "/lessons/candidate/" + LESSON + "/proposal-response", candidateToken, response(start, true)).andExpect(status().isForbidden());
    }

    @Test
    void competingConfirmAndRejectHaveOneWinner() throws Exception {
        assertRace(() -> postJson(BASE + "/lessons/" + LESSON + "/confirm", instructorToken, "{}"),
            () -> postJson(BASE + "/lessons/" + LESSON + "/reject", instructorToken, "{}"), 200);
    }

    @Test
    void workingHoursBreaksAndAbsenceAreEnforcedWithoutDeletingLessons() throws Exception {
        var start = future();
        String availability = BASE + "/instructors/me/availability";
        read(availability, instructorToken).andExpect(status().isOk()).andExpect(jsonPath("$.timeZone").value("Europe/Zagreb"));
        putJson(availability, instructorToken, block(start, "BREAK")).andExpect(status().isOk());
        postJson(BASE + "/lessons/candidate/reservations", candidateToken, proposal(start)).andExpect(status().isConflict());
        postJson(BASE + "/lessons/instructor/reservations", instructorToken, reservation(CANDIDATE, start)).andExpect(status().isConflict());
        postJson(BASE + "/lessons", adminToken, lessonBody(CANDIDATE, start)).andExpect(status().isConflict());
        putJson(availability, instructorToken, "{\"rules\":[],\"blocks\":[]}").andExpect(status().isOk());
        postJson(BASE + "/lessons/instructor/reservations", instructorToken, reservation(CANDIDATE, start)).andExpect(status().isCreated());
        putJson(availability, instructorToken, block(start, "ABSENCE")).andExpect(status().isConflict());
        assertThat(jdbc.queryForObject("SELECT count(*) FROM lessons WHERE status='CONFIRMED'", Long.class)).isEqualTo(1);
        int otherDay = start.atZone(java.time.ZoneId.of("Europe/Zagreb")).getDayOfWeek().getValue() % 7 + 1;
        String rules = "{\"rules\":[{\"dayOfWeek\":" + otherDay + ",\"startTime\":\"08:00\",\"endTime\":\"16:00\"}],\"blocks\":[]}";
        putJson(availability, instructorToken, rules).andExpect(status().isConflict());
        jdbc.update("UPDATE lessons SET status='CANCELLED'");
        putJson(availability, instructorToken, rules).andExpect(status().isOk());
        postJson(BASE + "/lessons/candidate/reservations", candidateToken, proposal(start)).andExpect(status().isConflict());
        putJson(BASE + "/instructors/" + INSTRUCTOR + "/availability", candidateToken, rules).andExpect(status().isForbidden());
        putJson(BASE + "/instructors/" + INSTRUCTOR + "/availability", adminToken, "{\"rules\":[],\"blocks\":[]}").andExpect(status().isOk());
    }

    @Test
    void proposalAcceptanceRacesAbsenceAndRechecksNewConflicts() throws Exception {
        var start = future();
        postJson(BASE + "/lessons/" + LESSON + "/propose", instructorToken, proposal(start)).andExpect(status().isOk());
        var pool = Executors.newFixedThreadPool(2);
        var gate = new CountDownLatch(1);
        try {
            var accept = pool.submit(() -> { gate.await(); return postJson(BASE + "/lessons/candidate/" + LESSON + "/proposal-response", candidateToken, response(start, true)).andReturn().getResponse().getStatus(); });
            var absence = pool.submit(() -> { gate.await(); return putJson(BASE + "/instructors/me/availability", instructorToken, block(start, "ABSENCE")).andReturn().getResponse().getStatus(); });
            gate.countDown();
            var results = List.of(accept.get(15, TimeUnit.SECONDS), absence.get(15, TimeUnit.SECONDS));
            assertThat(results).contains(409);
            assertThat(results.stream().filter(code -> code == 200 || code == 204).count()).isEqualTo(1);
        } finally { gate.countDown(); pool.shutdownNow(); }
    }

    @Test
    void acceptingTwoProposalsForTheSameSlotOnlyConfirmsOne() throws Exception {
        var start = future();
        jdbc.update("UPDATE candidates SET assigned_instructor_profile_id=? WHERE id=?", id(INSTRUCTOR), id(OTHER_CANDIDATE));
        jdbc.update("UPDATE lessons SET instructor_profile_id=?, proposed_start_at=? WHERE id IN (?,?)", id(INSTRUCTOR), java.sql.Timestamp.from(start), id(LESSON), id(OTHER_LESSON));
        // Give the second candidate an independent candidate membership for this race.
        jdbc.update("UPDATE candidates SET user_id=? WHERE id=?", id("20000000-0000-0000-0000-000000000002"), id(OTHER_CANDIDATE));
        jdbc.update("UPDATE school_memberships SET role_id=? WHERE id=?", id("00000000-0000-0000-0000-000000000003"), id("30000000-0000-0000-0000-000000000002"));
        assertRace(() -> postJson(BASE + "/lessons/candidate/" + LESSON + "/proposal-response", candidateToken, response(start, true)),
            () -> postJson(BASE + "/lessons/candidate/" + OTHER_LESSON + "/proposal-response", otherInstructorToken, response(start, true)), 204);
    }

    private String proposal(Instant start) { return "{\"startAt\":\"" + start + "\"}"; }
    private String response(Instant start, boolean accept) { return "{\"startAt\":\"" + start + "\",\"accept\":" + accept + "}"; }
    private String block(Instant start, String kind) { return "{\"rules\":[],\"blocks\":[{\"startAt\":\"" + start + "\",\"endAt\":\"" + start.plusSeconds(3600) + "\",\"kind\":\"" + kind + "\"}]}"; }
    private ResultActions putJson(String path, String token, String body) throws Exception {
        return mvc.perform(put(path).header("Authorization", "Bearer " + token).contentType(MediaType.APPLICATION_JSON).content(body));
    }

    private void assertRace(Callable<ResultActions> a, Callable<ResultActions> b, int success) throws Exception {
        var pool = Executors.newFixedThreadPool(2);
        var ready = new CountDownLatch(2);
        var start = new CountDownLatch(1);
        try {
            var futures = List.of(a, b).stream().map(action -> pool.submit(() -> {
                ready.countDown();
                if (!start.await(10, TimeUnit.SECONDS)) throw new AssertionError("Race start timed out");
                var result = action.call();
                int status = result.andReturn().getResponse().getStatus();
                if (status == 409) {
                    assertError(result, 409, "CONFLICT", result.andReturn().getRequest().getRequestURI());
                }
                return status;
            })).toList();
            assertThat(ready.await(10, TimeUnit.SECONDS)).isTrue();
            start.countDown();
            List<Integer> statuses = List.of(futures.get(0).get(15, TimeUnit.SECONDS), futures.get(1).get(15, TimeUnit.SECONDS));
            if (success == -1) {
                assertThat(statuses).contains(409);
                assertThat(statuses.stream().filter(code -> code == 200 || code == 201).count()).isEqualTo(1);
            } else {
                assertThat(statuses).containsExactlyInAnyOrder(success, 409);
            }
        } finally {
            start.countDown();
            pool.shutdownNow();
        }
    }

    private ResultActions read(String path, String token) throws Exception {
        return mvc.perform(get(path).header("Authorization", "Bearer " + token));
    }
    private ResultActions postJson(String path, String token, String body) throws Exception {
        return mvc.perform(post(path).header("Authorization", "Bearer " + token).contentType(MediaType.APPLICATION_JSON).content(body));
    }
    private void assertError(ResultActions result, int status, String code, String path) throws Exception {
        result.andExpect(status().is(status)).andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
            .andExpect(jsonPath("$.status").value(status)).andExpect(jsonPath("$.code").value(code))
            .andExpect(jsonPath("$.message").isNotEmpty()).andExpect(jsonPath("$.path").value(path));
    }
    private String token(int n) { return jwt.createAccessToken(id("20000000-0000-0000-0000-00000000000" + n), "user" + n + "@example.com"); }
    private static UUID id(String value) { return UUID.fromString(value); }
    private Instant future() { return Instant.now().plusSeconds(86400).truncatedTo(java.time.temporal.ChronoUnit.SECONDS); }
    private String reservation(String candidate, Instant start) { return "{\"candidateId\":\"" + candidate + "\",\"startAt\":\"" + start + "\"}"; }
    private String lessonBody(String candidate, Instant start) {
        return "{\"candidateId\":\"" + candidate + "\",\"instructorId\":\"" + INSTRUCTOR + "\",\"startAt\":\"" + start + "\"}";
    }
}
