#!/usr/bin/env bash
set -euo pipefail

# Exit with an error message
die() {
    echo "❌ Error: $1" >&2
    exit 1
}

# Check Docker and Buildx availability
docker info > /dev/null 2>&1 || die "Docker is not available. Make sure Docker is running and you're logged in."
command -v docker > /dev/null || die "'docker' command not found."
command -v docker buildx > /dev/null || die "'docker buildx' is required. Please update Docker."

# Ensure the 'attest-builder' exists with docker-container driver
if ! docker buildx inspect attest-builder >/dev/null 2>&1; then
    echo "⚙️  Creating builder 'attest-builder' with docker-container driver..."
    docker buildx create --name attest-builder --driver docker-container --use
else
    docker buildx use attest-builder
fi

# Get repository name from Git
REPO_NAME=$(basename -s .git "$(git config --get remote.origin.url)")
[ -z "$REPO_NAME" ] && die "Unable to determine repository name from Git."

# Get Git tag or fallback to short commit hash
TAG=$(git describe --tags --exact-match 2>/dev/null || git rev-parse --short=7 HEAD)

# Set Docker Hub username (default: loyaltolpi)
DOCKER_USERNAME="${DOCKER_USERNAME:-loyaltolpi}"
IMAGE_TAG="${DOCKER_USERNAME}/${REPO_NAME}:${TAG}"

# Display build information
echo ""
echo "🛠️  Building and pushing Docker image with attestations:"
echo "   📦 Image     : $IMAGE_TAG"
echo "   🧾 Provenance: enabled (mode=max)"
echo "   📜 SBOM      : enabled"
echo ""

# Build and push the image with attestations
docker buildx build \
    --no-cache \
    --builder attest-builder \
    --tag "$IMAGE_TAG" \
    --sbom=true \
    --attest type=provenance,mode=max \
    --push \
    .

echo ""
echo "✅ Image built and pushed successfully: $IMAGE_TAG"
