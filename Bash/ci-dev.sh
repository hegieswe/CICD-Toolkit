#!/usr/bin/env bash
set -euo pipefail

die() {
    echo "❌ Error: $1" >&2
    exit 1
}

docker info > /dev/null || die "Docker daemon tidak aktif"
command -v docker > /dev/null || die "'docker' tidak ditemukan"

if ! docker scout version &>/dev/null; then
    echo "⚠️  Docker Scout belum tersedia. Analisis CVE akan dilewati."
    ENABLE_SCOUT=false
else
    ENABLE_SCOUT=true
fi

REPO_NAME=$(basename -s .git "$(git config --get remote.origin.url)")
[ -z "$REPO_NAME" ] && die "Tidak dapat mendeteksi nama repository dari Git"

TAG=$(git describe --tags --exact-match 2>/dev/null || git rev-parse --short=7 HEAD)
DOCKER_USERNAME="${DOCKER_USERNAME:-loyaltolpi}"
IMAGE_TAG="${DOCKER_USERNAME}/${REPO_NAME}:${TAG}"

echo ""
echo "🧪 Build lokal untuk troubleshooting:"
echo "   📦 Image     : $IMAGE_TAG"
echo "   🧾 Provenance: skipped (not supported in local --load)"
echo "   📜 SBOM      : skipped"
echo "   🚫 Push      : skipped (local only)"
echo ""

docker buildx build \
  --builder default \
  --tag "$IMAGE_TAG" \
  --load \
  .

echo ""
echo "✅ Build lokal selesai. Image tersedia secara lokal: $IMAGE_TAG"

if [ "$ENABLE_SCOUT" = true ]; then
    echo ""
    echo "🔍 Analisis kerentanan dengan Docker Scout..."
    docker scout cves "$IMAGE_TAG" || echo "⚠️  Analisis CVE gagal"
else
    echo "ℹ️  Docker Scout tidak tersedia. Lewati analisis CVE."
fi
