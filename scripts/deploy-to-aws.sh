#!/bin/bash

# Simple AWS Deployment Script
# One command deployment for Cloud CV

set -e

echo "🚀 Cloud CV - AWS Deployment"
echo "=============================="
echo ""

# Check prerequisites
echo "🔍 Checking prerequisites..."

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install AWS CLI first."
    exit 1
fi

# Check Terraform
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform not found. Please install Terraform first."
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

echo "✅ Prerequisites check passed!"
echo ""

# Run the main deployment script
echo "🚀 Starting automated deployment..."
echo ""

./scripts/aws-deploy.sh

echo ""
echo "🎉 Deployment completed!"
echo "Check the output above for your Cloud CV URLs."
