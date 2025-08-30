package repository;

import model.Todo;
import repository.TodoRepository;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Repository;
import software.amazon.awssdk.enhanced.dynamodb.*;
import software.amazon.awssdk.enhanced.dynamodb.model.CreateTableEnhancedRequest;
import software.amazon.awssdk.enhanced.dynamodb.model.ProvisionedThroughput;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.services.dynamodb.model.DescribeTableRequest;
import software.amazon.awssdk.services.dynamodb.model.ResourceNotFoundException;
import software.amazon.awssdk.services.dynamodb.waiters.DynamoDbWaiter;

import javax.annotation.PostConstruct;
import java.util.*;

@Repository
@ConditionalOnProperty(name = "dynamodb.enabled", havingValue = "true", matchIfMissing = true)
public class TodoRepositoryImpl implements TodoRepository {

    private final DynamoDbEnhancedClient enhancedClient;
    private final DynamoDbTable<Todo> todoTable;
    private final DynamoDbClient dynamoDbClient;

    public TodoRepositoryImpl(DynamoDbClient dynamoDbClient) {
        this.dynamoDbClient = dynamoDbClient;
        this.enhancedClient = DynamoDbEnhancedClient.builder()
                .dynamoDbClient(dynamoDbClient)
                .build();

        this.todoTable = enhancedClient.table("todos", TableSchema.fromBean(Todo.class));
    }

    @PostConstruct
    private void createTableIfNotExists() {
        final String tableName = "todos";
        try {
            dynamoDbClient.describeTable(DescribeTableRequest.builder().tableName(tableName).build());
        } catch (ResourceNotFoundException rnfe) {
            // Create table with minimal provisioned throughput; for on-demand, adjust as needed
            todoTable.createTable(CreateTableEnhancedRequest.builder()
                    .provisionedThroughput(ProvisionedThroughput.builder()
                            .readCapacityUnits(5L)
                            .writeCapacityUnits(5L)
                            .build())
                    .build());

            try (DynamoDbWaiter waiter = dynamoDbClient.waiter()) {
                waiter.waitUntilTableExists(b -> b.tableName(tableName));
            }
        }
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