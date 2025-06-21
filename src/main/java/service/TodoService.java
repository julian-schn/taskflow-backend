package service;

import model.Todo;
import model.TodoRequest;
import model.TodoResponse;
import repository.TodoRepository;
import org.springframework.stereotype.Service;

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
        return mapToResponse(todo);
    }

    public List<TodoResponse> getAllTodos() {
        return todoRepository.findAll().stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    public TodoResponse getTodoById(String id) {
        return todoRepository.findById(id)
                .map(this::mapToResponse)
                .orElseThrow(() -> new RuntimeException("Todo not found"));
    }

    public void deleteTodo(String id) {
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