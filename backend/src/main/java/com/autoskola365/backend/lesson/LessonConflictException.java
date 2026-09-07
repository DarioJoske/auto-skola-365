package com.autoskola365.backend.lesson;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.CONFLICT)
public class LessonConflictException extends RuntimeException {

    public LessonConflictException(String message) {
        super(message);
    }
}
