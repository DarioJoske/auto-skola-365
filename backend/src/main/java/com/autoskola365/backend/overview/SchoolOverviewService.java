package com.autoskola365.backend.overview;

import java.time.*;
import java.time.temporal.TemporalAdjusters;
import java.util.*;
import java.util.stream.Collectors;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import com.autoskola365.backend.auth.*;
import com.autoskola365.backend.candidate.*;
import com.autoskola365.backend.instructor.InstructorRepository;
import com.autoskola365.backend.lesson.*;

@Service
@Transactional(readOnly = true)
public class SchoolOverviewService {
    static final ZoneId ZONE = ZoneId.of("Europe/Zagreb");
    static final List<String> ACTIVE_STATUSES = List.of("ENROLLED", "IN_THEORY", "PASSED_THEORY",
        "IN_DRIVING", "READY_FOR_EXAM", "EXAM_SCHEDULED");
    private final AuthorizationService authorization;
    private final CandidateRepository candidates;
    private final InstructorRepository instructors;
    private final LessonRepository lessons;
    private final Clock clock;

    @org.springframework.beans.factory.annotation.Autowired
    public SchoolOverviewService(AuthorizationService authorization, CandidateRepository candidates,
        InstructorRepository instructors, LessonRepository lessons) {
        this(authorization, candidates, instructors, lessons, Clock.system(ZONE));
    }

    SchoolOverviewService(AuthorizationService authorization, CandidateRepository candidates,
        InstructorRepository instructors, LessonRepository lessons, Clock clock) {
        this.clock = clock;
        this.authorization = authorization;
        this.candidates = candidates;
        this.instructors = instructors;
        this.lessons = lessons;
    }

    public SchoolOverviewResponse overview(UUID schoolId, AuthenticatedUser user) {
        requireAccess(schoolId, user);
        var now = clock.instant();
        var date = now.atZone(ZONE).toLocalDate();
        var start = date.atStartOfDay(ZONE).toInstant();
        var end = date.plusDays(1).atStartOfDay(ZONE).toInstant();
        var today = lessons.search(schoolId, start, end, null, null, null).stream()
            .filter(l -> !l.getStartAt().isBefore(start) && l.getStartAt().isBefore(end))
            .map(OverviewLesson::from).toList();
        return new SchoolOverviewResponse(date, ZONE.getId(), now,
            candidates.countBySchoolIdAndStatusIn(schoolId, ACTIVE_STATUSES),
            candidates.countBySchoolIdAndStatusInAndAssignedInstructorIsNull(schoolId, ACTIVE_STATUSES),
            lessons.countBySchoolIdAndStatus(schoolId, "REQUESTED"),
            lessons.countBySchoolIdAndStatusAndEndAtLessThanEqual(schoolId, "CONFIRMED", now),
            today.stream().filter(l -> l.status().equals("CONFIRMED")).count(),
            today.stream().filter(l -> l.status().equals("COMPLETED")).count(), today,
            lessons.findTop5BySchoolIdAndStatusOrderByStartAtAsc(schoolId, "REQUESTED")
                .stream().map(OverviewLesson::from).toList(),
            lessons.findTop5BySchoolIdAndStatusAndEndAtLessThanEqualOrderByStartAtAsc(schoolId, "CONFIRMED", now)
                .stream().map(OverviewLesson::from).toList());
    }

    public InstructorOverviewResponse instructors(UUID schoolId, String query, Boolean active,
        AuthenticatedUser user) {
        requireAccess(schoolId, user);
        var weekStart = LocalDate.now(clock.withZone(ZONE)).with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
        var start = weekStart.atStartOfDay(ZONE).toInstant();
        var end = weekStart.plusDays(7).atStartOfDay(ZONE).toInstant();
        var confirmed = lessons.search(schoolId, start, end, null, null, "CONFIRMED").stream()
            .filter(l -> !l.getStartAt().isBefore(start))
            .collect(Collectors.groupingBy(l -> l.getInstructor().getId()));
        var assigned = candidates.findBySchoolIdOrderByCreatedAtDesc(schoolId).stream()
            .filter(c -> c.getAssignedInstructor() != null)
            .collect(Collectors.groupingBy(c -> c.getAssignedInstructor().getId()));
        var search = query == null ? "" : query.strip().toLowerCase(Locale.ROOT);
        var entries = instructors.search(schoolId, active, null).stream().filter(profile -> {
            var account = profile.getSchoolMembership().getUser();
            return (account.getFirstName() + " " + account.getLastName() + " " + account.getEmail())
                .toLowerCase(Locale.ROOT).contains(search);
        }).map(profile -> {
            var account = profile.getSchoolMembership().getUser();
            var schedule = confirmed.getOrDefault(profile.getId(), List.of());
            var pupils = assigned.getOrDefault(profile.getId(), List.of()).stream()
                .sorted(Comparator.comparing(Candidate::getLastName).thenComparing(Candidate::getFirstName))
                .map(c -> new InstructorOverviewResponse.AssignedCandidate(c.getId(),
                    c.getFirstName() + " " + c.getLastName(), c.getStatus(), c.getDrivingCategory().getCode())).toList();
            return new InstructorOverviewResponse.Entry(profile.getId(), account.getFirstName() + " " + account.getLastName(),
                account.getEmail(), profile.isActive(), profile.getCategories().stream().map(c -> c.getCode()).sorted().toList(),
                schedule.size(), schedule.stream().mapToLong(l -> Duration.between(l.getStartAt(), l.getEndAt()).toMinutes()).sum(), pupils);
        }).toList();
        return new InstructorOverviewResponse(weekStart, weekStart.plusDays(6), ZONE.getId(), entries);
    }

    private void requireAccess(UUID schoolId, AuthenticatedUser user) {
        for (var permission : List.of("candidates.manage", "instructors.manage", "lessons.manage")) {
            if (!authorization.hasSchoolPermission(user, schoolId, permission)) {
                throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Nemaš ovlasti za operativni pregled ove škole.");
            }
        }
    }
}
