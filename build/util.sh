#!/usr/bin/env bash
function panic() {
  echo -ne "[\033[31mError\033[0m] $*\n" >&2
  exit 1
}
function debug() {
  if [ "$DEBUG" ]; then
    echo -ne "[\033[33mDebug\033[0m] $*\n" >&2
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
