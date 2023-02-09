#!/bin/bash
test "$BUILD_PATH" || exit 1

fail() {
  echo -e "$*" >&2
  exit 1
}

get_relative_path() {
  # shellcheck disable=SC2001
  echo "$1" | sed "s@$2/@@g"
}

c_download() {
  if [ ! -f "$2" ]; then
    wget -c -O "$2".dl "$1"
    mv "$2".dl "$2"
  fi
}
