package com.autoskola365.backend.progress;

import java.util.UUID;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.autoskola365.backend.auth.AuthenticatedUser;

@RestController
@RequestMapping("/api/schools/{schoolId}")
public class ProgressController {

    private final ProgressService service;

    public ProgressController(ProgressService service) {
        this.service = service;
    }

    @GetMapping("/candidates/{candidateId}/progress")
    public ProgressResponse candidate(
        @PathVariable UUID schoolId,
        @PathVariable UUID candidateId,
        @AuthenticationPrincipal AuthenticatedUser user
    ) {
        return service.forCandidate(schoolId, candidateId, user);
    }

    @GetMapping("/lessons/{lessonId}/progress")
    public ProgressResponse lesson(
        @PathVariable UUID schoolId,
        @PathVariable UUID lessonId,
        @AuthenticationPrincipal AuthenticatedUser user
    ) {
        return service.forLesson(schoolId, lessonId, user);
    }
}
