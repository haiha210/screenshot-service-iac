#!/bin/bash

# Script to package Lambda functions from aws/lambdas/handlers directory
# Reads configuration from lambda-config.yaml and creates zip packages
#
# Usage:
#   ./scripts/package-lambdas.sh [output_dir]
#
# Arguments:
#   output_dir - Optional: Directory to output zip files (default: aws/terraform/envs/prd/4.backend/lambda-packages)
#
# Examples:
#   ./scripts/package-lambdas.sh
#   ./scripts/package-lambdas.sh /tmp/lambda-packages
#   ./scripts/package-lambdas.sh aws/terraform/envs/stg/4.backend/lambda-packages

set -e

# Determine project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Set paths
LAMBDAS_DIR="$PROJECT_ROOT/aws/lambdas/handlers"
CONFIG_FILE="$PROJECT_ROOT/aws/templates/lambda-config.yaml"

# Set output directory (default or from argument)
if [ -n "$1" ]; then
    # If argument is absolute path, use it; otherwise make it relative to PROJECT_ROOT
    if [[ "$1" = /* ]]; then
        OUTPUT_DIR="$1"
    else
        OUTPUT_DIR="$PROJECT_ROOT/$1"
    fi
else
    OUTPUT_DIR="$PROJECT_ROOT/aws/terraform/envs/prd/4.backend/lambda-packages"
fi

echo "🔧 Lambda Packaging Tool"
echo "========================"
echo "Project Root: $PROJECT_ROOT"
echo "Lambdas Dir:  $LAMBDAS_DIR"
echo "Output Dir:   $OUTPUT_DIR"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Check if lambda config exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Error: lambda-config.yaml not found at $CONFIG_FILE"
    exit 1
fi

# Check if handlers directory exists
if [ ! -d "$LAMBDAS_DIR" ]; then
    echo "❌ Error: Lambda handlers directory not found at $LAMBDAS_DIR"
    exit 1
fi

# Parse YAML and get list of Lambda functions
# Using simple grep/awk approach since yq might not be installed
echo "📦 Packaging Lambda functions..."
echo ""

# Function to package a Lambda handler
package_lambda() {
    local handler_name=$1
    local handler_dir="$LAMBDAS_DIR/$handler_name"
    local zip_file="$OUTPUT_DIR/${handler_name}.zip"
    
    if [ ! -d "$handler_dir" ]; then
        echo "⚠️  Warning: Handler directory not found: $handler_dir"
        return 1
    fi
    
    echo "📦 Packaging: $handler_name"
    echo "   Source: $handler_dir"
    
    # Create temporary directory for packaging
    TMP_DIR=$(mktemp -d)
    
    # Copy Lambda files to temp directory
    cp -r "$handler_dir"/* "$TMP_DIR/"
    
    # Install dependencies if package.json exists (for Node.js)
    if [ -f "$TMP_DIR/package.json" ]; then
        echo "   📥 Installing Node.js dependencies..."
        if (cd "$TMP_DIR" && npm install --production --silent 2>/dev/null); then
            echo "   ✅ Dependencies installed"
        else
            echo "   ⚠️  Warning: npm install failed or no dependencies"
        fi
    fi
    
    # Install dependencies if requirements.txt exists (for Python)
    if [ -f "$TMP_DIR/requirements.txt" ]; then
        echo "   📥 Installing Python dependencies..."
        if (cd "$TMP_DIR" && pip install -r requirements.txt -t . --quiet 2>/dev/null); then
            echo "   ✅ Dependencies installed"
        else
            echo "   ⚠️  Warning: pip install failed or no dependencies"
        fi
    fi
    
    # Create zip package
    echo "   📦 Creating zip archive..."
    (cd "$TMP_DIR" && zip -r -q "$zip_file" . \
        -x "*.pyc" \
        -x "__pycache__/*" \
        -x "node_modules/.bin/*" \
        -x ".git/*" \
        -x "*.md" \
        -x "test/*" \
        -x "tests/*" \
        -x ".gitignore" \
        2>/dev/null || true)
    
    # Cleanup
    rm -rf "$TMP_DIR"
    
    # Verify zip file was created and get size
    if [ -f "$zip_file" ]; then
        local size=$(du -h "$zip_file" | cut -f1)
        echo "   ✅ Created: $(basename $zip_file) ($size)"
        echo ""
        return 0
    else
        echo "   ❌ Failed to create zip file"
        echo ""
        return 1
    fi
}

# Package all Lambda handlers found in the handlers directory
packaged_count=0
failed_count=0
packaged_functions=()

for handler_path in "$LAMBDAS_DIR"/*; do
    if [ -d "$handler_path" ]; then
        handler_name=$(basename "$handler_path")
        
        if package_lambda "$handler_name"; then
            ((packaged_count++))
            packaged_functions+=("$handler_name")
        else
            ((failed_count++))
        fi
    fi
done

echo "========================"
echo "📊 Summary:"
echo "   Total:    $((packaged_count + failed_count))"
echo "   Packaged: $packaged_count"
echo "   Failed:   $failed_count"
echo ""

if [ $packaged_count -gt 0 ]; then
    echo "📦 Packaged functions:"
    for fn in "${packaged_functions[@]}"; do
        echo "   - $fn.zip"
    done
    echo ""
fi

echo "📁 Output location: $OUTPUT_DIR"
echo ""

if [ $packaged_count -eq 0 ]; then
    echo "❌ No Lambda functions were packaged!"
    exit 1
fi

echo "✅ Lambda packaging completed successfully!"
echo ""
echo "Next steps:"
echo "1. Review packages in: $OUTPUT_DIR"
echo "2. Update lambda.tf to reference these packages"
echo "3. Run terraform plan/apply to deploy"
