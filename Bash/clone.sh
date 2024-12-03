#!/bin/bash

# Path to the JSON file containing username and token
AUTH_FILE="$HOME/.devops/auth.json"

# Function to check if a file exists
check_file_exists() {
    if [ ! -f "$1" ]; then
        echo " ❌ Error: File $1 not found."
        exit 1
    fi
}

# Function to check if jq is installed
check_jq_installed() {
    if ! command -v jq > /dev/null 2>&1; then
        echo " ❌ Error: jq is not installed. Please install jq first."
        exit 1
    fi
}

# Function to validate user input (repository name and branch/tag)
validate_input() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo " ❌ Error: The repository name and branch must be provided."
        echo " 📚 Usage: $0 <repository_name> <branch_or_tag>"
        exit 1
    fi
}

# Function to retrieve username and token from the JSON file
get_credentials() {
    USERNAME=$(jq -r '.usernameBitbucket' "$1")
    TOKEN=$(jq -r '.tokenBitbucket' "$1")

    if [ -z "$USERNAME" ] || [ -z "$TOKEN" ]; then
        echo " ❌ Error: Username or token not found in $1."
        exit 1
    fi
}

# Function to remove the existing directory if it exists
remove_existing_directory() {
    if [ -d "$1" ]; then
        echo " ⚠️  The directory $1 already exists. Deleting the old directory..."
        rm -rf "$1" || { echo " ❌ Failed to delete the old directory."; exit 1; }
        echo " ✅ The old directory $1 has been successfully deleted."
    fi
}

# Function to clone the repository
clone_repository() {
    AUTH_URL="https://${USERNAME}:${TOKEN}@bitbucket.org/loyaltoid/$1.git"
    if git clone --branch "$2" "$AUTH_URL" "$1"; then
        echo -e "\033[32m✅ The repository has been successfully cloned.\033[0m"
        echo " 📦 Repository: $1"
        echo " 🏷️  Branch/Tag: $2"
        echo " 📍 Location: $(pwd)/$1"
    else
        echo -e "\033[31m❌ Failed to clone the repository.\033[0m"
        exit 1
    fi
}

# ---- MAIN SCRIPT ----

# Validate user input
DEST_DIR="$1"
BRANCH_OR_TAG="$2"
validate_input "$DEST_DIR" "$BRANCH_OR_TAG"

# Check if authentication file exists
check_file_exists "$AUTH_FILE"

# Check if jq is installed
check_jq_installed

# Retrieve credentials (username and token) from the authentication file
get_credentials "$AUTH_FILE"

# Remove existing directory if needed
remove_existing_directory "$DEST_DIR"

# Clone the repository
clone_repository "$DEST_DIR" "$BRANCH_OR_TAG"
