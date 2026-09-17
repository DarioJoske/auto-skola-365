package com.autoskola365.backend.auth;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.jdbc.Sql;
import org.springframework.test.web.servlet.MockMvc;

import com.jayway.jsonpath.JsonPath;

@SpringBootTest
@AutoConfigureMockMvc
class AuthFlowIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JwtService jwtService;

    @Autowired
    private org.springframework.jdbc.core.JdbcTemplate jdbcTemplate;

    @Test
    void meWithoutTokenReturnsUnauthorized() throws Exception {
        mockMvc.perform(get("/api/me"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    @Sql(statements = {
        "DELETE FROM lesson_progress",
        "DELETE FROM lessons",
        "DELETE FROM candidates",
        "DELETE FROM instructor_availability_rules",
        "DELETE FROM instructors_categories",
        "DELETE FROM instructor_profiles",
        "DELETE FROM school_memberships",
        "DELETE FROM users",
        "DELETE FROM branches",
        "DELETE FROM schools",
        "DELETE FROM role_permissions",
        "DELETE FROM roles",
        "DELETE FROM permissions",
        "DELETE FROM driving_categories",
        "INSERT INTO roles (id, \"key\", name, scope) VALUES ('00000000-0000-0000-0000-000000000001', 'school_owner', 'School Owner', 'SCHOOL')",
        "INSERT INTO permissions (id, \"key\", description) VALUES ('00000000-0000-0000-0000-000000000101', 'school.settings.manage', 'Manage school settings and branch records.')",
        "INSERT INTO permissions (id, \"key\", description) VALUES ('00000000-0000-0000-0000-000000000102', 'users.manage', 'Manage school users and memberships.')",
        "INSERT INTO permissions (id, \"key\", description) VALUES ('00000000-0000-0000-0000-000000000103', 'candidates.manage', 'Manage candidates.')",
        "INSERT INTO permissions (id, \"key\", description) VALUES ('00000000-0000-0000-0000-000000000104', 'instructors.manage', 'Manage instructors.')",
        "INSERT INTO permissions (id, \"key\", description) VALUES ('00000000-0000-0000-0000-000000000105', 'lessons.manage', 'Manage lesson scheduling.')",
        "INSERT INTO role_permissions (role_id, permission_id) VALUES ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000101')",
        "INSERT INTO role_permissions (role_id, permission_id) VALUES ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000102')",
        "INSERT INTO role_permissions (role_id, permission_id) VALUES ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000103')",
        "INSERT INTO role_permissions (role_id, permission_id) VALUES ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000104')",
        "INSERT INTO role_permissions (role_id, permission_id) VALUES ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000105')",
        "INSERT INTO driving_categories (id, code, name, active) VALUES ('00000000-0000-0000-0000-000000000201', 'B', 'Passenger car', true)"
    })
    void loginReturnsTokenAndMeReturnsMemberships() throws Exception {
        String createTenantPayload = """
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
            """;

        mockMvc.perform(post("/api/platform/tenants")
                .contentType(MediaType.APPLICATION_JSON)
                .content(createTenantPayload))
            .andExpect(status().isCreated());

        String loginPayload = """
            {
              "email": "owner@example.com",
              "password": "change-me-123"
            }
            """;

        String loginResponse = mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(loginPayload))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.tokenType").value("Bearer"))
            .andExpect(jsonPath("$.accessToken").isString())
            .andExpect(jsonPath("$.user.email").value("owner@example.com"))
            .andExpect(jsonPath("$.user.memberships[0].schoolName").value("Auto Skola Demo"))
            .andExpect(jsonPath("$.user.memberships[0].roleKey").value("school_owner"))
            .andReturn()
            .getResponse()
            .getContentAsString();

        String accessToken = JsonPath.read(loginResponse, "$.accessToken");

        mockMvc.perform(get("/api/me")
                .header("Authorization", "Bearer " + accessToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.email").value("owner@example.com"))
            .andExpect(jsonPath("$.memberships[0].schoolName").value("Auto Skola Demo"))
            .andExpect(jsonPath("$.memberships[0].roleKey").value("school_owner"))
            .andExpect(jsonPath("$.memberships[0].permissions").isArray());
    }

    @Test
    @Sql(statements = {
        "DELETE FROM lesson_progress",
        "DELETE FROM lessons",
        "DELETE FROM candidates",
        "DELETE FROM instructor_availability_rules",
        "DELETE FROM instructors_categories",
        "DELETE FROM instructor_profiles",
        "DELETE FROM school_memberships",
        "DELETE FROM users",
        "DELETE FROM branches",
        "DELETE FROM schools",
        "DELETE FROM role_permissions",
        "DELETE FROM roles",
        "DELETE FROM permissions",
        "DELETE FROM driving_categories",
        "INSERT INTO roles (id, \"key\", name, scope) VALUES ('00000000-0000-0000-0000-000000000001', 'school_owner', 'School Owner', 'SCHOOL')",
        "INSERT INTO permissions (id, \"key\", description) VALUES ('00000000-0000-0000-0000-000000000103', 'candidates.manage', 'Manage candidates.')",
        "INSERT INTO role_permissions (role_id, permission_id) VALUES ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000103')",
        "INSERT INTO driving_categories (id, code, name, active) VALUES ('00000000-0000-0000-0000-000000000201', 'B', 'Passenger car', true)"
    })
    void ownerCanCreateAndListCandidates() throws Exception {
        String createTenantPayload = """
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
            """;

        mockMvc.perform(post("/api/platform/tenants")
                .contentType(MediaType.APPLICATION_JSON)
                .content(createTenantPayload))
            .andExpect(status().isCreated());

        String loginPayload = """
            {
              "email": "owner@example.com",
              "password": "change-me-123"
            }
            """;

        String loginResponse = mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(loginPayload))
            .andExpect(status().isOk())
            .andReturn()
            .getResponse()
            .getContentAsString();

        String accessToken = JsonPath.read(loginResponse, "$.accessToken");
        String schoolId = JsonPath.read(loginResponse, "$.user.memberships[0].schoolId");

        String createCandidatePayload = """
            {
              "firstName": "Ana",
              "lastName": "Anic",
              "email": "ana@example.com",
              "phone": "+385 91 000 111",
              "oib": "98765432109",
              "categoryCode": "B",
              "notes": "Prvi kandidat"
            }
            """;

        mockMvc.perform(post("/api/schools/" + schoolId + "/candidates")
                .header("Authorization", "Bearer " + accessToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(createCandidatePayload))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.firstName").value("Ana"))
            .andExpect(jsonPath("$.status").value("LEAD"))
            .andExpect(jsonPath("$.categoryCode").value("B"));

        mockMvc.perform(post("/api/schools/" + schoolId + "/candidates")
                .header("Authorization", "Bearer " + accessToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(createCandidatePayload))
            .andExpect(status().isConflict())
            .andExpect(jsonPath("$.code").value("CANDIDATE_OIB_ALREADY_EXISTS"))
            .andExpect(jsonPath("$.message").value("Kandidat s tim OIB-om vec postoji."));

        mockMvc.perform(get("/api/schools/" + schoolId + "/candidates")
                .header("Authorization", "Bearer " + accessToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$[0].firstName").value("Ana"))
            .andExpect(jsonPath("$[0].lastName").value("Anic"))
            .andExpect(jsonPath("$[0].categoryCode").value("B"));
    }

    @Test
    @Sql(statements = {
        "DELETE FROM lesson_progress",
        "DELETE FROM lessons",
        "DELETE FROM candidates",
        "DELETE FROM instructor_availability_rules",
        "DELETE FROM instructors_categories",
        "DELETE FROM instructor_profiles",
        "DELETE FROM school_memberships",
        "DELETE FROM users",
        "DELETE FROM branches",
        "DELETE FROM schools",
        "DELETE FROM role_permissions",
        "DELETE FROM roles",
        "DELETE FROM permissions",
        "DELETE FROM driving_categories",
        "INSERT INTO roles (id, \"key\", name, scope) VALUES ('00000000-0000-0000-0000-000000000001', 'school_owner', 'School Owner', 'SCHOOL')",
        "INSERT INTO permissions (id, \"key\", description) VALUES ('00000000-0000-0000-0000-000000000103', 'candidates.manage', 'Manage candidates.')",
        "INSERT INTO role_permissions (role_id, permission_id) VALUES ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000103')",
        "INSERT INTO driving_categories (id, code, name, active) VALUES ('00000000-0000-0000-0000-000000000201', 'B', 'Passenger car', true)",
        "INSERT INTO driving_categories (id, code, name, active) VALUES ('00000000-0000-0000-0000-000000000202', 'A', 'Motorcycle', true)"
    })
    void ownerCanReadUpdateAndFilterCandidates() throws Exception {
        String createTenantPayload = """
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
            """;

        mockMvc.perform(post("/api/platform/tenants")
                .contentType(MediaType.APPLICATION_JSON)
                .content(createTenantPayload))
            .andExpect(status().isCreated());

        String loginPayload = """
            {
              "email": "owner@example.com",
              "password": "change-me-123"
            }
            """;

        String loginResponse = mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(loginPayload))
            .andExpect(status().isOk())
            .andReturn()
            .getResponse()
            .getContentAsString();

        String accessToken = JsonPath.read(loginResponse, "$.accessToken");
        String schoolId = JsonPath.read(loginResponse, "$.user.memberships[0].schoolId");

        String firstCandidatePayload = """
            {
              "firstName": "Ana",
              "lastName": "Anic",
              "email": "ana@example.com",
              "phone": "+385 91 000 111",
              "oib": "98765432109",
              "status": "enrolled",
              "categoryCode": "B",
              "notes": "Prvi kandidat"
            }
            """;

        String createResponse = mockMvc.perform(post("/api/schools/" + schoolId + "/candidates")
                .header("Authorization", "Bearer " + accessToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(firstCandidatePayload))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.status").value("ENROLLED"))
            .andReturn()
            .getResponse()
            .getContentAsString();

        String candidateId = JsonPath.read(createResponse, "$.id");

        String secondCandidatePayload = """
            {
              "firstName": "Marko",
              "lastName": "Maric",
              "email": "marko@example.com",
              "phone": "+385 91 000 333",
              "oib": "12312312312",
              "status": "lead",
              "categoryCode": "A",
              "notes": "Drugi kandidat"
            }
            """;

        mockMvc.perform(post("/api/schools/" + schoolId + "/candidates")
                .header("Authorization", "Bearer " + accessToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(secondCandidatePayload))
            .andExpect(status().isCreated());

        mockMvc.perform(get("/api/schools/" + schoolId + "/candidates/" + candidateId)
                .header("Authorization", "Bearer " + accessToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.firstName").value("Ana"))
            .andExpect(jsonPath("$.status").value("ENROLLED"));

        String updateCandidatePayload = """
            {
              "firstName": "Ana",
              "lastName": "Anic Horvat",
              "email": "ana.horvat@example.com",
              "phone": "+385 91 000 222",
              "oib": "98765432109",
              "status": "in driving",
              "categoryCode": "B",
              "notes": "Prebacena u voznju"
            }
            """;

        mockMvc.perform(put("/api/schools/" + schoolId + "/candidates/" + candidateId)
                .header("Authorization", "Bearer " + accessToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(updateCandidatePayload))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.lastName").value("Anic Horvat"))
            .andExpect(jsonPath("$.email").value("ana.horvat@example.com"))
            .andExpect(jsonPath("$.status").value("IN_DRIVING"));

        mockMvc.perform(get("/api/schools/" + schoolId + "/candidates")
                .header("Authorization", "Bearer " + accessToken)
                .queryParam("status", "IN_DRIVING")
                .queryParam("categoryCode", "b")
                .queryParam("q", "horvat"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.length()").value(1))
            .andExpect(jsonPath("$[0].id").value(candidateId));
    }

    @Test
    @Sql(statements = {
        "DELETE FROM lesson_progress",
        "DELETE FROM lessons",
        "DELETE FROM candidates",
        "DELETE FROM instructor_availability_rules",
        "DELETE FROM instructors_categories",
        "DELETE FROM instructor_profiles",
        "DELETE FROM school_memberships",
        "DELETE FROM users",
        "DELETE FROM branches",
        "DELETE FROM schools",
        "DELETE FROM role_permissions",
        "DELETE FROM roles",
        "DELETE FROM permissions",
        "DELETE FROM driving_categories",
        "INSERT INTO roles (id, \"key\", name, scope) VALUES ('00000000-0000-0000-0000-000000000001', 'school_owner', 'School Owner', 'SCHOOL')",
        "INSERT INTO roles (id, \"key\", name, scope) VALUES ('00000000-0000-0000-0000-000000000002', 'instructor', 'Instructor', 'SCHOOL')",
        "INSERT INTO permissions (id, \"key\", description) VALUES ('00000000-0000-0000-0000-000000000104', 'instructors.manage', 'Manage instructors.')",
        "INSERT INTO role_permissions (role_id, permission_id) VALUES ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000104')",
        "INSERT INTO driving_categories (id, code, name, active) VALUES ('00000000-0000-0000-0000-000000000201', 'B', 'Passenger car', true)",
        "INSERT INTO driving_categories (id, code, name, active) VALUES ('00000000-0000-0000-0000-000000000202', 'A', 'Motorcycle', true)"
    })
    void ownerCanCreateReadUpdateAndFilterInstructors() throws Exception {
        String createTenantPayload = """
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
            """;

        mockMvc.perform(post("/api/platform/tenants")
                .contentType(MediaType.APPLICATION_JSON)
                .content(createTenantPayload))
            .andExpect(status().isCreated());

        String loginPayload = """
            {
              "email": "owner@example.com",
              "password": "change-me-123"
            }
            """;

        String loginResponse = mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(loginPayload))
            .andExpect(status().isOk())
            .andReturn()
            .getResponse()
            .getContentAsString();

        String accessToken = JsonPath.read(loginResponse, "$.accessToken");
        String schoolId = JsonPath.read(loginResponse, "$.user.memberships[0].schoolId");

        String createInstructorWithoutPasswordPayload = """
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
            """;

        mockMvc.perform(post("/api/schools/" + schoolId + "/instructors")
                .header("Authorization", "Bearer " + accessToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(createInstructorWithoutPasswordPayload))
            .andExpect(status().isBadRequest());

        String createInstructorPayload = """
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
            """;

        String createResponse = mockMvc.perform(post("/api/schools/" + schoolId + "/instructors")
                .header("Authorization", "Bearer " + accessToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(createInstructorPayload))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.firstName").value("Ivan"))
            .andExpect(jsonPath("$.categoryCodes[0]").value("B"))
            .andExpect(jsonPath("$.availabilityRules[0].dayOfWeek").value(1))
            .andReturn()
            .getResponse()
            .getContentAsString();

        String instructorId = JsonPath.read(createResponse, "$.id");

        mockMvc.perform(get("/api/schools/" + schoolId + "/instructors/" + instructorId)
                .header("Authorization", "Bearer " + accessToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.email").value("ivan@example.com"));

        String instructorLoginPayload = """
            {
              "email": "ivan@example.com",
              "password": "instruktor-123"
            }
            """;

        mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(instructorLoginPayload))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.user.memberships[0].roleKey").value("instructor"));

        String updateInstructorPayload = """
            {
              "firstName": "Ivan",
              "lastName": "Ivic Horvat",
              "email": "ivan@example.com",
              "phone": "+385 91 111 333",
              "licenseNumber": "ZG-99999",
              "active": false,
              "categoryCodes": ["A", "B"],
              "availabilityRules": [
                {
                  "dayOfWeek": 2,
                  "startTime": "09:00:00",
                  "endTime": "17:00:00"
                }
              ]
            }
            """;

        mockMvc.perform(put("/api/schools/" + schoolId + "/instructors/" + instructorId)
                .header("Authorization", "Bearer " + accessToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(updateInstructorPayload))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.lastName").value("Ivic Horvat"))
            .andExpect(jsonPath("$.active").value(false))
            .andExpect(jsonPath("$.categoryCodes.length()").value(2))
            .andExpect(jsonPath("$.availabilityRules.length()").value(1))
            .andExpect(jsonPath("$.availabilityRules[0].dayOfWeek").value(2));

        mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(instructorLoginPayload))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.user.memberships[0].roleKey").value("instructor"));

        String resetInstructorPasswordPayload = """
            {
              "firstName": "Ivan",
              "lastName": "Ivic Horvat",
              "email": "ivan@example.com",
              "password": "nova-lozinka-123",
              "phone": "+385 91 111 333",
              "licenseNumber": "ZG-99999",
              "active": false,
              "categoryCodes": ["A", "B"],
              "availabilityRules": [
                {
                  "dayOfWeek": 2,
                  "startTime": "09:00:00",
                  "endTime": "17:00:00"
                }
              ]
            }
            """;

        mockMvc.perform(put("/api/schools/" + schoolId + "/instructors/" + instructorId)
                .header("Authorization", "Bearer " + accessToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(resetInstructorPasswordPayload))
            .andExpect(status().isOk());

        String resetInstructorLoginPayload = """
            {
              "email": "ivan@example.com",
              "password": "nova-lozinka-123"
            }
            """;

        mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(resetInstructorLoginPayload))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.user.memberships[0].roleKey").value("instructor"));

        String duplicateAvailabilityPayload = """
            {
              "firstName": "Ivan",
              "lastName": "Ivic Horvat",
              "email": "ivan@example.com",
              "phone": "+385 91 111 333",
              "licenseNumber": "ZG-99999",
              "active": false,
              "categoryCodes": ["A", "B"],
              "availabilityRules": [
                {
                  "dayOfWeek": 2,
                  "startTime": "09:00:00",
                  "endTime": "17:00:00"
                },
                {
                  "dayOfWeek": 2,
                  "startTime": "09:00:00",
                  "endTime": "17:00:00"
                }
              ]
            }
            """;

        mockMvc.perform(put("/api/schools/" + schoolId + "/instructors/" + instructorId)
                .header("Authorization", "Bearer " + accessToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(duplicateAvailabilityPayload))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.availabilityRules.length()").value(1));

        mockMvc.perform(get("/api/schools/" + schoolId + "/instructors/" + instructorId)
                .header("Authorization", "Bearer " + accessToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.availabilityRules.length()").value(1));

        mockMvc.perform(get("/api/schools/" + schoolId + "/instructors")
                .header("Authorization", "Bearer " + accessToken)
                .queryParam("active", "false")
                .queryParam("categoryCode", "a"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.length()").value(1))
            .andExpect(jsonPath("$[0].id").value(instructorId))
            .andExpect(jsonPath("$[0].availabilityRules.length()").value(1));
    }

    @Test
    @Sql(statements = {
        "DELETE FROM lesson_progress",
        "DELETE FROM lessons",
        "DELETE FROM candidates",
        "DELETE FROM instructor_availability_rules",
        "DELETE FROM instructors_categories",
        "DELETE FROM instructor_profiles",
        "DELETE FROM school_memberships",
        "DELETE FROM users",
        "DELETE FROM branches",
        "DELETE FROM schools",
        "DELETE FROM role_permissions",
        "DELETE FROM roles",
        "DELETE FROM permissions",
        "DELETE FROM driving_categories",
        "INSERT INTO roles (id, \"key\", name, scope) VALUES ('00000000-0000-0000-0000-000000000001', 'school_owner', 'School Owner', 'SCHOOL')",
        "INSERT INTO roles (id, \"key\", name, scope) VALUES ('00000000-0000-0000-0000-000000000002', 'instructor', 'Instructor', 'SCHOOL')",
        "INSERT INTO permissions (id, \"key\", description) VALUES ('00000000-0000-0000-0000-000000000103', 'candidates.manage', 'Manage candidates.')",
        "INSERT INTO permissions (id, \"key\", description) VALUES ('00000000-0000-0000-0000-000000000104', 'instructors.manage', 'Manage instructors.')",
        "INSERT INTO permissions (id, \"key\", description) VALUES ('00000000-0000-0000-0000-000000000105', 'lessons.manage', 'Manage lesson scheduling.')",
        "INSERT INTO role_permissions (role_id, permission_id) VALUES ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000103')",
        "INSERT INTO role_permissions (role_id, permission_id) VALUES ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000104')",
        "INSERT INTO role_permissions (role_id, permission_id) VALUES ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000105')",
        "INSERT INTO driving_categories (id, code, name, active) VALUES ('00000000-0000-0000-0000-000000000201', 'B', 'Passenger car', true)"
    })
    void ownerCanCreateConfirmCancelAndPreventOverlappingLessons() throws Exception {
        String createTenantPayload = """
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
            """;

        mockMvc.perform(post("/api/platform/tenants")
                .contentType(MediaType.APPLICATION_JSON)
                .content(createTenantPayload))
            .andExpect(status().isCreated());

        String loginPayload = """
            {
              "email": "owner@example.com",
              "password": "change-me-123"
            }
            """;

        String loginResponse = mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(loginPayload))
            .andExpect(status().isOk())
            .andReturn()
            .getResponse()
            .getContentAsString();

        String accessToken = JsonPath.read(loginResponse, "$.accessToken");
        String schoolId = JsonPath.read(loginResponse, "$.user.memberships[0].schoolId");

        String createInstructorPayload = """
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
            """;

        String instructorResponse = mockMvc.perform(post("/api/schools/" + schoolId + "/instructors")
                .header("Authorization", "Bearer " + accessToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(createInstructorPayload))
            .andExpect(status().isCreated())
            .andReturn()
            .getResponse()
            .getContentAsString();

        String instructorId = JsonPath.read(instructorResponse, "$.id");

        String createCandidatePayload = """
            {
              "firstName": "Ana",
              "lastName": "Anic",
              "email": "ana@example.com",
              "phone": "+385 91 000 111",
              "oib": "98765432109",
              "status": "ENROLLED",
              "categoryCode": "B",
              "assignedInstructorId": "%s",
              "notes": "Kandidat za voznju"
            }
            """.formatted(instructorId);

        String candidateResponse = mockMvc.perform(post("/api/schools/" + schoolId + "/candidates")
                .header("Authorization", "Bearer " + accessToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(createCandidatePayload))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.assignedInstructorId").value(instructorId))
            .andReturn()
            .getResponse()
            .getContentAsString();

        String candidateId = JsonPath.read(candidateResponse, "$.id");

        String createLessonPayload = """
            {
              "candidateId": "%s",
              "instructorId": "%s",
              "lessonType": "DRIVING",
              "startAt": "2026-09-08T08:00:00Z",
              "notes": "Prvi sat voznje"
            }
            """.formatted(candidateId, instructorId);

        String lessonResponse = mockMvc.perform(post("/api/schools/" + schoolId + "/lessons")
                .header("Authorization", "Bearer " + accessToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(createLessonPayload))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.status").value("REQUESTED"))
            .andExpect(jsonPath("$.lessonType").value("DRIVING"))
            .andExpect(jsonPath("$.endAt").value("2026-09-08T09:00:00Z"))
            .andReturn()
            .getResponse()
            .getContentAsString();

        String lessonId = JsonPath.read(lessonResponse, "$.id");

        mockMvc.perform(post("/api/schools/" + schoolId + "/lessons")
                .header("Authorization", "Bearer " + accessToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(createLessonPayload))
            .andExpect(status().isConflict());

        mockMvc.perform(get("/api/schools/" + schoolId + "/lessons")
                .header("Authorization", "Bearer " + accessToken)
                .queryParam("from", "2026-09-08T00:00:00Z")
                .queryParam("to", "2026-09-09T00:00:00Z"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.length()").value(1))
            .andExpect(jsonPath("$[0].id").value(lessonId));

        mockMvc.perform(post("/api/schools/" + schoolId + "/lessons/" + lessonId + "/confirm")
                .header("Authorization", "Bearer " + accessToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("CONFIRMED"))
            .andExpect(jsonPath("$.confirmedAt").isString());

        mockMvc.perform(post("/api/schools/" + schoolId + "/lessons/" + lessonId + "/cancel")
                .header("Authorization", "Bearer " + accessToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("CANCELLED"))
            .andExpect(jsonPath("$.cancelledAt").isString());

        mockMvc.perform(post("/api/schools/" + schoolId + "/lessons")
                .header("Authorization", "Bearer " + accessToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(createLessonPayload))
            .andExpect(status().isCreated());
    }

    @Test
    @Sql(statements = {
        "DELETE FROM lesson_progress",
        "DELETE FROM lessons",
        "DELETE FROM candidates",
        "DELETE FROM instructor_availability_rules",
        "DELETE FROM instructors_categories",
        "DELETE FROM instructor_profiles",
        "DELETE FROM school_memberships",
        "DELETE FROM users",
        "DELETE FROM branches",
        "DELETE FROM schools",
        "DELETE FROM role_permissions",
        "DELETE FROM roles",
        "DELETE FROM permissions",
        "DELETE FROM driving_categories",
        "INSERT INTO roles (id, \"key\", name, scope) VALUES ('00000000-0000-0000-0000-000000000002', 'instructor', 'Instructor', 'SCHOOL')",
        "INSERT INTO permissions (id, \"key\", description) VALUES ('00000000-0000-0000-0000-000000000106', 'lessons.view_assigned', 'View assigned instructor lessons.')",
        "INSERT INTO role_permissions (role_id, permission_id) VALUES ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000106')",
        "INSERT INTO schools (id, name, status, created_at, updated_at) VALUES ('10000000-0000-0000-0000-000000000001', 'Auto Skola Demo', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO users (id, email, password_hash, first_name, last_name, status, created_at, updated_at) VALUES ('20000000-0000-0000-0000-000000000001', 'ivan@example.com', 'x', 'Ivan', 'Ivic', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO users (id, email, password_hash, first_name, last_name, status, created_at, updated_at) VALUES ('20000000-0000-0000-0000-000000000002', 'marko@example.com', 'x', 'Marko', 'Maric', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO school_memberships (id, school_id, user_id, role_id, status, created_at, updated_at) VALUES ('30000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO school_memberships (id, school_id, user_id, role_id, status, created_at, updated_at) VALUES ('30000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO driving_categories (id, code, name, active) VALUES ('00000000-0000-0000-0000-000000000201', 'B', 'Passenger car', true)",
        "INSERT INTO instructor_profiles (id, school_membership_id, license_number, active, created_at, updated_at) VALUES ('40000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', 'ZG-1', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO instructor_profiles (id, school_membership_id, license_number, active, created_at, updated_at) VALUES ('40000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000002', 'ZG-2', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO instructors_categories (instructor_profile_id, driving_category_id) VALUES ('40000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000201')",
        "INSERT INTO instructors_categories (instructor_profile_id, driving_category_id) VALUES ('40000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000201')",
        "INSERT INTO candidates (id, school_id, driving_category_id, assigned_instructor_profile_id, first_name, last_name, status, created_at, updated_at) VALUES ('50000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000201', '40000000-0000-0000-0000-000000000001', 'Ana', 'Anic', 'ENROLLED', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO candidates (id, school_id, driving_category_id, assigned_instructor_profile_id, first_name, last_name, status, created_at, updated_at) VALUES ('50000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000201', '40000000-0000-0000-0000-000000000002', 'Mia', 'Matic', 'ENROLLED', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO lessons (id, school_id, candidate_id, instructor_profile_id, driving_category_id, lesson_type, status, start_at, end_at, created_by_role, created_at, updated_at) VALUES ('60000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000201', 'DRIVING', 'REQUESTED', '2026-09-08T08:00:00Z', '2026-09-08T09:00:00Z', 'CANDIDATE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO lessons (id, school_id, candidate_id, instructor_profile_id, driving_category_id, lesson_type, status, start_at, end_at, created_by_role, created_at, updated_at) VALUES ('60000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000002', '40000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000201', 'DRIVING', 'REQUESTED', '2026-09-08T10:00:00Z', '2026-09-08T11:00:00Z', 'CANDIDATE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
    })
    void instructorReservationUsesCurrentAssignmentAndAdminCannotBypassIt() throws Exception {
        String school = "10000000-0000-0000-0000-000000000001";
        String candidate = "50000000-0000-0000-0000-000000000001";
        String instructor = "40000000-0000-0000-0000-000000000001";
        String otherInstructor = "40000000-0000-0000-0000-000000000002";
        String token = jwtService.createAccessToken(java.util.UUID.fromString("20000000-0000-0000-0000-000000000001"), "ivan@example.com");
        String base = "/api/schools/" + school;
        String endpoint = base + "/lessons/instructor/reservations";
        var startAt = java.time.Instant.now().plusSeconds(86400).truncatedTo(java.time.temporal.ChronoUnit.SECONDS);
        String payload = "{\"candidateId\":\"%s\",\"startAt\":\"%s\",\"notes\":\"Vožnja\"}".formatted(candidate, startAt);
        mockMvc.perform(post(endpoint).contentType(MediaType.APPLICATION_JSON).content(payload))
            .andExpect(status().isUnauthorized());
        mockMvc.perform(post(endpoint.replace(school, "10000000-0000-0000-0000-000000000002"))
                .header("Authorization", "Bearer " + token).contentType(MediaType.APPLICATION_JSON).content(payload))
            .andExpect(status().isForbidden());
        mockMvc.perform(post(endpoint).header("Authorization", "Bearer " + token).contentType(MediaType.APPLICATION_JSON)
                .content(payload.replace(candidate, "50000000-0000-0000-0000-000000000002")))
            .andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("CONFLICT"));
        mockMvc.perform(post(endpoint).header("Authorization", "Bearer " + token).contentType(MediaType.APPLICATION_JSON)
                .content(payload.replace(startAt.toString(), "2020-01-01T08:00:00Z")))
            .andExpect(status().isBadRequest());
        String response = mockMvc.perform(post(endpoint).header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content(payload))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.status").value("CONFIRMED"))
            .andExpect(jsonPath("$.instructorId").value(instructor))
            .andExpect(jsonPath("$.createdByRole").value("INSTRUCTOR"))
            .andExpect(jsonPath("$.endAt").value(startAt.plusSeconds(3600).toString()))
            .andReturn().getResponse().getContentAsString();
        String lessonId = JsonPath.read(response, "$.id");
        mockMvc.perform(post(endpoint).header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content(payload))
            .andExpect(status().isConflict());
        jdbcTemplate.update("UPDATE lessons SET start_at = ?, end_at = ? WHERE id = ?",
            java.sql.Timestamp.from(java.time.Instant.now().minusSeconds(7200)),
            java.sql.Timestamp.from(java.time.Instant.now().minusSeconds(3600)), java.util.UUID.fromString(lessonId));
        mockMvc.perform(post(base + "/lessons/" + lessonId + "/complete").header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content("{}"))
            .andExpect(status().isOk());
        mockMvc.perform(get(base + "/candidates/" + candidate + "/progress").header("Authorization", "Bearer " + token))
            .andExpect(status().isOk()).andExpect(jsonPath("$.completedDrivingHours").value(1));
        jdbcTemplate.update("UPDATE candidates SET assigned_instructor_profile_id = ? WHERE id = ?",
            java.util.UUID.fromString(otherInstructor), java.util.UUID.fromString(candidate));
        mockMvc.perform(get(base + "/candidates/instructor").header("Authorization", "Bearer " + token))
            .andExpect(status().isOk()).andExpect(jsonPath("$.length()").value(0));
        mockMvc.perform(post(endpoint).header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content(payload))
            .andExpect(status().isConflict());
        jdbcTemplate.update("INSERT INTO permissions (id, \"key\", description) VALUES (?, 'lessons.manage', 'Manage lessons')",
            java.util.UUID.fromString("00000000-0000-0000-0000-000000000108"));
        jdbcTemplate.update("INSERT INTO role_permissions (role_id, permission_id) VALUES (?, ?)",
            java.util.UUID.fromString("00000000-0000-0000-0000-000000000002"), java.util.UUID.fromString("00000000-0000-0000-0000-000000000108"));
        String adminPayload = "{\"candidateId\":\"%s\",\"instructorId\":\"%s\",\"startAt\":\"%s\"}".formatted(candidate, instructor, startAt);
        mockMvc.perform(post(base + "/lessons").header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content(adminPayload))
            .andExpect(status().isConflict());
        mockMvc.perform(post(base + "/lessons").header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content(adminPayload.replace(instructor, otherInstructor)))
            .andExpect(status().isCreated());
        jdbcTemplate.update("UPDATE instructor_profiles SET active = false WHERE id = ?", java.util.UUID.fromString(instructor));
        mockMvc.perform(post(endpoint).header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content(payload))
            .andExpect(status().isForbidden());
    }

    @Test
    @Sql(statements = {
        "DELETE FROM lesson_progress",
        "DELETE FROM lessons",
        "DELETE FROM candidates",
        "DELETE FROM instructor_availability_rules",
        "DELETE FROM instructors_categories",
        "DELETE FROM instructor_profiles",
        "DELETE FROM school_memberships",
        "DELETE FROM users",
        "DELETE FROM branches",
        "DELETE FROM schools",
        "DELETE FROM role_permissions",
        "DELETE FROM roles",
        "DELETE FROM permissions",
        "DELETE FROM driving_categories",
        "INSERT INTO roles (id, \"key\", name, scope) VALUES ('00000000-0000-0000-0000-000000000002', 'instructor', 'Instructor', 'SCHOOL')",
        "INSERT INTO permissions (id, \"key\", description) VALUES ('00000000-0000-0000-0000-000000000106', 'lessons.view_assigned', 'View assigned instructor lessons.')",
        "INSERT INTO role_permissions (role_id, permission_id) VALUES ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000106')",
        "INSERT INTO schools (id, name, status, created_at, updated_at) VALUES ('10000000-0000-0000-0000-000000000001', 'Auto Skola Demo', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO users (id, email, password_hash, first_name, last_name, status, created_at, updated_at) VALUES ('20000000-0000-0000-0000-000000000001', 'ivan@example.com', 'x', 'Ivan', 'Ivic', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO users (id, email, password_hash, first_name, last_name, status, created_at, updated_at) VALUES ('20000000-0000-0000-0000-000000000002', 'marko@example.com', 'x', 'Marko', 'Maric', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO school_memberships (id, school_id, user_id, role_id, status, created_at, updated_at) VALUES ('30000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO school_memberships (id, school_id, user_id, role_id, status, created_at, updated_at) VALUES ('30000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO driving_categories (id, code, name, active) VALUES ('00000000-0000-0000-0000-000000000201', 'B', 'Passenger car', true)",
        "INSERT INTO instructor_profiles (id, school_membership_id, license_number, active, created_at, updated_at) VALUES ('40000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', 'ZG-1', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO instructor_profiles (id, school_membership_id, license_number, active, created_at, updated_at) VALUES ('40000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000002', 'ZG-2', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO instructors_categories (instructor_profile_id, driving_category_id) VALUES ('40000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000201')",
        "INSERT INTO instructors_categories (instructor_profile_id, driving_category_id) VALUES ('40000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000201')",
        "INSERT INTO candidates (id, school_id, driving_category_id, assigned_instructor_profile_id, first_name, last_name, status, created_at, updated_at) VALUES ('50000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000201', '40000000-0000-0000-0000-000000000001', 'Ana', 'Anic', 'ENROLLED', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO candidates (id, school_id, driving_category_id, assigned_instructor_profile_id, first_name, last_name, status, created_at, updated_at) VALUES ('50000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000201', '40000000-0000-0000-0000-000000000002', 'Mia', 'Matic', 'ENROLLED', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO lessons (id, school_id, candidate_id, instructor_profile_id, driving_category_id, lesson_type, status, start_at, end_at, created_by_role, created_at, updated_at) VALUES ('60000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000201', 'DRIVING', 'REQUESTED', '2026-09-08T08:00:00Z', '2026-09-08T09:00:00Z', 'CANDIDATE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO lessons (id, school_id, candidate_id, instructor_profile_id, driving_category_id, lesson_type, status, start_at, end_at, created_by_role, created_at, updated_at) VALUES ('60000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000002', '40000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000201', 'DRIVING', 'REQUESTED', '2026-09-08T10:00:00Z', '2026-09-08T11:00:00Z', 'CANDIDATE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
    })
    void instructorCanListGetConfirmAndCancelOnlyOwnLessons() throws Exception {
        String instructorToken = jwtService.createAccessToken(
            java.util.UUID.fromString("20000000-0000-0000-0000-000000000001"),
            "ivan@example.com"
        );

        mockMvc.perform(get("/api/schools/10000000-0000-0000-0000-000000000001/lessons/instructor")
                .header("Authorization", "Bearer " + instructorToken)
                .queryParam("from", "2026-09-08T00:00:00Z")
                .queryParam("to", "2026-09-09T00:00:00Z"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.length()").value(1))
            .andExpect(jsonPath("$[0].id").value("60000000-0000-0000-0000-000000000001"))
            .andExpect(jsonPath("$[0].instructorId").value("40000000-0000-0000-0000-000000000001"));

        mockMvc.perform(get("/api/schools/10000000-0000-0000-0000-000000000001/candidates/instructor")
                .header("Authorization", "Bearer " + instructorToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.length()").value(1))
            .andExpect(jsonPath("$[0].id").value("50000000-0000-0000-0000-000000000001"))
            .andExpect(jsonPath("$[0].firstName").value("Ana"))
            .andExpect(jsonPath("$[0].assignedInstructorId").value("40000000-0000-0000-0000-000000000001"));

        mockMvc.perform(get("/api/schools/10000000-0000-0000-0000-000000000001/candidates/instructor")
                .header("Authorization", "Bearer " + instructorToken)
                .queryParam("q", "Mia"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.length()").value(0));

        mockMvc.perform(get("/api/schools/10000000-0000-0000-0000-000000000001/lessons/instructor/60000000-0000-0000-0000-000000000002")
                .header("Authorization", "Bearer " + instructorToken))
            .andExpect(status().isForbidden());

        mockMvc.perform(post("/api/schools/10000000-0000-0000-0000-000000000001/lessons/60000000-0000-0000-0000-000000000001/confirm")
                .header("Authorization", "Bearer " + instructorToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("CONFIRMED"))
            .andExpect(jsonPath("$.confirmedAt").isString());

        mockMvc.perform(post("/api/schools/10000000-0000-0000-0000-000000000001/lessons/60000000-0000-0000-0000-000000000001/cancel")
                .header("Authorization", "Bearer " + instructorToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("CANCELLED"))
            .andExpect(jsonPath("$.cancelledAt").isString());
    }

    @Test
    @Sql(statements = {
        "DELETE FROM lesson_progress",
        "DELETE FROM lessons",
        "DELETE FROM candidates",
        "DELETE FROM instructor_availability_rules",
        "DELETE FROM instructors_categories",
        "DELETE FROM instructor_profiles",
        "DELETE FROM school_memberships",
        "DELETE FROM users",
        "DELETE FROM branches",
        "DELETE FROM schools",
        "DELETE FROM role_permissions",
        "DELETE FROM roles",
        "DELETE FROM permissions",
        "DELETE FROM driving_categories",
        "INSERT INTO roles (id, \"key\", name, scope) VALUES ('00000000-0000-0000-0000-000000000002', 'instructor', 'Instructor', 'SCHOOL')",
        "INSERT INTO roles (id, \"key\", name, scope) VALUES ('00000000-0000-0000-0000-000000000003', 'candidate', 'Candidate', 'SCHOOL')",
        "INSERT INTO permissions (id, \"key\", description) VALUES ('00000000-0000-0000-0000-000000000106', 'lessons.view_assigned', 'View assigned instructor lessons.')",
        "INSERT INTO permissions (id, \"key\", description) VALUES ('00000000-0000-0000-0000-000000000107', 'lessons.reserve_own', 'Reserve own candidate lessons.')",
        "INSERT INTO role_permissions (role_id, permission_id) VALUES ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000106')",
        "INSERT INTO role_permissions (role_id, permission_id) VALUES ('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000107')",
        "INSERT INTO schools (id, name, status, created_at, updated_at) VALUES ('10000000-0000-0000-0000-000000000001', 'Auto Skola Demo', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO users (id, email, password_hash, first_name, last_name, status, created_at, updated_at) VALUES ('20000000-0000-0000-0000-000000000001', 'ivan@example.com', 'x', 'Ivan', 'Ivic', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO users (id, email, password_hash, first_name, last_name, status, created_at, updated_at) VALUES ('20000000-0000-0000-0000-000000000003', 'ana@example.com', 'x', 'Ana', 'Anic', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO users (id, email, password_hash, first_name, last_name, status, created_at, updated_at) VALUES ('20000000-0000-0000-0000-000000000004', 'mia@example.com', 'x', 'Mia', 'Matic', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO school_memberships (id, school_id, user_id, role_id, status, created_at, updated_at) VALUES ('30000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO school_memberships (id, school_id, user_id, role_id, status, created_at, updated_at) VALUES ('30000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000003', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO school_memberships (id, school_id, user_id, role_id, status, created_at, updated_at) VALUES ('30000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000003', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO driving_categories (id, code, name, active) VALUES ('00000000-0000-0000-0000-000000000201', 'B', 'Passenger car', true)",
        "INSERT INTO instructor_profiles (id, school_membership_id, license_number, active, created_at, updated_at) VALUES ('40000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', 'ZG-1', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO instructors_categories (instructor_profile_id, driving_category_id) VALUES ('40000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000201')",
        "INSERT INTO candidates (id, school_id, driving_category_id, assigned_instructor_profile_id, user_id, first_name, last_name, status, created_at, updated_at) VALUES ('50000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000201', '40000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000003', 'Ana', 'Anic', 'ENROLLED', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO candidates (id, school_id, driving_category_id, user_id, first_name, last_name, status, created_at, updated_at) VALUES ('50000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000201', '20000000-0000-0000-0000-000000000004', 'Mia', 'Matic', 'ENROLLED', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
    })
    void adminActivatesCandidateLoginAndPortalShowsOnlyOwnPublicData() throws Exception {
        String school = "10000000-0000-0000-0000-000000000001";
        String instructor = "40000000-0000-0000-0000-000000000001";
        String token = jwtService.createAccessToken(java.util.UUID.fromString("20000000-0000-0000-0000-000000000001"), "ivan@example.com");
        String base = "/api/schools/" + school;
        jdbcTemplate.update("INSERT INTO permissions (id, \"key\", description) VALUES (?, 'candidates.manage', 'Manage candidates')",
            java.util.UUID.fromString("00000000-0000-0000-0000-000000000109"));
        jdbcTemplate.update("INSERT INTO role_permissions (role_id, permission_id) VALUES (?, ?)",
            java.util.UUID.fromString("00000000-0000-0000-0000-000000000002"), java.util.UUID.fromString("00000000-0000-0000-0000-000000000109"));
        String payload = """
            {"firstName":"Iva","lastName":"Ivić","email":"iva.portal@example.com","categoryCode":"B",
             "assignedInstructorId":"%s","notes":"Internal school note","loginPassword":"Candidate123!"}
            """.formatted(instructor);
        String created = mockMvc.perform(post(base + "/candidates").header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content(payload))
            .andExpect(status().isCreated()).andExpect(jsonPath("$.hasLogin").value(true))
            .andExpect(jsonPath("$.loginEmail").value("iva.portal@example.com"))
            .andExpect(jsonPath("$.loginPassword").doesNotExist()).andReturn().getResponse().getContentAsString();
        String candidate = JsonPath.read(created, "$.id");
        String login = mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"iva.portal@example.com\",\"password\":\"Candidate123!\"}"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.user.memberships[0].roleKey").value("candidate"))
            .andReturn().getResponse().getContentAsString();
        String candidateToken = JsonPath.read(login, "$.accessToken");
        String updatePayload = payload.replace("Candidate123!", "UpdatedPass123!")
            .replace("\"categoryCode\":\"B\"", "\"categoryCode\":\"B\",\"status\":\"ENROLLED\"")
            .replace("iva.portal@example.com", "contact@example.com");
        mockMvc.perform(put(base + "/candidates/" + candidate).header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content(updatePayload))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.email").value("contact@example.com"))
            .andExpect(jsonPath("$.loginEmail").value("iva.portal@example.com"))
            .andExpect(jsonPath("$.loginPassword").doesNotExist());
        mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"iva.portal@example.com\",\"password\":\"Candidate123!\"}"))
            .andExpect(status().isUnauthorized());
        String updatedCredentials = "{\"email\":\"iva.portal@example.com\",\"password\":\"UpdatedPass123!\"}";
        mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON).content(updatedCredentials))
            .andExpect(status().isOk());
        String currentHash = jdbcTemplate.queryForObject(
            "SELECT password_hash FROM users WHERE email = 'iva.portal@example.com'", String.class);
        org.junit.jupiter.api.Assertions.assertNotEquals("UpdatedPass123!", currentHash);
        mockMvc.perform(put(base + "/candidates/" + candidate).header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(updatePayload.replace(",\"loginPassword\":\"UpdatedPass123!\"", "")))
            .andExpect(status().isOk());
        mockMvc.perform(put(base + "/candidates/" + candidate).header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content(updatePayload.replace("UpdatedPass123!", "short")))
            .andExpect(status().isBadRequest());
        mockMvc.perform(put(base + "/candidates/" + candidate).header("Authorization", "Bearer " + candidateToken)
                .contentType(MediaType.APPLICATION_JSON).content(updatePayload))
            .andExpect(status().isForbidden());
        mockMvc.perform(put(base.replace(school, "10000000-0000-0000-0000-000000000002") + "/candidates/" + candidate)
                .header("Authorization", "Bearer " + token).contentType(MediaType.APPLICATION_JSON).content(updatePayload))
            .andExpect(status().isForbidden());
        jdbcTemplate.update("UPDATE school_memberships SET role_id = ? WHERE user_id = (SELECT user_id FROM candidates WHERE id = ?)",
            java.util.UUID.fromString("00000000-0000-0000-0000-000000000002"), java.util.UUID.fromString(candidate));
        mockMvc.perform(put(base + "/candidates/" + candidate).header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content(updatePayload))
            .andExpect(status().isForbidden());
        jdbcTemplate.update("UPDATE school_memberships SET role_id = ? WHERE user_id = (SELECT user_id FROM candidates WHERE id = ?)",
            java.util.UUID.fromString("00000000-0000-0000-0000-000000000003"), java.util.UUID.fromString(candidate));
        org.junit.jupiter.api.Assertions.assertEquals(currentHash, jdbcTemplate.queryForObject(
            "SELECT password_hash FROM users WHERE email = 'iva.portal@example.com'", String.class));
        mockMvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON).content(updatedCredentials))
            .andExpect(status().isOk());

        mockMvc.perform(get(base + "/candidate-portal").header("Authorization", "Bearer " + candidateToken))
            .andExpect(status().isOk()).andExpect(jsonPath("$.candidateId").value(candidate))
            .andExpect(jsonPath("$.completedDrivingHours").value(0)).andExpect(jsonPath("$.requiredDrivingHours").value(35))
            .andExpect(jsonPath("$.notes").doesNotExist()).andExpect(jsonPath("$.canRequestLesson").value(true));
        mockMvc.perform(get(base + "/candidate-portal")).andExpect(status().isUnauthorized());
        mockMvc.perform(get(base + "/candidate-portal").header("Authorization", "Bearer " + token)).andExpect(status().isForbidden());
        mockMvc.perform(get(base.replace(school, "10000000-0000-0000-0000-000000000002") + "/candidate-portal")
                .header("Authorization", "Bearer " + candidateToken)).andExpect(status().isForbidden());
        mockMvc.perform(post(base + "/candidates").header("Authorization", "Bearer " + candidateToken)
                .contentType(MediaType.APPLICATION_JSON).content(payload)).andExpect(status().isForbidden());
        mockMvc.perform(post(base + "/candidates").header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content(payload.replace("iva.portal@example.com", "ivan@example.com")))
            .andExpect(status().isBadRequest());
        org.junit.jupiter.api.Assertions.assertEquals("x", jdbcTemplate.queryForObject(
            "SELECT password_hash FROM users WHERE email = 'ivan@example.com'", String.class));
        String startAt = java.time.Instant.now().plusSeconds(86400).toString();
        String booked = mockMvc.perform(post(base + "/lessons/candidate/reservations").header("Authorization", "Bearer " + candidateToken)
                .contentType(MediaType.APPLICATION_JSON).content("{\"startAt\":\"" + startAt + "\"}"))
            .andExpect(status().isCreated()).andExpect(jsonPath("$.status").value("REQUESTED"))
            .andReturn().getResponse().getContentAsString();
        String lesson = JsonPath.read(booked, "$.id");
        mockMvc.perform(post(base + "/lessons/" + lesson + "/confirm").header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());
        jdbcTemplate.update("UPDATE lessons SET start_at = ?, end_at = ?, notes = 'Private instructor note' WHERE id = ?",
            java.sql.Timestamp.from(java.time.Instant.now().minusSeconds(7200)),
            java.sql.Timestamp.from(java.time.Instant.now().minusSeconds(3600)), java.util.UUID.fromString(lesson));
        mockMvc.perform(post(base + "/lessons/" + lesson + "/complete").header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content("{\"note\":\"Private completion note\"}"))
            .andExpect(status().isOk());
        mockMvc.perform(get(base + "/candidate-portal").header("Authorization", "Bearer " + candidateToken))
            .andExpect(status().isOk()).andExpect(jsonPath("$.completedDrivingHours").value(1))
            .andExpect(jsonPath("$.lessons.length()").value(1)).andExpect(jsonPath("$.lessons[0].status").value("COMPLETED"))
            .andExpect(jsonPath("$.lessons[0].notes").doesNotExist()).andExpect(jsonPath("$.lessons[0].completionNote").doesNotExist());
        String otherToken = jwtService.createAccessToken(java.util.UUID.fromString("20000000-0000-0000-0000-000000000003"), "ana@example.com");
        mockMvc.perform(get(base + "/candidate-portal").header("Authorization", "Bearer " + otherToken))
            .andExpect(status().isOk()).andExpect(jsonPath("$.lessons.length()").value(0));
        jdbcTemplate.update("UPDATE candidates SET assigned_instructor_profile_id = null WHERE id = ?", java.util.UUID.fromString(candidate));
        mockMvc.perform(get(base + "/candidate-portal").header("Authorization", "Bearer " + candidateToken))
            .andExpect(status().isOk()).andExpect(jsonPath("$.canRequestLesson").value(false));
        jdbcTemplate.update("UPDATE school_memberships SET status = 'INACTIVE' WHERE user_id = (SELECT user_id FROM candidates WHERE id = ?)", java.util.UUID.fromString(candidate));
        mockMvc.perform(get(base + "/candidate-portal").header("Authorization", "Bearer " + candidateToken))
            .andExpect(status().isForbidden());
    }

    @Test
    @Sql(statements = {
        "DELETE FROM lesson_progress",
        "DELETE FROM lessons",
        "DELETE FROM candidates",
        "DELETE FROM instructor_availability_rules",
        "DELETE FROM instructors_categories",
        "DELETE FROM instructor_profiles",
        "DELETE FROM school_memberships",
        "DELETE FROM users",
        "DELETE FROM branches",
        "DELETE FROM schools",
        "DELETE FROM role_permissions",
        "DELETE FROM roles",
        "DELETE FROM permissions",
        "DELETE FROM driving_categories",
        "INSERT INTO roles (id, \"key\", name, scope) VALUES ('00000000-0000-0000-0000-000000000002', 'instructor', 'Instructor', 'SCHOOL')",
        "INSERT INTO roles (id, \"key\", name, scope) VALUES ('00000000-0000-0000-0000-000000000003', 'candidate', 'Candidate', 'SCHOOL')",
        "INSERT INTO permissions (id, \"key\", description) VALUES ('00000000-0000-0000-0000-000000000106', 'lessons.view_assigned', 'View assigned instructor lessons.')",
        "INSERT INTO permissions (id, \"key\", description) VALUES ('00000000-0000-0000-0000-000000000107', 'lessons.reserve_own', 'Reserve own candidate lessons.')",
        "INSERT INTO role_permissions (role_id, permission_id) VALUES ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000106')",
        "INSERT INTO role_permissions (role_id, permission_id) VALUES ('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000107')",
        "INSERT INTO schools (id, name, status, created_at, updated_at) VALUES ('10000000-0000-0000-0000-000000000001', 'Auto Skola Demo', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO users (id, email, password_hash, first_name, last_name, status, created_at, updated_at) VALUES ('20000000-0000-0000-0000-000000000001', 'ivan@example.com', 'x', 'Ivan', 'Ivic', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO users (id, email, password_hash, first_name, last_name, status, created_at, updated_at) VALUES ('20000000-0000-0000-0000-000000000003', 'ana@example.com', 'x', 'Ana', 'Anic', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO users (id, email, password_hash, first_name, last_name, status, created_at, updated_at) VALUES ('20000000-0000-0000-0000-000000000004', 'mia@example.com', 'x', 'Mia', 'Matic', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO school_memberships (id, school_id, user_id, role_id, status, created_at, updated_at) VALUES ('30000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO school_memberships (id, school_id, user_id, role_id, status, created_at, updated_at) VALUES ('30000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000003', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO school_memberships (id, school_id, user_id, role_id, status, created_at, updated_at) VALUES ('30000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000003', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO driving_categories (id, code, name, active) VALUES ('00000000-0000-0000-0000-000000000201', 'B', 'Passenger car', true)",
        "INSERT INTO instructor_profiles (id, school_membership_id, license_number, active, created_at, updated_at) VALUES ('40000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', 'ZG-1', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO instructors_categories (instructor_profile_id, driving_category_id) VALUES ('40000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000201')",
        "INSERT INTO candidates (id, school_id, driving_category_id, assigned_instructor_profile_id, user_id, first_name, last_name, status, created_at, updated_at) VALUES ('50000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000201', '40000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000003', 'Ana', 'Anic', 'ENROLLED', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO candidates (id, school_id, driving_category_id, user_id, first_name, last_name, status, created_at, updated_at) VALUES ('50000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000201', '20000000-0000-0000-0000-000000000004', 'Mia', 'Matic', 'ENROLLED', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
    })
    void candidateCanReserveRequestedDrivingLessonWithAssignedInstructor() throws Exception {
        String candidateToken = jwtService.createAccessToken(
            java.util.UUID.fromString("20000000-0000-0000-0000-000000000003"),
            "ana@example.com"
        );
        String reservationPayload = """
            {
              "startAt": "2026-09-08T08:00:00Z",
              "notes": "Zelim termin voznje"
            }
            """;

        mockMvc.perform(post("/api/schools/10000000-0000-0000-0000-000000000001/lessons/candidate/reservations")
                .header("Authorization", "Bearer " + candidateToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(reservationPayload))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.candidateId").value("50000000-0000-0000-0000-000000000003"))
            .andExpect(jsonPath("$.instructorId").value("40000000-0000-0000-0000-000000000001"))
            .andExpect(jsonPath("$.lessonType").value("DRIVING"))
            .andExpect(jsonPath("$.status").value("REQUESTED"))
            .andExpect(jsonPath("$.endAt").value("2026-09-08T09:00:00Z"))
            .andExpect(jsonPath("$.createdByRole").value("CANDIDATE"));

        mockMvc.perform(post("/api/schools/10000000-0000-0000-0000-000000000001/lessons/candidate/reservations")
                .header("Authorization", "Bearer " + candidateToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(reservationPayload))
            .andExpect(status().isConflict());

        String candidateWithoutInstructorToken = jwtService.createAccessToken(
            java.util.UUID.fromString("20000000-0000-0000-0000-000000000004"),
            "mia@example.com"
        );

        mockMvc.perform(post("/api/schools/10000000-0000-0000-0000-000000000001/lessons/candidate/reservations")
                .header("Authorization", "Bearer " + candidateWithoutInstructorToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(reservationPayload))
            .andExpect(status().isConflict())
            .andExpect(jsonPath("$.message").value("Candidate does not have an assigned instructor."));
    }
    @Test
    @Sql(statements = {
        "DELETE FROM lesson_progress",
        "DELETE FROM lessons",
        "DELETE FROM candidates",
        "DELETE FROM instructor_availability_rules",
        "DELETE FROM instructors_categories",
        "DELETE FROM instructor_profiles",
        "DELETE FROM school_memberships",
        "DELETE FROM users",
        "DELETE FROM branches",
        "DELETE FROM schools",
        "DELETE FROM role_permissions",
        "DELETE FROM roles",
        "DELETE FROM permissions",
        "DELETE FROM driving_categories",
        "INSERT INTO roles (id, \"key\", name, scope) VALUES ('00000000-0000-0000-0000-000000000002', 'instructor', 'Instructor', 'SCHOOL')",
        "INSERT INTO permissions (id, \"key\", description) VALUES ('00000000-0000-0000-0000-000000000106', 'lessons.view_assigned', 'View assigned instructor lessons.')",
        "INSERT INTO role_permissions (role_id, permission_id) VALUES ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000106')",
        "INSERT INTO schools (id, name, status, created_at, updated_at) VALUES ('10000000-0000-0000-0000-000000000001', 'Auto Skola Demo', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO users (id, email, password_hash, first_name, last_name, status, created_at, updated_at) VALUES ('20000000-0000-0000-0000-000000000001', 'ivan@example.com', 'x', 'Ivan', 'Ivic', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO users (id, email, password_hash, first_name, last_name, status, created_at, updated_at) VALUES ('20000000-0000-0000-0000-000000000002', 'marko@example.com', 'x', 'Marko', 'Maric', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO school_memberships (id, school_id, user_id, role_id, status, created_at, updated_at) VALUES ('30000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO school_memberships (id, school_id, user_id, role_id, status, created_at, updated_at) VALUES ('30000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO driving_categories (id, code, name, active) VALUES ('00000000-0000-0000-0000-000000000201', 'B', 'Passenger car', true)",
        "INSERT INTO instructor_profiles (id, school_membership_id, license_number, active, created_at, updated_at) VALUES ('40000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', 'ZG-1', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO instructor_profiles (id, school_membership_id, license_number, active, created_at, updated_at) VALUES ('40000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000002', 'ZG-2', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO instructors_categories (instructor_profile_id, driving_category_id) VALUES ('40000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000201')",
        "INSERT INTO instructors_categories (instructor_profile_id, driving_category_id) VALUES ('40000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000201')",
        "INSERT INTO candidates (id, school_id, driving_category_id, assigned_instructor_profile_id, first_name, last_name, status, created_at, updated_at) VALUES ('50000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000201', '40000000-0000-0000-0000-000000000001', 'Ana', 'Anic', 'ENROLLED', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO candidates (id, school_id, driving_category_id, assigned_instructor_profile_id, first_name, last_name, status, created_at, updated_at) VALUES ('50000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000201', '40000000-0000-0000-0000-000000000002', 'Mia', 'Matic', 'ENROLLED', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO lessons (id, school_id, candidate_id, instructor_profile_id, driving_category_id, lesson_type, status, start_at, end_at, created_by_role, created_at, updated_at) VALUES ('60000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000201', 'DRIVING', 'REQUESTED', '2026-09-08T08:00:00Z', '2026-09-08T09:00:00Z', 'CANDIDATE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO lessons (id, school_id, candidate_id, instructor_profile_id, driving_category_id, lesson_type, status, start_at, end_at, created_by_role, created_at, updated_at) VALUES ('60000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000002', '40000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000201', 'DRIVING', 'REQUESTED', '2026-09-08T10:00:00Z', '2026-09-08T11:00:00Z', 'CANDIDATE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
    })
    void instructorCompletesOwnPastLessonAndFinalStateIsProtected() throws Exception {
        String school = "10000000-0000-0000-0000-000000000001";
        String lessonId = "60000000-0000-0000-0000-000000000001";
        String url = "/api/schools/" + school + "/lessons/" + lessonId;
        String token = jwtService.createAccessToken(
            java.util.UUID.fromString("20000000-0000-0000-0000-000000000001"), "ivan@example.com");
        String other = jwtService.createAccessToken(
            java.util.UUID.fromString("20000000-0000-0000-0000-000000000002"), "marko@example.com");
        mockMvc.perform(post(url + "/complete").contentType(MediaType.APPLICATION_JSON).content("{}"))
            .andExpect(status().isUnauthorized());
        mockMvc.perform(post(url + "/complete").header("Authorization", "Bearer " + other)
                .contentType(MediaType.APPLICATION_JSON).content("{}"))
            .andExpect(status().isForbidden());
        mockMvc.perform(post("/api/schools/10000000-0000-0000-0000-000000000099/lessons/" + lessonId + "/complete")
                .header("Authorization", "Bearer " + token).contentType(MediaType.APPLICATION_JSON).content("{}"))
            .andExpect(status().isForbidden());
        mockMvc.perform(post(url + "/complete").header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content("{}"))
            .andExpect(status().isConflict())
            .andExpect(jsonPath("$.path").value(url + "/complete"));
        mockMvc.perform(post(url + "/confirm").header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());
        jdbcTemplate.update("UPDATE lessons SET start_at = ?, end_at = ?, notes = ? WHERE id = ?",
            java.sql.Timestamp.from(java.time.Instant.now().plusSeconds(3600)),
            java.sql.Timestamp.from(java.time.Instant.now().plusSeconds(7200)),
            "Postojeća napomena", java.util.UUID.fromString(lessonId));
        mockMvc.perform(post(url + "/complete").header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content("{}"))
            .andExpect(status().isConflict());
        jdbcTemplate.update("UPDATE lessons SET start_at = ?, end_at = ? WHERE id = ?",
            java.sql.Timestamp.from(java.time.Instant.now().minusSeconds(7200)),
            java.sql.Timestamp.from(java.time.Instant.now().minusSeconds(3600)), java.util.UUID.fromString(lessonId));
        mockMvc.perform(post(url + "/complete").header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content("{\"note\":\"" + "x".repeat(2001) + "\"}"))
            .andExpect(status().isBadRequest());
        mockMvc.perform(post(url + "/complete").header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content("{\"note\":\"  Vježbali smo parkiranje.  \"}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("COMPLETED"))
            .andExpect(jsonPath("$.completedAt").isString())
            .andExpect(jsonPath("$.completionNote").value("Vježbali smo parkiranje."))
            .andExpect(jsonPath("$.notes").value("Postojeća napomena"));
        for (String action : new String[] {"complete", "confirm", "cancel"}) {
            mockMvc.perform(post(url + "/" + action).header("Authorization", "Bearer " + token)
                    .contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isConflict());
        }
        mockMvc.perform(get("/api/schools/" + school + "/lessons/instructor/" + lessonId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("COMPLETED"))
            .andExpect(jsonPath("$.completionNote").value("Vježbali smo parkiranje."));
    }

    @Test
    @Sql(statements = {
        "DELETE FROM lesson_progress",
        "DELETE FROM lessons",
        "DELETE FROM candidates",
        "DELETE FROM instructor_availability_rules",
        "DELETE FROM instructors_categories",
        "DELETE FROM instructor_profiles",
        "DELETE FROM school_memberships",
        "DELETE FROM users",
        "DELETE FROM branches",
        "DELETE FROM schools",
        "DELETE FROM role_permissions",
        "DELETE FROM roles",
        "DELETE FROM permissions",
        "DELETE FROM driving_categories",
        "INSERT INTO roles (id, \"key\", name, scope) VALUES ('00000000-0000-0000-0000-000000000002', 'instructor', 'Instructor', 'SCHOOL')",
        "INSERT INTO permissions (id, \"key\", description) VALUES ('00000000-0000-0000-0000-000000000106', 'lessons.view_assigned', 'View assigned instructor lessons.')",
        "INSERT INTO role_permissions (role_id, permission_id) VALUES ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000106')",
        "INSERT INTO schools (id, name, status, created_at, updated_at) VALUES ('10000000-0000-0000-0000-000000000001', 'Auto Skola Demo', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO users (id, email, password_hash, first_name, last_name, status, created_at, updated_at) VALUES ('20000000-0000-0000-0000-000000000001', 'ivan@example.com', 'x', 'Ivan', 'Ivic', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO users (id, email, password_hash, first_name, last_name, status, created_at, updated_at) VALUES ('20000000-0000-0000-0000-000000000002', 'marko@example.com', 'x', 'Marko', 'Maric', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO school_memberships (id, school_id, user_id, role_id, status, created_at, updated_at) VALUES ('30000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO school_memberships (id, school_id, user_id, role_id, status, created_at, updated_at) VALUES ('30000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO driving_categories (id, code, name, active) VALUES ('00000000-0000-0000-0000-000000000201', 'B', 'Passenger car', true)",
        "INSERT INTO instructor_profiles (id, school_membership_id, license_number, active, created_at, updated_at) VALUES ('40000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', 'ZG-1', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO instructor_profiles (id, school_membership_id, license_number, active, created_at, updated_at) VALUES ('40000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000002', 'ZG-2', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO instructors_categories (instructor_profile_id, driving_category_id) VALUES ('40000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000201')",
        "INSERT INTO instructors_categories (instructor_profile_id, driving_category_id) VALUES ('40000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000201')",
        "INSERT INTO candidates (id, school_id, driving_category_id, assigned_instructor_profile_id, first_name, last_name, status, created_at, updated_at) VALUES ('50000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000201', '40000000-0000-0000-0000-000000000001', 'Ana', 'Anic', 'ENROLLED', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO candidates (id, school_id, driving_category_id, assigned_instructor_profile_id, first_name, last_name, status, created_at, updated_at) VALUES ('50000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000201', '40000000-0000-0000-0000-000000000002', 'Mia', 'Matic', 'ENROLLED', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO lessons (id, school_id, candidate_id, instructor_profile_id, driving_category_id, lesson_type, status, start_at, end_at, created_by_role, created_at, updated_at) VALUES ('60000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000201', 'DRIVING', 'REQUESTED', '2026-09-08T08:00:00Z', '2026-09-08T09:00:00Z', 'CANDIDATE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
        "INSERT INTO lessons (id, school_id, candidate_id, instructor_profile_id, driving_category_id, lesson_type, status, start_at, end_at, created_by_role, created_at, updated_at) VALUES ('60000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000002', '40000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000201', 'DRIVING', 'REQUESTED', '2026-09-08T10:00:00Z', '2026-09-08T11:00:00Z', 'CANDIDATE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
    })
    void progressCountsOnlyCompletedDrivingHoursAndRequiresAssignedAccess() throws Exception {
        String school = "10000000-0000-0000-0000-000000000001";
        String candidate = "50000000-0000-0000-0000-000000000001";
        String own = "60000000-0000-0000-0000-000000000001";
        String other = "60000000-0000-0000-0000-000000000002";
        String base = "/api/schools/" + school;
        String progress = base + "/candidates/" + candidate + "/progress";
        String lesson = base + "/lessons/" + own;
        String token = jwtService.createAccessToken(
            java.util.UUID.fromString("20000000-0000-0000-0000-000000000001"), "ivan@example.com");
        String otherToken = jwtService.createAccessToken(
            java.util.UUID.fromString("20000000-0000-0000-0000-000000000002"), "marko@example.com");

        mockMvc.perform(get(progress)).andExpect(status().isUnauthorized());
        mockMvc.perform(get(progress).header("Authorization", "Bearer " + otherToken))
            .andExpect(status().isForbidden());
        mockMvc.perform(get(base + "/lessons/" + other + "/progress").header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());
        mockMvc.perform(get(progress.replace(school, "10000000-0000-0000-0000-000000000099"))
                .header("Authorization", "Bearer " + token)).andExpect(status().isForbidden());

        jdbcTemplate.update("UPDATE lessons SET status='COMPLETED' WHERE id=?", java.util.UUID.fromString(other));
        for (String lessonStatus : new String[]{"REQUESTED", "CONFIRMED", "CANCELLED", "NO_SHOW"}) {
            jdbcTemplate.update("UPDATE lessons SET status=? WHERE id=?", lessonStatus, java.util.UUID.fromString(own));
            mockMvc.perform(get(progress).header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.completedDrivingHours").value(0))
                .andExpect(jsonPath("$.requiredDrivingHours").value(35))
                .andExpect(jsonPath("$.skills").doesNotExist())
                .andExpect(jsonPath("$.statuses").doesNotExist())
                .andExpect(jsonPath("$.entries").doesNotExist());
        }

        jdbcTemplate.update("UPDATE lessons SET status='CONFIRMED', start_at=?, end_at=? WHERE id=?",
            java.sql.Timestamp.from(java.time.Instant.now().minusSeconds(7200)),
            java.sql.Timestamp.from(java.time.Instant.now().minusSeconds(3600)), java.util.UUID.fromString(own));
        var executor = java.util.concurrent.Executors.newFixedThreadPool(2);
        var gate = new java.util.concurrent.CountDownLatch(1);
        try {
            java.util.concurrent.Callable<Integer> complete = () -> {
                gate.await();
                return mockMvc.perform(post(lesson + "/complete").header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON).content("{}"))
                    .andReturn().getResponse().getStatus();
            };
            var first = executor.submit(complete);
            var second = executor.submit(complete);
            gate.countDown();
            var responses = java.util.List.of(first.get(10, java.util.concurrent.TimeUnit.SECONDS),
                second.get(10, java.util.concurrent.TimeUnit.SECONDS));
            org.junit.jupiter.api.Assertions.assertTrue(responses.contains(200));
            org.junit.jupiter.api.Assertions.assertTrue(responses.contains(409));
        } finally {
            executor.shutdownNow();
        }
        mockMvc.perform(get(lesson + "/progress").header("Authorization", "Bearer " + token))
            .andExpect(status().isOk()).andExpect(jsonPath("$.completedDrivingHours").value(1));

        for (int i = 1; i <= 36; i++) {
            jdbcTemplate.update("""
                INSERT INTO lessons (id, school_id, candidate_id, instructor_profile_id, driving_category_id,
                    lesson_type, status, start_at, end_at, created_by_role, created_at, updated_at)
                SELECT ?, school_id, candidate_id, instructor_profile_id, driving_category_id,
                    lesson_type, status, start_at, end_at, created_by_role, created_at, updated_at
                FROM lessons WHERE id=?
                """, java.util.UUID.randomUUID(), java.util.UUID.fromString(own));
            if (i == 24) {
                mockMvc.perform(get(progress).header("Authorization", "Bearer " + token))
                    .andExpect(status().isOk()).andExpect(jsonPath("$.completedDrivingHours").value(25))
                    .andExpect(jsonPath("$.requiredDrivingHours").value(35));
            }
        }
        mockMvc.perform(get(progress).header("Authorization", "Bearer " + token))
            .andExpect(status().isOk()).andExpect(jsonPath("$.completedDrivingHours").value(37))
            .andExpect(jsonPath("$.requiredDrivingHours").value(35));
        mockMvc.perform(post(lesson + "/progress").header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content("{}"))
            .andExpect(status().isMethodNotAllowed())
            .andExpect(jsonPath("$.code").value("METHOD_NOT_ALLOWED"));

        jdbcTemplate.update("UPDATE instructor_profiles SET active=false WHERE id=?",
            java.util.UUID.fromString("40000000-0000-0000-0000-000000000001"));
        mockMvc.perform(get(progress).header("Authorization", "Bearer " + token)).andExpect(status().isForbidden());
        jdbcTemplate.update("UPDATE instructor_profiles SET active=true WHERE id=?",
            java.util.UUID.fromString("40000000-0000-0000-0000-000000000001"));

        String candidateBody = """
            {"firstName":"Ana","lastName":"Anic","status":"ENROLLED","categoryCode":"B",
             "assignedInstructorId":"40000000-0000-0000-0000-000000000001","requiredDrivingHours":30}
            """;
        mockMvc.perform(put(base + "/candidates/" + candidate).header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content(candidateBody)).andExpect(status().isForbidden());
        jdbcTemplate.update("INSERT INTO permissions (id, \"key\", description) VALUES (?, 'candidates.manage', 'Manage candidates')",
            java.util.UUID.fromString("00000000-0000-0000-0000-000000000199"));
        jdbcTemplate.update("INSERT INTO role_permissions (role_id, permission_id) VALUES (?, ?)",
            java.util.UUID.fromString("00000000-0000-0000-0000-000000000002"),
            java.util.UUID.fromString("00000000-0000-0000-0000-000000000199"));
        mockMvc.perform(put(base + "/candidates/" + candidate).header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content(candidateBody))
            .andExpect(status().isOk()).andExpect(jsonPath("$.requiredDrivingHours").value(30));
        mockMvc.perform(get(progress).header("Authorization", "Bearer " + token))
            .andExpect(status().isOk()).andExpect(jsonPath("$.requiredDrivingHours").value(30));
        mockMvc.perform(put(base + "/candidates/" + candidate).header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content(candidateBody.replace(":30", ":0")))
            .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("VALIDATION_FAILED"));
        mockMvc.perform(put(base + "/candidates/" + candidate).header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content(candidateBody.replace(",\"requiredDrivingHours\":30", "")))
            .andExpect(status().isOk()).andExpect(jsonPath("$.requiredDrivingHours").value(30));
    }

}
