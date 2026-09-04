package com.autoskola365.backend.instructor;

import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.autoskola365.backend.auth.AuthenticatedUser;
import com.autoskola365.backend.auth.AuthorizationService;
import com.autoskola365.backend.identity.Role;
import com.autoskola365.backend.identity.RoleRepository;
import com.autoskola365.backend.identity.SchoolMembership;
import com.autoskola365.backend.identity.SchoolMembershipRepository;
import com.autoskola365.backend.identity.UserAccount;
import com.autoskola365.backend.identity.UserAccountRepository;
import com.autoskola365.backend.school.School;
import com.autoskola365.backend.school.SchoolRepository;
import com.autoskola365.backend.training.DrivingCategory;
import com.autoskola365.backend.training.DrivingCategoryRepository;

@Service
public class InstructorService {

    private static final String MANAGE_INSTRUCTORS = "instructors.manage";
    private static final String INSTRUCTOR_ROLE = "instructor";

    private final InstructorRepository instructorRepository;
    private final SchoolRepository schoolRepository;
    private final UserAccountRepository userAccountRepository;
    private final SchoolMembershipRepository membershipRepository;
    private final RoleRepository roleRepository;
    private final DrivingCategoryRepository drivingCategoryRepository;
    private final AuthorizationService authorizationService;
    private final PasswordEncoder passwordEncoder;

