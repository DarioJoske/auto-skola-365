package com.autoskola365.backend.lesson;

import java.util.Arrays;

public enum LessonType {
    DRIVING,
    THEORY,
    EXAM;

    public String value() {
        return name();
    }

    public static String normalizeOrDefault(String rawType) {
        if (rawType == null || rawType.isBlank()) {
            return DRIVING.value();
        }

        return normalize(rawType);
    }

    public static String normalize(String rawType) {
        String normalized = rawType.trim().replace(' ', '_').replace('-', '_').toUpperCase();
        boolean allowed = Arrays.stream(values())
            .anyMatch(type -> type.name().equals(normalized));

        if (!allowed) {
            throw new InvalidLessonException("Lesson type is not supported.");
        }

        return normalized;
    }
}
