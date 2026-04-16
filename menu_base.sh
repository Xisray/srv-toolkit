#!/bin/bash

source msg.sh

if [[ $EUID -ne 0 ]]; then
  error "This script must be run as root!"
  exit 1
fi

MENU_LENGTH=70

PROMPT_SYMBOL="> "

function show_pause() {
  local prompt="${1:-Нажмите Enter для продолжения...}"
  colored_read _ "$prompt"
}

function make_separator() {
  local sep="${1:-*}"
  local total_len="${2:-$MENU_LENGTH}"
  local line=""
  while ((${#line} < total_len)); do
    line+="$sep"
  done
  line="${line:0:$total_len}"
  print "$line"
}

function show_menu_item() {
  get_next_color color
  get_next_color color2
  print "$color$1)$color2 $2${NC}"
}

function show_center() {
  local title="$1"
  local sep="${2:- }"
  local title_len=$(get_visible_length "$title")
  local padding=$(( ($MENU_LENGTH - title_len) / 2 ))
  [[ "$padding" -lt 0 ]] && padding=0
  show_left "${title}" "$sep" "$padding"
}

function show_left() {
  local title="$1"
  local sep="${2:- }"
  local left_offset="${3:-0}"

  local title_len=$(get_visible_length "$title")
  local remaining=$(($MENU_LENGTH - title_len - $left_offset))
  local start=$(make_separator "$sep" $left_offset)
  local end=$(make_separator "$sep" "$remaining")
  get_next_color sep_color
  get_next_color color

  print "$sep_color$start$color${title}$sep_color${end}${NC}"
}

function show_separator() {
  local sep="${1:-=}"
  local line=$(make_separator "$sep" "$MENU_LENGTH")
  get_next_color color
  print "$color$line${NC}"
}

function show_menu_footer() {
  local text="${1:-Введите номер пункта или [0] для возвращения назад}"
  show_separator
  show_center "$text"
  show_separator
}
