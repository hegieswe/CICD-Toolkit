#!/usr/bin/env bash
set -euo pipefail

# Exit with an error message
die() {
    echo "❌ Error: $1" >&2
    exit 1
}

# Check dependencies
docker info > /dev/null 2>&1 || die "Docker is not available. Make sure Docker is running and you're logged in."
command -v docker > /dev/null || die "'docker' command not found."
command -v docker buildx > /dev/null || die "'docker buildx' is required. Please update Docker."
command -v jq > /dev/null || die "'jq' is required. Please install jq."

# Ensure the 'attest-builder' exists
if ! docker buildx inspect attest-builder >/dev/null 2>&1; then
    echo "⚙️  Creating builder 'attest-builder' with docker-container driver..."
    docker buildx create --name attest-builder --driver docker-container --use
else
    docker buildx use attest-builder
fi

# Load metadata from JSON
INIT_FILE="DevOps/cicd-init.json"
[ -f "$INIT_FILE" ] || die "File $INIT_FILE tidak ditemukan."

PROJECT_NAME=$(jq -r '.name' "$INIT_FILE")
PORT=$(jq -r '.port' "$INIT_FILE")

# Validasi
[ -z "$PROJECT_NAME" ] || [ "$PROJECT_NAME" == "null" ] && die "Field .name tidak ditemukan atau kosong di $INIT_FILE"
[ -z "$PORT" ] || [ "$PORT" == "null" ] && die "Field .port tidak ditemukan atau kosong di $INIT_FILE"

# Get Git tag or fallback to commit hash
TAG=$(git describe --tags --exact-match 2>/dev/null || git rev-parse --short=7 HEAD)

# Docker Hub username default
DOCKER_USERNAME="${DOCKER_USERNAME:-loyaltolpi}"
IMAGE_TAG="${DOCKER_USERNAME}/${PROJECT_NAME}:${TAG}"

# Show build info
echo ""
echo "🛠️  Building and pushing Docker image with attestations:"
echo "   📦 Image     : $IMAGE_TAG"
echo "   📂 Project   : $PROJECT_NAME"
echo "   🔌 Port      : $PORT"
echo "   🧾 Provenance: enabled (mode=max)"
echo "   📜 SBOM      : enabled"
echo ""

# Build & Push
docker buildx build \
    --no-cache \
    --builder attest-builder \
    --build-arg PROJECT="$PROJECT_NAME" \
    --build-arg PORT="$PORT" \
    --tag "$IMAGE_TAG" \
    --sbom=true \
    --attest type=provenance,mode=max \
    --push \
    .

echo ""
echo "✅ Image built and pushed successfully: $IMAGE_TAG"
