package com.autoskola365.backend.instructor;

import java.time.Instant;
import java.util.UUID;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "instructor_availability_blocks")
public class AvailabilityBlock {
    @Id
    @GeneratedValue
    private UUID id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "instructor_profile_id")
    private InstructorProfile instructor;

    @Column(nullable = false)
    private Instant startAt;
    @Column(nullable = false)
    private Instant endAt;
    @Column(nullable = false)
    private String kind;
    protected AvailabilityBlock() {}
    public AvailabilityBlock(InstructorProfile instructor, Instant startAt, Instant endAt, String kind) {
        this.instructor = instructor;
        this.startAt = startAt;
        this.endAt = endAt;
        this.kind = kind;
    }
    public UUID getId() {
        return id;
    }
    public Instant getStartAt() {
        return startAt;
    }
    public Instant getEndAt() {
        return endAt;
    }
    public String getKind() {
        return kind;
    }
}
