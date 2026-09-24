package com.autoskola365.backend.lesson;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.autoskola365.backend.auth.AuthenticatedUser;
import com.autoskola365.backend.auth.AuthorizationService;
import com.autoskola365.backend.candidate.Candidate;
import com.autoskola365.backend.candidate.CandidateNotFoundException;
import com.autoskola365.backend.candidate.CandidateRepository;
import com.autoskola365.backend.instructor.InstructorNotFoundException;
import com.autoskola365.backend.instructor.InstructorProfile;
import com.autoskola365.backend.instructor.InstructorRepository;
import com.autoskola365.backend.school.Branch;
import com.autoskola365.backend.school.BranchRepository;

@Service
public class LessonService {

    private static final String MANAGE_LESSONS = "lessons.manage";
    private static final String VIEW_ASSIGNED_LESSONS = "lessons.view_assigned";
    private static final String RESERVE_OWN_LESSONS = "lessons.reserve_own";
    private static final Duration DEFAULT_DURATION = Duration.ofMinutes(60);

    private final LessonRepository lessonRepository;
    private final CandidateRepository candidateRepository;
    private final InstructorRepository instructorRepository;
    private final BranchRepository branchRepository;
    private final AuthorizationService authorizationService;

    public LessonService(
        LessonRepository lessonRepository,
        CandidateRepository candidateRepository,
        InstructorRepository instructorRepository,
        BranchRepository branchRepository,
        AuthorizationService authorizationService
    ) {
        this.lessonRepository = lessonRepository;
        this.candidateRepository = candidateRepository;
        this.instructorRepository = instructorRepository;
        this.branchRepository = branchRepository;
        this.authorizationService = authorizationService;
    }

    @Transactional(readOnly = true)
    public List<LessonResponse> list(
        UUID schoolId,
        Instant from,
        Instant to,
        UUID instructorId,
        UUID candidateId,
        String status,
        AuthenticatedUser authenticatedUser
    ) {
        requireManageLessons(schoolId, authenticatedUser);
        Instant normalizedFrom = from == null ? Instant.now().minus(Duration.ofDays(7)) : from;
        Instant normalizedTo = to == null ? normalizedFrom.plus(Duration.ofDays(31)) : to;
        if (!normalizedFrom.isBefore(normalizedTo)) {
            throw new InvalidLessonException("Lesson date range is invalid.");
        }

        String normalizedStatus = status == null || status.isBlank() ? null : LessonStatus.normalize(status);
        return lessonRepository.search(schoolId, normalizedFrom, normalizedTo, instructorId, candidateId, normalizedStatus)
            .stream()
            .map(this::toResponse)
            .toList();
    }

    @Transactional(readOnly = true)
    public LessonResponse get(UUID schoolId, UUID lessonId, AuthenticatedUser authenticatedUser) {
        requireManageLessons(schoolId, authenticatedUser);
        return lessonRepository.findByIdAndSchoolId(lessonId, schoolId)
            .map(this::toResponse)
            .orElseThrow(() -> new LessonNotFoundException("Lesson does not exist."));
    }

    @Transactional
    public LessonResponse create(UUID schoolId, LessonRequest request, AuthenticatedUser authenticatedUser) {
        requireSchoolLessonAccess(schoolId, authenticatedUser);
        LessonInputs inputs = getInputs(schoolId, request);
        requireManageLessonsOrAssignedInstructor(schoolId, inputs.instructor(), authenticatedUser);

        String status = LessonStatus.normalizeOrDefault(request.status());
        String lessonType = LessonType.normalizeOrDefault(request.lessonType());
        Instant endAt = endAtOrDefault(request);
        validateLesson(inputs, lessonType, status, request.startAt(), endAt, null);

        LessonCreatedByRole createdByRole = authorizationService.hasSchoolPermission(authenticatedUser, schoolId, MANAGE_LESSONS)
            ? LessonCreatedByRole.ADMIN
            : LessonCreatedByRole.INSTRUCTOR;
        Lesson lesson = new Lesson(
            inputs.candidate().getSchool(),
            inputs.candidate(),
            inputs.instructor(),
            inputs.candidate().getDrivingCategory(),
            inputs.branch(),
            lessonType,
            status,
            request.startAt(),
            endAt,
            request.notes(),
            createdByRole
        );

        return toResponse(lessonRepository.save(lesson));
    }

