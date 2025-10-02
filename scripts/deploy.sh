#!/bin/bash
# Cloud CV - Deployment Script
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
ENVIRONMENT="production"
AWS_REGION="us-east-1"
DOMAIN_NAME=""
CERTIFICATE_ARN=""
DRY_RUN=false
SKIP_BUILD=false
SKIP_TERRAFORM=false
SKIP_DEPLOY=false

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

Deploy Cloud CV - SRE/DevOps Engineer Portfolio

OPTIONS:
    -e, --environment ENV     Environment (default: production)
    -r, --region REGION      AWS region (default: us-east-1)
    -d, --domain DOMAIN      Custom domain name
    -c, --certificate ARN    ACM certificate ARN
    --dry-run               Show what would be deployed
    --skip-build            Skip Docker build
    --skip-terraform        Skip Terraform deployment
    --skip-deploy           Skip application deployment
    -h, --help              Show this help message

EXAMPLES:
    $0                                          # Deploy to production
    $0 --environment staging                   # Deploy to staging
    $0 --domain myresume.com --certificate arn:aws:acm:...  # Deploy with custom domain
    $0 --dry-run                               # Show deployment plan

ENVIRONMENT VARIABLES:
    AWS_ACCESS_KEY_ID         AWS access key
    AWS_SECRET_ACCESS_KEY     AWS secret key
    AWS_REGION               AWS region (overrides -r)
    DOMAIN_NAME              Custom domain (overrides -d)
    CERTIFICATE_ARN          ACM certificate ARN (overrides -c)

EOF
}

check_dependencies() {
    log "Checking dependencies..."
    
    local deps=("aws" "terraform" "docker" "git")
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

build_docker_image() {
    if [ "$SKIP_BUILD" = true ]; then
        log "Skipping Docker build"
        return
    fi
    
    log "Building Docker image..."
    
    cd "$PROJECT_ROOT"
    
    # Build the image
    docker build -f docker/Dockerfile -t cloud-cv:latest .
    
    # Tag for ECR (if using ECR)
    if [ -n "${ECR_REGISTRY:-}" ]; then
        docker tag cloud-cv:latest "$ECR_REGISTRY/cloud-cv:latest"
        docker tag cloud-cv:latest "$ECR_REGISTRY/cloud-cv:$(git rev-parse --short HEAD)"
    fi
    
    success "Docker image built successfully"
}

deploy_infrastructure() {
    if [ "$SKIP_TERRAFORM" = true ]; then
        log "Skipping Terraform deployment"
        return
    fi
    
    log "Deploying infrastructure with Terraform..."
    
    cd "$TERRAFORM_DIR"
    
    # Initialize Terraform
    terraform init -upgrade
    
    # Validate configuration
    terraform validate
    
    # Plan deployment
    local plan_file="terraform.tfplan"
    terraform plan -out="$plan_file \
        -var="aws_region=$AWS_REGION" \
        -var="environment=$ENVIRONMENT" \
        -var="domain_name=$DOMAIN_NAME" \
        -var="certificate_arn=$CERTIFICATE_ARN"
    
    if [ "$DRY_RUN" = true ]; then
        log "Dry run completed. No changes applied."
        return
    fi
    
    # Apply changes
    terraform apply "$plan_file"
    
    # Get outputs
    local bucket_name
    bucket_name=$(terraform output -raw bucket_name)
    local cloudfront_domain
    cloudfront_domain=$(terraform output -raw cloudfront_domain_name)
    local api_gateway_url
    api_gateway_url=$(terraform output -raw api_gateway_url)
    
    # Export outputs for deployment
    export BUCKET_NAME="$bucket_name"
    export CLOUDFRONT_DOMAIN="$cloudfront_domain"
    export API_GATEWAY_URL="$api_gateway_url"
    
    success "Infrastructure deployed successfully"
    log "S3 Bucket: $bucket_name"
    log "CloudFront Domain: $cloudfront_domain"
    log "API Gateway URL: $api_gateway_url"
}

deploy_application() {
    if [ "$SKIP_DEPLOY" = true ]; then
        log "Skipping application deployment"
        return
    fi
    
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

cleanup() {
    log "Cleaning up temporary files..."
    
    # Remove backup files
    find "$FRONTEND_DIR" -name "*.bak" -delete 2>/dev/null || true
    
    success "Cleanup completed"
}

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -r|--region)
                AWS_REGION="$2"
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
            --skip-build)
                SKIP_BUILD=true
                shift
                ;;
            --skip-terraform)
                SKIP_TERRAFORM=true
                shift
                ;;
            --skip-deploy)
                SKIP_DEPLOY=true
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
    
    # Override with environment variables
    AWS_REGION="${AWS_REGION:-$AWS_REGION}"
    DOMAIN_NAME="${DOMAIN_NAME:-$DOMAIN_NAME}"
    CERTIFICATE_ARN="${CERTIFICATE_ARN:-$CERTIFICATE_ARN}"
    
    log "Starting Cloud CV deployment..."
    log "Environment: $ENVIRONMENT"
    log "AWS Region: $AWS_REGION"
    log "Domain: ${DOMAIN_NAME:-'default'}"
    log "Certificate: ${CERTIFICATE_ARN:-'default'}"
    
    # Set up trap for cleanup
    trap cleanup EXIT
    
    # Run deployment steps
    check_dependencies
    check_aws_credentials
    build_docker_image
    deploy_infrastructure
    deploy_application
    run_health_checks
    
    success "Deployment completed successfully!"
    
    if [ -n "${CLOUDFRONT_DOMAIN:-}" ]; then
        log "Website URL: https://$CLOUDFRONT_DOMAIN"
    fi
    
    if [ -n "${API_GATEWAY_URL:-}" ]; then
        log "API URL: $API_GATEWAY_URL"
    fi
}

# Run main function
main "$@"
