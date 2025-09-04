#!/bin/bash

# LocalStack Lambda Setup Script
# This script builds the application and registers it as a Lambda function in LocalStack

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

# Configuration
FUNCTION_NAME="taskflow-backend"
RUNTIME="java17"
HANDLER="util.AwsLambdaHandler::handleRequest"
LOCALSTACK_ENDPOINT="http://localhost:4566"
REGION="eu-central-1"
JAR_PATH="target/taskflow-backend-0.0.1-SNAPSHOT.jar"

print_info "Setting up LocalStack Lambda function: $FUNCTION_NAME"

# Check if LocalStack is running
print_info "Checking if LocalStack is running..."
if ! curl -s "$LOCALSTACK_ENDPOINT/health" > /dev/null; then
    print_error "LocalStack is not running. Please start it with 'docker-compose up -d localstack'"
    exit 1
fi

print_success "LocalStack is running"

# Build the application
print_info "Building the application..."
mvn clean package -DskipTests

if [[ ! -f "$JAR_PATH" ]]; then
    print_error "Build failed - JAR file not found at $JAR_PATH"
    exit 1
fi

print_success "Application built successfully"

# Create a ZIP file for Lambda deployment
print_info "Creating deployment package..."
ZIP_PATH="target/taskflow-backend-lambda.zip"
cp "$JAR_PATH" "target/app.jar"
cd target && zip -r ../target/taskflow-backend-lambda.zip app.jar && cd ..

# Set AWS CLI to use LocalStack
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=$REGION

# Delete existing function if it exists
print_info "Cleaning up existing Lambda function..."
aws lambda delete-function \
    --function-name "$FUNCTION_NAME" \
    --endpoint-url "$LOCALSTACK_ENDPOINT" \
    --region "$REGION" 2>/dev/null || true

# Create IAM role for Lambda
print_info "Creating IAM role for Lambda..."
ROLE_NAME="lambda-execution-role"

# Create trust policy
cat > /tmp/trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create the role
aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document file:///tmp/trust-policy.json \
    --endpoint-url "$LOCALSTACK_ENDPOINT" \
    --region "$REGION" 2>/dev/null || true

# Attach basic execution policy
aws iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" \
    --endpoint-url "$LOCALSTACK_ENDPOINT" \
    --region "$REGION" 2>/dev/null || true

ROLE_ARN="arn:aws:iam::000000000000:role/$ROLE_NAME"

# Create the Lambda function
print_info "Creating Lambda function..."
aws lambda create-function \
    --function-name "$FUNCTION_NAME" \
    --runtime "$RUNTIME" \
    --role "$ROLE_ARN" \
    --handler "$HANDLER" \
    --zip-file "fileb://$ZIP_PATH" \
    --timeout 30 \
    --memory-size 1024 \
    --environment Variables='{
        SPRING_PROFILES_ACTIVE=lambda,
        DYNAMODB_ENABLED=true,
        DYNAMODB_TABLE_NAME=todos,
        USERS_TABLE_NAME=users,
        AWS_DYNAMODB_ENDPOINT=http://localstack:4566,
        JWT_SECRET=local-development-jwt-secret-key,
        CORS_ALLOWED_ORIGINS=*
    }' \
    --endpoint-url "$LOCALSTACK_ENDPOINT" \
    --region "$REGION"

print_success "Lambda function created successfully"

# Create API Gateway
print_info "Creating API Gateway..."
API_NAME="taskflow-api-local"

# Create REST API
API_ID=$(aws apigateway create-rest-api \
    --name "$API_NAME" \
    --endpoint-url "$LOCALSTACK_ENDPOINT" \
    --region "$REGION" \
    --query 'id' \
    --output text)

print_info "Created API Gateway with ID: $API_ID"

# Get root resource ID
ROOT_RESOURCE_ID=$(aws apigateway get-resources \
    --rest-api-id "$API_ID" \
    --endpoint-url "$LOCALSTACK_ENDPOINT" \
    --region "$REGION" \
    --query 'items[0].id' \
    --output text)

# Create proxy resource
PROXY_RESOURCE_ID=$(aws apigateway create-resource \
    --rest-api-id "$API_ID" \
    --parent-id "$ROOT_RESOURCE_ID" \
    --path-part "{proxy+}" \
    --endpoint-url "$LOCALSTACK_ENDPOINT" \
    --region "$REGION" \
    --query 'id' \
    --output text)

# Create ANY method for proxy resource
aws apigateway put-method \
    --rest-api-id "$API_ID" \
    --resource-id "$PROXY_RESOURCE_ID" \
    --http-method ANY \
    --authorization-type NONE \
    --endpoint-url "$LOCALSTACK_ENDPOINT" \
    --region "$REGION"

# Set up Lambda integration
LAMBDA_URI="arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/arn:aws:lambda:$REGION:000000000000:function:$FUNCTION_NAME/invocations"

aws apigateway put-integration \
    --rest-api-id "$API_ID" \
    --resource-id "$PROXY_RESOURCE_ID" \
    --http-method ANY \
    --type AWS_PROXY \
    --integration-http-method POST \
    --uri "$LAMBDA_URI" \
    --endpoint-url "$LOCALSTACK_ENDPOINT" \
    --region "$REGION"

# Create deployment
DEPLOYMENT_ID=$(aws apigateway create-deployment \
    --rest-api-id "$API_ID" \
    --stage-name local \
    --endpoint-url "$LOCALSTACK_ENDPOINT" \
    --region "$REGION" \
    --query 'id' \
    --output text)

# Add Lambda permission for API Gateway
aws lambda add-permission \
    --function-name "$FUNCTION_NAME" \
    --statement-id "api-gateway-invoke" \
    --action "lambda:InvokeFunction" \
    --principal "apigateway.amazonaws.com" \
    --source-arn "arn:aws:execute-api:$REGION:000000000000:$API_ID/*/*" \
    --endpoint-url "$LOCALSTACK_ENDPOINT" \
    --region "$REGION"

print_success "API Gateway configured successfully"

# Cleanup temporary files
rm -f /tmp/trust-policy.json

API_URL="http://localhost:4566/restapis/$API_ID/local/_user_request_"

print_success "LocalStack setup completed!"
echo ""
print_info "🚀 Your Lambda function is now running in LocalStack!"
echo ""
print_info "API Gateway URL: $API_URL"
print_info "Lambda Function: $FUNCTION_NAME"
echo ""
print_info "Test endpoints:"
echo "  Health Check: curl $API_URL/api/health/ping"
echo "  Register User: curl -X POST $API_URL/api/auth/register -H 'Content-Type: application/json' -d '{\"email\":\"test@test.com\",\"password\":\"password123\"}'"
echo ""
print_info "To view logs: aws logs describe-log-groups --endpoint-url $LOCALSTACK_ENDPOINT"
print_warning "Note: Make sure DynamoDB Local is also running for full functionality"
