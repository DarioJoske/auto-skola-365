package com.autoskola365.backend.lesson;

import static org.junit.jupiter.api.Assertions.*;
import java.time.Instant;
import org.junit.jupiter.api.Test;

class LessonCompletionTest {
    private final Instant now = Instant.parse("2026-09-15T10:00:00Z");

    private Lesson lesson(String status) {
        return new Lesson(null, null, null, null, null, "DRIVING", status,
            now.minusSeconds(3600), now, "Original", LessonCreatedByRole.ADMIN);
    }

    @Test
    void completesAtEndTimeWithOptionalNoteAndPreservesOriginalNotes() {
        Lesson lesson = lesson("CONFIRMED");
        lesson.complete("   ", now);
        assertEquals("COMPLETED", lesson.getStatus());
        assertEquals(now, lesson.getCompletedAt());
        assertNull(lesson.getCompletionNote());
        assertEquals("Original", lesson.getNotes());
        assertThrows(LessonConflictException.class, () -> lesson.update(null, null, null, null,
            "DRIVING", "REQUESTED", now, now.plusSeconds(3600), "Changed"));
    }

    @Test
    void rejectsNonConfirmedStatesAndEarlyCompletionWithoutChangingData() {
        for (String status : new String[]{"REQUESTED", "CANCELLED", "NO_SHOW", "COMPLETED"}) {
            Lesson lesson = lesson(status);
            assertThrows(LessonConflictException.class, () -> lesson.complete("Note", now));
            assertEquals(status, lesson.getStatus());
            assertNull(lesson.getCompletedAt());
        }
        Lesson lesson = lesson("CONFIRMED");
        assertThrows(LessonConflictException.class, () -> lesson.complete(null, now.minusSeconds(1)));
        assertEquals("CONFIRMED", lesson.getStatus());
    }
}
