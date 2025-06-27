package service;

import com.taskflow.taskflowbackend.auth.JwtService;
import model.User;
import repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

public class AuthServiceTest {

    private UserRepository userRepository;
    private JwtService jwtService;
    private AuthService authService;

    @BeforeEach
    void setUp() {
        userRepository = mock(UserRepository.class);
        jwtService = mock(JwtService.class);
        authService = new AuthService(userRepository, jwtService);
    }

    @Test
    void testLoginReturnsToken() {
        String username = "testuser";
        String password = "password";
        User user = new User();
        user.setUsername(username);
        user.setPassword(new BCryptPasswordEncoder().encode(password));

        when(userRepository.findByUsername(username)).thenReturn(Optional.of(user));
        when(jwtService.generateToken(username)).thenReturn("fake-jwt");

        String token = authService.login(username, password);

        assertNotNull(token);
        assertEquals("fake-jwt", token);
    }

    @Test
    void testLoginUserNotFound() {
        String username = "nonexistent";
        String password = "password";
        when(userRepository.findByUsername(username)).thenReturn(Optional.empty());

        RuntimeException thrown = assertThrows(RuntimeException.class, () -> {
            authService.login(username, password);
        });

        assertEquals("User not found", thrown.getMessage());
    }

    @Test
    void testLoginInvalidCredentials() {
        String username = "testuser";
        String password = "wrongPassword";
        User user = new User();
        user.setUsername(username);
        user.setPassword("correctPassword");
        when(userRepository.findByUsername(username)).thenReturn(Optional.of(user));

        RuntimeException thrown = assertThrows(RuntimeException.class, () -> {
            authService.login(username, password);
        });

        assertEquals("Invalid password", thrown.getMessage());
    }
}
