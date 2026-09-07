package com.autoskola365.backend.lesson;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.NOT_FOUND)
public class LessonNotFoundException extends RuntimeException {

    public LessonNotFoundException(String message) {
        super(message);
    }
}
