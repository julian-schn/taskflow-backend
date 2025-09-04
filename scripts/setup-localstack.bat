@echo off
REM LocalStack Lambda Setup Script for Windows
REM This script builds the application and registers it as a Lambda function in LocalStack

setlocal enabledelayedexpansion

REM Configuration
set FUNCTION_NAME=taskflow-backend
set RUNTIME=java17
set HANDLER=util.AwsLambdaHandler::handleRequest
set LOCALSTACK_ENDPOINT=http://localhost:4566
set REGION=eu-central-1
set JAR_PATH=target\taskflow-backend-0.0.1-SNAPSHOT.jar

echo [INFO] Setting up LocalStack Lambda function: %FUNCTION_NAME%

REM Check if LocalStack is running
echo [INFO] Checking if LocalStack is running...
curl -s "%LOCALSTACK_ENDPOINT%/health" >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] LocalStack is not running. Please start it with 'docker-compose up -d localstack'
    exit /b 1
)

echo [SUCCESS] LocalStack is running

REM Build the application
echo [INFO] Building the application...
call mvn clean package -DskipTests

if not exist "%JAR_PATH%" (
    echo [ERROR] Build failed - JAR file not found at %JAR_PATH%
    exit /b 1
)

echo [SUCCESS] Application built successfully

REM Create a ZIP file for Lambda deployment
echo [INFO] Creating deployment package...
set ZIP_PATH=target\taskflow-backend-lambda.zip
copy "%JAR_PATH%" "target\app.jar"
cd target
powershell Compress-Archive -Path app.jar -DestinationPath taskflow-backend-lambda.zip -Force
cd ..

REM Set AWS CLI to use LocalStack
set AWS_ACCESS_KEY_ID=test
set AWS_SECRET_ACCESS_KEY=test
set AWS_DEFAULT_REGION=%REGION%

REM Delete existing function if it exists
echo [INFO] Cleaning up existing Lambda function...
aws lambda delete-function --function-name "%FUNCTION_NAME%" --endpoint-url "%LOCALSTACK_ENDPOINT%" --region "%REGION%" 2>nul

REM Create IAM role for Lambda
echo [INFO] Creating IAM role for Lambda...
set ROLE_NAME=lambda-execution-role

REM Create trust policy
echo {> %TEMP%\trust-policy.json
echo   "Version": "2012-10-17",>> %TEMP%\trust-policy.json
echo   "Statement": [>> %TEMP%\trust-policy.json
echo     {>> %TEMP%\trust-policy.json
echo       "Effect": "Allow",>> %TEMP%\trust-policy.json
echo       "Principal": {>> %TEMP%\trust-policy.json
echo         "Service": "lambda.amazonaws.com">> %TEMP%\trust-policy.json
echo       },>> %TEMP%\trust-policy.json
echo       "Action": "sts:AssumeRole">> %TEMP%\trust-policy.json
echo     }>> %TEMP%\trust-policy.json
echo   ]>> %TEMP%\trust-policy.json
echo }>> %TEMP%\trust-policy.json

REM Create the role
aws iam create-role --role-name "%ROLE_NAME%" --assume-role-policy-document file://%TEMP%/trust-policy.json --endpoint-url "%LOCALSTACK_ENDPOINT%" --region "%REGION%" 2>nul

REM Attach basic execution policy
aws iam attach-role-policy --role-name "%ROLE_NAME%" --policy-arn "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" --endpoint-url "%LOCALSTACK_ENDPOINT%" --region "%REGION%" 2>nul

set ROLE_ARN=arn:aws:iam::000000000000:role/%ROLE_NAME%

