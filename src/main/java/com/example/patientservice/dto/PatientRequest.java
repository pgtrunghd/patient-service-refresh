package com.example.patientservice.dto;

import jakarta.validation.constraints.NotBlank;

public record PatientRequest(
        @NotBlank(message = "fullName must not be blank") String fullName,
        String address,
        String medicalHistory) {
}
