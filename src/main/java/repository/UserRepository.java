package repository;

import model.User;
import java.util.Optional;

public interface UserRepository {
    void save(User user);
    Optional<User> findById(String id);
    Optional<User> findByUsername(String username);
    void deleteById(String id);
}
