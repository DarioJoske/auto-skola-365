package com.autoskola365.backend.lesson;
import java.time.Instant;
import jakarta.validation.constraints.NotNull;
public record ProposalResponse(@NotNull Instant startAt, @NotNull Boolean accept) {}
