package com.autoskola365.backend.progress;
import java.time.Instant;
import java.util.*;
public record ProgressResponse(UUID candidateId, String candidateName, String categoryCode,
    UUID lessonId, boolean editable, List<Option> skills, List<Option> statuses, List<Entry> entries) {
    public record Option(String code, String label) {}
    public record Entry(UUID lessonId, Instant lessonEndAt, String skill, String status, Instant recordedAt) {}
}
