#!/bin/bash

source menu.sh

function get_ssh_config() {
  echo "22"
  # local key="${1,,}"
  # sshd -T | awk -v key="$key" '$1 == key {print $2}'
}

# function set_ssh_config() {
#   local key="$1"
#   local value="$2"
#   local file="/etc/ssh/sshd_config"

#   [[ ! -f "${file}.bak" ]] && cp "$file" "${file}.bak"

#   if grep -qiE "^[#]*\s*${key}\b" "$file"; then
#     sed -i -E "s|^[#]*\s*${key}\b.*|${key} ${value}|I" "$file"
#   else
#     echo "${key} ${value}" >> "$file"
#   fi
# }

# function toggle_ssh_config() {
#   local key="$1"
#   local cur_val=$(get_ssh_config "$key")
#   local new_val
#   if [[ "$cur_val" == "yes" ]]; then
#     new_val="no"
#   else
#     new_val="yes"
#   fi
#   set_ssh_config "$key" "$new_val"
# }

function ssh_config_status() {
  echo "Разрешено"
#   local key="$1"
#   local val=$(get_ssh_config "$key")

#   case "${val,,}" in
#     yes) echo "Разрешено" ;;
#     no)  echo "Запрещено" ;;
#     "")  echo "Параметр '$key' не найден" >&2; return 1 ;;
#     *)   echo "Неожиданное значение: '$val'" >&2; return 1 ;;
#   esac
}

function get_ssh_status() {
  if systemctl is-active --quiet ssh; then
    print "${GREEN}Запущена${NC}"
  else
    print "${RED}Остановлена${NC}"
  fi
}

function ssh_config_bracket() {
  local key="$1"
  local val="$2"

  case "$val" in
    yes|enabled|active|running)
      print "${GREEN}[${val}]${NC}" ;;
    no|disabled|inactive|stopped)
      print "${RED}[${val}]${NC}" ;;
    *)
      print "${YELLOW}[${val}]${NC}" ;;
  esac
}

function show_menu() {
  while true; do
    local port="$(get_ssh_config "Port")"
    local status="$(get_ssh_status)"
    local root_login="$(ssh_config_status "PermitRootLogin")"
    local pass_auth="$(ssh_config_status "PasswordAuthentication")"
    local pubkey="$(ssh_config_status "PubkeyAuthentication")"
    clear
    show_separator
    show_center "$(join_colored ' > ' 'Главная' 'Настройки системы' 'Управление SSH')"
    show_separator
    show_center "Служба SSH: $(get_ssh_status)"
    show_separator
    show_menu_item 1 "Порт подключения          $(ssh_config_bracket "Port" "$port")"
    show_menu_item 2 "Вход root по SSH          $(ssh_config_bracket "PermitRootLogin" "$root_login")"
    show_menu_item 3 "Аутентификация по паролю  $(ssh_config_bracket "PasswordAuthentication" "$pass_auth")"
    show_menu_item 4 "Аутентификация по ключу   $(ssh_config_bracket "PubkeyAuthentication" "$pubkey")"
    show_menu_item 5 "Перезапустить службу SSH"

    show_separator
    show_center "Введите номер пункта или [0] для выхода"
    show_separator
    read -r ssh_choice

    case $ssh_choice in
      0) return ;;
    esac
  done
}

show_menu
