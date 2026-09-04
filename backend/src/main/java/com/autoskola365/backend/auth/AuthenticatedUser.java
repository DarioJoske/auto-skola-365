package com.autoskola365.backend.auth;

import java.util.UUID;

public record AuthenticatedUser(UUID userId, String email) {
}
