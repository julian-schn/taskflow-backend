#!/bin/bash

# SAM Local Testing Script
# This script builds and runs the Lambda function locally using SAM CLI

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Default values
MODE="api"
PORT="3000"
DYNAMODB_LOCAL="false"
ENVIRONMENT="local"
DEBUG="false"

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -m, --mode           Mode: api, invoke, or build [default: api]"
    echo "  -p, --port           Port for SAM local API [default: 3000]"
    echo "  -d, --dynamodb-local Use local DynamoDB instead of AWS [default: false]"
    echo "  -e, --environment    Environment profile [default: local]"
    echo "  --debug              Enable debug mode [default: false]"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Modes:"
    echo "  api                  Start local API Gateway (sam local start-api)"
    echo "  invoke               Invoke function once (sam local invoke)"
    echo "  build                Build only (sam build)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Start API server on port 3000"
    echo "  $0 --mode api --port 8080            # Start API server on port 8080"
    echo "  $0 --mode invoke                     # Invoke function once"
    echo "  $0 --dynamodb-local true             # Use local DynamoDB"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--mode)
            MODE="$2"
            shift 2
            ;;
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        -d|--dynamodb-local)
            DYNAMODB_LOCAL="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --debug)
            DEBUG="true"
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate mode
if [[ ! "$MODE" =~ ^(api|invoke|build)$ ]]; then
    print_error "Invalid mode: $MODE. Must be api, invoke, or build."
    exit 1
fi

print_info "Starting SAM Local in $MODE mode"
print_info "Environment: $ENVIRONMENT"

# Check if SAM CLI is installed
if ! command -v sam &> /dev/null; then
    print_error "SAM CLI is not installed. Please install it first."
    print_info "Installation instructions: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html"
    exit 1
fi

# Check if Maven is installed for building
if ! command -v mvn &> /dev/null; then
    print_error "Maven is not installed. Please install it first."
    exit 1
fi

# Build the application
print_info "Building the application..."
mvn clean package -DskipTests

if [[ ! -f "target/taskflow-backend-0.0.1-SNAPSHOT.jar" ]]; then
    print_error "Build failed - JAR file not found"
    exit 1
fi

print_success "Application built successfully"

# Build with SAM
print_info "Building with SAM..."
sam build

if [[ "$MODE" == "build" ]]; then
    print_success "SAM build completed"
    exit 0
fi

# Set up environment variables
export SPRING_PROFILES_ACTIVE="$ENVIRONMENT"

# Configure DynamoDB endpoint based on user choice
if [[ "$DYNAMODB_LOCAL" == "true" ]]; then
    export AWS_DYNAMODB_ENDPOINT="http://localhost:8000"
    export DYNAMODB_ENABLED="true"
    print_info "Using local DynamoDB at http://localhost:8000"
    print_warning "Make sure local DynamoDB is running: docker-compose up -d dynamodb-local"
else
    export AWS_DYNAMODB_ENDPOINT=""
    export DYNAMODB_ENABLED="true"
    print_info "Using AWS DynamoDB (requires AWS credentials)"
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_warning "AWS credentials not configured. Some features may not work."
        print_info "Run 'aws configure' to set up AWS credentials"
    fi
fi

# Set up other environment variables
export JWT_SECRET="local-development-jwt-secret-key-for-testing-only"
export CORS_ALLOWED_ORIGINS="*"
export DYNAMODB_TABLE_NAME="todos"
export USERS_TABLE_NAME="users"

# Create a temporary env file for SAM
ENV_FILE=".env.sam"
cat > "$ENV_FILE" << EOF
SPRING_PROFILES_ACTIVE=$ENVIRONMENT
DYNAMODB_ENABLED=true
DYNAMODB_TABLE_NAME=todos
USERS_TABLE_NAME=users
AWS_DYNAMODB_ENDPOINT=$AWS_DYNAMODB_ENDPOINT
JWT_SECRET=$JWT_SECRET
CORS_ALLOWED_ORIGINS=$CORS_ALLOWED_ORIGINS
RATE_LIMIT_AUTH_REQUESTS_PER_MINUTE=10
RATE_LIMIT_REFRESH_REQUESTS_PER_MINUTE=20
EOF

# Additional debug flags
DEBUG_FLAGS=""
if [[ "$DEBUG" == "true" ]]; then
    DEBUG_FLAGS="--debug"
    print_info "Debug mode enabled"
fi

if [[ "$MODE" == "api" ]]; then
    print_info "Starting local API Gateway on port $PORT..."
    print_success "🚀 Your API will be available at: http://localhost:$PORT"
    echo ""
    print_info "Test endpoints:"
    echo "  Health Check: curl http://localhost:$PORT/api/health/ping"
    echo "  Register User: curl -X POST http://localhost:$PORT/api/auth/register -H 'Content-Type: application/json' -d '{\"email\":\"test@test.com\",\"password\":\"password123\"}'"
    echo ""
    print_warning "Press Ctrl+C to stop the server"
    echo ""
    
    # Start API Gateway
    sam local start-api \
        --port "$PORT" \
        --env-vars "$ENV_FILE" \
        $DEBUG_FLAGS
        
elif [[ "$MODE" == "invoke" ]]; then
    print_info "Invoking Lambda function once..."
    
    # Create a test event
    TEST_EVENT=".test-event.json"
    cat > "$TEST_EVENT" << 'EOF'
{
  "httpMethod": "GET",
  "path": "/api/health/ping",
  "queryStringParameters": null,
  "headers": {
    "Accept": "application/json",
    "Content-Type": "application/json"
  },
  "body": null,
  "isBase64Encoded": false,
  "requestContext": {
    "requestId": "test-request-id",
    "stage": "local",
    "httpMethod": "GET",
    "path": "/api/health/ping"
  }
}
EOF
    
    print_info "Using test event for health check endpoint"
    
    # Invoke the function
    sam local invoke \
        --event "$TEST_EVENT" \
        --env-vars "$ENV_FILE" \
        $DEBUG_FLAGS \
        TaskflowBackendFunction
    
    # Cleanup
    rm -f "$TEST_EVENT"
fi

# Cleanup
rm -f "$ENV_FILE"

print_success "SAM Local session completed"
