package com.autoskola365.backend.platform;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record CreateTenantRequest(
    @NotBlank String schoolName,
    String schoolOib,
    @Email String schoolEmail,
    String schoolPhone,
    @Valid @NotNull BranchPayload branch,
    @Valid @NotNull OwnerPayload owner
) {

    public record BranchPayload(
        @NotBlank String name,
        String address,
        String city,
        String phone
    ) {
    }

    public record OwnerPayload(
        @NotBlank String firstName,
        @NotBlank String lastName,
        @NotBlank @Email String email,
        String phone,
        @NotBlank @Size(min = 8) String password
    ) {
    }
}
