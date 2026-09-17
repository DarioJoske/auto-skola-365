package com.autoskola365.backend.overview;

import static org.mockito.Mockito.*;
import java.time.*;
import java.util.*;
import org.junit.jupiter.api.Test;
import com.autoskola365.backend.auth.*;
import com.autoskola365.backend.candidate.CandidateRepository;
import com.autoskola365.backend.instructor.InstructorRepository;
import com.autoskola365.backend.lesson.LessonRepository;

class SchoolOverviewTimeTest {
    @Test
    void daylightSavingDayUsesLocalMidnightsNotTwentyFourHours() {
        var authorization = mock(AuthorizationService.class);
        var lessons = mock(LessonRepository.class);
        var school = UUID.randomUUID();
        var user = new AuthenticatedUser(UUID.randomUUID(), "test@example.com");
        when(authorization.hasSchoolPermission(eq(user), eq(school), anyString())).thenReturn(true);
        var service = new SchoolOverviewService(authorization, mock(CandidateRepository.class),
            mock(InstructorRepository.class), lessons, Clock.fixed(Instant.parse("2026-03-29T12:00:00Z"), ZoneOffset.UTC));
        service.overview(school, user);
        verify(lessons).search(school, Instant.parse("2026-03-28T23:00:00Z"), Instant.parse("2026-03-29T22:00:00Z"), null, null, null);
    }
}
