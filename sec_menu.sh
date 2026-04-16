#!/bin/bash

REAL_PATH=$(readlink -f "$0")

SCRIPT_DIR=$(dirname "$REAL_PATH")

source "$SCRIPT_DIR/menu_base.sh"
source "$SCRIPT_DIR/utils.sh"

function show_menu_header() {
  local current_section="${1:-}"
  local nav_items=("Главная" "Безопасность и Доступ")

  [[ -n "$current_section" ]] && nav_items+=("$current_section")
  clear
  show_separator
  show_center "$(join_colored ' > ' "${nav_items[@]}")"
  show_separator
}

function is_ufw_installed() {
  command -v ufw &> /dev/null
}

function is_ufw_enabled() {
  if ufw status | grep -q "Status: active"; then return 0; else return 1; fi
}

function is_ssh_installed() {
  command -v sshd &> /dev/null
}

function is_ssh_running() {
  systemctl is-active --quiet ssh || systemctl is-active --quiet sshd
}

function get_ssh_config() {
  local key="${1,,}"
  sshd -T | awk -v key="$key" '$1 == key {print $2}'
}

function set_ssh_config() {
  local key="$1"
  local value="$2"
  local file="/etc/ssh/sshd_config"

  [[ ! -f "${file}.bak" ]] && cp "$file" "${file}.bak"

  if grep -qiE "^[#]*\s*${key}\b" "$file"; then
    sed -i -E "s|^[#]*\s*${key}\b.*|${key} ${value}|I" "$file"
  else
    echo "${key} ${value}" >> "$file"
  fi
}

function toggle_ssh_config() {
  local key="$1"
  local cur_val=$(get_ssh_config "$key")
  local new_val
  if [[ "$cur_val" == "yes" ]]; then
    new_val="no"
  else
    new_val="yes"
  fi
  set_ssh_config "$key" "$new_val"
}

function ssh_config_status() {
  local key="$1"
  local val=$(get_ssh_config "$key")

  case "${val,,}" in
    yes) echo "Разрешено" ;;
    no)  echo "Запрещено" ;;
    "")  echo "Параметр '$key' не найден" >&2; return 1 ;;
    *)   echo "Неожиданное значение: '$val'" >&2; return 1 ;;
  esac
}

function get_users() {
  local numbered=false
  local colored=false
  local show_root=false
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n|--numbered) numbered=true ;;
      -c|--colored)  colored=true ;;
      -r|--root)     show_root=true ;;
    esac
    shift
  done
  local users
  users=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd)

  $show_root && users=$(printf "root\n%s" "$users")

  local i=1
  while IFS= read -r user; do
    local name=""

    if $numbered; then
      if $colored; then
        join_colored_var name " " "$i)" "$user"
      else
        name="${i}) $user"
      fi
      ((i++))
    else
      if $colored; then
        colored_print "$user"
        continue
      else
        name="${user}"
      fi
    fi

    printf "%b\n" "$name"
  done <<< "$users"
}

function show_ufw_menu() {
  while true; do
    show_menu_header "Настройки UFW"
    status_text="Не установлен"
    if is_ufw_installed; then
      is_ufw_enabled && status_text="Запущен" || status_text="Выключён"
    fi
    show_center "Статус: $status_text"
    show_separator
    if ! is_ufw_installed; then
      show_menu_item 1 "Установить"
    else
      local action_text="Включить"
      is_ufw_enabled && action_text="Выключить"
      show_menu_item 1 "$action_text"
      show_menu_item 2 "Запретить порт"
      show_menu_item 3 "Разрешить порт"
      show_menu_item 4 "Удалить правило"
      show_menu_item 5 "Список правил"
      is_ufw_enabled && show_menu_item 6 "$action_text"
      show_menu_item "X" "Удалить"
    fi
    show_menu_footer
    colored_read choice "$PROMPT_SYMBOL"

    case $choice in
      1)
          if ! is_ufw_installed; then
            apt install -y ufw
          else
            is_ufw_enabled && ufw disable || ufw --force enable
          fi ;;
      2|3)
          [ "$choice" == "3" ] && action="allow" || action="deny"

          read_or_cancel port "Введите порт" || continue

          if ! is_valid_port "$port"; then
            error "Вы ввели не правильный порт"
            show_pause
            continue
          fi

          colored_print "Выберите протокол для порта $port:"
          colored_print "1) TCP\n2) UDP\n3) Оба (и TCP и UDP)\n0) Отмена"
          colored_read choice "$PROMPT_SYMBOL"

          case $choice in
            1) res=$(ufw $action "$port/tcp") ;;
            2) res=$(ufw $action "$port/udp") ;;
            3) res=$(ufw $action "$port") ;;
          esac ;;
      4)
          ufw status numbered | tail -n +5
          read_or_cancel num "Введите НОМЕР правила" || continue
          ask "Вы уверены, что хотите удалить правило #$num?" "n" && ufw --force delete "$num" ;;
      5)
          ufw status numbered | tail -n +5
          show_pause ;;
      6)  is_ufw_enabled && ufw reload ;;
      x|X|ч|Ч) apt purge -y ufw ;;
      0)  break ;;
    esac
  done
}

