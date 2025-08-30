package repository;

import model.User;
import repository.UserRepository;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Repository;
import software.amazon.awssdk.enhanced.dynamodb.*;
import software.amazon.awssdk.enhanced.dynamodb.model.CreateTableEnhancedRequest;
import software.amazon.awssdk.enhanced.dynamodb.model.GlobalSecondaryIndex;
import software.amazon.awssdk.enhanced.dynamodb.model.KeysAndAttributes;
import software.amazon.awssdk.enhanced.dynamodb.model.ProvisionedThroughput;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.services.dynamodb.model.AttributeDefinition;
import software.amazon.awssdk.services.dynamodb.model.CreateTableRequest;
import software.amazon.awssdk.services.dynamodb.model.DescribeTableRequest;
import software.amazon.awssdk.services.dynamodb.model.GlobalSecondaryIndexUpdate;
import software.amazon.awssdk.services.dynamodb.model.KeySchemaElement;
import software.amazon.awssdk.services.dynamodb.model.KeyType;
import software.amazon.awssdk.services.dynamodb.model.ProvisionedThroughputDescription;
import software.amazon.awssdk.services.dynamodb.model.ProvisionedThroughputExceededException;
import software.amazon.awssdk.services.dynamodb.model.Projection;
import software.amazon.awssdk.services.dynamodb.model.ProjectionType;
import software.amazon.awssdk.services.dynamodb.model.ResourceInUseException;
import software.amazon.awssdk.services.dynamodb.model.ResourceNotFoundException;
import software.amazon.awssdk.services.dynamodb.model.ScalarAttributeType;
import software.amazon.awssdk.services.dynamodb.model.UpdateTableRequest;
import software.amazon.awssdk.services.dynamodb.waiters.DynamoDbWaiter;

import java.util.Optional;

@Repository
@ConditionalOnProperty(name = "dynamodb.enabled", havingValue = "true", matchIfMissing = true)
public class UserRepositoryImpl implements UserRepository {

    private final DynamoDbTable<User> userTable;
    private final DynamoDbClient dynamoDbClient;

    public UserRepositoryImpl(DynamoDbClient dynamoDbClient) {
        this.dynamoDbClient = dynamoDbClient;
        DynamoDbEnhancedClient enhancedClient = DynamoDbEnhancedClient.builder()
                .dynamoDbClient(dynamoDbClient)
                .build();

        this.userTable = enhancedClient.table("users", TableSchema.fromBean(User.class));
    }

    @PostConstruct
    private void createTableAndIndexesIfNotExist() {
        final String tableName = "users";
        final String gsiName = "username-index";

        boolean tableExists = true;
        try {
            dynamoDbClient.describeTable(DescribeTableRequest.builder().tableName(tableName).build());
        } catch (ResourceNotFoundException rnfe) {
            tableExists = false;
        }

        if (!tableExists) {
            userTable.createTable(CreateTableEnhancedRequest.builder()
                    .provisionedThroughput(ProvisionedThroughput.builder()
                            .readCapacityUnits(5L)
                            .writeCapacityUnits(5L)
                            .build())
                    .globalSecondaryIndices(GlobalSecondaryIndex.builder()
                            .indexName(gsiName)
                            .projection(p -> p.projectionType(ProjectionType.ALL))
                            .provisionedThroughput(ProvisionedThroughput.builder()
                                    .readCapacityUnits(5L)
                                    .writeCapacityUnits(5L)
                                    .build())
                            .build())
                    .build());

            try (DynamoDbWaiter waiter = dynamoDbClient.waiter()) {
                waiter.waitUntilTableExists(b -> b.tableName(tableName));
            }
        } else {
            // Ensure GSI exists (idempotent: add if missing)
            var desc = dynamoDbClient.describeTable(DescribeTableRequest.builder().tableName(tableName).build());
            boolean hasIndex = desc.table().globalSecondaryIndexes() != null && desc.table().globalSecondaryIndexes().stream()
                    .anyMatch(i -> gsiName.equals(i.indexName()));
            if (!hasIndex) {
                dynamoDbClient.updateTable(UpdateTableRequest.builder()
                        .tableName(tableName)
                        .attributeDefinitions(AttributeDefinition.builder()
                                .attributeName("username")
                                .attributeType(ScalarAttributeType.S)
                                .build())
                        .globalSecondaryIndexUpdates(GlobalSecondaryIndexUpdate.builder()
                                .create(b -> b.indexName(gsiName)
                                        .keySchema(KeySchemaElement.builder()
                                                .attributeName("username")
                                                .keyType(KeyType.HASH)
                                                .build())
                                        .projection(Projection.builder().projectionType(ProjectionType.ALL).build())
                                        .provisionedThroughput(software.amazon.awssdk.services.dynamodb.model.ProvisionedThroughput.builder()
                                                .readCapacityUnits(5L)
                                                .writeCapacityUnits(5L)
                                                .build()))
                                .build())
                        .build());

                try (DynamoDbWaiter waiter = dynamoDbClient.waiter()) {
                    waiter.waitUntilTableExists(b -> b.tableName(tableName));
                }
            }
        }
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
        // Query the GSI for efficient username lookups
        return userTable.index("username-index")
                .query(r -> r.queryConditional(QueryConditional.keyEqualTo(k -> k.partitionValue(username))))
                .items()
                .stream()
                .findFirst();
    }

    @Override
    public void deleteById(String id) {
        userTable.deleteItem(r -> r.key(k -> k.partitionValue(id)));
    }
}