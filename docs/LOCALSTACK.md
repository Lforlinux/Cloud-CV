# Cloud CV - LocalStack Development Guide
# SRE/DevOps Engineer Portfolio

This guide covers using LocalStack for local AWS development, providing a cost-free and realistic AWS environment for testing and development.

## 🎯 What is LocalStack?

LocalStack is a fully functional local AWS cloud stack that runs on your machine. It provides:

- **Real AWS APIs**: Use actual AWS SDKs and CLI commands
- **Cost-Free Development**: No AWS charges during development
- **Offline Development**: Works without internet connection
- **Terraform Compatibility**: Works seamlessly with existing Terraform code
- **Realistic Testing**: Closer to production environment than mocks

## 🚀 Quick Start

### 1. Start LocalStack
```bash
# Start LocalStack development environment
./scripts/local-dev-start.sh start

# Or simply (start is the default)
./scripts/local-dev-start.sh
```

### 2. Upload Frontend Files
```bash
# Upload frontend files to S3
./scripts/local-dev-start.sh upload
```

### 3. Check Status
```bash
# Check LocalStack status
./scripts/local-dev-start.sh status
```

### 4. Stop LocalStack
```bash
# Stop LocalStack when done
./scripts/local-dev-start.sh stop
```

## 🏗️ LocalStack Architecture

### Services Included
- **S3**: Static website hosting
- **DynamoDB**: NoSQL database for visitor counter
- **Lambda**: Serverless visitor counter function
- **API Gateway**: REST API endpoint
- **IAM**: Identity and access management
- **CloudWatch**: Monitoring and logging

### LocalStack Configuration
```bash
# Services enabled
SERVICES=s3,dynamodb,lambda,apigateway,iam,cloudformation,sts

# Ports
- 4566: Main LocalStack API
- 4510-4559: Additional service ports
```

## 📋 Available Commands

### Start LocalStack
```bash
./scripts/local-dev-start.sh start
```
**What it does:**
- Starts LocalStack Docker container
- Creates S3 bucket (`cloud-cv-local`)
- Creates DynamoDB table (`visitor-counter`)
- Initializes visitor count
- Uploads frontend files
- Shows access URLs

### Stop LocalStack
```bash
./scripts/local-dev-start.sh stop
```
**What it does:**
- Stops LocalStack container
- Removes container
- Cleans up resources

### Restart LocalStack
```bash
./scripts/local-dev-start.sh restart
```
**What it does:**
- Stops existing LocalStack
- Starts fresh LocalStack
- Recreates all resources

### Upload Files
```bash
./scripts/local-dev-start.sh upload
```
**What it does:**
- Uploads frontend files to S3
- Updates existing files
- Preserves LocalStack state

### Check Status
```bash
./scripts/local-dev-start.sh status
```
**What it shows:**
- LocalStack container status
- Health check results
- Access URLs
- Service availability

## 🌐 Access URLs

### Website Access
- **Main Website**: http://localhost:4566/cloud-cv-local/index.html
- **S3 Browser**: http://localhost:4566/cloud-cv-local/
- **Health Check**: http://localhost:4566/_localstack/health

### Service Endpoints
- **S3**: http://localhost:4566
- **DynamoDB**: http://localhost:4566
- **Lambda**: http://localhost:4566
- **API Gateway**: http://localhost:4566

## 🔧 Development Workflow

### 1. Start Development Environment
```bash
# Start LocalStack
./scripts/local-dev-start.sh start
```

### 2. Make Changes
```bash
# Edit frontend files
nano frontend/index.html
nano frontend/styles.css
nano frontend/script.js
```

### 3. Upload Changes
```bash
# Upload updated files
./scripts/local-dev-start.sh upload
```

### 4. Test Changes
```bash
# Open browser
open http://localhost:4566/cloud-cv-local/index.html
```

### 5. Stop When Done
```bash
# Stop LocalStack
./scripts/local-dev-start.sh stop
```

## 🛠️ Troubleshooting

### LocalStack Not Starting
```bash
# Check if port 4566 is in use
lsof -i :4566

# Kill process using port
sudo kill -9 $(lsof -t -i:4566)

# Start LocalStack again
./scripts/local-dev-start.sh start
```

### Container Conflicts
```bash
# Remove existing containers
docker rm -f localstack

# Start fresh
./scripts/local-dev-start.sh start
```

### AWS CLI Issues
```bash
# Check AWS credentials
aws configure list

# Set LocalStack endpoint
export AWS_ENDPOINT_URL=http://localhost:4566

# Test S3 access
aws s3 ls --endpoint-url=http://localhost:4566
```

### Health Check Failures
```bash
# Check LocalStack logs
docker logs localstack

# Restart LocalStack
./scripts/local-dev-start.sh restart
```

## 📊 Monitoring

### LocalStack Health
```bash
# Check health status
curl http://localhost:4566/_localstack/health

# Expected response
{
  "services": {
    "s3": "running",
    "dynamodb": "running",
    "lambda": "running",
    "apigateway": "running"
  }
}
```

### Container Status
```bash
# Check container status
docker ps | grep localstack

# Check container logs
docker logs localstack
```

## 🔒 Security

### LocalStack Credentials
```bash
# Default LocalStack credentials
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test
AWS_DEFAULT_REGION=us-east-1
```

### Network Isolation
- LocalStack runs in Docker container
- Isolated from host network
- No external access required
- Safe for development

## 🚀 Advanced Usage

### Custom Services
```bash
# Start with specific services
docker run -d \
  --name localstack \
  -p 4566:4566 \
  -e SERVICES=s3,dynamodb \
  localstack/localstack:latest
```

### Persistent Data
```bash
# Mount volume for persistent data
docker run -d \
  --name localstack \
  -p 4566:4566 \
  -v /tmp/localstack:/tmp/localstack \
  localstack/localstack:latest
```

### Debug Mode
```bash
# Enable debug logging
docker run -d \
  --name localstack \
  -p 4566:4566 \
  -e DEBUG=1 \
  localstack/localstack:latest
```

## 📚 Best Practices

### 1. Use Profiles
```bash
# Start only needed services
SERVICES=s3,dynamodb
```

### 2. Persistent Data
```bash
# Use LocalStack persistence for data retention
```

### 3. Environment Variables
```bash
# Set AWS_ENDPOINT_URL globally
export AWS_ENDPOINT_URL=http://localhost:4566
```

### 4. Health Checks
```bash
# Always check LocalStack health before deploying
curl http://localhost:4566/_localstack/health
```

## 🤝 Contributing

### Development Setup
1. **Fork the repository**
2. **Create feature branch**: `git checkout -b feature/your-feature`
3. **Test with LocalStack**: `./scripts/local-dev-start.sh start`
4. **Make changes** and test locally
5. **Commit changes**: `git commit -m "Add your feature"`
6. **Push to branch**: `git push origin feature/your-feature`
7. **Create Pull Request**

### Code Standards
- **Shell Scripts**: Follow bash best practices
- **Documentation**: Clear and comprehensive
- **Testing**: Test with LocalStack before submitting
- **Error Handling**: Robust error handling and logging

---

*This guide demonstrates modern DevOps practices with local AWS development using LocalStack.*