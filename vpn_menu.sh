#!/bin/bash

REAL_PATH=$(readlink -f "$0")

SCRIPT_DIR=$(dirname "$REAL_PATH")

source "$SCRIPT_DIR/menu_base.sh"

function is_docker_installed() {
  command -v docker &> /dev/null
}

function is_docker_running() {
    systemctl is-active --quiet docker
}

function show_xui_menu() {
  is_docker_installed || bash <(curl -sSL https://get.docker.com)
  is_docker_running || systemctl start docker
  mkdir ~/panel
  cd ~/panel || return
  cat > compose.yml << EOF # универсальный путь до сертификатов
services:
  3xui:
    image: ghcr.io/mhsanaei/3x-ui:latest
    container_name: 3xui_app
    # hostname: yourhostname <- optional
    volumes:
      - \$PWD/db/:/etc/x-ui/
      - \$PWD/cert/:/root/cert/
    environment:
      XRAY_VMESS_AEAD_FORCED: "false"
      XUI_ENABLE_FAIL2BAN: "true"
    tty: true
    network_mode: host
    restart: unless-stopped
EOF
  docker compose up -d
  while [ "$(docker inspect -f '{{.State.Running}}' 3xui_app 2>/dev/null)" != "true" ]; do
    sleep 1
    echo -e "Жду"
  done
  docker exec -it 3xui_app /usr/local/x-ui/x-ui setting -username "remove" -password "remove"
}

function show_menu() {
  clear
  show_separator
  show_center "$(join_colored ' > ' 'Главная' 'Прокси и VPN')"
  show_separator
  show_menu_item 1 "3X-UI"
  show_menu_item 2 "Hysteria2"
  show_menu_item 3 "Amnezia"
  show_menu_item 4 "MTProxy"
  show_menu_item 5 "Native чё-то там"
  show_separator
  show_center "Введите номер пункта или [0] для возвращения назад"
  show_separator
}

while true; do
  show_menu
  read -r choice

  case $choice in
    1) show_xui_menu ;;
    0) break ;;
  esac
done
