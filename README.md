# taskflow-backend

## quickstart

everything you need for setting up taskflow to run locally

### prerequisites
- java 17+
- maven 3.6+
- docker (optional, for dynamodb)

### setup steps

1. **clone and navigate** (if not done yet)
   ```bash
   git clone https://gitlab.mi.hdm-stuttgart.de/soft-dev-for-coud/taskflow-backend.git
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

4. **run the application**
   ```bash
   # for local development (uses DynamoDB Local via Docker)
   docker compose up -d && mvn spring-boot:run -Dspring-boot.run.profiles=docker
   ```

your application should now be running at:
- **local**: http://localhost:8081
- **dynamodb local**: http://localhost:8000

---

## techstack
- java spring boot
- aws dynamodb (default persistence)
- aws lambda
- jwt
- docker
- log4j

## debugging/faq

### spring boot profiles

the application supports three different profiles for different environments:

#### local profile (recommended for development)
- **purpose**: local development and testing with DynamoDB Local
- **database**: dynamodb local via docker compose
- **port**: 8081
- **features**:
   - h2 console available at http://localhost:8081/h2-console
   - automatic table creation
   - debug logging enabled
   - circular references allowed for development
- **usage**: `docker compose up -d && mvn spring-boot:run -Dspring-boot.run.profiles=local`

#### docker profile
- **purpose**: local development with dynamodb container
- **database**: dynamodb local via docker compose
- **port**: 8081
- **features**:
   - full aws dynamodb integration
   - automatic table creation via docker compose
   - production-like environment locally
- **usage**: `docker-compose up -d` then `mvn spring-boot:run -Dspring-boot.run.profiles=docker`

#### prod profile
- **purpose**: production deployment
- **database**: aws dynamodb (cloud)
- **port**: 8080
- **features**:
   - production security settings
   - cloud aws services
   - optimized for performance
- **usage**: `mvn spring-boot:run -Dspring-boot.run.profiles=prod`

**recommendation**: use the `local` profile for development and testing. it uses DynamoDB Local via Docker for parity with prod.

### profile decision matrix

| profile | database | port | docker required? | aws required? | use case |
|---------|----------|------|------------------|---------------|----------|
| local | dynamodb local | 8081 | yes | no | quick development |
| docker | dynamodb local | 8081 | yes | no | test with dynamodb |
| prod | aws dynamodb | 8080 | no | yes | production deployment |

### how to run local dynamodb docker container
1. start container by running ``docker-compose up -d`` from project root
2. stop container by running ``docker-compose down`` from project root
3. check running docker containers with ``docker container ls``

**note:** the docker compose setup automatically creates the required tables (todos and users) when starting up, so manual table creation is no longer needed.

### verify docker dynamodb setup
1. start container as explained above
2. run springboot app with docker profile: ``mvn spring-boot:run -Dspring-boot.run.profiles=docker``
3. check with ``aws dynamodb list-tables --endpoint-url http://localhost:8000 --region eu-central-1`` (requires aws cli) if tables exist, should return "todos" and "users"
4. hit endpoints with api calls (e.g. ``POST ...``)

### how to test the api

#### option 1: local profile with dynamodb (recommended)
1. start docker dynamodb: ``docker compose up -d``
2. start springboot app with local profile: ``mvn spring-boot:run -Dspring-boot.run.profiles=local``
3. use curl commands to test endpoints (see examples below)

#### option 2: docker profile with dynamodb
1. start local dynamodb: ``docker-compose up -d``
2. start springboot app with docker profile: ``mvn spring-boot:run -Dspring-boot.run.profiles=docker``
3. use curl commands to test endpoints (see examples below)

#### option 3: prod profile with aws dynamodb
1. configure aws credentials (real values, not dummy)
2. start springboot app with prod profile: ``mvn spring-boot:run -Dspring-boot.run.profiles=prod``
3. use curl commands to test endpoints (port 8080 instead of 8081)

**note:** its recommended to use the local profile approach for development and testing as it's faster and doesn't require docker or aws services.

#### create todo
```bash
# local and docker profiles (port 8081)
curl -X POST http://localhost:8081/api/todos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "title": "my first todo",
    "description": "this is a test todo"
  }'

