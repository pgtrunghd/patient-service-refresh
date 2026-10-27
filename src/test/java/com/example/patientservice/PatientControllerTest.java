package com.example.patientservice;

import com.example.patientservice.controller.PatientController;
import com.example.patientservice.dto.PatientRequest;
import com.example.patientservice.entity.Patient;
import com.example.patientservice.service.PatientService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = PatientController.class, properties = {
        "spring.cloud.config.enabled=false", "spring.config.import="
})
class PatientControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private PatientService patientService;

    @Test
    void createPatientReturns201() throws Exception {
        Patient saved = new Patient();
        saved.setId(1L);
        saved.setFullName("Nguyen Van A");
        saved.setAddress("Ha Noi");
        saved.setMedicalHistory("Di ung penicillin");
        when(patientService.create(any(PatientRequest.class))).thenReturn(saved);

        mockMvc.perform(post("/api/v1/patients")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"fullName":"Nguyen Van A","address":"Ha Noi","medicalHistory":"Di ung penicillin"}
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(1))
                .andExpect(jsonPath("$.fullName").value("Nguyen Van A"));
    }

    @Test
    void createPatientWithoutNameReturns400() throws Exception {
        mockMvc.perform(post("/api/v1/patients")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"address\":\"Ha Noi\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void getPatientByIdReturns404WhenMissing() throws Exception {
        when(patientService.findById(99L)).thenReturn(java.util.Optional.empty());

        mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get("/api/v1/patients/99"))
                .andExpect(status().isNotFound());
    }
}
