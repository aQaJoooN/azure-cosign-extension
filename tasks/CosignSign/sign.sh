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

echo "Image Name: ${IMAGE_NAME}"
echo "Image Tag: ${IMAGE_TAG}"
echo "Allow Insecure Registry: ${ALLOW_INSECURE}"
echo "Verify Signature: ${VERIFY_SIGNATURE}"
echo ""

########################################
# Get secrets from service connection
########################################

echo "Step 1: Retrieving credentials from service connection..."

COSIGN_PASSWORD_VAR="ENDPOINT_AUTH_PARAMETER_${ENDPOINT_ID}_COSIGNPASSWORD"
COSIGN_PRIVATE_KEY_VAR="ENDPOINT_AUTH_PARAMETER_${ENDPOINT_ID}_COSIGNPRIVATEKEY"
COSIGN_PUBLIC_KEY_VAR="ENDPOINT_AUTH_PARAMETER_${ENDPOINT_ID}_COSIGNPUBLICKEY"

COSIGN_PASSWORD="${!COSIGN_PASSWORD_VAR:-}"
COSIGN_PRIVATE_KEY="${!COSIGN_PRIVATE_KEY_VAR:-}"
COSIGN_PUBLIC_KEY="${!COSIGN_PUBLIC_KEY_VAR:-}"

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
# Step 2: Create secure temp directory
########################################

echo "Step 2: Creating secure temporary directory..."

TEMP_DIR="$(mktemp -d)"
KEY_FILE="${TEMP_DIR}/cosign.key"
PUB_FILE="${TEMP_DIR}/cosign.pub"

echo "✓ Temporary directory created: ${TEMP_DIR}"
echo ""

########################################
# Cleanup function
########################################

cleanup() {
    local exit_code=$?
    
    echo ""
    echo "Step 7: Cleaning up sensitive data..."
    
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
# Step 3: Write key files
########################################

echo "Step 3: Creating key files..."

printf '%s' "$COSIGN_PRIVATE_KEY" > "$KEY_FILE"
chmod 600 "$KEY_FILE"

printf '%s' "$COSIGN_PUBLIC_KEY" > "$PUB_FILE"
chmod 644 "$PUB_FILE"

echo "✓ Private and public key files created"
echo ""

########################################
# Step 4: Set environment variables
########################################

echo "Step 4: Setting Cosign environment variables..."

# Export password for Cosign
export COSIGN_PASSWORD

# Air-gapped environment configuration
export COSIGN_EXPERIMENTAL=0
export SIGSTORE_NO_CACHE=true
export COSIGN_YES=true

echo "✓ Environment variables configured for air-gapped mode"
echo ""

########################################
# Step 5: Find image digest
########################################

echo "Step 5: Resolving image digest..."

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
# Step 6: Sign the image
########################################

echo "Step 6: Signing image with Cosign..."

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
    echo "Step 6.1: Verifying signature..."
    
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