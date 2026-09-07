package com.autoskola365.backend.school;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

public interface BranchRepository extends JpaRepository<Branch, UUID> {

    Optional<Branch> findByIdAndSchoolId(UUID id, UUID schoolId);
}
