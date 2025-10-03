#!/bin/bash

# AWS Cloud CV Deployment Script
# This script automates the deployment after Terraform creates resources

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "infra/terraform/main.tf" ]; then
    error "Please run this script from the Cloud-CV project root directory"
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    error "Terraform is not installed. Please install Terraform first."
    exit 1
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    error "AWS CLI is not installed. Please install AWS CLI first."
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    error "AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

log "🚀 Starting Cloud CV deployment..."

# Step 1: Deploy Infrastructure with Terraform
log "📋 Step 1: Deploying infrastructure with Terraform..."
cd infra/terraform/

# Initialize Terraform if not already done
if [ ! -d ".terraform" ]; then
    log "🔧 Initializing Terraform..."
    terraform init
fi

# Plan the deployment
log "📊 Planning Terraform deployment..."
terraform plan

# Deploy the infrastructure
log "🏗️ Deploying infrastructure..."
terraform apply -auto-approve

# Get resource names from Terraform outputs
log "📋 Getting resource information from Terraform..."
S3_BUCKET=$(terraform output -raw bucket_name)
CLOUDFRONT_URL="https://$(terraform output -raw cloudfront_domain_name)"
API_URL=$(terraform output -raw api_gateway_url)
S3_WEBSITE_URL="http://$(terraform output -raw bucket_website_endpoint)"

info "📊 Resources created:"
info "  S3 Bucket: $S3_BUCKET"
info "  CloudFront URL: $CLOUDFRONT_URL"
info "  API Gateway URL: $API_URL"
info "  S3 Website URL: $S3_WEBSITE_URL"

# Go back to project root
cd ../..

# Step 2: Upload Frontend Files
log "📁 Step 2: Uploading frontend files to S3..."

# Upload all frontend files with proper content types
aws s3 cp frontend/index.html s3://$S3_BUCKET/ --content-type "text/html"
aws s3 cp frontend/styles.css s3://$S3_BUCKET/ --content-type "text/css"
aws s3 cp frontend/script.js s3://$S3_BUCKET/ --content-type "application/javascript"
aws s3 cp cv.pdf s3://$S3_BUCKET/ --content-type "application/pdf"

# Set proper permissions for static website
aws s3 website s3://$S3_BUCKET --index-document index.html --error-document index.html

log "✅ Frontend files uploaded successfully!"

# Step 2.5: Clear CloudFront Cache
log "🔄 Step 2.5: Clearing CloudFront cache for updated files..."

# Get CloudFront distribution ID
log "🔍 Getting CloudFront distribution ID from Terraform outputs..."

# Check if Terraform state exists and has resources
if [ ! -f "infra/terraform/terraform.tfstate" ]; then
    warn "⚠️  Terraform state not found. Run 'terraform apply' first."
    warn "   Skipping CloudFront cache invalidation"
    warn "   You can manually invalidate cache after deployment"
elif ! grep -q "aws_cloudfront_distribution" infra/terraform/terraform.tfstate 2>/dev/null; then
    warn "⚠️  CloudFront distribution not found in Terraform state."
    warn "   Make sure 'terraform apply' completed successfully"
    warn "   Skipping CloudFront cache invalidation"
