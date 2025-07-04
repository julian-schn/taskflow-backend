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

4. **start services (optional)**
   if you want to use dynamodb instead of h2:
   ```bash
   docker-compose up -d
   ```

5. **run the application**
   ```bash
   # for local development (uses h2 database) recommended
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

### spring boot profiles

the application supports three different profiles for different environments:

#### local profile (recommended for development)
- **purpose**: local development and testing without external dependencies
- **database**: h2 in-memory database (fast startup, no setup required)
- **port**: 8081
- **features**: 
  - h2 console available at http://localhost:8081/h2-console
  - automatic table creation
  - debug logging enabled
  - circular references allowed for development
- **usage**: `mvn spring-boot:run -Dspring-boot.run.profiles=local`

#### docker profile
- **purpose**: containerized deployment with dynamodb
- **database**: dynamodb local via docker compose
- **port**: 8081
- **features**:
  - full aws dynamodb integration
  - automatic table creation via docker compose
  - production-like environment locally
- **usage**: `docker-compose up -d` then `mvn spring-boot:run`

#### prod profile
- **purpose**: production deployment
- **database**: aws dynamodb (cloud)
- **port**: 8080
- **features**:
  - production security settings
  - cloud aws services
  - optimized for performance
- **usage**: `mvn spring-boot:run -Dspring-boot.run.profiles=prod`

**recommendation**: use the `local` profile for development and testing. it provides the fastest setup and doesn't require docker or aws services.

### how to run local dynamodb docker container
1. start container by running ``docker-compose up -d`` from project root
2. stop container by running ``docker-compose down`` from project root
3. check running docker containers with ``docker container ls``

**note:** the docker compose setup automatically creates the required tables (todos and users) when starting up, so manual table creation is no longer needed.

### verify docker dynamodb setup
1. start container as explained above
2. run springboot app with local profile: ``mvn spring-boot:run -Dspring-boot.run.profiles=local``
3. check with ``aws dynamodb list-tables --endpoint-url http://localhost:8000 --region eu-central-1`` (requires aws cli) if tables exist, should return "todos" and "users"
4. hit endpoints with api calls (e.g. ``POST ...``)

#### configuring aws cli
- you need to run ``aws configure`` first after installing the cli, this prompts you to input some values, these are as follows:
```bash
export AWS_ACCESS_KEY_ID=dummy
export AWS_SECRET_ACCESS_KEY=dummy
export AWS_DEFAULT_REGION=eu-central-1
export AWS_DEFAULT_OUTPUT=json
```

### how to test the api

**recommended approach (local profile with h2 database):**
1. start springboot app with local profile: ``mvn spring-boot:run -Dspring-boot.run.profiles=local``
2. the app will automatically create an h2 in-memory database with all required tables
3. access h2 console at http://localhost:8081/h2-console if you want to inspect the database
4. use curl commands to test endpoints:

**alternative approach (with dynamodb):**
1. start local dynamodb: ``docker-compose up -d``
2. start springboot app: ``mvn spring-boot:run`` (uses default profile)
3. use curl commands to test endpoints:

**note:** its recommended to use the local profile approach for development and testing as it's faster and doesn't require docker or aws services.

#### create todo
```bash
curl -X POST http://localhost:8081/api/todos \
  -H "Content-Type: application/json" \
  -d '{
    "title": "my first todo",
    "description": "this is a test todo"
  }'
```

#### get all todos
```bash
curl http://localhost:8081/api/todos
```

#### get specific todo
```bash
# replace {id} with actual todo id from create response
curl http://localhost:8081/api/todos/{id}
```

#### delete todo
```bash
# replace {id} with actual todo id
curl -X DELETE http://localhost:8081/api/todos/{id}
```

#### authentication endpoints

**register a new user:**
```bash
curl -X POST http://localhost:8081/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "password123"
  }'
```

**login:**
```bash
curl -X POST http://localhost:8081/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "password123"
  }'
```

**refresh token:**
```bash
curl -X POST http://localhost:8081/api/auth/refresh \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**note:** all todo endpoints require authentication. include the jwt token in the authorization header:
```bash
curl -X POST http://localhost:8081/api/todos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "title": "my first todo",
    "description": "this is a test todo"
  }'
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

7. frontend integration
    - create react authentication pages
    - implement token storage and management
    - add protected route components
    - implement token refresh logic
    - add error handling and user feedback
    - add loading states
    - implement remember me functionality
    - add password reset flow

