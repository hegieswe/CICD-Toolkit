#!/bin/bash

# Fungsi untuk keluar dengan error
error_exit() {
    echo "❌ Error: $1"
    exit 1
}

# Validasi input environment
ENV="$1"
if [[ "$ENV" != "develop" && "$ENV" != "staging" && "$ENV" != "production" ]]; then
    error_exit "Usage: $0 <develop|staging|production>"
fi

# Path file JSON dan YAML
INIT_FILE="DevOps/cicd-init.json"
VALUES_FILE="DevOps/Values/${ENV}-values.yaml"

# Pastikan file JSON ada
[ ! -f "$INIT_FILE" ] && error_exit "File $INIT_FILE tidak ditemukan."

# Parsing dari cicd-init.json
PROJECT=$(jq -r .project "$INIT_FILE")
NAME=$(jq -r .name "$INIT_FILE")
SERVER=$(jq -r .server "$INIT_FILE")
PORT=$(jq -r .port "$INIT_FILE")
CHART=$(jq -r .chart "$INIT_FILE")

# Validasi parsing
[ -z "$PROJECT" ] && error_exit "project tidak ditemukan di $INIT_FILE"
[ -z "$NAME" ] && error_exit "name tidak ditemukan di $INIT_FILE"
[ -z "$SERVER" ] && error_exit "server tidak ditemukan di $INIT_FILE"
[ -z "$PORT" ] && error_exit "port tidak ditemukan di $INIT_FILE"
[ -z "$CHART" ] && error_exit "chart tidak ditemukan di $INIT_FILE"

# Dapatkan tag Git atau fallback ke commit ID
GIT_TAG=$(git describe --tags --exact-match 2>/dev/null)
if [ -n "$GIT_TAG" ]; then
    IMAGE_TAG="$GIT_TAG"
else
    IMAGE_TAG=$(git rev-parse --short=7 HEAD)
fi

# Output informatif
echo ""
echo "📦 Deployment Metadata"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Project   : $PROJECT"
echo " Branch    : $ENV"
echo " Name      : $NAME"
echo " Tag/Commit: $IMAGE_TAG"
echo " Server    : $SERVER"
echo " Port      : $PORT"
echo " Chart     : $CHART"
echo " Values    : $VALUES_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Update values.yaml menggunakan yq
yq e -i ".appDescriptor.project = \"$PROJECT\"" "$VALUES_FILE"
yq e -i ".appDescriptor.name = \"$NAME\"" "$VALUES_FILE"
yq e -i ".appDescriptor.env = \"$ENV\"" "$VALUES_FILE"
yq e -i ".appDescriptor.server = \"$SERVER\"" "$VALUES_FILE"
yq e -i ".service.port = $PORT" "$VALUES_FILE"
yq e -i ".image.repository = \"loyaltolpi/$NAME\"" "$VALUES_FILE"
yq e -i ".image.tag = \"$IMAGE_TAG\"" "$VALUES_FILE"
yq e -i ".volumes[0].name = \"secret-${PROJECT}-volume\"" "$VALUES_FILE"
yq e -i ".volumes[0].secret.secretName = \"secret-$NAME\"" "$VALUES_FILE"
yq e -i ".volumeMounts[0].name = \"secret-${PROJECT}-volume\"" "$VALUES_FILE"

echo "✅ Berhasil parsing metadata ke file Helm values untuk environment: $ENV"
