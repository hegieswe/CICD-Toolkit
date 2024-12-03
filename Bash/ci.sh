#!/usr/bin/env bash

# Function to check command and exit with an error message if it fails
check_command() {
    if ! $1; then
        echo " ❌ Error: $2"
        exit 1
    fi
}

# Function to check Docker login
check_docker_login() {
    docker info > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo " ❌ Docker not detected. Please ensure Docker is installed and you are logged into Docker Hub."
        exit 1
    fi
}

# Function to build Docker image
build_docker_image() {
    echo "🔨 Building Docker image..."
    docker build -t "$1" .
    check_command "docker build -t $1 ." "Docker image build failed"
    echo "✅ Docker image build successful: $1"
}

# Function to analyze vulnerabilities using Docker Scout
analyze_vulnerabilities() {
    echo "🔍 Analyzing vulnerabilities with Docker Scout..."
    docker scout cves "$1"
    check_command "docker scout cves $1" "Vulnerability analysis failed"
    echo "✅ Vulnerability analysis completed successfully."
}

# Function to push Docker image to Docker Hub
push_docker_image() {
    echo "🚀 Pushing Docker image to Docker Hub..."
    docker push "$1"
    check_command "docker push $1" "Docker image push failed"
    echo "✅ Docker image pushed successfully to Docker Hub: $1"
}

# Check Docker login and installation
check_docker_login

# Get repository name from the remote Git URL using git rev-parse
REPO_NAME=$(basename -s .git "$(git config --get remote.origin.url)")

# Check for tag or commit ID for Docker image tag
TAG=$(git describe --tags --exact-match 2>/dev/null)
if [ -n "$TAG" ]; then
    COMMIT_TAG="$TAG"
else
    COMMIT_TAG=$(git rev-parse --short=5 HEAD)
fi

# Define Docker image name (e.g., <username>/<repo-name>:<commit-id>)
DOCKER_USERNAME="loyaltolpi"
IMAGE_TAG="${DOCKER_USERNAME}/${REPO_NAME}:${COMMIT_TAG}"

# Display the Docker image information
echo "🖼️ Docker image name: ${IMAGE_TAG}"

# Build Docker image
build_docker_image "$IMAGE_TAG"

# Analyze vulnerabilities
analyze_vulnerabilities "$IMAGE_TAG"

# Push Docker image to Docker Hub
push_docker_image "$IMAGE_TAG"
