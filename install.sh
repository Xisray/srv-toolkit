#!/bin/bash

set -e

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root!" >&2
  exit 1
fi

REPO_URL=""

if ! command -v git &>/dev/null; then
  echo "Git not found. Installing..."
  apt update && apt upgrade -y && apt install -y git
fi

repo_name=$(basename "$REPO_URL" .git)

if [[ -d "$repo_name" ]]; then
  echo "Directory '$repo_name' already exists"
  exit 1
fi

git clone "$REPO_URL"

if [[ -f "$repo_name/install.sh" ]]; then
  rm -f "$repo_name/install.sh"
fi

chmod -R +x "$repo_name"
