package com.autoskola365.backend.overview;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public record InstructorOverviewResponse(LocalDate weekStart, LocalDate weekEnd, String timeZone,
    List<Entry> instructors) {
    public record Entry(UUID id, String name, String email, boolean active, List<String> categoryCodes,
        long confirmedLessons, long confirmedMinutes, List<AssignedCandidate> candidates) {}
    public record AssignedCandidate(UUID id, String name, String status, String categoryCode) {}
}
