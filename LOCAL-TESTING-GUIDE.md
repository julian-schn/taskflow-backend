# 🧪 Local Lambda Testing Guide

This guide covers how to test your Lambda function locally using both LocalStack and SAM Local.

## 🎯 Overview

You have two main options for local testing:

1. **🐳 LocalStack** - Complete AWS simulation in Docker
2. **⚡ SAM Local** - AWS's official local testing tool

## 📋 Prerequisites

- Docker and Docker Compose
- AWS CLI
- SAM CLI
- Maven
- curl (for testing)
- jq (optional, for pretty JSON output)

## 🐳 Option 1: LocalStack Testing

LocalStack creates a complete AWS environment on your computer.

### Setup LocalStack

1. **Start LocalStack and DynamoDB:**
   ```bash
   docker-compose up -d localstack dynamodb-local dynamodb-init
   ```

2. **Set up the Lambda function:**
   ```bash
   # Linux/Mac
   chmod +x scripts/setup-localstack.sh
   ./scripts/setup-localstack.sh
   
   # Windows
   scripts\setup-localstack.bat
   ```

3. **Test the function:**
   ```bash
   # Test health endpoint
   curl http://localhost:4566/restapis/YOUR_API_ID/local/_user_request_/api/health/ping
   ```

### What LocalStack Provides:

- ✅ Complete AWS API simulation
- ✅ API Gateway integration
- ✅ Lambda function execution
- ✅ DynamoDB integration
- ✅ IAM roles and permissions
- ✅ CloudWatch logs

### LocalStack URLs:

After setup, your API will be available at:
```
http://localhost:4566/restapis/{API_ID}/local/_user_request_/
```

The setup script will display the exact URL.

## ⚡ Option 2: SAM Local Testing

SAM Local is faster and simpler for function testing.

### Quick Start

1. **Start API server:**
   ```bash
   # Linux/Mac
   chmod +x scripts/sam-local.sh
   ./scripts/sam-local.sh
   
   # Windows
   scripts\sam-local.bat
   ```

2. **Your API runs at:** `http://localhost:3000`

3. **Test endpoints:**
   ```bash
   # Health check
   curl http://localhost:3000/api/health/ping
   
   # Register user
   curl -X POST http://localhost:3000/api/auth/register \
     -H "Content-Type: application/json" \
     -d '{"email":"test@test.com","password":"password123"}'
   ```

### SAM Local Options

```bash
# Different modes
./scripts/sam-local.sh --mode api          # Start API server (default)
./scripts/sam-local.sh --mode invoke       # Single function invocation
./scripts/sam-local.sh --mode build        # Build only

# Custom port
./scripts/sam-local.sh --port 8080

# Use local DynamoDB
./scripts/sam-local.sh --dynamodb-local true

# Debug mode
./scripts/sam-local.sh --debug
```

### SAM Local with Different Databases

#### Using Local DynamoDB:
```bash
# Start DynamoDB first
docker-compose up -d dynamodb-local dynamodb-init

# Start SAM with local DynamoDB
./scripts/sam-local.sh --dynamodb-local true
```

#### Using AWS DynamoDB:
```bash
# Configure AWS credentials
aws configure

# Start SAM with AWS DynamoDB
./scripts/sam-local.sh
```

## 🧪 Testing Your Local API

### Automated Testing

Use the provided test script:

```bash
# Linux/Mac
chmod +x scripts/test-local-api.sh
./scripts/test-local-api.sh

# Windows - use curl commands manually or PowerShell
```

### Manual Testing

#### 1. Health Check
```bash
curl http://localhost:3000/api/health/ping
```
Expected: `{"status":"UP"}`

#### 2. User Registration
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

#### 3. User Login
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```
Save the returned token for authenticated requests.

#### 4. Create Todo
```bash
TOKEN="your_jwt_token_here"
curl -X POST http://localhost:3000/api/todos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"My Todo","description":"Test todo"}'
```

#### 5. Get Todos
```bash
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:3000/api/todos
```

## 🔧 Configuration

### Environment Variables

Both testing methods support these environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `SPRING_PROFILES_ACTIVE` | Spring profile | `lambda` |
| `DYNAMODB_ENABLED` | Enable DynamoDB | `true` |
| `DYNAMODB_TABLE_NAME` | Todos table name | `todos` |
| `USERS_TABLE_NAME` | Users table name | `users` |
| `AWS_DYNAMODB_ENDPOINT` | DynamoDB endpoint | Local/AWS |
| `JWT_SECRET` | JWT signing secret | Test key |
| `CORS_ALLOWED_ORIGINS` | CORS origins | `*` |

### Custom Configuration

Create a `.env.local` file:
```bash
SPRING_PROFILES_ACTIVE=local
JWT_SECRET=my-custom-secret
DYNAMODB_TABLE_NAME=my-todos-table
```

## 🐛 Troubleshooting

### Common Issues

#### 1. "Port already in use"
```bash
# Find what's using the port
lsof -i :3000  # Mac/Linux
netstat -ano | findstr :3000  # Windows

