package com.autoskola365.backend.school;

import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

public interface BranchRepository extends JpaRepository<Branch, UUID> {
}
