package model;

import jakarta.validation.constraints.Size;

public class EditTodoRequest {
    @Size(max = 1000, message = "Description must be less than 1000 characters")
    private String description;

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }
} 