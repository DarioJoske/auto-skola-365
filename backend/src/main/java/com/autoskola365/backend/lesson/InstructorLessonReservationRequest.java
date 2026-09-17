package com.autoskola365.backend.lesson;

import java.time.Instant;
import java.util.UUID;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record InstructorLessonReservationRequest(
    @NotNull UUID candidateId,
    @NotNull Instant startAt,
    @Size(max = 2000) String notes
) {}
