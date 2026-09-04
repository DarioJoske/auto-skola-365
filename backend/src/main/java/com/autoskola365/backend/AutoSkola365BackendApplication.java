package com.autoskola365.backend;

import com.autoskola365.backend.auth.JwtProperties;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
@EnableConfigurationProperties(JwtProperties.class)
public class AutoSkola365BackendApplication {

    public static void main(String[] args) {
        SpringApplication.run(AutoSkola365BackendApplication.class, args);
    }
}
