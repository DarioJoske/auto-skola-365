package com.autoskola365.backend.overview;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import java.time.*;
import java.time.temporal.TemporalAdjusters;
import java.sql.Timestamp;
import java.util.*;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.jdbc.Sql;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import com.autoskola365.backend.auth.JwtService;

@SpringBootTest
@AutoConfigureMockMvc
@Sql("/tenancy-regression.sql")
class SchoolOverviewIntegrationTest {
    static final UUID SCHOOL = UUID.fromString("10000000-0000-0000-0000-000000000001");
    static final UUID OTHER = UUID.fromString("10000000-0000-0000-0000-000000000002");
    static final UUID ROLE = UUID.fromString("00000000-0000-0000-0000-000000000002");
    static final String BASE = "/api/schools/" + SCHOOL;
    @Autowired MockMvc mvc;
    @Autowired JdbcTemplate jdbc;
    @Autowired JwtService jwt;
    String token;

    @BeforeEach
    void grantAdminPermissions() {
        for (String permission : List.of("lessons.manage", "candidates.manage", "instructors.manage")) {
            var id = UUID.randomUUID();
            jdbc.update("INSERT INTO permissions (id,\"key\",description) VALUES (?,?,?)", id, permission, permission);
            jdbc.update("INSERT INTO role_permissions (role_id,permission_id) VALUES (?,?)", ROLE, id);
        }
        token = jwt.createAccessToken(UUID.fromString("20000000-0000-0000-0000-000000000001"), "ivan@example.com");
        jdbc.update("INSERT INTO schools (id,name,status,created_at,updated_at) VALUES (?, 'Other','ACTIVE',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)", OTHER);
        jdbc.update("DELETE FROM lessons");
    }

    @Test
    void dashboardCountsStatusesAndSchoolLocalDayWithoutLeakingOtherSchool() throws Exception {
        var today = LocalDate.now(SchoolOverviewService.ZONE);
        var start = today.atStartOfDay(SchoolOverviewService.ZONE).toInstant();
        lesson(SCHOOL, "CONFIRMED", start, 1);
        lesson(SCHOOL, "COMPLETED", start.plusSeconds(3600), 1);
        lesson(SCHOOL, "CANCELLED", start.plusSeconds(7200), 1);
        lesson(SCHOOL, "REQUESTED", start.plusSeconds(10800), 1);
        lesson(SCHOOL, "REQUESTED", today.plusDays(1).atStartOfDay(SchoolOverviewService.ZONE).toInstant(), 1);
        lesson(SCHOOL, "CONFIRMED", start.minusSeconds(1800), 1);
        lesson(OTHER, "REQUESTED", start.plusSeconds(3600), 1);
        jdbc.update("UPDATE candidates SET assigned_instructor_profile_id=NULL WHERE first_name='Ana'");
        read("/overview").andExpect(status().isOk())
            .andExpect(jsonPath("$.date").value(today.toString()))
            .andExpect(jsonPath("$.timeZone").value("Europe/Zagreb"))
            .andExpect(jsonPath("$.activeCandidates").value(2))
            .andExpect(jsonPath("$.unassignedActiveCandidates").value(1))
            .andExpect(jsonPath("$.pendingRequests").value(2))
            .andExpect(jsonPath("$.confirmedToday").value(1))
            .andExpect(jsonPath("$.completedToday").value(1))
            .andExpect(jsonPath("$.todayLessons.length()").value(4))
            .andExpect(jsonPath("$.todayLessons[0].startAt").value(org.hamcrest.Matchers.startsWith(today + "T00:00")))
            .andExpect(jsonPath("$.todayLessons[0].notes").doesNotExist());
    }

    @Test
    void closedCandidateStatusesAreNotActiveAndAttentionIsBounded() throws Exception {
        jdbc.update("UPDATE candidates SET status='PASSED' WHERE first_name='Ana'");
        jdbc.update("UPDATE candidates SET status='LEAD' WHERE first_name='Mia'");
        for (int n = 0; n < 7; n++) lesson(SCHOOL, "REQUESTED", Instant.now().minusSeconds(7200 + n * 3600), 1);
        lesson(SCHOOL, "CONFIRMED", Instant.now().minusSeconds(7200), 1);
        lesson(SCHOOL, "COMPLETED", Instant.now().minusSeconds(10800), 1);
        read("/overview").andExpect(status().isOk())
            .andExpect(jsonPath("$.activeCandidates").value(0))
            .andExpect(jsonPath("$.pendingRequests").value(7))
            .andExpect(jsonPath("$.requests.length()").value(5))
            .andExpect(jsonPath("$.overdueLessons").value(1))
            .andExpect(jsonPath("$.overdue.length()").value(1));
    }

