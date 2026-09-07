package com.autoskola365.backend.candidate;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CandidateRepository extends JpaRepository<Candidate, UUID> {

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
