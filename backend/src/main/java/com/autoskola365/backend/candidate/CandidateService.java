package com.autoskola365.backend.candidate;

import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.autoskola365.backend.auth.AuthenticatedUser;
import com.autoskola365.backend.auth.AuthorizationService;
import com.autoskola365.backend.school.School;
import com.autoskola365.backend.school.SchoolRepository;
import com.autoskola365.backend.training.DrivingCategory;
import com.autoskola365.backend.training.DrivingCategoryRepository;

@Service
public class CandidateService {

    private static final String MANAGE_CANDIDATES = "candidates.manage";

    private final CandidateRepository candidateRepository;
    private final SchoolRepository schoolRepository;
    private final DrivingCategoryRepository drivingCategoryRepository;
    private final AuthorizationService authorizationService;

    public CandidateService(
        CandidateRepository candidateRepository,
        SchoolRepository schoolRepository,
        DrivingCategoryRepository drivingCategoryRepository,
        AuthorizationService authorizationService
    ) {
        this.candidateRepository = candidateRepository;
        this.schoolRepository = schoolRepository;
        this.drivingCategoryRepository = drivingCategoryRepository;
        this.authorizationService = authorizationService;
    }

    @Transactional(readOnly = true)
    public List<CandidateResponse> list(
        UUID schoolId,
        String status,
        String categoryCode,
        String query,
        AuthenticatedUser authenticatedUser
    ) {
        requirePermission(schoolId, authenticatedUser);

        String normalizedStatus = status == null || status.isBlank() ? null : CandidateStatus.normalize(status);
        String normalizedCategory = categoryCode == null || categoryCode.isBlank() ? null : categoryCode.trim().toUpperCase();
        String normalizedQuery = query == null || query.isBlank() ? null : query.trim();

        return candidateRepository.findBySchoolIdOrderByCreatedAtDesc(schoolId)
            .stream()
            .filter(candidate -> normalizedStatus == null || candidate.getStatus().equals(normalizedStatus))
            .filter(candidate -> normalizedCategory == null || candidate.getDrivingCategory().getCode().equals(normalizedCategory))
            .filter(candidate -> normalizedQuery == null || matchesQuery(candidate, normalizedQuery))
            .map(this::toResponse)
            .toList();
    }

    @Transactional(readOnly = true)
    public CandidateResponse get(UUID schoolId, UUID candidateId, AuthenticatedUser authenticatedUser) {
        requirePermission(schoolId, authenticatedUser);

        return candidateRepository.findByIdAndSchoolId(candidateId, schoolId)
            .map(this::toResponse)
            .orElseThrow(() -> new CandidateNotFoundException("Candidate does not exist."));
    }

    @Transactional
    public CandidateResponse create(UUID schoolId, CreateCandidateRequest request, AuthenticatedUser authenticatedUser) {
        requirePermission(schoolId, authenticatedUser);

        School school = schoolRepository.findById(schoolId)
            .orElseThrow(() -> new IllegalArgumentException("School does not exist."));
        DrivingCategory category = getActiveCategory(request.categoryCode());
        String status = CandidateStatus.normalizeOrDefault(request.status());

        Candidate candidate = candidateRepository.save(new Candidate(
            school,
            category,
            request.firstName(),
            request.lastName(),
            request.email(),
            request.phone(),
            request.oib(),
            status,
            request.notes()
        ));

        return toResponse(candidate);
    }

    @Transactional
    public CandidateResponse update(
        UUID schoolId,
        UUID candidateId,
        UpdateCandidateRequest request,
        AuthenticatedUser authenticatedUser
    ) {
        requirePermission(schoolId, authenticatedUser);

        Candidate candidate = candidateRepository.findByIdAndSchoolId(candidateId, schoolId)
            .orElseThrow(() -> new CandidateNotFoundException("Candidate does not exist."));
        DrivingCategory category = getActiveCategory(request.categoryCode());
        String status = CandidateStatus.normalize(request.status());

        candidate.update(
            category,
            request.firstName(),
            request.lastName(),
            request.email(),
            request.phone(),
            request.oib(),
            status,
            request.notes()
        );

        return toResponse(candidate);
    }

    private DrivingCategory getActiveCategory(String categoryCode) {
        return drivingCategoryRepository.findByCodeAndActiveTrue(categoryCode.trim().toUpperCase())
            .orElseThrow(() -> new IllegalArgumentException("Driving category does not exist."));
    }

    private void requirePermission(UUID schoolId, AuthenticatedUser authenticatedUser) {
        if (!authorizationService.hasSchoolPermission(authenticatedUser, schoolId, MANAGE_CANDIDATES)) {
            throw new CandidateAccessDeniedException("User cannot manage candidates for this school.");
        }
    }

    private boolean matchesQuery(Candidate candidate, String query) {
        String normalizedQuery = query.toLowerCase();
        return contains(candidate.getFirstName(), normalizedQuery)
            || contains(candidate.getLastName(), normalizedQuery)
            || contains(candidate.getEmail(), normalizedQuery)
            || contains(candidate.getPhone(), normalizedQuery)
            || contains(candidate.getOib(), normalizedQuery);
    }

    private boolean contains(String value, String normalizedQuery) {
        return value != null && value.toLowerCase().contains(normalizedQuery);
    }

    private CandidateResponse toResponse(Candidate candidate) {
        return new CandidateResponse(
            candidate.getId(),
            candidate.getSchool().getId(),
            candidate.getFirstName(),
            candidate.getLastName(),
            candidate.getEmail(),
            candidate.getPhone(),
            candidate.getOib(),
            candidate.getStatus(),
            candidate.getDrivingCategory().getCode(),
            candidate.getDrivingCategory().getName(),
            candidate.getNotes()
        );
    }
}