    @Test
    void instructorSearchAssignedCandidatesAndConfirmedWeekExcludeOtherStatusesAndSchools() throws Exception {
        var monday = LocalDate.now(SchoolOverviewService.ZONE).with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
        var start = monday.atStartOfDay(SchoolOverviewService.ZONE).toInstant();
        lesson(SCHOOL, "CONFIRMED", start, 1);
        lesson(SCHOOL, "CONFIRMED", start.plusSeconds(7200), 2);
        for (String status : List.of("REQUESTED", "COMPLETED", "CANCELLED", "NO_SHOW")) lesson(SCHOOL, status, start.plusSeconds(3600), 1);
        lesson(SCHOOL, "CONFIRMED", start.minusSeconds(1800), 1);
        lesson(SCHOOL, "CONFIRMED", monday.plusDays(7).atStartOfDay(SchoolOverviewService.ZONE).toInstant(), 1);
        lesson(OTHER, "CONFIRMED", start, 1);
        read("/instructors/overview?query=IVAN&active=true").andExpect(status().isOk())
            .andExpect(jsonPath("$.weekStart").value(monday.toString()))
            .andExpect(jsonPath("$.weekEnd").value(monday.plusDays(6).toString()))
            .andExpect(jsonPath("$.instructors.length()").value(1))
            .andExpect(jsonPath("$.instructors[0].confirmedLessons").value(1))
            .andExpect(jsonPath("$.instructors[0].confirmedMinutes").value(60))
            .andExpect(jsonPath("$.instructors[0].candidates.length()").value(1))
            .andExpect(jsonPath("$.instructors[0].candidates[0].name").value("Ana Anic"));
        read("/instructors/overview?query=absent").andExpect(status().isOk()).andExpect(jsonPath("$.instructors").isEmpty());
        read("/instructors/overview?active=false").andExpect(status().isOk()).andExpect(jsonPath("$.instructors").isEmpty());
    }

    @Test
    void endpointsRequireAuthenticationAllPermissionsAndActiveSchoolMembership() throws Exception {
        for (String path : List.of("/overview", "/instructors/overview")) {
            mvc.perform(get(BASE + path)).andExpect(status().isUnauthorized()).andExpect(jsonPath("$.code").value("UNAUTHORIZED"));
            mvc.perform(get("/api/schools/" + OTHER + path).header("Authorization", "Bearer " + token))
                .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("FORBIDDEN"));
        }
        for (String permission : List.of("lessons.manage", "candidates.manage", "instructors.manage")) {
            var id = jdbc.queryForObject("SELECT id FROM permissions WHERE \"key\"=?", UUID.class, permission);
            jdbc.update("DELETE FROM role_permissions WHERE permission_id=?", id);
            for (String path : List.of("/overview", "/instructors/overview")) read(path).andExpect(status().isForbidden());
            jdbc.update("INSERT INTO role_permissions (role_id,permission_id) VALUES (?,?)", ROLE, id);
        }
        jdbc.update("UPDATE school_memberships SET status='INACTIVE'");
        for (String path : List.of("/overview", "/instructors/overview")) read(path).andExpect(status().isForbidden());
    }

    @Test
    void candidateLinksCanSearchTheFullDisplayedName() throws Exception {
        mvc.perform(get(BASE + "/candidates").param("q", "Ana Anic").header("Authorization", "Bearer " + token))
            .andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(1))
            .andExpect(jsonPath("$[0].firstName").value("Ana"));
    }

    @Test
    void schoolWithNoOperationalDataReturnsZeroes() throws Exception {
        jdbc.update("DELETE FROM candidates");
        read("/overview").andExpect(status().isOk()).andExpect(jsonPath("$.activeCandidates").value(0))
            .andExpect(jsonPath("$.pendingRequests").value(0)).andExpect(jsonPath("$.todayLessons").isEmpty())
            .andExpect(jsonPath("$.requests").isEmpty()).andExpect(jsonPath("$.overdue").isEmpty());
    }

    private ResultActions read(String path) throws Exception {
        return mvc.perform(get(BASE + path).header("Authorization", "Bearer " + token));
    }
    private void lesson(UUID school, String status, Instant start, int instructor) {
        jdbc.update("""
            INSERT INTO lessons (id, school_id, candidate_id, instructor_profile_id, driving_category_id,
            lesson_type,status,start_at,end_at,created_by_role,created_at,updated_at)
            VALUES (?,?,?,?,?,'DRIVING',?,?,?,'ADMIN',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)
            """, UUID.randomUUID(), school, UUID.fromString("50000000-0000-0000-0000-000000000001"),
            UUID.fromString("40000000-0000-0000-0000-00000000000" + instructor),
            UUID.fromString("00000000-0000-0000-0000-000000000201"), status, Timestamp.from(start), Timestamp.from(start.plusSeconds(3600)));
    }
}
