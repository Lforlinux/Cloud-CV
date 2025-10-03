# GitHub Actions CI/CD Setup

This document explains how to set up automated deployment for your Cloud CV project using GitHub Actions.

## 🚀 Overview

GitHub Actions will automatically:
- **Test** your code on every pull request
- **Deploy** to AWS when you push to main/master branch
- **Update** your Cloud CV website automatically
- **Invalidate** CloudFront cache for instant updates

## 📋 Prerequisites

1. **GitHub Repository**: Your code must be in a GitHub repository
2. **AWS Account**: With appropriate permissions
3. **AWS Credentials**: Access key and secret key

## 🔧 Setup Instructions

### Step 1: Create AWS IAM User

1. Go to AWS IAM Console
2. Create a new user (e.g., `cloud-cv-deploy`)
3. Attach the following policies:
   - `AmazonS3FullAccess`
   - `CloudFrontFullAccess`
   - `APIGatewayAdministrator`
   - `AWSLambdaFullAccess`
   - `AmazonDynamoDBFullAccess`
   - `IAMFullAccess`
   - `CloudWatchLogsFullAccess`

### Step 2: Add GitHub Secrets

In your GitHub repository, go to **Settings** → **Secrets and variables** → **Actions** and add:

```
AWS_ACCESS_KEY_ID: your-access-key-id
AWS_SECRET_ACCESS_KEY: your-secret-access-key
```

### Step 3: Push Your Code

```bash
git add .
git commit -m "Add GitHub Actions CI/CD"
git push origin main
```

## 🔄 Workflow Files

### 1. `ci-cd.yml` - Main Deployment Pipeline
- **Triggers**: Push to main/master, manual trigger
- **Jobs**: 
  - Test frontend files
  - Deploy to AWS
  - Update CloudFront cache

### 2. `deploy.yml` - Simple Deployment
- **Triggers**: Push to main/master, pull requests
- **Jobs**: Direct deployment without testing

### 3. `pr-check.yml` - Pull Request Validation
- **Triggers**: Pull requests only
- **Jobs**: Validate changes without deploying

## 🎯 How It Works

### On Pull Request:
1. **Validates** Terraform configuration
2. **Checks** frontend files exist
3. **Verifies** deployment scripts
4. **No deployment** (safe for testing)

### On Push to Main:
1. **Runs tests** (if configured)
2. **Deploys infrastructure** with Terraform
3. **Uploads files** to S3
4. **Updates API URLs** in frontend
5. **Invalidates CloudFront** cache
6. **Sets permissions** for website

## 🔍 Monitoring

### GitHub Actions Dashboard
- Go to your repository → **Actions** tab
- View workflow runs and logs
- Debug any failures

### AWS Console
- Check S3 bucket for uploaded files
- Monitor CloudFront distribution status
- View Lambda function logs
- Check API Gateway endpoints

## 🚨 Troubleshooting

### Common Issues:

1. **AWS Credentials Error**
   - Check if secrets are set correctly
   - Verify IAM user permissions

2. **Terraform Apply Fails**
   - Check AWS region settings
   - Verify S3 backend configuration

3. **CloudFront Not Working**
   - Wait 15-20 minutes for distribution
   - Check CloudFront console for status

4. **API Not Working**
   - Verify Lambda function deployed
   - Check API Gateway configuration
   - Test API endpoint directly

### Debug Steps:

1. **Check GitHub Actions logs**
2. **Test AWS CLI locally**
3. **Verify Terraform state in S3**
4. **Check CloudFront status**

## 🎉 Benefits

- **Automated Deployment**: No manual steps required
- **Consistent Environment**: Same deployment every time
- **Version Control**: Track all changes
- **Rollback Capability**: Easy to revert changes
- **Professional**: Shows DevOps skills to recruiters

## 📚 Next Steps

1. **Custom Domain**: Add Route53 configuration
2. **SSL Certificate**: Configure ACM
3. **Monitoring**: Add CloudWatch alarms
4. **Security**: Implement WAF rules
5. **Performance**: Add CloudFront optimizations

Your Cloud CV will now automatically deploy every time you push changes! 🚀
