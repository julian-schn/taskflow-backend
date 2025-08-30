package com.taskflow.taskflowbackend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;
 

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
public class TaskflowBackendApplication {

    public static void main(String[] args) {
        SpringApplication.run(TaskflowBackendApplication.class, args);
    }

}
