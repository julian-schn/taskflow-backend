package controller;

import auth.AuthRequest;
import auth.AuthResponse;
import io.github.bucket4j.Bucket;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import service.AuthService;
import service.RateLimiterService;
import auth.JwtService;

import jakarta.servlet.http.HttpServletRequest;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;
    private final JwtService jwtService;
    private final RateLimiterService rateLimiterService;

    public AuthController(AuthService authService, JwtService jwtService, RateLimiterService rateLimiterService) {
        this.authService = authService;
        this.jwtService = jwtService;
        this.rateLimiterService = rateLimiterService;
    }

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@RequestBody AuthRequest request, HttpServletRequest httpRequest) {
        String clientIP = getClientIP(httpRequest);
        Bucket bucket = rateLimiterService.resolveBucket(clientIP);
        if (!bucket.tryConsume(1)) {
            return ResponseEntity.status(429).build();
        }

        String token = authService.register(request.getUsername(), request.getPassword());
        return ResponseEntity.ok(new AuthResponse(token));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@RequestBody AuthRequest request, HttpServletRequest httpRequest) {
        String clientIP = getClientIP(httpRequest);
        Bucket bucket = rateLimiterService.resolveBucket(clientIP);
        if (!bucket.tryConsume(1)) {
            return ResponseEntity.status(429).build();
        }

        String token = authService.login(request.getUsername(), request.getPassword());
        return ResponseEntity.ok(new AuthResponse(token));
    }

    @PostMapping("/refresh")
    public ResponseEntity<AuthResponse> refreshToken(@RequestHeader("Authorization") String authHeader, HttpServletRequest httpRequest) {
        String clientIP = getClientIP(httpRequest);
        Bucket bucket = rateLimiterService.resolveRefreshBucket(clientIP);
        if (!bucket.tryConsume(1)) {
            return ResponseEntity.status(429).build();
        }

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            return ResponseEntity.badRequest().build();
        }

        try {
            String token = authHeader.substring(7);
            String newToken = authService.refreshToken(token);
            return ResponseEntity.ok(new AuthResponse(newToken));
        } catch (RuntimeException e) {
            return ResponseEntity.status(403).build();
        }
    }

    private String getClientIP(HttpServletRequest request) {
        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isEmpty() && !"unknown".equalsIgnoreCase(xForwardedFor)) {
            return xForwardedFor.split(",")[0].trim();
        }
        
        String xRealIP = request.getHeader("X-Real-IP");
        if (xRealIP != null && !xRealIP.isEmpty() && !"unknown".equalsIgnoreCase(xRealIP)) {
            return xRealIP;
        }
        
        return request.getRemoteAddr();
    }
}