package com.autoskola365.backend.lesson;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.autoskola365.backend.auth.AuthenticatedUser;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/schools/{schoolId}/lessons")
public class LessonController {

    private final LessonService lessonService;

    public LessonController(LessonService lessonService) {
        this.lessonService = lessonService;
    }

    @GetMapping
    public List<LessonResponse> list(
        @PathVariable UUID schoolId,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant from,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant to,
        @RequestParam(required = false) UUID instructorId,
        @RequestParam(required = false) UUID candidateId,
        @RequestParam(required = false) String status,
        @AuthenticationPrincipal AuthenticatedUser authenticatedUser
    ) {
        return lessonService.list(schoolId, from, to, instructorId, candidateId, status, authenticatedUser);
    }

    @GetMapping("/instructor")
    public List<LessonResponse> listInstructorLessons(
        @PathVariable UUID schoolId,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant from,
        @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant to,
        @RequestParam(required = false) String status,
        @AuthenticationPrincipal AuthenticatedUser authenticatedUser
    ) {
        return lessonService.listInstructorLessons(schoolId, from, to, status, authenticatedUser);
    }

    @GetMapping("/instructor/{lessonId}")
    public LessonResponse getInstructorLesson(
        @PathVariable UUID schoolId,
        @PathVariable UUID lessonId,
        @AuthenticationPrincipal AuthenticatedUser authenticatedUser
    ) {
        return lessonService.getInstructorLesson(schoolId, lessonId, authenticatedUser);
    }

    @PostMapping("/candidate/reservations")
    @ResponseStatus(HttpStatus.CREATED)
    public LessonResponse createCandidateReservation(
        @PathVariable UUID schoolId,
        @Valid @RequestBody CandidateLessonReservationRequest request,
        @AuthenticationPrincipal AuthenticatedUser authenticatedUser
    ) {
        return lessonService.createCandidateReservation(schoolId, request, authenticatedUser);
    }

    @GetMapping("/{lessonId}")
    public LessonResponse get(
        @PathVariable UUID schoolId,
        @PathVariable UUID lessonId,
        @AuthenticationPrincipal AuthenticatedUser authenticatedUser
    ) {
        return lessonService.get(schoolId, lessonId, authenticatedUser);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public LessonResponse create(
        @PathVariable UUID schoolId,
        @Valid @RequestBody LessonRequest request,
        @AuthenticationPrincipal AuthenticatedUser authenticatedUser
    ) {
        return lessonService.create(schoolId, request, authenticatedUser);
    }

    @PutMapping("/{lessonId}")
    public LessonResponse update(
        @PathVariable UUID schoolId,
        @PathVariable UUID lessonId,
        @Valid @RequestBody LessonRequest request,
        @AuthenticationPrincipal AuthenticatedUser authenticatedUser
    ) {
        return lessonService.update(schoolId, lessonId, request, authenticatedUser);
    }

    @PostMapping("/{lessonId}/confirm")
    public LessonResponse confirm(
        @PathVariable UUID schoolId,
        @PathVariable UUID lessonId,
        @AuthenticationPrincipal AuthenticatedUser authenticatedUser
    ) {
        return lessonService.confirm(schoolId, lessonId, authenticatedUser);
    }

    @PostMapping("/{lessonId}/complete")
    public LessonResponse complete(
        @PathVariable UUID schoolId,
        @PathVariable UUID lessonId,
        @Valid @RequestBody CompleteLessonRequest request,
        @AuthenticationPrincipal AuthenticatedUser authenticatedUser
    ) {
        return lessonService.complete(schoolId, lessonId, request, authenticatedUser);
    }

    @PostMapping("/{lessonId}/cancel")
    public LessonResponse cancel(
        @PathVariable UUID schoolId,
        @PathVariable UUID lessonId,
        @AuthenticationPrincipal AuthenticatedUser authenticatedUser
    ) {
        return lessonService.cancel(schoolId, lessonId, authenticatedUser);
    }
}
