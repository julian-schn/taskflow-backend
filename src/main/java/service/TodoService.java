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
        todoRepository.save(todo);
        todo.setUserId(getCurrentUsername());
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
                .orElseThrow(() -> new RuntimeException("Todo not found"));

        if (!getCurrentUsername().equals(todo.getUserId())) {
            throw new RuntimeException("Unauthorized access");
        }

        return mapToResponse(todo);
    }

    public void deleteTodo(String id) {
        Todo todo = todoRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Todo not found"));

        if (!getCurrentUsername().equals(todo.getUserId())) {
            throw new RuntimeException("Unauthorized access");
        }

        todoRepository.deleteById(id);
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