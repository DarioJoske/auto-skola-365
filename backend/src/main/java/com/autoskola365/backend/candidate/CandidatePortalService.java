package com.autoskola365.backend.candidate;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.autoskola365.backend.auth.AuthenticatedUser;
import com.autoskola365.backend.auth.AuthorizationService;
import com.autoskola365.backend.lesson.LessonRepository;

@Service
public class CandidatePortalService {
    private final CandidateRepository candidates;
    private final LessonRepository lessons;
    private final AuthorizationService authorization;
    public CandidatePortalService(CandidateRepository candidates, LessonRepository lessons, AuthorizationService authorization) {
        this.candidates = candidates; this.lessons = lessons; this.authorization = authorization;
    }
    @Transactional(readOnly = true)
    public PortalResponse get(UUID schoolId, AuthenticatedUser user) {
        if (!authorization.hasSchoolPermission(user, schoolId, "lessons.reserve_own")) {
            throw new CandidateAccessDeniedException("Nemate pristup kandidatskoj aplikaciji ove škole.");
        }
        var candidate = candidates.findBySchoolIdAndUserId(schoolId, user.userId())
            .orElseThrow(() -> new CandidateAccessDeniedException("Vaš račun nije povezan s kandidatom. Obratite se autoškoli."));
        var instructor = candidate.getAssignedInstructor();
        String instructorName = instructor == null ? null : instructor.getSchoolMembership().getUser().getFirstName()
            + " " + instructor.getSchoolMembership().getUser().getLastName();
        var items = lessons.findBySchoolIdAndCandidateIdOrderByStartAtDesc(schoolId, candidate.getId()).stream()
            .map(lesson -> new CandidateLesson(lesson.getId(), lesson.getStatus(), lesson.getStartAt(), lesson.getEndAt(),
                lesson.getInstructor().getSchoolMembership().getUser().getFirstName() + " "
                    + lesson.getInstructor().getSchoolMembership().getUser().getLastName(),
                lesson.getBranch() == null ? null : lesson.getBranch().getName())).toList();
        long completed = lessons.countBySchoolIdAndCandidateIdAndDrivingCategoryIdAndStatusAndLessonType(
            schoolId, candidate.getId(), candidate.getDrivingCategory().getId(), "COMPLETED", "DRIVING");
        return new PortalResponse(candidate.getId(), candidate.getFirstName(), candidate.getLastName(),
            candidate.getSchool().getName(), candidate.getDrivingCategory().getCode(), instructorName,
            instructor != null && instructor.isActive(), completed, candidate.getRequiredDrivingHours(), items);
    }
    public record PortalResponse(UUID candidateId, String firstName, String lastName, String schoolName,
        String categoryCode, String instructorName, boolean canRequestLesson, long completedDrivingHours,
        Integer requiredDrivingHours, List<CandidateLesson> lessons) {}
    public record CandidateLesson(UUID id, String status, Instant startAt, Instant endAt, String instructorName, String branchName) {}
}