function show_ssh_menu() {
  while true; do
    show_menu_header "Настройки SSH"

    status_text="Не установлен"
    if is_ssh_installed; then
      is_ssh_running && status_text="Запущен" || status_text="Выключён"
    fi
    show_center "Статус: $status_text"
    show_separator

    if is_ssh_installed; then
      is_ssh_running && status_text="Остановить" || status_text="Запустить"
      show_menu_item 1 "$status_text"
      show_menu_item 2 "Изменить порт $(get_ssh_config "Port")"
      show_menu_item 3 "Вход по SSH для root $(ssh_config_status "PermitRootLogin")"
      show_menu_item 4 "Вход по SSH через пароль $(ssh_config_status "PasswordAuthentication")"
      show_menu_item 5 "Вход по SSH через публичный ключ $(ssh_config_status "PubkeyAuthentication")"
      is_ssh_running && show_menu_item 6 "Перезапустить"
      show_menu_item "X" "Удалить"
    else
      show_menu_item 1 "Установить"
    fi

    show_menu_footer
    colored_read choice "$PROMPT_SYMBOL"

    case $choice in
      1)
          if is_ssh_installed; then
            is_ssh_running && [[ -n "$SSH_CONNECTION" ]] && ! ask "Отключение SSH разорвёт текущее соединение. Продолжить?" && continue
            is_ssh_running && systemctl stop ssh || systemctl start ssh
          else
            apt install -y openssh-server
          fi ;;
      2)
          read_port new_port "Введите порт" "$(get_valid_port)"
          local old_port=$(get_ssh_config "Port")
          [[ "$old_port" == "$new_port" ]] && continue
          set_ssh_config "Port" "$new_port"
          if is_ufw_installed; then
            ufw allow "$new_port"/tcp >/dev/null
            ufw delete allow "$old_port"/tcp >/dev/null
          fi ;;
      3)
          local cur_val="$(get_ssh_config "PermitRootLogin")"
          if [[ "$cur_val" == "yes" ]]; then
          local normal_users_count="$(awk -F: '$3 >= 1000 && $3 != 65534 {count++} END {print count+0}' /etc/passwd)"
          if [[ "$normal_users_count" -eq 0 ]]; then
            error "В системе нет обычных пользователей. Отключение Root-логина заблокирует доступ!"
            show_pause
            continue
          fi
        fi
        toggle_ssh_config "PermitRootLogin" ;;
      4)
          local cur_val="$(get_ssh_config "PasswordAuthentication")"
          if [[ "$cur_val" == "yes" ]]; then
            local pubkey_auth_val="$(get_ssh_config "PubkeyAuthentication")"
            if [[ "$pubkey_auth_val" == "no" ]]; then
              error "Нельзя отключить вход по паролю, так как вход по SSH-ключам тоже выключен. Сначала включите вход по ключам, иначе вы потеряете доступ к серверу!"
              show_pause
              continue
            fi
            local users_with_pubkey=0
            local permit_root="$(get_ssh_config "PermitRootLogin")"
            while IFS=: read -r username _ _ _ _ home _; do
              if [[ "$username" == "root" && "$permit_root" == "no" ]]; then
                continue
              fi

              if [[ -f "$home/.ssh/authorized_keys" && -s "$home/.ssh/authorized_keys" ]]; then
                ((users_with_pubkey++))
              fi
            done < /etc/passwd

            if [[ "$users_with_pubkey" -eq 0 ]]; then
              error "Невозможно отключить аутентификацию по паролю. В системе не найдено активных пользователей с настроенными SSH-ключами. Вы рискуете потерять доступ к серверу."
              show_pause
              continue
            fi
          fi
          toggle_ssh_config "PasswordAuthentication" ;;
      5)
          local cur_val="$(get_ssh_config "PubkeyAuthentication")"
          if [[ "$cur_val" == "yes" ]]; then
            pass_val="$(get_ssh_config "PasswordAuthentication")"
            if [[ "$pass_val" == "no" ]]; then
              error "Невозможно отключить аутентификацию по SSH-ключам, так как вход по паролю также запрещен. Отключение обоих методов приведет к полной потере доступа к серверу. Сначала включите PasswordAuthentication."
              show_pause
              continue
            fi
          fi
          toggle_ssh_config "PubkeyAuthentication" ;;
      6) is_ssh_running && ask "Вы уверены? Неверные настройки SSH могут привести к потере доступа!" && systemctl restart ssh ;;
      X|x|Ч|ч) apt purge -y openssh-server ;;
      0) break ;;
    esac
  done
}

