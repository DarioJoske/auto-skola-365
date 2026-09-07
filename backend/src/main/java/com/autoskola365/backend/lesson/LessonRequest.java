package com.autoskola365.backend.lesson;

import java.time.Instant;
import java.util.UUID;

import jakarta.validation.constraints.NotNull;

public record LessonRequest(
    @NotNull UUID candidateId,
    @NotNull UUID instructorId,
    UUID branchId,
    String lessonType,
    String status,
    @NotNull Instant startAt,
    Instant endAt,
    String notes
) {
}
