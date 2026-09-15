package com.autoskola365.backend.progress;
import java.util.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.autoskola365.backend.auth.*;
import com.autoskola365.backend.candidate.*;
import com.autoskola365.backend.lesson.*;
import com.autoskola365.backend.instructor.InstructorProfile;
import static com.autoskola365.backend.progress.ProgressResponse.*;
@Service
public class ProgressService {
    private final ProgressRepository records;
    private final CandidateRepository candidates;
    private final LessonRepository lessons;
    private final AuthorizationService auth;
    public ProgressService(ProgressRepository records, CandidateRepository candidates, LessonRepository lessons, AuthorizationService auth) {
        this.records=records; this.candidates=candidates; this.lessons=lessons; this.auth=auth;
    }
    private static final List<Option> SKILLS=List.of(
        new Option("VEHICLE_CONTROLS","Upravljanje komandama vozila"),
        new Option("START_STOP","Kretanje i zaustavljanje"),
        new Option("STEERING_LANE","Upravljanje i položaj u traci"),
        new Option("INTERSECTIONS","Raskrižja"), new Option("ROUNDABOUTS","Kružni tokovi"),
        new Option("PARKING","Parkiranje"), new Option("REVERSING","Vožnja unatrag"),
        new Option("CITY_TRAFFIC","Gradska vožnja"), new Option("OPEN_ROAD","Otvorena cesta"),
        new Option("EXAM_READINESS","Spremnost za ispit"));
    private static final List<Option> STATUSES=List.of(
        new Option("NOT_STARTED","Nije započeto"), new Option("IN_PROGRESS","U tijeku"),
        new Option("NEEDS_PRACTICE","Potrebna vježba"), new Option("SATISFACTORY","Zadovoljava"),
        new Option("MASTERED","Savladano"));

    @Transactional(readOnly=true)
    public ProgressResponse forCandidate(UUID schoolId, UUID candidateId, AuthenticatedUser user) {
        requireSchoolAccess(schoolId,user);
        Candidate candidate=candidates.findByIdAndSchoolId(candidateId,schoolId)
            .orElseThrow(()->new CandidateNotFoundException("Kandidat ne postoji."));
        requireCandidateAccess(schoolId,candidate,user);
        return response(schoolId,candidate,null,false);
    }
    @Transactional(readOnly=true)
    public ProgressResponse forLesson(UUID schoolId, UUID lessonId, AuthenticatedUser user) {
        requireSchoolAccess(schoolId,user);
        Lesson lesson=lessons.findByIdAndSchoolId(lessonId,schoolId)
            .orElseThrow(()->new LessonNotFoundException("Termin ne postoji."));
        requireCandidateAccess(schoolId,lesson.getCandidate(),user);
        return response(schoolId,lesson.getCandidate(),lessonId,canEdit(schoolId,lesson,user));
    }
    @Transactional
    public ProgressResponse save(UUID schoolId, UUID lessonId, ProgressRequest request, AuthenticatedUser user) {
        requireSchoolAccess(schoolId,user);
        Lesson lesson=lessons.findForUpdate(lessonId,schoolId)
            .orElseThrow(()->new LessonNotFoundException("Termin ne postoji."));
        requireCandidateAccess(schoolId,lesson.getCandidate(),user);
        if (!isAssigned(lesson.getInstructor(),user) || !auth.hasSchoolPermission(user,schoolId,"progress.manage_assigned"))
            throw new LessonAccessDeniedException("Možete procjenjivati samo vlastite sate.");
        if (!"COMPLETED".equals(lesson.getStatus()))
            throw new LessonConflictException("Napredak se bilježi nakon završetka sata.");
        if (!"B".equals(lesson.getCandidate().getDrivingCategory().getCode()))
            throw new InvalidLessonException("Predložak napretka trenutačno je dostupan za B kategoriju.");
        Set<String> seen=new HashSet<>();
        for (var item:request.assessments()) {
            if (!seen.add(item.skill()) || SKILLS.stream().noneMatch(o->o.code().equals(item.skill()))
                || STATUSES.stream().noneMatch(o->o.code().equals(item.status())))
                throw new InvalidLessonException("Procjena sadrži nepoznatu ili ponovljenu vještinu ili razinu napretka.");
        }
        Map<String,ProgressRecord> existing=new HashMap<>();
        records.findByLessonId(lessonId).forEach(r->existing.put(r.getSkill(),r));
        for (var item:request.assessments()) {
            ProgressRecord record=existing.getOrDefault(item.skill(),new ProgressRecord(lesson,item.skill()));
            record.assess(item.status());
            records.save(record);
        }
        records.flush();
        return response(schoolId,lesson.getCandidate(),lessonId,true);
    }
    private boolean canEdit(UUID schoolId, Lesson lesson, AuthenticatedUser user) {
        return "COMPLETED".equals(lesson.getStatus()) && "B".equals(lesson.getCandidate().getDrivingCategory().getCode())
            && isAssigned(lesson.getInstructor(),user) && auth.hasSchoolPermission(user,schoolId,"progress.manage_assigned");
    }
    private void requireSchoolAccess(UUID schoolId, AuthenticatedUser user) {
        if (!auth.hasSchoolPermission(user,schoolId,"progress.manage_assigned") && !auth.hasSchoolPermission(user,schoolId,"candidates.manage"))
            throw new CandidateAccessDeniedException("Nemate pristup napretku kandidata ove škole.");
    }
    private void requireCandidateAccess(UUID schoolId, Candidate candidate, AuthenticatedUser user) {
        if (!auth.hasSchoolPermission(user,schoolId,"candidates.manage") && !isAssigned(candidate.getAssignedInstructor(),user))
            throw new CandidateAccessDeniedException("Možete pregledavati samo dodijeljene kandidate.");
    }
    private boolean isAssigned(InstructorProfile instructor, AuthenticatedUser user) {
        return instructor!=null && instructor.isActive() && instructor.getSchoolMembership().getUser().getId().equals(user.userId());
    }
    private ProgressResponse response(UUID schoolId, Candidate candidate, UUID lessonId, boolean editable) {
        var entries=records.findByLessonCandidateIdAndLessonSchoolIdOrderByLessonEndAtDescRecordedAtDesc(candidate.getId(),schoolId)
            .stream().map(r->new Entry(r.getLesson().getId(),r.getLesson().getEndAt(),r.getSkill(),r.getStatus(),r.getRecordedAt())).toList();
        String category=candidate.getDrivingCategory().getCode();
        return new ProgressResponse(candidate.getId(),candidate.getFirstName()+" "+candidate.getLastName(),category,
            lessonId,editable,"B".equals(category)?SKILLS:List.of(),STATUSES,entries);
    }
}
