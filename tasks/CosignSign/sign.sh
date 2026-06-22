#!/usr/bin/env bash

set -euo pipefail

########################################
# Banner
########################################

echo "============================================"
echo "  Cosign Image Signing Task"
echo "============================================"

########################################
# Get task inputs
########################################

IMAGE_NAME="${INPUT_IMAGENAME}"
IMAGE_TAG="${INPUT_IMAGETAG}"
ENDPOINT_ID="${INPUT_COSIGNSERVICE}"
ALLOW_INSECURE="${INPUT_ALLOWINSECUREREGISTRY:-true}"
VERIFY_SIGNATURE="${INPUT_VERIFYSIGNATURE:-true}"
PREPEND_REGISTRY="${INPUT_PREPENDREGISTRYURL:-true}"

########################################
# Get service connection URL and prepend to image name
########################################

echo "Step 1: Processing service connection URL..."

# Get URL from the clean variable passed by index.js
ENDPOINT_URL="${COSIGN_ENDPOINT_URL:-}"

# Only prepend if enabled
if [[ "$PREPEND_REGISTRY" == "true" && -n "$ENDPOINT_URL" ]]; then
    # Remove http:// or https://
    REGISTRY_URL="${ENDPOINT_URL#http://}"
    REGISTRY_URL="${REGISTRY_URL#https://}"
    # Remove trailing slash if present
    REGISTRY_URL="${REGISTRY_URL%/}"
    
    # If image name doesn't already start with registry URL, prepend it
    if [[ ! "$IMAGE_NAME" =~ ^$REGISTRY_URL ]]; then
        IMAGE_NAME="${REGISTRY_URL}/${IMAGE_NAME}"
        echo "✓ Prepended registry URL: ${REGISTRY_URL}"
    fi
else
    echo "✓ Using image name as provided (registry URL not prepended)"
fi

echo "Final Image Name: ${IMAGE_NAME}"
echo "Image Tag: ${IMAGE_TAG}"
echo "Allow Insecure Registry: ${ALLOW_INSECURE}"
echo "Verify Signature: ${VERIFY_SIGNATURE}"
echo ""

########################################
# Get secrets from service connection
########################################

echo "Step 2: Retrieving credentials from service connection..."

# Get credentials from clean variables passed by index.js
COSIGN_PASSWORD="${COSIGN_KEY_PASSWORD:-}"
COSIGN_PRIVATE_KEY="${COSIGN_PRIVATE_KEY:-}"
COSIGN_PUBLIC_KEY="${COSIGN_PUBLIC_KEY:-}"

########################################
# Validate credentials
########################################

if [[ -z "$COSIGN_PASSWORD" ]]; then
    echo "##vso[task.logissue type=error]Cosign password not found in service connection"
    echo "##vso[task.complete result=Failed;]"
    exit 1
fi

if [[ -z "$COSIGN_PRIVATE_KEY" ]]; then
    echo "##vso[task.logissue type=error]Cosign private key not found in service connection"
    echo "##vso[task.complete result=Failed;]"
    exit 1
fi

if [[ -z "$COSIGN_PUBLIC_KEY" ]]; then
    echo "##vso[task.logissue type=error]Cosign public key not found in service connection"
    echo "##vso[task.complete result=Failed;]"
    exit 1
fi

echo "✓ Credentials retrieved successfully"
echo ""

########################################
# Mask password in logs
########################################

echo "##vso[task.setsecret]${COSIGN_PASSWORD}"

########################################
# Step 3: Create secure temp directory
########################################

echo "Step 3: Creating secure temporary directory..."

TEMP_DIR="$(mktemp -d)"
KEY_FILE="${TEMP_DIR}/cosign.key"
PUB_FILE="${TEMP_DIR}/cosign.pub"

echo "✓ Temporary directory created"
echo ""

########################################
# Cleanup function
########################################

cleanup() {
    local exit_code=$?
    
    echo ""
    echo "Step 9: Cleaning up..."
    
    # Docker logout
    if [[ -n "${DOCKER_REGISTRY_URL:-}" ]]; then
        echo "Logging out from Docker registry..."
        if docker logout "${DOCKER_REGISTRY_URL}" 2>/dev/null; then
            echo "✓ Docker logout successful"
        fi
    fi
    
    # Unset password environment variable
    if [[ -n "${COSIGN_PASSWORD:-}" ]]; then
        unset COSIGN_PASSWORD
        echo "✓ Password variable unset"
    fi
    
    # Securely delete key files
    if [[ -f "$KEY_FILE" ]]; then
        if command -v shred &> /dev/null; then
            shred -u "$KEY_FILE" 2>/dev/null || rm -f "$KEY_FILE"
        else
            rm -f "$KEY_FILE"
        fi
        echo "✓ Private key file deleted"
    fi
    
    if [[ -f "$PUB_FILE" ]]; then
        rm -f "$PUB_FILE"
        echo "✓ Public key file deleted"
    fi
    
    # Remove temp directory
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
        echo "✓ Temporary directory removed"
    fi
    
    echo ""
    if [[ $exit_code -eq 0 ]]; then
        echo "============================================"
        echo "  ✓ Task completed successfully"
        echo "============================================"
    else
        echo "============================================"
        echo "  ✗ Task failed with exit code: $exit_code"
        echo "============================================"
    fi
    
    exit $exit_code
}

trap cleanup EXIT INT TERM

########################################
# Secure file permissions
########################################

umask 077

########################################
# Step 4: Write key files
########################################

echo "Step 4: Creating key files..."

