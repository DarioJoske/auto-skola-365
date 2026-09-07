package com.autoskola365.backend.lesson;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.FORBIDDEN)
public class LessonAccessDeniedException extends RuntimeException {

    public LessonAccessDeniedException(String message) {
        super(message);
    }
}