    @Transactional(readOnly = true)
    public List<LessonResponse> listInstructorLessons(
        UUID schoolId,
        Instant from,
        Instant to,
        String status,
        AuthenticatedUser authenticatedUser
    ) {
        requireInstructorLessonAccess(schoolId, authenticatedUser);
        InstructorProfile instructor = getInstructorForUser(schoolId, authenticatedUser);
        Instant normalizedFrom = from == null ? Instant.now().minus(Duration.ofDays(7)) : from;
        Instant normalizedTo = to == null ? normalizedFrom.plus(Duration.ofDays(31)) : to;
        if (!normalizedFrom.isBefore(normalizedTo)) {
            throw new InvalidLessonException("Lesson date range is invalid.");
        }

        String normalizedStatus = status == null || status.isBlank() ? null : LessonStatus.normalize(status);
        return lessonRepository.searchInstructorLessons(
                schoolId,
                instructor.getId(),
                normalizedFrom,
                normalizedTo,
                normalizedStatus
            )
            .stream()
            .map(this::toResponse)
            .toList();
    }

    @Transactional(readOnly = true)
    public List<LessonResponse> instructorCandidateHistory(UUID schoolId, UUID candidateId, AuthenticatedUser user) {
        requireInstructorLessonAccess(schoolId, user);
        InstructorProfile instructor = getInstructorForUser(schoolId, user);
        Candidate candidate = candidateRepository.findByIdAndSchoolId(candidateId, schoolId)
            .orElseThrow(() -> new CandidateNotFoundException("Candidate does not exist."));
        if (!instructor.isActive() || candidate.getAssignedInstructor() == null
            || !candidate.getAssignedInstructor().getId().equals(instructor.getId())) {
            throw new LessonAccessDeniedException("User cannot access this candidate.");
        }
        return lessonRepository.findBySchoolIdAndCandidateIdAndInstructorIdOrderByStartAtDesc(
                schoolId, candidateId, instructor.getId()).stream()
            .map(this::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public LessonResponse getInstructorLesson(
        UUID schoolId,
        UUID lessonId,
        AuthenticatedUser authenticatedUser
    ) {
        requireInstructorLessonAccess(schoolId, authenticatedUser);
        InstructorProfile instructor = getInstructorForUser(schoolId, authenticatedUser);
        Lesson lesson = lessonRepository.findByIdAndSchoolId(lessonId, schoolId)
            .orElseThrow(() -> new LessonNotFoundException("Lesson does not exist."));
        requireAssignedInstructor(instructor, lesson);

        return toResponse(lesson);
    }

    @Transactional
    public LessonResponse createInstructorReservation(
        UUID schoolId, InstructorLessonReservationRequest request, AuthenticatedUser authenticatedUser
    ) {
        requireInstructorLessonAccess(schoolId, authenticatedUser);
        InstructorProfile instructor = getInstructorForUser(schoolId, authenticatedUser);
        if (!instructor.isActive()) {
            throw new LessonAccessDeniedException("Instruktor nije aktivan.");
        }
        if (!request.startAt().isAfter(Instant.now())) {
            throw new InvalidLessonException("Termin mora biti u budućnosti.");
        }
        return create(schoolId, new LessonRequest(
            request.candidateId(), instructor.getId(), null, LessonType.DRIVING.value(),
            LessonStatus.CONFIRMED.value(), request.startAt(), null, request.notes()
        ), authenticatedUser);
    }

    @Transactional
    public LessonResponse createCandidateReservation(
        UUID schoolId,
        CandidateLessonReservationRequest request,
        AuthenticatedUser authenticatedUser
    ) {
        requireCandidateReservationAccess(schoolId, authenticatedUser);
        Candidate candidate = candidateRepository.findForUpdateByUser(schoolId, authenticatedUser.userId())
            .orElseThrow(() -> new LessonAccessDeniedException("User cannot reserve lessons for this candidate."));
        InstructorProfile instructor = candidate.getAssignedInstructor();
        if (instructor == null) {
            throw new LessonConflictException("Candidate does not have an assigned instructor.");
        }

        Branch branch = request.branchId() == null
            ? null
            : branchRepository.findByIdAndSchoolId(request.branchId(), schoolId)
                .orElseThrow(() -> new InvalidLessonException("Branch does not exist."));
        LessonInputs inputs = new LessonInputs(candidate, instructor, branch);
        Instant endAt = endAtOrDefault(request.startAt(), request.endAt());
        validateLesson(inputs, LessonType.DRIVING.value(), LessonStatus.REQUESTED.value(), request.startAt(), endAt, null);

        Lesson lesson = new Lesson(
            candidate.getSchool(),
            candidate,
            instructor,
            candidate.getDrivingCategory(),
            branch,
            LessonType.DRIVING.value(),
            LessonStatus.REQUESTED.value(),
            request.startAt(),
            endAt,
            request.notes(),
            LessonCreatedByRole.CANDIDATE
        );

        return toResponse(lessonRepository.save(lesson));
    }

    @Transactional
    public LessonResponse update(
        UUID schoolId,
        UUID lessonId,
        LessonRequest request,
        AuthenticatedUser authenticatedUser
    ) {
        requireManageLessons(schoolId, authenticatedUser);
        Lesson lesson = lessonRepository.findForUpdate(lessonId, schoolId)
            .orElseThrow(() -> new LessonNotFoundException("Lesson does not exist."));
        LessonInputs inputs = getInputs(schoolId, request);

        String status = LessonStatus.normalizeOrDefault(request.status());
        String lessonType = LessonType.normalizeOrDefault(request.lessonType());
        Instant endAt = endAtOrDefault(request);
        validateLesson(inputs, lessonType, status, request.startAt(), endAt, lessonId);

        lesson.update(
            inputs.candidate(),
            inputs.instructor(),
            inputs.candidate().getDrivingCategory(),
            inputs.branch(),
            lessonType,
            status,
            request.startAt(),
            endAt,
            request.notes()
        );

        return toResponse(lesson);
    }

    @Transactional
    public LessonResponse confirm(UUID schoolId, UUID lessonId, AuthenticatedUser authenticatedUser) {
        requireSchoolLessonAccess(schoolId, authenticatedUser);
        Lesson lesson = lessonRepository.findForUpdate(lessonId, schoolId)
            .orElseThrow(() -> new LessonNotFoundException("Lesson does not exist."));
        requireManageLessonsOrAssignedInstructor(schoolId, lesson.getInstructor(), authenticatedUser);
        ensureNoOverlap(lesson, lesson.getId());
        lesson.confirm();

        return toResponse(lesson);
    }

    @Transactional
    public LessonResponse cancel(UUID schoolId, UUID lessonId, AuthenticatedUser authenticatedUser) {
        requireSchoolLessonAccess(schoolId, authenticatedUser);
        Lesson lesson = lessonRepository.findForUpdate(lessonId, schoolId)
            .orElseThrow(() -> new LessonNotFoundException("Lesson does not exist."));
        requireManageLessonsOrAssignedInstructor(schoolId, lesson.getInstructor(), authenticatedUser);
        lesson.cancel();

        return toResponse(lesson);
    }

    @Transactional
    public LessonResponse complete(UUID schoolId, UUID lessonId, CompleteLessonRequest request,
                                   AuthenticatedUser authenticatedUser) {
        requireInstructorLessonAccess(schoolId, authenticatedUser);
        InstructorProfile instructor = getInstructorForUser(schoolId, authenticatedUser);
        if (!instructor.isActive()) {
            throw new LessonAccessDeniedException("Instruktor nije aktivan.");
        }
        Lesson lesson = lessonRepository.findForUpdate(lessonId, schoolId)
            .orElseThrow(() -> new LessonNotFoundException("Termin ne postoji."));
        requireAssignedInstructor(instructor, lesson);
        lesson.complete(request.note(), Instant.now());
        return toResponse(lesson);
    }

    private LessonInputs getInputs(UUID schoolId, LessonRequest request) {
        Candidate candidate = candidateRepository.findForUpdate(request.candidateId(), schoolId)
            .orElseThrow(() -> new CandidateNotFoundException("Candidate does not exist."));
        InstructorProfile instructor = instructorRepository.findByIdAndSchoolMembershipSchoolId(request.instructorId(), schoolId)
            .orElseThrow(() -> new InstructorNotFoundException("Instructor does not exist."));
        Branch branch = request.branchId() == null
            ? null
            : branchRepository.findByIdAndSchoolId(request.branchId(), schoolId)
                .orElseThrow(() -> new InvalidLessonException("Branch does not exist."));

        return new LessonInputs(candidate, instructor, branch);
    }

    private Instant endAtOrDefault(LessonRequest request) {
        return endAtOrDefault(request.startAt(), request.endAt());
    }

    private Instant endAtOrDefault(Instant startAt, Instant endAt) {
        Instant defaultEndAt = startAt.plus(DEFAULT_DURATION);
        if (endAt == null) {
            return defaultEndAt;
        }
        if (!endAt.equals(defaultEndAt)) {
            throw new InvalidLessonException("Driving lesson duration must be 60 minutes.");
        }

        return endAt;
    }

    private void validateLesson(
        LessonInputs inputs,
        String lessonType,
        String status,
        Instant startAt,
        Instant endAt,
        UUID excludedLessonId
    ) {
        if (!startAt.isBefore(endAt)) {
            throw new InvalidLessonException("Lesson start time must be before end time.");
        }
        if (!LessonType.DRIVING.value().equals(lessonType)) {
            throw new InvalidLessonException("Only driving lessons are supported in the MVP.");
        }
        if (LessonStatus.COMPLETED.value().equals(status) || LessonStatus.NO_SHOW.value().equals(status)) {
            throw new InvalidLessonException("Lesson cannot be created or updated directly to final status.");
        }
        if (!inputs.instructor().isActive()) {
            throw new InvalidLessonException("Instructor is not active.");
        }
        if (inputs.candidate().getAssignedInstructor() == null
            || !inputs.candidate().getAssignedInstructor().getId().equals(inputs.instructor().getId())) {
            throw new LessonConflictException("Kandidat nije dodijeljen odabranom instruktoru. Osvježite popis kandidata.");
        }
        boolean instructorSupportsCategory = inputs.instructor().getCategories()
            .stream()
            .anyMatch(category -> category.getId().equals(inputs.candidate().getDrivingCategory().getId()));
        if (!instructorSupportsCategory) {
            throw new InvalidLessonException("Instructor does not support candidate category.");
        }
        if (!LessonStatus.CANCELLED.value().equals(status)) {
            ensureNoOverlap(inputs.candidate(), inputs.instructor(), startAt, endAt, excludedLessonId);
        }
    }

    private void ensureNoOverlap(Lesson lesson, UUID excludedLessonId) {
        ensureNoOverlap(
            lesson.getCandidate(),
            lesson.getInstructor(),
            lesson.getStartAt(),
            lesson.getEndAt(),
            excludedLessonId
        );
    }

    private void ensureNoOverlap(
        Candidate candidate,
        InstructorProfile instructor,
        Instant startAt,
        Instant endAt,
        UUID excludedLessonId
    ) {
        UUID schoolId = candidate.getSchool().getId();
        // Lock stable rows even when the slot has no lessons yet. Every scheduling
        // path uses candidate -> instructor order and holds both until commit.
        candidateRepository.findForUpdate(candidate.getId(), schoolId)
            .orElseThrow(() -> new CandidateNotFoundException("Candidate does not exist."));
        instructorRepository.findForUpdate(instructor.getId(), schoolId)
            .orElseThrow(() -> new InstructorNotFoundException("Instructor does not exist."));
        lessonRepository.search(schoolId, startAt, endAt, instructor.getId(), null, null).stream()
            .filter(conflict -> !LessonStatus.CANCELLED.value().equals(conflict.getStatus()))
            .filter(conflict -> !conflict.getId().equals(excludedLessonId))
            .findFirst().ifPresent(conflict -> {
                throw overlapConflict("Instruktor", conflict);
            });
        lessonRepository.search(schoolId, startAt, endAt, null, candidate.getId(), null).stream()
            .filter(conflict -> !LessonStatus.CANCELLED.value().equals(conflict.getStatus()))
            .filter(conflict -> !conflict.getId().equals(excludedLessonId))
            .findFirst().ifPresent(conflict -> {
                throw overlapConflict("Kandidat", conflict);
            });
    }

    private LessonConflictException overlapConflict(String resource, Lesson conflict) {
        // Explicit UTC avoids assuming the caller's local time zone and does not
        // reveal another candidate's identity to an instructor or candidate.
        var format = java.time.format.DateTimeFormatter.ofPattern("dd.MM.yyyy. HH:mm")
            .withZone(java.time.ZoneOffset.UTC);
        return new LessonConflictException(resource + " već ima termin "
            + format.format(conflict.getStartAt()) + " – " + format.format(conflict.getEndAt())
            + " UTC. Odaberite drugo vrijeme.");
    }

    private void requireManageLessons(UUID schoolId, AuthenticatedUser authenticatedUser) {
        if (!authorizationService.hasSchoolPermission(authenticatedUser, schoolId, MANAGE_LESSONS)) {
            throw new LessonAccessDeniedException("User cannot manage lessons for this school.");
        }
    }

    private void requireSchoolLessonAccess(UUID schoolId, AuthenticatedUser authenticatedUser) {
        if (!authorizationService.hasSchoolPermission(authenticatedUser, schoolId, MANAGE_LESSONS)
            && !authorizationService.hasSchoolPermission(authenticatedUser, schoolId, VIEW_ASSIGNED_LESSONS)) {
            throw new LessonAccessDeniedException("User cannot access lessons for this school.");
        }
    }

    private void requireManageLessonsOrAssignedInstructor(
        UUID schoolId,
        InstructorProfile instructor,
        AuthenticatedUser authenticatedUser
    ) {
        if (authorizationService.hasSchoolPermission(authenticatedUser, schoolId, MANAGE_LESSONS)) {
            return;
        }
        if (
            authorizationService.hasSchoolPermission(authenticatedUser, schoolId, VIEW_ASSIGNED_LESSONS)
                && instructor.getSchoolMembership().getUser().getId().equals(authenticatedUser.userId())
        ) {
            return;
        }

        throw new LessonAccessDeniedException("User cannot manage this lesson.");
    }

    private void requireInstructorLessonAccess(UUID schoolId, AuthenticatedUser authenticatedUser) {
        if (!authorizationService.hasSchoolPermission(authenticatedUser, schoolId, VIEW_ASSIGNED_LESSONS)) {
            throw new LessonAccessDeniedException("User cannot view assigned lessons for this school.");
        }
    }

    private void requireCandidateReservationAccess(UUID schoolId, AuthenticatedUser authenticatedUser) {
        if (!authorizationService.hasSchoolPermission(authenticatedUser, schoolId, RESERVE_OWN_LESSONS)) {
            throw new LessonAccessDeniedException("User cannot reserve own lessons for this school.");
        }
    }

    private InstructorProfile getInstructorForUser(UUID schoolId, AuthenticatedUser authenticatedUser) {
        return instructorRepository.findBySchoolMembershipSchoolIdAndSchoolMembershipUserId(schoolId, authenticatedUser.userId())
            .orElseThrow(() -> new LessonAccessDeniedException("User is not an instructor for this school."));
    }

    private void requireAssignedInstructor(InstructorProfile instructor, Lesson lesson) {
        if (!lesson.getInstructor().getId().equals(instructor.getId())) {
            throw new LessonAccessDeniedException("User cannot access this lesson.");
        }
    }

    private LessonResponse toResponse(Lesson lesson) {
        Branch branch = lesson.getBranch();
        return new LessonResponse(
            lesson.getId(),
            lesson.getSchool().getId(),
            lesson.getCandidate().getId(),
            lesson.getCandidate().getFirstName() + " " + lesson.getCandidate().getLastName(),
            lesson.getInstructor().getId(),
            lesson.getInstructor().getSchoolMembership().getUser().getFirstName()
                + " "
                + lesson.getInstructor().getSchoolMembership().getUser().getLastName(),
            lesson.getDrivingCategory().getCode(),
            lesson.getDrivingCategory().getName(),
            branch == null ? null : branch.getId(),
            branch == null ? null : branch.getName(),
            lesson.getLessonType(),
            lesson.getStatus(),
            lesson.getStartAt(),
            lesson.getEndAt(),
            lesson.getConfirmedAt(),
            lesson.getCancelledAt(),
            lesson.getNotes(),
            lesson.getCompletedAt(),
            lesson.getCompletionNote(),
            lesson.getCreatedByRole()
        );
    }

    private record LessonInputs(Candidate candidate, InstructorProfile instructor, Branch branch) {
    }
}
