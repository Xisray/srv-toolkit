#!/bin/bash

REAL_PATH=$(readlink -f "$0")

SCRIPT_DIR=$(dirname "$REAL_PATH")

source "$SCRIPT_DIR/menu_base.sh"

function show_menu() {
  clear
  show_separator
  show_center "$(join_colored ' > ' 'Главная' 'Администрирование')"
  show_separator
  show_menu_item 1 "Обновить приложения"
  show_menu_item 2 "Docker"
  show_menu_item 3 "Тестирование сервера"
  show_menu_item 4 "Перезагрузить сервер (WIP)"
  show_separator
  show_center "Введите номер пункта или [0] для возвращения назад"
  show_separator
}

while true; do
  show_menu
  read -r choice

  case $choice in
    1)
        clear
        apt update && apt upgrade -y ;;
    2)  bash "$SCRIPT_DIR/docker_menu.sh" ;;
    3)  bash "$SCRIPT_DIR/test_menu.sh" ;;
    0)  break ;;
  esac
done
