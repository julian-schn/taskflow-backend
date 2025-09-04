@echo off
REM SAM Local Testing Script for Windows
REM This script builds and runs the Lambda function locally using SAM CLI

setlocal enabledelayedexpansion

REM Default values
set MODE=api
set PORT=3000
set DYNAMODB_LOCAL=false
set ENVIRONMENT=local
set DEBUG=false

REM Parse command line arguments
:parse_args
if "%~1"=="" goto :start_execution
if "%~1"=="--mode" (
    set MODE=%~2
    shift
    shift
    goto :parse_args
)
if "%~1"=="--port" (
    set PORT=%~2
    shift
    shift
    goto :parse_args
)
if "%~1"=="--dynamodb-local" (
    set DYNAMODB_LOCAL=%~2
    shift
    shift
    goto :parse_args
)
if "%~1"=="--environment" (
    set ENVIRONMENT=%~2
    shift
    shift
    goto :parse_args
)
if "%~1"=="--debug" (
    set DEBUG=true
    shift
    goto :parse_args
)
if "%~1"=="--help" (
    goto :show_usage
)
echo [ERROR] Unknown option: %~1
goto :show_usage

:start_execution
REM Validate mode
if not "%MODE%"=="api" if not "%MODE%"=="invoke" if not "%MODE%"=="build" (
    echo [ERROR] Invalid mode: %MODE%. Must be api, invoke, or build.
    exit /b 1
)

echo [INFO] Starting SAM Local in %MODE% mode
echo [INFO] Environment: %ENVIRONMENT%

REM Check if SAM CLI is installed
sam --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] SAM CLI is not installed. Please install it first.
    echo [INFO] Installation instructions: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html
    exit /b 1
)

REM Check if Maven is installed
mvn --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Maven is not installed. Please install it first.
    exit /b 1
)

REM Build the application
echo [INFO] Building the application...
call mvn clean package -DskipTests

if not exist "target\taskflow-backend-0.0.1-SNAPSHOT.jar" (
    echo [ERROR] Build failed - JAR file not found
    exit /b 1
)

echo [SUCCESS] Application built successfully

REM Build with SAM
echo [INFO] Building with SAM...
sam build

if "%MODE%"=="build" (
    echo [SUCCESS] SAM build completed
    exit /b 0
)

REM Set up environment variables
set SPRING_PROFILES_ACTIVE=%ENVIRONMENT%

REM Configure DynamoDB endpoint
if "%DYNAMODB_LOCAL%"=="true" (
    set AWS_DYNAMODB_ENDPOINT=http://localhost:8000
    set DYNAMODB_ENABLED=true
    echo [INFO] Using local DynamoDB at http://localhost:8000
    echo [WARNING] Make sure local DynamoDB is running: docker-compose up -d dynamodb-local
) else (
    set AWS_DYNAMODB_ENDPOINT=
    set DYNAMODB_ENABLED=true
    echo [INFO] Using AWS DynamoDB (requires AWS credentials)
    
    REM Check AWS credentials
    aws sts get-caller-identity >nul 2>&1
    if %errorlevel% neq 0 (
        echo [WARNING] AWS credentials not configured. Some features may not work.
        echo [INFO] Run 'aws configure' to set up AWS credentials
    )
)

REM Set up other environment variables
set JWT_SECRET=local-development-jwt-secret-key-for-testing-only
set CORS_ALLOWED_ORIGINS=*
set DYNAMODB_TABLE_NAME=todos
set USERS_TABLE_NAME=users