function add_user_pubkey() {
  local username="$1"
  if ! id "$username" &>/dev/null; then
    error "Пользователь '$username' не найден!"
    return 1
  fi

  mkdir -p /home/$username/.ssh
  local ssh_key
  read_non_empty ssh_key "Введите публичный ключ для SSH"

  echo "$ssh_key" >> /home/$username/.ssh/authorized_keys

  chmod 700 /home/$username/.ssh
  chmod 600 /home/$username/.ssh/authorized_keys

  chown -R $username:$username /home/$username/.ssh
}

function show_users_menu() {
  while true; do
    show_menu_header "Пользователи"
    show_menu_item 1 "Создать пользователя"
    show_menu_item 2 "Настройки пользователя (WIP)"
    show_menu_item 3 "Список пользователей"
    show_menu_footer
    colored_read choice "$PROMPT_SYMBOL"

    case $choice in
      1)
          local default_user=
          while true; do
            default_user=$(gen_random_string 10)
            ! id "$default_user" &>/dev/null && break
          done
          local username
          while true; do
            read_or_default username "Введите имя пользователя" "$default_user"
            username="${username//[[:space:]]/}"
            [[ -z $username ]] && username="$default_user"

            if id "$username" &>/dev/null; then
              error "Пользователь '$username' уже существует!"
              continue
            fi
            break
          done

          local admin_group="sudo"
          getent group sudo &>/dev/null || admin_group="wheel"

          ask "Добавить пользователя в $admin_group группу?" || admin_group=""
          local extra_groups=""
          read_or_cancel extra_groups "Введите группы через пробел"
          extra_groups="${extra_groups//[[:space:]]/,}"

          local groups=""
          if [[ -n "$admin_group" && -n "$extra_groups" ]]; then
            groups="-G $admin_group,$extra_groups"
          elif [[ -n "$admin_group" ]]; then
            groups="-G $admin_group"
          elif [[ -n "$extra_groups" ]]; then
            groups="-G $extra_groups"
          fi

          print "'$groups'"

          if useradd -m -s /bin/bash $groups "$username"; then
            colored_print "Пользователь '$username' успешно создан." >&2
            colored_print "Введите пароль для пользователя '$username'" >&2
            passwd "$username"
            ask "Добавить публичный ключ пользователю '$username'?" && add_user_pubkey "$username"
          else
            error "Что-то пошло не так при создании пользователя '$username'"
            show_pause
          fi ;;
      3)
          show_menu_header "Пользователи"
          get_users -c -r | column
          show_separator
          print
          show_pause ;;
      0) break ;;
    esac
  done
}

function show_menu() {
  show_menu_header
  show_menu_item 1 "Настройки UFW"
  show_menu_item 2 "Настройка SSH"
  show_menu_item 3 "Пользователи"
  show_menu_item 4 "Управление сертификатами"
  show_menu_item 5 "Fail2ban"
  show_separator
  show_center "Введите номер пункта или [0] для возвращения назад"
  show_separator
}

while true; do
  show_menu
  colored_read choice "$PROMPT_SYMBOL"

  case $choice in
    1) show_ufw_menu ;;
    2) show_ssh_menu ;;
    3) show_users_menu ;;
    0) break ;;
  esac
done
