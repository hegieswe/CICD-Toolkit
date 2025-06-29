#!/usr/bin/env bash
set -euo pipefail

# Fungsi keluar dengan pesan error
die() {
    echo "❌ Error: $1" >&2
    exit 1
}

# Cek Docker & Buildx
docker info > /dev/null 2>&1 || die "Docker tidak tersedia. Pastikan Docker aktif dan sudah login."
command -v docker > /dev/null || die "'docker' tidak ditemukan."
command -v docker buildx > /dev/null || die "'docker buildx' tidak ditemukan. Pastikan Docker versi terbaru."

# Pastikan builder 'attest-builder' dengan driver docker-container tersedia
if ! docker buildx inspect attest-builder >/dev/null 2>&1; then
    echo "⚙️  Membuat builder 'attest-builder' dengan driver docker-container..."
    docker buildx create --name attest-builder --driver docker-container --use
else
    docker buildx use attest-builder
fi

# Ambil nama repo dari Git
REPO_NAME=$(basename -s .git "$(git config --get remote.origin.url)")
[ -z "$REPO_NAME" ] && die "Tidak dapat mendeteksi nama repository dari Git."

# Ambil tag atau commit ID
TAG=$(git describe --tags --exact-match 2>/dev/null || git rev-parse --short=7 HEAD)

# Tentukan nama image dan tag
DOCKER_USERNAME="${DOCKER_USERNAME:-loyaltolpi}"
IMAGE_TAG="${DOCKER_USERNAME}/${REPO_NAME}:${TAG}"

# Tampilkan metadata image
echo ""
echo "🛠️  Membangun dan push Docker image dengan attestation:"
echo "   📦 Image     : $IMAGE_TAG"
echo "   🧾 Provenance: enabled (mode=max)"
echo "   📜 SBOM      : enabled"
echo ""

# Bangun dan push image ke registry
docker buildx build \
    --builder attest-builder \
    --tag "$IMAGE_TAG" \
    --sbom=true \
    --attest type=provenance,mode=max \
    --push \
    .

echo ""
echo "✅ Build dan push image berhasil: $IMAGE_TAG"

# Analisis kerentanan (opsional)
echo ""
echo "🔍 Analisis kerentanan dengan Docker Scout..."
docker scout cves "$IMAGE_TAG" || echo "⚠️  Analisis CVE gagal atau tidak tersedia."
