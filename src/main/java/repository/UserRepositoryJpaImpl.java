package repository;

import model.User;
import model.UserJpa;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
@ConditionalOnProperty(name = "dynamodb.enabled", havingValue = "false", matchIfMissing = true)
public class UserRepositoryJpaImpl implements UserRepository {

    private final UserJpaRepository userJpaRepository;
    private final PasswordEncoder passwordEncoder;

    public UserRepositoryJpaImpl(UserJpaRepository userJpaRepository, PasswordEncoder passwordEncoder) {
        this.userJpaRepository = userJpaRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void save(User user) {
        UserJpa userJpa = new UserJpa();
        userJpa.setUsername(user.getUsername());
        userJpa.setPassword(user.getPassword());
        userJpa.setEmail(user.getRole());
        userJpaRepository.save(userJpa);
    }

    @Override
    public Optional<User> findById(String id) {
        try {
            Long longId = Long.parseLong(id);
            return userJpaRepository.findById(longId)
                    .map(this::convertToUser);
        } catch (NumberFormatException e) {
            return Optional.empty();
        }
    }

    @Override
    public Optional<User> findByUsername(String username) {
        return userJpaRepository.findByUsername(username)
                .map(this::convertToUser);
    }

    @Override
    public void deleteById(String id) {
        try {
            Long longId = Long.parseLong(id);
            userJpaRepository.deleteById(longId);
        } catch (NumberFormatException e) {
            // Ignore invalid ID format
        }
    }

    private User convertToUser(UserJpa userJpa) {
        User user = new User();
        user.setId(userJpa.getId().toString());
        user.setUsername(userJpa.getUsername());
        user.setPassword(userJpa.getPassword());
        user.setRole(userJpa.getEmail());
        return user;
    }
} 