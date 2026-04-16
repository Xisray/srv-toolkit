#!/bin/bash

source menu_base.sh

function show_ip_menu() {
  while true; do
    clear
    show_separator
    show_center "$(join_colored ' > ' 'Главная' 'Сетевые настройки' 'Управление IPv6')"
    show_separator
    show_menu_item 1 "Включить/Выключить IPv6" #Todo
    show_menu_item 2 "Авто IPv6 при загрузки-On/Off" #Todo
    show_separator
    show_center "Введите номер пункта или [0] для возвращения назад"
    show_separator
    read -r choice

    case $choice in
      0) break ;;
    esac
  done
}


function show_menu() {
  clear
  show_separator
  show_center "$(join_colored ' > ' 'Главная' 'Сетевые настройки')"
  show_separator
  show_menu_item 1 "Включить/Выключить BBR" #Todo
  show_menu_item 2 "Разрешить/Запретить ПИНГ" #Todo
  show_menu_item 3 "Управление IPv6"
  show_separator
  show_center "Введите номер пункта или [0] для возвращения назад"
  show_separator
}

while true; do
  show_menu
  read -r choice

  case $choice in
    3) show_ip_menu ;;
    0) break ;;
  esac
done
