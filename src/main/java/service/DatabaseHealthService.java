package service;

import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.stereotype.Service;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.ResultSet;
import java.util.HashMap;
import java.util.Map;

@Service
@ConditionalOnBean(javax.sql.DataSource.class)
public class DatabaseHealthService {

    private static final Logger logger = LogManager.getLogger(DatabaseHealthService.class);
    private final DataSource dataSource;

    public DatabaseHealthService(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    public Map<String, Object> checkDatabaseHealth() {
        Map<String, Object> healthData = new HashMap<>();
        try {
            return performDatabaseCheck(healthData);
        } catch (Exception e) {
            logger.error("Database health check failed", e);
            healthData.put("status", "DOWN");
            healthData.put("error", e.getMessage());
            healthData.put("database", "unreachable");
            return healthData;
        }
    }

    private Map<String, Object> performDatabaseCheck(Map<String, Object> healthData) {
        try (Connection connection = dataSource.getConnection()) {
            if (connection.isValid(1)) {
                // Test with a simple query
                try (Statement statement = connection.createStatement();
                     ResultSet resultSet = statement.executeQuery("SELECT 1")) {
                    
                    if (resultSet.next()) {
                        String databaseProductName = connection.getMetaData().getDatabaseProductName();
                        String databaseProductVersion = connection.getMetaData().getDatabaseProductVersion();
                        String url = connection.getMetaData().getURL();
                        
                        logger.info("Database health check successful - {} {}", databaseProductName, databaseProductVersion);
                        
                        healthData.put("status", "UP");
                        healthData.put("database", databaseProductName);
                        healthData.put("version", databaseProductVersion);
                        healthData.put("url", url);
                        healthData.put("connection", "valid");
                        return healthData;
                    }
                }
            }
            
            healthData.put("status", "DOWN");
            healthData.put("database", "connection invalid");
            healthData.put("connection", "failed validation");
            return healthData;
                    
        } catch (SQLException e) {
            logger.error("Database connection failed: {}", e.getMessage());
            healthData.put("status", "DOWN");
            healthData.put("error", e.getMessage());
            healthData.put("database", "connection failed");
            return healthData;
        }
    }

    public boolean isDatabaseConnected() {
        try (Connection connection = dataSource.getConnection()) {
            return connection.isValid(1);
        } catch (SQLException e) {
            logger.warn("Database connectivity check failed: {}", e.getMessage());
            return false;
        }
    }

    public String getDatabaseStatus() {
        try (Connection connection = dataSource.getConnection()) {
            if (connection.isValid(1)) {
                String databaseProductName = connection.getMetaData().getDatabaseProductName();
                String databaseProductVersion = connection.getMetaData().getDatabaseProductVersion();
                return String.format("%s %s - Connected", databaseProductName, databaseProductVersion);
            }
            return "Database connection invalid";
        } catch (SQLException e) {
            return "Database connection failed: " + e.getMessage();
        }
    }
} 