# 🛠️ Local Testing Scripts

This directory contains scripts for testing your Lambda function locally using both LocalStack and SAM Local.

## 📋 Available Scripts

### 🐳 LocalStack Scripts
- **`setup-localstack.sh`** / **`setup-localstack.bat`** - Sets up complete AWS environment in LocalStack
- Provides full AWS API simulation with Lambda, API Gateway, DynamoDB, and IAM

### ⚡ SAM Local Scripts  
- **`sam-local.sh`** / **`sam-local.bat`** - Runs Lambda function using SAM CLI
- Faster startup, excellent for development and debugging

### 🧪 Testing Scripts
- **`test-local-api.sh`** - Automated API testing script
- Tests health checks, authentication, and CRUD operations

## 🚀 Quick Start

### Option 1: SAM Local (Recommended for Development)
```bash
# Linux/Mac
./scripts/sam-local.sh

# Windows  
scripts\sam-local.bat

# Your API runs at: http://localhost:3000
```

### Option 2: LocalStack (Full AWS Simulation)
```bash
# 1. Start LocalStack
docker-compose up -d localstack dynamodb-local

# 2. Set up Lambda function
# Linux/Mac
./scripts/setup-localstack.sh

# Windows
scripts\setup-localstack.bat

# Your API runs at: http://localhost:4566/restapis/{API_ID}/local/_user_request_/
```

## 🧪 Testing Your API

```bash
# Automated testing (Linux/Mac only)
./scripts/test-local-api.sh

# Manual testing
curl http://localhost:3000/api/health/ping
```

## 📖 Documentation

See **`LOCAL-TESTING-GUIDE.md`** in the root directory for:
- Detailed setup instructions
- Troubleshooting guide
- Advanced configuration options
- CI/CD integration examples

## 🔧 Script Options

### SAM Local Options
```bash
./scripts/sam-local.sh --mode api          # Start API server (default)
./scripts/sam-local.sh --mode invoke       # Single invocation test
./scripts/sam-local.sh --port 8080         # Custom port
./scripts/sam-local.sh --dynamodb-local true  # Use local DynamoDB
./scripts/sam-local.sh --debug             # Enable debugging
```

### Test Script Options
```bash
./scripts/test-local-api.sh --url http://localhost:8080  # Custom API URL
./scripts/test-local-api.sh --email test@example.com     # Custom test email
```

## 🐛 Troubleshooting

### Common Issues:
1. **Port conflicts**: Use `--port` option to change port
2. **DynamoDB errors**: Start DynamoDB with `docker-compose up -d dynamodb-local`
3. **Build failures**: Run `mvn clean package -DskipTests`
4. **Permission errors**: Make scripts executable with `chmod +x scripts/*.sh`

### View Logs:
```bash
# SAM Local: logs appear in terminal
# LocalStack: docker logs localstack
# DynamoDB: docker logs dynamodb-local
```

For complete troubleshooting guide, see `LOCAL-TESTING-GUIDE.md`.
