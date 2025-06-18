package service;

import io.github.bucket4j.Bandwidth;
import io.github.bucket4j.Bucket;
import io.github.bucket4j.Refill;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class RateLimiterService {

    @Value("${rate.limit.auth.requests-per-minute:5}")
    private int authRequestsPerMinute;

    @Value("${rate.limit.auth.refresh-requests-per-minute:10}")
    private int refreshRequestsPerMinute;

    private final Map<String, Bucket> authCache = new ConcurrentHashMap<>();
    private final Map<String, Bucket> refreshCache = new ConcurrentHashMap<>();

    public Bucket resolveBucket(String key) {
        return authCache.computeIfAbsent(key, this::newAuthBucket);
    }

    public Bucket resolveRefreshBucket(String key) {
        return refreshCache.computeIfAbsent(key, this::newRefreshBucket);
    }

    private Bucket newAuthBucket(String key) {
        // Configurable requests per minute for auth endpoints (login/register)
        return Bucket.builder()
                .addLimit(Bandwidth.classic(authRequestsPerMinute, Refill.intervally(authRequestsPerMinute, Duration.ofMinutes(1))))
                .build();
    }

    private Bucket newRefreshBucket(String key) {
        // Configurable requests per minute for refresh endpoint (usually higher limit)
        return Bucket.builder()
                .addLimit(Bandwidth.classic(refreshRequestsPerMinute, Refill.intervally(refreshRequestsPerMinute, Duration.ofMinutes(1))))
                .build();
    }
}