#!/bin/bash

# Portfolio Cleanup Script
set -e

STACK_NAME="nsuku-portfolio"
REGION="us-east-1"

echo "🧹 Cleaning up Portfolio resources..."

# Get S3 bucket name before deleting stack
BUCKET_NAME=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`S3BucketName`].OutputValue' \
    --output text 2>/dev/null || echo "")

if [ ! -z "$BUCKET_NAME" ]; then
    echo "🗑️  Emptying S3 bucket: $BUCKET_NAME"
    aws s3 rm s3://$BUCKET_NAME --recursive
fi

# Delete CloudFormation stack
echo "🗂️  Deleting CloudFormation stack..."
aws cloudformation delete-stack \
    --stack-name $STACK_NAME \
    --region $REGION

echo "⏳ Waiting for stack deletion to complete..."
aws cloudformation wait stack-delete-complete \
    --stack-name $STACK_NAME \
    --region $REGION

echo "✅ Cleanup completed successfully!"