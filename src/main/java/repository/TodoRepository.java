package repository;

import model.Todo;

import java.util.List;
import java.util.Optional;

public interface TodoRepository {
    void save(Todo todo);
    Optional<Todo> findById(String id);
    List<Todo> findAll();
    void deleteById(String id);
}