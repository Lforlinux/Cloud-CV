#!/bin/bash
# Cloud CV - LocalStack Initialization Script
# SRE/DevOps Engineer Portfolio

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="us-east-1"
BUCKET_NAME="cloud-cv-local"
TABLE_NAME="cloud-cv-visitor-counter"
FUNCTION_NAME="cloud-cv-visitor-counter"
API_NAME="cloud-cv-api"

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

wait_for_localstack() {
    log "Waiting for LocalStack to be ready..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localstack:4566/_localstack/health > /dev/null 2>&1; then
            success "LocalStack is ready!"
            return 0
        fi
        
        log "Attempt $attempt/$max_attempts - LocalStack not ready yet..."
        sleep 2
        ((attempt++))
    done
    
    error "LocalStack failed to start within expected time"
}

create_s3_bucket() {
    log "Creating S3 bucket: $BUCKET_NAME"
    
    aws s3 mb s3://$BUCKET_NAME --endpoint-url=http://localstack:4566
    
    # Configure bucket for static website hosting
    aws s3 website s3://$BUCKET_NAME \
        --index-document index.html \
        --error-document error.html \
        --endpoint-url=http://localstack:4566
    
    success "S3 bucket created and configured for static website hosting"
}

create_dynamodb_table() {
    log "Creating DynamoDB table: $TABLE_NAME"
    
    aws dynamodb create-table \
        --table-name $TABLE_NAME \
        --attribute-definitions AttributeName=id,AttributeType=S \
        --key-schema AttributeName=id,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --endpoint-url=http://localstack:4566
    
    # Wait for table to be active
    aws dynamodb wait table-exists \
        --table-name $TABLE_NAME \
        --endpoint-url=http://localstack:4566
    
    success "DynamoDB table created and active"
}

create_lambda_function() {
    log "Creating Lambda function: $FUNCTION_NAME"
    
    # Create deployment package
    cd /opt/code/localstack/lambda
    zip -r function.zip lambda_function.py
    
    # Create IAM role for Lambda
    aws iam create-role \
        --role-name lambda-execution-role \
        --assume-role-policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "Service": "lambda.amazonaws.com"
                    },
                    "Action": "sts:AssumeRole"
                }
            ]
        }' \
        --endpoint-url=http://localstack:4566
    
    # Attach basic execution policy
    aws iam attach-role-policy \
        --role-name lambda-execution-role \
        --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole \
        --endpoint-url=http://localstack:4566
    
    # Attach DynamoDB policy
    aws iam put-role-policy \
        --role-name lambda-execution-role \
        --policy-name DynamoDBAccess \
        --policy-document '{
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Action": [
                        "dynamodb:GetItem",
                        "dynamodb:PutItem",
                        "dynamodb:UpdateItem"
                    ],
                    "Resource": "arn:aws:dynamodb:'$AWS_REGION':000000000000:table/'$TABLE_NAME'"
                }
            ]
        }' \
        --endpoint-url=http://localstack:4566
    
    # Create Lambda function
    aws lambda create-function \
        --function-name $FUNCTION_NAME \
        --runtime python3.11 \
        --role arn:aws:iam::000000000000:role/lambda-execution-role \
        --handler lambda_function.lambda_handler \
        --zip-file fileb://function.zip \
        --timeout 30 \
        --environment Variables='{
            "DYNAMODB_TABLE": "'$TABLE_NAME'"
        }' \
        --endpoint-url=http://localstack:4566
    
    success "Lambda function created"
}

