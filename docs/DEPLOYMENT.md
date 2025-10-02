# Cloud CV - Deployment Guide
# SRE/DevOps Engineer Portfolio

This guide covers deploying the Cloud CV project using AWS best practices, Terraform, Docker, and CI/CD pipelines.

## 🏗️ Architecture Overview

The Cloud CV project demonstrates modern DevOps practices with the following components:

- **Frontend**: Static website hosted on S3 with CloudFront CDN
- **Backend**: Serverless Lambda function for visitor counter
- **Database**: DynamoDB for visitor data storage
- **Infrastructure**: Terraform for Infrastructure as Code
- **CI/CD**: GitHub Actions for automated deployment
- **Monitoring**: CloudWatch for observability
- **Security**: IAM roles, SSL/TLS, and security best practices

## 📋 Prerequisites

### Required Tools
- AWS CLI v2
- Terraform >= 1.0
- Docker
- Git
- Node.js (for local development)

### AWS Account Setup
1. Create an AWS account
2. Configure AWS CLI: `aws configure`
3. Create an IAM user with appropriate permissions
4. Set up Route53 hosted zone (if using custom domain)

### GitHub Repository Setup
1. Fork or clone this repository
2. Set up GitHub Secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_REGION`

## 🚀 Quick Start

### 1. Clone and Setup
```bash
git clone <your-repo-url>
cd Cloud-CV
```

### 2. Configure Environment
```bash
# Copy environment template
cp .env.example .env

# Edit configuration
nano .env
```

### 3. Deploy Infrastructure
```bash
# Navigate to Terraform directory
cd infra/terraform

# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Deploy infrastructure
terraform apply
```

### 4. Deploy Application
```bash
# Run deployment script
./scripts/deploy.sh

# Or deploy manually
aws s3 sync frontend/ s3://your-bucket-name
```

## 🔧 Configuration

### Environment Variables

Create a `.env` file in the project root:

```bash
# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key

# Application Configuration
DOMAIN_NAME=your-domain.com
CERTIFICATE_ARN=arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012
ENVIRONMENT=production

# Monitoring
ALERT_EMAIL=your-email@example.com
```

### Terraform Variables

Create `terraform.tfvars`:

```hcl
aws_region = "us-east-1"
environment = "production"
domain_name = "your-domain.com"
certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
alert_email = "your-email@example.com"
```

## 🐳 Docker Development

### Local Development
```bash
# Start development environment
./scripts/local-dev.sh

# Start specific services
./scripts/local-dev.sh --service frontend
./scripts/local-dev.sh --service monitoring
./scripts/local-dev.sh --service localstack

# Build and start
./scripts/local-dev.sh --build --detach
```

### Docker Compose Services
- **Frontend**: Nginx-based web server (port 4000)
- **Dev Server**: Node.js development server (port 3000)
- **Prometheus**: Metrics collection (port 9090)
- **Grafana**: Dashboards (port 3001)
- **LocalStack**: AWS cloud emulation (port 4566)

### LocalStack Development
```bash
# Start LocalStack with AWS services
./scripts/local-dev.sh --service localstack

# Deploy to LocalStack
./scripts/localstack-deploy.sh

# Deploy with custom options
./scripts/localstack-deploy.sh --bucket my-bucket --region us-west-2
```

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow

The project includes a comprehensive CI/CD pipeline:

1. **Quality Checks**: Code quality, security scanning
2. **Build**: Docker image build and push to ECR
3. **Infrastructure**: Terraform deployment
4. **Application**: S3 sync and CloudFront invalidation
5. **Testing**: Health checks and performance tests
6. **Monitoring**: Alerting and notifications

### Manual Deployment

```bash
# Deploy everything
./scripts/deploy.sh

# Deploy with custom options
./scripts/deploy.sh --environment staging --domain staging.example.com

# Dry run
./scripts/deploy.sh --dry-run
```

## 📊 Monitoring and Observability

### CloudWatch Dashboard
- Lambda metrics (invocations, errors, duration)
- DynamoDB metrics (throttles, capacity)
- CloudFront metrics (requests, errors)
- Custom visitor count metrics

### Alerts
- Lambda errors and duration
- DynamoDB throttles
- CloudFront 4xx/5xx errors
- Monthly cost monitoring

### Logs
- Lambda execution logs
- API Gateway logs
- CloudFront access logs
- Application logs

## 🔒 Security

### IAM Roles
- Least privilege access
- Separate roles for different services
- No hardcoded credentials

### Network Security
- HTTPS only (TLS 1.2+)
- CloudFront security headers
- CORS configuration
- Rate limiting

### Data Protection
- S3 bucket encryption
- DynamoDB encryption at rest
- Secure parameter storage
- No sensitive data in code

## 🚨 Troubleshooting

### Common Issues

#### Terraform Errors
```bash
# Clean state and retry
terraform init -upgrade
terraform plan
terraform apply
```

#### Docker Issues
```bash
# Clean Docker environment
docker system prune -a
docker-compose down -v
```

#### AWS Permissions
```bash
# Check AWS credentials
aws sts get-caller-identity

# Test S3 access
aws s3 ls
```

#### CloudFront Issues
```bash
# Check distribution status
aws cloudfront get-distribution --id YOUR_DISTRIBUTION_ID

# Create invalidation
aws cloudfront create-invalidation --distribution-id YOUR_DISTRIBUTION_ID --paths "/*"
```

#### LocalStack Issues
```bash
# Check LocalStack health
curl http://localhost:4566/_localstack/health

# Check LocalStack logs
docker logs cloud-cv-localstack

# Restart LocalStack
./scripts/local-dev.sh --service localstack --clean
./scripts/local-dev.sh --service localstack

# Deploy to LocalStack
./scripts/localstack-deploy.sh
```

### Health Checks

```bash
# Check website
curl -I https://your-domain.com

# Check API
curl https://your-api-gateway-url.amazonaws.com/prod/visitor-count

# Check CloudWatch logs
aws logs describe-log-groups
```

## 📈 Performance Optimization

### Frontend Optimization
- Gzip compression
- Browser caching
- Image optimization
- Minification

### Infrastructure Optimization
- CloudFront caching
- S3 transfer acceleration
- Lambda optimization
- DynamoDB capacity planning

### Cost Optimization
- Right-sized resources
- Reserved capacity
- Lifecycle policies
- Cost monitoring

## 🔄 Updates and Maintenance

### Regular Tasks
- Update dependencies
- Security patches
- Performance monitoring
- Cost optimization

### Backup Strategy
- Terraform state backup
- S3 versioning
- DynamoDB backups
- Configuration backups

## 📚 Additional Resources

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

*This deployment guide demonstrates modern DevOps practices and cloud architecture expertise.*
