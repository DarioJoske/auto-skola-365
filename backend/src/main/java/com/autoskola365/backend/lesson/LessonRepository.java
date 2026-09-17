package com.autoskola365.backend.lesson;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface LessonRepository extends JpaRepository<Lesson, UUID> {

    long countBySchoolIdAndStatus(UUID schoolId, String status);

    long countBySchoolIdAndStatusAndEndAtLessThanEqual(UUID schoolId, String status, Instant now);

    @EntityGraph(attributePaths = {"candidate", "instructor.schoolMembership.user", "drivingCategory"})
    List<Lesson> findTop5BySchoolIdAndStatusOrderByStartAtAsc(UUID schoolId, String status);

    @EntityGraph(attributePaths = {"candidate", "instructor.schoolMembership.user", "drivingCategory"})
    List<Lesson> findTop5BySchoolIdAndStatusAndEndAtLessThanEqualOrderByStartAtAsc(
        UUID schoolId, String status, Instant now);

    List<Lesson> findBySchoolIdAndCandidateIdOrderByStartAtDesc(UUID schoolId, UUID candidateId);

    long countBySchoolIdAndCandidateIdAndDrivingCategoryIdAndStatusAndLessonType(
        UUID schoolId, UUID candidateId, UUID drivingCategoryId, String status, String lessonType
    );

    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @Query("select lesson from Lesson lesson where lesson.id = :id and lesson.school.id = :schoolId")
    Optional<Lesson> findForUpdate(@Param("id") UUID id, @Param("schoolId") UUID schoolId);


    @EntityGraph(attributePaths = {
        "school",
        "candidate",
        "instructor",
        "instructor.schoolMembership",
        "instructor.schoolMembership.user",
        "drivingCategory",
        "branch"
    })
    Optional<Lesson> findByIdAndSchoolId(UUID id, UUID schoolId);

    @Query("""
        select lesson
        from Lesson lesson
        join fetch lesson.school school
        join fetch lesson.candidate candidate
        join fetch lesson.instructor instructor
        join fetch instructor.schoolMembership membership
        join fetch membership.user instructorUser
        join fetch lesson.drivingCategory category
        left join fetch lesson.branch branch
        where school.id = :schoolId
          and lesson.startAt < :to
          and lesson.endAt > :from
          and (:instructorId is null or instructor.id = :instructorId)
          and (:candidateId is null or candidate.id = :candidateId)
          and (:status is null or lesson.status = :status)
        order by lesson.startAt asc
        """)
    List<Lesson> search(
        @Param("schoolId") UUID schoolId,
        @Param("from") Instant from,
        @Param("to") Instant to,
        @Param("instructorId") UUID instructorId,
        @Param("candidateId") UUID candidateId,
        @Param("status") String status
    );

    @Query("""
        select lesson
        from Lesson lesson
        join fetch lesson.school school
        join fetch lesson.candidate candidate
        join fetch lesson.instructor instructor
        join fetch instructor.schoolMembership membership
        join fetch membership.user instructorUser
        join fetch lesson.drivingCategory category
        left join fetch lesson.branch branch
        where school.id = :schoolId
          and instructor.id = :instructorId
          and lesson.startAt < :to
          and lesson.endAt > :from
          and (:status is null or lesson.status = :status)
        order by lesson.startAt asc
        """)
    List<Lesson> searchInstructorLessons(
        @Param("schoolId") UUID schoolId,
        @Param("instructorId") UUID instructorId,
        @Param("from") Instant from,
        @Param("to") Instant to,
        @Param("status") String status
    );

    @Query("""
        select count(lesson) > 0
        from Lesson lesson
        where lesson.school.id = :schoolId
          and lesson.instructor.id = :instructorId
          and lesson.status <> 'CANCELLED'
          and lesson.startAt < :endAt
          and lesson.endAt > :startAt
          and (:excludedLessonId is null or lesson.id <> :excludedLessonId)
        """)
    boolean existsInstructorOverlap(
        @Param("schoolId") UUID schoolId,
        @Param("instructorId") UUID instructorId,
        @Param("startAt") Instant startAt,
        @Param("endAt") Instant endAt,
        @Param("excludedLessonId") UUID excludedLessonId
    );

    @Query("""
        select count(lesson) > 0
        from Lesson lesson
        where lesson.school.id = :schoolId
          and lesson.candidate.id = :candidateId
          and lesson.status <> 'CANCELLED'
          and lesson.startAt < :endAt
          and lesson.endAt > :startAt
          and (:excludedLessonId is null or lesson.id <> :excludedLessonId)
        """)
    boolean existsCandidateOverlap(
        @Param("schoolId") UUID schoolId,
        @Param("candidateId") UUID candidateId,
        @Param("startAt") Instant startAt,
        @Param("endAt") Instant endAt,
        @Param("excludedLessonId") UUID excludedLessonId
    );
}
