package com.autoskola365.backend.lesson;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.BAD_REQUEST)
public class InvalidLessonException extends RuntimeException {

    public InvalidLessonException(String message) {
        super(message);
    }
}
