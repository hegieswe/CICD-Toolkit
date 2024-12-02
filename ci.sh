#!/usr/bin/env bash

# Fungsi untuk memeriksa perintah dan keluar dengan pesan error jika gagal
check_command() {
    if ! $1; then
        echo " ❌ Error: $2"
        exit 1
    fi
}

# Fungsi untuk memeriksa login Docker
check_docker_login() {
    docker info > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo " ❌ Docker tidak terdeteksi. Pastikan Docker sudah terinstall dan Anda sudah login ke Docker Hub."
        exit 1
    fi
}

# Fungsi untuk membangun Docker image
build_docker_image() {
    echo "Membangun image Docker..."
    docker build -t "$1" .
    check_command "docker build -t $1 ." "Build image Docker gagal"
    echo "✅ Build image Docker berhasil: $1"
}

# Fungsi untuk menganalisis kerentanannya menggunakan Docker Scout
analyze_vulnerabilities() {
    echo "Menganalisis kerentanannya menggunakan Docker Scout..."
    docker scout cves "$1"
    check_command "docker scout cves $1" "Analisis kerentanannya gagal"
    echo "✅ Analisis kerentanannya berhasil."
}

# Fungsi untuk mendorong Docker image ke Docker Hub
push_docker_image() {
    echo "Mendorong image Docker ke Docker Hub..."
    docker push "$1"
    check_command "docker push $1" "Push image Docker gagal"
    echo "✅ Push image Docker berhasil ke Docker Hub: $1"
}

# Cek login Docker dan instalasi Docker
check_docker_login

# Ambil nama repository dari URL remote Git menggunakan git rev-parse
REPO_NAME=$(basename -s .git "$(git config --get remote.origin.url)")

# Cek tag atau commit ID untuk Docker image tag
TAG=$(git describe --tags --exact-match 2>/dev/null)
if [ -n "$TAG" ]; then
    COMMIT_TAG="$TAG"
else
    COMMIT_TAG=$(git rev-parse --short=5 HEAD)
fi

# Tentukan nama image Docker (misalnya: <username>/<repo-name>:<commit-id>)
DOCKER_USERNAME="loyaltolpi"
IMAGE_TAG="${DOCKER_USERNAME}/${REPO_NAME}:${COMMIT_TAG}"

# Tampilkan informasi image yang akan dibangun
echo "Nama image Docker: ${IMAGE_TAG}"

# Proses build image Docker
build_docker_image "$IMAGE_TAG"

# Proses analisis kerentanannya
analyze_vulnerabilities "$IMAGE_TAG"

# Push image Docker ke Docker Hub
push_docker_image "$IMAGE_TAG"
