#!/bin/bash

REAL_PATH=$(readlink -f "$0")

SCRIPT_DIR=$(dirname "$REAL_PATH")

source "$SCRIPT_DIR/menu_base.sh"

function show_menu() {
  clear
  show_separator
  show_center "$(join_colored ' > ' 'Главная' 'Администрирование' 'Тестирование сервера')"
  show_separator
  show_menu_item 1 " 🌍 IP region"
  show_menu_item 2 " 🚧 Censorcheck для проверки геоблока"
  show_menu_item 3 " 🚧 Censorcheck для серверов РФ"
  show_menu_item 4 " 🚀 Тест до российских iPerf3 серверов"
  show_menu_item 5 " 📊 YABS Benchmark"
  show_menu_item 6 " 🛡️ IPQuality. Проверка IP сервера на блокировки зарубежными сервисами"
  show_menu_item 7 " 📡 Параметры сервера и проверка скорости к зарубежным провайдерам"
  show_menu_item 8 " 💻 Тест на процессор"
  show_menu_item 9 " 🔍 Запуск Realitls Scaner"
  show_menu_item 10 "🕵️‍♂️ Запустить DPI Detector (Анализ цензуры)"
  show_menu_item 11 "🔍 Запустить SNI Scan (Скан подсети)"
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
