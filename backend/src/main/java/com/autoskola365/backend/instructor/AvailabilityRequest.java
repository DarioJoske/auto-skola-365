package com.autoskola365.backend.instructor;

import java.time.Instant;
import java.util.List;
import jakarta.validation.Valid;
import com.autoskola365.backend.instructor.InstructorRequest.AvailabilityRuleRequest;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
public record AvailabilityRequest(
    @NotNull List<@NotNull @Valid AvailabilityRuleRequest> rules,
    @NotNull List<@NotNull @Valid BlockRequest> blocks
) {
    public record BlockRequest(@NotNull Instant startAt, @NotNull Instant endAt,
                               @NotNull @Pattern(regexp = "BREAK|ABSENCE") String kind) {}
}
