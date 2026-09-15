package com.autoskola365.backend.progress;
import java.time.Instant;
import java.util.UUID;
import jakarta.persistence.*;
import com.autoskola365.backend.lesson.Lesson;
@Entity
@Table(name="lesson_progress", uniqueConstraints=@UniqueConstraint(columnNames={"lesson_id", "skill"}))
public class ProgressRecord {
    @Id @GeneratedValue private UUID id;
    @ManyToOne(fetch=FetchType.LAZY, optional=false) @JoinColumn(name="lesson_id") private Lesson lesson;
    @Column(nullable=false) private String skill;
    @Column(nullable=false) private String status;
    @Column(nullable=false) private Instant recordedAt;
    protected ProgressRecord() {}
    public ProgressRecord(Lesson lesson, String skill) { this.lesson=lesson; this.skill=skill; }
    public void assess(String status) { this.status=status; this.recordedAt=Instant.now(); }
    public Lesson getLesson() { return lesson; }
    public String getSkill() { return skill; }
    public String getStatus() { return status; }
    public Instant getRecordedAt() { return recordedAt; }
}
