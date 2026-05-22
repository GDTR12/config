#!/usr/bin/env bash
set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

IMAGE_FOR_GPU_TEST="${IMAGE_FOR_GPU_TEST:-ubuntu:20.04}"
GPU_TEST_IMAGE_SET=0
NON_INTERACTIVE=0
RUN_GPU_TEST=""

for arg in "$@"; do
  case "$arg" in
    --non-interactive)
      NON_INTERACTIVE=1
      ;;
    --gpu-test)
      RUN_GPU_TEST="yes"
      ;;
    --no-gpu-test)
      RUN_GPU_TEST="no"
      ;;
    --gpu-test-image=*)
      IMAGE_FOR_GPU_TEST="${arg#*=}"
      GPU_TEST_IMAGE_SET=1
      ;;
    -h|--help)
      cat <<'EOF'
Usage: ./preflight.sh [options]

Options:
  --non-interactive  Do not ask questions and do not install missing packages.
  --gpu-test         Run Docker GPU smoke test.
  --no-gpu-test      Skip Docker GPU smoke test.
  --gpu-test-image=IMAGE
                     Image used by the Docker GPU smoke test.
  -h, --help         Show this help.

Environment:
  IMAGE_FOR_GPU_TEST Image used by the Docker GPU smoke test. Default: ubuntu:20.04
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 2
      ;;
  esac
done

if [[ -t 1 ]]; then
  BOLD="$(printf '\033[1m')"
  DIM="$(printf '\033[2m')"
  RED="$(printf '\033[31m')"
  GREEN="$(printf '\033[32m')"
  YELLOW="$(printf '\033[33m')"
  BLUE="$(printf '\033[34m')"
  RESET="$(printf '\033[0m')"
else
  BOLD=""
  DIM=""
  RED=""
  GREEN=""
  YELLOW=""
  BLUE=""
  RESET=""
fi

PASS=0
WARN=0
FAIL=0
SKIP=0
DOCKER_READY=0
DOCKER_NVIDIA_RUNTIME_READY=0
NVIDIA_READY=0
NVIDIA_TOOLKIT_READY=0

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

headline() {
  printf '\n%s%s%s\n' "$BOLD" "$1" "$RESET"
}

info() {
  printf '%s\n' "${DIM}$1${RESET}"
}

ok() {
  PASS=$((PASS + 1))
  printf '%s[OK]%s %s\n' "$GREEN" "$RESET" "$1"
}

warn() {
  WARN=$((WARN + 1))
  printf '%s[WARN]%s %s\n' "$YELLOW" "$RESET" "$1"
}

fail() {
  FAIL=$((FAIL + 1))
  printf '%s[FAIL]%s %s\n' "$RED" "$RESET" "$1"
}

skip() {
  SKIP=$((SKIP + 1))
  printf '%s[SKIP]%s %s\n' "$BLUE" "$RESET" "$1"
}

ask_yes_no() {
  local prompt="$1"
  local default="${2:-y}"
  local answer
  local suffix

  if [[ "$NON_INTERACTIVE" -eq 1 ]]; then
    [[ "$default" =~ ^[Yy]$ ]]
    return
  fi

  if [[ "$default" =~ ^[Yy]$ ]]; then
    suffix="Y/n"
  else
    suffix="y/N"
  fi

  while true; do
    read -r -p "$prompt [$suffix]: " answer
    answer="${answer:-$default}"
    case "$answer" in
      y|Y|yes|YES|Yes)
        return 0
        ;;
      n|N|no|NO|No)
        return 1
        ;;
      *)
        echo "Please answer yes or no."
        ;;
    esac
  done
}

confirm_install() {
  local prompt="$1"
  local default="${2:-n}"

  if [[ "$NON_INTERACTIVE" -eq 1 ]]; then
    info "Non-interactive mode: skipped prompt '$prompt'."
    return 1
  fi

  if [[ ! -t 0 ]]; then
    info "No interactive stdin: skipped prompt '$prompt'."
    return 1
  fi

  ask_yes_no "$prompt" "$default"
}

