ARG BASE_IMAGE=ubuntu:20.04
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000
ARG CONTAINER_SHELL=zsh
ARG CONTAINER_WORKDIR=/workspace
ARG DEFAULT_PACKAGES="git vim-gtk3 curl wget cmake htop ripgrep tmux zsh sudo ca-certificates build-essential"
ARG INSTALL_MINICONDA=1
ARG CONDA_DIR=/opt/conda
ARG CONDA_AUTO_ACTIVATE_BASE=0
ARG INSTALL_OH_MY_ZSH=1
ARG ZSH_THEME=powerlevel10k/powerlevel10k
ARG ZSH_PLUGINS="git vi-mode sudo z zsh-autosuggestions zsh-syntax-highlighting"
ARG COPY_TMUX_CONF=1
ARG VIM_CLIPBOARD=1

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PATH="${CONDA_DIR}/bin:${PATH}"

COPY .tmux.conf /tmp/dotfiles/.tmux.conf

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ${DEFAULT_PACKAGES}; \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    if getent group "${USER_GID}" >/dev/null; then \
      group_name="$(getent group "${USER_GID}" | cut -d: -f1)"; \
    else \
      groupadd --gid "${USER_GID}" "${USERNAME}"; \
      group_name="${USERNAME}"; \
    fi; \
    useradd --uid "${USER_UID}" --gid "${USER_GID}" --create-home --shell "/usr/bin/${CONTAINER_SHELL}" "${USERNAME}"; \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}"; \
    chmod 0440 "/etc/sudoers.d/${USERNAME}"; \
    mkdir -p "${CONTAINER_WORKDIR}"; \
    chown -R "${USERNAME}:${group_name}" "${CONTAINER_WORKDIR}"

RUN set -eux; \
    if [[ "${INSTALL_MINICONDA}" == "1" ]]; then \
      case "$(uname -m)" in \
        x86_64) miniconda_arch="x86_64" ;; \
        aarch64) miniconda_arch="aarch64" ;; \
        *) echo "Unsupported Miniconda architecture: $(uname -m)" >&2; exit 1 ;; \
      esac; \
      curl -fsSL -o /tmp/miniconda.sh "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-${miniconda_arch}.sh"; \
      bash /tmp/miniconda.sh -b -p "${CONDA_DIR}"; \
      rm -f /tmp/miniconda.sh; \
      auto_activate_base="false"; \
      if [[ "${CONDA_AUTO_ACTIVATE_BASE}" == "1" || "${CONDA_AUTO_ACTIVATE_BASE}" == "true" ]]; then auto_activate_base="true"; fi; \
      "${CONDA_DIR}/bin/conda" config --system --set auto_activate_base "${auto_activate_base}"; \
      "${CONDA_DIR}/bin/conda" clean -afy; \
      chown -R "${USERNAME}:${USER_GID}" "${CONDA_DIR}"; \
    fi

RUN set -eux; \
    user_home="/home/${USERNAME}"; \
    if [[ "${INSTALL_OH_MY_ZSH}" == "1" ]]; then \
      git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "${user_home}/.oh-my-zsh"; \
      git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${user_home}/.oh-my-zsh/custom/themes/powerlevel10k"; \
      git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "${user_home}/.oh-my-zsh/custom/plugins/zsh-autosuggestions"; \
      git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "${user_home}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"; \
      { \
        echo 'export ZSH="$HOME/.oh-my-zsh"'; \
        echo 'DISABLE_AUTO_UPDATE="true"'; \
        echo 'ZSH_DISABLE_COMPFIX="true"'; \
        echo 'POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true'; \
        echo "ZSH_THEME=\"${ZSH_THEME}\""; \
        echo "plugins=(${ZSH_PLUGINS})"; \
        echo 'source "$ZSH/oh-my-zsh.sh"'; \
        echo ''; \
        echo "export PATH=\"${CONDA_DIR}/bin:\$PATH\""; \
        echo "[[ -f \"${CONDA_DIR}/etc/profile.d/conda.sh\" ]] && source \"${CONDA_DIR}/etc/profile.d/conda.sh\""; \
      } > "${user_home}/.zshrc"; \
      chown -R "${USERNAME}:${USER_GID}" "${user_home}/.oh-my-zsh" "${user_home}/.zshrc"; \
    fi; \
    if [[ "${COPY_TMUX_CONF}" == "1" && -f /tmp/dotfiles/.tmux.conf ]]; then \
      cp /tmp/dotfiles/.tmux.conf "${user_home}/.tmux.conf"; \
      chown "${USERNAME}:${USER_GID}" "${user_home}/.tmux.conf"; \
    fi; \
    if [[ "${VIM_CLIPBOARD}" == "1" ]]; then \
      echo 'set clipboard=unnamedplus' > "${user_home}/.vimrc"; \
      chown "${USERNAME}:${USER_GID}" "${user_home}/.vimrc"; \
    fi

USER ${USERNAME}
WORKDIR ${CONTAINER_WORKDIR}
CMD ["zsh", "-l"]
