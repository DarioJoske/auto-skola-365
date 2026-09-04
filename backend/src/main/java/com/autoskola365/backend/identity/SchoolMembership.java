package com.autoskola365.backend.identity;

import java.util.UUID;

import com.autoskola365.backend.common.AuditableEntity;
import com.autoskola365.backend.school.School;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "school_memberships")
public class SchoolMembership extends AuditableEntity {

    @Id
    @GeneratedValue
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "school_id")
    private School school;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id")
    private UserAccount user;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "role_id")
    private Role role;

    @Column(nullable = false)
    private String status = "ACTIVE";

    protected SchoolMembership() {
    }

    public SchoolMembership(School school, UserAccount user, Role role) {
        this.school = school;
        this.user = user;
        this.role = role;
    }

    public UUID getId() {
        return id;
    }

    public School getSchool() {
        return school;
    }

    public UserAccount getUser() {
        return user;
    }

    public Role getRole() {
        return role;
    }

    public String getStatus() {
        return status;
    }
}
