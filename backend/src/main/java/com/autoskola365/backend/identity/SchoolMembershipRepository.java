package com.autoskola365.backend.identity;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.EntityGraph;

public interface SchoolMembershipRepository extends JpaRepository<SchoolMembership, UUID> {

    @EntityGraph(attributePaths = {"school", "role"})
    List<SchoolMembership> findByUserId(UUID userId);

    @EntityGraph(attributePaths = {"school", "role", "role.permissions"})
    List<SchoolMembership> findByUserIdAndStatus(UUID userId, String status);

    @EntityGraph(attributePaths = {"school", "user", "role", "role.permissions"})
    Optional<SchoolMembership> findBySchoolIdAndUserId(UUID schoolId, UUID userId);
}
