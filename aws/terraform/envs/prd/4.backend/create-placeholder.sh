#!/bin/bash

# Script to create Lambda placeholder package for initial deployment
# This is needed for the first Terraform apply

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Creating Lambda placeholder package..."

# Create temporary directory
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

# Create a simple Node.js handler
cat > index.js << 'EOF'
exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    return {
        statusCode: 200,
        headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        body: JSON.stringify({
            message: 'Placeholder Lambda function',
            timestamp: new Date().toISOString(),
            event: event
        })
    };
};
EOF

# Create Python handler for Python runtimes
cat > lambda_function.py << 'EOF'
import json
import logging
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    logger.info(f"Event: {json.dumps(event)}")
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'message': 'Placeholder Lambda function',
            'timestamp': datetime.now().isoformat(),
            'event': event
        })
    }
EOF

# Create zip package with both handlers
zip lambda-placeholder.zip index.js lambda_function.py

# Move to terraform directory
mv lambda-placeholder.zip "$SCRIPT_DIR/"

# Cleanup
cd "$SCRIPT_DIR"
rm -rf "$TMP_DIR"

echo "✅ Lambda placeholder package created: lambda-placeholder.zip"
echo ""
echo "Next steps:"
echo "1. cd $SCRIPT_DIR"
echo "2. terraform init"
echo "3. terraform plan -var-file=../terraform.stg.tfvars"
echo "4. terraform apply -var-file=../terraform.stg.tfvars"
