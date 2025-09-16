#!/bin/bash
set -e # Exit when error occured

USER_HOME=$(eval echo "~$SUDO_USER")
CONFIG_DIR="/tmp/${SUDO_USER}_config"
CONFIG_BACKUP_DIR="/tmp/${SUDO_USER}_config_backup"
SCRIPT_PATH=$(realpath "$0")


FILE_LST=(
  "${USER_HOME}/.config/kitty/kitty.conf"
  "${USER_HOME}/.tmux.conf"
  "${USER_HOME}/.config/nvim"
  ${SCRIPT_PATH}
)

FILE_TARGET_LST=(
  "kitty.conf"
  ".tmux.conf"
  "nvim"
  "sync.sh"
)

echo ${USER_HOME}

if [[ -d "${CONFIG_DIR}/.git" ]]; then
  echo "${CONFIG_DIR} exist, do git pull"
  cd ${CONFIG_DIR}
else
  rm -rf ${CONFIG_DIR}
  mkdir -p ${CONFIG_DIR}
  git clone git@github.com:GDTR12/config.git "${CONFIG_DIR}" || { echo "[Error]: git clone failed! Exiting."; exit 1; }
fi


if [[ $1 == "pull" ]]; then

  # Backup
  BACKUP_DIR="${CONFIG_BACKUP_DIR}/$(date +%Y-%m-%d-%M-%S)"
  echo "========================================================================"
  echo "                           Backup                                       "
  echo "========================================================================"
  mkdir -p ${BACKUP_DIR}
  for item in "${FILE_LST[@]}"; do
    if [[ -f ${item} ]]; then
      cp -rf ${item} "${BACKUP_DIR}"
      echo "Backup: ${BACKUP_DIR} <- ${item}"
    fi
  done

  # Pull source from github
  echo "========================================================================"
  echo "                            Pull                                        "
  echo "========================================================================"
  git pull  || { echo "[Error]: git pull failed! Exiting."; exit 1; }
  for ((i=0; i<${#FILE_TARGET_LST[@]}; i++)) do
    source="${FILE_TARGET_LST[$i]}"
    dest="${FILE_LST[$i]}"
    dest_dir=$(dirname ${dest})
    mkdir -p ${dest_dir}
    cp -rf "${CONFIG_DIR}/${source}" "$dest"
    echo "Update: ${dest} <- ${CONFIG_DIR}/${source}"
  done

elif [[ $1 == "push" ]]; then

  # Push source to github
  echo "========================================================================"
  echo "                            Push                                        "
  echo "========================================================================"
  for ((i=0; i<${#FILE_TARGET_LST[@]}; i++)) do
    target="${FILE_TARGET_LST[$i]}"
    source="${FILE_LST[$i]}"
    if [[ -d ${source} ]]; then
      rsync -a --exclude='.git' "$source/" "${CONFIG_DIR}/${target}"
    else
      cp -rf "$source" "${CONFIG_DIR}/${target}"
    fi
    echo "Update: ${source} -> ${CONFIG_DIR}/${target}"
  done

  cd "${CONFIG_DIR}"
  git add .
  git diff --cached
  git commit -m "$2"
  git push  || { echo "[Error]: git push failed! Exiting."; exit 1; }
fi









