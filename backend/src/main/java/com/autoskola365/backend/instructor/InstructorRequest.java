package com.autoskola365.backend.instructor;

import java.time.LocalTime;
import java.util.List;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

public record InstructorRequest(
    @NotBlank String firstName,
    @NotBlank String lastName,
    @Email @NotBlank String email,
    String password,
    String phone,
    String licenseNumber,
    Boolean active,
    @NotEmpty List<@NotBlank String> categoryCodes,
    List<@Valid AvailabilityRuleRequest> availabilityRules
) {

    public record AvailabilityRuleRequest(
        @Min(1) @Max(7) int dayOfWeek,
        @NotNull LocalTime startTime,
        @NotNull LocalTime endTime
    ) {
    }
}
