# API Endpoints Reference

Comprehensive reference for all available endpoints in the Taskflow Backend API.

## Base URLs

- **Local/Docker**: `http://localhost:8081`
- **Production**: `http://localhost:8080`

## Authentication Required

All todo endpoints require JWT authentication. Include the token in the `Authorization` header:
```
Authorization: Bearer <your-jwt-token>
```

---

## 🔐 Authentication Endpoints

### Register User
```http
POST /api/auth/register
```

**Request Body:**
```json
{
  "username": "string",
  "password": "string"
}
```

**Requirements:**
- Password: minimum 8 characters, must contain letters and numbers
- Username: must be unique

**Response:** `200 OK`
```json
{
  "token": "eyJhbGciOiJIUzUxMiJ9..."
}
```

**Errors:**
- `400` - Validation failed
- `409` - Username already exists
- `429` - Rate limit exceeded (5 requests/minute)

---

### Login User
```http
POST /api/auth/login
```

**Request Body:**
```json
{
  "username": "string",
  "password": "string"
}
```

**Response:** `200 OK`
```json
{
  "token": "eyJhbGciOiJIUzUxMiJ9..."
}
```

**Errors:**
- `401` - Invalid credentials
- `429` - Rate limit exceeded (5 requests/minute)

---

### Refresh Token
```http
POST /api/auth/refresh
```

**Headers:**
```
Authorization: Bearer <current-token>
```

**Response:** `200 OK`
```json
{
  "token": "eyJhbGciOiJIUzUxMiJ9..."
}
```

**Errors:**
- `400` - Missing or invalid authorization header
- `403` - Token invalid or expired
- `429` - Rate limit exceeded (10 requests/minute)

---

## 📝 Todo Endpoints

### Create Todo
```http
POST /api/todos
```

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "title": "string (required, max 100 chars)",
  "description": "string (optional, max 1000 chars)"
}
```

**Response:** `200 OK`
```json
{
  "id": "generated-uuid",
  "title": "My Todo",
  "description": "Todo description",
  "status": "PENDING",
  "createdAt": "2024-01-01T12:00:00Z",
  "updatedAt": "2024-01-01T12:00:00Z"
}
```

**Errors:**
- `400` - Validation failed
- `401` - Unauthorized (missing/invalid token)

---

### Get All Todos
```http
GET /api/todos
```

**Headers:**
```
Authorization: Bearer <token>
```

**Response:** `200 OK`
```json
[
  {
    "id": "uuid-1",
    "title": "Todo 1",
    "description": "Description 1",
    "status": "PENDING",
    "createdAt": "2024-01-01T12:00:00Z",
    "updatedAt": "2024-01-01T12:00:00Z"
  }
]
```

**Notes:**
- Returns only todos belonging to the authenticated user
- Empty array if no todos found

---

### Get Todo by ID
```http
GET /api/todos/{id}
```

**Headers:**
```
Authorization: Bearer <token>
```

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "title": "Todo Title",
  "description": "Todo description",
  "status": "PENDING",
  "createdAt": "2024-01-01T12:00:00Z",
  "updatedAt": "2024-01-01T12:00:00Z"
}
```

**Errors:**
- `401` - Unauthorized
- `403` - Access denied (todo belongs to another user)
- `404` - Todo not found

---

### Delete Todo
```http
DELETE /api/todos/{id}
```

**Headers:**
```
Authorization: Bearer <token>
```

**Response:** `204 No Content`

**Errors:**
- `401` - Unauthorized
- `403` - Access denied (todo belongs to another user)
- `404` - Todo not found

---

### Edit Todo Title
```http
PUT /api/todos/{id}
```

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "title": "string (required, max 100 chars)"
}
```

**Description:** Updates the title of an existing todo.

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "title": "Updated Todo Title",
  "description": "Todo description",
  "status": "PENDING",
  "createdAt": "2024-01-01T12:00:00Z",
  "updatedAt": "2024-01-01T12:10:00Z"
}
```

