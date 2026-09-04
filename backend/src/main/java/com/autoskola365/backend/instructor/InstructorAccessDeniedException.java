package com.autoskola365.backend.instructor;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.FORBIDDEN)
public class InstructorAccessDeniedException extends RuntimeException {

    public InstructorAccessDeniedException(String message) {
        super(message);
    }
}
