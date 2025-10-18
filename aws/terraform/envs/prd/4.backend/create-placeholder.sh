#!/bin/bash

# Wrapper script for backward compatibility
# This script calls the centralized package-lambdas.sh script
# and outputs to the local lambda-packages directory

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../../.." && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/lambda-packages"

echo "� Note: This script is a wrapper for scripts/package-lambdas.sh"
echo ""

# Call the centralized script with output directory
"$PROJECT_ROOT/scripts/package-lambdas.sh" "$OUTPUT_DIR"
