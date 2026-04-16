#!/bin/bash

source menu_base.sh

function show_menu() {
  clear
  show_separator
  show_center "$(join_colored ' > ' 'Главная' 'Прокси и VPN')"
  show_separator
  show_menu_item 1 "Xray"
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
    0) break ;;
  esac
done
