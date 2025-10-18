#!/bin/bash
set -e

# Get environment from argument or prompt
if [ -z "$1" ]; then
    echo "Please Input ENV (prd/stg/dev):"
    read env
else
    env=$1
fi

# Validate environment
if [[ ! "$env" =~ ^(prd|stg|dev)$ ]]; then
    echo "Error: Invalid environment '$env'. Must be prd, stg, or dev."
    exit 1
fi

project="screenshot-service"
region="ap-southeast-1"
profile="$project-$env"

echo "======================================"
echo "Environment: $env"
echo "Project: $project"
echo "Region: $region"
echo "Profile: $profile"
echo "======================================"

# Wrap all AWS commands with aws-vault exec
echo "Creating S3 bucket for Terraform state..."
aws-vault exec $profile -- aws s3api create-bucket \
    --bucket $project-$env-iac-state \
    --region $region \
    --create-bucket-configuration LocationConstraint=$region

echo "Enabling S3 bucket versioning..."
aws-vault exec $profile -- aws s3api put-bucket-versioning \
    --bucket $project-$env-iac-state \
    --versioning-configuration Status=Enabled \
    --region $region

echo "Blocking public access to S3 bucket..."
aws-vault exec $profile -- aws s3api put-public-access-block \
    --bucket $project-$env-iac-state \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
    --region $region

# Create Dynamodb table lock state
echo "Creating DynamoDB table for state locking..."
aws-vault exec $profile -- aws dynamodb create-table \
      --table-name $project-$env-terraform-state-lock \
      --attribute-definitions AttributeName=LockID,AttributeType=S \
      --key-schema AttributeName=LockID,KeyType=HASH \
      --billing-mode PAY_PER_REQUEST \
      --tags Key=Name,Value=$project-$env-terraform-state-lock Key=Environment,Value=$env \
      --region $region

# Create KMS key
echo "Creating KMS key for state encryption..."
KMS_KEY_ID=$(aws-vault exec $profile -- aws kms create-key \
    --description "Encrypt tfstate in s3 backend" \
    --query "KeyMetadata.KeyId" \
    --output text \
    --region $region)

echo "Creating KMS key alias..."
aws-vault exec $profile -- aws kms create-alias \
    --alias-name alias/$project-$env-iac \
    --target-key-id $KMS_KEY_ID \
    --region $region

KMS_KEY_ARN=$(aws-vault exec $profile -- aws kms describe-key \
    --key-id $KMS_KEY_ID \
    --query "KeyMetadata.Arn" \
    --output text \
    --region $region)

echo "======================================"
echo "✅ Setup completed successfully!"
echo "======================================"
echo "Terraform Backend Configuration:"
echo "  Bucket: $project-$env-iac-state"
echo "  DynamoDB Table: $project-$env-terraform-state-lock"
echo "  KMS Key ARN: $KMS_KEY_ARN"
echo "  KMS Key Alias: alias/$project-$env-iac"
echo "======================================"
