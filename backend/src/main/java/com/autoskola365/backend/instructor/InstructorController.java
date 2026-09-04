package com.autoskola365.backend.instructor;

import java.util.List;
import java.util.UUID;

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
@RequestMapping("/api/schools/{schoolId}/instructors")
public class InstructorController {

    private final InstructorService instructorService;

    public InstructorController(InstructorService instructorService) {
        this.instructorService = instructorService;
    }

    @GetMapping
    public List<InstructorResponse> list(
        @PathVariable UUID schoolId,
        @RequestParam(required = false) Boolean active,
        @RequestParam(required = false) String categoryCode,
        @AuthenticationPrincipal AuthenticatedUser authenticatedUser
    ) {
        return instructorService.list(schoolId, active, categoryCode, authenticatedUser);
    }

    @GetMapping("/{instructorId}")
    public InstructorResponse get(
        @PathVariable UUID schoolId,
        @PathVariable UUID instructorId,
        @AuthenticationPrincipal AuthenticatedUser authenticatedUser
    ) {
        return instructorService.get(schoolId, instructorId, authenticatedUser);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public InstructorResponse create(
        @PathVariable UUID schoolId,
        @Valid @RequestBody InstructorRequest request,
        @AuthenticationPrincipal AuthenticatedUser authenticatedUser
    ) {
        return instructorService.create(schoolId, request, authenticatedUser);
    }

    @PutMapping("/{instructorId}")
    public InstructorResponse update(
        @PathVariable UUID schoolId,
        @PathVariable UUID instructorId,
        @Valid @RequestBody InstructorRequest request,
        @AuthenticationPrincipal AuthenticatedUser authenticatedUser
    ) {
        return instructorService.update(schoolId, instructorId, request, authenticatedUser);
    }
}
