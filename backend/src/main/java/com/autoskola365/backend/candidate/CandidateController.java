package com.autoskola365.backend.candidate;

import java.util.List;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import com.autoskola365.backend.auth.AuthenticatedUser;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/schools/{schoolId}/candidates")
public class CandidateController {

    private final CandidateService candidateService;

    public CandidateController(CandidateService candidateService) {
        this.candidateService = candidateService;
    }

    @GetMapping
    public List<CandidateResponse> list(
        @PathVariable UUID schoolId,
        @RequestParam(required = false) String status,
        @RequestParam(required = false) String categoryCode,
        @RequestParam(required = false, name = "q") String query,
        @AuthenticationPrincipal AuthenticatedUser authenticatedUser
    ) {
        return candidateService.list(schoolId, status, categoryCode, query, authenticatedUser);
    }

    @GetMapping("/{candidateId}")
    public CandidateResponse get(
        @PathVariable UUID schoolId,
        @PathVariable UUID candidateId,
        @AuthenticationPrincipal AuthenticatedUser authenticatedUser
    ) {
        return candidateService.get(schoolId, candidateId, authenticatedUser);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public CandidateResponse create(
        @PathVariable UUID schoolId,
        @Valid @RequestBody CreateCandidateRequest request,
        @AuthenticationPrincipal AuthenticatedUser authenticatedUser
    ) {
        return candidateService.create(schoolId, request, authenticatedUser);
    }

    @PutMapping("/{candidateId}")
    public CandidateResponse update(
        @PathVariable UUID schoolId,
        @PathVariable UUID candidateId,
        @Valid @RequestBody UpdateCandidateRequest request,
        @AuthenticationPrincipal AuthenticatedUser authenticatedUser
    ) {
        return candidateService.update(schoolId, candidateId, request, authenticatedUser);
    }
}
