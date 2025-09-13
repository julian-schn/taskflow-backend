# CI/CD Pipeline Setup Guide

This guide will help you set up a complete CI/CD pipeline for your Taskflow Backend project using GitHub Actions and AWS Lambda.

## 🚀 Overview

The CI/CD pipeline includes:
- **Continuous Integration**: Automated testing, security scanning, and code quality checks
- **Continuous Deployment**: Automated deployment to dev, staging, and production environments
- **Performance Testing**: Load testing with k6
- **Security Scanning**: OWASP dependency checks
- **Code Quality**: SonarCloud integration

## 📋 Prerequisites

### 1. GitHub Repository Setup
- [ ] Repository is hosted on GitHub
- [ ] Branch protection rules are configured
- [ ] Required status checks are enabled

### 2. AWS Account Setup
- [ ] AWS account with appropriate permissions
- [ ] AWS CLI configured locally
- [ ] SAM CLI installed

### 3. Required Tools
- [ ] Java 17+
- [ ] Maven 3.9+
- [ ] Git
- [ ] AWS CLI
- [ ] SAM CLI

## 🔧 GitHub Secrets Configuration

### Required Secrets

Navigate to your GitHub repository → Settings → Secrets and variables → Actions → Repository secrets

#### AWS Credentials
```
AWS_ACCESS_KEY_ID=your-aws-access-key
AWS_SECRET_ACCESS_KEY=your-aws-secret-key
```

#### JWT Secrets (Environment-specific)
```
JWT_SECRET_DEV=your-dev-jwt-secret
JWT_SECRET_STAGING=your-staging-jwt-secret
JWT_SECRET_PROD=your-production-jwt-secret
```

#### CORS Origins (Environment-specific)
```
CORS_ORIGINS_STAGING=https://staging.yourdomain.com
CORS_ORIGINS_PROD=https://yourdomain.com,https://www.yourdomain.com
```

#### Optional Secrets
```
SONAR_TOKEN=your-sonarcloud-token
SLACK_WEBHOOK_URL=your-slack-webhook-url
```

### Creating AWS IAM User

1. **Create IAM User**:
   ```bash
   aws iam create-user --user-name taskflow-cicd
   ```

2. **Attach Policies**:
   ```bash
   aws iam attach-user-policy --user-name taskflow-cicd --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
   ```

3. **Create Access Keys**:
   ```bash
   aws iam create-access-key --user-name taskflow-cicd
   ```

4. **Save the credentials** and add them to GitHub Secrets.

## 🌍 Environment Setup

### 1. GitHub Environments

Create the following environments in your GitHub repository:

1. Go to **Settings** → **Environments**
2. Create environments:
   - `development`
   - `staging` 
   - `production`

### 2. Environment Protection Rules

#### Development Environment
- **Required reviewers**: None (auto-deploy)
- **Wait timer**: 0 minutes
- **Deployment branches**: `develop` branch only

#### Staging Environment
- **Required reviewers**: 1 reviewer
- **Wait timer**: 0 minutes
- **Deployment branches**: `main` branch only

#### Production Environment
- **Required reviewers**: 2 reviewers
- **Wait timer**: 5 minutes
- **Deployment branches**: `main` branch only

## 🔄 Workflow Triggers

### Automatic Triggers
- **Push to `develop`**: Deploys to development
- **Push to `main`**: Deploys to staging
- **Pull Requests**: Runs tests and security scans

### Manual Triggers
- **Workflow Dispatch**: Deploy to any environment
- **Performance Testing**: Run load tests

## 📊 Pipeline Stages

### 1. Continuous Integration (CI)
```yaml
test → security-scan → code-quality
```

**What happens:**
- ✅ Run unit tests
- ✅ Generate test reports
- ✅ Build application JAR
- ✅ Upload build artifacts
- ✅ Security vulnerability scanning
- ✅ Code quality analysis

### 2. Continuous Deployment (CD)
```yaml
deploy-dev → deploy-staging → deploy-prod
```

**What happens:**
- ✅ Download build artifacts
- ✅ Configure AWS credentials
- ✅ Deploy using SAM CLI
- ✅ Run smoke tests
- ✅ Get API URLs
- ✅ Comment on PRs with deployment info

