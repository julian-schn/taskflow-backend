# taskflow-backend

## techstack
- java spring boot
- aws dynamodb
- aws lambda
- jwt
- docker
- log4j

## debugging/faq

### how to run local dynamodb docker container
1. start container by running ``docker-compose up -d`` from project root
2. stop container by running ``docker-compose down`` from project root
3. check running docker containers with ``docker container ls``

### verify docker dynamodb setup
1. start container as explained above
2. run springboot app(``mvn spring-boot:run``)
3. from different console, use AWS cli pointing to ``localhost:8000`` to create table as follows (this command is normally run when running ``docker compose``):
```bash
aws dynamodb create-table \
  --table-name todos \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --endpoint-url http://localhost:8000 \
  --region eu-central-1
```
4. check with ``aws dynamodb list-tables --endpoint-url http://localhost:8000 --region eu-central-1`` (requires aws cli) if tables exist, should return "todos"
5. hit endpoints with with API calls (e.g. ``POST ...``)

#### configuring aws cli
- you need to run ``aws configure`` first after installing the cli, this prompts you to inputs some calues, these are as follows:
```bash
export AWS_ACCESS_KEY_ID=dummy
export AWS_SECRET_ACCESS_KEY=dummy
export AWS_DEFAULT_REGION=eu-central-1
export AWS_DEFAULT_OUTPUT=json
```

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

### secrets and environment variables
- secret is stored and injected as noted in ``application.yml``
- can be injected as environment variable at runtime
```bash
export JWT_SECRET=mysupersecretkey
mvn spring-boot:run
```
- or when running as docker container ``docker run -e JWT_SECRET=mysupersecretkey your-image``

## implementation roadmap
1. Implement basic Todo entity and DynamoDB table configuration (Done 16. June)
    - Create Todo model class with fields (id, title, description, status, createdAt, updatedAt)
    - Set up DynamoDB table configuration in application.yml
    - Create repository interface for Todo operations

2. Set up JWT authentication
    - Add JWT dependencies to pom.xml
    - Create User entity and table
    - Implement JWT token generation and validation
    - Create authentication endpoints (register, login)
    - Implement SecurityConfig for protected endpoints
    - Configure CORS for frontend communication
    - Add token refresh mechanism
    - Move JWT secret to environment variables
    - Add password validation rules
    - Implement rate limiting for auth endpoints

3. Implement Todo CRUD operations
    - Create TodoController with REST endpoints
    - Implement TodoService with business logic
    - Add request/response DTOs
    - Add input validation
    - Add authorization checks (users can only access their own todos)

4. Add basic error handling
    - Create custom exceptions
    - Implement global exception handler
    - Add proper HTTP status codes
    - Add validation error responses
    - Add authentication error responses
    - Add logging for errors
    - Implement error tracking

5. Write unit tests
    - Test TodoService
    - Test TodoController
    - Test repository layer
    - Add integration tests
    - Test authentication flow
    - Test authorization rules
    - Test error handling
    - Add security tests

6. Set up AWS Lambda configuration
    - Configure Lambda handler
    - Add Lambda deployment configuration
    - Test Lambda function locally
    - Set up CI/CD pipeline
    - Configure AWS Secrets Manager for sensitive data
    - Set up AWS CloudWatch for monitoring

7. Frontend Integration
    - Create React authentication pages
    - Implement token storage and management
    - Add protected route components
    - Implement token refresh logic
    - Add error handling and user feedback
    - Add loading states
    - Implement remember me functionality
    - Add password reset flow