# prod profile (port 8080)
curl -X POST http://localhost:8080/api/todos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "title": "my first todo",
    "description": "this is a test todo"
  }'
```

#### get all todos
```bash
# local and docker profiles
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" http://localhost:8081/api/todos

# prod profile
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" http://localhost:8080/api/todos
```

#### get specific todo
```bash
# replace {id} with actual todo id from create response
# local and docker profiles
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" http://localhost:8081/api/todos/{id}

# prod profile
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" http://localhost:8080/api/todos/{id}
```

#### delete todo
```bash
# replace {id} with actual todo id
# local and docker profiles
curl -X DELETE -H "Authorization: Bearer YOUR_JWT_TOKEN" http://localhost:8081/api/todos/{id}

# prod profile
curl -X DELETE -H "Authorization: Bearer YOUR_JWT_TOKEN" http://localhost:8080/api/todos/{id}
```

#### authentication endpoints

**register a new user:**
```bash
# local and docker profiles
curl -X POST http://localhost:8081/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "password123"
  }'

# prod profile
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "password123"
  }'
```

**login:**
```bash
# local and docker profiles
curl -X POST http://localhost:8081/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "password123"
  }'

# prod profile
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "password123"
  }'
```

**refresh token:**
```bash
# local and docker profiles
curl -X POST http://localhost:8081/api/auth/refresh \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# prod profile
curl -X POST http://localhost:8080/api/auth/refresh \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**note:** all todo endpoints require authentication. include the jwt token in the authorization header as shown in the examples above.

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

### health endpoints
the application provides comprehensive health check endpoints to monitor database connectivity and system status. these endpoints are publicly accessible and do not require authentication.

#### ping endpoint
basic service availability check to verify the application is running.
```bash
# local and docker profiles
curl http://localhost:8081/api/health/ping

# prod profile
curl http://localhost:8080/api/health/ping
```

**response:**
```json
{
  "status": "UP",
  "message": "Service is running",
  "timestamp": "1753639629182"
}
```

#### database health check
detailed database connectivity status including database type, version, and connection details.
```bash
# local and docker profiles
curl http://localhost:8081/api/health/database

# prod profile
curl http://localhost:8080/api/health/database
```

**response:**
```json
{
  "status": "UP",
  "database": "H2",
  "version": "2.3.232 (2024-08-11)",
  "url": "jdbc:h2:mem:testdb",
  "connection": "valid"
}
```

#### system status
complete system health including database status and application information.
```bash
# local and docker profiles
curl http://localhost:8081/api/health/status

# prod profile
curl http://localhost:8080/api/health/status
```

**response:**
```json
{
  "status": "UP",
  "application": "taskflow-backend",
  "timestamp": 1753639711530,
  "database_connected": true,
  "database_status": "H2 2.3.232 (2024-08-11) - Connected",
  "database": {
    "status": "UP",
    "database": "H2",
    "version": "2.3.232 (2024-08-11)",
    "url": "jdbc:h2:mem:testdb",
    "connection": "valid"
  }
}
```

#### actuator health endpoint
built-in spring boot actuator health check with detailed component status.
```bash
# local and docker profiles
curl http://localhost:8081/actuator/health

# prod profile
curl http://localhost:8080/actuator/health
```

**response:**
```json
{
  "status": "UP",
  "components": {
    "db": {
      "status": "UP",
      "details": {
        "database": "H2",
        "validationQuery": "isValid()"
      }
    },
    "diskSpace": {
      "status": "UP",
      "details": {
        "total": 994662584320,
        "free": 465283837952,
        "threshold": 10485760
      }
    },
    "ping": {
      "status": "UP"
    }
  }
}
```

