#!/bin/bash
# Cloud CV - AWS Deployment Script
# SRE/DevOps Engineer Portfolio

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/infra/terraform"
FRONTEND_DIR="$PROJECT_ROOT/frontend"

# Default values
AWS_REGION="us-east-1"
ENVIRONMENT="production"
DOMAIN_NAME=""
CERTIFICATE_ARN=""
DRY_RUN=false

# Functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy Cloud CV to AWS

OPTIONS:
    -r, --region REGION      AWS region (default: us-east-1)
    -e, --environment ENV    Environment (default: production)
    -d, --domain DOMAIN      Custom domain name
    -c, --certificate ARN    ACM certificate ARN
    --dry-run               Show what would be deployed
    -h, --help              Show this help message

EXAMPLES:
    $0                                          # Deploy to production
    $0 --domain myresume.com --certificate arn:aws:acm:...  # Deploy with custom domain
    $0 --dry-run                               # Show deployment plan

EOF
}

check_dependencies() {
    log "Checking dependencies..."
    
    local deps=("aws" "terraform")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        error "Missing dependencies: ${missing[*]}"
    fi
    
    success "All dependencies found"
}

check_aws_credentials() {
    log "Checking AWS credentials..."
    
    if ! aws sts get-caller-identity &> /dev/null; then
        error "AWS credentials not configured. Please run 'aws configure' or set environment variables."
    fi
    
    local caller_identity
    caller_identity=$(aws sts get-caller-identity)
    local account_id
    account_id=$(echo "$caller_identity" | jq -r '.Account')
    local user_arn
    user_arn=$(echo "$caller_identity" | jq -r '.Arn')
    
    log "AWS Account: $account_id"
    log "AWS User: $user_arn"
    
    success "AWS credentials verified"
}

deploy_infrastructure() {
    log "Deploying infrastructure with Terraform..."
    
    cd "$TERRAFORM_DIR"
    
    # Initialize Terraform
    terraform init
    
    # Validate configuration
    terraform validate
    
    # Plan deployment
    terraform plan \
        -var="aws_region=$AWS_REGION" \
        -var="environment=$ENVIRONMENT" \
        -var="domain_name=$DOMAIN_NAME" \
        -var="certificate_arn=$CERTIFICATE_ARN"
    
    if [ "$DRY_RUN" = true ]; then
        log "Dry run completed. No changes applied."
        return
    fi
    
    # Apply changes
    terraform apply -auto-approve \
        -var="aws_region=$AWS_REGION" \
        -var="environment=$ENVIRONMENT" \
        -var="domain_name=$DOMAIN_NAME" \
        -var="certificate_arn=$CERTIFICATE_ARN"
    
    # Get outputs
    local bucket_name
    bucket_name=$(terraform output -raw bucket_name)
    local cloudfront_domain
    cloudfront_domain=$(terraform output -raw cloudfront_domain_name)
    local api_gateway_url
    api_gateway_url=$(terraform output -raw api_gateway_url)
    
    # Export outputs
    export BUCKET_NAME="$bucket_name"
    export CLOUDFRONT_DOMAIN="$cloudfront_domain"
    export API_GATEWAY_URL="$api_gateway_url"
    
    success "Infrastructure deployed successfully"
    log "S3 Bucket: $bucket_name"
    log "CloudFront Domain: $cloudfront_domain"
    log "API Gateway URL: $api_gateway_url"
}

