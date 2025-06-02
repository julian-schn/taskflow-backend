# taskflow-backend

## techstack
- java spring boot
- aws dynamodb
- aws lambda
- jwt
- docker
- log4j

## development roadmap/strategy
1. set up project, imports, packages, datbase
2. define tables, classes, objects and mapping
3. add test cases
3. develop logic and handles
4. implement endpoints
5. set up ci/cd pipeline

## debugging/faq

### how to run local dynamodb docker container
1. start container by running ``docker-compose up -d`` from project root
2. stop container by running ``docker-compose down`` from project root

### verify docker dynamodb setup
1. start container as explained above
2. run springboot app(``mvn spring-boot:run``)
3. from different console, use AWS cli pointing to ``localhost:8000`` to create table as follows:
```bash
aws dynamodb create-table \
  --table-name todos \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --endpoint-url http://localhost:8000 \
  --region eu-central-1
```
4. hit endpoints with with API calls (e.g. ``POST ...``)

### how to test the api
1. start local dynamodb by running ``docker-compose up -d`` from project root
2. start springboot app by running ``mvn spring-boot:run`` from project root
3. use curl commands to test endpoints:

#### create todo
```bash
curl -X POST http://localhost:8080/api/todos \
  -H "Content-Type: application/json" \
  -d '{
    "title": "My first todo",
    "description": "This is a test todo"
  }'
```

#### get all todos
```bash
curl http://localhost:8080/api/todos
```

#### get specific todo
```bash
# replace {id} with actual todo id from create response
curl http://localhost:8080/api/todos/{id}
```

### delete todo
```bash
# replace {id} with actual todo id
curl -X DELETE http://localhost:8080/api/todos/{id}
```

#### example response format
```json
{
  "id": "generated-uuid",
  "title": "My first todo",
  "description": "This is a test todo",
  "status": "PENDING",
  "createdAt": "2024-05-31T18:38:21.996Z",
  "updatedAt": "2024-05-31T18:38:21.996Z"
}
```

## implementation roadmap
1. Implement basic Todo entity and DynamoDB table configuration
    - Create Todo model class with fields (id, title, description, status, createdAt, updatedAt)
    - Set up DynamoDB table configuration in application.yml
    - Create repository interface for Todo operations

2. Set up JWT authentication
    - Add JWT dependencies to pom.xml
    - Create User entity and table
    - Implement JWT token generation and validation
    - Create authentication endpoints (register, login)

3. Implement Todo CRUD operations
    - Create TodoController with REST endpoints
    - Implement TodoService with business logic
    - Add request/response DTOs
    - Add input validation

4. Add basic error handling
    - Create custom exceptions
    - Implement global exception handler
    - Add proper HTTP status codes

5. Write unit tests
    - Test TodoService
    - Test TodoController
    - Test repository layer
    - Add integration tests

6. Set up AWS Lambda configuration
    - Configure Lambda handler
    - Add Lambda deployment configuration
    - Test Lambda function locally

