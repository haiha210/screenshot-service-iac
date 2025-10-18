#!/bin/bash

# Script to generate lambda-config.yaml from a larger configuration
# Useful for managing 100+ Lambda functions

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to generate Lambda config entry
generate_lambda_config() {
    local name=$1
    local handler=$2
    local runtime=$3
    local path=$4
    local method=$5
    local timeout=${6:-30}
    local memory=${7:-256}
    local description=$8

    cat << EOF
  - name: $name
    handler: $handler
    runtime: $runtime
    timeout: $timeout
    memory_size: $memory
    description: "$description"
    api_path: $path
    http_method: $method
    environment:
      SERVICE_NAME: screenshots-service
      LOG_LEVEL: info
EOF
}

# Start YAML file
cat > "$SCRIPT_DIR/lambda-config-generated.yaml" << 'EOF'
# Auto-generated Lambda configuration
# Generated at: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

functions:
EOF

# Generate CRUD operations for multiple resources
RESOURCES=("screenshots" "users" "projects" "teams" "billing")

for resource in "${RESOURCES[@]}"; do
    echo "  # ${resource^} Management" >> "$SCRIPT_DIR/lambda-config-generated.yaml"
    
    # Create
    generate_lambda_config \
        "${resource}-create" \
        "handlers/${resource}/create.handler" \
        "nodejs18.x" \
        "/${resource}" \
        "POST" \
        "60" \
        "512" \
        "Create a new ${resource}" >> "$SCRIPT_DIR/lambda-config-generated.yaml"
    
    # List
    generate_lambda_config \
        "${resource}-list" \
        "handlers/${resource}/list.handler" \
        "nodejs18.x" \
        "/${resource}" \
        "GET" \
        "30" \
        "256" \
        "List all ${resource}" >> "$SCRIPT_DIR/lambda-config-generated.yaml"
    
    # Get
    generate_lambda_config \
        "${resource}-get" \
        "handlers/${resource}/get.handler" \
        "nodejs18.x" \
        "/${resource}/{id}" \
        "GET" \
        "30" \
        "256" \
        "Get ${resource} by ID" >> "$SCRIPT_DIR/lambda-config-generated.yaml"
    
    # Update
    generate_lambda_config \
        "${resource}-update" \
        "handlers/${resource}/update.handler" \
        "nodejs18.x" \
        "/${resource}/{id}" \
        "PUT" \
        "30" \
        "256" \
        "Update ${resource} by ID" >> "$SCRIPT_DIR/lambda-config-generated.yaml"
    
    # Delete
    generate_lambda_config \
        "${resource}-delete" \
        "handlers/${resource}/delete.handler" \
        "nodejs18.x" \
        "/${resource}/{id}" \
        "DELETE" \
        "30" \
        "256" \
        "Delete ${resource} by ID" >> "$SCRIPT_DIR/lambda-config-generated.yaml"
    
    echo "" >> "$SCRIPT_DIR/lambda-config-generated.yaml"
done

echo "✅ Generated lambda-config-generated.yaml with $((${#RESOURCES[@]} * 5)) Lambda functions"
echo "📝 Review the file and rename to lambda-config.yaml if satisfied"
echo ""
echo "Total Lambda functions: $((${#RESOURCES[@]} * 5))"
