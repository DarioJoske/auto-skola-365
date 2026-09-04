package com.autoskola365.backend.candidate;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.FORBIDDEN)
public class CandidateAccessDeniedException extends RuntimeException {

    public CandidateAccessDeniedException(String message) {
        super(message);
    }
}