# Use different port
./scripts/sam-local.sh --port 8080
```

#### 2. "DynamoDB connection failed"
```bash
# Check if DynamoDB is running
docker ps | grep dynamodb

# Start DynamoDB
docker-compose up -d dynamodb-local dynamodb-init

# Test DynamoDB
aws dynamodb list-tables --endpoint-url http://localhost:8000 --region eu-central-1
```

#### 3. "SAM build fails"
```bash
# Clean and rebuild
mvn clean package -DskipTests
sam build --debug
```

#### 4. "Function times out"
```bash
# Increase timeout in template.yaml
Timeout: 60  # seconds

# Or use debug mode
./scripts/sam-local.sh --debug
```

#### 5. "AWS credentials error"
```bash
# For AWS DynamoDB
aws configure

# For local testing, ignore this error
./scripts/sam-local.sh --dynamodb-local true
```

### Debugging

#### View Logs
```bash
# SAM Local logs appear in the terminal
./scripts/sam-local.sh --debug

# LocalStack logs
docker logs localstack

# DynamoDB logs
docker logs dynamodb-local
```

#### Debug in IDE

1. Start SAM in debug mode:
   ```bash
   sam local start-api --debug-port 5858
   ```

2. Attach your IDE debugger to port 5858

3. Set breakpoints in your Java code

#### Test Individual Components

```bash
# Test just the build
./scripts/sam-local.sh --mode build

# Test single invocation
./scripts/sam-local.sh --mode invoke

# Test DynamoDB connection
aws dynamodb scan --table-name todos --endpoint-url http://localhost:8000 --region eu-central-1
```

## 📊 Performance Comparison

| Feature | LocalStack | SAM Local |
|---------|------------|-----------|
| **Startup Time** | ~30 seconds | ~10 seconds |
| **Memory Usage** | High (full AWS sim) | Low (function only) |
| **AWS API Coverage** | Complete | Lambda + API Gateway |
| **Debugging** | Limited | Excellent |
| **Cold Start Simulation** | Yes | Yes |
| **Multi-service Testing** | Excellent | Limited |

## 🚀 Best Practices

### Development Workflow

1. **Quick Testing**: Use SAM Local for rapid development
2. **Integration Testing**: Use LocalStack for complete AWS testing
3. **CI/CD**: Use both in your pipeline

### Testing Strategy

```bash
# 1. Quick smoke test
./scripts/sam-local.sh --mode invoke

# 2. Full API testing
./scripts/sam-local.sh &
sleep 10
./scripts/test-local-api.sh
kill %1

# 3. Integration testing
docker-compose up -d
./scripts/setup-localstack.sh
# Run integration tests
docker-compose down
```

### Performance Optimization

1. **Keep DynamoDB running** between tests
2. **Use SAM build cache** - avoid unnecessary rebuilds
3. **Pre-warm Lambda** with health checks
4. **Use local DynamoDB** for faster tests

## 🔄 CI/CD Integration

### GitHub Actions Example

```yaml
name: Local Testing
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Java
        uses: actions/setup-java@v3
        with:
          java-version: '17'
          
      - name: Setup SAM
        uses: aws-actions/setup-sam@v2
        
      - name: Start LocalStack
        run: |
          docker-compose up -d localstack dynamodb-local
          sleep 30
          
      - name: Run Tests
        run: |
          chmod +x scripts/sam-local.sh scripts/test-local-api.sh
          ./scripts/sam-local.sh --mode build
          ./scripts/sam-local.sh &
          sleep 10
          ./scripts/test-local-api.sh
```

---

## 📞 Need Help?

- **SAM Issues**: Check [AWS SAM Documentation](https://docs.aws.amazon.com/serverless-application-model/)
- **LocalStack Issues**: Check [LocalStack Documentation](https://docs.localstack.cloud/)
- **Function Issues**: Enable debug mode and check logs
- **DynamoDB Issues**: Verify table creation with `aws dynamodb list-tables`
