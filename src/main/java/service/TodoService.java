package service;

import model.Todo;
import model.TodoRequest;
import model.TodoResponse;
import repository.TodoRepository;
import org.springframework.stereotype.Service;
import org.springframework.security.core.context.SecurityContextHolder;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class TodoService {

    private final TodoRepository todoRepository;

    public TodoService(TodoRepository todoRepository) {
        this.todoRepository = todoRepository;
    }

    public TodoResponse createTodo(TodoRequest request) {
        Todo todo = new Todo();
        todo.setId(UUID.randomUUID().toString());
        todo.setTitle(request.getTitle());
        todo.setDescription(request.getDescription());
        todo.setStatus("PENDING");
        todo.setCreatedAt(Instant.now());
        todo.setUpdatedAt(Instant.now());
        todo.setUserId(getCurrentUsername()); // Set userId BEFORE saving
        todoRepository.save(todo);
        return mapToResponse(todo);
    }

    private String getCurrentUsername() {
        return SecurityContextHolder.getContext().getAuthentication().getName();
    }

    public List<TodoResponse> getAllTodos() {
        String currentUser = getCurrentUsername();
        return todoRepository.findAll().stream()
                .filter(todo -> currentUser.equals(todo.getUserId()))
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    public TodoResponse getTodoById(String id) {
        Todo todo = todoRepository.findById(id)
                .orElseThrow(() -> new exception.TodoNotFoundException("Todo not found"));

        if (!getCurrentUsername().equals(todo.getUserId())) {
            throw new exception.UnauthorizedAccessException("Unauthorized access");
        }

        return mapToResponse(todo);
    }

    public void deleteTodo(String id) {
        Todo todo = todoRepository.findById(id)
                .orElseThrow(() -> new exception.TodoNotFoundException("Todo not found"));

        if (!getCurrentUsername().equals(todo.getUserId())) {
            throw new exception.UnauthorizedAccessException("Unauthorized access");
        }

        todoRepository.deleteById(id);
    }

    public TodoResponse toggleTodo(String id) {
        Todo todo = todoRepository.findById(id)
                .orElseThrow(() -> new exception.TodoNotFoundException("Todo not found"));

        if (!getCurrentUsername().equals(todo.getUserId())) {
            throw new exception.UnauthorizedAccessException("Unauthorized access");
        }

        // Toggle status between PENDING and COMPLETED
        String newStatus = "PENDING".equals(todo.getStatus()) ? "COMPLETED" : "PENDING";
        todo.setStatus(newStatus);
        todo.setUpdatedAt(Instant.now());

        todoRepository.save(todo);
        return mapToResponse(todo);
    }

    private TodoResponse mapToResponse(Todo todo) {
        TodoResponse res = new TodoResponse();
        res.setId(todo.getId());
        res.setTitle(todo.getTitle());
        res.setDescription(todo.getDescription());
        res.setStatus(todo.getStatus());
        res.setCreatedAt(todo.getCreatedAt());
        res.setUpdatedAt(todo.getUpdatedAt());
        return res;
    }
}