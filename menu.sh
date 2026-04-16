#!/bin/bash

REAL_PATH=$(readlink -f "$0")

SCRIPT_DIR=$(dirname "$REAL_PATH")

source "$SCRIPT_DIR/menu_base.sh"

function show_menu() {
  clear
  show_separator
  show_center "Главная"
  show_separator
  show_menu_item 1 "Обновить меню"
  show_separator
  show_menu_item 2 "Администрирование"
  show_menu_item 3 "Сетевые настройки"
  show_menu_item 4 "Безопасность и Доступ"
  show_menu_item 5 "Прокси и VPN"
  show_separator
  show_center "Введите номер пункта или [0] для выхода"
  show_separator
}

while true; do
  show_menu
  read -r choice

  case $choice in
    1)
        cd /opt/srv-toolkit || exit
        git fetch origin main &>/dev/null
        if git reset --hard origin/main > /dev/null; then
          chmod +x /opt/srv-toolkit/*
          colored_print "Обновлено! Перезапуск..."
          sleep 1
          exec bash "$0"
        else
          error "Ошибка обновления"
          show_pause
        fi
    2)  bash "$SCRIPT_DIR/admin_menu.sh" ;;
    3)  bash "$SCRIPT_DIR/net_menu.sh" ;;
    4)  bash "$SCRIPT_DIR/sec_menu.sh" ;;
    5)  bash "$SCRIPT_DIR/vpn_menu.sh" ;;
    0)  break ;;
  esac
done

