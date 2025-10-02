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
# Start LocalStack with all services
./scripts/local-dev.sh --service localstack

# Or start everything including LocalStack
./scripts/local-dev.sh --service all
```

### 2. Deploy to LocalStack
```bash
# Deploy infrastructure and application
./scripts/localstack-deploy.sh

# Deploy with custom options
./scripts/localstack-deploy.sh --bucket my-bucket --region us-west-2
```

### 3. Access Services
- **LocalStack Dashboard**: http://localhost:4566
- **S3 Website**: http://localhost:4566/cloud-cv-local/index.html
- **API Endpoint**: Available after deployment

## 🏗️ LocalStack Architecture

### Services Included
- **S3**: Static website hosting
- **DynamoDB**: NoSQL database for visitor counter
- **Lambda**: Serverless visitor counter function
- **API Gateway**: REST API endpoint
- **IAM**: Identity and access management
- **CloudWatch**: Monitoring and logging
- **Route53**: DNS management
- **ACM**: Certificate management
- **CloudFront**: CDN simulation

### Port Mapping
- **LocalStack Gateway**: 4566
- **External Services**: 4510-4559
- **Frontend**: 4000
- **Dev Server**: 3000
- **Prometheus**: 9090
- **Grafana**: 3001

## 🛠️ Development Workflow

### 1. Start Development Environment
```bash
# Start all services
./scripts/local-dev.sh

# Start only LocalStack
./scripts/local-dev.sh --service localstack

# Start with monitoring
./scripts/local-dev.sh --service localstack monitoring
```

### 2. Deploy Infrastructure
```bash
# Deploy everything
./scripts/localstack-deploy.sh

# Deploy infrastructure only
./scripts/localstack-deploy.sh --skip-frontend

# Deploy frontend only
./scripts/localstack-deploy.sh --skip-terraform
```

### 3. Test and Develop
```bash
# Test API endpoint
curl http://localhost:4566/restapis/{api-id}/prod/_user_request_/visitor-count

# Test S3 website
curl http://localhost:4566/cloud-cv-local/index.html

# Check LocalStack health
curl http://localhost:4566/_localstack/health
```

## 🔧 AWS CLI with LocalStack

### Basic Commands
```bash
# Set endpoint for all commands
export AWS_ENDPOINT_URL=http://localhost:4566

# Or use --endpoint-url for individual commands
aws --endpoint-url=http://localhost:4566 s3 ls
aws --endpoint-url=http://localhost:4566 dynamodb list-tables
aws --endpoint-url=http://localhost:4566 lambda list-functions
aws --endpoint-url=http://localhost:4566 apigateway get-rest-apis
```

### S3 Operations
```bash
# List buckets
aws --endpoint-url=http://localhost:4566 s3 ls

# List objects in bucket
aws --endpoint-url=http://localhost:4566 s3 ls s3://cloud-cv-local

# Upload file
aws --endpoint-url=http://localhost:4566 s3 cp file.txt s3://cloud-cv-local/

# Download file
aws --endpoint-url=http://localhost:4566 s3 cp s3://cloud-cv-local/file.txt ./
```

### DynamoDB Operations
```bash
# List tables
aws --endpoint-url=http://localhost:4566 dynamodb list-tables

# Describe table
aws --endpoint-url=http://localhost:4566 dynamodb describe-table --table-name cloud-cv-visitor-counter

# Put item
aws --endpoint-url=http://localhost:4566 dynamodb put-item \
    --table-name cloud-cv-visitor-counter \
    --item '{"id":{"S":"test"},"count":{"N":"1"}}'

# Get item
aws --endpoint-url=http://localhost:4566 dynamodb get-item \
    --table-name cloud-cv-visitor-counter \
    --key '{"id":{"S":"test"}}'
```

### Lambda Operations
```bash
# List functions
aws --endpoint-url=http://localhost:4566 lambda list-functions

# Invoke function
aws --endpoint-url=http://localhost:4566 lambda invoke \
    --function-name cloud-cv-visitor-counter \
    --payload '{}' \
    response.json

# Get function logs
aws --endpoint-url=http://localhost:4566 logs describe-log-groups
```

## 🏗️ Terraform with LocalStack

### LocalStack Provider Configuration
```hcl
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  
  endpoints {
    s3         = "http://localhost:4566"
    dynamodb   = "http://localhost:4566"
    lambda     = "http://localhost:4566"
    apigateway = "http://localhost:4566"
    # ... other endpoints
  }
}
```

### Deploy Infrastructure
```bash
# Navigate to Terraform directory
cd infra/terraform

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var="aws_region=us-east-1" -var="environment=local"

# Apply changes
terraform apply -var="aws_region=us-east-1" -var="environment=local"
```

### View Resources
```bash
# List all resources
terraform state list

# Show specific resource
terraform state show aws_s3_bucket.website