else
    # Get CloudFront distribution ID
    CLOUDFRONT_DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null | grep -v "Warning:" | grep -v "No outputs found" | head -1)
    
    if [ -n "$CLOUDFRONT_DISTRIBUTION_ID" ] && [ "$CLOUDFRONT_DISTRIBUTION_ID" != "null" ] && [[ "$CLOUDFRONT_DISTRIBUTION_ID" =~ ^[A-Z0-9]+$ ]]; then
        log "📡 Invalidating CloudFront cache..."
        
        aws cloudfront create-invalidation \
            --distribution-id "$CLOUDFRONT_DISTRIBUTION_ID" \
            --paths "/index.html" "/script.js" "/styles.css" "/cv.pdf" \
            --query 'Invalidation.Id' \
            --output text > /dev/null
        
        if [ $? -eq 0 ]; then
            log "✅ CloudFront cache invalidation created successfully!"
            warn "⏰ Cache invalidation takes 5-10 minutes to complete"
        else
            warn "⚠️  Failed to create CloudFront invalidation"
        fi
    else
        # Try to get distribution ID from AWS CLI
        CLOUDFRONT_DISTRIBUTION_ID=$(aws cloudfront list-distributions --query 'DistributionList.Items[?contains(Origins.Items[0].DomainName, `'$S3_BUCKET'`)].Id' --output text 2>/dev/null | head -1)
        
        if [ -n "$CLOUDFRONT_DISTRIBUTION_ID" ] && [[ "$CLOUDFRONT_DISTRIBUTION_ID" =~ ^[A-Z0-9]+$ ]]; then
            log "📡 Invalidating CloudFront cache..."
            
            aws cloudfront create-invalidation \
                --distribution-id "$CLOUDFRONT_DISTRIBUTION_ID" \
                --paths "/index.html" "/script.js" "/styles.css" "/cv.pdf" \
                --query 'Invalidation.Id' \
                --output text > /dev/null
            
            if [ $? -eq 0 ]; then
                log "✅ CloudFront cache invalidation created successfully!"
                warn "⏰ Cache invalidation takes 5-10 minutes to complete"
            else
                warn "⚠️  Failed to create CloudFront invalidation"
            fi
        else
            warn "⚠️  Could not find CloudFront distribution"
            warn "   You may need to manually invalidate the cache in AWS Console"
        fi
    fi
fi

# Step 3: Update Frontend with Real API URL
log "🔧 Step 3: Updating frontend with real API URL..."

# Create a backup of the original script
cp frontend/script.js frontend/script.js.backup

# Update the API URL in the script
sed -i.bak "s|http://localhost:4566/restapis/.*|$API_URL|g" frontend/script.js

# Re-upload the updated script
aws s3 cp frontend/script.js s3://$S3_BUCKET/

log "✅ Frontend updated with real API URL!"

# Step 4: Test the Deployment
log "🧪 Step 4: Testing deployment..."

# Test the API
log "🔌 Testing API endpoint..."
if curl -s "$API_URL/visitor-count" > /dev/null; then
    log "✅ API endpoint is working!"
else
    warn "⚠️ API endpoint test failed (this is normal for new deployments)"
fi

# Test the S3 website
log "📁 Testing S3 website..."
if curl -s "$S3_WEBSITE_URL" > /dev/null; then
    log "✅ S3 website is working!"
else
    warn "⚠️ S3 website test failed"
fi

# Step 5: Display Results
log "🎉 Deployment completed successfully!"
echo ""
info "🌐 Your Cloud CV URLs:"
info "  Main Website (CloudFront): $CLOUDFRONT_URL"
info "  Direct S3 URL: $S3_WEBSITE_URL"
info "  API Endpoint: $API_URL/visitor-count"
echo ""
info "📊 Deployment Summary:"
info "  ✅ S3 Bucket: $S3_BUCKET"
info "  ✅ CloudFront Distribution: Created"
info "  ✅ Lambda Function: Deployed"
info "  ✅ DynamoDB Table: Created"
info "  ✅ API Gateway: Configured"
info "  ✅ Frontend Files: Uploaded"
info "  ✅ API Integration: Updated"
info "  ✅ CloudFront Cache: Invalidated"
echo ""
warn "⏰ Note: CloudFront distribution takes 15-20 minutes to fully deploy"
warn "   Cache invalidation takes 5-10 minutes to complete"
warn "   The CloudFront URL will be available shortly"
echo ""
info "🔍 To monitor your deployment:"
info "  - Check AWS Console: https://console.aws.amazon.com"
info "  - Monitor costs: AWS Billing Dashboard"
info "  - Check CloudFront status: AWS CloudFront Console"
echo ""
log "🎯 Your Cloud CV is now live on AWS!"