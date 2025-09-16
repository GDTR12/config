#!/bin/bash

USER_HOME=$(eval echo "~$SUDO_USER")
CONFIG_DIR="/tmp/${SUDO_USER}_config"
CONFIG_BACKUP_DIR="/tmp/${SUDO_USER}_config_backup"
SCRIPT_PATH=$(realpath "$0")


FILE_LST=(
  "${USER_HOME}/.config/kitty/kitty.conf"
  "${USER_HOME}/.tmux.conf"
  ${SCRIPT_PATH}
)

FILE_TARGET_LST=(
  "kitty.conf"
  ".tmux.conf"
  "sync.sh"
)

echo ${USER_HOME}

if [[ -d "${CONFIG_DIR}/.git" ]]; then
  echo "${CONFIG_DIR} exist, do git pull"
  cd ${CONFIG_DIR}
else
  rm -rf ${CONFIG_DIR}
  mkdir -p ${CONFIG_DIR}
  git clone git@github.com:GDTR12/config.git "${CONFIG_DIR}"
fi


if [[ $1 == "pull" ]]; then

  # Backup
  BACKUP_DIR="${CONFIG_BACKUP_DIR}/$(date +%Y-%m-%d-%M-%S)"
  echo "========================================================================"
  echo "                           Backup                                       "
  echo "========================================================================"
  mkdir -p ${BACKUP_DIR}
  for item in "${FILE_LST[@]}"; do
    cp -f item "${BACKUP_DIR}"
  done

  # Pull source from github
  echo "========================================================================"
  echo "                            Pull                                        "
  echo "========================================================================"
  git pull
  for ((i=0; i<${#FILE_TARGET_LST[@]}; i++)) do
    target="${FILE_TARGET_LST[$i]}"
    dest="${FILE_LST[$i]}"
    cp -f "${CONFIG_DIR}/${target}" "$dest"
    echo "Update: ${dest} <- ${CONFIG_DIR}/${target}"
  done

elif [[ $1 == "push" ]]; then

  # Push source to github
  echo "========================================================================"
  echo "                            Push                                        "
  echo "========================================================================"
  for ((i=0; i<${#FILE_TARGET_LST[@]}; i++)) do
    target="${FILE_TARGET_LST[$i]}"
    dest="${FILE_LST[$i]}"
    cp -f "$dest" "${CONFIG_DIR}/${target}"
    echo "Update: ${dest} -> ${CONFIG_DIR}/${target}"
  done

  cd "${CONFIG_DIR}"
  git add .
  git diff
  git commit -m "$2"
  git push
fi









