#!/bin/bash

REAL_PATH=$(readlink -f "$0")

SCRIPT_DIR=$(dirname "$REAL_PATH")

source "$SCRIPT_DIR/menu_base.sh"
source "$SCRIPT_DIR/utils.sh"

function is_docker_installed() {
  command -v docker &> /dev/null
}

function is_docker_running() {
    systemctl is-active --quiet docker
}

function show_xui_menu() {
  is_docker_installed || bash <(curl -sSL https://get.docker.com)
  is_docker_running || systemctl start docker
  mkdir /root/panel
  cd /root/panel || return
  cat > compose.yml << EOF # универсальный путь до сертификатов
services:
  3xui:
    image: ghcr.io/mhsanaei/3x-ui:latest
    container_name: 3xui_app
    # hostname: yourhostname <- optional
    volumes:
      - /root/panel/db/:/etc/x-ui/
      - /root/panel/cert/:/root/cert/
    environment:
      XRAY_VMESS_AEAD_FORCED: "false"
      XUI_ENABLE_FAIL2BAN: "true"
    tty: true
    network_mode: host
    restart: unless-stopped
EOF
  docker compose up -d
  sleep 1
  while [ "$(docker inspect -f '{{.State.Running}}' 3xui_app 2>/dev/null)" != "true" ]; do
    sleep 1
  done
  sleep 1

  local username="$(gen_random_string)"
  local password="$(gen_random_string)"
  # local port=""
  # local webBasePath="$(gen_random_string)"

  docker exec -it 3xui_app /app/x-ui setting -username "$username" -password "$password" # -port "9234" -webBasePath "$webBasePath"
  colored_print "3X-UI установлен"
  colored_print "Username: $username"
  colored_print "Password: $password"
  show_pause
  # apt install -y openssl jq sqlite3

  # output=$(docker exec -it 3xui_app x-ui stop)

  # shor=($(openssl rand -hex 8) $(openssl rand -hex 8) $(openssl rand -hex 8) $(openssl rand -hex 8) $(openssl rand -hex 8) $(openssl rand -hex 8) $(openssl rand -hex 8) $(openssl rand -hex 8))

  # output=$(docker exec -it 3xui_app /app/bin/xray-linux-amd64 x25519)

  # private_key=$(echo "$output" | grep "^PrivateKey:" | awk '{print $2}')
  # public_key=$(echo "$output" | grep "^Password:" | awk '{print $2}')

  # trojan_pass=$(gen_random_string 10)
  # emoji_flag=$(LC_ALL=en_US.UTF-8 curl -s https://ipwho.is/ | jq -r '.flag.emoji')
  # ts=$(date "+%s%3N")

  # docker exec -it 3xui_app /app/x-ui setting -username "remove" -password "remove1" -port "9234" -webBasePath "xxaada"
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