#### health endpoint usage
- **monitoring**: use these endpoints for application monitoring and alerting
- **load balancers**: configure load balancers to use `/api/health/ping` for health checks
- **debugging**: use `/api/health/database` to troubleshoot database connectivity issues
- **status pages**: integrate `/api/health/status` into status page dashboards

**note:** if the database is down, the `/api/health/database` endpoint will return http 503 service unavailable status.

### cors configuration
the application includes a comprehensive cors (cross-origin resource sharing) configuration that supports both development and production environments.

#### development environment (local and docker profiles)
- supports common frontend development ports: 3000 (react), 3001, 8080 (vue.js), 4200 (angular)
- allows both localhost and 127.0.0.1 variants
- configuration is defined in `application.yml` and `application-docker.yml`

#### production environment (prod profile)
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

#### environment variables by profile

**local profile (minimal setup):**
- `jwt_secret` - secret key for jwt token signing (can use dummy value for development)
- `jwt_expiration_ms` - jwt token expiration time in milliseconds (default: 86400000)
- `server_port` - application port (default: 8081)

**docker profile (dynamodb local):**
- `jwt_secret` - secret key for jwt token signing (can use dummy value for development)
- `jwt_expiration_ms` - jwt token expiration time in milliseconds (default: 86400000)
- `aws_access_key_id` - aws access key (use 'dummy' for local development)
- `aws_secret_access_key` - aws secret key (use 'dummy' for local development)
- `aws_default_region` - aws region (default: eu-central-1)
- `aws_dynamodb_endpoint` - dynamodb endpoint (default: http://localhost:8000)
- `server_port` - application port (default: 8081)

**prod profile (all variables required):**
- `jwt_secret` - secret key for jwt token signing (required for production)
- `jwt_expiration_ms` - jwt token expiration time in milliseconds (default: 86400000)
- `aws_access_key_id` - aws access key (real production value)
- `aws_secret_access_key` - aws secret key (real production value)
- `aws_default_region` - aws region (default: eu-central-1)
- `server_port` - application port (default: 8080)

#### complete environment variable reference

**jwt configuration:**
- `jwt_secret` - secret key for jwt token signing (required for production)
- `jwt_expiration_ms` - jwt token expiration time in milliseconds (default: 86400000)

**aws configuration:**
- `aws_access_key_id` - aws access key (use 'dummy' for local development)
- `aws_secret_access_key` - aws secret key (use 'dummy' for local development)
- `aws_default_region` - aws region (default: eu-central-1)
- `aws_dynamodb_endpoint` - dynamodb endpoint (default: http://localhost:8000)

**database configuration (legacy, removed in favor of DynamoDB):**
- `db_url` - removed
- `db_username` - removed
- `db_password` - removed

**server configuration:**
- `server_port` - application port (default: 8081 for local/docker, 8080 for prod)

**rate limiting:**
- `rate_limit_auth_requests_per_minute` - auth requests per minute (default: 5)
- `rate_limit_refresh_requests_per_minute` - refresh requests per minute (default: 10)

**dynamodb configuration:**
- `dynamodb_enabled` - enable dynamodb (default: true)
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

5. write unit tests (done 24. june)
   - test todoservice
   - test todocontroller
   - test repository layer
   - add integration tests
   - test authentication flow
   - test authorization rules
   - test error handling
   - add security tests

6. set up aws lambda configuration
   - configure lambda handler
   - add lambda deployment configuration
   - test lambda function locally
   - set up ci/cd pipeline
   - configure aws secrets manager for sensitive data
   - set up aws cloudwatch for monitoring

7. frontend integration (done 28. july)
   - create react authentication pages
   - implement token storage and management
   - add protected route components
   - implement token refresh logic
   - add error handling and user feedback
   - add loading states
   - implement remember me functionality
   - add password reset flow