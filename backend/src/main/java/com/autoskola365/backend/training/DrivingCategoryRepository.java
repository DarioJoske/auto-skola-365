package com.autoskola365.backend.training;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

public interface DrivingCategoryRepository extends JpaRepository<DrivingCategory, UUID> {

    Optional<DrivingCategory> findByCodeAndActiveTrue(String code);
}