**Errors:**
- `400` - Validation failed (title blank or too long)
- `401` - Unauthorized
- `403` - Access denied (todo belongs to another user)
- `404` - Todo not found

---

### Toggle Todo Status
```http
PUT /api/todos/{id}/toggle
```

**Headers:**
```
Authorization: Bearer <token>
```

**Description:** Toggles todo status between "PENDING" (not done) and "COMPLETED" (done).

**Response:** `200 OK`
```json
{
  "id": "uuid",
  "title": "Todo Title",
  "description": "Todo description",
  "status": "COMPLETED",
  "createdAt": "2024-01-01T12:00:00Z",
  "updatedAt": "2024-01-01T12:05:00Z"
}
```

**Status Logic:**
- `PENDING` → `COMPLETED` (mark as done)
- `COMPLETED` → `PENDING` (mark as not done)

**Errors:**
- `401` - Unauthorized
- `403` - Access denied (todo belongs to another user)
- `404` - Todo not found

---

## 🏥 Health Check Endpoints

### Basic Ping
```http
GET /api/health/ping
```

**Response:** `200 OK`
```json
{
  "status": "UP",
  "message": "Service is running",
  "timestamp": "1753639629182"
}
```

---

### Database Health
```http
GET /api/health/database
```

**Response:** `200 OK` / `503 Service Unavailable`
```json
{
  "status": "UP",
  "database": "Amazon DynamoDB",
  "endpoint": "http://localhost:8000",
  "connection": "valid"
}
```

---

### System Status
```http
GET /api/health/status
```

**Response:** `200 OK`
```json
{
  "status": "UP",
  "application": "taskflow-backend",
  "timestamp": 1753639711530,
  "database_connected": true,
  "database_status": "Amazon DynamoDB - Connected",
  "database": {
    "status": "UP",
    "database": "Amazon DynamoDB",
    "endpoint": "http://localhost:8000",
    "connection": "valid"
  }
}
```

---

### Spring Actuator Health
```http
GET /actuator/health
```

**Response:** `200 OK`
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
      "status": "UP"
    },
    "ping": {
      "status": "UP"
    }
  }
}
```

---

## 🗄️ DynamoDB Notes (Development)

- The service uses DynamoDB by default for all profiles.
- With DynamoDB Local (Docker), the application will auto-create tables and indexes on startup:
  - Table `todos` with partition key `id` (STRING)
  - Table `users` with partition key `id` (STRING)
  - Global Secondary Index `username-index` on `users.username` for efficient lookups
  - Billing mode: on-demand (PAY_PER_REQUEST)

## 📊 Rate Limits

- **Auth endpoints** (register/login): 5 requests per minute per IP
- **Token refresh**: 10 requests per minute per IP
- **Other endpoints**: No rate limiting

## 🔒 Security Notes

- Health endpoints are publicly accessible
- H2 console is only available in local/development profiles
- All todo operations are user-scoped (users can only access their own todos)
- JWT tokens expire after 24 hours by default

## 📝 Example Usage

```bash
# 1. Register a user
curl -X POST http://localhost:8081/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username": "john", "password": "password123"}'

# 2. Extract token from response and create a todo
curl -X POST http://localhost:8081/api/todos \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"title": "My First Todo", "description": "Learn the API"}'

# 3. Get all todos
curl -H "Authorization: Bearer <token>" \
  http://localhost:8081/api/todos

# 4. Edit todo title
curl -X PUT -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"title": "Updated Todo Title"}' \
  http://localhost:8081/api/todos/1

# 5. Toggle todo status (PENDING → COMPLETED or COMPLETED → PENDING)
curl -X PUT -H "Authorization: Bearer <token>" \
  http://localhost:8081/api/todos/1/toggle

# 6. Check system health
curl http://localhost:8081/api/health/status
``` 