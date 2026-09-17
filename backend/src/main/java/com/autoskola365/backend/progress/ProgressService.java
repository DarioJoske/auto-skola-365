package com.autoskola365.backend.progress;

import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.autoskola365.backend.auth.AuthenticatedUser;
import com.autoskola365.backend.auth.AuthorizationService;
import com.autoskola365.backend.candidate.Candidate;
import com.autoskola365.backend.candidate.CandidateAccessDeniedException;
import com.autoskola365.backend.candidate.CandidateNotFoundException;
import com.autoskola365.backend.candidate.CandidateRepository;
import com.autoskola365.backend.instructor.InstructorProfile;
import com.autoskola365.backend.lesson.Lesson;
import com.autoskola365.backend.lesson.LessonAccessDeniedException;
import com.autoskola365.backend.lesson.LessonNotFoundException;
import com.autoskola365.backend.lesson.LessonRepository;
import com.autoskola365.backend.lesson.LessonStatus;
import com.autoskola365.backend.lesson.LessonType;

@Service
@Transactional(readOnly = true)
public class ProgressService {

    private final CandidateRepository candidates;
    private final LessonRepository lessons;
    private final AuthorizationService auth;

    public ProgressService(CandidateRepository candidates, LessonRepository lessons, AuthorizationService auth) {
        this.candidates = candidates;
        this.lessons = lessons;
        this.auth = auth;
    }

    public ProgressResponse forCandidate(UUID schoolId, UUID candidateId, AuthenticatedUser user) {
        requireSchoolAccess(schoolId, user);
        Candidate candidate = candidates.findByIdAndSchoolId(candidateId, schoolId)
            .orElseThrow(() -> new CandidateNotFoundException("Kandidat ne postoji."));
        requireCandidateAccess(schoolId, candidate, user);
        return response(schoolId, candidate);
    }

    public ProgressResponse forLesson(UUID schoolId, UUID lessonId, AuthenticatedUser user) {
        requireSchoolAccess(schoolId, user);
        Lesson lesson = lessons.findByIdAndSchoolId(lessonId, schoolId)
            .orElseThrow(() -> new LessonNotFoundException("Termin ne postoji."));
        if (!auth.hasSchoolPermission(user, schoolId, "candidates.manage")
            && !isAssigned(lesson.getInstructor(), user)) {
            throw new LessonAccessDeniedException("Možete pregledavati samo vlastite vožnje.");
        }
        requireCandidateAccess(schoolId, lesson.getCandidate(), user);
        return response(schoolId, lesson.getCandidate());
    }

    private void requireSchoolAccess(UUID schoolId, AuthenticatedUser user) {
        if (!auth.hasSchoolPermission(user, schoolId, "lessons.view_assigned")
            && !auth.hasSchoolPermission(user, schoolId, "candidates.manage")) {
            throw new CandidateAccessDeniedException("Nemate pristup napretku kandidata ove škole.");
        }
    }

    private void requireCandidateAccess(UUID schoolId, Candidate candidate, AuthenticatedUser user) {
        if (!auth.hasSchoolPermission(user, schoolId, "candidates.manage")
            && !isAssigned(candidate.getAssignedInstructor(), user)) {
            throw new CandidateAccessDeniedException("Možete pregledavati samo dodijeljene kandidate.");
        }
    }

    private boolean isAssigned(InstructorProfile instructor, AuthenticatedUser user) {
        return instructor != null && instructor.isActive()
            && instructor.getSchoolMembership().getUser().getId().equals(user.userId());
    }

    private ProgressResponse response(UUID schoolId, Candidate candidate) {
        long completedHours = lessons.countBySchoolIdAndCandidateIdAndDrivingCategoryIdAndStatusAndLessonType(
            schoolId, candidate.getId(), candidate.getDrivingCategory().getId(),
            LessonStatus.COMPLETED.value(), LessonType.DRIVING.value()
        );
        return new ProgressResponse(
            candidate.getId(), candidate.getFirstName() + " " + candidate.getLastName(),
            candidate.getDrivingCategory().getCode(), completedHours, candidate.getRequiredDrivingHours()
        );
    }
}
