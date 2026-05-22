#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/.ub20-gpu.env}"
RECREATE=0

for arg in "$@"; do
  case "$arg" in
    --recreate)
      RECREATE=1
      ;;
    -h|--help)
      cat <<'EOF'
Usage: ./run.sh [options]

Options:
  --recreate  Remove an existing stopped/running container and create it again.
  -h, --help  Show this help.
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 2
      ;;
  esac
done

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE. Run ./configure.sh first." >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

IMAGE_NAME="${IMAGE_NAME:-ub20-gpu}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
CONTAINER_NAME="${CONTAINER_NAME:-ub20-gpu}"
CONTAINER_SHELL="${CONTAINER_SHELL:-zsh}"
CONTAINER_WORKDIR="${CONTAINER_WORKDIR:-/workspace}"
HOST_WORKDIR="${HOST_WORKDIR:-$SCRIPT_DIR/workspace}"
ENABLE_GPU="${ENABLE_GPU:-1}"
NETWORK_HOST="${NETWORK_HOST:-1}"
SHM_SIZE="${SHM_SIZE:-512m}"
MOUNT_DATASET="${MOUNT_DATASET:-0}"
HOST_DATASET_DIR="${HOST_DATASET_DIR:-}"
CONTAINER_DATASET_DIR="${CONTAINER_DATASET_DIR:-/data}"
VIM_CLIPBOARD="${VIM_CLIPBOARD:-1}"

IMAGE_REF="${IMAGE_NAME}:${IMAGE_TAG}"

container_exists() {
  docker container inspect "$CONTAINER_NAME" >/dev/null 2>&1
}

container_running() {
  [[ "$(docker container inspect -f '{{.State.Running}}' "$CONTAINER_NAME" 2>/dev/null || true)" == "true" ]]
}

ensure_dir() {
  local path="$1"
  local label="$2"

  if [[ -z "$path" ]]; then
    echo "$label path is empty." >&2
    exit 1
  fi

  if [[ ! -d "$path" ]]; then
    echo "Creating $label directory: $path"
    mkdir -p "$path"
  fi
}

if [[ "$RECREATE" -eq 1 ]] && container_exists; then
  docker rm -f "$CONTAINER_NAME"
fi

if container_exists; then
  if container_running; then
    docker exec -it "$CONTAINER_NAME" "$CONTAINER_SHELL" -l
  else
    docker start -ai "$CONTAINER_NAME"
  fi
  exit 0
fi

ensure_dir "$HOST_WORKDIR" "workspace"

run_args=(
  run
  -it
  --name "$CONTAINER_NAME"
  --hostname "$CONTAINER_NAME"
  --workdir "$CONTAINER_WORKDIR"
  --shm-size "$SHM_SIZE"
  -v "$HOST_WORKDIR:$CONTAINER_WORKDIR"
)

if [[ "$ENABLE_GPU" == "1" ]]; then
  run_args+=(--gpus all)
fi

if [[ "$NETWORK_HOST" == "1" ]]; then
  run_args+=(--network host)
fi

if [[ "$MOUNT_DATASET" == "1" ]]; then
  ensure_dir "$HOST_DATASET_DIR" "dataset"
  run_args+=(-v "$HOST_DATASET_DIR:$CONTAINER_DATASET_DIR")
fi

if [[ "$VIM_CLIPBOARD" == "1" && -n "${DISPLAY:-}" && -d /tmp/.X11-unix ]]; then
  run_args+=(-e "DISPLAY=${DISPLAY}" -v /tmp/.X11-unix:/tmp/.X11-unix:rw)
fi

run_args+=("$IMAGE_REF" "$CONTAINER_SHELL" "-l")

docker "${run_args[@]}"
