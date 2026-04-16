#!/bin/bash

source msg.sh

declare -gA __used_strings=()
declare -gA __used_ports=()

function gen_random_string() {
  local length="${1:-12}"
  local unique="${2:-false}"
  local candidate
  while true; do
    candidate=$(head -c 4096 /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c "$length")
    if [[ "$unique" != "true" ]]; then
      echo "$candidate"
      return 0
    fi
    if [[ -z "${__used_strings[$candidate]}" ]]; then
      __used_strings[$candidate]=1
      echo "$candidate"
      return 0
    fi
  done
}

function get_port() { echo $(( ((RANDOM<<15)|RANDOM) % 49152 + 10000 )); }

function is_valid_port() {
  [[ "$1" =~ ^[0-9]+$ ]] && (( "$1" >= 1 && "$1" <= 65535 ))
}

function is_occupied_port() {
	local port=$1
    (echo > /dev/tcp/127.0.0.1/"$port") >/dev/null 2>&1
}

function get_valid_port() {
  local port
	while true; do
		port=$(get_port)
		if ! is_occupied_port "$port" && [[ -z "${__used_ports[$port]}" ]]; then
      __used_ports[$port]=1
			echo "$port"
			return 0
		fi
	done
}

function read_port() {
  local var_name="$1"
  local prompt="$2"
  local default_port="$3"
  local port
  local __rp_input

  if [[ -n "$default_port" ]]; then
    if ! is_valid_port "$default_port" || is_occupied_port "$default_port"; then
      default_port=""
    fi
  fi

  while true; do
    read_or_default __rp_input "$prompt" "$default_port"
    __rp_input="${__rp_input//[[:space:]]/}"
    if [[ -z "$__rp_input" && -n "$default_port" ]]; then
      printf -v "$var_name" "%s" "$default_port"
      return 0
    fi
    if ! is_valid_port "$__rp_input"; then
      error "Неправильный порт. Пожалуйста вводите числа между 1 и 65535."
      continue
    fi

    if is_occupied_port "$__rp_input"; then
      error "Порт '$__rp_input' уже используется."
      continue
    fi
    printf -v "$var_name" "%s" "$__rp_input"
    return 0
  done
}
