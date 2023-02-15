#!/usr/bin/env bash
function panic() {
  echo -ne "[\033[31mError\033[0m]\033[31m $UTIL_TYPE\033[0m: $*\n" >&2
  exit 1
}
function debug() {
  if [ "$DEBUG" ]; then
    echo -ne "[\033[33mDebug\033[0m]\033[31m$UTIL_TYPE\033[0m: $*\n" >&2
  fi
}
function check_commands() {
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null 2>&1 || panic "未在当前环境中发现 '$cmd' 命令."
  done
}
function check_files() {
  for path in "$@"; do
    test -f "$path" || panic "文件 '$path' 不存在."
  done
}
function check_dirs() {
  for path in "$@"; do
    test -d "$path" || panic "目录 '$path' 不存在."
  done
}
function create_dirs() {
  for path in "$@"; do
    test ! -d "$path" || (mkdir -p "$path" && debug "创建目录 $path")
  done
}
function reset_files() {
  for path in "$@"; do
    dir="$(dirname "$path")"
    test -d "$dir" || mkdir -p "$dir"
    test ! -f "$path" || (rm "$path" && debug "删除旧配置 $path")
    test -f "$path" || touch "$path"
  done
}

function fix_files_path() {
  test "$*" || return 1
  for path in "$@"; do
    dir="$(dirname "$path")"
    test -d "$dir" || mkdir -p "$dir"
  done
  return 0
}
