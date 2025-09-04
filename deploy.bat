@echo off
REM Taskflow Backend - AWS SAM Deployment Script for Windows
REM This script builds and deploys the Taskflow Backend to AWS Lambda

setlocal enabledelayedexpansion

REM Default values
set ENVIRONMENT=dev
set REGION=eu-central-1
set JWT_SECRET=
set CORS_ORIGINS=*
set STACK_NAME=

REM Parse command line arguments
:parse_args
if "%~1"=="" goto :check_environment
if "%~1"=="--environment" (
    set ENVIRONMENT=%~2
    shift
    shift
    goto :parse_args
)
if "%~1"=="--region" (
    set REGION=%~2
    shift
    shift
    goto :parse_args
)
if "%~1"=="--jwt-secret" (
    set JWT_SECRET=%~2
    shift
    shift
    goto :parse_args
)
if "%~1"=="--cors-origins" (
    set CORS_ORIGINS=%~2
    shift
    shift
    goto :parse_args
)
if "%~1"=="--stack-name" (
    set STACK_NAME=%~2
    shift
    shift
    goto :parse_args
)
if "%~1"=="--help" (
    goto :show_usage
)
echo Unknown option: %~1
goto :show_usage

:check_environment
REM Validate environment
if not "%ENVIRONMENT%"=="dev" if not "%ENVIRONMENT%"=="staging" if not "%ENVIRONMENT%"=="prod" (
    echo [ERROR] Invalid environment: %ENVIRONMENT%. Must be dev, staging, or prod.
    exit /b 1
)

REM Set default stack name if not provided
if "%STACK_NAME%"=="" (
    set STACK_NAME=taskflow-backend-%ENVIRONMENT%
)

REM Validate JWT secret for production
if "%ENVIRONMENT%"=="prod" if "%JWT_SECRET%"=="" (
    echo [ERROR] JWT secret is required for production deployment.
    echo Use: deploy.bat --environment prod --jwt-secret "your-super-secret-key"
    exit /b 1
)

REM Set default JWT secret for dev/staging if not provided
if "%JWT_SECRET%"=="" (
    set JWT_SECRET=your-super-secure-jwt-secret-key-that-is-at-least-256-bits-long-for-production-use
)

echo [INFO] Starting Taskflow Backend deployment...
echo [INFO] Environment: %ENVIRONMENT%
echo [INFO] Region: %REGION%
echo [INFO] Stack Name: %STACK_NAME%
echo [INFO] CORS Origins: %CORS_ORIGINS%

REM Check if AWS CLI is installed
aws --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] AWS CLI is not installed. Please install it first.
    exit /b 1
)

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

REM Check AWS credentials
echo [INFO] Checking AWS credentials...
aws sts get-caller-identity >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] AWS credentials not configured. Please run 'aws configure' first.
    exit /b 1
)

echo [SUCCESS] AWS credentials configured

REM Build the application
echo [INFO] Building the application...
call mvn clean package -DskipTests

if not exist "target\taskflow-backend-0.0.1-SNAPSHOT.jar" (
    echo [ERROR] Build failed - JAR file not found
    exit /b 1
)

echo [SUCCESS] Application built successfully

REM Get AWS Account ID for S3 bucket
for /f "tokens=*" %%i in ('aws sts get-caller-identity --query Account --output text') do set AWS_ACCOUNT_ID=%%i

REM Deploy with SAM
echo [INFO] Deploying to AWS...

sam deploy ^
    --template-file template.yaml ^
    --stack-name "%STACK_NAME%" ^
    --s3-bucket "sam-deployments-%REGION%-%AWS_ACCOUNT_ID%" ^
    --capabilities CAPABILITY_IAM ^
    --region "%REGION%" ^
    --parameter-overrides Environment="%ENVIRONMENT%" JwtSecret="%JWT_SECRET%" CorsAllowedOrigins="%CORS_ORIGINS%" ^
    --no-fail-on-empty-changeset

if %errorlevel% equ 0 (
    echo [SUCCESS] Deployment completed successfully!
    
    REM Get the API URL
    for /f "tokens=*" %%i in ('aws cloudformation describe-stacks --stack-name "%STACK_NAME%" --region "%REGION%" --query "Stacks[0].Outputs[?OutputKey==`TaskflowApi`].OutputValue" --output text') do set API_URL=%%i
    
    echo [SUCCESS] API Gateway URL: !API_URL!
    echo [INFO] You can test your API at: !API_URL!api/health/ping
    
    REM Display useful endpoints
    echo.
    echo [INFO] Useful endpoints:
    echo   Health Check: !API_URL!api/health/ping
    echo   Authentication: !API_URL!api/auth/register
    echo   Todos: !API_URL!api/todos
    echo.
    
) else (
    echo [ERROR] Deployment failed!
    exit /b 1
)

goto :end

:show_usage
echo Usage: deploy.bat [OPTIONS]
echo.
echo Options:
echo   --environment   Environment (dev, staging, prod) [default: dev]
echo   --region        AWS Region [default: eu-central-1]
echo   --jwt-secret    JWT Secret (required for production)
echo   --cors-origins  CORS allowed origins [default: *]
echo   --stack-name    CloudFormation stack name [default: taskflow-backend-{env}]
echo   --help          Show this help message
echo.
echo Examples:
echo   deploy.bat --environment dev
echo   deploy.bat --environment prod --jwt-secret "your-super-secret-key" --cors-origins "https://yourdomain.com"
echo.
exit /b 0

:end