printf '%s' "$COSIGN_PRIVATE_KEY" > "$KEY_FILE"
chmod 600 "$KEY_FILE"

printf '%s' "$COSIGN_PUBLIC_KEY" > "$PUB_FILE"
chmod 644 "$PUB_FILE"

echo "✓ Private and public key files created"
echo ""

########################################
# Step 5: Set environment variables
########################################

echo "Step 5: Setting Cosign environment variables..."

# Export password for Cosign
export COSIGN_PASSWORD

# Air-gapped environment configuration
export COSIGN_EXPERIMENTAL=0
export SIGSTORE_NO_CACHE=true
export COSIGN_YES=true

echo "✓ Environment variables configured for air-gapped mode"
echo ""

########################################
# Step 6: Docker login
########################################

echo "Step 6: Logging into Docker registry..."

DOCKER_REGISTRY_URL="${DOCKER_REGISTRY_URL:-}"
DOCKER_USERNAME="${DOCKER_REGISTRY_USERNAME:-}"
DOCKER_PASSWORD="${DOCKER_REGISTRY_PASSWORD:-}"

if [[ -z "$DOCKER_REGISTRY_URL" || -z "$DOCKER_USERNAME" || -z "$DOCKER_PASSWORD" ]]; then
    echo "##vso[task.logissue type=error]Docker registry credentials not found"
    exit 1
fi

# Mask Docker password in logs
echo "##vso[task.setsecret]${DOCKER_PASSWORD}"

# Remove protocol from registry URL for docker login
DOCKER_LOGIN_URL="${DOCKER_REGISTRY_URL#http://}"
DOCKER_LOGIN_URL="${DOCKER_LOGIN_URL#https://}"

echo "Registry: ${DOCKER_LOGIN_URL}"

if echo "${DOCKER_PASSWORD}" | docker login "${DOCKER_LOGIN_URL}" -u "${DOCKER_USERNAME}" --password-stdin; then
    echo "✓ Docker login successful"
else
    echo "##vso[task.logissue type=error]Docker login failed"
    exit 1
fi
echo ""

########################################
# Step 7: Find image digest
########################################

echo "Step 7: Resolving image digest..."

IMAGE_REF="${IMAGE_NAME}:${IMAGE_TAG}"
echo "Image reference: ${IMAGE_REF}"

# Check if docker is available
if ! command -v docker &> /dev/null; then
    echo "##vso[task.logissue type=error]Docker command not found. Please ensure Docker is installed on the agent."
    exit 1
fi

# Try to get digest from local image first
DIGEST_REF=""
if docker inspect "$IMAGE_REF" &> /dev/null; then
    DIGEST_REF="$(docker inspect --format='{{join .RepoDigests "\n"}}' "${IMAGE_REF}" 2>/dev/null | head -n 1 || true)"
fi

# If local inspection fails, try manifest inspect
if [[ -z "$DIGEST_REF" ]]; then
    echo "Local inspect failed, trying manifest inspect..."
    DIGEST=$(docker manifest inspect "${IMAGE_REF}" 2>/dev/null | grep -Po '"digest":\s*"\K[^"]+' | head -n 1 || true)
    if [[ -n "$DIGEST" ]]; then
        DIGEST_REF="${IMAGE_NAME}@${DIGEST}"
    fi
fi

if [[ -z "$DIGEST_REF" ]]; then
    echo "##vso[task.logissue type=error]Failed to resolve image digest. Ensure the image exists and is accessible."
    exit 1
fi

echo "✓ Resolved digest reference: ${DIGEST_REF}"
echo ""

########################################
# Step 8: Sign the image
########################################

echo "Step 8: Signing image with Cosign..."

COSIGN_ARGS=(
    "sign"
    "--key" "$KEY_FILE"
    "--yes"
    "--tlog-upload=false"
)

if [[ "$ALLOW_INSECURE" == "true" ]]; then
    COSIGN_ARGS+=("--allow-insecure-registry")
fi

COSIGN_ARGS+=("$DIGEST_REF")

if ! cosign "${COSIGN_ARGS[@]}"; then
    echo "##vso[task.logissue type=error]Failed to sign image"
    exit 1
fi

echo "✓ Image signed successfully"
echo ""

########################################
# Step 7: Verify signature (optional)
########################################

if [[ "$VERIFY_SIGNATURE" == "true" ]]; then
    echo "Step 8.1: Verifying signature..."
    
    VERIFY_ARGS=(
        "verify"
        "--key" "$PUB_FILE"
        "--insecure-ignore-tlog=true"
    )
    
    if [[ "$ALLOW_INSECURE" == "true" ]]; then
        VERIFY_ARGS+=("--allow-insecure-registry")
    fi
    
    VERIFY_ARGS+=("$IMAGE_REF")
    
    # Run verification and capture output
    if VERIFY_OUTPUT=$(cosign "${VERIFY_ARGS[@]}" 2>&1); then
        echo "✓ Signature verified successfully"
        
        # Extract and display identity if jq is available
        if command -v jq &> /dev/null; then
            IDENTITY=$(echo "$VERIFY_OUTPUT" | jq -r '.[].critical.identity.docker-reference' 2>/dev/null || true)
            if [[ -n "$IDENTITY" ]]; then
                echo "  Identity: ${IDENTITY}"
            fi
        fi
    else
        echo "##vso[task.logissue type=warning]Signature verification failed"
        echo "$VERIFY_OUTPUT"
    fi
    echo ""
fi

########################################
# Success - cleanup will run via trap
########################################

exit 0