package com.autoskola365.backend.progress;

import java.util.UUID;

public record ProgressResponse(
    UUID candidateId,
    String candidateName,
    String categoryCode,
    long completedDrivingHours,
    Integer requiredDrivingHours
) {
}
