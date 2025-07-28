package model;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class EditTodoRequest {
    @NotBlank(message = "Title must not be blank")
    @Size(max = 100, message = "Title must be less than 100 characters")
    private String title;

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }
} 