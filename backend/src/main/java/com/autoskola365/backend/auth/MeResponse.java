package com.autoskola365.backend.auth;

import java.util.List;
import java.util.UUID;

public record MeResponse(
    UUID id,
    String email,
    String firstName,
    String lastName,
    String phone,
    String status,
    List<MembershipResponse> memberships
) {

    public record MembershipResponse(
        UUID id,
        UUID schoolId,
        String schoolName,
        String membershipStatus,
        String roleKey,
        String roleName,
        String roleScope,
        List<String> permissions
    ) {
    }
}
