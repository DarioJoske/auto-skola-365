package com.autoskola365.backend.progress;
import java.util.*;
import org.springframework.data.jpa.repository.*;
public interface ProgressRepository extends JpaRepository<ProgressRecord,UUID> {
    @EntityGraph(attributePaths="lesson")
    List<ProgressRecord> findByLessonCandidateIdAndLessonSchoolIdOrderByLessonEndAtDescRecordedAtDesc(UUID candidateId, UUID schoolId);
    List<ProgressRecord> findByLessonId(UUID lessonId);
}
