#!/bin/bash

source menu_base.sh

function show_menu() {
  clear
  show_separator
  show_center "Главная"
  show_separator
  show_menu_item 1 "Администрирование"
  show_menu_item 2 "Сетевые настройки"
  show_menu_item 3 "Безопасность и Доступ"
  show_menu_item 4 "Прокси и VPN"
  show_separator
  show_center "Введите номер пункта или [0] для выхода"
  show_separator
}

while true; do
  show_menu
  read -r choice

  case $choice in
    1)  ./admin_menu.sh ;;
    2)  ./net_menu.sh ;;
    3)  ./sec_menu.sh ;;
    4)  ./vpn_menu.sh ;;
    0)  break ;;
  esac
done

