package com.autoskola365.backend.auth;

import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.autoskola365.backend.identity.SchoolMembership;
import com.autoskola365.backend.identity.SchoolMembershipRepository;

@Service
public class AuthorizationService {

    private final SchoolMembershipRepository membershipRepository;

    public AuthorizationService(SchoolMembershipRepository membershipRepository) {
        this.membershipRepository = membershipRepository;
    }

    @Transactional(readOnly = true)
    public boolean hasSchoolPermission(AuthenticatedUser authenticatedUser, UUID schoolId, String permissionKey) {
        return membershipRepository.findByUserIdAndStatus(authenticatedUser.userId(), "ACTIVE")
            .stream()
            .filter(membership -> membership.getSchool().getId().equals(schoolId))
            .map(SchoolMembership::getRole)
            .flatMap(role -> role.getPermissions().stream())
            .anyMatch(permission -> permissionKey.equals(permission.getKey()));
    }
}
