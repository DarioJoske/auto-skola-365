package com.autoskola365.backend.candidate;

import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.autoskola365.backend.auth.AuthenticatedUser;
import com.autoskola365.backend.auth.AuthorizationService;
import com.autoskola365.backend.instructor.InstructorProfile;
import com.autoskola365.backend.instructor.InstructorRepository;
import com.autoskola365.backend.school.School;
import com.autoskola365.backend.school.SchoolRepository;
import com.autoskola365.backend.training.DrivingCategory;
import com.autoskola365.backend.training.DrivingCategoryRepository;

@Service
public class CandidateService {

    private static final String MANAGE_CANDIDATES = "candidates.manage";
    private static final String VIEW_ASSIGNED_LESSONS = "lessons.view_assigned";

    private final CandidateRepository candidateRepository;
    private final SchoolRepository schoolRepository;
    private final DrivingCategoryRepository drivingCategoryRepository;
    private final InstructorRepository instructorRepository;
    private final AuthorizationService authorizationService;
    private final com.autoskola365.backend.identity.UserAccountRepository users;
    private final com.autoskola365.backend.identity.SchoolMembershipRepository memberships;
    private final com.autoskola365.backend.identity.RoleRepository roles;
    private final org.springframework.security.crypto.password.PasswordEncoder passwordEncoder;

