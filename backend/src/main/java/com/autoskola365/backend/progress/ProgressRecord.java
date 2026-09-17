package com.autoskola365.backend.progress;
import java.time.Instant;
import java.util.UUID;
import jakarta.persistence.*;
import com.autoskola365.backend.lesson.Lesson;
@Entity
@Table(name="lesson_progress", uniqueConstraints=@UniqueConstraint(columnNames={"lesson_id", "skill"}))
// Retain the legacy mapping for stored assessments; MVP has no assessment write API.
public class ProgressRecord {
    @Id @GeneratedValue private UUID id;
    @ManyToOne(fetch=FetchType.LAZY, optional=false) @JoinColumn(name="lesson_id") private Lesson lesson;
    @Column(nullable=false) private String skill;
    @Column(nullable=false) private String status;
    @Column(nullable=false) private Instant recordedAt;
    protected ProgressRecord() {}
    public Lesson getLesson() { return lesson; }
    public String getSkill() { return skill; }
    public String getStatus() { return status; }
    public Instant getRecordedAt() { return recordedAt; }
}
