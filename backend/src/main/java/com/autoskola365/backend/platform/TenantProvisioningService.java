package com.autoskola365.backend.platform;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.autoskola365.backend.identity.Role;
import com.autoskola365.backend.identity.RoleRepository;
import com.autoskola365.backend.identity.SchoolMembership;
import com.autoskola365.backend.identity.SchoolMembershipRepository;
import com.autoskola365.backend.identity.UserAccount;
import com.autoskola365.backend.identity.UserAccountRepository;
import com.autoskola365.backend.school.Branch;
import com.autoskola365.backend.school.BranchRepository;
import com.autoskola365.backend.school.School;
import com.autoskola365.backend.school.SchoolRepository;

@Service
public class TenantProvisioningService {

    private final SchoolRepository schoolRepository;
    private final BranchRepository branchRepository;
    private final UserAccountRepository userAccountRepository;
    private final RoleRepository roleRepository;
    private final SchoolMembershipRepository membershipRepository;
    private final PasswordEncoder passwordEncoder;

    public TenantProvisioningService(
        SchoolRepository schoolRepository,
        BranchRepository branchRepository,
        UserAccountRepository userAccountRepository,
        RoleRepository roleRepository,
        SchoolMembershipRepository membershipRepository,
        PasswordEncoder passwordEncoder
    ) {
        this.schoolRepository = schoolRepository;
        this.branchRepository = branchRepository;
        this.userAccountRepository = userAccountRepository;
        this.roleRepository = roleRepository;
        this.membershipRepository = membershipRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional
    public CreateTenantResponse createTenant(CreateTenantRequest request) {
        userAccountRepository.findByEmailIgnoreCase(request.owner().email())
            .ifPresent(user -> {
                throw new IllegalArgumentException("Owner email is already registered.");
            });

        School school = schoolRepository.save(new School(
            request.schoolName(),
            request.schoolOib(),
            request.schoolEmail(),
            request.schoolPhone()
        ));

        Branch branch = branchRepository.save(new Branch(
            school,
            request.branch().name(),
            request.branch().address(),
            request.branch().city(),
            request.branch().phone()
        ));

        UserAccount owner = userAccountRepository.save(new UserAccount(
            request.owner().email(),
            passwordEncoder.encode(request.owner().password()),
            request.owner().firstName(),
            request.owner().lastName(),
            request.owner().phone()
        ));

        Role ownerRole = roleRepository.findByKey("school_owner")
            .orElseThrow(() -> new IllegalStateException("Missing school_owner role seed."));

        SchoolMembership membership = membershipRepository.save(new SchoolMembership(school, owner, ownerRole));

        return new CreateTenantResponse(
            school.getId(),
            branch.getId(),
            owner.getId(),
            membership.getId()
        );
    }
}
