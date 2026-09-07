package com.autoskola365.backend.lesson;

import java.time.Instant;
import java.util.UUID;

import jakarta.validation.constraints.NotNull;

public record CandidateLessonReservationRequest(
    UUID branchId,
    @NotNull Instant startAt,
    Instant endAt,
    String notes
) {
}
