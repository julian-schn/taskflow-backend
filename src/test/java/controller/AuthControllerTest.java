package controller;

import auth.AuthRequest;
import auth.AuthResponse;
import controller.AuthController;
import service.AuthService;
import com.taskflow.taskflowbackend.auth.JwtService;
import service.RateLimiterService;
import io.github.bucket4j.Bucket;
import jakarta.servlet.http.HttpServletRequest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.ResponseEntity;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

public class AuthControllerTest {

    private AuthService authService;
    private JwtService jwtService;
    private RateLimiterService rateLimiterService;
    private AuthController authController;
    private HttpServletRequest httpServletRequest;
    private Bucket bucket;

    @BeforeEach
    void setUp() {
        authService = mock(AuthService.class);
        jwtService = mock(JwtService.class);
        rateLimiterService = mock(RateLimiterService.class);
        httpServletRequest = mock(HttpServletRequest.class);
        bucket = mock(Bucket.class);
        authController = new AuthController(authService, jwtService, rateLimiterService);
        when(httpServletRequest.getRemoteAddr()).thenReturn("127.0.0.1");
        when(rateLimiterService.resolveBucket(anyString())).thenReturn(bucket);
        when(bucket.tryConsume(1)).thenReturn(true);
    }

    @Test
    void testRegister() {
        AuthRequest request = new AuthRequest();
        request.setUsername("testuser");
        request.setPassword("password");

        when(authService.register("testuser", "password")).thenReturn("fake-jwt");

        ResponseEntity<AuthResponse> response = authController.register(request, httpServletRequest);

        assertEquals(200, response.getStatusCodeValue());
        assertNotNull(response.getBody());
        assertEquals("fake-jwt", response.getBody().getToken());

        verify(authService, times(1)).register("testuser", "password");
    }

    @Test
    void testLogin() {
        AuthRequest request = new AuthRequest();
        request.setUsername("testuser");
        request.setPassword("password");

        when(authService.login("testuser", "password")).thenReturn("fake-jwt");

        ResponseEntity<AuthResponse> response = authController.login(request, httpServletRequest);

        assertEquals(200, response.getStatusCodeValue());
        assertNotNull(response.getBody());
        assertEquals("fake-jwt", response.getBody().getToken());

        verify(authService, times(1)).login("testuser", "password");
    }
}