package com.autoskola365.backend.instructor;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
public interface AvailabilityBlockRepository extends JpaRepository<AvailabilityBlock, UUID> {
    List<AvailabilityBlock> findByInstructorIdOrderByStartAt(UUID instructorId);
}
