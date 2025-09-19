#!/bin/bash

# Validate CI/CD workflow configuration
# This script checks the security.yml workflow for common issues

set -e

WORKFLOW_FILE=".github/workflows/security.yml"
REPO_ROOT=$(git rev-parse --show-toplevel)

cd "$REPO_ROOT"

echo "🔍 Validating CI/CD workflow..."

# Check if workflow file exists
if [[ ! -f "$WORKFLOW_FILE" ]]; then
  echo "❌ Workflow file not found: $WORKFLOW_FILE"
  exit 1
fi

# Validate YAML syntax
echo "📋 Checking YAML syntax..."
python3 -c "import yaml; yaml.safe_load(open('$WORKFLOW_FILE'))" || {
  echo "❌ Invalid YAML syntax in $WORKFLOW_FILE"
  exit 1
}
echo "✅ YAML syntax is valid"

# Check for required permissions
echo "🔐 Checking permissions..."
if grep -q "packages: write" "$WORKFLOW_FILE"; then
  echo "✅ packages: write permission found"
else
  echo "❌ Missing packages: write permission"
  exit 1
fi

# Check image name pattern
echo "🏷️ Checking image name configuration..."
if grep -q "ghcr.io/\${{ github.repository_owner }}/platform-api" "$WORKFLOW_FILE"; then
  echo "✅ Correct image name pattern found"
else
  echo "❌ Incorrect image name pattern"
  exit 1
fi

# Check push conditions
echo "🚀 Checking push conditions..."
if grep -q "if: github.event_name == 'push'" "$WORKFLOW_FILE"; then
  echo "✅ Push conditions found"
else
  echo "❌ Missing push conditions"
  exit 1
fi

# Check if build/test works
echo "🔨 Testing build..."
npm ci --silent
npm run build --silent
echo "✅ Build successful"

# Check Dockerfile exists
if [[ -f "Dockerfile" ]]; then
  echo "✅ Dockerfile found"
else
  echo "❌ Dockerfile not found"
  exit 1
fi

echo ""
echo "🎉 All validations passed!"
echo ""
echo "Repository will push images to:"
echo "  ghcr.io/$(basename $(git remote get-url origin | sed 's/\.git$//' | sed 's/.*[\/:]//') | tr '[:upper:]' '[:lower:]')/platform-api"
echo ""
echo "Next steps:"
echo "1. Ensure you have Cosign secrets configured (COSIGN_PRIVATE_KEY, COSIGN_PASSWORD)"
echo "2. Push to main branch to trigger the full workflow"
echo "3. Check GitHub Actions tab for workflow execution"