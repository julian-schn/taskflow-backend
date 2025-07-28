package repository;

import model.Todo;
import model.TodoJpa;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
@ConditionalOnProperty(name = "dynamodb.enabled", havingValue = "false", matchIfMissing = true)
public class TodoRepositoryJpaImpl implements TodoRepository {

    private final TodoJpaRepository todoJpaRepository;

    public TodoRepositoryJpaImpl(TodoJpaRepository todoJpaRepository) {
        this.todoJpaRepository = todoJpaRepository;
    }

    @Override
    public void save(Todo todo) {
        TodoJpa todoJpa = new TodoJpa();
        todoJpa.setTitle(todo.getTitle());
        todoJpa.setDescription(todo.getDescription());
        todoJpa.setCompleted("COMPLETED".equals(todo.getStatus()));
        todoJpa.setUserId(todo.getUserId());
        todoJpa.setCreatedAt(LocalDateTime.now());
        todoJpa.setUpdatedAt(LocalDateTime.now());
        
        // Save and update the Todo with the generated database ID
        TodoJpa savedTodoJpa = todoJpaRepository.save(todoJpa);
        todo.setId(savedTodoJpa.getId().toString());
    }

    @Override
    public Optional<Todo> findById(String id) {
        try {
            Long longId = Long.parseLong(id);
            return todoJpaRepository.findById(longId)
                    .map(this::convertToTodo);
        } catch (NumberFormatException e) {
            return Optional.empty();
        }
    }

    @Override
    public List<Todo> findAll() {
        return todoJpaRepository.findAll().stream()
                .map(this::convertToTodo)
                .toList();
    }

    @Override
    public void deleteById(String id) {
        try {
            Long longId = Long.parseLong(id);
            todoJpaRepository.deleteById(longId);
        } catch (NumberFormatException e) {
            // Ignore invalid ID format
        }
    }

    private Todo convertToTodo(TodoJpa todoJpa) {
        Todo todo = new Todo();
        todo.setId(todoJpa.getId().toString());
        todo.setTitle(todoJpa.getTitle());
        todo.setDescription(todoJpa.getDescription());
        todo.setStatus(todoJpa.isCompleted() ? "COMPLETED" : "PENDING");
        todo.setUserId(todoJpa.getUserId());
        todo.setCreatedAt(todoJpa.getCreatedAt().atZone(java.time.ZoneId.systemDefault()).toInstant());
        todo.setUpdatedAt(todoJpa.getUpdatedAt().atZone(java.time.ZoneId.systemDefault()).toInstant());
        return todo;
    }
} 