package com.autoskola365.backend.lesson;

import java.time.Instant;
import java.util.UUID;

import com.autoskola365.backend.candidate.Candidate;
import com.autoskola365.backend.common.AuditableEntity;
import com.autoskola365.backend.instructor.InstructorProfile;
import com.autoskola365.backend.school.Branch;
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
@Table(name = "lessons")
public class Lesson extends AuditableEntity {

    @Id
    @GeneratedValue
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "school_id")
    private School school;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "candidate_id")
    private Candidate candidate;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "instructor_profile_id")
    private InstructorProfile instructor;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "driving_category_id")
    private DrivingCategory drivingCategory;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id")
    private Branch branch;

    @Column(name = "lesson_type", nullable = false)
    private String lessonType = LessonType.DRIVING.value();

    @Column(nullable = false)
    private String status = LessonStatus.REQUESTED.value();

    @Column(name = "start_at", nullable = false)
    private Instant startAt;

    @Column(name = "end_at", nullable = false)
    private Instant endAt;

    @Column(name = "confirmed_at")
    private Instant confirmedAt;

    @Column(name = "cancelled_at")
    private Instant cancelledAt;

    private String notes;

    @Column(name = "created_by_role", nullable = false)
    private String createdByRole = LessonCreatedByRole.ADMIN.name();

    protected Lesson() {
    }

    public Lesson(
        School school,
        Candidate candidate,
        InstructorProfile instructor,
        DrivingCategory drivingCategory,
        Branch branch,
        String lessonType,
        String status,
        Instant startAt,
        Instant endAt,
        String notes,
        LessonCreatedByRole createdByRole
    ) {
        this.school = school;
        this.candidate = candidate;
        this.instructor = instructor;
        this.drivingCategory = drivingCategory;
        this.branch = branch;
        this.lessonType = lessonType;
        this.status = status;
        this.startAt = startAt;
        this.endAt = endAt;
        this.notes = notes;
        this.createdByRole = createdByRole.name();
    }

    public void update(
        Candidate candidate,
        InstructorProfile instructor,
        DrivingCategory drivingCategory,
        Branch branch,
        String lessonType,
        String status,
        Instant startAt,
        Instant endAt,
        String notes
    ) {
        this.candidate = candidate;
        this.instructor = instructor;
        this.drivingCategory = drivingCategory;
        this.branch = branch;
        this.lessonType = lessonType;
        this.status = status;
        this.startAt = startAt;
        this.endAt = endAt;
        this.notes = notes;
        if (!LessonStatus.CONFIRMED.value().equals(status)) {
            this.confirmedAt = null;
        }
        if (!LessonStatus.CANCELLED.value().equals(status)) {
            this.cancelledAt = null;
        }
    }

    public void confirm() {
        status = LessonStatus.CONFIRMED.value();
        confirmedAt = Instant.now();
        cancelledAt = null;
    }

    public void cancel() {
        status = LessonStatus.CANCELLED.value();
        cancelledAt = Instant.now();
    }

    public UUID getId() {
        return id;
    }

    public School getSchool() {
        return school;
    }

    public Candidate getCandidate() {
        return candidate;
    }

    public InstructorProfile getInstructor() {
        return instructor;
    }

    public DrivingCategory getDrivingCategory() {
        return drivingCategory;
    }

    public Branch getBranch() {
        return branch;
    }

    public String getLessonType() {
        return lessonType;
    }

    public String getStatus() {
        return status;
    }

    public Instant getStartAt() {
        return startAt;
    }

    public Instant getEndAt() {
        return endAt;
    }

    public Instant getConfirmedAt() {
        return confirmedAt;
    }

    public Instant getCancelledAt() {
        return cancelledAt;
    }

    public String getNotes() {
        return notes;
    }

    public String getCreatedByRole() {
        return createdByRole;
    }
}
