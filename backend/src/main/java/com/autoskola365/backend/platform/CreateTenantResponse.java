package com.autoskola365.backend.platform;

import java.util.UUID;

public record CreateTenantResponse(
    UUID schoolId,
    UUID branchId,
    UUID ownerUserId,
    UUID membershipId
) {
}
