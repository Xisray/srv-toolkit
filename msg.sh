#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

COLORS=("$RED" "$GREEN" "$BLUE" "$YELLOW" "$CYAN")
COLOR_INDEX=0

function print() {
  local msg="$1"
  shift
  echo -e $@ "$msg"
}

function get_next_color() {
  local var_name="$1"
  local current_color="${COLORS[$COLOR_INDEX]}"
  COLOR_INDEX=$(( (COLOR_INDEX + 1) % ${#COLORS[@]} ))
  printf -v "$var_name" "%b" "$current_color"
}

function colored_print() {
  local msg="$1"
  shift
  get_next_color color
  echo -e $@ "${color}$msg${NC}"
}

function join_colored_var() {
  local var_name="$1"
  local sep="$2"
  shift
  local items=("$@")
  local count=${#items[@]}
  local result=""

  for ((__i=0; __i<count; __i++)); do
    get_next_color color
    result+="${color}${items[__i]}${NC}"
    if (( __i < count - 1 )); then
      get_random_color sep_color
      result+="${sep_color}${sep}${NC}"
    fi
  done
  printf -v "$var_name" "%b" "$result"
}

function join_colored() {
  local sep="$1"
  shift
  local items=("$@")
  local count=${#items[@]}
  local result=""

  for ((i=0; i<count; i++)); do
    get_next_color color
    result+="${color}${items[i]}${NC}"
    if (( i < count - 1 )); then
      get_random_color sep_color
      result+="${sep_color}${sep}${NC}"
    fi
  done

  print "$result"
}

function get_random_color() {
  local var_name="$1"
  local rand_index=$(( RANDOM % ${#COLORS[@]} ))
  printf -v "$var_name" "%b" "${COLORS[$rand_index]}"
}

function warn() {
  print "${YELLOW}[WARN] $* ${NC}"
}

function error() {
  print "${RED}[ERROR] $* ${NC}" >&2
}

function success() {
  print "${GREEN}[SUCCESS] $* ${NC}"
}

function info() {
  print "${BLUE}[INFO] $* ${NC}"
}

function colored_read() {
  local var_name="$1"
  local prompt="$2"
  local __cr_input
  local prompt_color
  get_next_color prompt_color
  echo -ne "${prompt_color}"
  read -r -p "$(print $prompt_color"$prompt"$NC)" __cr_input
  printf -v "$var_name" "%s" "$__cr_input"
}

function ask() {
  local prompt="$1"
  local default="${2:-n}"
  local display_default

  if [[ "$default" == "y" || "$default" == "Y" ]]; then
    display_default="[Y/n]"
    default="y"
  else
    display_default="[y/N]"
    default="n"
  fi

  while true; do
    colored_read choice "$prompt $display_default:"
    choice="${choice,,}"
    if [[ -z "$choice" ]]; then
      choice="$default"
    fi

    case "$choice" in
      y|Y|yes) return 0 ;;
      n|N|no)  return 1 ;;
      *) echo "Please enter 'y' or 'n'." ;;
    esac
  done
}

function read_non_empty() {
  local var_name="$1"
  local prompt="$2: "
  local __rne_input
  while true; do
    colored_read __rne_input "$prompt"
    __rne_input="${__rne_input#"${__rne_input%%[![:space:]]*}"}"
    __rne_input="${__rne_input%"${__rne_input##*[![:space:]]*}"}"

    if [[ -n "$__rne_input" ]]; then
      break
    fi
  done
  printf -v "$var_name" "%s" "$__rne_input"
}

function read_or_default() {
  local var_name="$1"
  local prompt="$2"
  local default_value="$3"
  local __rod_input

  [[ -n "$default_value" ]] && prompt+=" [default: $default_value]"
  prompt+=":"

  colored_read __rod_input "$prompt"
  __rod_input="${__rod_input#"${__rod_input%%[![:space:]]*}"}"
  __rod_input="${__rod_input%"${__rod_input##*[![:space:]]*}"}"

  if [[ -z $__rod_input ]]; then
    printf -v "$var_name" "%s" "$default_value"
  else
    printf -v "$var_name" "%s" "$__rod_input"
  fi
}

function read_or_cancel() {
  local var_name="$1"
  local prompt="$2"
  local cancel_text="${3:-(Нажмите Enter для отмены)}"
  local __re_input
  colored_read __re_input "$prompt $cancel_text:"

  [[ -z "$__re_input" ]] && return 1
  printf -v "$var_name" "%s" "$__re_input"
}

function is_cmd() {
  command -v "$1" >/dev/null 2>&1
}

function get_visible_length() {
  local str="$1"
  local clean_str=$(echo -e "$str" | sed 's/\x1b\[[0-9;]*m//g')
  echo "${#clean_str}"
}