    public CandidateService(
        CandidateRepository candidateRepository,
        SchoolRepository schoolRepository,
        DrivingCategoryRepository drivingCategoryRepository,
        InstructorRepository instructorRepository,
        AuthorizationService authorizationService,
        com.autoskola365.backend.identity.UserAccountRepository users,
        com.autoskola365.backend.identity.SchoolMembershipRepository memberships,
        com.autoskola365.backend.identity.RoleRepository roles,
        org.springframework.security.crypto.password.PasswordEncoder passwordEncoder
    ) {
        this.candidateRepository = candidateRepository;
        this.schoolRepository = schoolRepository;
        this.drivingCategoryRepository = drivingCategoryRepository;
        this.instructorRepository = instructorRepository;
        this.authorizationService = authorizationService;
        this.users = users;
        this.memberships = memberships;
        this.roles = roles;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional(readOnly = true)
    public List<CandidateResponse> list(
        UUID schoolId,
        String status,
        String categoryCode,
        UUID assignedInstructorId,
        boolean withoutInstructor,
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
            .filter(candidate -> !withoutInstructor || candidate.getAssignedInstructor() == null)
            .filter(candidate -> assignedInstructorId == null || matchesAssignedInstructor(candidate, assignedInstructorId))
            .filter(candidate -> normalizedQuery == null || matchesQuery(candidate, normalizedQuery))
            .map(this::toResponse)
            .toList();
    }

    @Transactional(readOnly = true)
    public List<CandidateResponse> listInstructorCandidates(
        UUID schoolId,
        String status,
        String categoryCode,
        String query,
        AuthenticatedUser authenticatedUser
    ) {
        requireInstructorAccess(schoolId, authenticatedUser);
        InstructorProfile instructor = getInstructorForUser(schoolId, authenticatedUser);

        String normalizedStatus = status == null || status.isBlank() ? null : CandidateStatus.normalize(status);
        String normalizedCategory = categoryCode == null || categoryCode.isBlank() ? null : categoryCode.trim().toUpperCase();
        String normalizedQuery = query == null || query.isBlank() ? null : query.trim();

        return candidateRepository.findBySchoolIdAndAssignedInstructorIdOrderByCreatedAtDesc(schoolId, instructor.getId())
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
        InstructorProfile assignedInstructor = getAssignedInstructor(schoolId, request.assignedInstructorId());
        String status = CandidateStatus.normalizeOrDefault(request.status());
        ensureOibIsUnique(schoolId, request.oib(), null);

        Candidate candidate = candidateRepository.save(new Candidate(
            school,
            category,
            request.firstName(),
            request.lastName(),
            request.email(),
            request.phone(),
            request.oib(),
            status,
            assignedInstructor,
            request.notes()
        ));

        candidate.setRequiredDrivingHours(request.requiredDrivingHours());
        saveLoginPassword(candidate, request.loginPassword());
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
        InstructorProfile assignedInstructor = getAssignedInstructor(schoolId, request.assignedInstructorId());
        String status = CandidateStatus.normalize(request.status());
        ensureOibIsUnique(schoolId, request.oib(), candidateId);

        if (!candidate.getDrivingCategory().getId().equals(category.getId())) {
            candidate.setRequiredDrivingHours(null);
        }
        if (request.requiredDrivingHours() != null) {
            candidate.setRequiredDrivingHours(request.requiredDrivingHours());
        }

        candidate.update(
            category,
            request.firstName(),
            request.lastName(),
            request.email(),
            request.phone(),
            request.oib(),
            status,
            assignedInstructor,
            request.notes()
        );

        saveLoginPassword(candidate, request.loginPassword());
        return toResponse(candidate);
    }

    private DrivingCategory getActiveCategory(String categoryCode) {
        return drivingCategoryRepository.findByCodeAndActiveTrue(categoryCode.trim().toUpperCase())
            .orElseThrow(() -> new IllegalArgumentException("Driving category does not exist."));
    }

    private void ensureOibIsUnique(UUID schoolId, String oib, UUID excludedCandidateId) {
        if (oib == null || oib.isBlank()) {
            return;
        }

        String normalizedOib = oib.trim();
        boolean exists = excludedCandidateId == null
            ? candidateRepository.existsBySchoolIdAndOib(schoolId, normalizedOib)
            : candidateRepository.existsBySchoolIdAndOibAndIdNot(schoolId, normalizedOib, excludedCandidateId);
        if (exists) {
            throw new CandidateDuplicateOibException("Kandidat s tim OIB-om vec postoji.");
        }
    }

    private InstructorProfile getAssignedInstructor(UUID schoolId, UUID instructorId) {
        if (instructorId == null) {
            return null;
        }

        return instructorRepository.findByIdAndSchoolMembershipSchoolId(instructorId, schoolId)
            .orElseThrow(() -> new IllegalArgumentException("Assigned instructor does not exist."));
    }

    private void saveLoginPassword(Candidate candidate, String password) {
        if (password == null) return;
        if (candidate.getUser() != null) {
            var user = candidate.getUser();
            var userMemberships = memberships.findByUserId(user.getId());
            boolean hasCandidateAccess = userMemberships.stream().anyMatch(membership ->
                membership.getSchool().getId().equals(candidate.getSchool().getId())
                    && "candidate".equals(membership.getRole().getKey())
                    && "ACTIVE".equals(membership.getStatus()));
            boolean hasOtherAccess = userMemberships.stream().anyMatch(membership ->
                !membership.getSchool().getId().equals(candidate.getSchool().getId())
                    || !"candidate".equals(membership.getRole().getKey()));
            if (!hasCandidateAccess || hasOtherAccess) {
                throw new CandidateAccessDeniedException(
                    "Lozinku je moguće promijeniti samo za kandidatski račun ove škole.");
            }
            user.changePasswordHash(passwordEncoder.encode(password));
            return;
        }
        String email = candidate.getEmail();
        if (email == null || email.isBlank()) {
            throw new IllegalArgumentException("Za aktivaciju pristupa unesite email kandidata.");
        }
        if (users.findByEmailIgnoreCase(email.trim()).isPresent()) {
            throw new IllegalArgumentException("Email već ima korisnički račun. Unesite drugi email za novi pristup.");
        }
        var role = roles.findByKey("candidate").orElseThrow(() -> new IllegalStateException("Missing candidate role seed."));
        var user = users.save(new com.autoskola365.backend.identity.UserAccount(email.trim(),
            passwordEncoder.encode(password), candidate.getFirstName(), candidate.getLastName(), candidate.getPhone()));
        memberships.save(new com.autoskola365.backend.identity.SchoolMembership(candidate.getSchool(), user, role));
        candidate.linkUser(user);
    }

    private void requirePermission(UUID schoolId, AuthenticatedUser authenticatedUser) {
        if (!authorizationService.hasSchoolPermission(authenticatedUser, schoolId, MANAGE_CANDIDATES)) {
            throw new CandidateAccessDeniedException("User cannot manage candidates for this school.");
        }
    }

    private void requireInstructorAccess(UUID schoolId, AuthenticatedUser authenticatedUser) {
        if (!authorizationService.hasSchoolPermission(authenticatedUser, schoolId, VIEW_ASSIGNED_LESSONS)) {
            throw new CandidateAccessDeniedException("User cannot view assigned candidates for this school.");
        }
    }

    private InstructorProfile getInstructorForUser(UUID schoolId, AuthenticatedUser authenticatedUser) {
        return instructorRepository.findBySchoolMembershipSchoolIdAndSchoolMembershipUserId(schoolId, authenticatedUser.userId())
            .orElseThrow(() -> new CandidateAccessDeniedException("User is not an instructor for this school."));
    }

    private boolean matchesQuery(Candidate candidate, String query) {
        String normalizedQuery = query.toLowerCase();
        return contains(candidate.getFirstName() + " " + candidate.getLastName(), normalizedQuery)
            || contains(candidate.getFirstName(), normalizedQuery)
            || contains(candidate.getLastName(), normalizedQuery)
            || contains(candidate.getEmail(), normalizedQuery)
            || contains(candidate.getPhone(), normalizedQuery)
            || contains(candidate.getOib(), normalizedQuery);
    }

    private boolean matchesAssignedInstructor(Candidate candidate, UUID assignedInstructorId) {
        InstructorProfile assignedInstructor = candidate.getAssignedInstructor();
        return assignedInstructor != null && assignedInstructor.getId().equals(assignedInstructorId);
    }

    private boolean contains(String value, String normalizedQuery) {
        return value != null && value.toLowerCase().contains(normalizedQuery);
    }

    private CandidateResponse toResponse(Candidate candidate) {
        InstructorProfile assignedInstructor = candidate.getAssignedInstructor();
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
            assignedInstructor == null ? null : assignedInstructor.getId(),
            assignedInstructor == null ? null : assignedInstructor.getSchoolMembership().getUser().getFirstName()
                + " "
                + assignedInstructor.getSchoolMembership().getUser().getLastName(),
            candidate.getNotes(),
            candidate.getRequiredDrivingHours(),
            candidate.getUser() != null,
            candidate.getUser() == null ? null : candidate.getUser().getEmail()
        );
    }
}
