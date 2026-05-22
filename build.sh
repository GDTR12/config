#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/.ub20-gpu.env}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Missing $ENV_FILE. Run ./configure.sh first." >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

IMAGE_NAME="${IMAGE_NAME:-ub20-gpu}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
BASE_IMAGE="${BASE_IMAGE:-ubuntu:20.04}"
CONTAINER_USER="${CONTAINER_USER:-dev}"
CONTAINER_SHELL="${CONTAINER_SHELL:-zsh}"
CONTAINER_WORKDIR="${CONTAINER_WORKDIR:-/workspace}"
SYNC_UID_GID="${SYNC_UID_GID:-1}"
if [[ "$SYNC_UID_GID" == "1" ]]; then
  HOST_UID="$(id -u)"
  HOST_GID="$(id -g)"
else
  HOST_UID="${HOST_UID:-1000}"
  HOST_GID="${HOST_GID:-1000}"
fi
DEFAULT_PACKAGES="${DEFAULT_PACKAGES:-git vim-gtk3 curl wget cmake htop ripgrep tmux zsh sudo ca-certificates build-essential}"
INSTALL_MINICONDA="${INSTALL_MINICONDA:-1}"
CONDA_DIR="${CONDA_DIR:-/opt/conda}"
CONDA_AUTO_ACTIVATE_BASE="${CONDA_AUTO_ACTIVATE_BASE:-0}"
INSTALL_OH_MY_ZSH="${INSTALL_OH_MY_ZSH:-1}"
ZSH_THEME="${ZSH_THEME:-powerlevel10k/powerlevel10k}"
ZSH_PLUGINS="${ZSH_PLUGINS:-git vi-mode sudo z zsh-autosuggestions zsh-syntax-highlighting}"
COPY_TMUX_CONF="${COPY_TMUX_CONF:-1}"
VIM_CLIPBOARD="${VIM_CLIPBOARD:-1}"

IMAGE_REF="${IMAGE_NAME}:${IMAGE_TAG}"

echo "Building ${IMAGE_REF} from ${BASE_IMAGE}"

docker build \
  --file "$SCRIPT_DIR/Dockerfile" \
  --tag "$IMAGE_REF" \
  --build-arg BASE_IMAGE="$BASE_IMAGE" \
  --build-arg USERNAME="$CONTAINER_USER" \
  --build-arg USER_UID="$HOST_UID" \
  --build-arg USER_GID="$HOST_GID" \
  --build-arg CONTAINER_SHELL="$CONTAINER_SHELL" \
  --build-arg CONTAINER_WORKDIR="$CONTAINER_WORKDIR" \
  --build-arg DEFAULT_PACKAGES="$DEFAULT_PACKAGES" \
  --build-arg INSTALL_MINICONDA="$INSTALL_MINICONDA" \
  --build-arg CONDA_DIR="$CONDA_DIR" \
  --build-arg CONDA_AUTO_ACTIVATE_BASE="$CONDA_AUTO_ACTIVATE_BASE" \
  --build-arg INSTALL_OH_MY_ZSH="$INSTALL_OH_MY_ZSH" \
  --build-arg ZSH_THEME="$ZSH_THEME" \
  --build-arg ZSH_PLUGINS="$ZSH_PLUGINS" \
  --build-arg COPY_TMUX_CONF="$COPY_TMUX_CONF" \
  --build-arg VIM_CLIPBOARD="$VIM_CLIPBOARD" \
  "$SCRIPT_DIR"

echo "Built ${IMAGE_REF}"