create_api_gateway() {
    log "Creating API Gateway: $API_NAME"
    
    # Create REST API
    local api_id=$(aws apigateway create-rest-api \
        --name $API_NAME \
        --description "Cloud CV API Gateway" \
        --endpoint-url=http://localstack:4566 \
        --query 'id' --output text)
    
    # Get root resource ID
    local root_id=$(aws apigateway get-resources \
        --rest-api-id $api_id \
        --endpoint-url=http://localstack:4566 \
        --query 'items[0].id' --output text)
    
    # Create resource for visitor-count
    local resource_id=$(aws apigateway create-resource \
        --rest-api-id $api_id \
        --parent-id $root_id \
        --path-part visitor-count \
        --endpoint-url=http://localstack:4566 \
        --query 'id' --output text)
    
    # Create GET method
    aws apigateway put-method \
        --rest-api-id $api_id \
        --resource-id $resource_id \
        --http-method GET \
        --authorization-type NONE \
        --endpoint-url=http://localstack:4566
    
    # Create integration with Lambda
    aws apigateway put-integration \
        --rest-api-id $api_id \
        --resource-id $resource_id \
        --http-method GET \
        --type AWS_PROXY \
        --integration-http-method POST \
        --uri arn:aws:apigateway:$AWS_REGION:lambda:path/2015-03-31/functions/arn:aws:lambda:$AWS_REGION:000000000000:function:$FUNCTION_NAME/invocations \
        --endpoint-url=http://localstack:4566
    
    # Add Lambda permission for API Gateway
    aws lambda add-permission \
        --function-name $FUNCTION_NAME \
        --statement-id apigateway-invoke \
        --action lambda:InvokeFunction \
        --principal apigateway.amazonaws.com \
        --source-arn "arn:aws:execute-api:$AWS_REGION:000000000000:$api_id/*/*" \
        --endpoint-url=http://localstack:4566
    
    # Deploy API
    aws apigateway create-deployment \
        --rest-api-id $api_id \
        --stage-name prod \
        --endpoint-url=http://localstack:4566
    
    # Store API URL for later use
    echo "http://localhost:4566/restapis/$api_id/prod/_user_request_/visitor-count" > /tmp/api-url.txt
    
    success "API Gateway created and deployed"
}

upload_frontend_files() {
    log "Uploading frontend files to S3"
    
    # Create a simple index.html for testing
    cat > /tmp/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Cloud CV - Local Development</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .header { background: #4F46E5; color: white; padding: 20px; border-radius: 8px; }
        .content { margin: 20px 0; }
        .api-test { background: #f5f5f5; padding: 15px; border-radius: 5px; }
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
                <li>S3 Static Website Hosting</li>
                <li>DynamoDB for visitor counter</li>
                <li>Lambda function for API</li>
                <li>API Gateway for REST API</li>
            </ul>
            <div class="api-test">
                <h3>API Test</h3>
                <p>Visitor Count API: <a href="#" id="api-url">Loading...</a></p>
                <button onclick="testAPI()">Test Visitor Counter</button>
                <div id="result"></div>
            </div>
        </div>
    </div>
    <script>
        // Get API URL from the initialization
        fetch('/api-url.txt')
            .then(response => response.text())
            .then(url => {
                document.getElementById('api-url').href = url;
                document.getElementById('api-url').textContent = url;
            });
        
        function testAPI() {
            fetch('/api-url.txt')
                .then(response => response.text())
                .then(url => fetch(url))
                .then(response => response.json())
                .then(data => {
                    document.getElementById('result').innerHTML = 
                        '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
                })
                .catch(error => {
                    document.getElementById('result').innerHTML = 
                        '<p style="color: red;">Error: ' + error.message + '</p>';
                });
        }
    </script>
</body>
</html>
EOF
    
    # Upload to S3
    aws s3 cp /tmp/index.html s3://$BUCKET_NAME/index.html --endpoint-url=http://localstack:4566
    
    success "Frontend files uploaded to S3"
}

create_cloudwatch_log_group() {
    log "Creating CloudWatch log group for Lambda"
    
    aws logs create-log-group \
        --log-group-name /aws/lambda/$FUNCTION_NAME \
        --endpoint-url=http://localstack:4566
    
    success "CloudWatch log group created"
}

show_summary() {
    log "LocalStack initialization completed!"
    echo ""
    echo "Services created:"
    echo "  S3 Bucket:        s3://$BUCKET_NAME"
    echo "  DynamoDB Table:   $TABLE_NAME"
    echo "  Lambda Function:  $FUNCTION_NAME"
    echo "  API Gateway:      $API_NAME"
    echo ""
    echo "Access URLs:"
    echo "  LocalStack:       http://localhost:4566"
    echo "  S3 Website:       http://localhost:4566/$BUCKET_NAME/index.html"
    echo "  API Endpoint:      $(cat /tmp/api-url.txt 2>/dev/null || echo 'Not available')"
    echo ""
    echo "AWS CLI commands (use --endpoint-url=http://localhost:4566):"
    echo "  aws s3 ls"
    echo "  aws dynamodb list-tables"
    echo "  aws lambda list-functions"
    echo "  aws apigateway get-rest-apis"
}

main() {
    log "Starting LocalStack initialization..."
    
    # Wait for LocalStack to be ready
    wait_for_localstack
    
    # Create AWS resources
    create_s3_bucket
    create_dynamodb_table
    create_lambda_function
    create_api_gateway
    upload_frontend_files
    create_cloudwatch_log_group
    
    # Show summary
    show_summary
    
    success "LocalStack initialization completed successfully!"
}

# Run main function
main "$@"
