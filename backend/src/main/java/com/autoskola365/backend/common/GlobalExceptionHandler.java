package com.autoskola365.backend.common;

import java.time.Instant;

import org.springframework.core.annotation.AnnotationUtils;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.ErrorResponseException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import com.autoskola365.backend.candidate.CandidateDuplicateOibException;

import jakarta.servlet.http.HttpServletRequest;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final String CANDIDATE_OIB_CONSTRAINT = "ux_candidates_school_oib";

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    ResponseEntity<ApiErrorResponse> handleUnsupportedMethod(
        HttpRequestMethodNotSupportedException exception,
        HttpServletRequest request
    ) {
        return error(HttpStatus.METHOD_NOT_ALLOWED, "METHOD_NOT_ALLOWED",
            "Ova radnja nije dostupna za traženi resurs.", request);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    ResponseEntity<ApiErrorResponse> handleValidation(
        MethodArgumentNotValidException exception,
        HttpServletRequest request
    ) {
        String message = exception.getBindingResult()
            .getFieldErrors()
            .stream()
            .findFirst()
            .map(error -> error.getField() + ": " + error.getDefaultMessage())
            .orElse("Request validation failed.");

        return error(HttpStatus.BAD_REQUEST, "VALIDATION_FAILED", message, request);
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    ResponseEntity<ApiErrorResponse> handleDataIntegrity(
        DataIntegrityViolationException exception,
        HttpServletRequest request
    ) {
        String rootMessage = rootMessage(exception);
        if (rootMessage.contains(CANDIDATE_OIB_CONSTRAINT)) {
            return error(
                HttpStatus.CONFLICT,
                "CANDIDATE_OIB_ALREADY_EXISTS",
                "Kandidat s tim OIB-om vec postoji.",
                request
            );
        }

        return error(
            HttpStatus.CONFLICT,
            "DATA_INTEGRITY_VIOLATION",
            "Zapis vec postoji ili krsi pravila baze.",
            request
        );
    }

    @ExceptionHandler(IllegalArgumentException.class)
    ResponseEntity<ApiErrorResponse> handleIllegalArgument(
        IllegalArgumentException exception,
        HttpServletRequest request
    ) {
        return error(HttpStatus.BAD_REQUEST, "BAD_REQUEST", message(exception), request);
    }

    @ExceptionHandler(CandidateDuplicateOibException.class)
    ResponseEntity<ApiErrorResponse> handleCandidateDuplicateOib(
        CandidateDuplicateOibException exception,
        HttpServletRequest request
    ) {
        return error(
            HttpStatus.CONFLICT,
            "CANDIDATE_OIB_ALREADY_EXISTS",
            message(exception),
            request
        );
    }

    @ExceptionHandler(ErrorResponseException.class)
    ResponseEntity<ApiErrorResponse> handleErrorResponse(
        ErrorResponseException exception,
        HttpServletRequest request
    ) {
        HttpStatus status = HttpStatus.valueOf(exception.getStatusCode().value());
        return error(status, defaultCode(status), message(exception), request);
    }

    @ExceptionHandler(RuntimeException.class)
    ResponseEntity<ApiErrorResponse> handleRuntimeException(
        RuntimeException exception,
        HttpServletRequest request
    ) {
        ResponseStatus responseStatus = AnnotationUtils.findAnnotation(exception.getClass(), ResponseStatus.class);
        if (responseStatus != null) {
            return error(responseStatus.code(), defaultCode(responseStatus.code()), message(exception), request);
        }

        return error(
            HttpStatus.INTERNAL_SERVER_ERROR,
            "INTERNAL_SERVER_ERROR",
            "Dogodila se neocekivana greska.",
            request
        );
    }

    private ResponseEntity<ApiErrorResponse> error(
        HttpStatus status,
        String code,
        String message,
        HttpServletRequest request
    ) {
        return ResponseEntity
            .status(status)
            .body(new ApiErrorResponse(
                Instant.now(),
                status.value(),
                status.getReasonPhrase(),
                code,
                message,
                request.getRequestURI()
            ));
    }

    private String message(RuntimeException exception) {
        String message = exception.getMessage();
        return message == null || message.isBlank() ? "Request failed." : message;
    }

    private String rootMessage(Throwable exception) {
        Throwable current = exception;
        while (current.getCause() != null && current.getCause() != current) {
            current = current.getCause();
        }

        String message = current.getMessage();
        return message == null ? "" : message;
    }

    private String defaultCode(HttpStatus status) {
        return switch (status) {
            case BAD_REQUEST -> "BAD_REQUEST";
            case UNAUTHORIZED -> "UNAUTHORIZED";
            case FORBIDDEN -> "FORBIDDEN";
            case NOT_FOUND -> "NOT_FOUND";
            case CONFLICT -> "CONFLICT";
            default -> status.is5xxServerError() ? "INTERNAL_SERVER_ERROR" : "REQUEST_FAILED";
        };
    }
}
