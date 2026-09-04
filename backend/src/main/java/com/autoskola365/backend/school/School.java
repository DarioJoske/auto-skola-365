package com.autoskola365.backend.school;

import java.util.UUID;

import com.autoskola365.backend.common.AuditableEntity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "schools")
public class School extends AuditableEntity {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(nullable = false)
    private String name;

    private String oib;

    private String email;

    private String phone;

    @Column(nullable = false)
    private String status = "ACTIVE";

    protected School() {
    }

    public School(String name, String oib, String email, String phone) {
        this.name = name;
        this.oib = oib;
        this.email = email;
        this.phone = phone;
    }

    public UUID getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public String getOib() {
        return oib;
    }

    public String getEmail() {
        return email;
    }

    public String getPhone() {
        return phone;
    }

    public String getStatus() {
        return status;
    }
}
