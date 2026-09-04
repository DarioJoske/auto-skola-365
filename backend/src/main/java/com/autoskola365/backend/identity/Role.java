package com.autoskola365.backend.identity;

import java.util.Set;
import java.util.UUID;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.JoinTable;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.Table;

@Entity
@Table(name = "roles")
public class Role {

    @Id
    private UUID id;

    @Column(name = "\"key\"", nullable = false, unique = true)
    private String key;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String scope;

    @ManyToMany(fetch = FetchType.EAGER)
    @JoinTable(
        name = "role_permissions",
        joinColumns = @JoinColumn(name = "role_id"),
        inverseJoinColumns = @JoinColumn(name = "permission_id")
    )
    private Set<Permission> permissions = Set.of();

    protected Role() {
    }

    public UUID getId() {
        return id;
    }

    public String getKey() {
        return key;
    }

    public String getName() {
        return name;
    }

    public String getScope() {
        return scope;
    }

    public Set<Permission> getPermissions() {
        return permissions;
    }
}
