package com.autoskola365.backend.lesson;

import java.util.Arrays;

public enum LessonStatus {
    REQUESTED,
    CONFIRMED,
    COMPLETED,
    CANCELLED,
    NO_SHOW;

    public String value() {
        return name();
    }

    public static String normalizeOrDefault(String rawStatus) {
        if (rawStatus == null || rawStatus.isBlank()) {
            return REQUESTED.value();
        }

        return normalize(rawStatus);
    }

    public static String normalize(String rawStatus) {
        String normalized = rawStatus.trim().replace(' ', '_').replace('-', '_').toUpperCase();
        boolean allowed = Arrays.stream(values())
            .anyMatch(status -> status.name().equals(normalized));

        if (!allowed) {
            throw new InvalidLessonException("Lesson status is not supported.");
        }

        return normalized;
    }
}
