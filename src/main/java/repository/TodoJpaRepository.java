package repository;

import model.TodoJpa;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TodoJpaRepository extends JpaRepository<TodoJpa, Long> {
    List<TodoJpa> findByUserId(String userId);
} 