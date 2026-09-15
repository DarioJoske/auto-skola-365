package com.autoskola365.backend.progress;
import java.util.List;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
public record ProgressRequest(@NotNull @Size(min=1,max=10) List<@NotNull @Valid Assessment> assessments) {
    public record Assessment(@NotBlank String skill, @NotBlank String status) {}
}
