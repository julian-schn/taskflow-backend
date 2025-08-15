package repository;

import model.Todo;
import model.TodoJpa;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
@ConditionalOnProperty(name = "dynamodb.enabled", havingValue = "false", matchIfMissing = true)
public class TodoRepositoryJpaImpl implements TodoRepository {

    private final TodoJpaRepository todoJpaRepository;

    public TodoRepositoryJpaImpl(TodoJpaRepository todoJpaRepository) {
        this.todoJpaRepository = todoJpaRepository;
    }

    @Override
    public void save(Todo todo) {
        // Unterscheide Insert vs. Update anhand der (String-)ID
        TodoJpa entity;

        Long existingId = parseId(todo.getId());
        if (existingId != null) {
            // UPDATE-PFAD: Bestehenden Datensatz laden
            Optional<TodoJpa> existingOpt = todoJpaRepository.findById(existingId);
            if (existingOpt.isPresent()) {
                entity = existingOpt.get();
                // Nur veränderliche Felder aktualisieren
                entity.setTitle(todo.getTitle());
                entity.setDescription(todo.getDescription());
                entity.setCompleted("COMPLETED".equalsIgnoreCase(todo.getStatus()));
                // userId i. d. R. unverändert; falls gesetzt, übernehmen
                if (todo.getUserId() != null) {
                    entity.setUserId(todo.getUserId());
                }
                // createdAt beibehalten, updatedAt neu setzen
                entity.setUpdatedAt(LocalDateTime.now());
            } else {
                // ID vorhanden, aber nicht gefunden -> wie Insert behandeln
                entity = buildNewEntityFrom(todo);
            }
        } else {
            // INSERT-PFAD
            entity = buildNewEntityFrom(todo);
        }

        TodoJpa saved = todoJpaRepository.save(entity);

        // Model-ID (String) mit der DB-ID synchronisieren (wichtig für Aufrufer wie toggle)
        todo.setId(saved.getId().toString());
    }

    @Override
    public Optional<Todo> findById(String id) {
        Long longId = parseId(id);
        if (longId == null) return Optional.empty();

        return todoJpaRepository.findById(longId).map(this::convertToTodo);
    }

    @Override
    public List<Todo> findAll() {
        return todoJpaRepository.findAll().stream()
                .map(this::convertToTodo)
                .toList();
    }

    @Override
    public void deleteById(String id) {
        Long longId = parseId(id);
        if (longId != null) {
            todoJpaRepository.deleteById(longId);
        }
    }

    // ---------- Helper ----------

    private Long parseId(String id) {
        if (id == null || id.isBlank()) return null;
        try {
            return Long.parseLong(id);
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private TodoJpa buildNewEntityFrom(Todo todo) {
        TodoJpa entity = new TodoJpa();
        entity.setTitle(todo.getTitle());
        entity.setDescription(todo.getDescription());
        entity.setCompleted("COMPLETED".equalsIgnoreCase(todo.getStatus()));
        entity.setUserId(todo.getUserId());
        // Timestamps: bei Insert beides auf jetzt
        LocalDateTime now = LocalDateTime.now();
        entity.setCreatedAt(now);
        entity.setUpdatedAt(now);
        return entity;
    }

    private Todo convertToTodo(TodoJpa todoJpa) {
        Todo todo = new Todo();
        todo.setId(todoJpa.getId().toString());
        todo.setTitle(todoJpa.getTitle());
        todo.setDescription(todoJpa.getDescription());
        todo.setStatus(todoJpa.isCompleted() ? "COMPLETED" : "PENDING");
        todo.setUserId(todoJpa.getUserId());
        // LocalDateTime -> Instant (System-Zone)
        todo.setCreatedAt(todoJpa.getCreatedAt().atZone(java.time.ZoneId.systemDefault()).toInstant());
        todo.setUpdatedAt(todoJpa.getUpdatedAt().atZone(java.time.ZoneId.systemDefault()).toInstant());
        return todo;
    }
}
