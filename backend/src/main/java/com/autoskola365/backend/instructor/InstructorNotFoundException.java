package com.autoskola365.backend.instructor;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.NOT_FOUND)
public class InstructorNotFoundException extends RuntimeException {

    public InstructorNotFoundException(String message) {
        super(message);
    }
}
