package com.autoskola365.backend.instructor;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
public interface AvailabilityRuleRepository extends JpaRepository<InstructorAvailabilityRule, UUID> {
    List<InstructorAvailabilityRule> findByInstructorProfileIdOrderByDayOfWeekAscStartTimeAsc(UUID instructorId);
}
