package com.autoskola365.backend.candidate;

import java.util.UUID;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;

public record UpdateCandidateRequest(
    @NotBlank String firstName,
    @NotBlank String lastName,
    @Email String email,
    String phone,
    String oib,
    @NotBlank String status,
    @NotBlank String categoryCode,
    UUID assignedInstructorId,
    String notes,
    @Positive Integer requiredDrivingHours,
    @jakarta.validation.constraints.Size(min = 8, max = 72) String loginPassword
) {
}
