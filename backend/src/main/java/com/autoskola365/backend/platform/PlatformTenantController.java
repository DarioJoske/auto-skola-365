package com.autoskola365.backend.platform;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/platform/tenants")
public class PlatformTenantController {

    private final TenantProvisioningService tenantProvisioningService;

    public PlatformTenantController(TenantProvisioningService tenantProvisioningService) {
        this.tenantProvisioningService = tenantProvisioningService;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public CreateTenantResponse createTenant(@Valid @RequestBody CreateTenantRequest request) {
        return tenantProvisioningService.createTenant(request);
    }
}