### 3. Performance Testing
```yaml
performance-test
```

**What happens:**
- ✅ Install k6 performance testing tool
- ✅ Create performance test scripts
- ✅ Run load tests against deployed API
- ✅ Generate performance reports
- ✅ Upload test results

## 🚀 Deployment Process

### Development Deployment
- **Trigger**: Push to `develop` branch
- **Environment**: `development`
- **Stack Name**: `taskflow-backend-dev`
- **CORS**: `*` (all origins allowed)
- **Auto-deploy**: Yes

### Staging Deployment
- **Trigger**: Push to `main` branch
- **Environment**: `staging`
- **Stack Name**: `taskflow-backend-staging`
- **CORS**: Restricted to staging domain
- **Approval**: 1 reviewer required

### Production Deployment
- **Trigger**: Manual workflow dispatch
- **Environment**: `production`
- **Stack Name**: `taskflow-backend-prod`
- **CORS**: Restricted to production domains
- **Approval**: 2 reviewers required
- **Wait Timer**: 5 minutes

## 🔍 Monitoring and Alerts

### GitHub Actions
- **Status Checks**: Required for merging PRs
- **Artifacts**: Build artifacts and test reports
- **Logs**: Detailed logs for each step

### AWS CloudWatch
- **Lambda Logs**: Application logs
- **API Gateway Logs**: Request/response logs
- **CloudFormation Events**: Deployment events

### Notifications
- **Slack**: Production deployment notifications
- **GitHub**: PR comments with deployment info
- **Email**: Workflow failure notifications

## 🛠️ Customization

### Adding New Environments
1. Update `samconfig.toml`
2. Add environment to GitHub Actions workflow
3. Create GitHub environment with protection rules
4. Add required secrets

### Modifying Test Thresholds
Edit the performance test thresholds in `.github/workflows/performance-test.yml`:
```yaml
thresholds: {
  http_req_duration: ['p(95)<2000'], # 95% of requests < 2s
  http_req_failed: ['rate<0.1'],     # Error rate < 10%
  error_rate: ['rate<0.05'],         # Custom error rate < 5%
}
```

### Adding New Tests
1. Add test files to `src/test/java/`
2. Update test configuration in `pom.xml`
3. Tests will run automatically in CI pipeline

## 🐛 Troubleshooting

### Common Issues

#### 1. AWS Credentials Error
```
Error: The security token included in the request is invalid
```
**Solution**: Check AWS credentials in GitHub Secrets

#### 2. SAM Deploy Failure
```
Error: Stack taskflow-backend-dev does not exist
```
**Solution**: Ensure stack name matches in `samconfig.toml`

#### 3. Build Failure
```
Error: Failed to execute goal org.apache.maven.plugins:maven-compiler-plugin
```
**Solution**: Check Java version compatibility

#### 4. Test Failure
```
Error: Tests failed
```
**Solution**: Check test logs and fix failing tests

### Debugging Steps

1. **Check GitHub Actions Logs**:
   - Go to Actions tab
   - Click on failed workflow
   - Review step logs

2. **Check AWS CloudFormation**:
   - Go to AWS Console → CloudFormation
   - Check stack events for errors

3. **Check Lambda Logs**:
   - Go to AWS Console → Lambda
   - Check CloudWatch logs

4. **Local Testing**:
   ```bash
   # Test locally
   mvn clean test
   
   # Deploy locally
   sam local start-api
   ```

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS SAM Documentation](https://docs.aws.amazon.com/serverless-application-model/)
- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [k6 Performance Testing](https://k6.io/docs/)

## 🤝 Contributing

When contributing to this project:
1. Create a feature branch from `develop`
2. Make your changes
3. Create a pull request
4. Ensure all CI checks pass
5. Request review from team members
6. Merge after approval

## 📞 Support

If you encounter issues with the CI/CD pipeline:
1. Check this guide first
2. Review GitHub Actions logs
3. Check AWS CloudFormation events
4. Create an issue in the repository
5. Contact the development team
