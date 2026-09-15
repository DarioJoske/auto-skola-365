package com.autoskola365.backend.lesson;

import jakarta.validation.constraints.Size;

public record CompleteLessonRequest(
    @Size(max = 2000, message = "Bilješka može sadržavati najviše 2000 znakova.") String note
) {}
