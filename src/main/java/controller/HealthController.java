package controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import service.DatabaseHealthService;
import java.util.Optional;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/health")
public class HealthController {

    private final DatabaseHealthService databaseHealthService;

    public HealthController(Optional<DatabaseHealthService> databaseHealthService) {
        this.databaseHealthService = databaseHealthService.orElse(null);
    }

    @GetMapping("/database")
    public ResponseEntity<Map<String, Object>> checkDatabaseHealth() {
        if (databaseHealthService == null) {
            Map<String, Object> healthData = new HashMap<>();
            healthData.put("status", "UNKNOWN");
            healthData.put("database", "not-configured");
            return ResponseEntity.ok(healthData);
        }
        Map<String, Object> healthData = databaseHealthService.checkDatabaseHealth();
        
        // Return HTTP 503 Service Unavailable if database is down
        if ("DOWN".equals(healthData.get("status"))) {
            return ResponseEntity.status(503).body(healthData);
        }
        
        return ResponseEntity.ok(healthData);
    }

    @GetMapping("/status")
    public ResponseEntity<Map<String, Object>> getSystemStatus() {
        Map<String, Object> systemStatus = new HashMap<>();
        
        // Check database health
        if (databaseHealthService != null) {
            Map<String, Object> dbHealth = databaseHealthService.checkDatabaseHealth();
            systemStatus.put("database", dbHealth);
            systemStatus.put("status", "UP".equals(dbHealth.get("status")) ? "UP" : "DEGRADED");
            boolean dbConnected = databaseHealthService.isDatabaseConnected();
            systemStatus.put("database_connected", dbConnected);
            systemStatus.put("database_status", databaseHealthService.getDatabaseStatus());
        } else {
            systemStatus.put("database", Map.of(
                    "status", "UNKNOWN",
                    "database", "not-configured"
            ));
            systemStatus.put("status", "UP");
            systemStatus.put("database_connected", false);
            systemStatus.put("database_status", "Database not configured");
        }
        
        // Add basic system info
        systemStatus.put("application", "taskflow-backend");
        systemStatus.put("timestamp", System.currentTimeMillis());
        return ResponseEntity.ok(systemStatus);
    }

    @GetMapping("/ping")
    public ResponseEntity<Map<String, String>> ping() {
        Map<String, String> response = new HashMap<>();
        response.put("status", "UP");
        response.put("message", "Service is running");
        response.put("timestamp", String.valueOf(System.currentTimeMillis()));
        return ResponseEntity.ok(response);
    }
} 