package com.autoskola365.backend.candidate;

import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import com.autoskola365.backend.auth.AuthenticatedUser;

@RestController
@RequestMapping("/api/schools/{schoolId}/candidate-portal")
public class CandidatePortalController {
    private final CandidatePortalService service;
    public CandidatePortalController(CandidatePortalService service) { this.service = service; }
    @GetMapping
    public CandidatePortalService.PortalResponse get(@PathVariable UUID schoolId, @AuthenticationPrincipal AuthenticatedUser user) {
        return service.get(schoolId, user);
    }
}