    public InstructorService(
        InstructorRepository instructorRepository,
        SchoolRepository schoolRepository,
        UserAccountRepository userAccountRepository,
        SchoolMembershipRepository membershipRepository,
        RoleRepository roleRepository,
        DrivingCategoryRepository drivingCategoryRepository,
        AuthorizationService authorizationService,
        PasswordEncoder passwordEncoder
    ) {
        this.instructorRepository = instructorRepository;
        this.schoolRepository = schoolRepository;
        this.userAccountRepository = userAccountRepository;
        this.membershipRepository = membershipRepository;
        this.roleRepository = roleRepository;
        this.drivingCategoryRepository = drivingCategoryRepository;
        this.authorizationService = authorizationService;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional(readOnly = true)
    public List<InstructorResponse> list(
        UUID schoolId,
        Boolean active,
        String categoryCode,
        AuthenticatedUser authenticatedUser
    ) {
        requirePermission(schoolId, authenticatedUser);

        String normalizedCategory = categoryCode == null || categoryCode.isBlank() ? null : categoryCode.trim().toUpperCase();
        return instructorRepository.search(schoolId, active, normalizedCategory)
            .stream()
            .map(this::toResponse)
            .toList();
    }

    @Transactional(readOnly = true)
    public InstructorResponse get(UUID schoolId, UUID instructorId, AuthenticatedUser authenticatedUser) {
        requirePermission(schoolId, authenticatedUser);

        return instructorRepository.findByIdAndSchoolMembershipSchoolId(instructorId, schoolId)
            .map(this::toResponse)
            .orElseThrow(() -> new InstructorNotFoundException("Instructor does not exist."));
    }

    @Transactional
    public InstructorResponse create(UUID schoolId, InstructorRequest request, AuthenticatedUser authenticatedUser) {
        requirePermission(schoolId, authenticatedUser);

        School school = schoolRepository.findById(schoolId)
            .orElseThrow(() -> new IllegalArgumentException("School does not exist."));
        UserAccount user = userAccountRepository.findByEmailIgnoreCase(request.email())
            .orElseGet(() -> userAccountRepository.save(new UserAccount(
                request.email(),
                passwordEncoder.encode(UUID.randomUUID().toString()),
                request.firstName(),
                request.lastName(),
                request.phone()
            )));
        user.updateProfile(request.firstName(), request.lastName(), request.phone());

        Role instructorRole = roleRepository.findByKey(INSTRUCTOR_ROLE)
            .orElseThrow(() -> new IllegalStateException("Missing instructor role seed."));
        SchoolMembership membership = membershipRepository.findBySchoolIdAndUserId(schoolId, user.getId())
            .orElseGet(() -> membershipRepository.save(new SchoolMembership(school, user, instructorRole)));

        if (instructorRepository.existsBySchoolMembershipId(membership.getId())) {
            throw new IllegalArgumentException("Instructor already exists for this school.");
        }

        InstructorProfile instructor = new InstructorProfile(
            membership,
            request.licenseNumber(),
            activeOrDefault(request)
        );
        applyInstructorDetails(instructor, request);

        return toResponse(instructorRepository.save(instructor));
    }

    @Transactional
    public InstructorResponse update(
        UUID schoolId,
        UUID instructorId,
        InstructorRequest request,
        AuthenticatedUser authenticatedUser
    ) {
        requirePermission(schoolId, authenticatedUser);

        InstructorProfile instructor = instructorRepository.findByIdAndSchoolMembershipSchoolId(instructorId, schoolId)
            .orElseThrow(() -> new InstructorNotFoundException("Instructor does not exist."));
        instructor.getSchoolMembership().getUser().updateProfile(
            request.firstName(),
            request.lastName(),
            request.phone()
        );
        applyInstructorDetails(instructor, request);

        return toResponse(instructor);
    }

    private void applyInstructorDetails(InstructorProfile instructor, InstructorRequest request) {
        Set<DrivingCategory> categories = getActiveCategories(request.categoryCodes());
        instructor.update(request.licenseNumber(), activeOrDefault(request), categories);
        instructor.replaceAvailabilityRules(toAvailabilityRules(instructor, request.availabilityRules()));
    }

    private boolean activeOrDefault(InstructorRequest request) {
        return request.active() == null || request.active();
    }

    private Set<DrivingCategory> getActiveCategories(List<String> categoryCodes) {
        Set<DrivingCategory> categories = new HashSet<>();

        for (String categoryCode : categoryCodes) {
            DrivingCategory category = drivingCategoryRepository.findByCodeAndActiveTrue(categoryCode.trim().toUpperCase())
                .orElseThrow(() -> new IllegalArgumentException("Driving category does not exist."));
            categories.add(category);
        }

        return categories;
    }

    private List<InstructorAvailabilityRule> toAvailabilityRules(
        InstructorProfile instructor,
        List<InstructorRequest.AvailabilityRuleRequest> rules
    ) {
        if (rules == null) {
            return List.of();
        }

        return rules.stream()
            .map(rule -> {
                if (!rule.startTime().isBefore(rule.endTime())) {
                    throw new IllegalArgumentException("Availability start time must be before end time.");
                }

                return new InstructorAvailabilityRule(
                    instructor,
                    rule.dayOfWeek(),
                    rule.startTime(),
                    rule.endTime()
                );
            })
            .toList();
    }

    private void requirePermission(UUID schoolId, AuthenticatedUser authenticatedUser) {
        if (!authorizationService.hasSchoolPermission(authenticatedUser, schoolId, MANAGE_INSTRUCTORS)) {
            throw new InstructorAccessDeniedException("User cannot manage instructors for this school.");
        }
    }

    private InstructorResponse toResponse(InstructorProfile instructor) {
        SchoolMembership membership = instructor.getSchoolMembership();
        UserAccount user = membership.getUser();

        List<String> categoryCodes = instructor.getCategories()
            .stream()
            .map(DrivingCategory::getCode)
            .sorted(Comparator.naturalOrder())
            .toList();
        List<InstructorResponse.AvailabilityRuleResponse> availabilityRules = instructor.getAvailabilityRules()
            .stream()
            .sorted(Comparator
                .comparingInt(InstructorAvailabilityRule::getDayOfWeek)
                .thenComparing(InstructorAvailabilityRule::getStartTime))
            .map(rule -> new InstructorResponse.AvailabilityRuleResponse(
                rule.getId(),
                rule.getDayOfWeek(),
                rule.getStartTime(),
                rule.getEndTime()
            ))
            .toList();

        return new InstructorResponse(
            instructor.getId(),
            membership.getSchool().getId(),
            user.getId(),
            membership.getId(),
            user.getFirstName(),
            user.getLastName(),
            user.getEmail(),
            user.getPhone(),
            instructor.getLicenseNumber(),
            instructor.isActive(),
            categoryCodes,
            availabilityRules
        );
    }
}
