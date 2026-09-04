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

    @Test
    void meWithoutTokenReturnsUnauthorized() throws Exception {
        mockMvc.perform(get("/api/me"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    @Sql(statements = {
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

        mockMvc.perform(get("/api/schools/" + schoolId + "/candidates")
                .header("Authorization", "Bearer " + accessToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$[0].firstName").value("Ana"))
            .andExpect(jsonPath("$[0].lastName").value("Anic"))
            .andExpect(jsonPath("$[0].categoryCode").value("B"));
    }

    @Test
    @Sql(statements = {
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

        String createInstructorPayload = """
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

        mockMvc.perform(get("/api/schools/" + schoolId + "/instructors")
                .header("Authorization", "Bearer " + accessToken)
                .queryParam("active", "false")
                .queryParam("categoryCode", "a"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.length()").value(1))
            .andExpect(jsonPath("$[0].id").value(instructorId));
    }
}