# Get outputs
terraform output
```

## 🐳 Docker Compose Services

### LocalStack Service
```yaml
localstack:
  image: localstack/localstack:latest
  container_name: cloud-cv-localstack
  ports:
    - "4566:4566"
    - "4510-4559:4510-4559"
  environment:
    - SERVICES=s3,cloudfront,lambda,dynamodb,apigateway,iam,cloudwatch,logs,route53,acm
    - DEBUG=1
    - PERSISTENCE=1
    - LAMBDA_EXECUTOR=docker
  volumes:
    - "${TMPDIR:-/tmp/}localstack:/tmp/localstack"
    - "/var/run/docker.sock:/var/run/docker.sock"
```

### LocalStack Init Service
```yaml
localstack-init:
  image: amazon/aws-cli:latest
  container_name: cloud-cv-localstack-init
  depends_on:
    - localstack
  environment:
    - AWS_ENDPOINT_URL=http://localstack:4566
  command: ["/bin/bash", "/scripts/init.sh"]
```

## 📊 Monitoring and Debugging

### LocalStack Health Check
```bash
# Check health
curl http://localhost:4566/_localstack/health

# Check specific services
curl http://localhost:4566/_localstack/health | jq '.services'
```

### View Logs
```bash
# LocalStack logs
docker logs cloud-cv-localstack

# LocalStack init logs
docker logs cloud-cv-localstack-init

# Follow logs
docker logs -f cloud-cv-localstack
```

### Debugging
```bash
# Enable debug mode
export DEBUG=1

# Check service status
curl http://localhost:4566/_localstack/health

# List all services
curl http://localhost:4566/_localstack/health | jq '.services | keys'
```

## 🔄 Development Workflow

### 1. Start Development Environment
```bash
# Start LocalStack
./scripts/local-dev.sh --service localstack

# Wait for LocalStack to be ready
sleep 30
```

### 2. Deploy Infrastructure
```bash
# Deploy with Terraform
./scripts/localstack-deploy.sh

# Or deploy manually
cd infra/terraform
terraform apply -var="aws_region=us-east-1" -var="environment=local"
```

### 3. Deploy Application
```bash
# Deploy frontend
./scripts/localstack-deploy.sh --skip-terraform

# Or deploy manually
aws --endpoint-url=http://localhost:4566 s3 cp frontend/index.html s3://cloud-cv-local/
```

### 4. Test and Iterate
```bash
# Test API
curl http://localhost:4566/restapis/{api-id}/prod/_user_request_/visitor-count

# Test website
curl http://localhost:4566/cloud-cv-local/index.html

# Make changes and redeploy
./scripts/localstack-deploy.sh
```

## 🚨 Troubleshooting

### Common Issues

#### LocalStack Not Starting
```bash
# Check Docker is running
docker ps

# Check LocalStack logs
docker logs cloud-cv-localstack

# Restart LocalStack
./scripts/local-dev.sh --service localstack --clean
./scripts/local-dev.sh --service localstack
```

#### Terraform Errors
```bash
# Check LocalStack is running
curl http://localhost:4566/_localstack/health

# Clean Terraform state
cd infra/terraform
terraform destroy
terraform init
terraform apply
```

#### API Gateway Issues
```bash
# Check API Gateway
aws --endpoint-url=http://localhost:4566 apigateway get-rest-apis

# Check Lambda function
aws --endpoint-url=http://localhost:4566 lambda list-functions

# Test API endpoint
curl http://localhost:4566/restapis/{api-id}/prod/_user_request_/visitor-count
```

#### S3 Issues
```bash
# Check S3 buckets
aws --endpoint-url=http://localhost:4566 s3 ls

# Check bucket contents
aws --endpoint-url=http://localhost:4566 s3 ls s3://cloud-cv-local

# Test website
curl http://localhost:4566/cloud-cv-local/index.html
```

### Performance Issues
```bash
# Check LocalStack resources
docker stats cloud-cv-localstack

# Increase Docker memory if needed
# Docker Desktop -> Settings -> Resources -> Memory
```

## 🎯 Best Practices

### Development
1. **Use Profiles**: Start only needed services
2. **Persistent Data**: Use LocalStack persistence for data retention
3. **Environment Variables**: Set AWS_ENDPOINT_URL globally
4. **Health Checks**: Always check LocalStack health before deploying

### Testing
1. **Automated Tests**: Use LocalStack in CI/CD pipelines
2. **Isolated Tests**: Each test should use clean state
3. **Mock Data**: Use realistic test data
4. **Error Testing**: Test error scenarios

### Production Parity
1. **Same Terraform**: Use identical Terraform for local and production
2. **Environment Variables**: Use same environment variables
3. **Resource Naming**: Use consistent naming conventions
4. **Monitoring**: Test monitoring and alerting

## 📚 Additional Resources

- [LocalStack Documentation](https://docs.localstack.cloud/)
- [LocalStack GitHub](https://github.com/localstack/localstack)
- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)

## 🤝 Contributing

This LocalStack integration demonstrates:
- **Infrastructure as Code**: Terraform with LocalStack
- **Local Development**: Cost-free AWS development
- **CI/CD Testing**: Automated testing with LocalStack
- **Production Parity**: Identical local and production environments

---

*LocalStack provides a powerful local AWS development environment that enables cost-free, realistic testing and development.*
