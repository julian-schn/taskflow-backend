# 🚀 Taskflow Backend - AWS SAM Deployment Guide

This guide explains how to deploy your Taskflow Backend to AWS using AWS SAM (Serverless Application Model).

## 📋 Prerequisites

Before deploying, make sure you have:

1. **AWS Account** - Sign up at [aws.amazon.com](https://aws.amazon.com)
2. **AWS CLI** - [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
3. **SAM CLI** - [Installation Guide](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html)
4. **Java 17+** - Required for building the application
5. **Maven** - For building the Java application

## 🔧 Setup

### 1. Configure AWS Credentials

Run this command and enter your AWS credentials:
```bash
aws configure
```

You'll need:
- AWS Access Key ID
- AWS Secret Access Key  
- Default region (e.g., `eu-central-1`)
- Output format (use `json`)

### 2. Verify Prerequisites

Check that everything is installed:
```bash
# Check AWS CLI
aws --version

# Check SAM CLI
sam --version

# Check Java
java --version

# Check Maven
mvn --version
```

## 🚀 Deployment

### Quick Start (Development)

For a quick development deployment:

**Linux/Mac:**
```bash
./deploy.sh
```

**Windows:**
```batch
deploy.bat
```

### Production Deployment

For production deployment with custom settings:

**Linux/Mac:**
```bash
./deploy.sh \
  --environment prod \
  --jwt-secret "your-super-secure-production-jwt-secret-key-at-least-256-bits" \
  --cors-origins "https://yourdomain.com,https://app.yourdomain.com"
```

**Windows:**
```batch
deploy.bat --environment prod --jwt-secret "your-super-secure-production-jwt-secret-key-at-least-256-bits" --cors-origins "https://yourdomain.com,https://app.yourdomain.com"
```

### Manual Deployment

If you prefer manual control:

1. **Build the application:**
   ```bash
   mvn clean package -DskipTests
   ```

2. **Deploy with SAM:**
   ```bash
   sam deploy \
     --template-file template.yaml \
     --stack-name taskflow-backend-dev \
     --s3-bucket sam-deployments-eu-central-1-YOUR_AWS_ACCOUNT_ID \
     --capabilities CAPABILITY_IAM \
     --region eu-central-1 \
     --parameter-overrides \
       Environment=dev \
       JwtSecret="your-jwt-secret" \
       CorsAllowedOrigins="*"
   ```

## 🎯 What Gets Created

The deployment creates these AWS resources:

### 🔧 **Lambda Function**
- **Name**: `taskflow-backend-{environment}`
- **Runtime**: Java 17
- **Memory**: 1GB (optimized for Spring Boot)
- **Timeout**: 30 seconds
- **Handler**: `util.AwsLambdaHandler::handleRequest`

### 🌐 **API Gateway**
- **Type**: REST API
- **Stage**: `{environment}` (dev/staging/prod)
- **CORS**: Configured for your frontend
- **Routes**: All routes (`/{proxy+}`) forwarded to Lambda

### 🗄️ **DynamoDB Tables**
- **Todos Table**: `todos-{environment}`
  - Primary Key: `id` (String)
  - Global Secondary Index: `UserIdIndex` on `userId`
- **Users Table**: `users-{environment}`
  - Primary Key: `id` (String)  
  - Global Secondary Index: `EmailIndex` on `email`

### 📝 **CloudWatch Logs**
- Lambda function logs
- API Gateway access logs
- 14-day retention policy

## 🔗 Accessing Your API

After deployment, you'll get an API Gateway URL like:
```
https://abc123def4.execute-api.eu-central-1.amazonaws.com/dev/
```

### Available Endpoints:

- **Health Check**: `GET /api/health/ping`
- **Register User**: `POST /api/auth/register`
- **Login**: `POST /api/auth/login`
- **Get Todos**: `GET /api/todos`
- **Create Todo**: `POST /api/todos`
- **Update Todo**: `PUT /api/todos/{id}`
- **Delete Todo**: `DELETE /api/todos/{id}`

## 🧪 Testing Your Deployment

### 1. Health Check
```bash
curl https://YOUR_API_URL/api/health/ping
```
Should return: `{"status":"UP","timestamp":"..."}`

### 2. Register a User
```bash
curl -X POST https://YOUR_API_URL/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

### 3. Create a Todo
```bash
# First login to get a JWT token
TOKEN=$(curl -X POST https://YOUR_API_URL/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}' \
  | jq -r '.token')

# Create a todo
curl -X POST https://YOUR_API_URL/api/todos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"title":"My first todo","description":"Test todo from API"}'
```

## 🛠️ Customization Options

### Environment Variables

You can customize these parameters during deployment:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `Environment` | Deployment environment | `dev` |
| `JwtSecret` | JWT signing secret | Auto-generated |
| `CorsAllowedOrigins` | CORS allowed origins | `*` |

### Example Custom Deployment:
```bash
sam deploy \
  --parameter-overrides \
    Environment=staging \
    JwtSecret="my-super-secret-key" \
    CorsAllowedOrigins="https://myapp.com,https://staging.myapp.com"
```

## 🔧 Troubleshooting

### Common Issues:

1. **Build Fails**
   ```bash
   # Make sure Java 17+ is installed
   java --version
   
   # Clean and rebuild
   mvn clean package -DskipTests
   ```

2. **AWS Credentials Issue**
   ```bash
   # Reconfigure AWS CLI
   aws configure
   
   # Test credentials
   aws sts get-caller-identity
   ```

3. **SAM Deploy Fails**
   ```bash
   # Check if S3 bucket exists (SAM creates it automatically)
   aws s3 ls s3://sam-deployments-REGION-ACCOUNT_ID
   
   # Delete and redeploy if needed
   sam delete --stack-name taskflow-backend-dev
   ```

4. **Lambda Cold Start Issues**
   - The first request might take 10-15 seconds (cold start)
   - Subsequent requests will be much faster
   - Consider using AWS Lambda Provisioned Concurrency for production

### Logs and Monitoring:

1. **View Lambda Logs:**
   ```bash
   sam logs --stack-name taskflow-backend-dev --tail
   ```

2. **View CloudFormation Stack:**
   ```bash
   aws cloudformation describe-stacks --stack-name taskflow-backend-dev
   ```

## 🧹 Cleanup

To delete all AWS resources:

```bash
sam delete --stack-name taskflow-backend-dev
```

**⚠️ Warning**: This will permanently delete all data in your DynamoDB tables!

## 💰 Cost Estimation

**Development usage** (light testing):
- Lambda: ~$0.00 (free tier covers most development usage)
- API Gateway: ~$0.00-$1.00/month
- DynamoDB: ~$0.00 (free tier: 25GB storage, 25 WCU, 25 RCU)
- CloudWatch Logs: ~$0.00-$1.00/month

**Production usage** will depend on your traffic volume.

## 🎉 Next Steps

1. **Set up CI/CD** - Automate deployments with GitHub Actions
2. **Add Monitoring** - Set up CloudWatch alarms
3. **Custom Domain** - Add a custom domain to API Gateway
4. **Frontend Integration** - Update your frontend to use the new API URL
5. **Security** - Review IAM permissions and enable AWS WAF if needed

---

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review AWS CloudWatch logs
3. Consult the [AWS SAM documentation](https://docs.aws.amazon.com/serverless-application-model/)
