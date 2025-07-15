#!/bin/bash

# Portfolio Deployment Script
set -e

STACK_NAME="nsuku-portfolio"
REGION="us-east-1"  # Required for CloudFront
TEMPLATE_FILE="cloudformation-template.yaml"

echo "🚀 Deploying Portfolio to AWS..."

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

# Deploy CloudFormation stack
echo "📦 Deploying CloudFormation stack..."
aws cloudformation deploy \
    --template-file $TEMPLATE_FILE \
    --stack-name $STACK_NAME \
    --region $REGION \
    --capabilities CAPABILITY_IAM \
    --no-fail-on-empty-changeset

# Get S3 bucket name from stack outputs
echo "🔍 Getting S3 bucket name..."
BUCKET_NAME=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`S3BucketName`].OutputValue' \
    --output text)

if [ -z "$BUCKET_NAME" ]; then
    echo "❌ Failed to get S3 bucket name"
    exit 1
fi

echo "📁 S3 Bucket: $BUCKET_NAME"

# Upload website files to S3
echo "⬆️  Uploading website files..."
aws s3 sync . s3://$BUCKET_NAME \
    --exclude "*.sh" \
    --exclude "*.yaml" \
    --exclude "*.yml" \
    --exclude "*.pem" \
    --exclude "*.json" \
    --exclude "README.md" \
    --exclude ".git/*" \
    --exclude "scripts/*" \
    --delete

# Set proper content types
aws s3 cp s3://$BUCKET_NAME/index.html s3://$BUCKET_NAME/index.html --content-type "text/html" --metadata-directive REPLACE
aws s3 cp s3://$BUCKET_NAME/css/style.css s3://$BUCKET_NAME/css/style.css --content-type "text/css" --metadata-directive REPLACE
aws s3 cp s3://$BUCKET_NAME/js/script.js s3://$BUCKET_NAME/js/script.js --content-type "application/javascript" --metadata-directive REPLACE

# Get CloudFront distribution ID and invalidate cache
echo "🔄 Invalidating CloudFront cache..."
DISTRIBUTION_ID=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`DistributionId`].OutputValue' \
    --output text)

aws cloudfront create-invalidation \
    --distribution-id $DISTRIBUTION_ID \
    --paths "/*"

# Get website URL
WEBSITE_URL=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`WebsiteURL`].OutputValue' \
    --output text)

echo "✅ Deployment completed successfully!"
echo "🌐 Website URL: $WEBSITE_URL"
echo "📊 CloudFront Distribution ID: $DISTRIBUTION_ID"
echo "🪣 S3 Bucket: $BUCKET_NAME"
echo ""
echo "Note: CloudFront distribution may take 10-15 minutes to fully deploy."