deploy_application() {
    log "Deploying application..."
    
    # Check if we have the required variables
    if [ -z "${BUCKET_NAME:-}" ]; then
        error "BUCKET_NAME not set. Run infrastructure deployment first."
    fi
    
    # Update frontend with API URL
    if [ -n "${API_GATEWAY_URL:-}" ]; then
        log "Updating frontend with API URL: $API_GATEWAY_URL"
        
        # Update script.js
        if [ -f "$FRONTEND_DIR/script.js" ]; then
            sed -i.bak "s|this.apiUrl = '';|this.apiUrl = '$API_GATEWAY_URL';|g" "$FRONTEND_DIR/script.js"
        fi
        
        # Update index.html
        if [ -f "$FRONTEND_DIR/index.html" ]; then
            sed -i.bak "s|<meta name=\"api-url\" content=\"\">|<meta name=\"api-url\" content=\"$API_GATEWAY_URL\">|g" "$FRONTEND_DIR/index.html"
        fi
    fi
    
    # Sync files to S3
    log "Syncing files to S3 bucket: $BUCKET_NAME"
    
    # Sync static assets with long cache
    aws s3 sync "$FRONTEND_DIR/" "s3://$BUCKET_NAME" \
        --delete \
        --cache-control "max-age=31536000" \
        --exclude "*.html" \
        --exclude "*.css" \
        --exclude "*.js"
    
    # Sync HTML files with shorter cache
    aws s3 sync "$FRONTEND_DIR/" "s3://$BUCKET_NAME" \
        --delete \
        --cache-control "max-age=3600" \
        --include "*.html"
    
    # Sync CSS and JS files
    aws s3 sync "$FRONTEND_DIR/" "s3://$BUCKET_NAME" \
        --delete \
        --cache-control "max-age=86400" \
        --include "*.css" \
        --include "*.js"
    
    # Invalidate CloudFront cache
    if [ -n "${CLOUDFRONT_DOMAIN:-}" ]; then
        local distribution_id
        distribution_id=$(aws cloudfront list-distributions \
            --query "DistributionList.Items[?DomainName=='$CLOUDFRONT_DOMAIN'].Id" \
            --output text)
        
        if [ -n "$distribution_id" ]; then
            log "Invalidating CloudFront cache for distribution: $distribution_id"
            aws cloudfront create-invalidation \
                --distribution-id "$distribution_id" \
                --paths "/*"
        fi
    fi
    
    success "Application deployed successfully"
}

run_health_checks() {
    log "Running health checks..."
    
    if [ -n "${CLOUDFRONT_DOMAIN:-}" ]; then
        local url="https://$CLOUDFRONT_DOMAIN"
        
        # Wait for CloudFront propagation
        log "Waiting for CloudFront propagation (this may take a few minutes)..."
        sleep 30
        
        # Test main page
        if curl -f -s "$url/" > /dev/null; then
            success "Main page is accessible"
        else
            warning "Main page health check failed"
        fi
        
        # Test API endpoint
        if [ -n "${API_GATEWAY_URL:-}" ]; then
            if curl -f -s "$API_GATEWAY_URL" > /dev/null; then
                success "API endpoint is accessible"
            else
                warning "API endpoint health check failed"
            fi
        fi
    fi
}

show_access_urls() {
    log "Deployment completed successfully!"
    echo ""
    echo "🌐 Website Access URLs:"
    echo ""
    
    if [ -n "${CLOUDFRONT_DOMAIN:-}" ]; then
        echo "  🚀 CloudFront CDN (Recommended):"
        echo "     https://$CLOUDFRONT_DOMAIN"
        echo ""
    fi
    
    if [ -n "${BUCKET_NAME:-}" ]; then
        echo "  📦 S3 Website (Direct):"
        echo "     http://$BUCKET_NAME.s3-website-$AWS_REGION.amazonaws.com"
        echo ""
    fi
    
    if [ -n "${API_GATEWAY_URL:-}" ]; then
        echo "  🔌 API Endpoint:"
        echo "     $API_GATEWAY_URL"
        echo ""
    fi
    
    echo "📊 AWS Console URLs:"
    echo "  S3 Bucket:        https://s3.console.aws.amazon.com/s3/buckets/$BUCKET_NAME"
    echo "  CloudFront:       https://console.aws.amazon.com/cloudfront/v3/home"
    echo "  Lambda:           https://console.aws.amazon.com/lambda/home"
    echo "  DynamoDB:        https://console.aws.amazon.com/dynamodb/home"
    echo "  API Gateway:      https://console.aws.amazon.com/apigateway/home"
    echo ""
    
    if [ -n "${CLOUDFRONT_DOMAIN:-}" ]; then
        echo "🎉 Your Cloud CV is now live at:"
        echo "   https://$CLOUDFRONT_DOMAIN"
        echo ""
        echo "💡 Pro tip: CloudFront may take 5-15 minutes to fully propagate globally."
        echo "   If you get a 404 error, wait a few minutes and try again."
    fi
}

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--region)
                AWS_REGION="$2"
                shift 2
                ;;
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -d|--domain)
                DOMAIN_NAME="$2"
                shift 2
                ;;
            -c|--certificate)
                CERTIFICATE_ARN="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done
    
    log "Starting Cloud CV AWS deployment..."
    log "Region: $AWS_REGION"
    log "Environment: $ENVIRONMENT"
    log "Domain: ${DOMAIN_NAME:-'default'}"
    log "Certificate: ${CERTIFICATE_ARN:-'default'}"
    
    # Run deployment steps
    check_dependencies
    check_aws_credentials
    deploy_infrastructure
    deploy_application
    run_health_checks
    show_access_urls
    
    success "AWS deployment completed successfully!"
}

# Run main function
main "$@"
