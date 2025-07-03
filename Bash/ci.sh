#!/usr/bin/env bash
set -euo pipefail

# Fungsi untuk keluar dengan error
die() {
    echo "❌ Error: $1" >&2
    exit 1
}

# Cek semua tool yang dibutuhkan
docker info > /dev/null 2>&1 || die "Docker tidak tersedia. Pastikan Docker sudah jalan dan kamu sudah login."
command -v docker > /dev/null || die "Perintah 'docker' tidak ditemukan."
command -v docker buildx > /dev/null || die "'docker buildx' diperlukan. Silakan install atau update Docker kamu."
command -v jq > /dev/null || die "'jq' diperlukan. Silakan install terlebih dahulu."

# Siapkan builder buildx jika belum ada
if ! docker buildx inspect attest-builder >/dev/null 2>&1; then
    echo "⚙️  Creating builder 'attest-builder' using docker-container driver..."
    docker buildx create --name attest-builder --driver docker-container --use
else
    docker buildx use attest-builder
fi

# Ambil metadata proyek dari cicd-init.json
INIT_FILE="DevOps/cicd-init.json"
[ -f "$INIT_FILE" ] || die "File $INIT_FILE not found."

PROJECT_NAME=$(jq -r '.name' "$INIT_FILE")
[ -z "$PROJECT_NAME" ] || [ "$PROJECT_NAME" == "null" ] && die "Field '.name' is missing or empty in $INIT_FILE."

# Ambil tag git kalau ada, fallback ke short commit
TAG=$(git describe --tags --exact-match 2>/dev/null || git rev-parse --short=7 HEAD)

# Tentukan nama user Docker Hub dan tag image-nya
DOCKER_USERNAME="${DOCKER_USERNAME:-loyaltolpi}"
IMAGE_TAG="${DOCKER_USERNAME}/${PROJECT_NAME}:${TAG}"

# Tampilkan informasi sebelum build
echo ""
echo "🛠️  Building and pushing Docker image with attestations"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " 📦 Image      : $IMAGE_TAG"
echo " 📂 Project    : $PROJECT_NAME"
echo " 🧾 Provenance : enabled (mode=max)"
echo " 📜 SBOM       : enabled"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Build dan push image-nya
docker buildx build \
    --no-cache \
    --builder attest-builder \
    --build-arg PROJECT="$PROJECT_NAME" \
    --tag "$IMAGE_TAG" \
    --sbom=true \
    --attest type=provenance,mode=max \
    --push \
    .

# Konfirmasi sukses
echo ""
echo "✅ Docker image has been successfully built and pushed: $IMAGE_TAG"