capture_command() {
  local __var_name="$1"
  shift
  local __output
  local __status
  set +e
  __output="$("$@" 2>&1)"
  __status=$?
  set -e
  printf -v "$__var_name" '%s' "$__output"
  return "$__status"
}

ask_text() {
  local prompt="$1"
  local default="${2:-}"
  local answer

  if [[ "$NON_INTERACTIVE" -eq 1 ]]; then
    printf '%s' "$default"
    return
  fi

  read -r -p "$prompt [$default]: " answer
  printf '%s' "${answer:-$default}"
}

ask_choice() {
  local prompt="$1"
  local default_index="$2"
  shift 2
  local choices=("$@")
  local answer
  local i

  if [[ "$NON_INTERACTIVE" -eq 1 ]]; then
    printf '%s' "${choices[$((default_index - 1))]}"
    return
  fi

  printf '%s\n' "$prompt" >&2
  for i in "${!choices[@]}"; do
    printf '  %s) %s\n' "$((i + 1))" "${choices[$i]}" >&2
  done

  while true; do
    read -r -p "Choose [${default_index}]: " answer
    answer="${answer:-$default_index}"
    if [[ "$answer" =~ ^[0-9]+$ ]] && (( answer >= 1 && answer <= ${#choices[@]} )); then
      printf '%s' "${choices[$((answer - 1))]}"
      return
    fi
    echo "Please choose a number from 1 to ${#choices[@]}." >&2
  done
}

need_sudo() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    return 0
  fi

  if ! command_exists sudo; then
    fail "sudo is required for installation, but sudo is not available."
    return 1
  fi

  return 0
}

run_with_sudo() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

restart_docker() {
  if command_exists systemctl; then
    run_with_sudo systemctl restart docker && return 0
  fi

  if command_exists service; then
    run_with_sudo service docker restart && return 0
  fi

  fail "Cannot find systemctl or service to restart Docker."
  return 1
}

configure_nvidia_docker_runtime() {
  if ! command_exists nvidia-ctk; then
    fail "nvidia-ctk is not available, so Docker NVIDIA runtime cannot be configured yet."
    return 1
  fi

  if ! need_sudo; then
    return 1
  fi

  run_with_sudo nvidia-ctk runtime configure --runtime=docker || return 1
  restart_docker || return 1
}

install_docker() {
  if ! need_sudo; then
    return 1
  fi

  info "Installing Docker from Ubuntu apt package: docker.io"
  run_with_sudo apt-get update || return 1
  run_with_sudo apt-get install -y docker.io || return 1
  run_with_sudo systemctl enable --now docker || return 1
}

add_user_to_docker_group() {
  local target_user="${SUDO_USER:-${USER:-}}"

  if [[ -z "$target_user" ]]; then
    fail "Cannot determine current user for docker group fix."
    return 1
  fi

  if ! need_sudo; then
    return 1
  fi

  run_with_sudo groupadd -f docker || return 1
  run_with_sudo usermod -aG docker "$target_user" || return 1
  warn "User '$target_user' was added to docker group. Log out and log back in before running Docker without sudo."
}

install_nvidia_driver() {
  if ! need_sudo; then
    return 1
  fi

  if ! command_exists ubuntu-drivers; then
    run_with_sudo apt-get update || return 1
    run_with_sudo apt-get install -y ubuntu-drivers-common || return 1
  fi

  info "Installing the recommended NVIDIA driver with ubuntu-drivers autoinstall."
  run_with_sudo ubuntu-drivers autoinstall || return 1
  warn "NVIDIA driver installation usually requires a reboot before nvidia-smi works."
}

install_nvidia_container_toolkit() {
  if ! need_sudo; then
    return 1
  fi

  if ! command_exists curl; then
    run_with_sudo apt-get update || return 1
    run_with_sudo apt-get install -y curl ca-certificates gnupg || return 1
  fi

  info "Installing nvidia-container-toolkit from NVIDIA's apt repository."
  run_with_sudo install -m 0755 -d /etc/apt/keyrings || return 1
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | run_with_sudo gpg --dearmor -o /etc/apt/keyrings/nvidia-container-toolkit-keyring.gpg || return 1
  curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/etc/apt/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    run_with_sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list >/dev/null || return 1
  run_with_sudo apt-get update || return 1
  run_with_sudo apt-get install -y nvidia-container-toolkit || return 1
  run_with_sudo nvidia-ctk runtime configure --runtime=docker || return 1
  restart_docker || return 1
}

select_gpu_test_image() {
  if [[ "$RUN_GPU_TEST" == "no" ]]; then
    return
  fi

  if [[ "$GPU_TEST_IMAGE_SET" -eq 1 ]]; then
    return
  fi

  local selected
  selected="$(ask_choice "Choose the image for Docker GPU smoke test:" 1 \
    "ubuntu:20.04" \
    "nvidia/cuda:12.4.1-base-ubuntu20.04" \
    "custom")"

  if [[ "$selected" == "custom" ]]; then
    IMAGE_FOR_GPU_TEST="$(ask_text "Custom GPU test image" "$IMAGE_FOR_GPU_TEST")"
  else
    IMAGE_FOR_GPU_TEST="$selected"
  fi
}

check_os() {
  headline "System"

  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    ok "OS detected: ${PRETTY_NAME:-unknown}"
    if [[ "${ID:-}" != "ubuntu" ]]; then
      warn "Host OS is not Ubuntu. The container can still be Ubuntu 20.04, but install hints may need adjustment."
    fi
  else
    warn "Cannot read /etc/os-release."
  fi

  if command_exists uname; then
    ok "Kernel: $(uname -srmo)"
  fi
}

check_docker() {
  headline "Docker"

  if ! command_exists docker; then
    fail "Docker CLI is not installed or not in PATH."
    if confirm_install "Install Docker now using Ubuntu package docker.io?" "n"; then
      if install_docker && command_exists docker; then
        ok "Docker installed."
      else
        fail "Docker installation did not complete successfully."
      fi
    else
      info "Install Docker on the host before building or running the GPU container."
    fi
    return
  fi

  ok "Docker CLI: $(docker --version)"

  local docker_info
  if ! capture_command docker_info docker info; then
    fail "Docker daemon is not reachable by the current user."
    info "$docker_info"
    if [[ "$docker_info" == *"permission denied"* ]] && confirm_install "Add current user to docker group?" "y"; then
      add_user_to_docker_group || true
    else
      info "Start Docker, or add the current user to the docker group and re-login."
    fi
    return
  fi

  ok "Docker daemon is reachable."
  DOCKER_READY=1

  if id -nG "$USER" 2>/dev/null | tr ' ' '\n' | grep -qx docker; then
    ok "Current user is in the docker group."
  else
    warn "Current user is not in the docker group. You may need sudo for Docker commands."
    if confirm_install "Add current user to docker group?" "n"; then
      add_user_to_docker_group || true
    fi
  fi

  if docker info --format '{{json .Runtimes}}' 2>/dev/null | grep -q nvidia; then
    ok "Docker reports an nvidia runtime."
    DOCKER_NVIDIA_RUNTIME_READY=1
  else
    warn "Docker does not report an nvidia runtime. This can be normal with newer toolkit versions, but GPU smoke test is the real check."
    if command_exists nvidia-ctk; then
      if confirm_install "Configure NVIDIA runtime for Docker now with nvidia-ctk?" "y"; then
        if configure_nvidia_docker_runtime; then
          if docker info --format '{{json .Runtimes}}' 2>/dev/null | grep -q nvidia; then
            ok "Docker now reports an nvidia runtime."
            DOCKER_NVIDIA_RUNTIME_READY=1
          else
            warn "nvidia-ctk configuration completed, but Docker still does not list an nvidia runtime. GPU smoke test will be the final check."
          fi
        else
          fail "Failed to configure NVIDIA runtime for Docker."
        fi
      fi
    else
      info "nvidia-ctk is not available yet. The toolkit check below can install it."
    fi
  fi
}

check_nvidia_host() {
  headline "NVIDIA host driver"

  if ! command_exists nvidia-smi; then
    fail "nvidia-smi is not available on the host."
    if confirm_install "Install the recommended NVIDIA driver on the host now?" "n"; then
      install_nvidia_driver || true
    else
      info "Install a working NVIDIA driver on the host. Do not install the driver inside the container."
    fi
    return
  fi

  local smi
  if ! capture_command smi nvidia-smi --query-gpu=name,driver_version --format=csv,noheader; then
    fail "nvidia-smi exists but failed to query the GPU."
    info "$smi"
    if confirm_install "Try installing/reinstalling the recommended NVIDIA driver now?" "n"; then
      install_nvidia_driver || true
    fi
    return
  fi

  ok "nvidia-smi can query the GPU."
  NVIDIA_READY=1
  printf '%s\n' "$smi" | sed 's/^/       GPU: /'
}

check_nvidia_container_toolkit() {
  headline "NVIDIA container toolkit"

  local found=0

  if command_exists nvidia-ctk; then
    ok "nvidia-ctk is available: $(nvidia-ctk --version 2>/dev/null | head -n 1)"
    found=1
  fi

  if command_exists dpkg; then
    if dpkg -s nvidia-container-toolkit >/dev/null 2>&1; then
      ok "Package installed: nvidia-container-toolkit"
      found=1
    fi
    if dpkg -s nvidia-container-runtime >/dev/null 2>&1; then
      ok "Package installed: nvidia-container-runtime"
      found=1
    fi
  fi

  if [[ "$found" -eq 0 ]]; then
    fail "NVIDIA container toolkit was not detected."
    if confirm_install "Install nvidia-container-toolkit now?" "y"; then
      if install_nvidia_container_toolkit; then
        ok "nvidia-container-toolkit installation command completed."
        NVIDIA_TOOLKIT_READY=1
      else
        fail "nvidia-container-toolkit installation did not complete successfully."
      fi
    else
      info "The host needs nvidia-container-toolkit for 'docker run --gpus all ...'."
    fi
  else
    NVIDIA_TOOLKIT_READY=1
  fi
}

check_docker_gpu() {
  headline "Docker GPU smoke test"

  if [[ -z "$RUN_GPU_TEST" ]]; then
    RUN_GPU_TEST="yes"
  fi

  if [[ "$RUN_GPU_TEST" != "yes" ]]; then
    skip "Docker GPU smoke test skipped."
    return
  fi

  if ! command_exists docker; then
    skip "Docker is missing, so GPU smoke test cannot run."
    return
  fi

  if [[ "$DOCKER_READY" -ne 1 ]]; then
    skip "Docker daemon is not ready, so GPU smoke test cannot run."
    return
  fi

  if [[ "$NVIDIA_READY" -ne 1 ]]; then
    skip "NVIDIA host driver is not ready, so GPU smoke test cannot run."
    return
  fi

  if [[ "$NVIDIA_TOOLKIT_READY" -ne 1 ]]; then
    skip "NVIDIA container toolkit is not ready, so GPU smoke test cannot run."
    return
  fi

  select_gpu_test_image
  info "Running: docker run --rm --gpus all ${IMAGE_FOR_GPU_TEST} nvidia-smi"

  local output
  if capture_command output docker run --rm --gpus all "$IMAGE_FOR_GPU_TEST" nvidia-smi; then
    ok "Docker can expose the GPU to containers."
    printf '%s\n' "$output" | sed -n '1,15p' | sed 's/^/       /'
  else
    fail "Docker GPU smoke test failed."
    info "$output"
  fi
}

print_summary() {
  headline "Summary"
  printf '%s passed, %s warnings, %s failed, %s skipped\n' "$PASS" "$WARN" "$FAIL" "$SKIP"

  if [[ "$FAIL" -gt 0 ]]; then
    printf '%s\n' "${RED}Preflight finished with blocking issues.${RESET}"
    return 1
  fi

  if [[ "$WARN" -gt 0 ]]; then
    printf '%s\n' "${YELLOW}Preflight finished with warnings. The setup may still work.${RESET}"
    return 0
  fi

  printf '%s\n' "${GREEN}Preflight passed.${RESET}"
}

main() {
  set -e
  printf '%s\n' "${BOLD}ub20-gpu preflight${RESET}"
  info "Project directory: $SCRIPT_DIR"

  check_os
  check_docker
  check_nvidia_host
  check_nvidia_container_toolkit
  check_docker_gpu
  print_summary
}

main "$@"
