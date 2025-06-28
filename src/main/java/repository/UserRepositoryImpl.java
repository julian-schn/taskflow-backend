package repository;

import model.User;
import repository.UserRepository;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Repository;
import software.amazon.awssdk.enhanced.dynamodb.*;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;

import java.util.Optional;

@Repository
@ConditionalOnProperty(name = "dynamodb.enabled", havingValue = "true", matchIfMissing = false)
public class UserRepositoryImpl implements UserRepository {

    private final DynamoDbTable<User> userTable;

    public UserRepositoryImpl(DynamoDbClient dynamoDbClient) {
        DynamoDbEnhancedClient enhancedClient = DynamoDbEnhancedClient.builder()
                .dynamoDbClient(dynamoDbClient)
                .build();

        this.userTable = enhancedClient.table("users", TableSchema.fromBean(User.class));
    }

    @Override
    public void save(User user) {
        userTable.putItem(user);
    }

    @Override
    public Optional<User> findById(String id) {
        return Optional.ofNullable(userTable.getItem(r -> r.key(k -> k.partitionValue(id))));
    }

    @Override
    public Optional<User> findByUsername(String username) {
        // DynamoDB does not support querying non-key attributes without an index.
        return userTable.scan()
                .items()
                .stream()
                .filter(u -> u.getUsername().equals(username))
                .findFirst();
    }

    @Override
    public void deleteById(String id) {
        userTable.deleteItem(r -> r.key(k -> k.partitionValue(id)));
    }
}