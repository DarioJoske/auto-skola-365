package com.autoskola365.backend.lesson;
import java.time.Instant;
import jakarta.validation.constraints.NotNull;
public record ProposalRequest(@NotNull Instant startAt) {}
