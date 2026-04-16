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

function is_container_running() {
  docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null | grep -q true
}

function remove_docker() {
  ! ask "Удалить docker?" && return
  clear
  apt purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
  rm -rf /var/lib/docker /var/lib/containerd
  rm -f /etc/apt/sources.list.d/docker.sources /etc/apt/keyrings/docker.asc
}

function remove_container() {
  local id=$1
  ! ask "Удалить контейнер '$id'?" && return 1
  docker rm -f "$id"
}

function show_menu_header() {
  local current_section="${1:-}"
  local nav_items=("Главная" "Администрирование" "Docker")

  [[ -n "$current_section" ]] && nav_items+=("$current_section")
  clear
  show_separator
  show_center "$(join_colored ' > ' "${nav_items[@]}")"
  show_separator
}

function show_container_actions() {
  local id=$1
  local name=$2

  while true; do
    clear
    show_separator
    show_center "Контейнер: $name ($id)"
    local status="Незапущен"
    is_container_running "$id" && status="Запущен"
    show_center "Статус: $status"
    show_separator
    show_menu_item 1 "Посмотреть логи"
    if is_container_running "$id"; then
      show_menu_item 2 "Перезапустить"
      show_menu_item 3 "Остановить"
      show_menu_item 4 "Войти в терминал"
    else
      show_menu_item 2 "Запустить"
    fi
    show_menu_item "X" "Удалить (NEED TEST)"
    show_menu_footer
    colored_read choice "$PROMPT_SYMBOL"

    case $choice in
      1) clear && docker logs -f "$id" && show_pause ;;
      2)
          if is_container_running "$id"; then
            docker restart "$id"
          else
            docker start "$id"
          fi ;;
      3)  is_container_running "$id" && docker stop "$id" ;;
      4)
          if is_container_running "$id"; then
            clear
            docker exec -it "$id" /bin/bash || docker exec -it "$id" /bin/sh
          fi ;;
      X|x|ч|Ч) remove_container "$id" && show_pause && break ;;
      0) break ;;
      *) echo "Неверный пункт" ;;
    esac
  done
}

function show_manage_container_menu() {
  while true; do
    show_menu_header "Управление контейнерами"
    mapfile -t containers < <(docker ps --format "{{.ID}} | {{.Names}} | {{.Status}}" -a)
    if [ ${#containers[@]} -eq 0 ]; then
      show_center "Запущенные контейнеры не найдены."
    else
      for i in "${!containers[@]}"; do
        colored_print "$((i+1))) ${containers[$i]}"
      done
    fi
    show_separator
    show_center "Введите номер контейнера или [0] для выхода"
    show_separator
    colored_read choice "$PROMPT_SYMBOL"

    [[ "$choice" == "0" ]] && break
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -le "${#containers[@]}" ] && [ "$choice" -gt 0 ]; then
      local selected_data="${containers[$((choice-1))]}"
      local container_id=$(echo "$selected_data" | cut -d' ' -f1)
      local container_name=$(echo "$selected_data" | cut -d'|' -f2 | xargs)

      show_container_actions "$container_id" "$container_name"
    else
      show_pause "Неверный ввод. Нажмите Enter для продолжения..."
    fi
  done
}

function show_manage_menu() {
  while true; do
    show_menu_header 'Управление'
    status_text="Не запущен"
    is_docker_running && status_text="Запущен"
    show_center "$(join_colored ': ' 'Статус' "$status_text")"
    show_separator
    if is_docker_running; then
      show_menu_item 1 "Остановить"
      show_menu_item 2 "Перезапустить"
    else
      show_menu_item 1 "Запустить"
    fi
    show_menu_footer
    colored_read choice "$PROMPT_SYMBOL"

    case $choice in
      1)
          if is_docker_running; then
            systemctl stop docker
          else
            systemctl start docker
          fi ;;
      2)
          if is_docker_running; then
            systemctl restart docker
          fi ;;
      0)  break ;;
    esac
  done
}

function show_monitoring_menu() {
  while true; do
    show_menu_header 'Мониторинг'
    show_menu_item 1 "Список запущенных контейнеров"
    show_menu_item 2 "Статистика потребления ресурсов"
    show_menu_footer
    colored_read choice "$PROMPT_SYMBOL"

    case $choice in
      1) clear && docker ps && print && show_pause ;;
      2) clear && docker stats ;;
      0) break ;;
    esac
  done
}

function show_clear_menu() {
  while true; do
    show_menu_header "Очистка"
    show_menu_item 1 "Очистить неиспользуемые контейнеры"
    show_menu_item 2 "Очистить неиспользуемые сети"
    show_menu_item 3 "Полная очистка"
    show_menu_footer
    colored_read choice "$PROMPT_SYMBOL"
    clear
    case $choice in
      1) docker container prune && show_pause ;;
      2) docker network prune && show_pause ;;
      3)
          local flags=""
          ask "Удалить неиспользуемые образы?" "y" && flags+="-a "
          ask "Удалить неиспользуемые тома?" "n" && flags+="--volumes "
          docker system prune -f $flags
          show_pause ;;
      0) break ;;
    esac
  done
}

function show_menu() {
  show_menu_header
  local status_text="Не установлен"
  if is_docker_installed; then
      status_text="Не запущен"
      is_docker_running && status_text="Запущен"
  fi
  show_center "$(join_colored ': ' 'Статус' "$status_text")"
  show_separator
  if ! is_docker_installed; then
    show_menu_item 1 "Установить (NEED TEST)"
  else
    if is_docker_running; then
      show_menu_item 1 "Остановить"
      show_menu_item 2 "Перезапустить"
      show_menu_item 3 "Мониторинг"
      show_menu_item 4 "Управление контейнерами"
      show_menu_item 5 "Очистка"
    else
      show_menu_item 1 "Запустить"
      show_menu_item 2 "Очистка"
    fi
    show_menu_item "X" "Удалить (NEED TEST)"
  fi
  show_menu_footer
}

while true; do
  show_menu
  colored_read choice "$PROMPT_SYMBOL"

  case $choice in
    1)
        if is_docker_installed; then
          if is_docker_running; then
            systemctl stop docker
          else
            systemctl start docker
          fi
        else
          clear
          bash <(curl -sSL https://get.docker.com)
        fi ;;
    2)
        if is_docker_running; then
          systemctl restart docker
        else
          show_clear_menu
        fi ;;
    3)  is_docker_running && show_monitoring_menu ;;
    4)  is_docker_running && show_manage_container_menu ;;
    5)  is_docker_running && show_clear_menu ;;
    X|x|ч|Ч)  is_docker_installed && remove_docker ;;
    0) break ;;
  esac
done
