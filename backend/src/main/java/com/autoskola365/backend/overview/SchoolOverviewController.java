package com.autoskola365.backend.overview;

import java.util.UUID;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import com.autoskola365.backend.auth.AuthenticatedUser;

@RestController
@RequestMapping("/api/schools/{schoolId}")
public class SchoolOverviewController {
    private final SchoolOverviewService service;
    public SchoolOverviewController(SchoolOverviewService service) { this.service = service; }

    @GetMapping("/overview")
    public SchoolOverviewResponse overview(@PathVariable UUID schoolId,
        @AuthenticationPrincipal AuthenticatedUser user) {
        return service.overview(schoolId, user);
    }

    @GetMapping("/instructors/overview")
    public InstructorOverviewResponse instructors(@PathVariable UUID schoolId,
        @RequestParam(required = false) String query, @RequestParam(required = false) Boolean active,
        @AuthenticationPrincipal AuthenticatedUser user) {
        return service.instructors(schoolId, query, active, user);
    }
}
