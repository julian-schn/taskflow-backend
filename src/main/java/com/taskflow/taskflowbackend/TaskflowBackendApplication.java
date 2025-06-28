package com.taskflow.taskflowbackend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

@SpringBootApplication
@ComponentScan(basePackages = {
    "com.taskflow.taskflowbackend",
    "repository",
    "service",
    "controller",
    "auth",
    "config",
    "model",
    "exception",
    "util"
})
@EnableJpaRepositories(basePackages = "repository")
public class TaskflowBackendApplication {

    public static void main(String[] args) {
        SpringApplication.run(TaskflowBackendApplication.class, args);
    }

}
