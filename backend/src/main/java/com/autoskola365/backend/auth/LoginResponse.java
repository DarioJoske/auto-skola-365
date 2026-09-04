package com.autoskola365.backend.auth;

public record LoginResponse(
    String accessToken,
    String tokenType,
    long expiresInMinutes,
    MeResponse user
) {
}
