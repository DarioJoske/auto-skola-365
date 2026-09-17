package com.autoskola365.backend.candidate;

import java.util.UUID;

public record CandidateResponse(
    UUID id,
    UUID schoolId,
    String firstName,
    String lastName,
    String email,
    String phone,
    String oib,
    String status,
    String categoryCode,
    String categoryName,
    UUID assignedInstructorId,
    String assignedInstructorName,
    String notes,
    Integer requiredDrivingHours,
    boolean hasLogin,
    String loginEmail
) {
}
