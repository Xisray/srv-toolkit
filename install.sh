#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root!" >&2
  exit 1
fi

if ! command -v git &>/dev/null; then
  echo "Git not found. Installing..."
  apt update && apt install -y git
fi

TARGET_DIR="/opt/srv-toolkit"

if [ -d "$TARGET_DIR/.git" ]; then
  cd "$TARGET_DIR" || exit
  git fetch origin main
  git reset --hard origin/main
else
  rm -rf "$TARGET_DIR"
  git clone https://github.com/Xisray/srv-toolkit.git "$TARGET_DIR"
fi

chmod -R +x "$TARGET_DIR"

ln -sf "$TARGET_DIR/menu.sh" /usr/local/bin/srv-menu
