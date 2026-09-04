package com.autoskola365.backend.instructor;

import java.time.LocalTime;
import java.util.List;
import java.util.UUID;

public record InstructorResponse(
    UUID id,
    UUID schoolId,
    UUID userId,
    UUID membershipId,
    String firstName,
    String lastName,
    String email,
    String phone,
    String licenseNumber,
    boolean active,
    List<String> categoryCodes,
    List<AvailabilityRuleResponse> availabilityRules
) {

    public record AvailabilityRuleResponse(
        UUID id,
        int dayOfWeek,
        LocalTime startTime,
        LocalTime endTime
    ) {
    }
}
