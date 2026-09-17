package com.autoskola365.backend.overview;

import java.time.OffsetDateTime;
import java.util.UUID;
import com.autoskola365.backend.lesson.Lesson;

public record OverviewLesson(UUID id, UUID candidateId, String candidateName,
    UUID instructorId, String instructorName, String categoryCode, String status,
    OffsetDateTime startAt, OffsetDateTime endAt) {
    static OverviewLesson from(Lesson lesson) {
        var candidate = lesson.getCandidate();
        var user = lesson.getInstructor().getSchoolMembership().getUser();
        return new OverviewLesson(lesson.getId(), candidate.getId(),
            candidate.getFirstName() + " " + candidate.getLastName(), lesson.getInstructor().getId(),
            user.getFirstName() + " " + user.getLastName(), lesson.getDrivingCategory().getCode(),
            lesson.getStatus(), lesson.getStartAt().atZone(SchoolOverviewService.ZONE).toOffsetDateTime(),
            lesson.getEndAt().atZone(SchoolOverviewService.ZONE).toOffsetDateTime());
    }
}
