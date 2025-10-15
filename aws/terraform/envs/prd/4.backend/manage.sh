#!/bin/bash

# Makefile-style commands for managing Lambda + API Gateway infrastructure

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_help() {
    cat << EOF
Usage: ./manage.sh [command]

Commands:
    init                Initialize Terraform
    plan                Plan infrastructure changes
    apply               Apply infrastructure changes
    destroy             Destroy infrastructure
    output              Show Terraform outputs
    validate            Validate Terraform configuration
    fmt                 Format Terraform files
    
    create-placeholder  Create Lambda placeholder package
    generate-config     Generate Lambda config from template
    
    test-api            Test API Gateway endpoints
    logs                View Lambda logs (requires function name)
    
    help                Show this help message

Examples:
    ./manage.sh init
    ./manage.sh plan
    ./manage.sh apply
    ./manage.sh test-api
    ./manage.sh logs screenshot-create

EOF
}

init_terraform() {
    echo -e "${GREEN}Initializing Terraform...${NC}"
    terraform init
}

plan_terraform() {
    echo -e "${GREEN}Planning Terraform changes...${NC}"
    terraform plan -var-file=../terraform.stg.tfvars
}

apply_terraform() {
    echo -e "${GREEN}Applying Terraform changes...${NC}"
    terraform apply -var-file=../terraform.stg.tfvars
}

destroy_terraform() {
    echo -e "${RED}Destroying infrastructure...${NC}"
    read -p "Are you sure? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        terraform destroy -var-file=../terraform.stg.tfvars
    else
        echo "Aborted."
    fi
}

show_output() {
    echo -e "${GREEN}Terraform Outputs:${NC}"
    terraform output
}

validate_terraform() {
    echo -e "${GREEN}Validating Terraform configuration...${NC}"
    terraform validate
}

format_terraform() {
    echo -e "${GREEN}Formatting Terraform files...${NC}"
    terraform fmt -recursive
}

create_placeholder() {
    echo -e "${GREEN}Creating Lambda placeholder...${NC}"
    bash create-placeholder.sh
}

generate_config() {
    echo -e "${GREEN}Generating Lambda configuration...${NC}"
    bash generate-lambda-config.sh
}

test_api() {
    echo -e "${GREEN}Testing API Gateway endpoints...${NC}"
    
    # Get API Gateway URL from Terraform output
    API_URL=$(terraform output -raw api_gateway_url 2>/dev/null)
    
    if [ -z "$API_URL" ]; then
        echo -e "${RED}Error: Could not get API Gateway URL${NC}"
        echo "Make sure infrastructure is deployed first"
        exit 1
    fi
    
    echo -e "${YELLOW}API Gateway URL: $API_URL${NC}"
    echo ""
    
    # Test health endpoint
    echo -e "${GREEN}Testing /health endpoint...${NC}"
    curl -s "${API_URL}/health" | jq '.' || echo "Failed"
    echo ""
    
    # Test list screenshots
    echo -e "${GREEN}Testing GET /screenshots...${NC}"
    curl -s "${API_URL}/screenshots" | jq '.' || echo "Failed"
    echo ""
    
    # Test create screenshot
    echo -e "${GREEN}Testing POST /screenshots...${NC}"
    curl -s -X POST "${API_URL}/screenshots" \
        -H "Content-Type: application/json" \
        -d '{"url": "https://example.com"}' | jq '.' || echo "Failed"
    echo ""
}

view_logs() {
    local function_name=$1
    
    if [ -z "$function_name" ]; then
        echo -e "${RED}Error: Function name required${NC}"
        echo "Usage: ./manage.sh logs <function-name>"
        echo ""
        echo "Available functions:"
        terraform output -json lambda_function_names 2>/dev/null | jq -r '.[]' || echo "Run 'terraform apply' first"
        exit 1
    fi
    
    # Get project and env from tfvars
    PROJECT=$(grep 'project' ../terraform.stg.tfvars | cut -d'"' -f2)
    ENV=$(grep 'env' ../terraform.stg.tfvars | cut -d'"' -f2)
    
    local full_function_name="${PROJECT}-${ENV}-${function_name}"
    local log_group="/aws/lambda/${full_function_name}"
    
    echo -e "${GREEN}Viewing logs for ${full_function_name}...${NC}"
    echo -e "${YELLOW}Log Group: ${log_group}${NC}"
    echo ""
    
    # Use AWS CLI to get recent logs
    aws logs tail "$log_group" --follow --format short
}

# Main command handler
case "${1:-help}" in
    init)
        init_terraform
        ;;
    plan)
        plan_terraform
        ;;
    apply)
        apply_terraform
        ;;
    destroy)
        destroy_terraform
        ;;
    output)
        show_output
        ;;
    validate)
        validate_terraform
        ;;
    fmt|format)
        format_terraform
        ;;
    create-placeholder)
        create_placeholder
        ;;
    generate-config)
        generate_config
        ;;
    test-api)
        test_api
        ;;
    logs)
        view_logs "$2"
        ;;
    help|--help|-h)
        print_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo ""
        print_help
        exit 1
        ;;
esac
