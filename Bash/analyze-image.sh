#!/usr/bin/env bash
set -euo pipefail

# Exit on error
die() {
    echo "❌ Error: $1" >&2
    exit 1
}

# Check Docker Scout availability
command -v docker > /dev/null || die "'docker' command not found."
docker scout version > /dev/null 2>&1 || die "'docker scout' is not available. Please install Docker Scout."

# Use DOCKER_USERNAME and REPO_NAME from environment or infer from Git
DOCKER_USERNAME="${DOCKER_USERNAME:-loyaltolpi}"
REPO_NAME="${REPO_NAME:-$(basename -s .git "$(git config --get remote.origin.url)")}"
TAG="${TAG:-$(git describe --tags --exact-match 2>/dev/null || git rev-parse --short=7 HEAD)}"

IMAGE_TAG="${DOCKER_USERNAME}/${REPO_NAME}:${TAG}"

echo "🔍 Analyzing image vulnerabilities for: $IMAGE_TAG"
docker scout cves "$IMAGE_TAG"
