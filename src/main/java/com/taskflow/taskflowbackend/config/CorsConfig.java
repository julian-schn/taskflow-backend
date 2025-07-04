package com.taskflow.taskflowbackend.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.List;

@Configuration
public class CorsConfig {

    @Value("${cors.allowed-origins}")
    private String allowedOriginsString;

    @Value("${cors.allowed-methods}")
    private String allowedMethodsString;

    @Value("${cors.allowed-headers}")
    private String allowedHeadersString;

    @Value("${cors.exposed-headers}")
    private String exposedHeadersString;

    @Value("${cors.allow-credentials}")
    private boolean allowCredentials;

    @Value("${cors.max-age}")
    private long maxAge;

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        
        // Parse comma-separated strings into lists
        List<String> allowedOrigins = Arrays.asList(allowedOriginsString.split(","));
        List<String> allowedMethods = Arrays.asList(allowedMethodsString.split(","));
        List<String> allowedHeaders = Arrays.asList(allowedHeadersString.split(","));
        List<String> exposedHeaders = Arrays.asList(exposedHeadersString.split(","));
        
        // Set CORS configuration from properties
        configuration.setAllowedOrigins(allowedOrigins);
        configuration.setAllowedMethods(allowedMethods);
        configuration.setAllowedHeaders(allowedHeaders);
        configuration.setExposedHeaders(exposedHeaders);
        configuration.setAllowCredentials(allowCredentials);
        configuration.setMaxAge(maxAge);
        
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
} 