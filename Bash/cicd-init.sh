#!/bin/bash

# Daftar proyek yang valid
VALID_PROJECTS=("apigateway" "gohttp" "goduoenv" "gogrpc")

# Fungsi untuk menampilkan error dan keluar
error_exit() {
    echo "❌ Error: $1"
    exit 1
}

# Fungsi untuk mengunduh file menggunakan curl
download_file() {
    local URL="$1"
    local DEST="$2"
    
    echo "📥 [DOWNLOAD] Downloading from $URL..."
    curl -s -o "$DEST" "$URL" || error_exit "Failed to download $DEST"
    echo "✅ [DONE] Downloaded: $DEST"
}

# Fungsi untuk menghapus file atau direktori jika sudah ada
remove_existing() {
    local TARGET="$1"
    if [ -e "$TARGET" ]; then
        echo "🗑️ [CLEANUP] $TARGET already exists. Removing it..."
        rm -rf "$TARGET"
    fi
}

# Fungsi utama untuk menangani proyek
init_project() {
    local PROJECT_NAME="$1"
    local DOCKERFILE_URL INIT_JSON_URL VALUES_YAML_URL

    # Tentukan URL berdasarkan nama proyek
    case "$PROJECT_NAME" in
        apigateway)
            DOCKERFILE_URL="https://raw.githubusercontent.com/hegieswe/CICD-Toolkit/refs/heads/main/Dockerfile/Dockerfile-apigateway"
            INIT_JSON_URL="https://raw.githubusercontent.com/hegieswe/CICD-Toolkit/refs/heads/main/Initial/init-apigateway.json"
            VALUES_YAML_URL="https://raw.githubusercontent.com/hegieswe/K8S-Toolkit/refs/heads/main/apigateway-chart/values.yaml"
            ;;
        
        gohttp)
            DOCKERFILE_URL="https://raw.githubusercontent.com/hegieswe/CICD-Toolkit/refs/heads/main/Dockerfile/Dockerfile-golang"
            INIT_JSON_URL="https://raw.githubusercontent.com/hegieswe/CICD-Toolkit/refs/heads/main/Initial/init-gohttp.json"
            VALUES_YAML_URL="https://raw.githubusercontent.com/hegieswe/K8S-Toolkit/refs/heads/main/gohttp-chart/values.yaml"
            ;;
        
        goduoenv)
            DOCKERFILE_URL="https://raw.githubusercontent.com/hegieswe/CICD-Toolkit/refs/heads/main/Dockerfile/Dockerfile-golang"
            INIT_JSON_URL="https://raw.githubusercontent.com/hegieswe/CICD-Toolkit/refs/heads/main/Initial/init-goduoenv.json"
            VALUES_YAML_URL="https://raw.githubusercontent.com/hegieswe/K8S-Toolkit/refs/heads/main/goduoenv-chart/values.yaml"
            ;;
        
        gogrpc)
            DOCKERFILE_URL="https://raw.githubusercontent.com/hegieswe/CICD-Toolkit/refs/heads/main/Dockerfile/Dockerfile-golang"
            INIT_JSON_URL="https://raw.githubusercontent.com/hegieswe/CICD-Toolkit/refs/heads/main/Initial/init-gogrpc.json"
            VALUES_YAML_URL="https://raw.githubusercontent.com/hegieswe/K8S-Toolkit/refs/heads/main/gogrpc-chart/values.yaml"
            ;;
        
        *)
            error_exit "Unknown project type '$PROJECT_NAME'. Valid options are: apigateway, gohttp, goduoenv, gogrpc."
            ;;
    esac

    # Hapus dan download ulang Dockerfile
    echo "🐋 [DOCKERFILE] Processing Dockerfile..."
    remove_existing "Dockerfile"
    download_file "$DOCKERFILE_URL" "Dockerfile"

    # Hapus dan buat direktori DevOps
    echo "📂 [DIRECTORY] Setting up DevOps directory..."
    remove_existing "DevOps"
    mkdir -p DevOps/Values

    # Hapus dan download ulang JSON file
    echo "📄 [JSON] Downloading initialization file..."
    remove_existing "DevOps/cicd-init.json"
    download_file "$INIT_JSON_URL" "DevOps/cicd-init.json"

    # Hapus dan download ulang YAML helm-chart file
    echo "⚙️ [HELM-CHART] Downloading helm-chart values..."
    remove_existing "DevOps/Values/values.yaml"
    download_file "$VALUES_YAML_URL" "DevOps/Values/values.yaml"

    # Membuat tiga salinan values.yaml
    echo "📝 [COPIES] Creating develop-values.yaml, staging-values.yaml, and production-values.yaml..."
    cp DevOps/Values/values.yaml DevOps/Values/develop-values.yaml
    cp DevOps/Values/values.yaml DevOps/Values/staging-values.yaml
    cp DevOps/Values/values.yaml DevOps/Values/production-values.yaml

    # Menghapus values.yaml asli
    echo "🗑️ [CLEANUP] Removing original values.yaml..."
    rm DevOps/Values/values.yaml

    echo "🎉 [SUCCESS] Project '$PROJECT_NAME' initialized successfully."
}

# Periksa apakah nama proyek diberikan
if [ -z "$1" ]; then
    error_exit "Please provide a project name (e.g., apigateway, gohttp, goduoenv, or gogrpc)."
fi

# Validasi input terhadap daftar proyek yang valid
if [[ ! " ${VALID_PROJECTS[@]} " =~ " $1 " ]]; then
    error_exit "Unknown project type '$1'. Valid options are: apigateway, gohttp, goduoenv, gogrpc."
fi

# Jalankan fungsi untuk menginisialisasi proyek berdasarkan input
init_project "$1"
