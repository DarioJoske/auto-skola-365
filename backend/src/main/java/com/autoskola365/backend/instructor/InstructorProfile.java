package com.autoskola365.backend.instructor;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

import com.autoskola365.backend.common.AuditableEntity;
import com.autoskola365.backend.identity.SchoolMembership;
import com.autoskola365.backend.training.DrivingCategory;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.JoinTable;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.Table;

@Entity
@Table(name = "instructor_profiles")
public class InstructorProfile extends AuditableEntity {

    @Id
    @GeneratedValue
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "school_membership_id")
    private SchoolMembership schoolMembership;

    @Column(name = "license_number")
    private String licenseNumber;

    @Column(nullable = false)
    private boolean active = true;

    @ManyToMany
    @JoinTable(
        name = "instructors_categories",
        joinColumns = @JoinColumn(name = "instructor_profile_id"),
        inverseJoinColumns = @JoinColumn(name = "driving_category_id")
    )
    private Set<DrivingCategory> categories = new HashSet<>();

    @OneToMany(mappedBy = "instructorProfile", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<InstructorAvailabilityRule> availabilityRules = new ArrayList<>();

    protected InstructorProfile() {
    }

    public InstructorProfile(SchoolMembership schoolMembership, String licenseNumber, boolean active) {
        this.schoolMembership = schoolMembership;
        this.licenseNumber = licenseNumber;
        this.active = active;
    }

    public void update(String licenseNumber, boolean active, Set<DrivingCategory> categories) {
        this.licenseNumber = licenseNumber;
        this.active = active;
        this.categories.clear();
        this.categories.addAll(categories);
    }

    public void replaceAvailabilityRules(List<InstructorAvailabilityRule> rules) {
        availabilityRules.clear();
        availabilityRules.addAll(rules);
    }

    public UUID getId() {
        return id;
    }

    public SchoolMembership getSchoolMembership() {
        return schoolMembership;
    }

    public String getLicenseNumber() {
        return licenseNumber;
    }

    public boolean isActive() {
        return active;
    }

    public Set<DrivingCategory> getCategories() {
        return categories;
    }

    public List<InstructorAvailabilityRule> getAvailabilityRules() {
        return availabilityRules;
    }
}
