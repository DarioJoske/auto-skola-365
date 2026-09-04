package com.autoskola365.backend.candidate;

import java.util.Arrays;

public enum CandidateStatus {
    LEAD,
    ENROLLED,
    IN_THEORY,
    PASSED_THEORY,
    IN_DRIVING,
    READY_FOR_EXAM,
    EXAM_SCHEDULED,
    PASSED,
    DROPPED,
    ARCHIVED;

    public String value() {
        return name();
    }

    public static String normalizeOrDefault(String rawStatus) {
        if (rawStatus == null || rawStatus.isBlank()) {
            return LEAD.value();
        }

        return normalize(rawStatus);
    }

    public static String normalize(String rawStatus) {
        String normalized = rawStatus.trim().replace(' ', '_').replace('-', '_').toUpperCase();
        boolean allowed = Arrays.stream(values())
            .anyMatch(status -> status.name().equals(normalized));

        if (!allowed) {
            throw new InvalidCandidateStatusException("Candidate status is not supported.");
        }

        return normalized;
    }
}
