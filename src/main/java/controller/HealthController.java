package controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import service.DatabaseHealthService;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/health")
public class HealthController {

    private final DatabaseHealthService databaseHealthService;

    public HealthController(DatabaseHealthService databaseHealthService) {
        this.databaseHealthService = databaseHealthService;
    }

    @GetMapping("/database")
    public ResponseEntity<Map<String, Object>> checkDatabaseHealth() {
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
        Map<String, Object> dbHealth = databaseHealthService.checkDatabaseHealth();
        systemStatus.put("database", dbHealth);
        
        // Add basic system info
        systemStatus.put("application", "taskflow-backend");
        systemStatus.put("timestamp", System.currentTimeMillis());
        systemStatus.put("status", "UP".equals(dbHealth.get("status")) ? "UP" : "DEGRADED");
        
        // Check if database is connected
        boolean dbConnected = databaseHealthService.isDatabaseConnected();
        systemStatus.put("database_connected", dbConnected);
        systemStatus.put("database_status", databaseHealthService.getDatabaseStatus());
        
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