REM Create the Lambda function
echo [INFO] Creating Lambda function...
aws lambda create-function ^
    --function-name "%FUNCTION_NAME%" ^
    --runtime "%RUNTIME%" ^
    --role "%ROLE_ARN%" ^
    --handler "%HANDLER%" ^
    --zip-file "fileb://%ZIP_PATH%" ^
    --timeout 30 ^
    --memory-size 1024 ^
    --environment Variables="{SPRING_PROFILES_ACTIVE=lambda,DYNAMODB_ENABLED=true,DYNAMODB_TABLE_NAME=todos,USERS_TABLE_NAME=users,AWS_DYNAMODB_ENDPOINT=http://localstack:4566,JWT_SECRET=local-development-jwt-secret-key,CORS_ALLOWED_ORIGINS=*}" ^
    --endpoint-url "%LOCALSTACK_ENDPOINT%" ^
    --region "%REGION%"

echo [SUCCESS] Lambda function created successfully

REM Create API Gateway
echo [INFO] Creating API Gateway...
set API_NAME=taskflow-api-local

REM Create REST API
for /f "tokens=*" %%i in ('aws apigateway create-rest-api --name "%API_NAME%" --endpoint-url "%LOCALSTACK_ENDPOINT%" --region "%REGION%" --query "id" --output text') do set API_ID=%%i

echo [INFO] Created API Gateway with ID: !API_ID!

REM Get root resource ID
for /f "tokens=*" %%i in ('aws apigateway get-resources --rest-api-id "!API_ID!" --endpoint-url "%LOCALSTACK_ENDPOINT%" --region "%REGION%" --query "items[0].id" --output text') do set ROOT_RESOURCE_ID=%%i

REM Create proxy resource
for /f "tokens=*" %%i in ('aws apigateway create-resource --rest-api-id "!API_ID!" --parent-id "!ROOT_RESOURCE_ID!" --path-part "{proxy+}" --endpoint-url "%LOCALSTACK_ENDPOINT%" --region "%REGION%" --query "id" --output text') do set PROXY_RESOURCE_ID=%%i

REM Create ANY method for proxy resource
aws apigateway put-method --rest-api-id "!API_ID!" --resource-id "!PROXY_RESOURCE_ID!" --http-method ANY --authorization-type NONE --endpoint-url "%LOCALSTACK_ENDPOINT%" --region "%REGION%"

REM Set up Lambda integration
set LAMBDA_URI=arn:aws:apigateway:%REGION%:lambda:path/2015-03-31/functions/arn:aws:lambda:%REGION%:000000000000:function:%FUNCTION_NAME%/invocations

aws apigateway put-integration --rest-api-id "!API_ID!" --resource-id "!PROXY_RESOURCE_ID!" --http-method ANY --type AWS_PROXY --integration-http-method POST --uri "%LAMBDA_URI%" --endpoint-url "%LOCALSTACK_ENDPOINT%" --region "%REGION%"

REM Create deployment
for /f "tokens=*" %%i in ('aws apigateway create-deployment --rest-api-id "!API_ID!" --stage-name local --endpoint-url "%LOCALSTACK_ENDPOINT%" --region "%REGION%" --query "id" --output text') do set DEPLOYMENT_ID=%%i

REM Add Lambda permission for API Gateway
aws lambda add-permission --function-name "%FUNCTION_NAME%" --statement-id "api-gateway-invoke" --action "lambda:InvokeFunction" --principal "apigateway.amazonaws.com" --source-arn "arn:aws:execute-api:%REGION%:000000000000:!API_ID!/*/*" --endpoint-url "%LOCALSTACK_ENDPOINT%" --region "%REGION%"

echo [SUCCESS] API Gateway configured successfully

REM Cleanup
del %TEMP%\trust-policy.json

set API_URL=http://localhost:4566/restapis/!API_ID!/local/_user_request_

echo [SUCCESS] LocalStack setup completed!
echo.
echo [INFO] Your Lambda function is now running in LocalStack!
echo.
echo [INFO] API Gateway URL: !API_URL!
echo [INFO] Lambda Function: %FUNCTION_NAME%
echo.
echo [INFO] Test endpoints:
echo   Health Check: curl !API_URL!/api/health/ping
echo   Register User: curl -X POST !API_URL!/api/auth/register -H "Content-Type: application/json" -d "{\"email\":\"test@test.com\",\"password\":\"password123\"}"
echo.
echo [WARNING] Note: Make sure DynamoDB Local is also running for full functionality
