package com.autoskola365.backend.instructor;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface InstructorRepository extends JpaRepository<InstructorProfile, UUID> {

    @EntityGraph(attributePaths = {
        "schoolMembership",
        "schoolMembership.school",
        "schoolMembership.user",
        "categories",
        "availabilityRules"
    })
    Optional<InstructorProfile> findByIdAndSchoolMembershipSchoolId(UUID id, UUID schoolId);

    @EntityGraph(attributePaths = {
        "schoolMembership",
        "schoolMembership.school",
        "schoolMembership.user",
        "categories"
    })
    Optional<InstructorProfile> findBySchoolMembershipSchoolIdAndSchoolMembershipUserId(UUID schoolId, UUID userId);

    boolean existsBySchoolMembershipId(UUID schoolMembershipId);

    @Query("""
        select distinct instructor
        from InstructorProfile instructor
        join fetch instructor.schoolMembership membership
        join fetch membership.school school
        join fetch membership.user user
        left join fetch instructor.categories category
        left join fetch instructor.availabilityRules availabilityRule
        where school.id = :schoolId
          and (:active is null or instructor.active = :active)
          and (:categoryCode is null or category.code = :categoryCode)
        order by user.lastName asc, user.firstName asc
        """)
    List<InstructorProfile> search(
        @Param("schoolId") UUID schoolId,
        @Param("active") Boolean active,
        @Param("categoryCode") String categoryCode
    );
}
