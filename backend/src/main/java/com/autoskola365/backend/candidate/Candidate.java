package com.autoskola365.backend.candidate;

import java.util.UUID;

import com.autoskola365.backend.common.AuditableEntity;
import com.autoskola365.backend.instructor.InstructorProfile;
import com.autoskola365.backend.identity.UserAccount;
import com.autoskola365.backend.school.School;
import com.autoskola365.backend.training.DrivingCategory;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "candidates")
public class Candidate extends AuditableEntity {

    @Id
    @GeneratedValue
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "school_id")
    private School school;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "driving_category_id")
    private DrivingCategory drivingCategory;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assigned_instructor_profile_id")
    private InstructorProfile assignedInstructor;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private UserAccount user;

    @Column(name = "first_name", nullable = false)
    private String firstName;

    @Column(name = "last_name", nullable = false)
    private String lastName;

    private String email;

    private String phone;

    private String oib;

    @Column(nullable = false)
    private String status = CandidateStatus.LEAD.value();

    private String notes;

    @Column(name = "required_driving_hours")
    private Integer requiredDrivingHours;

    protected Candidate() {
    }

    public Candidate(
        School school,
        DrivingCategory drivingCategory,
        String firstName,
        String lastName,
        String email,
        String phone,
        String oib,
        String status,
        InstructorProfile assignedInstructor,
        String notes
    ) {
        this(school, drivingCategory, firstName, lastName, email, phone, oib, status, assignedInstructor, null, notes);
    }

    public Candidate(
        School school,
        DrivingCategory drivingCategory,
        String firstName,
        String lastName,
        String email,
        String phone,
        String oib,
        String status,
        InstructorProfile assignedInstructor,
        UserAccount user,
        String notes
    ) {
        this.school = school;
        this.drivingCategory = drivingCategory;
        this.assignedInstructor = assignedInstructor;
        this.user = user;
        this.firstName = firstName;
        this.lastName = lastName;
        this.email = email;
        this.phone = phone;
        this.oib = oib;
        this.status = status;
        this.notes = notes;
    }

    public void update(
        DrivingCategory drivingCategory,
        String firstName,
        String lastName,
        String email,
        String phone,
        String oib,
        String status,
        InstructorProfile assignedInstructor,
        String notes
    ) {
        this.drivingCategory = drivingCategory;
        this.assignedInstructor = assignedInstructor;
        this.firstName = firstName;
        this.lastName = lastName;
        this.email = email;
        this.phone = phone;
        this.oib = oib;
        this.status = status;
        this.notes = notes;
    }

    public UUID getId() {
        return id;
    }

    public School getSchool() {
        return school;
    }

    public DrivingCategory getDrivingCategory() {
        return drivingCategory;
    }

    public InstructorProfile getAssignedInstructor() {
        return assignedInstructor;
    }

    public void linkUser(UserAccount user) { this.user = user; }

    public UserAccount getUser() {
        return user;
    }

    public String getFirstName() {
        return firstName;
    }

    public String getLastName() {
        return lastName;
    }

    public String getEmail() {
        return email;
    }

    public String getPhone() {
        return phone;
    }

    public String getOib() {
        return oib;
    }

    public String getStatus() {
        return status;
    }

    public String getNotes() {
        return notes;
    }

    public Integer getRequiredDrivingHours() {
        return requiredDrivingHours != null ? requiredDrivingHours
            : "B".equals(drivingCategory.getCode()) ? 35 : null;
    }

    public void setRequiredDrivingHours(Integer requiredDrivingHours) {
        this.requiredDrivingHours = requiredDrivingHours;
    }
}
