#!/bin/bash
# Cloud CV - LocalStack Deployment Script
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
ENVIRONMENT="local"
BUCKET_NAME="cloud-cv-local"
TABLE_NAME="cloud-cv-visitor-counter"
FUNCTION_NAME="cloud-cv-visitor-counter"

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

Deploy Cloud CV to LocalStack for local development

OPTIONS:
    -r, --region REGION      AWS region (default: us-east-1)
    -e, --environment ENV    Environment (default: local)
    -b, --bucket BUCKET      S3 bucket name (default: cloud-cv-local)
    --skip-terraform         Skip Terraform deployment
    --skip-frontend          Skip frontend deployment
    -h, --help              Show this help message

EXAMPLES:
    $0                                          # Deploy everything to LocalStack
    $0 --skip-terraform                         # Skip Terraform, deploy frontend only
    $0 --bucket my-bucket                       # Use custom bucket name

ENVIRONMENT VARIABLES:
    AWS_ENDPOINT_URL         LocalStack endpoint (default: http://localhost:4566)
    AWS_ACCESS_KEY_ID        AWS access key (default: test)
    AWS_SECRET_ACCESS_KEY    AWS secret key (default: test)

EOF
}

check_dependencies() {
    log "Checking dependencies..."
    
    local deps=("aws" "terraform" "docker")
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

check_localstack() {
    log "Checking LocalStack availability..."
    
    if ! curl -f -s http://localhost:4566/_localstack/health > /dev/null 2>&1; then
        error "LocalStack is not running. Please start it first with: ./scripts/local-dev.sh --service localstack"
    fi
    
    success "LocalStack is running"
}

setup_aws_credentials() {
    log "Setting up AWS credentials for LocalStack..."
    
    export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-test}"
    export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-test}"
    export AWS_DEFAULT_REGION="$AWS_REGION"
    export AWS_ENDPOINT_URL="${AWS_ENDPOINT_URL:-http://localhost:4566}"
    
    success "AWS credentials configured for LocalStack"
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
        -var="bucket_name=$BUCKET_NAME" \
        -var="table_name=$TABLE_NAME" \
        -var="function_name=$FUNCTION_NAME"
    
    # Apply changes
    terraform apply -auto-approve \
        -var="aws_region=$AWS_REGION" \
        -var="environment=$ENVIRONMENT" \
        -var="bucket_name=$BUCKET_NAME" \
        -var="table_name=$TABLE_NAME" \
        -var="function_name=$FUNCTION_NAME"
    
    # Get outputs
    local api_gateway_url
    api_gateway_url=$(terraform output -raw api_gateway_url)
    local s3_website_url
    s3_website_url=$(terraform output -raw s3_website_url)
    
    # Export outputs
    export API_GATEWAY_URL="$api_gateway_url"
    export S3_WEBSITE_URL="$s3_website_url"
    
    success "Infrastructure deployed successfully"
    log "API Gateway URL: $api_gateway_url"
    log "S3 Website URL: $s3_website_url"
}

