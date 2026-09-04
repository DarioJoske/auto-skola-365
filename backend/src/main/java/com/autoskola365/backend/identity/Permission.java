package com.autoskola365.backend.identity;

import java.util.UUID;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "permissions")
public class Permission {

    @Id
    private UUID id;

    @Column(name = "\"key\"", nullable = false, unique = true)
    private String key;

    @Column(nullable = false)
    private String description;

    protected Permission() {
    }

    public UUID getId() {
        return id;
    }

    public String getKey() {
        return key;
    }

    public String getDescription() {
        return description;
    }
}
