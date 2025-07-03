#!/bin/bash

# Valid project names
VALID_PROJECTS=("apigateway" "gohttp" "goduoenv" "gogrpc")

# Function to show error and exit
error_exit() {
    echo "❌ Error: $1"
    exit 1
}

# Function to download a file using curl
download_file() {
    local URL="$1"
    local DEST="$2"
    echo "📥 [DOWNLOAD] Downloading from $URL..."
    curl -s -o "$DEST" "$URL" || error_exit "Failed to download $DEST"
    echo "✅ [DONE] Downloaded: $DEST"
}

# Function to remove existing file or directory
remove_existing() {
    local TARGET="$1"
    if [ -e "$TARGET" ]; then
        echo "🗑️ [CLEANUP] $TARGET already exists. Removing it..."
        rm -rf "$TARGET"
    fi
}

# Function to auto-adjust cicd-init.json based on current repository
adjust_cicd_json_by_repo() {
    local JSON_FILE="DevOps/cicd-init.json"
    local REPO_NAME
    REPO_NAME=$(basename -s .git "$(git config --get remote.origin.url)")

    [[ -z "$REPO_NAME" || ! -f "$JSON_FILE" ]] && return

    local PROJECT_PREFIX
    PROJECT_PREFIX=$(echo "$REPO_NAME" | cut -d'-' -f1)

    local NAME="$REPO_NAME"

    local SERVER
    if [[ "$REPO_NAME" == *"manager"* || "$REPO_NAME" == *"apigateway"* ]]; then
        SERVER="front"
    elif [[ "$REPO_NAME" == *"module"* ]]; then
        SERVER="back"
    else
        SERVER="unknown"
    fi

    echo "🔧 Updating DevOps/cicd-init.json with:"
    echo "   - server : $SERVER"
    echo "   - project: $PROJECT_PREFIX"
    echo "   - name   : $NAME"

    jq \
        --arg server "$SERVER" \
        --arg project "$PROJECT_PREFIX" \
        --arg name "$NAME" \
        '.server = $server | .project = $project | .name = $name' \
        "$JSON_FILE" > "$JSON_FILE.tmp" && mv "$JSON_FILE.tmp" "$JSON_FILE"
}

# Main project initialization
init_project() {
    local PROJECT_NAME="$1"
    local DOCKERFILE_URL INIT_JSON_URL VALUES_YAML_URL

    case "$PROJECT_NAME" in
        apigateway)
            DOCKERFILE_URL="https://raw.githubusercontent.com/hegieswe/CICD-Toolkit/main/Dockerfile/Dockerfile-apigateway"
            INIT_JSON_URL="https://raw.githubusercontent.com/hegieswe/CICD-Toolkit/main/Initial/init-apigateway.json"
            VALUES_YAML_URL="https://raw.githubusercontent.com/hegieswe/K8S-Toolkit/main/apigateway-chart/values.yaml"
            ;;
        gohttp)
            DOCKERFILE_URL="https://raw.githubusercontent.com/hegieswe/CICD-Toolkit/main/Dockerfile/Dockerfile-golang"
            INIT_JSON_URL="https://raw.githubusercontent.com/hegieswe/CICD-Toolkit/main/Initial/init-gohttp.json"
            VALUES_YAML_URL="https://raw.githubusercontent.com/hegieswe/K8S-Toolkit/main/gohttp-chart/values.yaml"
            ;;
        goduoenv)
            DOCKERFILE_URL="https://raw.githubusercontent.com/hegieswe/CICD-Toolkit/main/Dockerfile/Dockerfile-golang"
            INIT_JSON_URL="https://raw.githubusercontent.com/hegieswe/CICD-Toolkit/main/Initial/init-goduoenv.json"
            VALUES_YAML_URL="https://raw.githubusercontent.com/hegieswe/K8S-Toolkit/main/goduoenv-chart/values.yaml"
            ;;
        gogrpc)
            DOCKERFILE_URL="https://raw.githubusercontent.com/hegieswe/CICD-Toolkit/main/Dockerfile/Dockerfile-golang"
            INIT_JSON_URL="https://raw.githubusercontent.com/hegieswe/CICD-Toolkit/main/Initial/init-gogrpc.json"
            VALUES_YAML_URL="https://raw.githubusercontent.com/hegieswe/K8S-Toolkit/main/gogrpc-chart/values.yaml"
            ;;
        *)
            error_exit "Unknown project '$PROJECT_NAME'. Valid options: ${VALID_PROJECTS[*]}"
            ;;
    esac

    echo "🐋 [DOCKERFILE] Preparing Dockerfile..."
    remove_existing "Dockerfile"
    download_file "$DOCKERFILE_URL" "Dockerfile"

    echo "📂 [DIRECTORY] Setting up DevOps directory..."
    remove_existing "DevOps"
    mkdir -p DevOps/Values

    echo "📄 [JSON] Downloading initialization JSON..."
    remove_existing "DevOps/cicd-init.json"
    download_file "$INIT_JSON_URL" "DevOps/cicd-init.json"

    echo "⚙️ [HELM-CHART] Downloading Helm values.yaml..."
    remove_existing "DevOps/Values/values.yaml"
    download_file "$VALUES_YAML_URL" "DevOps/Values/values.yaml"

    echo "📝 [COPIES] Creating develop, staging, and production values.yaml files..."
    cp DevOps/Values/values.yaml DevOps/Values/develop-values.yaml
    cp DevOps/Values/values.yaml DevOps/Values/staging-values.yaml
    cp DevOps/Values/values.yaml DevOps/Values/production-values.yaml
    rm DevOps/Values/values.yaml

    adjust_cicd_json_by_repo

    echo "🎉 [SUCCESS] Project '$PROJECT_NAME' has been initialized successfully."
}

# === MAIN ===

if [ -z "$1" ]; then
    error_exit "Please provide a project name (e.g., apigateway, gohttp, goduoenv, gogrpc)."
fi

if [[ ! " ${VALID_PROJECTS[*]} " =~ " $1 " ]]; then
    error_exit "Invalid project '$1'. Valid options: ${VALID_PROJECTS[*]}"
fi

init_project "$1"