REM Create a temporary env file for SAM
set ENV_FILE=.env.sam
echo SPRING_PROFILES_ACTIVE=%ENVIRONMENT%> %ENV_FILE%
echo DYNAMODB_ENABLED=true>> %ENV_FILE%
echo DYNAMODB_TABLE_NAME=todos>> %ENV_FILE%
echo USERS_TABLE_NAME=users>> %ENV_FILE%
echo AWS_DYNAMODB_ENDPOINT=%AWS_DYNAMODB_ENDPOINT%>> %ENV_FILE%
echo JWT_SECRET=%JWT_SECRET%>> %ENV_FILE%
echo CORS_ALLOWED_ORIGINS=%CORS_ALLOWED_ORIGINS%>> %ENV_FILE%
echo RATE_LIMIT_AUTH_REQUESTS_PER_MINUTE=10>> %ENV_FILE%
echo RATE_LIMIT_REFRESH_REQUESTS_PER_MINUTE=20>> %ENV_FILE%

REM Additional debug flags
set DEBUG_FLAGS=
if "%DEBUG%"=="true" (
    set DEBUG_FLAGS=--debug
    echo [INFO] Debug mode enabled
)

if "%MODE%"=="api" (
    echo [INFO] Starting local API Gateway on port %PORT%...
    echo [SUCCESS] Your API will be available at: http://localhost:%PORT%
    echo.
    echo [INFO] Test endpoints:
    echo   Health Check: curl http://localhost:%PORT%/api/health/ping
    echo   Register User: curl -X POST http://localhost:%PORT%/api/auth/register -H "Content-Type: application/json" -d "{\"email\":\"test@test.com\",\"password\":\"password123\"}"
    echo.
    echo [WARNING] Press Ctrl+C to stop the server
    echo.
    
    REM Start API Gateway
    sam local start-api --port %PORT% --env-vars %ENV_FILE% %DEBUG_FLAGS%
    
) else if "%MODE%"=="invoke" (
    echo [INFO] Invoking Lambda function once...
    
    REM Create a test event
    set TEST_EVENT=.test-event.json
    echo {> %TEST_EVENT%
    echo   "httpMethod": "GET",>> %TEST_EVENT%
    echo   "path": "/api/health/ping",>> %TEST_EVENT%
    echo   "queryStringParameters": null,>> %TEST_EVENT%
    echo   "headers": {>> %TEST_EVENT%
    echo     "Accept": "application/json",>> %TEST_EVENT%
    echo     "Content-Type": "application/json">> %TEST_EVENT%
    echo   },>> %TEST_EVENT%
    echo   "body": null,>> %TEST_EVENT%
    echo   "isBase64Encoded": false,>> %TEST_EVENT%
    echo   "requestContext": {>> %TEST_EVENT%
    echo     "requestId": "test-request-id",>> %TEST_EVENT%
    echo     "stage": "local",>> %TEST_EVENT%
    echo     "httpMethod": "GET",>> %TEST_EVENT%
    echo     "path": "/api/health/ping">> %TEST_EVENT%
    echo   }>> %TEST_EVENT%
    echo }>> %TEST_EVENT%
    
    echo [INFO] Using test event for health check endpoint
    
    REM Invoke the function
    sam local invoke --event %TEST_EVENT% --env-vars %ENV_FILE% %DEBUG_FLAGS% TaskflowBackendFunction
    
    REM Cleanup
    del %TEST_EVENT%
)

REM Cleanup
del %ENV_FILE%

echo [SUCCESS] SAM Local session completed
goto :end

:show_usage
echo Usage: sam-local.bat [OPTIONS]
echo.
echo Options:
echo   --mode           Mode: api, invoke, or build [default: api]
echo   --port           Port for SAM local API [default: 3000]
echo   --dynamodb-local Use local DynamoDB instead of AWS [default: false]
echo   --environment    Environment profile [default: local]
echo   --debug          Enable debug mode [default: false]
echo   --help           Show this help message
echo.
echo Modes:
echo   api              Start local API Gateway (sam local start-api)
echo   invoke           Invoke function once (sam local invoke)
echo   build            Build only (sam build)
echo.
echo Examples:
echo   sam-local.bat                                    # Start API server on port 3000
echo   sam-local.bat --mode api --port 8080            # Start API server on port 8080
echo   sam-local.bat --mode invoke                     # Invoke function once
echo   sam-local.bat --dynamodb-local true             # Use local DynamoDB
echo.
exit /b 0

:end