deploy_frontend() {
    log "Deploying frontend to S3..."
    
    # Check if we have the required variables
    if [ -z "${S3_WEBSITE_URL:-}" ]; then
        error "S3_WEBSITE_URL not set. Run infrastructure deployment first."
    fi
    
    # Update frontend with API URL
    if [ -n "${API_GATEWAY_URL:-}" ]; then
        log "Updating frontend with API URL: $API_GATEWAY_URL"
        
        # Create a temporary index.html with API URL
        cat > /tmp/index.html << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cloud CV - Local Development</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background: #4F46E5; color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
        .content { margin: 20px 0; }
        .api-test { background: #f8f9fa; padding: 15px; border-radius: 5px; border-left: 4px solid #4F46E5; }
        .status { padding: 10px; border-radius: 5px; margin: 10px 0; }
        .success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        button { background: #4F46E5; color: white; border: none; padding: 10px 20px; border-radius: 5px; cursor: pointer; }
        button:hover { background: #3730A3; }
        pre { background: #f8f9fa; padding: 10px; border-radius: 5px; overflow-x: auto; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Cloud CV - Local Development</h1>
            <p>SRE/DevOps Engineer Portfolio - LocalStack Environment</p>
        </div>
        <div class="content">
            <h2>Local Development Environment</h2>
            <p>This is running on LocalStack with the following services:</p>
            <ul>
                <li><strong>S3:</strong> Static website hosting</li>
                <li><strong>DynamoDB:</strong> Visitor counter database</li>
                <li><strong>Lambda:</strong> Serverless visitor counter function</li>
                <li><strong>API Gateway:</strong> REST API endpoint</li>
            </ul>
            
            <div class="api-test">
                <h3>API Test</h3>
                <p><strong>API Endpoint:</strong> <span id="api-url">Loading...</span></p>
                <button onclick="testAPI()">Test Visitor Counter</button>
                <div id="result"></div>
            </div>
            
            <div class="content">
                <h3>LocalStack Services</h3>
                <p>You can interact with LocalStack using AWS CLI:</p>
                <pre># List S3 buckets
aws --endpoint-url=http://localhost:4566 s3 ls

# List DynamoDB tables
aws --endpoint-url=http://localhost:4566 dynamodb list-tables

# List Lambda functions
aws --endpoint-url=http://localhost:4566 lambda list-functions

# List API Gateway APIs
aws --endpoint-url=http://localhost:4566 apigateway get-rest-apis</pre>
            </div>
        </div>
    </div>

    <script>
        // Set API URL
        document.getElementById('api-url').textContent = '${API_GATEWAY_URL:-Not available}';
        
        function testAPI() {
            const apiUrl = '${API_GATEWAY_URL:-}';
            if (!apiUrl) {
                document.getElementById('result').innerHTML = 
                    '<div class="status error">API URL not available</div>';
                return;
            }
            
            document.getElementById('result').innerHTML = 
                '<div class="status">Testing API...</div>';
            
            fetch(apiUrl)
                .then(response => response.json())
                .then(data => {
                    document.getElementById('result').innerHTML = 
                        '<div class="status success">API Response:</div><pre>' + 
                        JSON.stringify(data, null, 2) + '</pre>';
                })
                .catch(error => {
                    document.getElementById('result').innerHTML = 
                        '<div class="status error">Error: ' + error.message + '</div>';
                });
        }
    </script>
</body>
</html>
EOF
        
        # Upload to S3
        aws s3 cp /tmp/index.html s3://$BUCKET_NAME/index.html --endpoint-url=http://localhost:4566
        
        # Clean up
        rm -f /tmp/index.html
    fi
    
    success "Frontend deployed successfully"
}

run_health_checks() {
    log "Running health checks..."
    
    # Check LocalStack
    if curl -f -s http://localhost:4566/_localstack/health > /dev/null 2>&1; then
        success "LocalStack is healthy"
    else
        warning "LocalStack health check failed"
    fi
    
    # Check S3 website
    if curl -f -s "$S3_WEBSITE_URL" > /dev/null 2>&1; then
        success "S3 website is accessible"
    else
        warning "S3 website health check failed"
    fi
    
    # Check API endpoint
    if [ -n "${API_GATEWAY_URL:-}" ]; then
        if curl -f -s "$API_GATEWAY_URL" > /dev/null 2>&1; then
            success "API endpoint is accessible"
        else
            warning "API endpoint health check failed"
        fi
    fi
}

show_summary() {
    log "LocalStack deployment completed!"
    echo ""
    echo "Services deployed:"
    echo "  S3 Bucket:        s3://$BUCKET_NAME"
    echo "  DynamoDB Table:   $TABLE_NAME"
    echo "  Lambda Function:  $FUNCTION_NAME"
    echo "  API Gateway:      $API_GATEWAY_URL"
    echo ""
    echo "Access URLs:"
    echo "  LocalStack:       http://localhost:4566"
    echo "  S3 Website:       $S3_WEBSITE_URL"
    echo "  API Endpoint:     $API_GATEWAY_URL"
    echo ""
    echo "AWS CLI commands:"
    echo "  aws --endpoint-url=http://localhost:4566 s3 ls"
    echo "  aws --endpoint-url=http://localhost:4566 dynamodb list-tables"
    echo "  aws --endpoint-url=http://localhost:4566 lambda list-functions"
    echo "  aws --endpoint-url=http://localhost:4566 apigateway get-rest-apis"
}

main() {
    # Parse command line arguments
    local skip_terraform=false
    local skip_frontend=false
    
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
            -b|--bucket)
                BUCKET_NAME="$2"
                shift 2
                ;;
            --skip-terraform)
                skip_terraform=true
                shift
                ;;
            --skip-frontend)
                skip_frontend=true
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
    
    log "Starting LocalStack deployment..."
    log "Region: $AWS_REGION"
    log "Environment: $ENVIRONMENT"
    log "Bucket: $BUCKET_NAME"
    log "Skip Terraform: $skip_terraform"
    log "Skip Frontend: $skip_frontend"
    
    # Run deployment steps
    check_dependencies
    check_localstack
    setup_aws_credentials
    
    if [ "$skip_terraform" = false ]; then
        deploy_infrastructure
    fi
    
    if [ "$skip_frontend" = false ]; then
        deploy_frontend
    fi
    
    run_health_checks
    show_summary
    
    success "LocalStack deployment completed successfully!"
}

# Run main function
main "$@"
