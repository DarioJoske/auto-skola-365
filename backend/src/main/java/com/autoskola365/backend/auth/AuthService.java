package com.autoskola365.backend.auth;

import java.util.Comparator;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.autoskola365.backend.identity.SchoolMembership;
import com.autoskola365.backend.identity.SchoolMembershipRepository;
import com.autoskola365.backend.identity.UserAccount;
import com.autoskola365.backend.identity.UserAccountRepository;

@Service
public class AuthService {

    private final UserAccountRepository userAccountRepository;
    private final SchoolMembershipRepository membershipRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final JwtProperties jwtProperties;

    public AuthService(
        UserAccountRepository userAccountRepository,
        SchoolMembershipRepository membershipRepository,
        PasswordEncoder passwordEncoder,
        JwtService jwtService,
        JwtProperties jwtProperties
    ) {
        this.userAccountRepository = userAccountRepository;
        this.membershipRepository = membershipRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.jwtProperties = jwtProperties;
    }

    @Transactional(readOnly = true)
    public LoginResponse login(LoginRequest request) {
        UserAccount user = userAccountRepository.findByEmailIgnoreCase(request.email())
            .filter(account -> passwordEncoder.matches(request.password(), account.getPasswordHash()))
            .orElseThrow(() -> new InvalidCredentialsException("Invalid email or password."));

        String accessToken = jwtService.createAccessToken(user.getId(), user.getEmail());
        return new LoginResponse(accessToken, "Bearer", jwtProperties.expirationMinutes(), toMeResponse(user));
    }

    @Transactional(readOnly = true)
    public MeResponse getCurrentUser(AuthenticatedUser authenticatedUser) {
        UserAccount user = userAccountRepository.findById(authenticatedUser.userId())
            .orElseThrow(() -> new InvalidCredentialsException("Authenticated user no longer exists."));

        return toMeResponse(user);
    }

    private MeResponse toMeResponse(UserAccount user) {
        var memberships = membershipRepository.findByUserIdAndStatus(user.getId(), "ACTIVE")
            .stream()
            .map(this::toMembershipResponse)
            .toList();

        return new MeResponse(
            user.getId(),
            user.getEmail(),
            user.getFirstName(),
            user.getLastName(),
            user.getPhone(),
            user.getStatus(),
            memberships
        );
    }

    private MeResponse.MembershipResponse toMembershipResponse(SchoolMembership membership) {
        var permissions = membership.getRole().getPermissions()
            .stream()
            .map(permission -> permission.getKey())
            .sorted(Comparator.naturalOrder())
            .toList();

        return new MeResponse.MembershipResponse(
            membership.getId(),
            membership.getSchool().getId(),
            membership.getSchool().getName(),
            membership.getStatus(),
            membership.getRole().getKey(),
            membership.getRole().getName(),
            membership.getRole().getScope(),
            permissions
        );
    }
}
