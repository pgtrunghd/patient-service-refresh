package com.example.patientservice.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.context.config.annotation.RefreshScope;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RefreshScope
public class WelcomeController {
    @Value("${app.welcome}")
    private String welcome;

    @GetMapping(value = "/welcome", produces = "text/plain;charset=UTF-8")
    public String welcome() {
        return welcome;
    }
}
