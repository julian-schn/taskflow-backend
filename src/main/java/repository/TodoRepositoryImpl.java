package repository;

import model.Todo;
import repository.TodoRepository;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Repository;
import software.amazon.awssdk.enhanced.dynamodb.*;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;

import javax.annotation.PostConstruct;
import java.util.*;

@Repository
@ConditionalOnProperty(name = "dynamodb.enabled", havingValue = "true", matchIfMissing = true)
public class TodoRepositoryImpl implements TodoRepository {

    private final DynamoDbEnhancedClient enhancedClient;
    private final DynamoDbTable<Todo> todoTable;

    public TodoRepositoryImpl(DynamoDbClient dynamoDbClient) {
        this.enhancedClient = DynamoDbEnhancedClient.builder()
                .dynamoDbClient(dynamoDbClient)
                .build();

        this.todoTable = enhancedClient.table("todos", TableSchema.fromBean(Todo.class));
    }

    @PostConstruct
    private void createTableIfNotExists() {
        // Skip for now; handled by docker init
    }

    @Override
    public void save(Todo todo) {
        todoTable.putItem(todo);
    }

    @Override
    public Optional<Todo> findById(String id) {
        return Optional.ofNullable(todoTable.getItem(r -> r.key(k -> k.partitionValue(id))));
    }

    @Override
    public List<Todo> findAll() {
        List<Todo> todos = new ArrayList<>();
        todoTable.scan().items().forEach(todos::add);
        return todos;
    }

    @Override
    public void deleteById(String id) {
        todoTable.deleteItem(r -> r.key(k -> k.partitionValue(id)));
    }
}