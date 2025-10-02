# Cloud CV - SRE/DevOps Engineer Portfolio

A modern, cloud-hosted resume showcasing 15+ years of SRE/DevOps expertise with AWS best practices.

## 🏗️ Architecture

This project demonstrates enterprise-grade DevOps practices:

- **Infrastructure as Code**: Terraform for reproducible infrastructure
- **CI/CD Pipeline**: GitHub Actions for automated deployment
- **Containerization**: Docker for consistent environments
- **Serverless**: AWS Lambda for visitor counter
- **CDN**: CloudFront for global content delivery
- **Security**: SSL/TLS, IAM roles, least privilege access
- **Monitoring**: CloudWatch for observability

## 🚀 Features

- **One-Click Deployment**: Automated CI/CD pipeline
- **Visitor Counter**: Serverless Lambda function with DynamoDB
- **Global CDN**: CloudFront distribution for performance
- **SSL/TLS**: Automatic certificate management
- **Responsive Design**: Mobile-first approach
- **SEO Optimized**: Meta tags and structured data

## 🛠️ Tech Stack

### Frontend
- HTML5, CSS3, JavaScript (ES6+)
- Responsive design with CSS Grid/Flexbox
- Modern JavaScript with async/await
- Jekyll for dynamic content management

### Infrastructure
- **AWS S3**: Static website hosting
- **AWS CloudFront**: CDN and SSL termination
- **AWS Lambda**: Serverless visitor counter
- **AWS DynamoDB**: NoSQL database for visitor data
- **AWS Route53**: DNS management
- **AWS Certificate Manager**: SSL certificates
- **AWS IAM**: Security and access management

### DevOps Tools
- **Terraform**: Infrastructure as Code
- **GitHub Actions**: CI/CD pipeline
- **Docker**: Containerization
- **LocalStack**: Local AWS development
- **Git**: Version control

### Local Development
- **LocalStack**: AWS cloud emulation
- **Docker Compose**: Multi-service orchestration
- **Prometheus**: Metrics collection
- **Grafana**: Dashboards and visualization

## 📁 Project Structure

```
├── .github/workflows/     # GitHub Actions CI/CD
├── frontend/              # Static website files
├── infra/                 # Terraform infrastructure
│   ├── lambda/           # Lambda function code
│   └── terraform/        # Infrastructure definitions
├── docker/               # Docker configuration
├── docs/                 # Documentation
└── scripts/              # Deployment scripts
```

## 🚀 Quick Start

### Prerequisites
- AWS CLI configured
- Terraform >= 1.0
- Docker
- Node.js (for local development)

### Local Development
```bash
# Clone the repository
git clone <your-repo-url>
cd Cloud-CV

# Start local development environment
./scripts/local-dev.sh

# Start with LocalStack (AWS emulation)
./scripts/local-dev.sh --service localstack

# Deploy to LocalStack
./scripts/localstack-deploy.sh

# Access the site
open http://localhost:4000
```

### Deployment
```bash
# Initialize Terraform
cd infra/terraform
terraform init

# Plan the deployment
terraform plan

# Deploy the infrastructure
terraform apply
```

## 🔧 Configuration

### Environment Variables
Create a `.env` file:
```bash
AWS_REGION=us-east-1
DOMAIN_NAME=your-domain.com
BUCKET_NAME=your-resume-bucket
```

### GitHub Secrets
Configure these secrets in your GitHub repository:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`

## 📊 Monitoring

- **CloudWatch**: Application and infrastructure metrics
- **AWS X-Ray**: Distributed tracing
- **Cost Monitoring**: AWS Cost Explorer

## 🔒 Security

- **SSL/TLS**: Automatic certificate management
- **IAM Roles**: Least privilege access
- **VPC**: Network isolation (if needed)
- **WAF**: Web Application Firewall (optional)

## 🎯 Best Practices Demonstrated

1. **Infrastructure as Code**: All resources defined in Terraform
2. **GitOps**: Git-based deployment workflow
3. **Immutable Infrastructure**: No manual changes to production
4. **Security by Design**: IAM, encryption, least privilege
5. **Monitoring**: Comprehensive observability
6. **Cost Optimization**: Right-sized resources
7. **Disaster Recovery**: Multi-AZ deployment
8. **Performance**: CDN and caching strategies

## 📈 Performance

- **Lighthouse Score**: 95+ across all metrics
- **Core Web Vitals**: Optimized for user experience
- **Global CDN**: Sub-100ms response times
- **Compression**: Gzip/Brotli compression enabled

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**SRE/DevOps Engineer** with 15+ years of experience
- Website: [l4linux.com](https://l4linux.com)
- LinkedIn: [Your LinkedIn Profile]
- GitHub: [Your GitHub Profile]

---

*This project demonstrates modern DevOps practices and cloud architecture expertise.*
