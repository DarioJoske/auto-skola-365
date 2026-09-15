package com.autoskola365.backend.lesson;

import java.time.Instant;
import java.util.UUID;

public record LessonResponse(
    UUID id,
    UUID schoolId,
    UUID candidateId,
    String candidateName,
    UUID instructorId,
    String instructorName,
    String categoryCode,
    String categoryName,
    UUID branchId,
    String branchName,
    String lessonType,
    String status,
    Instant startAt,
    Instant endAt,
    Instant confirmedAt,
    Instant cancelledAt,
    String notes,
    Instant completedAt,
    String completionNote,
    String createdByRole
) {
}
