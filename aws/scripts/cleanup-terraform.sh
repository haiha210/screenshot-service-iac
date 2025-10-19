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
echo "⚠️  WARNING: This will DELETE all Terraform backend resources!"
echo "======================================"
echo "Environment: $env"
echo "Project: $project"
echo "Region: $region"
echo "Profile: $profile"
echo "======================================"
echo ""
echo "Resources that will be deleted:"
echo "  - S3 Bucket: $project-$env-iac-state (including all objects and versions)"
echo "  - DynamoDB Table: $project-$env-terraform-state-lock"
echo "  - KMS Key: alias/$project-$env-iac"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "======================================"
echo "Starting cleanup..."
echo "======================================"

# Delete all objects and versions from S3 bucket
echo "Deleting all objects and versions from S3 bucket..."
BUCKET_EXISTS=$(aws-vault exec $profile -- aws s3api head-bucket --bucket $project-$env-iac-state --region $region 2>&1 || echo "not-found")

if [[ "$BUCKET_EXISTS" != *"not-found"* ]]; then
    # Delete all object versions (including delete markers)
    echo "  - Deleting all object versions..."
    aws-vault exec $profile -- aws s3api list-object-versions \
        --bucket $project-$env-iac-state \
        --region $region \
        --output json \
        --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' | \
    jq -r '.Objects[]? | "--key \"\(.Key)\" --version-id \"\(.VersionId)\""' | \
    while read line; do
        if [ ! -z "$line" ]; then
            eval aws-vault exec $profile -- aws s3api delete-object --bucket $project-$env-iac-state --region $region $line
        fi
    done

    # Delete all delete markers
    echo "  - Deleting all delete markers..."
    aws-vault exec $profile -- aws s3api list-object-versions \
        --bucket $project-$env-iac-state \
        --region $region \
        --output json \
        --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' | \
    jq -r '.Objects[]? | "--key \"\(.Key)\" --version-id \"\(.VersionId)\""' | \
    while read line; do
        if [ ! -z "$line" ]; then
            eval aws-vault exec $profile -- aws s3api delete-object --bucket $project-$env-iac-state --region $region $line
        fi
    done

    # Delete the bucket
    echo "  - Deleting S3 bucket..."
    aws-vault exec $profile -- aws s3api delete-bucket \
        --bucket $project-$env-iac-state \
        --region $region
    echo "✅ S3 bucket deleted successfully"
else
    echo "ℹ️  S3 bucket not found, skipping..."
fi

# Delete DynamoDB table
echo ""
echo "Deleting DynamoDB table..."
TABLE_EXISTS=$(aws-vault exec $profile -- aws dynamodb describe-table --table-name $project-$env-terraform-state-lock --region $region 2>&1 || echo "not-found")

if [[ "$TABLE_EXISTS" != *"not-found"* ]]; then
    aws-vault exec $profile -- aws dynamodb delete-table \
        --table-name $project-$env-terraform-state-lock \
        --region $region

    echo "  - Waiting for table deletion to complete..."
    aws-vault exec $profile -- aws dynamodb wait table-not-exists \
        --table-name $project-$env-terraform-state-lock \
        --region $region
    echo "✅ DynamoDB table deleted successfully"
else
    echo "ℹ️  DynamoDB table not found, skipping..."
fi

# Get KMS key ID from alias
echo ""
echo "Deleting KMS key and alias..."
KMS_KEY_ID=$(aws-vault exec $profile -- aws kms describe-key \
    --key-id alias/$project-$env-iac \
    --region $region \
    --query "KeyMetadata.KeyId" \
    --output text 2>/dev/null || echo "")

if [ ! -z "$KMS_KEY_ID" ] && [ "$KMS_KEY_ID" != "None" ]; then
    # Disable the key immediately (makes it unusable right away)
    echo "  - Disabling KMS key immediately..."
    aws-vault exec $profile -- aws kms disable-key \
        --key-id $KMS_KEY_ID \
        --region $region

    # Delete the alias
    echo "  - Deleting KMS alias..."
    aws-vault exec $profile -- aws kms delete-alias \
        --alias-name alias/$project-$env-iac \
        --region $region

    # Schedule key deletion with minimum waiting period (7 days)
    echo "  - Scheduling KMS key deletion (minimum 7 day waiting period - AWS requirement)..."
    aws-vault exec $profile -- aws kms schedule-key-deletion \
        --key-id $KMS_KEY_ID \
        --pending-window-in-days 7 \
        --region $region

    echo "✅ KMS key disabled immediately and scheduled for deletion in 7 days"
    echo "   (Key is now unusable and will be permanently deleted after 7 days)"
else
    echo "ℹ️  KMS key not found, skipping..."
fi

echo ""
echo "======================================"
echo "✅ Cleanup completed successfully!"
echo "======================================"
echo "Deleted resources:"
echo "  ✅ S3 Bucket: $project-$env-iac-state (deleted)"
echo "  ✅ DynamoDB Table: $project-$env-terraform-state-lock (deleted)"
echo "  ✅ KMS Key: alias/$project-$env-iac (disabled and scheduled for deletion)"
echo "======================================"
echo ""
echo "📝 Important Notes:"
echo "  • KMS key is DISABLED immediately and cannot be used anymore"
echo "  • KMS key will be PERMANENTLY DELETED after 7 days (AWS requirement)"
echo "  • You can cancel the deletion within 7 days if needed using:"
echo "    aws kms cancel-key-deletion --key-id $KMS_KEY_ID"
echo ""
