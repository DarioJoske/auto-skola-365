package com.autoskola365.backend.candidate;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import jakarta.persistence.LockModeType;

public interface CandidateRepository extends JpaRepository<Candidate, UUID> {

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select candidate from Candidate candidate where candidate.id = :id and candidate.school.id = :schoolId")
    Optional<Candidate> findForUpdate(@Param("id") UUID id, @Param("schoolId") UUID schoolId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select candidate from Candidate candidate where candidate.school.id = :schoolId and candidate.user.id = :userId")
    Optional<Candidate> findForUpdateByUser(@Param("schoolId") UUID schoolId, @Param("userId") UUID userId);

    @EntityGraph(attributePaths = {
        "drivingCategory",
        "assignedInstructor",
        "assignedInstructor.schoolMembership",
        "assignedInstructor.schoolMembership.user"
    })
    List<Candidate> findBySchoolIdOrderByCreatedAtDesc(UUID schoolId);

    @EntityGraph(attributePaths = {
        "drivingCategory",
        "assignedInstructor",
        "assignedInstructor.schoolMembership",
        "assignedInstructor.schoolMembership.user"
    })
    List<Candidate> findBySchoolIdAndAssignedInstructorIdOrderByCreatedAtDesc(UUID schoolId, UUID assignedInstructorId);

    @EntityGraph(attributePaths = {
        "drivingCategory",
        "assignedInstructor",
        "assignedInstructor.schoolMembership",
        "assignedInstructor.schoolMembership.user"
    })
    Optional<Candidate> findByIdAndSchoolId(UUID id, UUID schoolId);

    @EntityGraph(attributePaths = {
        "school",
        "drivingCategory",
        "assignedInstructor",
        "assignedInstructor.schoolMembership",
        "assignedInstructor.schoolMembership.user"
    })
    Optional<Candidate> findBySchoolIdAndUserId(UUID schoolId, UUID userId);

    boolean existsBySchoolIdAndOib(UUID schoolId, String oib);

    boolean existsBySchoolIdAndOibAndIdNot(UUID schoolId, String oib, UUID id);
}
