#!/bin/bash

# Taskflow Backend - AWS SAM Deployment Script
# This script builds and deploys the Taskflow Backend to AWS Lambda

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="dev"
REGION="eu-central-1"
JWT_SECRET=""
CORS_ORIGINS="*"
STACK_NAME=""

# Function to print colored output
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

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -e, --environment   Environment (dev, staging, prod) [default: dev]"
    echo "  -r, --region        AWS Region [default: eu-central-1]"
    echo "  -j, --jwt-secret    JWT Secret (required for production)"
    echo "  -c, --cors-origins  CORS allowed origins [default: *]"
    echo "  -s, --stack-name    CloudFormation stack name [default: taskflow-backend-{env}]"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --environment dev"
    echo "  $0 --environment prod --jwt-secret 'your-super-secret-key' --cors-origins 'https://yourdomain.com'"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -j|--jwt-secret)
            JWT_SECRET="$2"
            shift 2
            ;;
        -c|--cors-origins)
            CORS_ORIGINS="$2"
            shift 2
            ;;
        -s|--stack-name)
            STACK_NAME="$2"
            shift 2
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

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT. Must be dev, staging, or prod."
    exit 1
fi

# Set default stack name if not provided
if [[ -z "$STACK_NAME" ]]; then
    STACK_NAME="taskflow-backend-$ENVIRONMENT"
fi

# Validate JWT secret for production
if [[ "$ENVIRONMENT" == "prod" && -z "$JWT_SECRET" ]]; then
    print_error "JWT secret is required for production deployment."
    print_info "Use: $0 --environment prod --jwt-secret 'your-super-secret-key'"
    exit 1
fi

# Set default JWT secret for dev/staging if not provided
if [[ -z "$JWT_SECRET" ]]; then
    JWT_SECRET="your-super-secure-jwt-secret-key-that-is-at-least-256-bits-long-for-production-use"
fi

print_info "Starting Taskflow Backend deployment..."
print_info "Environment: $ENVIRONMENT"
print_info "Region: $REGION"
print_info "Stack Name: $STACK_NAME"
print_info "CORS Origins: $CORS_ORIGINS"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if SAM CLI is installed
if ! command -v sam &> /dev/null; then
    print_error "SAM CLI is not installed. Please install it first."
    print_info "Installation instructions: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html"
    exit 1
fi

# Check if Maven is installed
if ! command -v mvn &> /dev/null; then
    print_error "Maven is not installed. Please install it first."
    exit 1
fi

# Check AWS credentials
print_info "Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

print_success "AWS credentials configured"

# Build the application
print_info "Building the application..."
mvn clean package -DskipTests

if [[ ! -f "target/taskflow-backend-0.0.1-SNAPSHOT.jar" ]]; then
    print_error "Build failed - JAR file not found"
    exit 1
fi

print_success "Application built successfully"

# Deploy with SAM
print_info "Deploying to AWS..."

sam deploy \
    --template-file template.yaml \
    --stack-name "$STACK_NAME" \
    --s3-bucket "sam-deployments-$REGION-$(aws sts get-caller-identity --query Account --output text)" \
    --capabilities CAPABILITY_IAM \
    --region "$REGION" \
    --parameter-overrides \
        Environment="$ENVIRONMENT" \
        JwtSecret="$JWT_SECRET" \
        CorsAllowedOrigins="$CORS_ORIGINS" \
    --no-fail-on-empty-changeset

if [[ $? -eq 0 ]]; then
    print_success "Deployment completed successfully!"
    
    # Get the API URL
    API_URL=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`TaskflowApi`].OutputValue' \
        --output text)
    
    print_success "API Gateway URL: $API_URL"
    print_info "You can test your API at: ${API_URL}api/health/ping"
    
    # Display useful endpoints
    echo ""
    print_info "Useful endpoints:"
    echo "  Health Check: ${API_URL}api/health/ping"
    echo "  Authentication: ${API_URL}api/auth/register"
    echo "  Todos: ${API_URL}api/todos"
    echo ""
    
else
    print_error "Deployment failed!"
    exit 1
fi
