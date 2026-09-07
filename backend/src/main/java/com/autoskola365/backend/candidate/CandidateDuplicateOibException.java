package com.autoskola365.backend.candidate;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.CONFLICT)
public class CandidateDuplicateOibException extends RuntimeException {

    public CandidateDuplicateOibException(String message) {
        super(message);
    }
}
