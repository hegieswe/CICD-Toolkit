#!/bin/bash

# Fungsi buat keluar kalau error
error_exit() {
    echo "❌ Error: $1"
    exit 1
}

# Validasi input environment
ENV="$1"
if [[ "$ENV" != "develop" && "$ENV" != "staging" && "$ENV" != "production" ]]; then
    error_exit "Usage: $0 <develop|staging|production>"
fi

# Lokasi file JSON dan YAML
INIT_FILE="DevOps/cicd-init.json"
VALUES_FILE="DevOps/Values/${ENV}-values.yaml"

# Pastikan file JSON-nya ada
[ ! -f "$INIT_FILE" ] && error_exit "File $INIT_FILE not found."

# Ambil data dari cicd-init.json
PROJECT=$(jq -r .project "$INIT_FILE")
NAME=$(jq -r .name "$INIT_FILE")
SERVER=$(jq -r .server "$INIT_FILE")
PORT=$(jq -r .port "$INIT_FILE")
PORT2=$(jq -r .port2 "$INIT_FILE")
CHART=$(jq -r .chart "$INIT_FILE")

# Validasi kalau ada yang kosong
[ -z "$PROJECT" ] && error_exit "Field 'project' is missing in $INIT_FILE"
[ -z "$NAME" ] && error_exit "Field 'name' is missing in $INIT_FILE"
[ -z "$SERVER" ] && error_exit "Field 'server' is missing in $INIT_FILE"
[ -z "$PORT" ] && error_exit "Field 'port' is missing in $INIT_FILE"
[ -z "$CHART" ] && error_exit "Field 'chart' is missing in $INIT_FILE"

# Cek apakah masih ada nilai default template
DEFAULT_WARNINGS=()
[[ "$PROJECT" == "name_project" ]] && DEFAULT_WARNINGS+=("project")
[[ "$NAME" == "name_service" ]] && DEFAULT_WARNINGS+=("name")
[[ "$SERVER" == "front/back" ]] && DEFAULT_WARNINGS+=("server")
[[ "$PORT" == "http" ]] && DEFAULT_WARNINGS+=("port")
[[ "$PORT2" == "grpc" ]] && DEFAULT_WARNINGS+=("port2")

if [ ${#DEFAULT_WARNINGS[@]} -gt 0 ]; then
    echo "❌ Some fields in $INIT_FILE still use default values:"
    for field in "${DEFAULT_WARNINGS[@]}"; do
        echo "   - $field"
    done
    echo "🔧 Please replace the default values before continuing."
    exit 1
fi

# Ambil tag Git atau fallback ke commit hash
GIT_TAG=$(git describe --tags --exact-match 2>/dev/null)
if [ -n "$GIT_TAG" ]; then
    IMAGE_TAG="$GIT_TAG"
else
    IMAGE_TAG=$(git rev-parse --short=7 HEAD)
fi

# Output info ke user
echo ""
echo "📦 Deployment Metadata"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Project   : $PROJECT"
echo " Branch    : $ENV"
echo " Name      : $NAME"
echo " Tag/Commit: $IMAGE_TAG"
echo " Server    : $SERVER"
echo " Port      : $PORT"
if [[ "$PORT2" != "null" && -n "$PORT2" ]]; then
    echo " Port2     : $PORT2"
fi
echo " Chart     : $CHART"
echo " Values    : $VALUES_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Update isi values.yaml pakai yq
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

# Kalau pakai chart gogrpc dan ada port2-nya, aktifkan serviceGrpc
if [[ "$CHART" == "gogrpc-chart" && "$PORT2" != "null" && -n "$PORT2" ]]; then
    yq e -i '.serviceGrpc.enabled = true' "$VALUES_FILE"
    yq e -i '.serviceGrpc.type = "grpc"' "$VALUES_FILE"
    yq e -i ".serviceGrpc.port = $PORT2" "$VALUES_FILE"
fi

echo "✅ Metadata parsed and applied to environment: $ENV"
