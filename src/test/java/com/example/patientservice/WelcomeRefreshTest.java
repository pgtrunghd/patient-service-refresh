package com.example.patientservice;

import com.example.patientservice.controller.WelcomeController;
import java.util.HashMap;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration;
import org.springframework.boot.autoconfigure.orm.jpa.HibernateJpaAutoConfiguration;
import org.springframework.boot.autoconfigure.data.jpa.JpaRepositoriesAutoConfiguration;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Import;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(classes = WelcomeRefreshTest.TestApplication.class,
        webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT,
        properties = {"spring.cloud.config.enabled=false", "spring.config.import=",
                "management.endpoints.web.exposure.include=refresh",
                "app.welcome=Chào mừng tới BV RikkeiAcademy"})
class WelcomeRefreshTest {
    @Configuration(proxyBeanMethods = false)
    @EnableAutoConfiguration(exclude = {DataSourceAutoConfiguration.class,
            HibernateJpaAutoConfiguration.class, JpaRepositoriesAutoConfiguration.class})
    @Import(WelcomeController.class)
    static class TestApplication { }

    @Autowired
    TestRestTemplate rest;

    @Autowired
    ConfigurableEnvironment environment;

    @Test
    void keepsCachedWelcomeUntilActuatorRefreshThenReturnsNewValue() {
        Map<String, Object> properties = new HashMap<>();
        properties.put("app.welcome", "Chào mừng tới BV RikkeiAcademy");
        environment.getPropertySources().addFirst(new MapPropertySource("welcome-test", properties));
        assertThat(rest.getForObject("/welcome", String.class))
                .isEqualTo("Chào mừng tới BV RikkeiAcademy");

        properties.put("app.welcome", "Chào mừng tới BV RikkeiEducation");
        assertThat(rest.getForObject("/welcome", String.class))
                .isEqualTo("Chào mừng tới BV RikkeiAcademy");

        var refresh = rest.postForEntity("/actuator/refresh", null, String[].class);
        assertThat(refresh.getStatusCode().value()).isEqualTo(200);
        assertThat(rest.getForObject("/welcome", String.class))
                .isEqualTo("Chào mừng tới BV RikkeiEducation");
    }
}
