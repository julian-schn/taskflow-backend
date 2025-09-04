#!/bin/bash

# Test Local API Script
# This script tests the locally running Lambda function with various endpoints

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

# Default configuration
API_URL="http://localhost:3000"
TEST_EMAIL="test@example.com"
TEST_PASSWORD="password123"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --url)
            API_URL="$2"
            shift 2
            ;;
        --email)
            TEST_EMAIL="$2"
            shift 2
            ;;
        --password)
            TEST_PASSWORD="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --url       API URL [default: http://localhost:3000]"
            echo "  --email     Test email [default: test@example.com]"
            echo "  --password  Test password [default: password123]"
            echo "  -h, --help  Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

print_info "Testing API at: $API_URL"
print_info "Test User: $TEST_EMAIL"

# Check if curl is available
if ! command -v curl &> /dev/null; then
    print_error "curl is not installed. Please install it first."
    exit 1
fi

# Check if jq is available (optional but helpful)
JQ_AVAILABLE=false
if command -v jq &> /dev/null; then
    JQ_AVAILABLE=true
fi

# Function to make HTTP requests and format output
make_request() {
    local method=$1
    local endpoint=$2
    local data=$3
    local auth_header=$4
    local description=$5
    
    print_info "Testing: $description"
    echo "  Request: $method $API_URL$endpoint"
    
    if [[ -n "$data" ]]; then
        echo "  Data: $data"
    fi
    
    # Build curl command
    local curl_cmd="curl -s -w \"\nHTTP_STATUS:%{http_code}\n\" -X $method"
    
    if [[ -n "$auth_header" ]]; then
        curl_cmd="$curl_cmd -H \"Authorization: $auth_header\""
    fi
    
    if [[ -n "$data" ]]; then
        curl_cmd="$curl_cmd -H \"Content-Type: application/json\" -d '$data'"
    fi
    
    curl_cmd="$curl_cmd \"$API_URL$endpoint\""
    
    # Execute request
    local response=$(eval $curl_cmd)
    local http_status=$(echo "$response" | grep "HTTP_STATUS:" | cut -d: -f2)
    local body=$(echo "$response" | grep -v "HTTP_STATUS:")
    
    echo "  Status: $http_status"
    
    if [[ $JQ_AVAILABLE == true && -n "$body" ]]; then
        echo "  Response:"
        echo "$body" | jq . 2>/dev/null || echo "    $body"
    else
        echo "  Response: $body"
    fi
    
    if [[ $http_status -ge 200 && $http_status -lt 300 ]]; then
        print_success "✓ $description - PASSED"
    else
        print_error "✗ $description - FAILED (HTTP $http_status)"
    fi
    
    echo ""
    return $http_status
}

# Test 1: Health Check
print_info "=== Test 1: Health Check ==="
make_request "GET" "/api/health/ping" "" "" "Health Check"

# Test 2: User Registration
print_info "=== Test 2: User Registration ==="
REGISTER_DATA="{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}"
make_request "POST" "/api/auth/register" "$REGISTER_DATA" "" "User Registration"

# Test 3: User Login
print_info "=== Test 3: User Login ==="
LOGIN_DATA="{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}"
login_response=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "$LOGIN_DATA" \
    "$API_URL/api/auth/login")

login_status=$(curl -s -w "%{http_code}" -o /dev/null -X POST \
    -H "Content-Type: application/json" \
    -d "$LOGIN_DATA" \
    "$API_URL/api/auth/login")

echo "  Request: POST $API_URL/api/auth/login"
echo "  Data: $LOGIN_DATA"
echo "  Status: $login_status"

if [[ $JQ_AVAILABLE == true ]]; then
    echo "  Response:"
    echo "$login_response" | jq . 2>/dev/null || echo "    $login_response"
    
    # Extract token if login successful
    TOKEN=$(echo "$login_response" | jq -r '.token' 2>/dev/null)
    if [[ "$TOKEN" != "null" && -n "$TOKEN" ]]; then
        print_success "✓ User Login - PASSED (Token received)"
    else
        print_error "✗ User Login - FAILED (No token received)"
        TOKEN=""
    fi
else
    echo "  Response: $login_response"
    # Try to extract token without jq (less reliable)
    TOKEN=$(echo "$login_response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    if [[ -n "$TOKEN" ]]; then
        print_success "✓ User Login - PASSED (Token received)"
    else
        print_error "✗ User Login - FAILED (No token received)"
    fi
fi

echo ""

# Test 4: Create Todo (requires authentication)
if [[ -n "$TOKEN" ]]; then
    print_info "=== Test 4: Create Todo (Authenticated) ==="
    TODO_DATA="{\"title\":\"Test Todo\",\"description\":\"This is a test todo created by the test script\"}"
    make_request "POST" "/api/todos" "$TODO_DATA" "Bearer $TOKEN" "Create Todo"
    
    # Test 5: Get Todos (requires authentication)
    print_info "=== Test 5: Get Todos (Authenticated) ==="
    make_request "GET" "/api/todos" "" "Bearer $TOKEN" "Get Todos"
else
    print_warning "=== Skipping authenticated tests (no token available) ==="
fi

# Test 6: Unauthorized Access
print_info "=== Test 6: Unauthorized Access ==="
make_request "GET" "/api/todos" "" "" "Get Todos (Unauthorized)"

# Test 7: Invalid Endpoint
print_info "=== Test 7: Invalid Endpoint ==="
make_request "GET" "/api/nonexistent" "" "" "Invalid Endpoint"

print_info "=== Test Summary ==="
print_success "Local API testing completed!"
print_info "If any tests failed, check:"
print_info "  1. Is the local API running? (./scripts/sam-local.sh)"
print_info "  2. Is DynamoDB available? (docker-compose up -d dynamodb-local)"
print_info "  3. Check the API logs for error details"
