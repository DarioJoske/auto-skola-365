package com.autoskola365.backend.school;

import java.util.UUID;

import com.autoskola365.backend.common.AuditableEntity;

import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "branches")
public class Branch extends AuditableEntity {

    @Id
    @GeneratedValue
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "school_id")
    private School school;

    private String name;

    private String address;

    private String city;

    private String phone;

    protected Branch() {
    }

    public Branch(School school, String name, String address, String city, String phone) {
        this.school = school;
        this.name = name;
        this.address = address;
        this.city = city;
        this.phone = phone;
    }

    public UUID getId() {
        return id;
    }

    public School getSchool() {
        return school;
    }

    public String getName() {
        return name;
    }
}
