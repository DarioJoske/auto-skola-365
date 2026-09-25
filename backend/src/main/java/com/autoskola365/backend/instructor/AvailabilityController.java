package com.autoskola365.backend.instructor;

import java.util.UUID;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import com.autoskola365.backend.auth.AuthenticatedUser;
@RestController
@RequestMapping("/api/schools/{schoolId}/instructors")
public class AvailabilityController {
    private final AvailabilityService service;
    public AvailabilityController(AvailabilityService service) { this.service = service; }
    @GetMapping({"/me/availability", "/{instructorId}/availability"})
    public AvailabilityService.AvailabilityResponse get(@PathVariable UUID schoolId,
        @PathVariable(required = false) UUID instructorId, @AuthenticationPrincipal AuthenticatedUser user) {
        return service.get(schoolId, instructorId, user);
    }
    @PutMapping({"/me/availability", "/{instructorId}/availability"})
    public AvailabilityService.AvailabilityResponse save(@PathVariable UUID schoolId,
        @PathVariable(required = false) UUID instructorId, @Valid @RequestBody AvailabilityRequest request,
        @AuthenticationPrincipal AuthenticatedUser user) { return service.save(schoolId, instructorId, request, user); }
}
