#!/usr/bin/env bash

set -e

# Error handler
error_exit() {
    echo "❌ Error: $1"
    exit 1
}

# Cek dependensi helm
command -v helm >/dev/null 2>&1 || error_exit "Helm belum terinstal."
command -v kubectl >/dev/null 2>&1 || error_exit "kubectl belum terinstal."

# Pastikan helm repo ada
if ! helm repo list | grep -q "k8s-toolkit"; then
    echo "➕ Menambahkan helm repo: k8s-toolkit"
    helm repo add k8s-toolkit https://hegieswe.github.io/K8S-Toolkit/gh-pages
fi

helm repo update

# Ambil branch atau tag
BRANCH=$(git rev-parse --abbrev-ref HEAD)
TAG=$(git describe --tags --exact-match 2>/dev/null || true)

# Konfigurasi context Kubernetes
if [ -n "$TAG" ]; then
    CONTEXT="rke2-production-ue"
    ENV="production"
else
    case "$BRANCH" in
        develop)
            CONTEXT="rke2-develop-qoin"
            ENV="develop"
            ;;
        staging)
            CONTEXT="rke2-staging-qoin"
            ENV="staging"
            ;;
        *)
            error_exit "Branch tidak dikenali untuk deployment. Hanya support: develop, staging, atau tag (production)."
            ;;
    esac
fi

# Gunakan context
echo "🔧 Menggunakan Kubernetes context: $CONTEXT"
kubectl config use-context "$CONTEXT"

# Parsing file JSON
JSON_FILE="DevOps/cicd-init.json"
[ -f "$JSON_FILE" ] || error_exit "File cicd-init.json tidak ditemukan di $JSON_FILE"

PROJECT=$(jq -r '.project' "$JSON_FILE")
NAME=$(jq -r '.name' "$JSON_FILE")
SERVER=$(jq -r '.server' "$JSON_FILE")
PORT=$(jq -r '.port' "$JSON_FILE")
CHART=$(jq -r '.chart' "$JSON_FILE")

RELEASE_NAME="$NAME"
CHART_NAME="k8s-toolkit/$CHART"
VALUES_FILE="DevOps/Values/${ENV}-values.yaml"

# Ambil tag atau commit ID
if [ -n "$TAG" ]; then
    VERSION="$TAG"
else
    VERSION=$(git rev-parse --short=7 HEAD)
fi

# Tampilkan info
echo "📝 Informasi Deployment:"
echo "Project     = $PROJECT"
echo "Branch/Env  = $ENV"
echo "Name        = $NAME"
echo "Tag         = $VERSION"
echo "Server      = $SERVER"
echo "Port        = $PORT"
echo "Chart       = $CHART"
echo "Values File = $VALUES_FILE"

# Tampilkan image tag sebelum deploy
echo "🔍 Mengecek image tag saat ini di Kubernetes..."
CURRENT_IMAGE=$(kubectl get deployment "$RELEASE_NAME" -o=jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null || echo "N/A")
echo "📦 Image Sebelumnya: $CURRENT_IMAGE"

# Preview hasil helm rendering (template)
echo "🧪 [DRY RUN] Menampilkan hasil render Helm chart..."
helm template "$RELEASE_NAME" "$CHART_NAME" -f "$VALUES_FILE" --namespace default | tee DevOps/rendered-manifest.yaml > /dev/null

# Helm upgrade
echo "🚀 Melakukan deployment ke Kubernetes menggunakan Helm..."
helm upgrade --install "$RELEASE_NAME" "$CHART_NAME" -f "$VALUES_FILE" --namespace default

# Tampilkan image setelah deploy
echo "✅ Deployment selesai. Mengecek image terbaru..."
sleep 2
NEW_IMAGE=$(kubectl get deployment "$RELEASE_NAME" -o=jsonpath="{.spec.template.spec.containers[0].image}" 2>/dev/null)
echo "📦 Image Setelah Deploy: $NEW_IMAGE"
