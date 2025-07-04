# taskflow-backend

## quickstart

get the taskflow backend running in 5 minutes!

### prerequisites
- java 17+ 
- maven 3.6+
- docker (optional, for dynamodb)

### setup steps

1. **clone and navigate**
   ```bash
   git clone <your-repo-url>
   cd taskflow-backend
   ```

2. **set up environment variables**
   ```bash
   # option a: use the setup script (recommended)
   ./setup-env.sh
   
   # option b: manual setup
   cp env.example .env
   # edit .env if needed (defaults work for local development)
   ```

3. **install dependencies**
   ```bash
   mvn clean install
   ```

4. **start services (optional)**
   if you want to use dynamodb instead of h2:
   ```bash
   docker-compose up -d
   ```

5. **run the application**
   ```bash
   # for local development (uses h2 database)
   mvn spring-boot:run -Dspring-boot.run.profiles=local
   
   # or if you want to use dynamodb
   mvn spring-boot:run
   ```

your application should now be running at:
- **local**: http://localhost:8081
- **h2 console**: http://localhost:8081/h2-console

---

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

### cors configuration
the application includes a comprehensive cors (cross-origin resource sharing) configuration that supports both development and production environments.

#### development environment
- supports common frontend development ports: 3000 (react), 3001, 8080 (vue.js), 4200 (angular)
- allows both localhost and 127.0.0.1 variants
- configuration is defined in `application.yml`

#### production environment
- configured in `application-prod.yml`
- **important**: update the `cors.allowed-origins` list with your actual production domains
- example:
```yaml
cors:
  allowed-origins:
    - https://yourdomain.com
    - https://www.yourdomain.com
    - https://app.yourdomain.com
```

#### supported features
- **http methods**: get, post, put, delete, patch, options, head
- **headers**: authorization, content-type, accept, origin, and more
- **credentials**: enabled for authentication support
- **preflight caching**: 1 hour cache for options requests
- **exposed headers**: authorization, pagination headers, rate limit headers

#### customizing cors
to modify cors settings, update the configuration in the appropriate `application-*.yml` file:
```yaml
cors:
  allowed-origins:
    - https://your-frontend-domain.com
  allowed-methods:
    - get
    - post
    - put
    - delete
  allowed-headers:
    - authorization
    - content-type
  allow-credentials: true
  max-age: 3600
```

### environment variables and secrets

the application uses environment variables for configuration. create a `.env` file in the project root with the following variables:

#### required environment variables

**jwt configuration:**
- `jwt_secret` - secret key for jwt token signing (required for production)
- `jwt_expiration_ms` - jwt token expiration time in milliseconds (default: 86400000)

**aws configuration:**
- `aws_access_key_id` - aws access key (use 'dummy' for local development)
- `aws_secret_access_key` - aws secret key (use 'dummy' for local development)
- `aws_default_region` - aws region (default: eu-central-1)
- `aws_dynamodb_endpoint` - dynamodb endpoint (default: http://localhost:8000)

**database configuration:**
- `db_url` - database connection url (default: jdbc:h2:mem:testdb)
- `db_username` - database username (default: sa)
- `db_password` - database password (default: empty)

**server configuration:**
- `server_port` - application port (default: 8081 for local, 8080 for production)

**rate limiting:**
- `rate_limit_auth_requests_per_minute` - auth requests per minute (default: 5)
- `rate_limit_refresh_requests_per_minute` - refresh requests per minute (default: 10)

**dynamodb configuration:**
- `dynamodb_enabled` - enable dynamodb (default: false for local, true for production)
- `dynamodb_table_name` - dynamodb table name (default: todos)

**cors configuration:**
- `cors_allowed_origins` - comma-separated list of allowed origins
- `cors_allowed_methods` - comma-separated list of allowed http methods
- `cors_allowed_headers` - comma-separated list of allowed headers
- `cors_exposed_headers` - comma-separated list of exposed headers
- `cors_allow_credentials` - allow credentials (default: true)
- `cors_max_age` - preflight cache time in seconds (default: 3600)

#### setup instructions

1. **copy the example file:**
   ```bash
   cp env.example .env
   ```

2. **edit the `.env` file** with your actual values

3. **for production**, ensure all required variables are set:
   ```bash
   export jwt_secret=your-super-secret-key
   export aws_access_key_id=your-aws-access-key
   export aws_secret_access_key=your-aws-secret-key
   export db_url=your-production-db-url
   ```

4. **for docker compose**, the `.env` file will be automatically loaded

**note:** the `.env` file is ignored by git for security. never commit real secrets to version control.

## implementation roadmap
1. implement basic todo entity and dynamodb table configuration (done 16. june)
    - create todo model class with fields (id, title, description, status, createdat, updatedat)
    - set up dynamodb table configuration in application.yml
    - create repository interface for todo operations

2. set up jwt authentication (done 18. june)
    - add jwt dependencies to pom.xml
    - create user entity and table
    - implement jwt token generation and validation
    - create authentication endpoints (register, login)
    - implement securityconfig for protected endpoints
    - configure cors for frontend communication
    - add token refresh mechanism
    - move jwt secret to environment variables
    - add password validation rules
    - implement rate limiting for auth endpoints

3. implement todo crud operations (done 21. june)
    - create todocontroller with rest endpoints
    - implement todoservice with business logic
    - add request/response dtos
    - add input validation
    - add authorization checks (users can only access their own todos)

4. add basic error handling (done 24. june)
    - create custom exceptions
    - implement global exception handler
    - add proper http status codes
    - add validation error responses
    - add authentication error responses
    - add logging for errors
    - implement error tracking

5. Write unit tests (Done 24. June)
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

