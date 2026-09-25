package com.autoskola365.backend.instructor;

import java.time.Instant;
import java.time.ZoneId;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.autoskola365.backend.auth.AuthenticatedUser;
import com.autoskola365.backend.auth.AuthorizationService;
import com.autoskola365.backend.lesson.InvalidLessonException;
import com.autoskola365.backend.lesson.Lesson;
import com.autoskola365.backend.lesson.LessonConflictException;
import com.autoskola365.backend.lesson.LessonRepository;

@Service
public class AvailabilityService {
    @jakarta.persistence.PersistenceContext
    private jakarta.persistence.EntityManager entityManager;
    public static final ZoneId ZONE = ZoneId.of("Europe/Zagreb");
    private final InstructorRepository instructors;
    private final AvailabilityRuleRepository rules;
    private final AvailabilityBlockRepository blocks;
    private final LessonRepository lessons;
    private final AuthorizationService authorization;
    public AvailabilityService(InstructorRepository instructors, AvailabilityRuleRepository rules,
        AvailabilityBlockRepository blocks, LessonRepository lessons, AuthorizationService authorization) {
        this.instructors = instructors;
        this.rules = rules;
        this.blocks = blocks;
        this.lessons = lessons;
        this.authorization = authorization;
    }
    @Transactional(readOnly = true)
    public AvailabilityResponse get(UUID schoolId, UUID instructorId, AuthenticatedUser user) {
        return response(authorize(schoolId, instructorId, user));
    }
    @Transactional
    public AvailabilityResponse save(UUID schoolId, UUID instructorId, AvailabilityRequest request, AuthenticatedUser user) {
        InstructorProfile owner = authorize(schoolId, instructorId, user);
        InstructorProfile instructor = instructors.findForUpdate(owner.getId(), schoolId).orElseThrow();
        entityManager.refresh(instructor);
        authorize(schoolId, instructorId, user);
        var newRules = request.rules().stream().map(r -> {
            if (!r.startTime().isBefore(r.endTime())) throw new InvalidLessonException("Početak dostupnosti mora biti prije kraja.");
            return new InstructorAvailabilityRule(instructor, r.dayOfWeek(), r.startTime(), r.endTime());
        }).toList();
        var newBlocks = request.blocks().stream().map(b -> {
            if (!b.startAt().isBefore(b.endAt())) throw new InvalidLessonException("Početak pauze ili odsutnosti mora biti prije kraja.");
            return new AvailabilityBlock(instructor, b.startAt(), b.endAt(), b.kind());
        }).toList();
        validateExisting(instructor, newRules, newBlocks);
        instructor.replaceAvailabilityRules(newRules);
        blocks.deleteAll(blocks.findByInstructorIdOrderByStartAt(instructor.getId()));
        blocks.saveAll(newBlocks);
        instructors.flush();
        return response(instructor);
    }
    public void validateExistingRules(InstructorProfile instructor, List<InstructorAvailabilityRule> newRules) {
        validateExisting(instructor, newRules, blocks.findByInstructorIdOrderByStartAt(instructor.getId()));
    }
    private void validateExisting(InstructorProfile instructor, List<InstructorAvailabilityRule> newRules, List<AvailabilityBlock> newBlocks) {
        for (Lesson lesson : lessons.findByInstructorIdAndEndAtAfter(instructor.getId(), Instant.now())) {
            if (!lesson.getStatus().equals("CANCELLED") && !fits(newRules, newBlocks, lesson.getStartAt(), lesson.getEndAt())) {
                throw new LessonConflictException("Dostupnost se preklapa s postojećim terminom. Najprije izričito promijenite ili otkažite termin.");
            }
        }
    }
    // Caller holds the instructor row lock; read fresh rules after acquiring it.
    public void requireAvailable(UUID instructorId, Instant start, Instant end) {
        if (!fits(rules.findByInstructorProfileIdOrderByDayOfWeekAscStartTimeAsc(instructorId),
            blocks.findByInstructorIdOrderByStartAt(instructorId), start, end)) {
            throw new LessonConflictException("Instruktor nije dostupan u odabrano vrijeme. Provjerite radno vrijeme, pauze i odsutnost.");
        }
    }
    private boolean fits(List<InstructorAvailabilityRule> weekly, List<AvailabilityBlock> exclusions, Instant start, Instant end) {
        if (exclusions.stream().anyMatch(b -> start.isBefore(b.getEndAt()) && end.isAfter(b.getStartAt()))) return false;
        if (weekly.isEmpty()) return true; // Legacy profiles have no working-hours restriction.
        var localStart = start.atZone(ZONE);
        var localEnd = end.atZone(ZONE);
        return localStart.toLocalDate().equals(localEnd.toLocalDate()) && weekly.stream().anyMatch(r ->
            r.getDayOfWeek() == localStart.getDayOfWeek().getValue()
            && !localStart.toLocalTime().isBefore(r.getStartTime()) && !localEnd.toLocalTime().isAfter(r.getEndTime()));
    }
    private InstructorProfile authorize(UUID schoolId, UUID instructorId, AuthenticatedUser user) {
        if (instructorId != null) {
            if (!authorization.hasSchoolPermission(user, schoolId, "instructors.manage")) throw new InstructorAccessDeniedException("Nemate pravo uređivanja dostupnosti.");
            return instructors.findByIdAndSchoolMembershipSchoolId(instructorId, schoolId)
                .orElseThrow(() -> new InstructorNotFoundException("Instruktor ne postoji."));
        }
        if (!authorization.hasSchoolPermission(user, schoolId, "lessons.view_assigned")) throw new InstructorAccessDeniedException("Nemate pristup dostupnosti.");
        var instructor = instructors.findBySchoolMembershipSchoolIdAndSchoolMembershipUserId(schoolId, user.userId())
            .orElseThrow(() -> new InstructorAccessDeniedException("Instruktor ne postoji."));
        if (!instructor.isActive()) throw new InstructorAccessDeniedException("Instruktor nije aktivan.");
        return instructor;
    }
    private AvailabilityResponse response(InstructorProfile instructor) {
        return new AvailabilityResponse(ZONE.getId(), rules.findByInstructorProfileIdOrderByDayOfWeekAscStartTimeAsc(instructor.getId()).stream()
            .map(r -> new InstructorRequest.AvailabilityRuleRequest(r.getDayOfWeek(), r.getStartTime(), r.getEndTime())).toList(),
            blocks.findByInstructorIdOrderByStartAt(instructor.getId()).stream()
            .map(b -> new AvailabilityRequest.BlockRequest(b.getStartAt(), b.getEndAt(), b.getKind())).toList());
    }
    public record AvailabilityResponse(String timeZone, List<InstructorRequest.AvailabilityRuleRequest> rules,
        List<AvailabilityRequest.BlockRequest> blocks) {}
}
