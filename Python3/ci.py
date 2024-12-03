#!/usr/bin/env python3

import subprocess
import sys

# Function to check commands and exit with an error message if it fails
def check_command(command, error_message):
    try:
        subprocess.check_call(command, shell=True)
    except subprocess.CalledProcessError:
        print(f"❌ Error: {error_message}")
        sys.exit(1)

# Function to check Docker login
def check_docker_login():
    try:
        subprocess.check_call("docker info > /dev/null 2>&1", shell=True)
    except subprocess.CalledProcessError:
        print("❌ Docker is not detected. Please ensure Docker is installed and you are logged into Docker Hub.")
        sys.exit(1)

# Function to build Docker image
def build_docker_image(image_tag):
    print(f"🔨 Building Docker image with tag: {image_tag} ...")
    check_command(f"docker build -t {image_tag} .", "Docker image build failed")
    print(f"✅ Docker image build successful: {image_tag}")

# Function to analyze vulnerabilities using Docker Scout
def analyze_vulnerabilities(image_tag):
    print(f"🔍 Analyzing vulnerabilities for image: {image_tag} using Docker Scout...")
    check_command(f"docker scout cves {image_tag}", "Vulnerability analysis failed")
    print("✅ Vulnerability analysis successful.")

# Function to push Docker image to Docker Hub
def push_docker_image(image_tag):
    print(f"🚀 Pushing Docker image with tag: {image_tag} to Docker Hub...")
    check_command(f"docker push {image_tag}", "Docker image push failed")
    print(f"✅ Docker image successfully pushed to Docker Hub: {image_tag}")

# Function to get the repository name from the remote Git
def get_repo_name():
    repo_url = subprocess.check_output("git config --get remote.origin.url", shell=True).decode('utf-8').strip()
    return repo_url.split('/')[-1].replace('.git', '')

# Function to get the tag or commit ID
def get_commit_tag():
    try:
        # Try to get the exact matching tag
        tag = subprocess.check_output("git describe --tags --exact-match", shell=True).decode('utf-8').strip()
        if tag:
            return tag
    except subprocess.CalledProcessError:
        pass
    # If no tag, get the commit ID
    commit_id = subprocess.check_output("git rev-parse --short=5 HEAD", shell=True).decode('utf-8').strip()
    return commit_id

def main():
    # Check Docker login and Docker installation
    check_docker_login()

    # Get the repository name from the remote Git URL
    repo_name = get_repo_name()

    # Check for tag or commit ID for the Docker image tag
    commit_tag = get_commit_tag()

    # Define the Docker image name
    docker_username = "loyaltolpi"
    image_tag = f"{docker_username}/{repo_name}:{commit_tag}"

    # Display the Docker image details
    print(f"\n🚀 Building Docker Image with the following details:")
    print(f"   Repository Name: {repo_name}")
    print(f"   Docker Image Tag: {commit_tag}")
    print(f"   Full Image Tag: {image_tag}\n")

    # Build the Docker image
    build_docker_image(image_tag)

    # Analyze vulnerabilities
    analyze_vulnerabilities(image_tag)

    # Push Docker image to Docker Hub
    push_docker_image(image_tag)

if __name__ == "__main__":
    main()
