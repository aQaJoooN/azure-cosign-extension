#!/bin/bash

set -e

echo "============================================"
echo "  Cosign Extension Build Script"
echo "============================================"
echo ""

# Check if tfx-cli is installed
if ! command -v tfx &> /dev/null; then
    echo "Error: tfx-cli is not installed"
    echo "Install it with: npm install -g tfx-cli"
    exit 1
fi

echo "✓ tfx-cli is installed"
echo ""

# Get version from vss-extension.json
VERSION=$(grep -Po '"version":\s*"\K[^"]+' vss-extension.json | head -n 1)
echo "Building version: $VERSION"
echo ""

# Clean old builds
echo "Cleaning old builds..."
rm -f *.vsix
echo "✓ Cleaned"
echo ""

# Create extension
echo "Creating extension package..."
tfx extension create --manifest-globs vss-extension.json

# Find the created vsix file
VSIX_FILE=$(ls -t *.vsix 2>/dev/null | head -n 1)

if [ -z "$VSIX_FILE" ]; then
    echo "✗ Failed to create extension package"
    exit 1
fi

echo "✓ Extension packaged successfully"
echo ""
echo "============================================"
echo "  Build Complete"
echo "============================================"
echo ""
echo "Extension file: $VSIX_FILE"
echo ""
echo "Next steps:"
echo "1. Upload to Azure DevOps:"
echo "   - Go to Organization/Collection Settings"
echo "   - Navigate to Extensions"
echo "   - Click 'Upload new extension'"
echo "   - Select: $VSIX_FILE"
echo ""
echo "2. Or use API:"
echo "   tfx extension publish --vsix $VSIX_FILE --service-url <your-url> --token <pat>"
echo ""
