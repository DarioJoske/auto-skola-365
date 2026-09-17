package com.autoskola365.backend.overview;

import java.time.LocalDate;
import java.time.Instant;
import java.util.List;

public record SchoolOverviewResponse(LocalDate date, String timeZone, Instant generatedAt,
    long activeCandidates, long unassignedActiveCandidates, long pendingRequests, long overdueLessons,
    long confirmedToday, long completedToday, List<OverviewLesson> todayLessons,
    List<OverviewLesson> requests, List<OverviewLesson> overdue) {}
