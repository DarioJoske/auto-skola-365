package com.autoskola365.backend.candidate;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CandidateRepository extends JpaRepository<Candidate, UUID> {

    @EntityGraph(attributePaths = {"drivingCategory"})
    List<Candidate> findBySchoolIdOrderByCreatedAtDesc(UUID schoolId);

    @EntityGraph(attributePaths = {"drivingCategory"})
    Optional<Candidate> findByIdAndSchoolId(UUID id, UUID schoolId);
}
