package service;

import auth.JwtService;
import model.User;
import repository.UserRepository;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final BCryptPasswordEncoder bCryptPasswordEncoder = new BCryptPasswordEncoder();
    private final JwtService jwtService;

    public AuthService(UserRepository userRepository, JwtService jwtService) {
        this.userRepository = userRepository;
        this.jwtService = jwtService;
    }

    public String register(String username, String password) {
        // Check if user already exists
        if (userRepository.findByUsername(username).isPresent()) {
            throw new RuntimeException("Username already exists");
        }
        //Check password validity
        if (password.length() < 8 || !password.matches(".*\\d.*") || !password.matches(".*[A-Za-z].*")) {
            throw new IllegalArgumentException("Password must be at least 8 characters long and contain both letters and numbers.");
        }

        // Create new user
        User user = new User();
        user.setId(UUID.randomUUID().toString());
        user.setUsername(username);
        user.setPassword(bCryptPasswordEncoder.encode(password));
        user.setRole("USER");

        // Save user
        userRepository.save(user);

        // Generate token
        return jwtService.generateToken(username);
    }

    public String login(String username, String password) {
        // Find user
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Verify password
        if (!bCryptPasswordEncoder.matches(password, user.getPassword())) {
            throw new RuntimeException("Invalid password");
        }

        // Generate token
        return jwtService.generateToken(username);
    }

    public String refreshToken(String token) {
        // Extract username from token
        String username = jwtService.extractUsername(token);
        
        if (username == null) {
            throw new RuntimeException("Invalid token");
        }

        // Verify token is valid
        if (!jwtService.isTokenValid(token, username)) {
            throw new RuntimeException("Token is invalid or expired");
        }

        // Verify user still exists in database
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Generate new token
        return jwtService.generateToken(username);
    }
}
