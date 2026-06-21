#!/bin/bash

set -e

echo "=========================================="
echo "  Pre-Push Validation Script"
echo "=========================================="
echo ""

ERRORS=0
WARNINGS=0

# Check if we're in the right directory
if [ ! -f "vss-extension.json" ]; then
    echo "❌ Error: Run this script from the azure-cosign-extension directory"
    exit 1
fi

echo "✓ Running from correct directory"
echo ""

# Function to increment error counter
error() {
    echo "❌ $1"
    ERRORS=$((ERRORS + 1))
}

# Function to increment warning counter
warning() {
    echo "⚠️  $1"
    WARNINGS=$((WARNINGS + 1))
}

# Function for success messages
success() {
    echo "✓ $1"
}

echo "=========================================="
echo "2. Checking for hardcoded secrets"
echo "=========================================="
if grep -rE "(password|secret|token|key)\s*=\s*['\"][^'\"]{10,}['\"]" \
    --exclude-dir=.git \
    --exclude-dir=node_modules \
    --exclude="*.vsix" \
    --exclude="*.md" \
    --exclude="validate-before-push.sh" . > /dev/null 2>&1; then
    error "Potential hardcoded secrets found!"
else
    success "No hardcoded secrets detected"
fi
echo ""

echo "=========================================="
echo "3. Validating JSON files"
echo "=========================================="
JSON_FILES=(
    "vss-extension.json"
    "service-endpoint/cosign-endpoint.json"
    "tasks/CosignSign/task.json"
    "tasks/CosignSign/package.json"
)

for file in "${JSON_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        error "Missing required file: $file"
    elif command -v jq >/dev/null 2>&1; then
        if jq empty "$file" >/dev/null 2>&1; then
            success "Valid JSON: $file"
        else
            error "Invalid JSON: $file"
        fi
    else
        warning "jq not installed, skipping JSON validation for $file"
    fi
done
echo ""

echo "=========================================="
echo "4. Validating shell scripts"
echo "=========================================="
SHELL_FILES=(
    "tasks/CosignSign/sign.sh"
    "build.sh"
)

for file in "${SHELL_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        error "Missing required file: $file"
    elif bash -n "$file" 2>/dev/null; then
        success "Valid syntax: $file"
    else
        error "Invalid syntax: $file"
    fi
done
echo ""

echo "=========================================="
echo "5. Checking required files"
echo "=========================================="
REQUIRED_FILES=(
    "LICENSE"
    "README.md"
    "CHANGELOG.md"
    "CONTRIBUTING.md"
    "SECURITY.md"
    ".gitignore"
    ".gitattributes"
    "vss-extension.json"
    "service-endpoint/cosign-endpoint.json"
    "tasks/CosignSign/task.json"
    "tasks/CosignSign/sign.sh"
    ".github/workflows/build.yml"
    ".github/workflows/validate.yml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        success "Present: $file"
    else
        error "Missing: $file"
    fi
done
echo ""

echo "=========================================="
echo "6. Checking version consistency"
echo "=========================================="
VSS_VERSION=$(grep -Po '"version":\s*"\K[^"]+' vss-extension.json | head -1)
TASK_MAJOR=$(grep -Po '"Major":\s*\K[0-9]+' tasks/CosignSign/task.json)
TASK_MINOR=$(grep -Po '"Minor":\s*\K[0-9]+' tasks/CosignSign/task.json)
TASK_PATCH=$(grep -Po '"Patch":\s*\K[0-9]+' tasks/CosignSign/task.json)
TASK_VERSION="${TASK_MAJOR}.${TASK_MINOR}.${TASK_PATCH}"

echo "vss-extension.json version: $VSS_VERSION"
echo "task.json version: $TASK_VERSION"

if [ "$VSS_VERSION" = "$TASK_VERSION" ]; then
    success "Versions match"
else
    warning "Version mismatch between vss-extension.json and task.json"
fi
echo ""

echo "=========================================="
echo "7. Checking git status"
echo "=========================================="
if [ -d ".git" ]; then
    if [ -n "$(git status --porcelain)" ]; then
        warning "Uncommitted changes detected"
        git status --short
    else
        success "No uncommitted changes"
    fi
else
    warning "Not a git repository (run 'git init' first)"
fi
echo ""

echo "=========================================="
echo "8. Checking .gitignore"
echo "=========================================="
GITIGNORE_PATTERNS=(
    "*.vsix"
    "node_modules"
    "*.log"
)

for pattern in "${GITIGNORE_PATTERNS[@]}"; do
    if grep -q "$pattern" .gitignore 2>/dev/null; then
        success ".gitignore contains: $pattern"
    else
        warning ".gitignore missing pattern: $pattern"
    fi
done
echo ""

echo "=========================================="
echo "  Validation Summary"
echo "=========================================="
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "🎉 All checks passed!"
    echo ""
    echo "Ready to push to GitHub!"
    echo ""
    echo "Next steps:"
    echo "1. git init (if not already done)"
    echo "2. git add ."
    echo "3. git commit -m 'feat: initial release'"
    echo "4. Create GitHub repository"
    echo "5. git remote add origin https://github.com/aQaJoooN/azure-cosign-extension.git.git"
    echo "6. git push -u origin main"
    echo "7. git tag -a v1.0.0 -m 'Release v1.0.0'"
    echo "8. git push origin v1.0.0"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo "⚠️  $WARNINGS warning(s) found"
    echo ""
    echo "You can proceed, but review warnings above."
    exit 0
else
    echo "❌ $ERRORS error(s) found"
    if [ $WARNINGS -gt 0 ]; then
        echo "⚠️  $WARNINGS warning(s) found"
    fi
    echo ""
    echo "Please fix errors before pushing to GitHub."
    exit 1
fi
